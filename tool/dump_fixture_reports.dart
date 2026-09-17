// Prints what api_guard produces for the test fixtures, as markdown.
//
// CI appends this to the job summary, so every pull request shows the tool's
// actual output on our own examples: the API diff between consecutive fixture
// versions, the dead code each transition introduces, the full dead code
// picture per version, and the dead code on the package layout fixture. Run it
// the same way locally:
//
//   dart run tool/dump_fixture_reports.dart

import 'dart:io';

import 'package:mtrust_api_guard/dead_code/dead_code_delta.dart';
import 'package:mtrust_api_guard/dead_code/dead_code_finder.dart';
import 'package:mtrust_api_guard/dead_code/dead_code_report.dart';
import 'package:mtrust_api_guard/logger.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import '../test/helpers/fixture_package.dart';

/// The fixtures, oldest first. Consecutive pairs get diffed.
const _fixtures = ['app_v100', 'app_v101', 'app_v110', 'app_v200'];

/// Not a version of the others, so it gets a report of its own rather than a
/// place in the diffs.
const _layoutFixture = 'dead_code_layout';

/// What each fixture is set up to demonstrate.
const _notes = <String, String>{
  'app_v100':
      'Entry point `lib/src/api.dart`. `lib/src/internal.dart` and '
      '`lib/src/dead_code_cases.dart` sit outside the closure.',
  'app_v101': 'Entry point moves to `lib/main.dart`, which re-exports `lib/src/api.dart`.',
  'app_v110': 'Everything is exported.',
  'app_v200': 'Carries the magnitude_overrides examples.',
  _layoutFixture:
      'Entry point `lib/layout.dart`. What a real package layout brings: an '
      '`example/` with a pubspec of its own, generated parts that '
      '`analyzer.exclude` hides, a conditional export, and exported code with '
      'private members and a private implementation. The dead findings are '
      'planted: a private helper in one branch of the conditional export, a '
      'private method of `Api`, and `Draft`, which only its own generated part '
      'refers to.',
};

Future<void> main() async {
  logger.level = Level.error;

  final out = StringBuffer()
    ..writeln('## What api_guard produces for the test fixtures')
    ..writeln();

  final packages = <String, Directory>{};
  final apiDocs = <String, String>{};

  for (final fixture in _fixtures) {
    final source = Directory(p.join('test', 'fixtures', fixture));
    if (!source.existsSync()) continue;

    final package = await materializeFixturePackage(source, 'api_guard_test', initGit: true);
    packages[fixture] = package;

    final apiDoc = p.join(package.parent.path, '$fixture.json');
    final generated = await _runGuard(['generate', '-r', package.path, '--out', apiDoc]);
    if (File(apiDoc).existsSync()) {
      apiDocs[fixture] = apiDoc;
    } else {
      stderr.writeln('generate failed for $fixture: $generated');
    }
  }

  out
    ..writeln('### API changes between versions')
    ..writeln()
    ..writeln(
      '`compare`, run on consecutive fixtures. This is what feeds the '
      'API Changes section of a changelog.',
    )
    ..writeln();

  for (var i = 0; i + 1 < _fixtures.length; i++) {
    final from = _fixtures[i];
    final to = _fixtures[i + 1];
    if (!apiDocs.containsKey(from) || !apiDocs.containsKey(to)) continue;

    out
      ..writeln('<details><summary><code>$from</code> → <code>$to</code></summary>')
      ..writeln();

    final diff = await _runGuard(['compare', '--base-ref', apiDocs[from]!, '--new-ref', apiDocs[to]!]);
    out
      ..writeln(diff.trim().isEmpty ? 'No API changes.' : diff.trim())
      ..writeln()
      ..writeln('</details>')
      ..writeln();
  }

  out
    ..writeln('### Dead code introduced between versions')
    ..writeln()
    ..writeln(
      '`dead-code --base-ref`, the delta a reviewer would see on a pull '
      'request. Pre-existing findings are counted, not listed.',
    )
    ..writeln();

  final reports = <String, DeadCodeReport>{};
  for (final entry in packages.entries) {
    reports[entry.key] = await DeadCodeFinder(root: entry.value).run();
  }

  for (var i = 0; i + 1 < _fixtures.length; i++) {
    final from = _fixtures[i];
    final to = _fixtures[i + 1];
    final base = reports[from];
    final head = reports[to];
    if (base == null || head == null) continue;

    final delta = diffDeadCode(base: base, head: head, baseRef: from);
    final markdown = DeadCodeDeltaFormatter(delta, markdownHeaderLevel: 5).formatMarkdown();

    out
      ..writeln(
        '<details><summary><code>$from</code> → <code>$to</code> — '
        '${delta.introduced.length} added, ${delta.resolved.length} resolved</summary>',
      )
      ..writeln()
      ..writeln(markdown.isEmpty ? 'No change in dead code.' : markdown.trim())
      ..writeln()
      ..writeln('</details>')
      ..writeln();
  }

  out
    ..writeln('### Dead code per version')
    ..writeln()
    ..writeln('`dead-code`, the full picture for each fixture.')
    ..writeln();

  for (final fixture in _fixtures) {
    final report = reports[fixture];
    if (report != null) _writeReport(out, fixture, report);
  }

  out
    ..writeln('### Dead code on a package layout')
    ..writeln()
    ..writeln('`dead-code` on `test/fixtures/$_layoutFixture`.')
    ..writeln();

  final layout = await materializeFixturePackage(Directory(p.join('test', 'fixtures', _layoutFixture)), _layoutFixture);
  packages[_layoutFixture] = layout;
  _writeReport(out, _layoutFixture, await DeadCodeFinder(root: layout).run());

  for (final package in packages.values) {
    if (package.parent.existsSync()) package.parent.deleteSync(recursive: true);
  }

  stdout.write(out);
}

/// One fixture's full dead code report, collapsed under a count.
void _writeReport(StringBuffer out, String fixture, DeadCodeReport report) {
  final markdown = DeadCodeFormatter(report, markdownHeaderLevel: 5).formatMarkdown();

  out
    ..writeln(
      '<details><summary><code>$fixture</code> — '
      '${report.dead.length} dead, ${report.apiSurface.length} exported and '
      'unreferenced</summary>',
    )
    ..writeln()
    ..writeln(_notes[fixture] ?? '')
    ..writeln()
    ..writeln(markdown.isEmpty ? 'Nothing to report.' : markdown.trim())
    ..writeln();

  if (report.apiSurface.isNotEmpty) {
    out.writeln('Exported and unreferenced inside the package, so not dead:');
    out.writeln();
    for (final finding in report.apiSurface) {
      out.writeln('- `${finding.qualifiedName}` — ${finding.kind.label}, `${finding.filePath}`');
    }
    out.writeln();
  }

  out
    ..writeln('</details>')
    ..writeln();
}

/// Runs the CLI and returns its output with the startup banner removed.
Future<String> _runGuard(List<String> args) async {
  final result = await Process.run('dart', [
    'run',
    'bin/mtrust_api_guard.dart',
    args.first,
    '--silent',
    ...args.skip(1),
  ]);

  final lines = result.stdout.toString().split('\n');
  final bannerEnd = lines.lastIndexWhere((line) => line.contains('mtrust_api_guard version:'));
  return lines.skip(bannerEnd + 1).join('\n');
}
