import 'dart:io';

import 'package:mtrust_api_guard/dead_code/dead_code_finder.dart';
import 'package:mtrust_api_guard/dead_code/dead_code_report.dart';
import 'package:test/test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('DeadCodeFinder', () {
    late Directory packageDir;
    late DeadCodeReport report;

    setUpAll(() async {
      // app_v100 configures `lib/src/api.dart` as its only entry point, so
      // everything under `lib/src/dead_code_cases.dart` is outside the export
      // closure and invisible to the API documentation the other tests diff.
      packageDir = await materializeFixturePackage(TestFixtures().appV100Dir, 'api_guard_test');
      report = await DeadCodeFinder(root: packageDir).run();
    });

    tearDownAll(() async {
      if (packageDir.existsSync()) await packageDir.delete(recursive: true);
    });

    Iterable<String> deadNames() => report.dead.map((d) => d.qualifiedName);
    Iterable<String> apiSurfaceNames() => report.apiSurface.map((d) => d.qualifiedName);
    Iterable<String> docOnlyNames() => report.docOnly.map((d) => d.qualifiedName);
    Iterable<String> allReported() => [...deadNames(), ...apiSurfaceNames(), ...docOnlyNames()];

    test('reports an unreferenced internal class as dead', () {
      expect(deadNames(), contains('DeadInternal'));
    });

    test('reports an unreferenced private class as dead', () {
      expect(deadNames(), contains('_DeadPrivate'));
    });

    test('does not let a function keep itself alive by recursing', () {
      expect(deadNames(), contains('_recursivelyDead'));
    });

    test('reports an exported but internally unreferenced declaration as API surface', () {
      expect(apiSurfaceNames(), containsAll(['User', 'Product', 'Status']));
      expect(deadNames(), isNot(contains('User')));
      expect(deadNames(), isNot(contains('Product')));
    });

    test('reports a public class outside the entry points as dead', () {
      // `lib/src/internal.dart` is not reachable from `lib/src/api.dart`.
      expect(deadNames(), contains('Internal'));
      expect(apiSurfaceNames(), isNot(contains('Internal')));
    });

    test('reports an unreferenced private class in an exported file as dead', () {
      // Private, so the export namespace never carries it, entry point or not.
      expect(deadNames(), contains('_PrivateClass'));
    });

    test('keeps a declaration referenced from lib alive', () {
      expect(allReported(), isNot(contains('UsedInternally')));
    });

    test('keeps a declaration referenced only from test alive', () {
      expect(allReported(), isNot(contains('UsedOnlyByTest')));
    });

    test('keeps a declaration referenced only from bin alive', () {
      expect(allReported(), isNot(contains('UsedOnlyByBin')));
    });

    test('keeps a declaration referenced only from a generated file alive', () {
      expect(allReported(), isNot(contains('UsedByGenerated')));
    });

    test('never reports declarations inside a generated file', () {
      expect(allReported(), isNot(contains('GeneratedDead')));
      expect(allReported(), isNot(contains('GeneratedHelper')));
    });

    test('reports only the dead container, not each of its members', () {
      expect(deadNames(), contains('DeadInternal'));
      expect(deadNames(), isNot(contains('DeadInternal.neverCalled')));
      expect(deadNames(), isNot(contains('DeadInternal.neverRead')));
    });

    test('reports a field that is written but never read', () {
      expect(deadNames(), contains('Holder.unreadField'));
      expect(allReported(), isNot(contains('Holder')));
      expect(allReported(), isNot(contains('Holder.readField')));
    });

    test('keeps an extension alive through the members that are applied', () {
      expect(allReported(), isNot(contains('StringShouting')));
      expect(allReported(), isNot(contains('StringShouting.shouted')));
    });

    test('reports an extension that is never applied', () {
      expect(deadNames(), contains('DeadExtension'));
    });

    test('resolves an applied operator back to its declaration', () {
      // A name-based reference search cannot connect `a + b` to `operator +`.
      expect(allReported(), isNot(contains('Vec.+')));
    });

    test('keeps an override alive when the supertype hook is called', () {
      expect(allReported(), isNot(contains('Subclass.hook')));
      expect(allReported(), isNot(contains('Base.hook')));
    });

    test('skips declarations the language or core libraries invoke implicitly', () {
      expect(allReported(), isNot(contains('Serializable.toJson')));
    });

    test('skips a vm entry point', () {
      expect(allReported(), isNot(contains('nativeCallback')));
    });

    test('skips main', () {
      expect(allReported(), isNot(contains('main')));
    });

    test('separates a declaration referenced only from a doc comment', () {
      expect(docOnlyNames(), contains('DocumentedOnly'));
      expect(deadNames(), isNot(contains('DocumentedOnly')));
    });

    test('counts the files it scanned and the declarations it checked', () {
      expect(report.filesScanned, greaterThan(0));
      expect(report.declarationsChecked, greaterThan(report.dead.length));
    });

    test('reports every finding with a usable source location', () {
      for (final finding in [...report.dead, ...report.apiSurface, ...report.docOnly]) {
        expect(finding.line, greaterThan(0), reason: '${finding.qualifiedName} has no line');
        expect(finding.filePath, startsWith('lib/'), reason: '${finding.qualifiedName} is outside lib/');
        expect(finding.filePath, isNot(contains(r'\')), reason: 'paths use forward slashes');
      }
    });

    test('finds exactly the dead declarations the fixture plants', () {
      expect(deadNames().toSet(), {
        // Outside the entry point closure.
        'Internal',
        // Private, so never in the export namespace.
        '_PrivateClass',
        // Planted in lib/src/dead_code_cases.dart, one per rule.
        'DeadInternal',
        '_DeadPrivate',
        '_recursivelyDead',
        'DeadExtension',
        'Holder.unreadField',
        'DocumentationCarrier',
      });
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
