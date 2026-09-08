import 'dart:io';

import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

/// Detects files to be excluded from API documentation generation based on analysis_options.yaml
/// This function reads the analysis_options.yaml file at the specified [root] directory
/// and extracts file exclusion patterns from the 'analyzer.exclude' section.
/// It returns a Set of normalized file paths that match the exclusion patterns.
///
/// If the analysis_options.yaml file doesn't exist, has no `analyzer` section
/// or no exclusions in it, an empty Set is returned.

Set<String> detectExclusionsFromAnalyzer(String root) {
  final analysisOptions = File('$root/analysis_options.yaml');

  if (!analysisOptions.existsSync()) {
    return <String>{};
  }

  final yaml = loadYaml(analysisOptions.readAsStringSync());
  if (yaml is! Map) {
    return <String>{};
  }

  final analyzerSection = yaml['analyzer'];
  if (analyzerSection is! Map) {
    return <String>{};
  }

  final exclude = analyzerSection['exclude'];
  if (exclude is! YamlList) {
    return <String>{};
  }

  final exclusions = <String>{};
  for (final path in exclude) {
    for (final file in Glob(path.toString()).listSync(root: root)) {
      exclusions.add(normalize(absolute(file.path)));
    }
  }

  return exclusions;
}

/// Detects files to be excluded from API documentation generation based on analysis_options.yaml
/// This function reads the analysis_options.yaml file at the specified [root] directory
/// and extracts file exclusion patterns from the 'api_guard.exclude' section.
/// It returns a Set of normalized file paths that match the exclusion patterns.
///
/// If the analysis_options.yaml file doesn't exist or doesn't contain exclusion patterns,
/// an empty Set is returned
///
/// Example analysis_options.yaml:
/// ```yaml
/// api_guard:
///   exclude:
///     - "**/*.g.dart"
///     - "lib/generated/**"
/// ```
///
Set<String> detectExclusionsFromConfig(String root) {
  final config = File('$root/analysis_options.yaml');

  if (!config.existsSync()) {
    return <String>{};
  }

  final yaml = loadYaml(config.readAsStringSync());

  final apiGuard = yaml['api_guard'];

  if (apiGuard == null) {
    return <String>{};
  }

  if (apiGuard is String) {
    return <String>{};
  }

  if (apiGuard is YamlList) {
    final exclusions = <String>{};
    for (final item in apiGuard) {
      if (item is String) {
        exclusions.addAll(Glob(item).listSync().map((e) => normalize(e.path)));
      }
    }
    return exclusions;
  }
  return {};
}
