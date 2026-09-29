import 'dart:convert';
import 'dart:io';

import 'package:mtrust_api_guard/dead_code/dead_code_finder.dart';
import 'package:mtrust_api_guard/dead_code/dead_code_report.dart';
import 'package:path/path.dart' as p;
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

    Set<String> names(List<DeadDeclaration> bucket) => {for (final finding in bucket) finding.qualifiedName};

    test('finds exactly the dead declarations the fixture plants', () {
      expect(names(report.dead), {
        // Not reachable from the entry point, `lib/src/api.dart`.
        'Internal',
        // In an exported file, but private, so no export namespace carries it.
        '_PrivateClass',
        // Planted in lib/src/dead_code_cases.dart. Its members are dead along
        // with it, and only the class is listed.
        'DeadInternal',
        '_DeadPrivate',
        // Calls itself and nothing else does.
        '_recursivelyDead',
        // Never applied.
        'DeadExtension',
        // Written by the constructor and never read.
        'Holder.unreadField',
        'DocumentationCarrier',
        'Registers._registration',
        // A function, so `jsonEncode` does not call it.
        'toJson',
        // Used by nothing but other dead code, generated or mutual.
        'UsedOnlyByDeadGeneratedCode',
        'DeadCaller',
        'ChainedHelper',
        'MutualA',
        'MutualB',
      });
    });

    test('lists an unreferenced export as API surface', () {
      expect(names(report.apiSurface), containsAll(['User', 'Product', 'Status']));
    });

    test('lists what only a doc comment mentions on its own', () {
      expect(names(report.docOnly), {'DocumentedOnly'});
    });

    // The false positives, each with what keeps it out of the report.
    const alive = {
      'UsedInternally': 'bin/ refers to it',
      'UsedOnlyByBin': 'bin/ refers to it',
      'UsedOnlyByTest': 'test/ refers to it',
      'UsedByGenerated': 'live generated code refers to it',
      'GeneratedHelper': 'it is generated',
      'GeneratedDead': 'it is generated',
      '_register': 'an instance field initializer calls it',
      'Listed.first': 'values is read',
      'Listed.second': 'values is read',
      'Ticker._ticks': 'an increment reads it',
      'Dial.level': 'an assignment calls the setter',
      'Dial.[]=': 'an assignment calls it',
      'Point.doubled': 'a pattern reads it',
      '_twice': 'a getter read through a pattern calls it',
      'Vec.+': 'a + b resolves to it',
      'StringShouting': 'a member of it is applied',
      'Constants._': 'it is the only constructor of its class',
      'Holder': 'it is constructed',
      'Holder.readField': 'it is read',
      'Base.hook': 'it is called',
      'Subclass.hook': 'the member it overrides is called',
      'Shape.area': 'it is abstract and an override of it is called',
      'Serializable.toJson': 'jsonEncode calls it',
      'nativeCallback': 'it is a vm entry point',
      'main': 'it is main',
    };
    for (final MapEntry(key: name, value: reason) in alive.entries) {
      test('does not report $name, because $reason', () {
        expect(
          [...report.dead, ...report.apiSurface, ...report.docOnly].map((d) => d.qualifiedName),
          isNot(contains(name)),
        );
      });
    }

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
  }, timeout: const Timeout(Duration(minutes: 5)));

  group('DeadCodeFinder on package layouts', () {
    late Directory packageDir;
    late DeadCodeReport report;

    setUpAll(() async {
      // `example/` has a pubspec of its own, the way a Flutter package's
      // example app does, so it is resolved on its own too.
      packageDir = await materializeFixturePackage(TestFixtures().deadCodeLayoutDir, 'dead_code_layout');
      report = await DeadCodeFinder(root: packageDir).run();
    });

    tearDownAll(() async {
      if (packageDir.existsSync()) await packageDir.delete(recursive: true);
    });

    Set<String> names(List<DeadDeclaration> bucket) => {for (final finding in bucket) finding.qualifiedName};

    test('finds exactly the dead declarations the fixture plants', () {
      expect(names(report.dead), {
        '_ioHelperNobodyCalls',
        // Private, so exporting `Api` does not make it reachable.
        'Api._neverCalled',
        // Only its own generated code refers to it.
        'Draft',
      });
    });

    test('lists exactly the exports nothing in the package refers to as API surface', () {
      // `greeting` is a top-level variable, exported as its getter, and a doc
      // comment links to it as well.
      expect(names(report.apiSurface), {'greeting', 'Api', 'Greeter.greet'});
    });

    const alive = {
      'UsedOnlyByExample': 'a nested example package refers to it',
      'Model.value': 'a part that analyzer.exclude hides reads it',
      'platformName': 'it is a branch of a conditional export',
      '_PoliteGreeter.greet': 'it overrides an exported member',
    };
    for (final MapEntry(key: name, value: reason) in alive.entries) {
      test('does not report $name, because $reason', () {
        expect(
          [...report.dead, ...report.apiSurface, ...report.docOnly].map((d) => d.qualifiedName),
          isNot(contains(name)),
        );
      });
    }
  }, timeout: const Timeout(Duration(minutes: 5)));

  group('unresolvedPackageWarning', () {
    late Directory temp;

    setUp(() => temp = Directory.systemTemp.createTempSync('api_guard_resolution_'));
    tearDown(() => temp.deleteSync(recursive: true));

    void writePubspec(String directory, String fields) {
      Directory(directory).createSync(recursive: true);
      File(p.join(directory, 'pubspec.yaml')).writeAsStringSync('''
$fields
publish_to: none
environment:
  sdk: ">=3.11.0 <4.0.0"
''');
    }

    Future<void> pubGet(String directory) async {
      final result = await Process.run('dart', ['pub', 'get'], workingDirectory: directory);
      if (result.exitCode != 0) throw StateError('dart pub get failed in $directory: ${result.stderr}');
    }

    test('asks for pub get when the package was never resolved', () {
      writePubspec(temp.path, 'name: never_resolved');

      expect(unresolvedPackageWarning(temp.path), contains('Run pub get first'));
    });

    test('accepts a pub workspace member, which is resolved at the workspace root', () async {
      writePubspec(temp.path, 'name: workspace_root\nworkspace:\n  - member');
      final member = p.join(temp.path, 'member');
      writePubspec(member, 'name: member\nresolution: workspace');
      await pubGet(temp.path);

      expect(File(p.join(member, '.dart_tool', 'package_config.json')).existsSync(), isFalse);
      expect(unresolvedPackageWarning(member), isNull);
    });

    test('names the packages the package config points at that are gone', () async {
      writePubspec(temp.path, 'name: pruned');
      await pubGet(temp.path);
      final config = File(p.join(temp.path, '.dart_tool', 'package_config.json'));
      final json = jsonDecode(config.readAsStringSync()) as Map<String, dynamic>;
      (json['packages'] as List).add({'name': 'vanished', 'rootUri': '../vanished/', 'packageUri': 'lib/'});
      config.writeAsStringSync(jsonEncode(json));

      expect(unresolvedPackageWarning(temp.path), contains('vanished'));
    });
  });
}
