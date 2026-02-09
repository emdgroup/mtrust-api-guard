import 'dart:io';

import 'package:mtrust_api_guard/logger.dart';
import 'package:yaml/yaml.dart';

import 'package:mtrust_api_guard/config/magnitude_override.dart';

/// Configuration of the api guard. Can be placed in the analysis_options.yaml
/// file.
class ApiGuardConfig {
  /// Files to include in the API documentation.
  final Set<String> include;

  /// Files to exclude from the API documentation.
  final Set<String> exclude;

  /// Entry points for the API analysis.
  final List<String> entryPoints;

  /// Whether to generate a badge for the version.
  final bool generateBadge;

  /// Overrides for the magnitude of changes.
  final List<MagnitudeOverride> magnitudeOverrides;

  ApiGuardConfig({
    required this.include,
    required this.exclude,
    this.entryPoints = const [],
    required this.generateBadge,
    this.magnitudeOverrides = const [],
  });

  factory ApiGuardConfig.defaultConfig() {
    return ApiGuardConfig(
      include: {'lib/**.dart'},
      exclude: {},
      entryPoints: [],
      generateBadge: true,
      magnitudeOverrides: [],
    );
  }

  ApiGuardConfig copyWith({
    bool? generateBadge,
    Set<String>? include,
    Set<String>? exclude,
    List<String>? entryPoints,
    List<MagnitudeOverride>? magnitudeOverrides,
  }) {
    return ApiGuardConfig(
      include: include ?? this.include,
      exclude: exclude ?? this.exclude,
      entryPoints: entryPoints ?? this.entryPoints,
      generateBadge: generateBadge ?? this.generateBadge,
      magnitudeOverrides: magnitudeOverrides ?? this.magnitudeOverrides,
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

    final magnitudeOverrides = (apiGuard['magnitude_overrides'] as YamlList?)
            ?.map((e) => MagnitudeOverride.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [];

    logger.info('Loaded ${magnitudeOverrides.length} magnitude overrides from analysis_options.yaml');

    return defaultConfig.copyWith(
      include: (apiGuard["include"] as YamlList?)?.map((e) => e.toString()).toSet(),
      exclude: (apiGuard["exclude"] as YamlList?)?.map((e) => e.toString()).toSet(),
      entryPoints: (apiGuard["entry_points"] as YamlList?)?.map((e) => e.toString()).toList(),
      generateBadge: apiGuard['generateBadge'],
      magnitudeOverrides: magnitudeOverrides,
    );
  }

  /// Loads the configuration from the `analysis_options.yaml` file in the
  /// provided [root] directory. Returns the default configuration if the file
  /// does not exist or if the `api_guard` section is missing.
  static ApiGuardConfig load(Directory root) {
    final configFile = File('${root.path}/analysis_options.yaml');
    if (configFile.existsSync()) {
      try {
        return ApiGuardConfig.fromYaml(configFile);
      } catch (e) {
        // We can't use the logger here easily without creating a dependency
        // loop or passing it in. It's safe to throw or print if needed,
        // but for now let's just return default and maybe log outside.
        // Actually, let's rethrow or let the caller handle.
        // But to keep it simple as a helper:
        logger.warn('Warning: Failed to load analysis_options.yaml: $e');
        return ApiGuardConfig.defaultConfig();
      }
    }
    return ApiGuardConfig.defaultConfig();
  }
}
