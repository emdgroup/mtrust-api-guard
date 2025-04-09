import 'dart:async';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:args/command_runner.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:mtrust_api_guard/doc_generator/detect_exclusions.dart';
import 'package:mtrust_api_guard/doc_generator/library_types.dart';
import 'package:mtrust_api_guard/doc_items.dart';
import 'package:mtrust_api_guard/logger.dart';
import 'package:mtrust_api_guard/mtrust_api_guard.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';

class DocGeneratorCommand extends Command {
  @override
  String get description => "Generate API documentation from Dart files";

  @override
  String get name => "generate";

  DocGeneratorCommand() {
    argParser
      ..addOption(
        'path',
        abbr: 'p',
        help: 'Dart files to scan. Supports patterns.',
        defaultsTo: 'lib/**/*.dart',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output file path',
        defaultsTo: 'lib/documentation.g.dart',
      )
      ..addFlag(
        "verbose",
        help: 'Verbose output.',
        defaultsTo: false,
      )
      ..addOption(
        'exclude',
        abbr: 'e',
        help: 'Path(s) to exclude from the analysis. Defaults to the files '
            'defined in analysis_options.yaml or no files if it is not present.',
        defaultsTo: null,
      );
  }

  @override
  FutureOr? run() {
    final args = argResults!.arguments;
    main(args);
  }
}

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

  final paths = argResults['path'] as String;
  final outputPath = argResults['output'] as String;
  final excludePaths = argResults['exclude'] as String?;
  final verbose = argResults['verbose'] as bool;

  final dartFiles = Glob(paths)
      .listSync()
      .map(
        (e) => p.normalize(e.absolute.path),
      )
      .toList();

  Set<String> exclusions = {};

  if (excludePaths != null) {
    exclusions = Glob(excludePaths)
        .listSync()
        .map((e) => p.normalize(e.absolute.path))
        .toSet();
  } else {
    if (verbose) {
      logger.detail("Checking for excluded files in analysis_options.yaml...");
    }
    exclusions = await detectExclusions(Directory.current.path);
  }

  if (dartFiles.isEmpty) {
    logger.err('No Dart files found in the specified paths. Exiting');
    return;
  }

  if (!verbose) {
    logger.info('Found ${dartFiles.length} Dart files to analyze.');
    logger.info('Excluding ${exclusions.length} files.');
  } else {
    logger.info("Files to analyze:");
    for (var e in dartFiles) {
      logger.detail("\t" + e);
    }
    logger.info("Exclusions:");
    for (var e in exclusions) {
      logger.detail("\t" + e);
    }
  }

  final contextCollection = AnalysisContextCollection(
    includedPaths: dartFiles,
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
        "Analyzed $file [${dartFiles.indexOf(file) + 1}/${dartFiles.length}]");
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

  // Write output file
  File(outputPath).writeAsStringSync(libraryTypes + "\n" + output);
  logger.success('Generated documentation file: $outputPath');
}
