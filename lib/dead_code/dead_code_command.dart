import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mtrust_api_guard/api_guard_command_mixin.dart';
import 'package:mtrust_api_guard/dead_code/dead_code_report.dart';
import 'package:mtrust_api_guard/dead_code/dead_code_scan.dart';
import 'package:mtrust_api_guard/logger.dart';
import 'package:path/path.dart';

class DeadCodeCommand extends Command with ApiGuardCommandMixinWithRoot {
  @override
  String get description => 'Report declarations nothing live refers to and no consumer can reach';

  @override
  String get name => 'dead-code';

  DeadCodeCommand() {
    argParser
      ..addOption('format', abbr: 'f', help: 'Output format', defaultsTo: 'text', allowed: ['text', 'markdown', 'json'])
      ..addMultiOption(
        'out',
        help:
            'Write the report to a file. Repeat it to write several formats '
            'from one scan, in which case the format comes from each file '
            'extension (.json, .md) and falls back to --format.',
      )
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

  List<String> get out => argResults?['out'] as List<String>;

  String? get baseUrl => argResults?['base-url'] as String?;

  String? get baseRef => argResults?['base-ref'] as String?;

  @override
  FutureOr? run() async {
    // One scan, however many renderings of it are asked for. With --base-ref
    // that scan is two analyzer passes and a worktree, so asking for json and
    // markdown separately would pay for it twice.
    final scan = await scanDeadCode(dartRoot: root, gitRoot: Directory.current, baseRef: baseRef, baseUrl: baseUrl);

    if (out.isEmpty) {
      // ignore: avoid_print
      print(_render(scan, format));
      return null;
    }

    for (final path in out) {
      final file = File(path);
      if (!file.existsSync()) file.createSync(recursive: true);
      await file.writeAsString(_render(scan, _formatFor(path)));
      logger.success('Wrote dead code report to $path');
    }
    return null;
  }

  String _render(DeadCodeMarkdown scan, String as) => switch (as) {
    'json' => const JsonEncoder.withIndent('  ').convert(scan.toJson()),
    'markdown' => scan.formatMarkdown(),
    _ => scan.format(),
  };

  /// What to write into [path], taken from its extension so that several
  /// `--out` files can come out of one scan. Anything unrecognised is left to
  /// `--format`.
  String _formatFor(String path) => switch (extension(path)) {
    '.json' => 'json',
    '.md' || '.markdown' => 'markdown',
    _ => format,
  };
}
