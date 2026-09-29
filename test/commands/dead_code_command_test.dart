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

      // Each file gets the format its extension names, not `--format`. That
      // there are findings did not fail the command either: runApiGuard throws
      // on a non-zero exit code.
      final report = jsonDecode(File(jsonPath).readAsStringSync()) as Map<String, dynamic>;
      expect(namesIn(report, 'dead'), contains('Internal'));
      expect(File(markdownPath).readAsStringSync(), contains('⚠️ Dead code'));
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

    test('compare scans the new ref rather than the working tree', () async {
      await useFixture(testSetup.fixtures.appV110Dir);
      await testSetup.commitChanges('chore!: Initial release v${TestConstants.initialVersion}');
      await runProcess('git', ['tag', 'v${TestConstants.initialVersion}'], workingDir: testSetup.tempDir.path);

      final apiFile = File(p.join(testSetup.tempDir.path, 'lib', 'src', 'api.dart'));
      apiFile.writeAsStringSync('${apiFile.readAsStringSync()}\n\nclass BrandNewExportedClass {}\n');
      await testSetup.commitChanges('feat: add a class');
      await runProcess('git', ['tag', 'v${TestConstants.minorVersion}'], workingDir: testSetup.tempDir.path);

      // Dead code that only exists after the ref being compared. Both halves of
      // the comparison are asked about the same two tags, so neither should see
      // it.
      plantOrphan();
      await testSetup.commitChanges('chore: add something nothing reaches');

      final outPath = p.join(testSetup.tempDir.path, 'compare_at_ref.txt');
      await testSetup.runApiGuard('compare', [
        '--base-ref',
        'v${TestConstants.initialVersion}',
        '--new-ref',
        'v${TestConstants.minorVersion}',
        '--out',
        outPath,
        '--dead-code',
      ]);

      final output = await File(outPath).readAsString();

      expect(output, contains('BrandNewExportedClass'), reason: 'the API half still compares the two refs');
      expect(output, isNot(contains('OrphanedHelper')), reason: 'the orphan is younger than the ref compared');
    });

    test('--base-ref HEAD reports what an uncommitted change added', () async {
      await useFixture(testSetup.fixtures.appV110Dir);
      await testSetup.commitChanges('chore!: Initial release v${TestConstants.initialVersion}');

      // Left uncommitted, so the working tree is no longer what HEAD names.
      plantOrphan();

      final report = await runDeadCode(args: ['--base-ref', 'HEAD']);

      expect(namesIn(report, 'introduced'), ['OrphanedHelper']);
      expect(report['deleted'], isEmpty);
      expect(report['revived'], isEmpty);
      expect(report['baseRef'], 'HEAD');
    });

    test('--base-ref finds the package when run from below the repository root', () async {
      await testSetup.setupGitRepo();
      final package = Directory(p.join(testSetup.tempDir.path, 'packages', 'nested'));
      await copyDir(testSetup.fixtures.packageBaseDir, package);
      await copyDir(testSetup.fixtures.appV110Dir, package);
      await testSetup.commitChanges('chore!: Initial release v${TestConstants.initialVersion}');

      File(p.join(package.path, 'lib', 'src', 'orphan.dart')).writeAsStringSync('class OrphanedHelper {}\n');
      await testSetup.commitChanges('feat: add something nothing reaches');

      // The worktree of the base has the package under `packages/nested` too,
      // not at its root, which is where the command runs from.
      final outPath = p.join(testSetup.tempDir.path, 'dead_code.json');
      await testSetup.runApiGuard('dead-code', ['--base-ref', 'HEAD~1', '--out', outPath], workingDirectory: package);

      final report = jsonDecode(File(outPath).readAsStringSync()) as Map<String, dynamic>;
      expect(namesIn(report, 'introduced'), ['OrphanedHelper']);
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

    test('--base-ref tells a deleted declaration from one that is used now', () async {
      await useFixture(testSetup.fixtures.appV110Dir);
      plantOrphan();
      final gone = File(p.join(testSetup.tempDir.path, 'lib', 'src', 'gone.dart'))
        ..writeAsStringSync('class GoneHelper {}\n');
      await testSetup.commitChanges('chore!: Initial release v${TestConstants.initialVersion}');
      await runProcess('git', ['tag', 'v${TestConstants.initialVersion}'], workingDir: testSetup.tempDir.path);

      // One orphan is deleted. The other is called from the entry point, so
      // its declaration is still there and a reviewer should not read
      // "deleted".
      gone.deleteSync();
      final apiFile = File(p.join(testSetup.tempDir.path, 'lib', 'src', 'api.dart'));
      apiFile.writeAsStringSync(
        "import 'orphan.dart';\n\n${apiFile.readAsStringSync()}\n\n"
        'String orphanLabel() => OrphanedHelper().unusedLabel;\n',
      );
      await testSetup.commitChanges('feat: delete one orphan and use the other');

      final report = await runDeadCode(args: ['--base-ref', 'v${TestConstants.initialVersion}']);

      expect(namesIn(report, 'deleted'), ['GoneHelper']);
      expect(namesIn(report, 'revived'), ['OrphanedHelper']);
      expect(report['introduced'], isEmpty);
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
