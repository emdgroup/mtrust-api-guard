import 'package:mtrust_api_guard/dead_code/dead_code_report.dart';
import 'package:test/test.dart';

import 'dead_code_fixtures.dart';

void main() {
  group('DeadDeclaration', () {
    test('qualifies a member with its container', () {
      expect(declaration(name: 'run', container: 'Runner').qualifiedName, 'Runner.run');
    });

    test('leaves a top level declaration unqualified', () {
      expect(declaration(name: 'run').qualifiedName, 'run');
    });

    test('omits an absent container from json', () {
      expect(declaration().toJson(), isNot(contains('container')));
    });
  });

  group('DeadCodeFormatter text', () {
    test('says so when there is nothing to report', () {
      final output = DeadCodeFormatter(report()).format();
      expect(output, contains('No dead code found.'));
    });

    test('groups findings under their file and orders them by line', () {
      final output = DeadCodeFormatter(
        report(
          dead: [
            declaration(name: 'Late', line: 30),
            declaration(name: 'Early', line: 4),
          ],
        ),
      ).format();

      expect(output.indexOf('Early'), lessThan(output.indexOf('Late')));
      expect(output, contains('lib/src/widget.dart'));
      expect(output, contains('(public)'));
    });

    test('marks a private finding', () {
      final output = DeadCodeFormatter(report(dead: [declaration(name: '_Hidden')])).format();
      expect(output, contains('(private)'));
    });

    test('lists doc-only findings separately from dead ones', () {
      final output = DeadCodeFormatter(report(docOnly: [declaration(name: 'Mentioned')])).format();
      expect(output, contains('Referenced only from doc comments'));
      expect(output, contains('Mentioned'));
    });

    test('summarises what was scanned', () {
      final output = DeadCodeFormatter(
        report(
          dead: [declaration()],
          apiSurface: [declaration(name: 'Exported')],
        ),
      ).format();
      expect(output, contains('Scanned 4 files'));
      expect(output, contains('checked 40 declarations'));
      expect(output, contains('1 dead'));
      expect(output, contains('1 unreferenced but exported'));
    });
  });

  group('DeadCodeFormatter markdown', () {
    test('is empty when there is nothing to warn about', () {
      expect(DeadCodeFormatter(report()).formatMarkdown(), isEmpty);
    });

    test('is empty when the only findings are exported API surface', () {
      // Nothing to warn a reviewer about: a consumer can reach these.
      expect(DeadCodeFormatter(report(apiSurface: [declaration()])).formatMarkdown(), isEmpty);
    });

    test('renders a warning heading at the requested level', () {
      final output = DeadCodeFormatter(report(dead: [declaration()]), markdownHeaderLevel: 3).formatMarkdown();
      expect(output, contains('### ⚠️ Dead code'));
    });

    test('links files when a url builder is given', () {
      final output = DeadCodeFormatter(
        report(dead: [declaration()]),
        fileUrlBuilder: (path) => 'https://example.test/$path',
      ).formatMarkdown();
      expect(output, contains('[lib/src/widget.dart](https://example.test/lib/src/widget.dart)'));
    });

    test('falls back to plain code spans without a url builder', () {
      final output = DeadCodeFormatter(report(dead: [declaration()])).formatMarkdown();
      expect(output, contains('`lib/src/widget.dart`'));
      expect(output, isNot(contains('](')));
    });

    test('agrees in number with the singular and the plural', () {
      final one = DeadCodeFormatter(report(dead: [declaration()])).formatMarkdown();
      expect(one, contains('1 declaration nothing live refers to'));
      expect(one, contains('no consumer can reach it'));

      final two = DeadCodeFormatter(
        report(
          dead: [
            declaration(name: 'A'),
            declaration(name: 'B', line: 20),
          ],
        ),
      ).formatMarkdown();
      expect(two, contains('2 declarations nothing live refers to'));
      expect(two, contains('no consumer can reach them'));
    });

    test('folds doc-only findings into a details block', () {
      final output = DeadCodeFormatter(
        report(
          dead: [declaration()],
          docOnly: [declaration(name: 'Mentioned')],
        ),
      ).formatMarkdown();
      expect(output, contains('<details><summary>1 referenced only from doc comments</summary>'));
      expect(output, contains('</details>'));
    });
  });

  group('DeadCodeReport', () {
    test('is empty when nothing is dead and nothing is doc-only', () {
      expect(report(apiSurface: [declaration()]).isEmpty, isTrue);
      expect(report(dead: [declaration()]).isEmpty, isFalse);
      expect(report(docOnly: [declaration()]).isEmpty, isFalse);
    });

    test('serialises counts alongside the findings', () {
      final json = report(
        dead: [declaration()],
        docOnly: [declaration(name: 'M')],
      ).toJson();
      expect(json['summary'], {
        'filesScanned': 4,
        'declarationsChecked': 40,
        'deadCount': 1,
        'apiSurfaceCount': 0,
        'docOnlyCount': 1,
      });
      expect((json['dead'] as List).single, containsPair('qualifiedName', 'Widget'));
    });
  });
}
