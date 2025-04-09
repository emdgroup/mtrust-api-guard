import 'dart:async';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mtrust_api_guard/doc_file_path.dart';
import 'package:mtrust_api_guard/doc_generator/detect_exclusions.dart';
import 'package:mtrust_api_guard/doc_generator/detect_target_files.dart';
import 'package:mtrust_api_guard/doc_generator/doc_generator_command.dart';
import 'package:mtrust_api_guard/doc_generator/find_project_root.dart';
import 'package:mtrust_api_guard/doc_generator/library_types.dart';
import 'package:mtrust_api_guard/doc_items.dart';
import 'package:mtrust_api_guard/logger.dart';
import 'package:mtrust_api_guard/mtrust_api_guard.dart';
import 'package:source_gen/source_gen.dart';

Future<void> main(List<String> args) async {
  // Set up command line argument parser
  final parser = DocGeneratorCommand().argParser;
  final argResults = parser.parse(args);

  if (argResults['help'] as bool) {
    logger.info('Documentation Generator');
    logger.info('Usage: dart doc_generator.dart [options]');
    logger.info(parser.usage);
    return;
  }

  final root = argResults['root'] as String?;
  late Directory rootDir;

  // Find the root directory to base the analysis on
  if (root == null) {
    rootDir = await findProjectRoot(Directory.current.path);

    if (rootDir.path != Directory.current.path) {
      logger.info("Changing root directory to $rootDir");
    }
  } else {
    rootDir = Directory(root);

    if (!rootDir.existsSync()) {
      logger.err('Root directory does not exist: $root');
      return;
    }
  }

  // Detect the files to analyze

  final dartFiles = detectTargetFiles(rootDir.path);

  if (dartFiles.isEmpty) {
    logger.err('No Dart files found in the specified paths. Exiting');
    return;
  }

  final exclusions = detectExclusionsFromAnalyzer(rootDir.path)
    ..addAll(
      detectExclusionsFromConfig(rootDir.path),
    );

  dartFiles.removeAll(exclusions);

  logger.info('Including ${dartFiles.length} files.');
  logger.info('Excluding ${exclusions.length} files.');

  // Start the analysis

  final contextCollection = AnalysisContextCollection(
    includedPaths: dartFiles.toList(),
    excludedPaths: exclusions.toList(),
  );

  final classes = <DocComponent>[];

  final progress = logger.progress("Analyzing dart files");

  // Analyze each file
  for (final file in dartFiles) {
    try {
      final context = contextCollection.contextFor(file);
      final library = await context.currentSession.getResolvedLibrary(file);
      if (library is! ResolvedLibraryResult) {
        throw StateError('Library not resolved.');
      }

      final classesInLibrary = LibraryReader(library.element).classes;

      for (final classItem in classesInLibrary) {
        classes.add(DocComponent(
          name: classItem.name,
          isNullSafe: true,
          description:
              classItem.documentationComment?.replaceAll("///", "") ?? "",
          constructors: classItem.constructors
              .map((e) => DocConstructor(
                    name: e.name.toString(),
                    signature: e.parameters
                        .map((param) => DocParameter(
                              description: param.documentationComment ?? "",
                              name: param.name.toString(),
                              type: param.type.toString(),
                              named: param.isNamed,
                              required: param.isRequired,
                            ))
                        .toList(),
                    features: [
                      if (e.isConst) "const",
                      if (e.isFactory) "factory",
                      if (e.isExternal) "external",
                    ],
                  ))
              .toList(),
          properties: classItem.fields
              .map((e) => DocProperty(
                    name: e.name.toString(),
                    type: e.type.toString(),
                    description: e.documentationComment ?? "",
                    features: [
                      if (e.isStatic) "static",
                      if (e.isCovariant) "covariant",
                      if (e.isFinal) "final",
                      if (e.isConst) "const",
                      if (e.isLate) "late",
                    ],
                  ))
              .toList(),
          methods: classItem.methods.map((e) => e.name.toString()).toList(),
        ));
      }
    } catch (e) {
      logger.err('Error analyzing file $file: $e');
    }
    progress.update(
      "Analyzed $file [${dartFiles.toList().indexOf(file) + 1}/${dartFiles.length}]",
    );
  }

  progress.complete();

  logger.success('Found ${classes.length} classes.');

  final outputProgress = logger.progress("Generating output");

  // Generate output
  final outputLibrary = Library((libraryBuilder) {
    libraryBuilder.body.add(Field((field) => field
      ..name = "docComponents"
      ..modifier = FieldModifier.constant
      ..assignment = literalList([
        for (final classItem in classes)
          refer("DocComponent").newInstance([], {
            "name": literalString(classItem.name),
            "isNullSafe": literalBool(classItem.isNullSafe),
            "description": literalString(classItem.description),
            "properties": literalList(classItem.properties
                .map((e) => refer("DocProperty").newInstance([], {
                      "name": literalString(e.name),
                      "type": literalString(e.type),
                      "description": literalString(e.description),
                      "features": literalList(
                          e.features.map((e) => literalString(e)).toList()),
                    }))
                .toList()),
            "constructors": literalList(classItem.constructors
                .map((e) => refer("DocConstructor").newInstance([], {
                      "name": literalString(e.name),
                      "signature": literalList(e.signature
                          .map((e) => refer("DocParameter").newInstance(
                                [],
                                {
                                  "name": literalString(e.name),
                                  "type": literalString(e.type),
                                  "description": literalString(e.description),
                                  "named": literalBool(e.named),
                                  "required": literalBool(e.required),
                                },
                              ))
                          .toList()),
                      "features": literalList(
                          e.features.map((e) => literalString(e)).toList()),
                    }))
                .toList()),
            "methods": literalList(
                classItem.methods.map((e) => literalString(e)).toList()),
          })
      ]).code));
  });

  final emitter = DartEmitter.scoped();
  final output = DartFormatter().format('${outputLibrary.accept(emitter)}');

  outputProgress.complete();

  final outputFile = getDocFile(rootDir.path);

  // Write output file
  outputFile.writeAsStringSync(libraryTypes + "\n" + output);
  logger.success('Generated documentation file: ${outputFile.path}');

  contextCollection.dispose();
}
