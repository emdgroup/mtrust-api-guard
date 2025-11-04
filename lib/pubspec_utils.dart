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
}
