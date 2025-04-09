import 'dart:io';

import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:mtrust_api_guard/doc_generator/find_project_root.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

Future<Set<String>> detectExclusions(String path) async {
  final root = await findProjectRoot(path);

  final analysisOptions = File('${root.path}/analysis_options.yaml');

  final exclusions = <String>{};

  if (!analysisOptions.existsSync()) {
    print(
        'analysis_options.yaml not found in ${root.path}. No files will be excluded.');
  } else {
    final analysisOptionsContent = analysisOptions.readAsStringSync();
    final yaml = loadYaml(analysisOptionsContent);

    final exclude = yaml['analyzer']['exclude'] as YamlList?;

    if (exclude != null) {
      for (final path in exclude) {
        var pattern = Glob(path);
        for (final file in pattern.listSync()) {
          exclusions.add(normalize(file.path));
        }
      }
    }
  }

  return exclusions;
}
