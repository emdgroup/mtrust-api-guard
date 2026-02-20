// ignore_for_file: avoid_print

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../helpers/test_setup.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Version Plugin Command Tests', () {
    late TestSetup testSetup;

    setUp(() async {
      testSetup = TestSetup();
      await testSetup.setUp();
    });

    tearDown(() async {
      await testSetup.tearDown();
    });

    /// Helper to update pubspec.yaml using YamlEditor
    Future<void> _updatePubspec(String filePath, List<Object> path, dynamic value) async {
      final pubspecFile = File(filePath);
      final pubspecContent = await pubspecFile.readAsString();
      final editor = YamlEditor(pubspecContent);
      editor.update(path, value);
      await pubspecFile.writeAsString(editor.toString());
    }

    /// Common setup helper: Initialize git repo, Flutter plugin, add homepage, and set up initial version
    /// Returns before committing so tests can add their constraint files first
    Future<void> _setupPluginBase() async {
      // Initialize git repo and flutter plugin
      await testSetup.setupGitRepo();
      await testSetup.setupFlutterPlugin();

      // Add homepage to pubspec.yaml for testing changelog links
      final pubspecFile = File(p.join(testSetup.tempDir.path, 'pubspec.yaml'));
      await _updatePubspec(
        pubspecFile.path,
        ['homepage'],
        'https://github.com/emdgroup/mtrust-api-guard/',
      );

      // Set up initial version 0.0.1 with initial API
      await copyDir(testSetup.fixtures.appV100Dir, testSetup.tempDir);
    }

    /// Helper to verify version bump and changelog
    Future<void> _verifyVersionBumpAndChangelog({
      required String expectedChangelogText,
      String? additionalChangelogText,
    }) async {
      await testSetup.runApiGuard('version', ['--verbose']);

      expect(testSetup.getCurrentVersion(), TestConstants.majorVersion);

      // Verify tag was created
      final tags = await runProcess(
        'git',
        ['tag'],
        workingDir: testSetup.tempDir.path,
        captureOutput: true,
      );
      expect(tags, contains('v${TestConstants.initialVersion}'));
      expect(tags, contains('v${TestConstants.majorVersion}'));

      // Verify changelog was generated correctly
      final changelogFile = File(p.join(testSetup.tempDir.path, 'CHANGELOG.md'));
      final changelogContent = await changelogFile.readAsString();
      printOnFailure('Generated Changelog:\n$changelogContent');

      // Verify changelog contains expected constraint change
      expect(changelogContent, contains(expectedChangelogText));
      if (additionalChangelogText != null) {
        expect(changelogContent, contains(additionalChangelogText));
      }

      // Verify it's listed as a breaking change
      expect(changelogContent, contains('💣 Breaking changes'));
    }

    test('detects Dart SDK constraint changes as breaking changes in plugins', () async {
      await _setupPluginBase();

      // Set up initial Dart SDK constraint in pubspec.yaml
      final pubspecFile = File(p.join(testSetup.tempDir.path, 'pubspec.yaml'));
      await _updatePubspec(
        pubspecFile.path,
        ['environment', 'sdk'],
        '^2.12.0',
      );

      // Commit initial state with Dart SDK constraint and tag it
      await testSetup.commitChanges('chore!: Initial release v${TestConstants.initialVersion}');
      await runProcess('git', ['tag', 'v${TestConstants.initialVersion}'], workingDir: testSetup.tempDir.path);
      expect(testSetup.getCurrentVersion(), TestConstants.initialVersion);

      // Change Dart SDK constraint from ^2.12.0 to ^3.0.0
      await _updatePubspec(
        pubspecFile.path,
        ['environment', 'sdk'],
        '^3.0.0',
      );

      await testSetup.commitChanges('feat: increase Dart SDK constraint to ^3.0.0');

      await _verifyVersionBumpAndChangelog(
        expectedChangelogText: '🎯 Minimum Dart SDK version increased:',
        additionalChangelogText: 'from `^2.12.0` to `^3.0.0`',
      );
    });

    test('detects Flutter constraint changes as breaking changes in plugins', () async {
      await _setupPluginBase();

      // Set up initial Flutter constraint in pubspec.yaml
      final pubspecFile = File(p.join(testSetup.tempDir.path, 'pubspec.yaml'));

      await _updatePubspec(
        pubspecFile.path,
        ['environment', 'flutter'],
        '^3.0.0',
      );

      // Commit initial state with Flutter constraint and tag it
      await testSetup.commitChanges('chore!: Initial release v${TestConstants.initialVersion}');
      await runProcess('git', ['tag', 'v${TestConstants.initialVersion}'], workingDir: testSetup.tempDir.path);
      expect(testSetup.getCurrentVersion(), TestConstants.initialVersion);

      await _updatePubspec(
        pubspecFile.path,
        ['environment', 'flutter'],
        '^3.5.0',
      );

      await testSetup.commitChanges('feat: increase Flutter constraint to ^3.5.0');

      await _verifyVersionBumpAndChangelog(
        expectedChangelogText: '🎯 Minimum Flutter SDK version increased:',
        additionalChangelogText: 'from `^3.0.0` to `^3.5.0`',
      );
    });

    test('detects Android constraint changes as breaking changes in plugins', () async {
      await _setupPluginBase();

      // Create initial Android build.gradle file for plugin (android/build.gradle)
      final androidDir = Directory(p.join(testSetup.tempDir.path, 'android'));
      await androidDir.create(recursive: true);
      final buildGradleFile = File(p.join(androidDir.path, 'build.gradle'));
      await buildGradleFile.writeAsString('''
group 'com.example.api_guard_test'
version '1.0-SNAPSHOT'

buildscript {
    ext.kotlin_version = '1.7.10'
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:7.3.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:\$kotlin_version"
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

apply plugin: 'com.android.library'

android {
    compileSdkVersion 33

    defaultConfig {
        minSdkVersion 19
    }
}
''');

      // Commit initial state with Android constraint and tag it
      await testSetup.commitChanges('chore!: Initial release v${TestConstants.initialVersion}');
      await runProcess('git', ['tag', 'v${TestConstants.initialVersion}'], workingDir: testSetup.tempDir.path);
      expect(testSetup.getCurrentVersion(), TestConstants.initialVersion);

      // Change Android minSdkVersion (19 -> 21) - this should be a breaking change
      await buildGradleFile.writeAsString('''
group 'com.example.api_guard_test'
version '1.0-SNAPSHOT'

buildscript {
    ext.kotlin_version = '1.7.10'
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:7.3.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:\$kotlin_version"
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

apply plugin: 'com.android.library'

android {
    compileSdkVersion 33

    defaultConfig {
        minSdkVersion 21
    }
}
''');

      await testSetup.commitChanges('feat: increase Android minSdkVersion to 21');

      await _verifyVersionBumpAndChangelog(
        expectedChangelogText: '🤖 Minimum Android SDK version increased:',
        additionalChangelogText: 'from `19` to `21`',
      );
    });

    test('detects iOS constraint changes as breaking changes in plugins', () async {
      await _setupPluginBase();

      // Create initial iOS .podspec file with platform version
      final iosDir = Directory(p.join(testSetup.tempDir.path, 'ios'));
      await iosDir.create(recursive: true);
      final podspecFile = File(p.join(iosDir.path, 'api_guard_test.podspec'));
      await podspecFile.writeAsString('''
Pod::Spec.new do |s|
  s.name             = 'api_guard_test'
  s.version          = '0.0.1'
  s.summary          = 'A test plugin'
  s.description      = 'A test plugin for API guard'
  s.homepage         = 'https://github.com/emdgroup/mtrust-api-guard'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Test' => 'test@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.platform         = :ios, '12.0'
end
''');

      // Commit initial state with iOS constraint and tag it
      await testSetup.commitChanges('chore!: Initial release v${TestConstants.initialVersion}');
      await runProcess('git', ['tag', 'v${TestConstants.initialVersion}'], workingDir: testSetup.tempDir.path);
      expect(testSetup.getCurrentVersion(), TestConstants.initialVersion);

      // Change iOS minimum OS version (12.0 -> 13.0) - this should be a breaking change
      await podspecFile.writeAsString('''
Pod::Spec.new do |s|
  s.name             = 'api_guard_test'
  s.version          = '0.0.1'
  s.summary          = 'A test plugin'
  s.description      = 'A test plugin for API guard'
  s.homepage         = 'https://github.com/emdgroup/mtrust-api-guard'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Test' => 'test@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.platform         = :ios, '13.0'
end
''');

      await testSetup.commitChanges('feat: increase iOS minimum OS version to 13.0');

      await _verifyVersionBumpAndChangelog(
        expectedChangelogText: '🍎 Minimum iOS SDK version increased:',
        additionalChangelogText: 'from `12.0` to `13.0`',
      );
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
