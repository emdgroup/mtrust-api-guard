import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mtrust_api_guard/doc_generator/resolve_ref_sdk.dart';

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
        help:
            'Root directory of the Dart project.'
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
        help:
            'The previous version to compare against.'
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

/// Escape hatches for the SDK a git ref is resolved with.
mixin ApiGuardCommandMixinWithSdkOverrides on Command {
  @override
  ArgParser get argParser {
    final argParser = super.argParser;

    if (!argParser.hasOptionWithKey('ref-sdk')) {
      argParser.addMultiOption(
        'ref-sdk',
        help:
            'Use this Flutter SDK version for a specific git ref instead of the '
            'one pinned in that ref. Repeat the option for several refs.',
        valueHelp: 'ref=version',
        splitCommas: false,
      );
    }
    if (!argParser.hasOptionWithKey('no-sdk-autodetect')) {
      argParser.addFlag(
        'no-sdk-autodetect',
        help:
            'Use the ambient Flutter SDK for every ref, ignoring .fvmrc, FVM '
            'config, workflow and pubspec SDK pins.',
        defaultsTo: false,
        negatable: false,
      );
    }
    return argParser;
  }

  /// The SDK overrides configured on this command.
  SdkOverrideOptions get sdkOverrideOptions {
    final values = (argResults?['ref-sdk'] as List<String>?) ?? const <String>[];
    final overrides = <String, String>{};

    for (final value in values) {
      final separator = value.indexOf('=');
      final ref = separator < 0 ? '' : value.substring(0, separator).trim();
      final version = separator < 0 ? '' : value.substring(separator + 1).trim();

      if (ref.isEmpty || version.isEmpty) {
        usageException(
          'Invalid --ref-sdk value "$value": expected <ref>=<version>, '
          'e.g. liquid_flutter/v23.0.0-16=3.44.8',
        );
      }
      overrides[ref] = version;
    }

    return SdkOverrideOptions(
      refSdkOverrides: overrides,
      autodetect: !(argResults?['no-sdk-autodetect'] as bool? ?? false),
    );
  }
}
