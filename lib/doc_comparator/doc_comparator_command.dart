// ignore_for_file: avoid_print

import 'dart:async';
import 'package:args/command_runner.dart';
import 'package:mtrust_api_guard/doc_comparator/doc_comparator.dart';

class DocComparatorCommand extends Command {
  @override
  String get description => "Compare two API documentation files";

  @override
  String get name => "compare";

  static final DocComparatorCommand _instance =
      DocComparatorCommand._internal();

  factory DocComparatorCommand() => _instance;

  @override
  String get usage {
    return super.usage +
        "\n\n"
            "Hint: For 'base' and 'new', you can use:\n"
            "- local file paths (e.g. 'lib/documentation.dart'),\n"
            "- remote URLs (e.g. 'https://example.com/documentation.dart'),\n"
            "- or even Git references (e.g. 'HEAD:lib/documentation.dart').\n";
  }

  DocComparatorCommand._internal() {
    argParser
      ..addOption(
        'root',
        abbr: 'r',
        help:
            'Root directory of the dart project. Defaults to auto detect from the root directory. Will try walking up the directory tree if no root is found.',
        defaultsTo: null,
      )
      ..addOption(
        'base',
        abbr: 'b',
        help: 'Base documentation file',
      )
      ..addOption(
        'new',
        abbr: 'n',
        help: "New documentation file",
      )
      ..addMultiOption(
        'magnitudes',
        abbr: 'm',
        help: 'Show only changes with the specified magnitudes',
        defaultsTo: ['major', 'minor', 'patch'],
        allowed: ['major', 'minor', 'patch'],
      );
  }

  @override
  FutureOr? run() {
    final args = argResults!.arguments;
    main(args);
  }
}
