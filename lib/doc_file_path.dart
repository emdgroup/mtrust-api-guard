import 'dart:io';

import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

File getDocFile(String root) {
  final defaultDocFile = File(join(root, 'lib', 'documentation.g.dart'));
  final analysisOptions = File('$root/analysis_options.yaml');

  if (!analysisOptions.existsSync()) {
    return defaultDocFile;
  }

  final yaml = loadYaml(analysisOptions.readAsStringSync());

  final apiGuard = yaml['api_guard'] as YamlMap?;

  if (apiGuard == null) {
    return defaultDocFile;
  }

  final documentationFile = apiGuard['documentation_file'] as String?;

  if (documentationFile == null) {
    return defaultDocFile;
  }

  return File(join(root, documentationFile));
}
