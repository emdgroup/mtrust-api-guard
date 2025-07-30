// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mtrust_api_guard/api_guard_command_mixin.dart';
import 'package:mtrust_api_guard/badges/badge_generator.dart';
import 'package:mtrust_api_guard/config/config.dart';
import 'package:mtrust_api_guard/doc_comparator/api_change.dart';
import 'package:mtrust_api_guard/doc_comparator/doc_ext.dart';
import 'package:mtrust_api_guard/doc_comparator/file_loader.dart';
import 'package:mtrust_api_guard/doc_comparator/parse_doc_file.dart';
import 'package:mtrust_api_guard/find_project_root.dart';
import 'package:mtrust_api_guard/logger.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml_edit/yaml_edit.dart';

class VersionCommand extends Command
    with ApiGuardCommandMixinWithRoot, ApiGuardCommandMixinWithBaseNew {
  @override
  String get description =>
      "Calculate and output the next version based on API changes";

  @override
  String get name => "version";

  static final VersionCommand _instance = VersionCommand._internal();

  factory VersionCommand() => _instance;

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
        defaultsTo: true,
      )
      ..addFlag(
        'commit',
        abbr: 'c',
        help: 'Commit the version to git',
        defaultsTo: true,
      )
      ..addFlag(
        'pre-release',
        abbr: 'p',
        help: 'Add pre-release suffix (-dev.N)',
        defaultsTo: false,
      );
  }

  Future<YamlEditor> _getPubspec(String filePath) async {
    final pubspecFile = File(filePath);
    if (!pubspecFile.existsSync()) {
      throw Exception('pubspec.yaml not found at ${pubspecFile.path}');
    }
    final pubspecContent = await pubspecFile.readAsString();
    final pubspec = YamlEditor(pubspecContent);
    return pubspec;
  }

  Future<void> _writePubspec(String filePath, YamlEditor pubspec) async {
    final pubspecFile = File(filePath);
    if (!pubspecFile.existsSync()) {
      throw Exception('pubspec.yaml not found at ${pubspecFile.path}');
    }
    await pubspecFile.writeAsString(pubspec.toString());
  }

  Future<void> _commitVersion(String version) async {
    await Process.run('git', ['add', 'pubspec.yaml', 'api_guard/']);
    await Process.run('git', [
      'commit',
      '-m',
      'chore: bump version to $version [skip ci]',
    ]);
    await Process.run('git', ['tag', 'v$version']);
  }

  Future<void> _writeNewVersion(String filePath, String newVersion) async {
    final pubspec = await _getPubspec(filePath);

    pubspec.update(["version"], newVersion);

    await _writePubspec(filePath, pubspec);
  }

  Future<String> _getBaseVersion(String filePath) async {
    try {
      final pubspec = await _getPubspec(filePath);

      final version = pubspec.parseAt(["version"]).value;
      if (version == null) {
        throw Exception('Version not found in pubspec.yaml');
      }

      return version.toString();
    } catch (e) {
      logger.err('Error retrieving package version: $e');
      rethrow;
    }
  }

  Future<String> _calculateNextVersion(String currentVersion,
      ApiChangeMagnitude magnitude, bool isPreRelease) async {
    var version = Version.parse(currentVersion);

    logger.info('Current version: $version');

    switch (magnitude) {
      case ApiChangeMagnitude.major:
        logger.info('Incrementing major version');
        version = version.nextMajor;
        break;
      case ApiChangeMagnitude.minor:
        logger.info('Incrementing minor version');
        version = version.nextMinor;
        break;
      case ApiChangeMagnitude.patch:
        logger.info('Incrementing patch version');
        version = version.nextPatch;
        break;
    }

    final newVersion = version.toString();

    logger.info('New version: $newVersion');

    if (isPreRelease) {
      var preReleaseNum = 1;
      while (await _gitTagExists('$newVersion-dev.$preReleaseNum')) {
        preReleaseNum++;
      }
      logger.info('Pre-release version: $newVersion-dev.$preReleaseNum');
      return '$newVersion-dev.$preReleaseNum';
    } else if (await _gitTagExists(newVersion)) {
      logger.err('Version $newVersion already exists as a git tag');
      throw Exception('Version $newVersion already exists as a git tag');
    }

    return newVersion;
  }

  Future<bool> _gitTagExists(String tag) async {
    final result = await Process.run('git', ['tag', '-l', tag]);
    return result.stdout.toString().trim().isNotEmpty;
  }

  @override
  FutureOr? run() async {
    final argResults = this.argResults!;

    // Find the project root
    final rootPath = argResults['root'] as String?;
    final rootDir = rootPath != null
        ? Directory(rootPath)
        : findProjectRoot(Directory.current.path);

    // Load config and determine doc file path
    final analysisOptionsFile =
        File(join(rootDir.path, 'analysis_options.yaml'));
    ApiGuardConfig config;

    if (analysisOptionsFile.existsSync()) {
      logger.info(
          'Loading config from analysis_options.yaml at ${analysisOptionsFile.path}');
      config = ApiGuardConfig.fromYaml(analysisOptionsFile);
    } else {
      logger.info('No analysis_options.yaml found, using default config.');
      config = ApiGuardConfig.defaultConfig();
    }

    final docFilePath = join(rootDir.path, config.docFile);
    logger.info('Documentation file path resolved to: $docFilePath');

    // Determine base and new file paths
    final newFile = argResults['new'] as String? ?? docFilePath;
    final baseFile = argResults['base'] as String?;

    try {
      logger.info('Reading new documentation file: $newFile');
      final newContent = await getFileContent(newFile);
      final baseContent = baseFile != null
          ? await (() async {
              logger.info('Reading base documentation file: $baseFile');
              return await getFileContent(baseFile);
            })()
          : await (() async {
              logger.info(
                  'No base file provided, retrieving previous version of documentation file from git history.');
              return await getPreviousGitFileContent(docFilePath, rootDir);
            })();

      logger.info('Comparing documentation files...');
      final apiChanges = parseDocComponentsFile(baseContent).compareTo(
        parseDocComponentsFile(newContent),
      );

      var highestMagnitude = ApiChangeMagnitude.patch;

      // Determine highest magnitude
      if (apiChanges.isNotEmpty) {
        highestMagnitude = getHighestMagnitude(apiChanges);
      }

      // Get base version from pubspec.yaml
      final baseVersion = await _getBaseVersion(
        join(rootDir.path, 'pubspec.yaml'),
      );

      // Calculate next version
      final isPreRelease = argResults['pre-release'] as bool;
      final nextVersion = await _calculateNextVersion(
        baseVersion,
        highestMagnitude,
        isPreRelease,
      );

      await _writeNewVersion(
        join(rootDir.path, 'pubspec.yaml'),
        nextVersion,
      );

      if (argResults['badge'] as bool) {
        final badge = await generateVersionBadge(nextVersion);
        final badgeFile = File(join(rootDir.path, 'api_guard/version.svg'));
        if (!badgeFile.existsSync()) {
          badgeFile.createSync(recursive: true);
        }
        await badgeFile.writeAsString(badge);
      }

      if (argResults['commit'] as bool) {
        await _commitVersion(nextVersion);
      }

      logger.info('New version written to pubspec.yaml: $nextVersion');
    } catch (e, stack) {
      logger.err('An error occurred: \n$e');
      logger.err('Stack trace: $stack');
      exit(1);
    }
  }
}
