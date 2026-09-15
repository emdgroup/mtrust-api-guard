import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mtrust_api_guard/api_guard_command_mixin.dart';
import 'package:mtrust_api_guard/dead_code/dead_code_report.dart';
import 'package:mtrust_api_guard/dead_code/dead_code_scan.dart';
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
      ..addOption('base-url', help: 'Base URL for file links (e.g. https://github.com/org/repo/blob/main)')
      ..addOption(
        'base-ref',
        abbr: 'b',
        help:
            'Report only what changed since this git ref, rather than everything '
            'currently dead. Costs a second analysis pass.',
      );
  }

  String get format => argResults?['format'] as String;

  String? get out => argResults?['out'] as String?;

  String? get baseUrl => argResults?['base-url'] as String?;

  String? get baseRef => argResults?['base-ref'] as String?;

  @override
  FutureOr? run() async {
    final scan = await scanDeadCode(dartRoot: root, gitRoot: Directory.current, baseRef: baseRef, baseUrl: baseUrl);
    final output = _render(scan, format);

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

  String _render(DeadCodeMarkdown scan, String as) => switch (as) {
    'json' => const JsonEncoder.withIndent('  ').convert(scan.toJson()),
    'markdown' => scan.formatMarkdown(),
    _ => scan.format(),
  };
}
