import 'dart:io';

import 'package:yaml/yaml.dart';

/// Configuration of the api guard. Can be placed in the analysis_options.yaml
/// file.
class ApiGuardConfig {
  /// Files to include in the API documentation.
  final Set<String> include;

  /// Files to exclude from the API documentation.
  final Set<String> exclude;

  /// File to write the API documentation to.
  final String docFile;

  ApiGuardConfig({
    required this.include,
    required this.exclude,
    required this.docFile,
  });

  factory ApiGuardConfig.defaultConfig() {
    return ApiGuardConfig(
      include: {'lib/**.dart'},
      exclude: {'api_guard/documentation.g.dart'},
      docFile: 'api_guard/documentation.g.dart',
    );
  }

  factory ApiGuardConfig.fromYaml(File analysisOptionsFile) {
    assert(analysisOptionsFile.existsSync(), 'analysis_options.yaml not found');

    YamlMap yaml;
    try {
      yaml = loadYaml(analysisOptionsFile.readAsStringSync());
    } catch (e) {
      throw Exception('Failed to parse analysis_options.yaml: $e');
    }

    final apiGuard = yaml['api_guard'] as YamlMap?;

    if (apiGuard == null) {
      return ApiGuardConfig.defaultConfig();
    }

    Set<String> exclude = {};
    Set<String> include = {};

    if (yaml["analyzer"] != null) {
      if (yaml["analyzer"]["exclude"] != null) {
        exclude = (yaml["analyzer"]["exclude"] as YamlList)
            .map((e) => e.toString())
            .toSet();
      }
    }

    if (apiGuard["exclude"] != null) {
      exclude.addAll(
        (apiGuard["exclude"] as YamlList).map((e) => e.toString()).toSet(),
      );
    }

    if (apiGuard["include"] != null) {
      include = (apiGuard["include"] as YamlList)
          .map(
            (e) => e.toString(),
          )
          .toSet();
    } else {
      include = ApiGuardConfig.defaultConfig().include.toSet();
    }

    return ApiGuardConfig(
      include: include,
      exclude: exclude,
      docFile: apiGuard['docFile'] ?? ApiGuardConfig.defaultConfig().docFile,
    );
  }
}
