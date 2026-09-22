import 'dart:io';

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
  const DeadCodeDelta({
    required this.introduced,
    required this.deleted,
    required this.revived,
    required this.preExisting,
    this.baseRef,
  });

  /// Findings this change added. The ones a reviewer can still do something
  /// about cheaply.
  final List<DeadDeclaration> introduced;

  /// Findings whose declaration is gone from the new revision. A rename or a
  /// move reads as a deletion, because a finding names a declaration in a file.
  final List<DeadDeclaration> deleted;

  /// Findings whose declaration is still there and is not dead any more,
  /// because live code reaches it now, or because the package exports it now.
  final List<DeadDeclaration> revived;

  /// Findings that were already there. Debt, not this change's doing.
  final List<DeadDeclaration> preExisting;

  /// The revision compared against, for the report to name.
  final String? baseRef;

  /// Everything that left the report, however it left.
  List<DeadDeclaration> get resolved => [...deleted, ...revived];

  bool get isEmpty => introduced.isEmpty && deleted.isEmpty && revived.isEmpty;

  Map<String, dynamic> toJson() => {
    'baseRef': baseRef,
    'summary': {
      'introducedCount': introduced.length,
      'deletedCount': deleted.length,
      'revivedCount': revived.length,
      'preExistingCount': preExisting.length,
    },
    'introduced': introduced.map((e) => e.toJson()).toList(),
    'deleted': deleted.map((e) => e.toJson()).toList(),
    'revived': revived.map((e) => e.toJson()).toList(),
    'preExisting': preExisting.map((e) => e.toJson()).toList(),
  };
}

/// Scans [baseRef] and [newRef], and reports how dead code changed between
/// them. Without a [newRef] the head side is the working tree.
///
/// Both sides are scanned with the same rules, so a finding that appears on
/// only one side really did appear or disappear, rather than being classified
/// differently.
Future<DeadCodeDelta> compareDeadCode({
  required String baseRef,
  String? newRef,
  required Directory dartRoot,
  required Directory gitRoot,
}) async {
  final head = await scanRevision(ref: newRef, dartRoot: dartRoot, gitRoot: gitRoot);
  final base = await scanRevision(ref: baseRef, dartRoot: dartRoot, gitRoot: gitRoot);

  return diffDeadCode(base: base, head: head, baseRef: baseRef);
}

/// Scans [ref] in a worktree of its own, or the working tree when [ref] is
/// null or already checked out.
Future<DeadCodeReport> scanRevision({
  required String? ref,
  required Directory dartRoot,
  required Directory gitRoot,
}) async {
  if (ref == null) return DeadCodeFinder(root: dartRoot).run();
  return withRefWorktree(
    ref: ref,
    dartRoot: dartRoot,
    gitRoot: gitRoot,
    body: (packageRoot) => DeadCodeFinder(root: packageRoot).run(),
  );
}

/// Splits [head]'s findings against [base]'s.
DeadCodeDelta diffDeadCode({required DeadCodeReport base, required DeadCodeReport head, String? baseRef}) {
  final before = base.dead.map(_identify).toSet();
  final after = head.dead.map(_identify).toSet();
  final deadContainersBefore = _deadContainers(base);
  final deadContainersAfter = _deadContainers(head);
  final stillDeclared = _declaredIn(head);

  bool wasDead(DeadDeclaration d) => before.contains(_identify(d)) || deadContainersBefore.contains(_container(d));
  bool isDead(DeadDeclaration d) => after.contains(_identify(d)) || deadContainersAfter.contains(_container(d));

  final resolved = base.dead.where((d) => !isDead(d)).toList();

  return DeadCodeDelta(
    introduced: head.dead.where((d) => !wasDead(d)).toList(),
    deleted: resolved.where((d) => !stillDeclared.contains(_identify(d))).toList(),
    revived: resolved.where((d) => stillDeclared.contains(_identify(d))).toList(),
    preExisting: head.dead.where(wasDead).toList(),
    baseRef: baseRef,
  );
}

