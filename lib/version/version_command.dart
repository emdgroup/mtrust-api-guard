// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mtrust_api_guard/api_guard_command_mixin.dart';
import 'package:mtrust_api_guard/doc_generator/git_utils.dart';

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
        help: 'Add pre-release suffix (-dev.N)',
        defaultsTo: false,
      )
      ..addOption(
        'tag-prefix',
        help: 'Prefix for version tags',
        defaultsTo: 'v',
        valueHelp: 'prefix',
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

  @override
  FutureOr? run() async {
    // Load config and determine doc file path

    final gitRoot = await GitUtils.findGitRoot(Directory.current.path);

    final result = await version(
      gitRoot: Directory(gitRoot),
      dartRoot: Directory.current,
      badge: badge,
      baseRef: baseRef,
      tag: tag,
      commit: commit,
      generateChangelog: generateChangelog,
      cache: cache,
      isPreRelease: preRelease,
      tagPrefix: tagPrefix,
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
