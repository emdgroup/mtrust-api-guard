import 'dart:async';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mtrust_api_guard/bootstrap.dart';
import 'package:mtrust_api_guard/doc_generator/doc_generator_command.dart';
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

  final (dartFiles, exclusions, outputFile) = evaluateTargetFiles(argResults);

  if (dartFiles.isEmpty) {
    logger.err('No Dart files found in the specified paths. Exiting');
    return;
  }

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

  logger.success(
    'Found ${classes.length} classes: ${classes.map((e) => e.name).join(', ')}',
  );

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

  if (!outputFile.existsSync()) {
    outputFile.createSync(recursive: true);
  }

  // Write output file
  outputFile.writeAsStringSync(libraryTypes + "\n" + output);
  logger.success('Generated documentation file: ${outputFile.path}');

  contextCollection.dispose();
}