/// The declarations [report] lists that other findings can be folded into.
///
/// A dead member of a dead class is not listed on its own, so comparing the
/// listed findings alone reads the fold as a change: the member would count as
/// no longer dead when its class went dead, and as newly dead when its class
/// came alive.
Set<String> _deadContainers(DeadCodeReport report) => {
  for (final declaration in report.dead)
    if (declaration.container == null) '${declaration.filePath}:${declaration.name}',
};

/// The key its container has in [_deadContainers], for a member.
String? _container(DeadDeclaration declaration) =>
    declaration.container == null ? null : '${declaration.filePath}:${declaration.container}';

/// What [report] saw declared. The buckets are folded in as well, so a report
/// that carries no [DeadCodeReport.declarations] still tells a deletion from a
/// declaration that became API surface.
Set<_Identity> _declaredIn(DeadCodeReport report) => {
  for (final declaration in [...report.declarations, ...report.dead, ...report.apiSurface, ...report.docOnly])
    _identify(declaration),
};

/// Renders a [DeadCodeDelta] as plain text or as markdown for a PR comment.
class DeadCodeDeltaFormatter extends DeadCodeMarkdown {
  const DeadCodeDeltaFormatter(this.delta, {super.markdownHeaderLevel, super.fileUrlBuilder});

  final DeadCodeDelta delta;

  @override
  Map<String, dynamic> toJson() => delta.toJson();

  @override
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

    void writeSection(String title, List<DeadDeclaration> findings) {
      if (findings.isEmpty) return;
      buffer.writeln(title);
      for (final finding in findings) {
        buffer.writeln('  ${finding.filePath}  ${finding.kind.label} ${finding.qualifiedName}');
      }
      buffer.writeln();
    }

    writeSection('Deleted:', delta.deleted);
    writeSection('No longer dead:', delta.revived);

    buffer.writeln(summaryLine);
    return buffer.toString();
  }

  /// Markdown for a PR comment. Empty when this change neither added nor
  /// removed dead code, so a clean pull request carries no line about it.
  @override
  String formatMarkdown() {
    if (delta.isEmpty) return '';

    final buffer = StringBuffer()..writeln();

    if (delta.introduced.isNotEmpty) {
      buffer
        ..writeln('$heading ⚠️ Dead code added')
        ..writeln()
        ..writeln(
          '${delta.introduced.length} '
          '${DeadCodeMarkdown.plural(delta.introduced.length, 'declaration', 'declarations')} '
          'nothing live refers to, added since `${delta.baseRef ?? 'base'}`, and '
          'outside the export closure so no consumer can reach '
          '${DeadCodeMarkdown.plural(delta.introduced.length, 'it', 'them')}.',
        )
        ..writeln();
      writeFindingsByFile(buffer, delta.introduced);
    }

    if (delta.deleted.isNotEmpty) {
      writeDetails(buffer, '✅ ${delta.deleted.length} dead ${_declarations(delta.deleted)} deleted', [
        for (final finding in delta.deleted) '- `${finding.qualifiedName}` — `${finding.filePath}`',
      ]);
    }

    if (delta.revived.isNotEmpty) {
      writeDetails(buffer, '✅ ${delta.revived.length} ${_declarations(delta.revived)} no longer dead', [
        for (final finding in delta.revived) '- `${finding.qualifiedName}` — `${finding.filePath}`',
      ]);
    }

    buffer.writeln('<sub>$summaryLine</sub>');
    return buffer.toString();
  }

  /// The counts, for a caller that wants the delta in one line.
  String get summaryLine {
    final parts = ['${delta.introduced.length} added'];
    if (delta.deleted.isNotEmpty) parts.add('${delta.deleted.length} deleted');
    if (delta.revived.isNotEmpty) parts.add('${delta.revived.length} no longer dead');
    parts.add('${delta.preExisting.length} already there');
    return '${parts.join(', ')}.';
  }

  static String _declarations(List<DeadDeclaration> findings) =>
      DeadCodeMarkdown.plural(findings.length, 'declaration', 'declarations');
}
