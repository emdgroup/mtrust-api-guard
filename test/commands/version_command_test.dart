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
      // 1. Initialize git repo and flutter package
      await testSetup.setupGitRepo();
      await testSetup.setupFlutterPackage();

      // 2. Set up initial version (1.0.0)
      await copyDir(testSetup.fixtures.appV100Dir, testSetup.tempDir);

      // 3. Commit initial state and tag it
      await testSetup.commitChanges('chore!: Initial release v${TestConstants.initialVersion}');

      printOnFailure('Initial version: ${testSetup.getCurrentVersion()}');

      await runProcess('git', ['tag', 'v${TestConstants.initialVersion}'], workingDir: testSetup.tempDir.path);

      expect(testSetup.getCurrentVersion(), TestConstants.initialVersion);

      // 4. Apply patch-level changes (1.0.0 -> 1.0.1)
      await copyDir(testSetup.fixtures.appV101Dir, testSetup.tempDir);

      // 5. Commit and run version command to detect patch change
      await testSetup.commitChanges('API change to v${TestConstants.patchVersion}');

      await testSetup.runApiGuard('version', []);

      expect(testSetup.getCurrentVersion(), TestConstants.patchVersion);

      // 6. Apply minor-level changes (1.0.1 -> 1.1.0)
      await copyDir(testSetup.fixtures.appV110Dir, testSetup.tempDir);

      // 7. Commit and run version command to detect minor change
      await testSetup.commitChanges('API change to v${TestConstants.minorVersion}');

      await testSetup.runApiGuard('version', []);

      expect(testSetup.getCurrentVersion(), TestConstants.minorVersion);

      // 8. Apply major-level changes (1.1.0 -> 2.0.0)
      await copyDir(testSetup.fixtures.appV200Dir, testSetup.tempDir);
      await testSetup.commitChanges('feat: implement compatibility with v${TestConstants.majorVersion}');

      await testSetup.runApiGuard('version', []);

      expect(testSetup.getCurrentVersion(), TestConstants.majorVersion);

      // 9. Verify all version tags were created
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

      // 10. Verify changelog was generated correctly
      final changelogFile = File(p.join(testSetup.tempDir.path, 'CHANGELOG.md'));
      final changelogContent = stripChangelog(
        await changelogFile.readAsString(),
      );

      if (!testSetup.fixtures.expectedChangelogFile.existsSync()) {
        testSetup.fixtures.expectedChangelogFile.createSync();
        testSetup.fixtures.expectedChangelogFile.writeAsStringSync(changelogContent);
      }

      final expectedChangelog = stripChangelog(
        await testSetup.fixtures.expectedChangelogFile.readAsString(),
      );

      expect(changelogContent, equalsIgnoringWhitespace(expectedChangelog));
    });

    test('version command fails when no previous version is found', () async {
      // 1. Initialize git repo without any tags
      await testSetup.setupGitRepo();
      await testSetup.setupFlutterPackage();

      // 2. Set up initial version
      await copyDir(testSetup.fixtures.appV100Dir, testSetup.tempDir);

      // 3. Commit initial state (but don't tag it)
      await testSetup.commitChanges('chore!: Initial release v${TestConstants.initialVersion}');

      expect(testSetup.getCurrentVersion(), TestConstants.initialVersion);

      // 4. Make changes and attempt version command
      await copyDir(testSetup.fixtures.appV101Dir, testSetup.tempDir);

      expect(() async => await testSetup.runApiGuard('version', []), throwsA(isA<Exception>()));

      expect(testSetup.getCurrentVersion(), TestConstants.initialVersion);
    });

    test('version command fails when uncommitted changes are detected', () async {
      await testSetup.setupGitRepo();
      await testSetup.setupFlutterPackage();
      // Copy files but don't commit them
      await copyDir(testSetup.fixtures.appV100Dir, testSetup.tempDir);
      // Should fail due to uncommitted changes
      expect(() async => await testSetup.runApiGuard('version', []), throwsA(isA<Exception>()));
    });

    test('pre-release flag on version command works as expected', () async {
      // 1. Set up initial tagged version
      await testSetup.setupGitRepo();
      await testSetup.setupFlutterPackage();
      await copyDir(testSetup.fixtures.appV100Dir, testSetup.tempDir);
      await testSetup.commitChanges('chore!: Initial release v${TestConstants.initialVersion}');
      await runProcess('git', ['tag', 'v${TestConstants.initialVersion}'], workingDir: testSetup.tempDir.path);

      expect(testSetup.getCurrentVersion(), TestConstants.initialVersion);

      // 2. Apply minor changes and create pre-release version
      await copyDir(testSetup.fixtures.appV110Dir, testSetup.tempDir);
      await testSetup.commitChanges('API change to v${TestConstants.minorVersion}');

      await testSetup.runApiGuard('version', ['--pre-release']);
      expect(testSetup.getCurrentVersion(), '0.1.0-dev.1');

      // 3. Apply major changes and create another pre-release
      await copyDir(testSetup.fixtures.appV200Dir, testSetup.tempDir);
      await testSetup.commitChanges('feat: implement compatibility with v${TestConstants.majorVersion}');

      await testSetup.runApiGuard('version', ['--pre-release']);
      expect(testSetup.getCurrentVersion(), '1.0.0-dev.1');

      // 4. Finalize the release (removes pre-release suffix)
      await testSetup.runApiGuard('version', []);

      expect(testSetup.getCurrentVersion(), '1.0.0');
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
