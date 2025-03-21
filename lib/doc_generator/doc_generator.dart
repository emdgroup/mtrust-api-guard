import 'dart:async';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:args/command_runner.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mtrust_api_guard/mtrust_api_guard.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';

import '../doc_items.dart';

class DocGeneratorCommand extends Command {
  @override
  String get description => "Generate API documentation from Dart files";

  @override
  String get name => "generate";

  DocGeneratorCommand() {
    argParser
      ..addMultiOption('path',
          abbr: 'p',
          help: 'Path(s) to scan for Dart files',
          defaultsTo: ['lib/src'])
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output file path',
        defaultsTo: 'lib/documentation.g.dart',
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
    print('Documentation Generator');
    print('Usage: dart doc_generator.dart [options]');
    print(parser.usage);
    return;
  }

  final paths = argResults['path'] as List<String>;
  final outputPath = argResults['output'] as String;

  // Collect and analyze Dart files
  final dartFiles = <File>[];
  for (final path in paths) {
    final directory = Directory(path);
    if (await directory.exists()) {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          dartFiles.add(entity);
        }
      }
    } else {
      print('Warning: Directory does not exist: $path');
    }
  }

  if (dartFiles.isEmpty) {
    print('No Dart files found in the specified paths.');
    return;
  }

  print('Found ${dartFiles.length} Dart files to analyze.');

  final normalizedPaths = paths.map((path) {
    final dir = Directory(path);
    return p.normalize(dir.absolute.path);
  }).toList();
  final contextCollection = AnalysisContextCollection(
    includedPaths: normalizedPaths,
  );

  final classes = <DocComponent>[];

  // Analyze each file
  for (final file in dartFiles) {
    final path = p.normalize(file.absolute.path);
    if (path.endsWith('.g.dart')) {
      continue; // Skip generated files, as they are not API-related
    }
    try {
      final context = contextCollection.contextFor(path);
      final library = await context.currentSession.getResolvedLibrary(path);
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
      print('Error analyzing file ${file.path}: $e');
    }
  }

  print('Found ${classes.length} classes.');

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

  // Load the type definitions from `doc_items.dart`
  final file = File('lib/doc_items.dart');
  final libraryTypes = file.readAsStringSync();

  // Write output file
  File(outputPath).writeAsStringSync(libraryTypes + "\n" + output);
  print('Generated documentation file: $outputPath');
}
