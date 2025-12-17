import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:collection/collection.dart';
import 'package:mtrust_api_guard/api_guard_command_mixin.dart';
import 'package:mtrust_api_guard/doc_comparator/api_change.dart';
import 'package:mtrust_api_guard/doc_comparator/api_change_formatter.dart';
import 'package:mtrust_api_guard/doc_comparator/doc_comparator.dart';
import 'package:mtrust_api_guard/doc_generator/git_utils.dart';
import 'package:mtrust_api_guard/logger.dart';

class DocComparatorCommand extends Command
    with ApiGuardCommandMixinWithBaseNew, ApiGuardCommandMixinWithRoot, ApiGuardCommandMixinWithCache {
  @override
  String get description => "Compare two API documentation files";

  @override
  String get name => "compare";

  static final DocComparatorCommand _instance = DocComparatorCommand._internal();

  factory DocComparatorCommand() => _instance;

  DocComparatorCommand._internal() {
    argParser.addMultiOption(
      'magnitudes',
      abbr: 'm',
      help: 'Show only changes with the specified magnitudes',
      defaultsTo: ['major', 'minor', 'patch'],
      allowed: ['major', 'minor', 'patch'],
    );
    argParser.addOption(
      'out',
      help: 'Write the comparison results to a file',
    );
    argParser.addOption(
      'base-url',
      help: 'Base URL for file links (e.g. https://github.com/org/repo/blob/v1.0.0)',
    );
  }

  String? get out {
    return argResults?['out'] as String?;
  }

  String? get baseUrl {
    return argResults?['base-url'] as String?;
  }

  Set<ApiChangeMagnitude> get magnitudes {
    final magnitudes = argResults?['magnitudes'] as List<String>;
    return magnitudes
        .map((e) => ApiChangeMagnitude.values.firstWhereOrNull(
              (element) => element.toString().contains(e),
            ))
        .whereType<ApiChangeMagnitude>()
        .toSet();
  }

  @override
  FutureOr? run() async {
    final changes = await compare(
      baseRef: baseRef ?? await GitUtils.getPreviousRef(Directory.current.path),
      newRef: newRef,
      dartRoot: root,
      gitRoot: Directory.current,
      cache: cache,
    );

    final formatter = ApiChangeFormatter(
      changes,
      magnitudes: magnitudes,
    );

    if (!formatter.hasRelevantChanges) {
      logger.info('No relevant changes detected');
      exit(0);
    }

    final formattedOutput = formatter.format();

    if (out != null) {
      if (!File(out!).existsSync()) {
        File(out!).createSync();
      }
      await File(out!).writeAsString(formattedOutput);
      logger.success('Wrote comparison results to $out');
    } else {
      // ignore: avoid_print
      print(formattedOutput);
    }
  }
}
