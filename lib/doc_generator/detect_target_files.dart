import 'dart:io';

import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

Set<String> defaultFiles(String root) {
  final files = <String>{};

  final pattern = Glob('lib/**.dart');

  for (final file in pattern.listSync(root: root)) {
    files.add(normalize(file.path));
  }

  return files;
}

Set<String> detectTargetFiles(String root) {
  final analysisOptions = File('$root/analysis_options.yaml');

  if (!analysisOptions.existsSync()) {
    return defaultFiles(root);
  }

  final yaml = loadYaml(analysisOptions.readAsStringSync());

  final apiGuard = yaml['api_guard'] as YamlMap?;

  if (apiGuard == null) {
    return defaultFiles(root);
  }

  final include = apiGuard['include'];

  if (include == null) {
    return defaultFiles(root);
  }

  final targetFiles = <String>{};

  // Include parameter is a list of strings

  if (include is YamlList) {
    for (final item in include) {
      targetFiles.addAll(
          Glob(item).listSync(root: root).map((e) => normalize(e.path)));
    }
  }

  // Include parameter is a single string

  if (include is String) {
    targetFiles.addAll(
        Glob(include).listSync(root: root).map((e) => normalize(e.path)));
  }

  return targetFiles;
}
