// ignore_for_file: avoid_print

import 'dart:io';

import 'package:collection/collection.dart';
import 'package:mtrust_api_guard/doc_comparator/api_change_formatter.dart';
import 'package:mtrust_api_guard/doc_comparator/doc_comparator_command.dart';
import 'package:mtrust_api_guard/doc_comparator/doc_ext.dart';

import 'package:mtrust_api_guard/doc_comparator/file_loader.dart';
import 'package:mtrust_api_guard/doc_comparator/parse_doc_file.dart';
import 'package:mtrust_api_guard/logger.dart';
import 'package:mtrust_api_guard/mtrust_api_guard.dart';
import 'package:mtrust_api_guard/config/config.dart';
import 'package:mtrust_api_guard/find_project_root.dart';
import 'package:path/path.dart';

void main(List<String> args) async {
  final cmd = DocComparatorCommand();
  final argResults = cmd.argResults ?? cmd.argParser.parse(args);

  final magnitudes = (argResults['magnitudes'] as List<String>)
      .map((e) => ApiChangeMagnitude.values.firstWhereOrNull(
            (element) => element.toString().contains(e),
          ))
      .whereType<ApiChangeMagnitude>()
      .toSet();

  // Load config and determine doc file path
  final rootDir = findProjectRoot(Directory.current.path);
  final analysisOptionsFile = File(join(rootDir.path, 'analysis_options.yaml'));
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
    final formatter = ApiChangeFormatter(apiChanges, magnitudes: magnitudes);
    logger.info(formatter.highestMagnitudeText);
    logger.info(formatter.format());
  } catch (e, stack) {
    logger.err('An error occurred: \\n$e');
    logger.err('Stack trace: $stack');
    exit(1);
  }
}
