import 'dart:io';

import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

class PubspecUtils {
  static Version getVersion(String pubspecContent) {
    final pubspec = loadYaml(pubspecContent);
    final version = pubspec['version'];
    return Version.parse(version);
  }

  static String getPackageName(String pubspecContent) {
    final pubspec = loadYaml(pubspecContent);
    return pubspec['name'] as String;
  }

  static Future<void> setVersion(File pubspec, Version version) async {
    final pubspecEditor = await _getPubspec(pubspec.path);
    pubspecEditor.update(["version"], version.toString());
    await pubspec.writeAsString(pubspecEditor.toString());
  }

  static Future<YamlEditor> _getPubspec(String filePath) async {
    final pubspecFile = File(filePath);
    if (!pubspecFile.existsSync()) {
      throw Exception('pubspec.yaml not found at ${pubspecFile.path}');
    }
    final pubspecContent = await pubspecFile.readAsString();
    final pubspec = YamlEditor(pubspecContent);
    return pubspec;
  }

  /// Extracts the constraint prefix from a version constraint string
  /// Returns the prefix (^, >=, <=, >, <, ~) or '^' as default
  static String _extractConstraintPrefix(String constraint) {
    if (constraint.startsWith('>=')) return '>=';
    if (constraint.startsWith('<=')) return '<=';
    if (constraint.startsWith('^')) return '^';
    if (constraint.startsWith('~')) return '~';
    if (constraint.startsWith('>')) return '>';
    if (constraint.startsWith('<')) return '<';
    return '^';
  }

  /// Creates a new version constraint preserving the original constraint prefix
  static String _createConstraint(String oldConstraint, Version newVersion) {
    try {
      VersionConstraint.parse(oldConstraint);
      final prefix = _extractConstraintPrefix(oldConstraint);
      return '$prefix${newVersion.toString()}';
    } catch (_) {
      // Invalid constraint, default to ^
      return '^${newVersion.toString()}';
    }
  }

  /// Updates a workspace dependency version while maintaining constraint format
  /// Updates both dependencies and dev_dependencies sections
  static Future<void> updateWorkspaceDependency(
    File pubspec,
    String packageName,
    Version newVersion,
  ) async {
    final pubspecEditor = await _getPubspec(pubspec.path);
    final pubspecContent = await pubspec.readAsString();
    final pubspecYaml = loadYaml(pubspecContent) as Map;

    // Helper function to update dependency in a section
    void updateDependencyInSection(String sectionName) {
      final section = pubspecYaml[sectionName];
      if (section == null || section is! Map) {
        return;
      }

      final dependency = section[packageName];
      if (dependency == null) {
        return;
      }

      if (dependency is String) {
        final newConstraint = _createConstraint(dependency, newVersion);
        pubspecEditor.update([sectionName, packageName], newConstraint);
      } else if (dependency is Map) {
        // For path dependencies or other complex formats, update version if present
        if (dependency.containsKey('version')) {
          final oldVersion = dependency['version'];
          if (oldVersion is String) {
            final newConstraint = _createConstraint(oldVersion, newVersion);
            pubspecEditor.update([sectionName, packageName, 'version'], newConstraint);
          }
        }
      } else {
        // Default to ^ constraint
        final newConstraint = '^${newVersion.toString()}';
        pubspecEditor.update([sectionName, packageName], newConstraint);
      }
    }

    // Update in dependencies section
    updateDependencyInSection('dependencies');

    // Update in dev_dependencies section
    updateDependencyInSection('dev_dependencies');

    await pubspec.writeAsString(pubspecEditor.toString());
  }

  /// Gets all dependencies (including dev_dependencies) from a pubspec file
  static Map<String, dynamic> getAllDependencies(String pubspecContent) {
    final pubspec = loadYaml(pubspecContent) as Map;
    final dependencies = <String, dynamic>{};

    if (pubspec.containsKey('dependencies') && pubspec['dependencies'] is Map) {
      dependencies.addAll(Map<String, dynamic>.from(pubspec['dependencies'] as Map));
    }

    if (pubspec.containsKey('dev_dependencies') && pubspec['dev_dependencies'] is Map) {
      dependencies.addAll(Map<String, dynamic>.from(pubspec['dev_dependencies'] as Map));
    }

    return dependencies;
  }
}
