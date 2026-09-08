import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mtrust_api_guard/api_guard_command_mixin.dart';
import 'package:mtrust_api_guard/dead_code/dead_code_finder.dart';
import 'package:mtrust_api_guard/dead_code/dead_code_report.dart';
import 'package:mtrust_api_guard/logger.dart';

class DeadCodeCommand extends Command with ApiGuardCommandMixinWithRoot {
  @override
  String get description => 'Report declarations nothing references and no consumer can reach';

  @override
  String get name => 'dead-code';

  DeadCodeCommand() {
    argParser
      ..addOption('format', abbr: 'f', help: 'Output format', defaultsTo: 'text', allowed: ['text', 'markdown', 'json'])
      ..addOption('out', help: 'Write the report to a file')
      ..addOption('base-url', help: 'Base URL for file links (e.g. https://github.com/org/repo/blob/main)');
  }

  String get format => argResults?['format'] as String;

  String? get out => argResults?['out'] as String?;

  String? get baseUrl => argResults?['base-url'] as String?;

  @override
  FutureOr? run() async {
    final report = await DeadCodeFinder(root: root).run();

    final formatter = DeadCodeFormatter(report, fileUrlBuilder: baseUrl == null ? null : (path) => '$baseUrl/$path');

    final output = switch (format) {
      'json' => const JsonEncoder.withIndent('  ').convert(report.toJson()),
      'markdown' => formatter.formatMarkdown(),
      _ => formatter.format(),
    };

    if (out != null) {
      final file = File(out!);
      if (!file.existsSync()) file.createSync(recursive: true);
      await file.writeAsString(output);
      logger.success('Wrote dead code report to $out');
    } else {
      // ignore: avoid_print
      print(output);
    }
  }
}
