import 'package:collection/collection.dart';
import 'package:mtrust_api_guard/dead_code/dead_code_report.dart';

/// The parts of a markdown report that the snapshot and the delta render the
/// same way.
abstract class DeadCodeMarkdown {
  const DeadCodeMarkdown({this.markdownHeaderLevel = 1, this.fileUrlBuilder});

  /// Depth of the section heading, so a report can be nested under whatever
  /// the caller already wrote.
  final int markdownHeaderLevel;

  /// Turns a path relative to the package root into a link, when the caller
  /// knows where the tree is browsable.
  final String? Function(String filePath)? fileUrlBuilder;

  String get heading => '#' * markdownHeaderLevel;

  /// Plain text, for a terminal.
  String format();

  /// Markdown for a PR comment. Empty when there is nothing to say, so a clean
  /// pull request carries no line about it.
  String formatMarkdown();

  /// What was found, for `--format json`.
  Map<String, dynamic> toJson();

  static String plural(int count, String singular, String plural) => count == 1 ? singular : plural;

  /// `1 declaration`, `2 declarations`.
  static String declarations(int count) => '$count ${plural(count, 'declaration', 'declarations')}';

  /// What the dead [findings] listed below it have in common. A delta says in
  /// [added] since when they are there.
  String describeDead(List<DeadDeclaration> findings, {String added = ''}) =>
      '${declarations(findings.length)} nothing live refers to, ${added}and outside the export closure '
      'so no consumer can reach ${plural(findings.length, 'it', 'them')}.';

  /// Findings by file, files in path order and findings in line order.
  Map<String, List<DeadDeclaration>> groupByFile(List<DeadDeclaration> declarations) {
    final grouped = groupBy(declarations, (DeadDeclaration d) => d.filePath);
    final sortedKeys = grouped.keys.toList()..sort();
    return {for (final key in sortedKeys) key: grouped[key]!..sort((a, b) => a.line.compareTo(b.line))};
  }

  /// A bold file heading, linked when [fileUrlBuilder] is given, followed by
  /// one bullet per finding under it.
  void writeFindingsByFile(StringBuffer buffer, List<DeadDeclaration> findings) {
    for (final entry in groupByFile(findings).entries) {
      final link = fileUrlBuilder?.call(entry.key);
      buffer
        ..writeln('**${link != null ? '[${entry.key}]($link)' : '`${entry.key}`'}**')
        ..writeln();
      for (final finding in entry.value) {
        buffer.writeln('- `${finding.qualifiedName}` — ${finding.kind.label}, line ${finding.line}');
      }
      buffer.writeln();
    }
  }

  /// A collapsed block, for the bucket that is context rather than something
  /// to act on.
  void writeDetails(StringBuffer buffer, String summary, List<String> lines) {
    buffer
      ..writeln('<details><summary>$summary</summary>')
      ..writeln();
    lines.forEach(buffer.writeln);
    buffer
      ..writeln()
      ..writeln('</details>')
      ..writeln();
  }
}

/// Renders a [DeadCodeReport] as plain text or as markdown for a PR comment.
class DeadCodeFormatter extends DeadCodeMarkdown {
  const DeadCodeFormatter(this.report, {super.markdownHeaderLevel, super.fileUrlBuilder});

  final DeadCodeReport report;

  @override
  Map<String, dynamic> toJson() => report.toJson();

  /// Plain text, one finding per line, grouped by file.
  @override
  String format() {
    final buffer = StringBuffer();

    if (report.dead.isEmpty) {
      buffer.writeln('No dead code found.');
    } else {
      for (final entry in groupByFile(report.dead).entries) {
        buffer.writeln(entry.key);
        for (final decl in entry.value) {
          buffer.writeln(
            '  ${decl.line}:${decl.column}  ${decl.kind.label.padRight(13)} '
            '${decl.qualifiedName}  (${decl.isPrivate ? 'private' : 'public'})',
          );
        }
        buffer.writeln();
      }
    }

    if (report.docOnly.isNotEmpty) {
      buffer.writeln('Referenced only from doc comments, not counted as dead:');
      for (final entry in groupByFile(report.docOnly).entries) {
        buffer.writeln(entry.key);
        for (final decl in entry.value) {
          buffer.writeln('  ${decl.line}:${decl.column}  ${decl.kind.label} ${decl.qualifiedName}');
        }
      }
      buffer.writeln();
    }

    buffer.writeln(_summaryLine());

    return buffer.toString();
  }

  /// Markdown section suitable for appending to a PR comment. Returns an empty
  /// string when there is nothing to warn about.
  @override
  String formatMarkdown() {
    if (report.isEmpty) return '';

    final buffer = StringBuffer()
      ..writeln()
      ..writeln('$heading ⚠️ Dead code')
      ..writeln();

    if (report.dead.isNotEmpty) {
      buffer
        ..writeln(describeDead(report.dead))
        ..writeln();
      writeFindingsByFile(buffer, report.dead);
    }

    if (report.docOnly.isNotEmpty) {
      writeDetails(buffer, '${report.docOnly.length} referenced only from doc comments', [
        for (final decl in report.docOnly) '- `${decl.qualifiedName}` — `${decl.filePath}`, line ${decl.line}',
      ]);
    }

    buffer.writeln('<sub>${_summaryLine()}</sub>');

    return buffer.toString();
  }

  String _summaryLine() {
    final parts = [
      'Scanned ${report.filesScanned} ${DeadCodeMarkdown.plural(report.filesScanned, 'file', 'files')}',
      'checked ${DeadCodeMarkdown.declarations(report.declarationsChecked)}',
      '${report.dead.length} dead',
    ];
    if (report.apiSurface.isNotEmpty) {
      parts.add('${report.apiSurface.length} unreferenced but exported');
    }
    if (report.docOnly.isNotEmpty) {
      parts.add('${report.docOnly.length} doc-only');
    }
    return '${parts.join(', ')}.';
  }
}
