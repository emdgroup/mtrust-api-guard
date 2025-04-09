import 'dart:async';
import 'package:args/command_runner.dart';
import 'package:mtrust_api_guard/doc_generator/doc_generator.dart';

class DocGeneratorCommand extends Command {
  @override
  String get description => "Generate API documentation from Dart files";

  @override
  String get name => "generate";

  DocGeneratorCommand() {
    argParser.addOption(
      'root',
      abbr: 'r',
      help:
          'Root directory of the dart project. Defaults to auto detect from the root directory. Will try walking up the directory tree if no root is found.',
      defaultsTo: null,
    );
  }

  @override
  FutureOr? run() {
    final args = argResults!.arguments;
    main(args);
  }
}
