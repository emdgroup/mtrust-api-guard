import 'package:mtrust_api_guard/dead_code/dead_code_delta.dart';
import 'package:mtrust_api_guard/dead_code/dead_code_report.dart';
import 'package:test/test.dart';

import 'dead_code_fixtures.dart';

void main() {
  group('diffDeadCode', () {
    test('reports a finding only the new revision has as introduced', () {
      final delta = diffDeadCode(
        base: report(dead: []),
        head: report(dead: [declaration(name: 'Orphan')]),
      );

      expect(delta.introduced.map((d) => d.qualifiedName), ['Orphan']);
      expect(delta.resolved, isEmpty);
      expect(delta.preExisting, isEmpty);
    });

    test('reports a finding whose declaration is gone as deleted', () {
      final delta = diffDeadCode(
        base: report(dead: [declaration(name: 'Orphan')]),
        head: report(dead: []),
      );

      expect(delta.deleted.map((d) => d.qualifiedName), ['Orphan']);
      expect(delta.revived, isEmpty);
      expect(delta.introduced, isEmpty);
    });

    test('reports a finding whose declaration is still there as revived', () {
      // Somebody wired the orphan up rather than deleting it.
      final delta = diffDeadCode(
        base: report(dead: [declaration(name: 'Orphan')]),
        head: report(declarations: [declaration(name: 'Orphan')]),
      );

      expect(delta.revived.map((d) => d.qualifiedName), ['Orphan']);
      expect(delta.deleted, isEmpty);
    });

    test('counts a finding the package started exporting as revived', () {
      final delta = diffDeadCode(
        base: report(dead: [declaration(name: 'Orphan')]),
        head: report(apiSurface: [declaration(name: 'Orphan')]),
      );

      expect(delta.revived.map((d) => d.qualifiedName), ['Orphan']);
      expect(delta.deleted, isEmpty);
    });

    test('reports a finding both sides have as pre-existing', () {
      final delta = diffDeadCode(
        base: report(dead: [declaration(name: 'Orphan')]),
        head: report(dead: [declaration(name: 'Orphan')]),
      );

      expect(delta.preExisting.map((d) => d.qualifiedName), ['Orphan']);
      expect(delta.introduced, isEmpty);
      expect(delta.resolved, isEmpty);
    });

    test('does not call a finding new just because it moved down the file', () {
      // Someone adds an import and every declaration below shifts. Keying on
      // the line number would report the whole file as newly dead.
      final delta = diffDeadCode(
        base: report(dead: [declaration(name: 'Orphan', line: 12)]),
        head: report(dead: [declaration(name: 'Orphan', line: 48)]),
      );

      expect(delta.introduced, isEmpty);
      expect(delta.preExisting, hasLength(1));
    });

    test('tells apart two declarations with the same name in different files', () {
      final delta = diffDeadCode(
        base: report(
          dead: [declaration(name: 'Orphan', filePath: 'lib/a.dart')],
        ),
        head: report(
          dead: [declaration(name: 'Orphan', filePath: 'lib/b.dart')],
        ),
      );

      expect(delta.introduced.single.filePath, 'lib/b.dart');
      expect(delta.deleted.single.filePath, 'lib/a.dart');
    });

    test('tells apart a member from a top level declaration of the same name', () {
      final delta = diffDeadCode(
        base: report(dead: [declaration(name: 'run')]),
        head: report(
          dead: [declaration(name: 'run', container: 'Runner')],
        ),
      );

      expect(delta.introduced.single.qualifiedName, 'Runner.run');
      expect(delta.deleted.single.qualifiedName, 'run');
    });

    test('treats a change of kind as a different declaration', () {
      final delta = diffDeadCode(
        base: report(
          dead: [declaration(name: 'Thing', kind: DeadCodeKind.classKind)],
        ),
        head: report(
          dead: [declaration(name: 'Thing', kind: DeadCodeKind.mixinKind)],
        ),
      );

      expect(delta.introduced, hasLength(1));
      expect(delta.deleted, hasLength(1));
    });

    test('does not call a member alive again when its whole class went dead', () {
      // Only the outermost finding is reported, so a member drops off the list
      // the moment its class joins it. It got deader, not less dead.
      final member = declaration(name: 'bar', container: 'Foo');
      final delta = diffDeadCode(
        base: report(dead: [member]),
        head: report(
          dead: [declaration(name: 'Foo', line: 5)],
          declarations: [
            declaration(name: 'Foo', line: 5),
            member,
          ],
        ),
      );

      expect(delta.introduced.map((d) => d.qualifiedName), ['Foo']);
      expect(delta.revived, isEmpty);
      expect(delta.deleted, isEmpty);
    });

    test('does not call a member newly dead when its class came alive', () {
      // The mirror image: the class stops being dead and its dead member is
      // listed on its own for the first time, having been dead all along.
      final member = declaration(name: 'bar', container: 'Foo');
      final container = declaration(name: 'Foo', line: 5);
      final delta = diffDeadCode(
        base: report(dead: [container], declarations: [container, member]),
        head: report(dead: [member], declarations: [container, member]),
      );

      expect(delta.introduced, isEmpty);
      expect(delta.preExisting.map((d) => d.qualifiedName), ['Foo.bar']);
      expect(delta.revived.map((d) => d.qualifiedName), ['Foo']);
    });

    test('carries the base ref through for the report to name', () {
      final delta = diffDeadCode(
        base: report(dead: []),
        head: report(dead: []),
        baseRef: 'main',
      );
      expect(delta.baseRef, 'main');
    });
  });

  group('DeadCodeDeltaFormatter', () {
    test('says nothing at all when the change neither added nor resolved any', () {
      final delta = diffDeadCode(
        base: report(dead: [declaration(name: 'Orphan')]),
        head: report(dead: [declaration(name: 'Orphan')]),
      );

      // A clean pull request should carry no line about dead code, or people
      // stop reading the comment.
      expect(DeadCodeDeltaFormatter(delta).formatMarkdown(), isEmpty);
      expect(delta.isEmpty, isTrue);
    });

    test('names the base ref it compared against', () {
      final delta = diffDeadCode(
        base: report(dead: []),
        head: report(dead: [declaration(name: 'Orphan')]),
        baseRef: 'main',
      );

      expect(DeadCodeDeltaFormatter(delta).formatMarkdown(), contains('added since `main`'));
      expect(DeadCodeDeltaFormatter(delta).format(), contains('introduced since main'));
    });

    test('counts pre-existing findings without listing them', () {
      final delta = diffDeadCode(
        base: report(dead: [declaration(name: 'Old')]),
        head: report(
          dead: [
            declaration(name: 'Old'),
            declaration(name: 'New', line: 30),
          ],
        ),
      );

      final markdown = DeadCodeDeltaFormatter(delta).formatMarkdown();
      expect(markdown, contains('`New`'));
      expect(markdown, isNot(contains('`Old`')), reason: 'debt is not this change to answer for');
      expect(markdown, contains('1 already there'));
    });

    test('folds deleted findings into a details block', () {
      final delta = diffDeadCode(
        base: report(dead: [declaration(name: 'Gone')]),
        head: report(dead: []),
      );

      final markdown = DeadCodeDeltaFormatter(delta).formatMarkdown();
      expect(markdown, contains('✅ 1 dead declaration deleted'));
      expect(markdown, contains('`Gone`'));
    });

    test('keeps a declaration that is only alive again out of the deleted block', () {
      final delta = diffDeadCode(
        base: report(
          dead: [
            declaration(name: 'Woken'),
            declaration(name: 'Gone', line: 40),
          ],
        ),
        head: report(declarations: [declaration(name: 'Woken')]),
      );

      final markdown = DeadCodeDeltaFormatter(delta).formatMarkdown();
      expect(markdown, contains('✅ 1 dead declaration deleted'));
      expect(markdown, contains('✅ 1 declaration no longer dead'));
      expect(markdown, contains('1 deleted, 1 no longer dead'));

      expect(DeadCodeDeltaFormatter(delta).format(), contains('Deleted:\n  lib/src/widget.dart  class Gone'));
      expect(DeadCodeDeltaFormatter(delta).format(), contains('No longer dead:\n  lib/src/widget.dart  class Woken'));
    });

    test('links files when a url builder is given', () {
      final delta = diffDeadCode(
        base: report(dead: []),
        head: report(dead: [declaration()]),
      );

      final markdown = DeadCodeDeltaFormatter(
        delta,
        fileUrlBuilder: (path) => 'https://example.test/$path',
      ).formatMarkdown();

      expect(markdown, contains('[lib/src/widget.dart](https://example.test/lib/src/widget.dart)'));
    });

    test('agrees in number with the singular and the plural', () {
      final one = DeadCodeDeltaFormatter(
        diffDeadCode(
          base: report(dead: []),
          head: report(dead: [declaration(name: 'A')]),
        ),
      ).formatMarkdown();
      expect(one, contains('1 declaration nothing live refers to'));
      expect(one, contains('no consumer can reach it'));

      final two = DeadCodeDeltaFormatter(
        diffDeadCode(
          base: report(dead: []),
          head: report(
            dead: [
              declaration(name: 'A'),
              declaration(name: 'B', line: 30),
            ],
          ),
        ),
      ).formatMarkdown();
      expect(two, contains('2 declarations nothing live refers to'));
      expect(two, contains('no consumer can reach them'));
    });

    test('serialises the buckets', () {
      final delta = diffDeadCode(
        base: report(
          dead: [
            declaration(name: 'Old'),
            declaration(name: 'Gone', line: 40),
          ],
        ),
        head: report(
          dead: [
            declaration(name: 'Old'),
            declaration(name: 'New', line: 30),
          ],
        ),
        baseRef: 'main',
      );

      expect(delta.toJson()['summary'], {
        'introducedCount': 1,
        'deletedCount': 1,
        'revivedCount': 0,
        'preExistingCount': 1,
      });
      expect(delta.toJson()['baseRef'], 'main');
    });
  });
}
