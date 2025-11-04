// ignore_for_file: avoid_print

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../helpers/test_setup.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Version Command Tests', () {
    late TestSetup testSetup;

    setUp(() async {
      testSetup = TestSetup();
      await testSetup.setUp();
    });

    tearDown(() async {
      await testSetup.tearDown();
    });

    test('detects API changes between versions', () async {
      // 1. Copy app_v1 to tempDir
      await copyDir(testSetup.fixtures.appV100Dir, testSetup.tempDir);

      // 2. Initialize git
      await testSetup.setupGitRepo();
      await testSetup.setupFlutterPackage();

      // 4. Commit initial state
      await testSetup.commitChanges(
          'chore!: Initial release v${TestConstants.initialVersion}');

      printOnFailure('Initial version: ${testSetup.getCurrentVersion()}');

      await runProcess('git', ['tag', 'v${TestConstants.initialVersion}'],
          workingDir: testSetup.tempDir.path);

      expect(testSetup.getCurrentVersion(), TestConstants.initialVersion);

      // 5. Copy app_v1_0_1 over tempDir
      await copyDir(testSetup.fixtures.appV101Dir, testSetup.tempDir);

      // 6. Commit changes
      await testSetup
          .commitChanges('API change to v${TestConstants.patchVersion}');

      await testSetup.runApiGuard('version', []);

      expect(testSetup.getCurrentVersion(), TestConstants.patchVersion);

      // 6. Copy app_v2 over tempDir
      await copyDir(testSetup.fixtures.appV110Dir, testSetup.tempDir);

      // 7. Commit changes
      await testSetup
          .commitChanges('API change to v${TestConstants.minorVersion}');

      await testSetup.runApiGuard('version', []);

      expect(testSetup.getCurrentVersion(), TestConstants.minorVersion);

      // 8. Copy app_v3 over tempDir
      await copyDir(testSetup.fixtures.appV200Dir, testSetup.tempDir);
      await testSetup.commitChanges(
          'feat: implement compatibility with v${TestConstants.majorVersion}');

      await testSetup.runApiGuard('version', []);

      expect(testSetup.getCurrentVersion(), TestConstants.majorVersion);

      // Compare the tags
      final tags = await runProcess(
        'git',
        ['tag'],
        workingDir: testSetup.tempDir.path,
        captureOutput: true,
      );
      expect(tags, contains('v${TestConstants.initialVersion}'));
      expect(tags, contains('v${TestConstants.patchVersion}'));
      expect(tags, contains('v${TestConstants.minorVersion}'));
      expect(tags, contains('v${TestConstants.majorVersion}'));

      // 9. Compare output to expected snapshot
      final changelogFile =
          File(p.join(testSetup.tempDir.path, 'CHANGELOG.md'));
      final changelogContent = stripChangelog(
        await changelogFile.readAsString(),
      );

      if (!testSetup.fixtures.expectedChangelogFile.existsSync()) {
        testSetup.fixtures.expectedChangelogFile.createSync();
        testSetup.fixtures.expectedChangelogFile
            .writeAsStringSync(changelogContent);
      }

      final expectedChangelog = stripChangelog(
        await testSetup.fixtures.expectedChangelogFile.readAsString(),
      );

      expect(changelogContent, equalsIgnoringWhitespace(expectedChangelog));
    });

    test('version command fails when no previous version is found', () async {
      // 1. Copy app_v1 to tempDir
      await copyDir(testSetup.fixtures.appV100Dir, testSetup.tempDir);

      // 2. Initialize git
      await testSetup.setupGitRepo();
      await testSetup.setupFlutterPackage();

      // 4. Commit initial state
      await testSetup.commitChanges(
          'chore!: Initial release v${TestConstants.initialVersion}');

      expect(testSetup.getCurrentVersion(), TestConstants.initialVersion);

      // 5. Copy app_v1_0_1 over tempDir
      await copyDir(testSetup.fixtures.appV101Dir, testSetup.tempDir);

      expect(() async => await testSetup.runApiGuard('version', []),
          throwsA(isA<Exception>()));

      expect(testSetup.getCurrentVersion(), TestConstants.initialVersion);
    });

    test('version command fails when uncommitted changes are detected',
        () async {
      await testSetup.setupGitRepo();
      await testSetup.setupFlutterPackage();
      expect(() async => await testSetup.runApiGuard('version', []),
          throwsA(isA<Exception>()));
    });

    test('pre-release flag on version command works as expected', () async {
      await testSetup.setupGitRepo();
      await testSetup.setupFlutterPackage();
      await testSetup.commitChanges(
          'chore!: Initial release v${TestConstants.initialVersion}');
      await runProcess('git', ['tag', 'v${TestConstants.initialVersion}'],
          workingDir: testSetup.tempDir.path);

      expect(testSetup.getCurrentVersion(), TestConstants.initialVersion);

      await copyDir(testSetup.fixtures.appV110Dir, testSetup.tempDir);

      // 7. Commit changes
      await testSetup
          .commitChanges('API change to v${TestConstants.minorVersion}');

      await testSetup.runApiGuard('version', ['--pre-release']);
      expect(testSetup.getCurrentVersion(), '0.1.0-dev.1');

      // 8. Copy app_v3 over tempDir
      await copyDir(testSetup.fixtures.appV200Dir, testSetup.tempDir);
      await testSetup.commitChanges(
          'feat: implement compatibility with v${TestConstants.majorVersion}');

      await testSetup.runApiGuard('version', ['--pre-release']);
      expect(testSetup.getCurrentVersion(), '1.0.0-dev.1');

      await testSetup.runApiGuard('version', []);

      expect(testSetup.getCurrentVersion(), '1.0.0');
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
