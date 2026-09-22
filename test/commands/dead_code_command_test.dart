import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../helpers/test_helpers.dart';
import '../helpers/test_setup.dart';

void main() {
  group('Dead Code Command Tests', () {
    late TestSetup testSetup;

    setUp(() async {
      testSetup = TestSetup();
      await testSetup.setUp();
    });

    tearDown(() async {
      await testSetup.tearDown();
    });

    /// Runs the command and returns the report it wrote.
    Future<Map<String, dynamic>> runDeadCode({String name = 'dead_code.json', List<String> args = const []}) async {
      final outPath = p.join(testSetup.tempDir.path, name);
      await testSetup.runApiGuard('dead-code', ['-f', 'json', '--out', outPath, ...args]);
      return jsonDecode(File(outPath).readAsStringSync()) as Map<String, dynamic>;
    }

    /// Puts a fixture in place on a fresh git repo and Flutter package.
    Future<void> useFixture(Directory fixture) async {
      await testSetup.setupGitRepo();
      await testSetup.setupFlutterPackage();
      await copyDir(fixture, testSetup.tempDir);
    }

    /// Adds a file nothing reaches, which is what a pull request that
    /// introduces dead code looks like.
    void plantOrphan() {
      File(p.join(testSetup.tempDir.path, 'lib', 'src', 'orphan.dart')).writeAsStringSync('''
class OrphanedHelper {
  String get unusedLabel => 'nobody calls this';
}
''');
    }

    List<String> namesIn(Map<String, dynamic> report, String bucket) => [
      for (final finding in report[bucket] as List) (finding as Map)['qualifiedName'] as String,
    ];

    test('reports a public class outside the entry points as dead', () async {
      await useFixture(testSetup.fixtures.appV100Dir);

      final report = await runDeadCode();

      // `lib/src/internal.dart` is not reachable from the configured entry
      // point, so no consumer can get to `Internal` and nothing in the package
      // uses it either.
      expect(namesIn(report, 'dead'), contains('Internal'));

      // Everything the entry point exports is unreferenced from inside the
      // package, which is what a library looks like. None of it is dead.
      expect(namesIn(report, 'apiSurface'), containsAll(['User', 'Product', 'Status']));
      expect(namesIn(report, 'dead'), isNot(contains('User')));
    });

    test('reports an unreferenced private class as dead', () async {
      await useFixture(testSetup.fixtures.appV100Dir);

      final report = await runDeadCode();

      expect(namesIn(report, 'dead'), contains('_PrivateClass'));
    });

    test('stops reporting a declaration once the next version deletes it', () async {
      await useFixture(testSetup.fixtures.appV100Dir);

      final before = await runDeadCode(name: 'dead_code_v100.json');
      expect(namesIn(before, 'dead'), containsAll(['_PrivateClass', 'Internal']));

      // v101 drops `_PrivateClass` and keeps `internal.dart` outside the entry
      // point, which now reaches through `lib/main.dart`.
      await copyDir(testSetup.fixtures.appV101Dir, testSetup.tempDir);

      final after = await runDeadCode(name: 'dead_code_v101.json');
      expect(namesIn(after, 'dead'), isNot(contains('_PrivateClass')));
      expect(namesIn(after, 'dead'), contains('Internal'));
    });

    test('follows the entry point through a re-exporting library', () async {
      await useFixture(testSetup.fixtures.appV101Dir);

      // v101 points at `lib/main.dart`, which re-exports `lib/src/api.dart`.
      // The closure has to follow that export or the whole API reads as dead.
      final report = await runDeadCode();

      expect(namesIn(report, 'apiSurface'), containsAll(['User', 'Product']));
      expect(namesIn(report, 'dead'), isNot(contains('User')));
    });

    test('finds only unread private members when every declaration is exported', () async {
      await useFixture(testSetup.fixtures.appV110Dir);

      final report = await runDeadCode();

      // Exporting a class does not let a consumer reach its private members,
      // and nothing in the package reads these two.
      expect(
        namesIn(report, 'dead'),
        unorderedEquals(['User._internalId', 'MagnitudeOverrideTest._willNotBeReportedInChangelog']),
      );
      expect(report['apiSurface'], isNotEmpty);
      expect((report['summary'] as Map)['declarationsChecked'], greaterThan(0));
    });

    test('writes no markdown section when there is nothing to warn about', () async {
      await testSetup.setupGitRepo();
      await testSetup.setupFlutterPackage();
      File(p.join(testSetup.tempDir.path, 'lib', 'src', 'api.dart'))
        ..createSync(recursive: true)
        ..writeAsStringSync('class Exported {}\n');

      final outPath = p.join(testSetup.tempDir.path, 'dead_code.md');
      await testSetup.runApiGuard('dead-code', ['-f', 'markdown', '--out', outPath]);

      expect(File(outPath).readAsStringSync().trim(), isEmpty);
    });

    test('renders markdown with links when a base url is given', () async {
      await useFixture(testSetup.fixtures.appV100Dir);

      final outPath = p.join(testSetup.tempDir.path, 'dead_code.md');
      await testSetup.runApiGuard('dead-code', [
        '-f',
        'markdown',
        '--out',
        outPath,
        '--base-url',
        'https://example.test/blob/main',
      ]);

      final markdown = File(outPath).readAsStringSync();
      expect(markdown, contains('⚠️ Dead code'));
      expect(markdown, contains('`Internal`'));
      expect(markdown, contains('https://example.test/blob/main/lib/src/internal.dart'));
    });

    test('writes every --out from a single scan', () async {
      await useFixture(testSetup.fixtures.appV100Dir);

      final jsonPath = p.join(testSetup.tempDir.path, 'report.json');
      final markdownPath = p.join(testSetup.tempDir.path, 'report.md');
      await testSetup.runApiGuard('dead-code', ['--out', jsonPath, '--out', markdownPath]);

      // Each file gets the format its extension names, not `--format`.
      final report = jsonDecode(File(jsonPath).readAsStringSync()) as Map<String, dynamic>;
      expect(namesIn(report, 'dead'), contains('Internal'));
      expect(File(markdownPath).readAsStringSync(), contains('⚠️ Dead code'));
    });

    test('picks up dead code a change introduces', () async {
      await useFixture(testSetup.fixtures.appV110Dir);

      final before = await runDeadCode(name: 'dead_code_before.json');
      expect(namesIn(before, 'dead'), isNot(contains('OrphanedHelper')));

      plantOrphan();

      final after = await runDeadCode(name: 'dead_code_after.json');

      expect(namesIn(after, 'dead'), contains('OrphanedHelper'));
      expect((after['summary'] as Map)['deadCount'], greaterThan((before['summary'] as Map)['deadCount'] as int));
    });

    test('reports the delta when compare is given a git base ref', () async {
      await useFixture(testSetup.fixtures.appV110Dir);
      await testSetup.commitChanges('chore!: Initial release v${TestConstants.initialVersion}');
      await runProcess('git', ['tag', 'v${TestConstants.initialVersion}'], workingDir: testSetup.tempDir.path);

      // A change that adds an exported class and, alongside it, something
      // nothing reaches. The API diff sees the first, the scan sees the second.
      plantOrphan();
      final apiFile = File(p.join(testSetup.tempDir.path, 'lib', 'src', 'api.dart'));
      apiFile.writeAsStringSync('${apiFile.readAsStringSync()}\n\nclass BrandNewExportedClass {}\n');
      await testSetup.commitChanges('feat: add a class and some dead code');

      final outPath = p.join(testSetup.tempDir.path, 'compare_with_dead_code.txt');
      await testSetup.runApiGuard('compare', [
        '--base-ref',
        'v${TestConstants.initialVersion}',
        '--new-ref',
        'HEAD',
        '--out',
        outPath,
        '--dead-code',
      ]);

      final output = await File(outPath).readAsString();

      expect(output, contains('BrandNewExportedClass'), reason: 'the API change is still reported');
      expect(output, contains('Dead code added'));
      expect(output, contains('`OrphanedHelper`'));
      expect(output, contains('added since'), reason: 'compare passes its own base ref through, so this is a delta');
    });

    test('falls back to the full report when compare is given generated api files', () async {
      await useFixture(testSetup.fixtures.appV110Dir);
      await testSetup.commitChanges('chore!: Initial release v${TestConstants.initialVersion}');
      await runProcess('git', ['tag', 'v${TestConstants.initialVersion}'], workingDir: testSetup.tempDir.path);

      final apiFilesDir = Directory(p.join(testSetup.tempDir.parent.path, 'api_files'));
      await apiFilesDir.create(recursive: true);
      final baseApiFile = p.join(apiFilesDir.path, 'api_base.json');
      await testSetup.runApiGuard('generate', ['--out', baseApiFile]);

      // A change that adds an exported class and, alongside it, something
      // nothing reaches. The API diff sees the first, the scan sees the second.
      plantOrphan();
      final apiFile = File(p.join(testSetup.tempDir.path, 'lib', 'src', 'api.dart'));
      apiFile.writeAsStringSync('${apiFile.readAsStringSync()}\n\nclass BrandNewExportedClass {}\n');
      await testSetup.commitChanges('feat: add a class and some dead code');

      final headApiFile = p.join(apiFilesDir.path, 'api_head.json');
      await testSetup.runApiGuard('generate', ['--out', headApiFile]);

      final outPath = p.join(testSetup.tempDir.path, 'compare_with_dead_code.txt');
      await testSetup.runApiGuard('compare', [
        '--base-ref',
        baseApiFile,
        '--new-ref',
        headApiFile,
        '--out',
        outPath,
        '--dead-code',
      ]);

      final output = await File(outPath).readAsString();

      expect(output, contains('BrandNewExportedClass'), reason: 'the API change is still reported');
      expect(output, contains('⚠️ Dead code'));
      expect(output, contains('`OrphanedHelper`'));
    });

    test('--base-ref reports only what the change added', () async {
      await useFixture(testSetup.fixtures.appV110Dir);
      await testSetup.commitChanges('chore!: Initial release v${TestConstants.initialVersion}');
      await runProcess('git', ['tag', 'v${TestConstants.initialVersion}'], workingDir: testSetup.tempDir.path);

      // app_v110 exports everything, so the base revision has nothing dead.
      // Then a change orphans one declaration and leaves the rest alone.
      plantOrphan();
      await testSetup.commitChanges('feat: add something nothing reaches');

      final report = await runDeadCode(args: ['--base-ref', 'v${TestConstants.initialVersion}']);

      expect(namesIn(report, 'introduced'), contains('OrphanedHelper'));
      expect(report['deleted'], isEmpty);
      expect(report['revived'], isEmpty);
      expect(report['baseRef'], 'v${TestConstants.initialVersion}');
    });

    test('--base-ref stays quiet about dead code that predates the change', () async {
      await useFixture(testSetup.fixtures.appV101Dir);
      await testSetup.commitChanges('chore!: Initial release v${TestConstants.initialVersion}');
      await runProcess('git', ['tag', 'v${TestConstants.initialVersion}'], workingDir: testSetup.tempDir.path);

      // app_v101 already has `Internal` sitting outside its entry point. A
      // commit that adds only an exported class should say so, rather than hand
      // the reviewer debt that was there before they started.
      final apiFile = File(p.join(testSetup.tempDir.path, 'lib', 'src', 'api.dart'));
      apiFile.writeAsStringSync('${apiFile.readAsStringSync()}\n\nclass BrandNewExportedClass {}\n');
      await testSetup.commitChanges('feat: add an exported class');

      final report = await runDeadCode(args: ['--base-ref', 'v${TestConstants.initialVersion}']);

      expect(report['introduced'], isEmpty, reason: 'this commit orphaned nothing');
      expect(
        (report['summary'] as Map)['preExistingCount'],
        greaterThan(0),
        reason: 'app_v100 dead code is still counted, just not blamed on this change',
      );
    });

    test('--base-ref reports a deleted declaration as deleted', () async {
      await useFixture(testSetup.fixtures.appV110Dir);
      plantOrphan();
      await testSetup.commitChanges('chore!: Initial release v${TestConstants.initialVersion}');
      await runProcess('git', ['tag', 'v${TestConstants.initialVersion}'], workingDir: testSetup.tempDir.path);

      File(p.join(testSetup.tempDir.path, 'lib', 'src', 'orphan.dart')).deleteSync();
      await testSetup.commitChanges('chore: delete the orphan');

      final report = await runDeadCode(args: ['--base-ref', 'v${TestConstants.initialVersion}']);

      expect(namesIn(report, 'deleted'), contains('OrphanedHelper'));
      expect(report['revived'], isEmpty);
      expect(report['introduced'], isEmpty);
    });

    test('--base-ref separates a declaration that is used now from a deleted one', () async {
      await useFixture(testSetup.fixtures.appV110Dir);
      plantOrphan();
      await testSetup.commitChanges('chore!: Initial release v${TestConstants.initialVersion}');
      await runProcess('git', ['tag', 'v${TestConstants.initialVersion}'], workingDir: testSetup.tempDir.path);

      // The entry point calls the orphan instead of anyone deleting it, so the
      // declaration is still there and a reviewer should not read "deleted".
      final apiFile = File(p.join(testSetup.tempDir.path, 'lib', 'src', 'api.dart'));
      apiFile.writeAsStringSync(
        "import 'orphan.dart';\n\n${apiFile.readAsStringSync()}\n\n"
        'String orphanLabel() => OrphanedHelper().unusedLabel;\n',
      );
      await testSetup.commitChanges('feat: use the orphan');

      final report = await runDeadCode(args: ['--base-ref', 'v${TestConstants.initialVersion}']);

      expect(namesIn(report, 'revived'), contains('OrphanedHelper'));
      expect(report['deleted'], isEmpty);
      expect(report['introduced'], isEmpty);
    });

    test('exits zero even with findings, so a report never blocks a pipeline', () async {
      await useFixture(testSetup.fixtures.appV100Dir);

      // runApiGuard throws on a non-zero exit code, so reaching the assertion
      // is the assertion.
      final report = await runDeadCode();
      expect(report['dead'], isNotEmpty);
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
