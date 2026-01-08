// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mtrust_api_guard/api_guard_command_mixin.dart';

import 'package:mtrust_api_guard/version/version.dart';

class VersionCommand extends Command
    with ApiGuardCommandMixinWithRoot, ApiGuardCommandMixinWithBaseNew, ApiGuardCommandMixinWithCache {
  static final VersionCommand _instance = VersionCommand._internal();

  factory VersionCommand() => _instance;

  @override
  String get description => "Calculate and output the next version based on API changes";

  @override
  String get name => "version";

  @override
  String get usage {
    return super.usage +
        "\n\n"
            "Calculates the next version based on API changes between versions.\n"
            "Uses the current package version from the base file.\n";
  }

  VersionCommand._internal() {
    argParser
      ..addFlag(
        'badge',
        abbr: 'g',
        help: 'Generate a badge for the version',
      )
      ..addFlag(
        'commit',
        help: 'Commit the version to git',
        defaultsTo: true,
      )
      ..addFlag(
        'tag',
        abbr: 't',
        help: 'Tag the version',
        defaultsTo: true,
      )
      ..addFlag(
        'generate-changelog',
        help: 'Generate a changelog entry based on API changes',
        defaultsTo: true,
      )
      ..addOption(
        'json',
        help: 'Output the result as JSON to the specified file',
        valueHelp: 'file',
      )
      ..addFlag(
        'pre-release',
        abbr: 'p',
        help: 'Add pre-release suffix. 3.0.0-dev.1 where dev.1 is the pre-release suffix',
        defaultsTo: false,
      )
      ..addOption(
        'tag-prefix',
        help: 'Prefix for version tags useful for mono repos where multiple packages are versioned together',
        defaultsTo: 'v',
        valueHelp: 'prefix',
      )
      ..addOption(
        'dart-file',
        help: 'Output the version as a Dart constant to the specified file',
        valueHelp: 'file',
      );
  }

  bool get tag {
    return argResults?['tag'] as bool;
  }

  bool get commit {
    return argResults?['commit'] as bool;
  }

  bool get preRelease {
    return argResults?['pre-release'] as bool;
  }

  bool get badge {
    return argResults?['badge'] as bool;
  }

  bool get generateChangelog {
    return argResults?['generate-changelog'] as bool;
  }

  String? get json {
    return argResults?['json'] as String?;
  }

  String get tagPrefix {
    return argResults?['tag-prefix'] as String? ?? 'v';
  }

  String? get dartFile {
    return argResults?['dart-file'] as String?;
  }

  @override
  FutureOr? run() async {
    // Load config and determine doc file path

    final result = await version(
      gitRoot: Directory.current,
      dartRoot: Directory.current,
      badge: badge,
      baseRef: baseRef,
      tag: tag,
      commit: commit,
      generateChangelog: generateChangelog,
      cache: cache,
      isPreRelease: preRelease,
      tagPrefix: tagPrefix,
      dartFile: dartFile,
    );

    if (json != null) {
      final jsonFile = File(json!);
      if (!jsonFile.existsSync()) {
        jsonFile.createSync(recursive: true);
      }
      await jsonFile.writeAsString(jsonEncode(result.toJson()));
    }
  }
}
