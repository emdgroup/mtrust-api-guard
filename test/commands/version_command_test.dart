// ignore_for_file: avoid_print

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:recase/recase.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

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
      final pubspecContent = await pubspecFile.readAsString();
      final updatedPubspecContent = pubspecContent.replaceFirst(
        'homepage:',
        'homepage: https://github.com/emdgroup/mtrust-api-guard/',
      );
      await pubspecFile.writeAsString(updatedPubspecContent);

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
      await testSetup.commitChanges('fix: add _internalId to Product, remove _PrivateClass');
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

    test('dart-file option generates version constant file', () async {
      // 1. Set up initial tagged version
      await testSetup.setupGitRepo();
      await testSetup.setupFlutterPackage();
      await copyDir(testSetup.fixtures.appV100Dir, testSetup.tempDir);
      await testSetup.commitChanges('chore!: Initial release v${TestConstants.initialVersion}');
      await runProcess('git', ['tag', 'v${TestConstants.initialVersion}'], workingDir: testSetup.tempDir.path);

      expect(testSetup.getCurrentVersion(), TestConstants.initialVersion);

      // 2. Get package name from pubspec.yaml
      final pubspecFile = File(p.join(testSetup.tempDir.path, 'pubspec.yaml'));
      final pubspecContent = await pubspecFile.readAsString();
      final pubspec = loadYaml(pubspecContent) as YamlMap;
      final packageName = pubspec['name'] as String;

      // 3. Apply patch-level changes and run version command with --dart-file
      await copyDir(testSetup.fixtures.appV101Dir, testSetup.tempDir);
      await testSetup.commitChanges('fix: add _internalId to Product');

      final dartFilePath = p.join(testSetup.tempDir.path, 'lib', 'version_info.dart');
      await testSetup.runApiGuard('version', ['--dart-file', dartFilePath]);

      expect(testSetup.getCurrentVersion(), TestConstants.patchVersion);

      // 4. Verify Dart file was created with correct content
      final dartFile = File(dartFilePath);
      expect(dartFile.existsSync(), isTrue);

      final dartContent = await dartFile.readAsString();
      // Convert package name to camelCase using recase (matching implementation)
      final camelCasePackageName = ReCase(packageName).camelCase;
      final expectedConstantName = '${camelCasePackageName}Version';
      final expectedContent = "const String $expectedConstantName = '${TestConstants.patchVersion}';\n";

      expect(dartContent, equals(expectedContent));
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
