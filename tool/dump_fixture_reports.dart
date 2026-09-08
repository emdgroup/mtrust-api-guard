// Prints what the dead code scan produces for each test fixture, as markdown.
//
// `generate` and `compare` have their fixture output checked in already, as
// test/fixtures/apiV100.json and test/fixtures/expected_compare_v100_v101.txt.
// The dead code scan has no such file, its tests assert on the findings
// structurally, so this is how you look at the report itself:
//
//   dart run tool/dump_fixture_reports.dart
//
// Nothing in CI runs this. It is here to be read by a person.

import 'dart:io';

import 'package:mtrust_api_guard/dead_code/dead_code_finder.dart';
import 'package:mtrust_api_guard/dead_code/dead_code_report.dart';
import 'package:mtrust_api_guard/logger.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

/// The fixtures worth showing, and what each one is there to demonstrate.
const _fixtures = <String, String>{
  'app_v100':
      'Entry point `lib/src/api.dart`. Everything it exports is API surface; '
      '`lib/src/internal.dart` and `lib/src/dead_code_cases.dart` are outside '
      'the closure.',
  'app_v101': 'Entry point `lib/main.dart`, which re-exports `lib/src/api.dart`.',
  'app_v110': 'Every declaration is exported, so nothing is dead.',
};

Future<void> main() async {
  // The scan is chatty by design; the report is the output here.
  logger.level = Level.error;

  final buffer = StringBuffer()
    ..writeln('## Dead code scan on the test fixtures')
    ..writeln()
    ..writeln('What `mtrust_api_guard dead-code` reports for each fixture.')
    ..writeln();

  for (final entry in _fixtures.entries) {
    final fixture = Directory(p.join('test', 'fixtures', entry.key));
    if (!fixture.existsSync()) {
      stderr.writeln('Skipping ${entry.key}: not found');
      continue;
    }

    final package = await _materialize(fixture);
    try {
      final report = await DeadCodeFinder(root: package).run();
      final formatter = DeadCodeFormatter(report, markdownHeaderLevel: 4);

      buffer
        ..writeln('### `${entry.key}`')
        ..writeln()
        ..writeln(entry.value)
        ..writeln();

      final markdown = formatter.formatMarkdown();
      buffer.writeln(markdown.isEmpty ? 'Nothing to report.' : markdown.trim());

      if (report.apiSurface.isNotEmpty) {
        buffer
          ..writeln()
          ..writeln(
            '<details><summary>${report.apiSurface.length} exported and '
            'unreferenced inside the package, so not dead</summary>',
          )
          ..writeln();
        for (final finding in report.apiSurface) {
          buffer.writeln('- `${finding.qualifiedName}` — ${finding.kind.label}, `${finding.filePath}`');
        }
        buffer
          ..writeln()
          ..writeln('</details>');
      }
      buffer.writeln();
    } finally {
      if (package.parent.existsSync()) package.parent.deleteSync(recursive: true);
    }
  }

  stdout.write(buffer);
}

/// Copies a fixture somewhere writable and resolves it, so the analyzer can
/// follow its `package:` imports.
Future<Directory> _materialize(Directory fixture) async {
  final temp = await Directory.systemTemp.createTemp('api_guard_fixture_report_');
  final target = Directory(p.join(temp.path, 'api_guard_test'))..createSync(recursive: true);

  await for (final entity in fixture.list(recursive: true)) {
    final destination = p.join(target.path, p.relative(entity.path, from: fixture.path));
    if (entity is File) {
      await File(destination).create(recursive: true);
      await entity.copy(destination);
    } else if (entity is Directory) {
      await Directory(destination).create(recursive: true);
    }
  }

  File(p.join(target.path, 'pubspec.yaml')).writeAsStringSync('''
name: api_guard_test
description: Fixture package, resolved so the scan can read it.
version: 1.0.0
publish_to: none

environment:
  sdk: ">=3.11.0 <4.0.0"
''');

  final result = await Process.run('dart', ['pub', 'get'], workingDirectory: target.path);
  if (result.exitCode != 0) {
    throw StateError('dart pub get failed in ${target.path}: ${result.stderr}');
  }

  return target;
}
