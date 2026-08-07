import 'dart:convert';

import 'package:mtrust_api_guard/changelog_generator/changelog_archive.dart';
import 'package:test/test.dart';

void main() {
  group('splitChangelogForPubLimit', () {
    test('leaves under-limit changelog unchanged without archive', () {
      final changelog = _section('1.0.0', 'small');
      final result = splitChangelogForPubLimit(changelog);

      expect(result.archive, isNull);
      expect(result.changelog, contains('## 1.0.0'));
      expect(result.changelog, isNot(contains('Older versions')));
    });

    test('keeps existing archive link when under limit', () {
      final changelog = '${_section('2.0.0', 'new')}\n\n$changelogArchiveFooter';
      final result = splitChangelogForPubLimit(changelog, existingArchive: _section('1.0.0', 'old'));

      expect(result.archive, contains('## 1.0.0'));
      expect(result.changelog, contains('## 2.0.0'));
      expect(result.changelog, contains('Older versions'));
      expect(result.changelog, contains(changelogArchiveFileName));
    });

    test('peels oldest sections into archive when over limit', () {
      final s1 = _section('3.0.0', 'a' * 200);
      final s2 = _section('2.0.0', 'b' * 200);
      final s3 = _section('1.0.0', 'c' * 200);
      final changelog = joinChangelogSections([s1, s2, s3]);

      // ~660B total; one section (~220B) + footer (~100B) fits under 400.
      final result = splitChangelogForPubLimit(changelog, maxBytes: 400, targetBytes: 350);

      expect(result.changelog, contains('## 3.0.0'));
      expect(result.changelog, contains('Older versions'));
      expect(utf8.encode(result.changelog).length, lessThanOrEqualTo(400));

      expect(result.archive, isNotNull);
      expect(result.archive!, contains('## 2.0.0'));
      expect(result.archive!, contains('## 1.0.0'));
      expect(result.archive!.indexOf('## 2.0.0'), lessThan(result.archive!.indexOf('## 1.0.0')));
      expect(result.changelog, isNot(contains('## 1.0.0')));
    });

    test('prepends newly peeled sections ahead of existing archive', () {
      final s1 = _section('3.0.0', 'a' * 200);
      final s2 = _section('2.0.0', 'b' * 200);
      final changelog = joinChangelogSections([s1, s2]);
      final existing = _section('1.0.0', 'old');

      final result = splitChangelogForPubLimit(changelog, existingArchive: existing, maxBytes: 400, targetBytes: 350);

      expect(result.archive, isNotNull);
      expect(result.archive!.indexOf('## 2.0.0'), lessThan(result.archive!.indexOf('## 1.0.0')));
    });

    test('keeps Unreleased plus newest release when archiving', () {
      final unreleased = _section('Unreleased', 'u' * 150);
      final s1 = _section('2.0.0', 'a' * 200);
      final s2 = _section('1.0.0', 'b' * 200);
      final changelog = joinChangelogSections([unreleased, s1, s2]);

      // Total ~600B; min keep is Unreleased+2.0.0 (~380B + footer).
      final result = splitChangelogForPubLimit(changelog, maxBytes: 550, targetBytes: 500);

      expect(result.changelog, contains('## Unreleased'));
      expect(result.changelog, contains('## 2.0.0'));
      expect(result.archive, isNotNull);
      expect(result.archive!, contains('## 1.0.0'));
      expect(result.changelog, isNot(contains('## 1.0.0')));
    });

    test('footer appears only once after repeated splits', () {
      final s1 = _section('2.0.0', 'a' * 200);
      final s2 = _section('1.0.0', 'b' * 200);
      final first = splitChangelogForPubLimit(joinChangelogSections([s1, s2]), maxBytes: 400, targetBytes: 350);

      expect(first.archive, isNotNull);
      expect(first.changelog, contains('Older versions'));

      final second = splitChangelogForPubLimit(
        first.changelog,
        existingArchive: first.archive,
        maxBytes: 400,
        targetBytes: 350,
      );

      expect('Older versions'.allMatches(second.changelog).length, 1);
    });

    test('throws when a single section exceeds the max limit', () {
      final huge = _section('1.0.0', 'x' * 200);

      expect(
        () => splitChangelogForPubLimit(huge, maxBytes: 50, targetBytes: 40),
        throwsA(isA<ChangelogTooLargeException>()),
      );
    });
  });

  group('parseChangelogSections', () {
    test('ignores Older versions footer header', () {
      final content = '''
## 2.0.0

notes

---

## Older versions

See [CHANGELOG_ARCHIVE.md](CHANGELOG_ARCHIVE.md) for earlier releases.
''';
      final sections = parseChangelogSections(content);
      expect(sections, hasLength(1));
      expect(sections.single, contains('## 2.0.0'));
    });
  });
}

String _section(String version, String body) {
  return '## $version\n\n$body\n';
}
