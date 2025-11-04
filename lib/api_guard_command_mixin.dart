import 'dart:io';

import 'package:args/command_runner.dart';

// ignore: implementation_imports
import 'package:args/src/arg_parser.dart';

extension ArgParserExt on ArgParser {
  /// Checks if the parser contains an option with the given key.
  bool hasOptionWithKey(String key) {
    return options.entries.any((e) => e.key == key);
  }
}

mixin ApiGuardCommandMixinWithCache on Command {
  @override
  ArgParser get argParser {
    final argParser = super.argParser;

    if (!argParser.hasOptionWithKey('cache')) {
      argParser.addFlag(
        'cache',
        abbr: 'c',
        help: 'Cache the generated documentation for the specified ref',
        defaultsTo: true,
      );
    }
    return argParser;
  }

  bool get cache {
    return argResults?['cache'] as bool;
  }
}

mixin ApiGuardCommandMixinWithRoot on Command {
  @override
  ArgParser get argParser {
    final argParser = super.argParser;
    if (!argParser.hasOptionWithKey('root')) {
      argParser.addOption(
        'root',
        abbr: 'r',
        help: 'Root directory of the Dart project.'
            ' Defaults to auto-detect from the current directory.',
        defaultsTo: null,
      );
    }
    return argParser;
  }

  Directory get root {
    final rootPath = argResults?['root'] as String?;
    final rootDir = rootPath != null ? Directory(rootPath) : Directory.current;

    if (!rootDir.existsSync()) {
      throw Exception('Root directory does not exist: $rootPath');
    }

    return rootDir;
  }
}

mixin ApiGuardCommandMixinWithBaseNew on Command {
  @override
  ArgParser get argParser {
    final argParser = super.argParser;
    if (!argParser.hasOptionWithKey('base-ref')) {
      argParser.addOption(
        'base-ref',
        abbr: 'b',
        help: 'The previous version to compare against.'
            'Defaults to previous version from git history.',
      );
    }
    if (!argParser.hasOptionWithKey('new-ref')) {
      argParser.addOption(
        'new-ref',
        abbr: 'n',
        defaultsTo: 'HEAD',
        help: "The new version to compare against defaulting to HEAD",
      );
    }
    return argParser;
  }

  String? get baseRef {
    return argResults?['base-ref'] as String?;
  }

  String get newRef {
    return argResults?['new-ref'] as String;
  }
}
