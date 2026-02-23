// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mtrust_api_guard/api_guard_command_mixin.dart';
import 'package:mtrust_api_guard/doc_generator/git_utils.dart';
import 'package:mtrust_api_guard/logger.dart';
import 'package:mtrust_api_guard/version/workspace_version.dart';
import 'package:mtrust_api_guard/version/workspace_utils.dart';

class VersionWorkspaceCommand extends Command
    with ApiGuardCommandMixinWithRoot, ApiGuardCommandMixinWithBaseNew, ApiGuardCommandMixinWithCache {
  static final VersionWorkspaceCommand _instance = VersionWorkspaceCommand._internal();

  factory VersionWorkspaceCommand() => _instance;

  @override
  String get description =>
      "Calculate and output the next version for all packages in a workspace based on API changes";

  @override
  String get name => "version-workspace";

  @override
  String get usage {
    return super.usage +
        "\n\n"
            "Calculates the next version for each package in a Dart workspace based on API changes.\n"
            "Only packages with changes compared to the base ref will be versioned.\n"
            "Tags are created in format: {package-name}/v{version}\n"
            "Dependencies between workspace packages are automatically updated.\n";
  }

  VersionWorkspaceCommand._internal() {
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
        help: 'Add pre-release suffix. Defaults to 3.0.0-1 unless --pre-release-prefix is provided',
        defaultsTo: false,
      )
      ..addOption(
        'pre-release-prefix',
        help: 'Prefix for pre-release versions. Example: --pre-release-prefix dev -> 3.0.0-dev.1',
        defaultsTo: '',
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

  String get preReleasePrefix {
    return argResults?['pre-release-prefix'] as String? ?? '';
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

  String? get dartFile {
    return argResults?['dart-file'] as String?;
  }

  @override
  FutureOr? run() async {
    final rootDir = root;
    final gitRoot = Directory(GitUtils.getRepositoryRoot(rootDir.path));

    // Detect workspace
    final workspace = detectWorkspace(rootDir);
    if (workspace == null) {
      logger.err('No workspace detected. Root pubspec.yaml must contain a "workspace" property.');
      logger.info('For single-package projects, use the "version" command instead.');
      exit(1);
    }

    logger.info('Detected workspace with ${workspace.memberPaths.length} members');

    final result = await versionWorkspace(
      gitRoot: gitRoot,
      workspace: workspace,
      badge: badge,
      baseRef: baseRef,
      tag: tag,
      newRef: newRef,
      commit: commit,
      generateChangelog: generateChangelog,
      cache: cache,
      isPreRelease: preRelease,
      preReleasePrefix: preReleasePrefix,
      dartFile: dartFile,
    );

    if (json != null) {
      final jsonFile = File(json!);
      if (!jsonFile.existsSync()) {
        jsonFile.createSync(recursive: true);
      }
      await jsonFile.writeAsString(jsonEncode(result.toJson()));
    }

    logger.success('Workspace versioning completed. Versioned ${result.packageVersions.length} package(s).');
  }
}
