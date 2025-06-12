import 'dart:io';

import 'package:args/args.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:mtrust_api_guard/config/config.dart';
import 'package:mtrust_api_guard/find_project_root.dart';
import 'package:mtrust_api_guard/logger.dart';
import 'package:path/path.dart';

(Set<String> files, Set<String> exclusions, File outputFile)
    evaluateTargetFiles(ArgResults argResults) {
  final root = argResults['root'] as String?;
  late Directory rootDir;

  // Find the root directory to base the analysis on
  if (root == null) {
    rootDir = findProjectRoot(Directory.current.path);

    if (rootDir.path != Directory.current.path) {
      logger.info("Changing root directory to $rootDir");
    }
  } else {
    rootDir = Directory(root);

    if (!rootDir.existsSync()) {
      logger.err('Root directory does not exist: $root');
      exit(1);
    }
  }

  // Detect the files to analyze

  final analysisOptionsFile = File('$rootDir.path/analysis_options.yaml');

  ApiGuardConfig config;

  if (analysisOptionsFile.existsSync()) {
    config = ApiGuardConfig.fromYaml(
      analysisOptionsFile,
    );
  } else {
    config = ApiGuardConfig.defaultConfig();
  }

  final targetFiles = <String>{};

  for (final include in config.include) {
    targetFiles.addAll(
      Glob(include).listSync(root: rootDir.path).map((e) => normalize(e.path)),
    );
  }

  final exclusions = <String>{};
  for (final exclude in config.exclude) {
    exclusions.addAll(
      Glob(exclude).listSync(root: rootDir.path).map((e) => normalize(e.path)),
    );
  }

  final outputFile = File(join(rootDir.path, config.docFile));

  return (targetFiles.difference(exclusions), exclusions, outputFile);
}
