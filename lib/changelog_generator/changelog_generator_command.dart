// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mtrust_api_guard/changelog_generator/changelog_generator.dart';
import 'package:mtrust_api_guard/config/config.dart';
import 'package:mtrust_api_guard/doc_comparator/doc_ext.dart';

import 'package:mtrust_api_guard/doc_comparator/file_loader.dart';
import 'package:mtrust_api_guard/doc_comparator/parse_doc_file.dart';
import 'package:mtrust_api_guard/find_project_root.dart';
import 'package:mtrust_api_guard/logger.dart';
import 'package:path/path.dart';

class ChangelogGeneratorCommand extends Command {
  @override
  String get description => "Generate a changelog entry based on API changes";

  @override
  String get name => "changelog";

  static final ChangelogGeneratorCommand _instance =
      ChangelogGeneratorCommand._internal();

  factory ChangelogGeneratorCommand() => _instance;

  @override
  String get usage {
    return super.usage +
        "\n\n"
            "Generates a changelog entry based on API changes between versions and updates CHANGELOG.md.\n"
            "Uses the current package version from pubspec.yaml.\n";
  }

  ChangelogGeneratorCommand._internal() {
    argParser
      ..addOption(
        'root',
        abbr: 'r',
        help:
            'Root directory of the dart project. Defaults to auto detect from the current directory.',
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
      ..addFlag(
        'update',
        abbr: 'u',
        help: 'Update the CHANGELOG.md file',
        defaultsTo: true,
      );
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

      logger.info('Comparing documentation files to generate changelog...');
      final apiChanges = parseDocComponentsFile(baseContent).compareTo(
        parseDocComponentsFile(newContent),
      );

      // Generate changelog
      final changelogGenerator = ChangelogGenerator(
        apiChanges: apiChanges,
        projectRoot: rootDir,
      );

      if (argResults['update'] as bool) {
        await changelogGenerator.updateChangelogFile();
      } else {
        final changelogEntry =
            await changelogGenerator.generateChangelogEntry();
        print('\n$changelogEntry');
      }
    } catch (e, stack) {
      logger.err('An error occurred: \n$e');
      logger.err('Stack trace: $stack');
      exit(1);
    }
  }
}
