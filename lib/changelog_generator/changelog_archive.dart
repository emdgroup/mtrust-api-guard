import 'dart:convert';

/// pub.dev rejects publishes when `CHANGELOG.md` exceeds this size.
const int pubChangelogMaxBytes = 262144;

/// When archiving, trim until at or below this size so the next release
/// does not immediately exceed [pubChangelogMaxBytes].
const int pubChangelogTargetBytes = 230000;

const String changelogArchiveFileName = 'CHANGELOG_ARCHIVE.md';

const String changelogArchiveFooter = '''
---

## Older versions

See [CHANGELOG_ARCHIVE.md](CHANGELOG_ARCHIVE.md) for earlier releases.
''';

/// Thrown when changelog content cannot be kept under [pubChangelogMaxBytes]
/// even after archiving older sections.
class ChangelogTooLargeException implements Exception {
  ChangelogTooLargeException(this.message);

  final String message;

  @override
  String toString() => 'ChangelogTooLargeException: $message';
}

/// Result of enforcing the pub.dev changelog size limit.
class SplitChangelogResult {
  const SplitChangelogResult({required this.changelog, this.archive});

  /// Content to write to `CHANGELOG.md`.
  final String changelog;

  /// Content to write to `CHANGELOG_ARCHIVE.md`, or `null` if the archive
  /// file should be removed / not written.
  final String? archive;
}

/// Splits [changelog] so the published file stays within pub.dev's size limit.
///
/// Older `##` version sections are moved into [existingArchive] (prepended,
/// newest-first). When [existingArchive] is omitted/`null` (e.g. full
/// regenerate), the archive contains only newly peeled sections.
SplitChangelogResult splitChangelogForPubLimit(
  String changelog, {
  String? existingArchive,
  int maxBytes = pubChangelogMaxBytes,
  int targetBytes = pubChangelogTargetBytes,
}) {
  final existing = _normalizeArchive(existingArchive);
  final sections = parseChangelogSections(changelog);

  if (sections.isEmpty) {
    final stripped = stripOlderVersionsFooter(changelog);
    if (existing.isEmpty) {
      return SplitChangelogResult(changelog: stripped, archive: null);
    }
    return SplitChangelogResult(changelog: _withFooter(stripped.isEmpty ? '' : stripped), archive: existing);
  }

  final kept = List<String>.from(sections);
  final peeled = <String>[];

  int changelogBytes(List<String> versionSections, {required bool withFooter}) {
    final body = joinChangelogSections(versionSections);
    if (!withFooter) return utf8.encode(body).length;
    return utf8.encode(_withFooter(body)).length;
  }

  bool willHaveArchive() => peeled.isNotEmpty || existing.isNotEmpty;

  if (changelogBytes(kept, withFooter: willHaveArchive()) > maxBytes) {
    final minKeep = _minimumSectionsToKeep(kept);

    while (changelogBytes(kept, withFooter: true) > targetBytes && kept.length > minKeep) {
      peeled.add(kept.removeLast());
    }

    if (changelogBytes(kept, withFooter: true) > maxBytes) {
      final header = kept.first.split('\n').first;
      throw ChangelogTooLargeException(
        'Changelog cannot stay under the pub.dev limit ($maxBytes bytes); '
        'newest section "$header" (with archive link) still exceeds it.',
      );
    }
  }

  final archiveBody = _buildArchiveBody(peeled: peeled, existing: existing);
  final body = joinChangelogSections(kept);
  final changelogOut = archiveBody == null ? body : _withFooter(body);

  return SplitChangelogResult(changelog: changelogOut, archive: archiveBody);
}

/// Parses `##` version sections from a changelog, ignoring the archive footer.
List<String> parseChangelogSections(String changelog) {
  final content = stripOlderVersionsFooter(changelog);
  final lines = content.split('\n');
  final sections = <String>[];
  final current = StringBuffer();
  var inSection = false;

  void flush() {
    if (!inSection) return;
    sections.add(current.toString());
    current.clear();
  }

  for (final line in lines) {
    if (_isVersionHeader(line)) {
      flush();
      inSection = true;
      current.writeln(line);
    } else if (inSection) {
      current.writeln(line);
    }
  }
  flush();

  return sections.map(_trimTrailingNewlines).where((s) => s.isNotEmpty).toList();
}

/// Joins version sections with a blank line between them.
String joinChangelogSections(List<String> sections) {
  if (sections.isEmpty) return '';
  return '${sections.map(_trimTrailingNewlines).join('\n\n')}\n';
}

/// Removes the "Older versions" footer if present.
String stripOlderVersionsFooter(String changelog) {
  final pattern = RegExp(r'\n---\s*\n\s*## Older versions\s*\n[\s\S]*$', multiLine: true);
  return changelog.replaceFirst(pattern, '\n').trimRight();
}

bool _isVersionHeader(String line) {
  if (!line.startsWith('## ')) return false;
  final title = line.substring(3).trim();
  return title != 'Older versions';
}

int _minimumSectionsToKeep(List<String> sections) {
  if (sections.isEmpty) return 0;
  final firstHeader = sections.first.split('\n').first;
  final isUnreleased = firstHeader.startsWith('## Unreleased');
  if (isUnreleased && sections.length >= 2) return 2;
  return 1;
}

String? _buildArchiveBody({required List<String> peeled, required String existing}) {
  // [peeled] was filled oldest-first; reverse for newest-first archive order.
  final newlyArchived = peeled.reversed.map(_trimTrailingNewlines).toList();
  final parts = <String>[...newlyArchived, if (existing.isNotEmpty) existing];
  if (parts.isEmpty) return null;
  return joinChangelogSections(parts);
}

String _normalizeArchive(String? existingArchive) {
  if (existingArchive == null) return '';
  return _trimTrailingNewlines(existingArchive);
}

String _withFooter(String body) {
  final trimmed = body.trimRight();
  return '$trimmed\n\n$changelogArchiveFooter';
}

String _trimTrailingNewlines(String value) {
  return value.replaceFirst(RegExp(r'\n+$'), '');
}
