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

      // 1.1 Add homepage to pubspec.yaml for testing changelog links
      final pubspecFile = File(p.join(testSetup.tempDir.path, 'pubspec.yaml'));
      var pubspecContent = await pubspecFile.readAsString();

      // Normalize SDK constraint to ensure consistent test results regardless of local Flutter version
      pubspecContent = pubspecContent.replaceAll(
        RegExp(r'sdk:.*'),
        'sdk: ">=3.0.0 <4.0.0"',
      );

      final updatedPubspecContent = pubspecContent.replaceFirst(
        'homepage:',
        'homepage: https://github.com/emdgroup/mtrust-api-guard/',
      );
      await pubspecFile.writeAsString(updatedPubspecContent);

      // 2. Set up initial version (1.0.0)
      await copyDir(testSetup.fixtures.appV100Dir, testSetup.tempDir);

      // Add initial android constraints
      final androidDir = Directory(p.join(testSetup.tempDir.path, 'android', 'app'));
      if (!androidDir.existsSync()) {
        androidDir.createSync(recursive: true);
      }
      final gradleFile = File(p.join(androidDir.path, 'build.gradle'));
      await gradleFile.writeAsString('''
android {
    defaultConfig {
        minSdkVersion 19
        targetSdkVersion 30
        compileSdkVersion 30
    }
}
''');

      // 3. Commit initial state and tag it
      await testSetup.commitChanges('chore!: Initial release v${TestConstants.initialVersion}');

      printOnFailure('Initial version: ${testSetup.getCurrentVersion()}');

      await runProcess('git', ['tag', 'v${TestConstants.initialVersion}'], workingDir: testSetup.tempDir.path);

      expect(testSetup.getCurrentVersion(), TestConstants.initialVersion);

      // 4. Apply patch-level changes (1.0.0 -> 1.0.1)
      await copyDir(testSetup.fixtures.appV101Dir, testSetup.tempDir);

      // Add a dependency
      final pubspecFileV101 = File(p.join(testSetup.tempDir.path, 'pubspec.yaml'));
      var pubspecContentV101 = await pubspecFileV101.readAsString();
      // Add path dependency to avoid pub get issues
      pubspecContentV101 = pubspecContentV101.replaceFirst(
        'dependencies:',
        'dependencies:\n  path: ^1.8.0',
      );
      await pubspecFileV101.writeAsString(pubspecContentV101);

      // 5. Commit and run version command to detect patch change
      await testSetup.commitChanges('fix: add _internalId to Product, remove _PrivateClass');
      await testSetup.runApiGuard('version', ["--verbose"]);

      expect(testSetup.getCurrentVersion(), TestConstants.patchVersion);

      // 6. Apply minor-level changes (1.0.1 -> 1.1.0)
      await copyDir(testSetup.fixtures.appV110Dir, testSetup.tempDir);

      // Remove dependency added in previous step
      final pubspecFileV110 = File(p.join(testSetup.tempDir.path, 'pubspec.yaml'));
      var pubspecContentV110 = await pubspecFileV110.readAsString();
      pubspecContentV110 = pubspecContentV110.replaceFirst(
        'dependencies:\n  path: ^1.8.0',
        'dependencies:',
      );
      await pubspecFileV110.writeAsString(pubspecContentV110);

      // 7. Commit and run version command to detect minor change
      await testSetup.commitChanges('API change to v${TestConstants.minorVersion}');

      await testSetup.runApiGuard('version', ["--verbose"]);

      expect(testSetup.getCurrentVersion(), TestConstants.minorVersion);

      // 8. Apply major-level changes (1.1.0 -> 2.0.0)
      await copyDir(testSetup.fixtures.appV200Dir, testSetup.tempDir);

      // Change android constraints
      final gradleFileV200 = File(p.join(testSetup.tempDir.path, 'android', 'app', 'build.gradle'));
      await gradleFileV200.writeAsString('''
android {
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 30
        compileSdkVersion 30
    }
}
''');

      // Change SDK constraints (Breaking change)
      final pubspecFileV200 = File(p.join(testSetup.tempDir.path, 'pubspec.yaml'));
      var pubspecContentV200 = await pubspecFileV200.readAsString();
      pubspecContentV200 = pubspecContentV200.replaceFirst(
        'sdk: ">=3.0.0 <4.0.0"',
        'sdk: ">=3.2.0 <4.0.0"',
      );
      await pubspecFileV200.writeAsString(pubspecContentV200);

      await testSetup.commitChanges('feat: implement compatibility with v${TestConstants.majorVersion}');

      await testSetup.runApiGuard('version', ["--verbose"]);

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
      printOnFailure('Generated Changelog:\n$changelogContent');

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

    test('custom tag prefix works correctly', () async {
      // 1. Set up initial tagged version with custom prefix
      await testSetup.setupGitRepo();
      await testSetup.setupFlutterPackage();
      await copyDir(testSetup.fixtures.appV100Dir, testSetup.tempDir);
      await testSetup.commitChanges('chore!: Initial release ${TestConstants.initialVersion}');
      await runProcess('git', ['tag', 'release/${TestConstants.initialVersion}'], workingDir: testSetup.tempDir.path);

      expect(testSetup.getCurrentVersion(), TestConstants.initialVersion);

      // 2. Apply patch-level changes and use custom prefix
      await copyDir(testSetup.fixtures.appV101Dir, testSetup.tempDir);
      await testSetup.commitChanges('fix: add _internalId to Product');

      await testSetup.runApiGuard('version', ['--tag-prefix', 'release/']);
      expect(testSetup.getCurrentVersion(), TestConstants.patchVersion);

      // 3. Verify tag was created with custom prefix
      final tags = await runProcess(
        'git',
        ['tag'],
        workingDir: testSetup.tempDir.path,
        captureOutput: true,
      );
      expect(tags, contains('release/${TestConstants.initialVersion}'));
      expect(tags, contains('release/${TestConstants.patchVersion}'));
      expect(tags, isNot(contains('v${TestConstants.patchVersion}')));
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
