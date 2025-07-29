import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:mtrust_api_guard/bootstrap.dart';
import 'package:mtrust_api_guard/doc_generator/doc_generator_command.dart';
import 'package:mtrust_api_guard/logger.dart';
import 'package:mtrust_api_guard/models/doc_items.dart';
import 'package:mtrust_api_guard/mtrust_api_guard.dart';
import 'package:path/path.dart';

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

      final classesInLibrary = library.element2.classes;

      for (final classItem in classesInLibrary) {
        classes.add(DocComponent(
          name: classItem.name3.toString(),
          filePath: relative(
            file,
            from: contextCollection.contextFor(file).contextRoot.root.path,
          ),
          isNullSafe: true,
          description:
              classItem.documentationComment?.replaceAll("///", "") ?? "",
          constructors: classItem.constructors2
              .map((e) => DocConstructor(
                    name: e.name3.toString(),
                    signature: e.formalParameters
                        .map((param) => DocParameter(
                              description: param.documentationComment ?? "",
                              name: param.name3.toString(),
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
          properties: classItem.fields2
              .map((e) => DocProperty(
                    name: e.name3.toString(),
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
          methods: classItem.methods2.map((e) => e.name3.toString()).toList(),
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

  final output = jsonEncode(classes);

  if (!outputFile.existsSync()) {
    outputFile.createSync(recursive: true);
  }
  outputFile.writeAsStringSync(output);

  outputProgress.complete();

  if (!outputFile.existsSync()) {
    outputFile.createSync(recursive: true);
  }
  logger.success('Generated documentation file: ${outputFile.path}');

  contextCollection.dispose();
}
