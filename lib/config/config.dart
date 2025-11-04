import 'dart:io';

import 'package:yaml/yaml.dart';

/// Configuration of the api guard. Can be placed in the analysis_options.yaml
/// file.
class ApiGuardConfig {
  /// Files to include in the API documentation.
  final Set<String> include;

  /// Files to exclude from the API documentation.
  final Set<String> exclude;

  /// Whether to generate a badge for the version.
  final bool generateBadge;

  ApiGuardConfig({
    required this.include,
    required this.exclude,
    required this.generateBadge,
  });

  factory ApiGuardConfig.defaultConfig() {
    return ApiGuardConfig(
      include: {'lib/**.dart'},
      exclude: {},
      generateBadge: true,
    );
  }

  ApiGuardConfig copyWith({
    bool? generateBadge,
    Set<String>? include,
    Set<String>? exclude,
  }) {
    return ApiGuardConfig(
      include: include ?? this.include,
      exclude: exclude ?? this.exclude,
      generateBadge: generateBadge ?? this.generateBadge,
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

    final defaultConfig = ApiGuardConfig.defaultConfig();

    if (apiGuard == null) {
      return ApiGuardConfig.defaultConfig();
    }

    return defaultConfig.copyWith(
      include: (apiGuard["include"] as YamlList?)?.map((e) => e.toString()).toSet(),
      exclude: (apiGuard["exclude"] as YamlList?)?.map((e) => e.toString()).toSet(),
      generateBadge: apiGuard['generateBadge'],
    );
  }
}
