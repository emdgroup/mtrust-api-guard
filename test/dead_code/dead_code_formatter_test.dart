import 'package:mtrust_api_guard/dead_code/dead_code_report.dart';
import 'package:test/test.dart';

DeadDeclaration _declaration({
  String name = 'Widget',
  String? container,
  DeadCodeKind kind = DeadCodeKind.classKind,
  String filePath = 'lib/src/widget.dart',
  int line = 12,
  bool isPrivate = false,
}) => DeadDeclaration(
  name: name,
  container: container,
  kind: kind,
  filePath: filePath,
  line: line,
  column: 7,
  isPrivate: isPrivate,
);

DeadCodeReport _report({
  List<DeadDeclaration> dead = const [],
  List<DeadDeclaration> apiSurface = const [],
  List<DeadDeclaration> docOnly = const [],
}) => DeadCodeReport(dead: dead, apiSurface: apiSurface, docOnly: docOnly, filesScanned: 4, declarationsChecked: 40);

void main() {
  group('DeadDeclaration', () {
    test('qualifies a member with its container', () {
      expect(_declaration(name: 'run', container: 'Runner').qualifiedName, 'Runner.run');
    });

    test('leaves a top level declaration unqualified', () {
      expect(_declaration(name: 'run').qualifiedName, 'run');
    });

    test('omits an absent container from json', () {
      expect(_declaration().toJson(), isNot(contains('container')));
    });
  });

  group('DeadCodeFormatter text', () {
    test('says so when there is nothing to report', () {
      final output = DeadCodeFormatter(_report()).format();
      expect(output, contains('No dead code found.'));
    });

    test('groups findings under their file and orders them by line', () {
      final output = DeadCodeFormatter(
        _report(
          dead: [
            _declaration(name: 'Late', line: 30),
            _declaration(name: 'Early', line: 4),
          ],
        ),
      ).format();

      expect(output.indexOf('Early'), lessThan(output.indexOf('Late')));
      expect(output, contains('lib/src/widget.dart'));
      expect(output, contains('(public)'));
    });

    test('marks a private finding', () {
      final output = DeadCodeFormatter(_report(dead: [_declaration(name: '_Hidden', isPrivate: true)])).format();
      expect(output, contains('(private)'));
    });

    test('lists doc-only findings separately from dead ones', () {
      final output = DeadCodeFormatter(_report(docOnly: [_declaration(name: 'Mentioned')])).format();
      expect(output, contains('Referenced only from doc comments'));
      expect(output, contains('Mentioned'));
    });

    test('summarises what was scanned', () {
      final output = DeadCodeFormatter(
        _report(
          dead: [_declaration()],
          apiSurface: [_declaration(name: 'Exported')],
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
      expect(DeadCodeFormatter(_report()).formatMarkdown(), isEmpty);
    });

    test('is empty when the only findings are exported API surface', () {
      // Nothing to warn a reviewer about: a consumer can reach these.
      expect(DeadCodeFormatter(_report(apiSurface: [_declaration()])).formatMarkdown(), isEmpty);
    });

    test('renders a warning heading at the requested level', () {
      final output = DeadCodeFormatter(_report(dead: [_declaration()]), markdownHeaderLevel: 3).formatMarkdown();
      expect(output, contains('### ⚠️ Dead code'));
    });

    test('links files when a url builder is given', () {
      final output = DeadCodeFormatter(
        _report(dead: [_declaration()]),
        fileUrlBuilder: (path) => 'https://example.test/$path',
      ).formatMarkdown();
      expect(output, contains('[lib/src/widget.dart](https://example.test/lib/src/widget.dart)'));
    });

    test('falls back to plain code spans without a url builder', () {
      final output = DeadCodeFormatter(_report(dead: [_declaration()])).formatMarkdown();
      expect(output, contains('`lib/src/widget.dart`'));
      expect(output, isNot(contains('](')));
    });

    test('agrees in number with the singular and the plural', () {
      final one = DeadCodeFormatter(_report(dead: [_declaration()])).formatMarkdown();
      expect(one, contains('1 declaration nothing references'));
      expect(one, contains('no consumer can reach it'));

      final two = DeadCodeFormatter(
        _report(
          dead: [
            _declaration(name: 'A'),
            _declaration(name: 'B', line: 20),
          ],
        ),
      ).formatMarkdown();
      expect(two, contains('2 declarations nothing references'));
      expect(two, contains('no consumer can reach them'));
    });

    test('folds doc-only findings into a details block', () {
      final output = DeadCodeFormatter(
        _report(
          dead: [_declaration()],
          docOnly: [_declaration(name: 'Mentioned')],
        ),
      ).formatMarkdown();
      expect(output, contains('<details><summary>1 referenced only from doc comments</summary>'));
      expect(output, contains('</details>'));
    });
  });

  group('DeadCodeReport', () {
    test('is empty when nothing is dead and nothing is doc-only', () {
      expect(_report(apiSurface: [_declaration()]).isEmpty, isTrue);
      expect(_report(dead: [_declaration()]).isEmpty, isFalse);
      expect(_report(docOnly: [_declaration()]).isEmpty, isFalse);
    });

    test('serialises counts alongside the findings', () {
      final json = _report(
        dead: [_declaration()],
        docOnly: [_declaration(name: 'M')],
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
