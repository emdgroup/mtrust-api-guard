import 'dart:io';

import 'package:collection/collection.dart';
import 'package:mtrust_api_guard/dead_code/dead_code_finder.dart';
import 'package:mtrust_api_guard/dead_code/dead_code_report.dart';
import 'package:mtrust_api_guard/doc_generator/ref_worktree.dart';

/// What identifies a finding across two revisions.
///
/// Deliberately not the line number. A declaration that moved down because
/// someone added an import above it is the same dead declaration, and treating
/// it as newly introduced would make the report cry wolf on every change.
typedef _Identity = ({String filePath, String qualifiedName, DeadCodeKind kind});

_Identity _identify(DeadDeclaration declaration) =>
    (filePath: declaration.filePath, qualifiedName: declaration.qualifiedName, kind: declaration.kind);

/// Dead code as it changed between two revisions.
class DeadCodeDelta {
  const DeadCodeDelta({required this.introduced, required this.resolved, required this.preExisting, this.baseRef});

  /// Findings this change added. The ones a reviewer can still do something
  /// about cheaply.
  final List<DeadDeclaration> introduced;

  /// Findings that were dead before and are not any more, either deleted or
  /// used by something now.
  final List<DeadDeclaration> resolved;

  /// Findings that were already there. Debt, not this change's doing.
  final List<DeadDeclaration> preExisting;

  /// The revision compared against, for the report to name.
  final String? baseRef;

  bool get isEmpty => introduced.isEmpty && resolved.isEmpty;

  Map<String, dynamic> toJson() => {
    'baseRef': baseRef,
    'summary': {
      'introducedCount': introduced.length,
      'resolvedCount': resolved.length,
      'preExistingCount': preExisting.length,
    },
    'introduced': introduced.map((e) => e.toJson()).toList(),
    'resolved': resolved.map((e) => e.toJson()).toList(),
    'preExisting': preExisting.map((e) => e.toJson()).toList(),
  };
}

/// Scans [baseRef] and the working tree, and reports how dead code changed
/// between them.
///
/// Both sides are scanned with the same rules, so a finding that appears on
/// only one side really did appear or disappear, rather than being classified
/// differently.
Future<DeadCodeDelta> compareDeadCode({
  required String baseRef,
  required Directory dartRoot,
  required Directory gitRoot,
}) async {
  final head = await DeadCodeFinder(root: dartRoot).run();

  final base = await withRefWorktree(
    ref: baseRef,
    dartRoot: dartRoot,
    gitRoot: gitRoot,
    body: (packageRoot) => DeadCodeFinder(root: packageRoot).run(),
  );

  return diffDeadCode(base: base, head: head, baseRef: baseRef);
}

/// Splits [head]'s findings against [base]'s.
DeadCodeDelta diffDeadCode({required DeadCodeReport base, required DeadCodeReport head, String? baseRef}) {
  final before = base.dead.map(_identify).toSet();
  final after = head.dead.map(_identify).toSet();

  final introduced = head.dead.where((d) => !before.contains(_identify(d))).toList();
  final preExisting = head.dead.where((d) => before.contains(_identify(d))).toList();
  final resolved = base.dead.where((d) => !after.contains(_identify(d))).toList();

  return DeadCodeDelta(introduced: introduced, resolved: resolved, preExisting: preExisting, baseRef: baseRef);
}

/// Renders a [DeadCodeDelta] as plain text or as markdown for a PR comment.
class DeadCodeDeltaFormatter {
  DeadCodeDeltaFormatter(this.delta, {this.markdownHeaderLevel = 1, this.fileUrlBuilder});

  final DeadCodeDelta delta;
  final int markdownHeaderLevel;
  final String? Function(String filePath)? fileUrlBuilder;

  String format() {
    final buffer = StringBuffer();

    if (delta.introduced.isEmpty) {
      buffer.writeln('No new dead code.');
    } else {
      buffer.writeln('Dead code introduced since ${delta.baseRef ?? 'the base revision'}:');
      for (final finding in delta.introduced) {
        buffer.writeln('  ${finding.filePath}:${finding.line}  ${finding.kind.label} ${finding.qualifiedName}');
      }
      buffer.writeln();
    }

    if (delta.resolved.isNotEmpty) {
      buffer.writeln('No longer dead:');
      for (final finding in delta.resolved) {
        buffer.writeln('  ${finding.filePath}  ${finding.kind.label} ${finding.qualifiedName}');
      }
      buffer.writeln();
    }

    buffer.writeln(_summaryLine());
    return buffer.toString();
  }

  /// Markdown for a PR comment. Empty when this change neither added nor
  /// removed dead code, so a clean pull request carries no line about it.
  String formatMarkdown() {
    if (delta.isEmpty) return '';

    final header = '#' * markdownHeaderLevel;
    final buffer = StringBuffer()..writeln();

    if (delta.introduced.isNotEmpty) {
      buffer
        ..writeln('$header ⚠️ Dead code added')
        ..writeln()
        ..writeln(
          '${delta.introduced.length} '
          '${delta.introduced.length == 1 ? 'declaration' : 'declarations'} '
          'nothing references, added since `${delta.baseRef ?? 'base'}`, and '
          'outside the export closure so no consumer can reach '
          '${delta.introduced.length == 1 ? 'it' : 'them'}.',
        )
        ..writeln();

      for (final entry in groupBy(delta.introduced, (DeadDeclaration d) => d.filePath).entries) {
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

    if (delta.resolved.isNotEmpty) {
      buffer
        ..writeln('<details><summary>✅ ${delta.resolved.length} no longer dead</summary>')
        ..writeln();
      for (final finding in delta.resolved) {
        buffer.writeln('- `${finding.qualifiedName}` — `${finding.filePath}`');
      }
      buffer
        ..writeln()
        ..writeln('</details>')
        ..writeln();
    }

    buffer.writeln('<sub>${_summaryLine()}</sub>');
    return buffer.toString();
  }

  String _summaryLine() {
    final parts = ['${delta.introduced.length} added'];
    if (delta.resolved.isNotEmpty) parts.add('${delta.resolved.length} resolved');
    parts.add('${delta.preExisting.length} already there');
    return '${parts.join(', ')}.';
  }
}
