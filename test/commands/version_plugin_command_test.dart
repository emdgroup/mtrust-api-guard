// ignore_for_file: avoid_print

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

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

    test('detects Android constraint changes as breaking changes in plugins', () async {
      // 1. Initialize git repo and flutter plugin
      await testSetup.setupGitRepo();
      await testSetup.setupFlutterPlugin();

      // 1.1 Add homepage to pubspec.yaml for testing changelog links
      final pubspecFile = File(p.join(testSetup.tempDir.path, 'pubspec.yaml'));
      var pubspecContent = await pubspecFile.readAsString();

      final updatedPubspecContent = pubspecContent.replaceFirst(
        'homepage:',
        'homepage: https://github.com/emdgroup/mtrust-api-guard/',
      );
      await pubspecFile.writeAsString(updatedPubspecContent);

      // 2. Set up initial version (1.0.0) with initial API
      await copyDir(testSetup.fixtures.appV100Dir, testSetup.tempDir);

      // 2.1 Create initial Android build.gradle file for plugin (android/build.gradle)
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

      // 3. Commit initial state and tag it
      await testSetup.commitChanges('chore!: Initial release v${TestConstants.initialVersion}');

      printOnFailure('Initial version: ${testSetup.getCurrentVersion()}');

      await runProcess('git', ['tag', 'v${TestConstants.initialVersion}'], workingDir: testSetup.tempDir.path);

      expect(testSetup.getCurrentVersion(), TestConstants.initialVersion);

      // 4. Change Android minSdkVersion (19 -> 21) - this should be a breaking change
      final buildGradleFileV200 = File(p.join(androidDir.path, 'build.gradle'));
      await buildGradleFileV200.writeAsString('''
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

      // 5. Commit and run version command to detect major change
      await testSetup.commitChanges('feat: increase Android minSdkVersion to 21');

      await testSetup.runApiGuard('version', ['--verbose']);

      expect(testSetup.getCurrentVersion(), TestConstants.majorVersion);

      // 6. Verify tag was created
      final tags = await runProcess(
        'git',
        ['tag'],
        workingDir: testSetup.tempDir.path,
        captureOutput: true,
      );
      expect(tags, contains('v${TestConstants.initialVersion}'));
      expect(tags, contains('v${TestConstants.majorVersion}'));

      // 7. Verify changelog was generated correctly with Android constraint change
      final changelogFile = File(p.join(testSetup.tempDir.path, 'CHANGELOG.md'));
      final changelogContent = await changelogFile.readAsString();
      printOnFailure('Generated Changelog:\n$changelogContent');

      // Verify changelog contains Android constraint change
      expect(changelogContent, contains('android:minSdkVersion'));
      expect(changelogContent, contains('Android minSdkVersion changed from `19` to `21`'));
      expect(changelogContent, contains('Platform constraint changed'));
      
      // Verify it's listed as a breaking change
      expect(changelogContent, contains('💣 Breaking changes'));
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
