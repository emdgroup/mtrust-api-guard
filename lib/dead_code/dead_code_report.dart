import 'package:collection/collection.dart';

/// The kind of declaration a [DeadDeclaration] refers to.
enum DeadCodeKind {
  classKind('class'),
  mixinKind('mixin'),
  enumKind('enum'),
  extensionKind('extension'),
  extensionTypeKind('extension type'),
  typedefKind('typedef'),
  functionKind('function'),
  methodKind('method'),
  getterKind('getter'),
  setterKind('setter'),
  fieldKind('field'),
  variableKind('variable'),
  constructorKind('constructor'),
  enumValueKind('enum value');

  const DeadCodeKind(this.label);

  /// Human readable label used in reports.
  final String label;
}

/// A declaration that no code in the package references.
class DeadDeclaration {
  const DeadDeclaration({
    required this.name,
    required this.kind,
    required this.filePath,
    required this.line,
    required this.column,
    required this.isPrivate,
    this.container,
  });

  /// Simple (unqualified) name of the declaration.
  final String name;

  /// Enclosing declaration name (the class for a method), if any.
  final String? container;

  final DeadCodeKind kind;

  /// Path relative to the package root, using `/` separators.
  final String filePath;

  /// One-based line of the declaration's name.
  final int line;

  /// One-based column of the declaration's name.
  final int column;

  /// Whether the declaration is library-private (name starts with `_`).
  final bool isPrivate;

  /// `Container.name` when the declaration has an enclosing type, `name`
  /// otherwise.
  String get qualifiedName => container == null ? name : '$container.$name';

  Map<String, dynamic> toJson() => {
    'name': name,
    'qualifiedName': qualifiedName,
    'kind': kind.label,
    'file': filePath,
    'line': line,
    'column': column,
    'isPrivate': isPrivate,
    if (container != null) 'container': container,
  };

  @override
  String toString() => '$filePath:$line:$column ${kind.label} $qualifiedName';
}

/// The result of a dead code scan.
class DeadCodeReport {
  const DeadCodeReport({
    required this.dead,
    required this.apiSurface,
    required this.docOnly,
    required this.filesScanned,
    required this.declarationsChecked,
  });

  /// Declarations nothing references and that no consumer can reach, because
  /// they are not part of the package's export closure.
  final List<DeadDeclaration> dead;

  /// Declarations nothing inside the package references, but that the package
  /// exports. A consumer can call these, so they are reported separately and
  /// never counted as dead.
  final List<DeadDeclaration> apiSurface;

  /// Declarations referenced only from doc comments. A `[Foo]` link resolves
  /// to a real element, but a comment mentioning something is not code using
  /// it.
  final List<DeadDeclaration> docOnly;

  /// Number of files that contributed declarations or references.
  final int filesScanned;

  /// Number of declarations that were checked for references.
  final int declarationsChecked;

  bool get isEmpty => dead.isEmpty && docOnly.isEmpty;

  Map<String, dynamic> toJson() => {
    'summary': {
      'filesScanned': filesScanned,
      'declarationsChecked': declarationsChecked,
      'deadCount': dead.length,
      'apiSurfaceCount': apiSurface.length,
      'docOnlyCount': docOnly.length,
    },
    'dead': dead.map((e) => e.toJson()).toList(),
    'apiSurface': apiSurface.map((e) => e.toJson()).toList(),
    'docOnly': docOnly.map((e) => e.toJson()).toList(),
  };
}

/// Renders a [DeadCodeReport] as plain text or as markdown for a PR comment.
class DeadCodeFormatter {
  DeadCodeFormatter(this.report, {this.markdownHeaderLevel = 1, this.fileUrlBuilder});

  final DeadCodeReport report;
  final int markdownHeaderLevel;
  final String? Function(String filePath)? fileUrlBuilder;

  /// Plain text, one finding per line, grouped by file.
  String format() {
    final buffer = StringBuffer();

    if (report.dead.isEmpty) {
      buffer.writeln('No dead code found.');
    } else {
      for (final entry in _groupByFile(report.dead).entries) {
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
      for (final entry in _groupByFile(report.docOnly).entries) {
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
  String formatMarkdown() {
    if (report.isEmpty) return '';

    final header = '#' * markdownHeaderLevel;
    final buffer = StringBuffer();

    buffer.writeln();
    buffer.writeln('$header ⚠️ Dead code');
    buffer.writeln();

    if (report.dead.isNotEmpty) {
      buffer.writeln(
        '${report.dead.length} ${_plural(report.dead.length, 'declaration', 'declarations')} '
        'nothing references, and outside the export closure so no consumer can reach '
        '${report.dead.length == 1 ? 'it' : 'them'}.',
      );
      buffer.writeln();

      for (final entry in _groupByFile(report.dead).entries) {
        final link = fileUrlBuilder?.call(entry.key);
        buffer.writeln('**${link != null ? '[${entry.key}]($link)' : '`${entry.key}`'}**');
        buffer.writeln();
        for (final decl in entry.value) {
          buffer.writeln('- `${decl.qualifiedName}` — ${decl.kind.label}, line ${decl.line}');
        }
        buffer.writeln();
      }
    }

    if (report.docOnly.isNotEmpty) {
      buffer.writeln('<details><summary>${report.docOnly.length} referenced only from doc comments</summary>');
      buffer.writeln();
      for (final decl in report.docOnly) {
        buffer.writeln('- `${decl.qualifiedName}` — `${decl.filePath}`, line ${decl.line}');
      }
      buffer.writeln();
      buffer.writeln('</details>');
      buffer.writeln();
    }

    buffer.writeln('<sub>${_summaryLine()}</sub>');

    return buffer.toString();
  }

  String _summaryLine() {
    final parts = [
      'Scanned ${report.filesScanned} ${_plural(report.filesScanned, 'file', 'files')}',
      'checked ${report.declarationsChecked} '
          '${_plural(report.declarationsChecked, 'declaration', 'declarations')}',
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

  static String _plural(int count, String singular, String plural) => count == 1 ? singular : plural;

  Map<String, List<DeadDeclaration>> _groupByFile(List<DeadDeclaration> declarations) {
    final grouped = groupBy(declarations, (DeadDeclaration d) => d.filePath);
    final sortedKeys = grouped.keys.toList()..sort();
    return {for (final key in sortedKeys) key: grouped[key]!..sort((a, b) => a.line.compareTo(b.line))};
  }
}
