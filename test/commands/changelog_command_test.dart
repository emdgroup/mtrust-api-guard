// ignore_for_file: avoid_print

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../helpers/test_setup.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Changelog Command Tests', () {
    late TestSetup testSetup;

    setUp(() async {
      testSetup = TestSetup();
      await testSetup.setUp();
    });

    tearDown(() async {
      await testSetup.tearDown();
    });

    Future<void> updatePubspec(String filePath, List<Object> path, dynamic value) async {
      final pubspecFile = File(filePath);
      final pubspecContent = await pubspecFile.readAsString();
      final editor = YamlEditor(pubspecContent);
      editor.update(path, value);
      await pubspecFile.writeAsString(editor.toString());
    }

    test('regenerate overwrites CHANGELOG.md from version tags', () async {
      await testSetup.setupGitRepo();
      await testSetup.setupFlutterPackage();
      await copyDir(testSetup.fixtures.appV100Dir, testSetup.tempDir);

      final pubspecFile = File(p.join(testSetup.tempDir.path, 'pubspec.yaml'));
      await updatePubspec(pubspecFile.path, ['homepage'], 'https://github.com/emdgroup/mtrust-api-guard/');

      await testSetup.commitChanges('chore!: Initial release v${TestConstants.initialVersion}');
      await runProcess('git', ['tag', 'v${TestConstants.initialVersion}'], workingDir: testSetup.tempDir.path);

      await copyDir(testSetup.fixtures.appV101Dir, testSetup.tempDir);
      testSetup.setVersion(TestConstants.patchVersion);
      await testSetup.commitChanges('fix: API changes for v${TestConstants.patchVersion}');
      await runProcess('git', ['tag', 'v${TestConstants.patchVersion}'], workingDir: testSetup.tempDir.path);

      await testSetup.runApiGuard('changelog', ['--regenerate', '--ignore-lagging-tags']);

      final changelogFile = File(p.join(testSetup.tempDir.path, 'CHANGELOG.md'));
      expect(changelogFile.existsSync(), isTrue);

      final changelog = await changelogFile.readAsString();
      printOnFailure('Regenerated changelog:\n$changelog');

      final versionHeaders = RegExp(r'^## (.+)$', multiLine: true).allMatches(changelog).map((m) => m.group(1)).toList();

      expect(versionHeaders.first, TestConstants.patchVersion);
      expect(versionHeaders, contains(TestConstants.initialVersion));
      expect(versionHeaders.indexOf(TestConstants.patchVersion), lessThan(versionHeaders.indexOf(TestConstants.initialVersion)));
      expect(changelog, contains('### API Changes'));
      expect(changelog, contains('Released on:'));
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('regenerate tolerates an empty initial commit with no Dart project', () async {
      await testSetup.setupGitRepo();

      // Empty initial commit without a pubspec.yaml, mirroring the broken
      // first-commit scenario that previously crashed regeneration.
      await runProcess('git', ['commit', '--allow-empty', '-m', 'chore: init'], workingDir: testSetup.tempDir.path);

      await testSetup.setupFlutterPackage();
      await copyDir(testSetup.fixtures.appV100Dir, testSetup.tempDir);
      await testSetup.commitChanges('chore!: Initial release v${TestConstants.initialVersion}');
      await runProcess('git', ['tag', 'v${TestConstants.initialVersion}'], workingDir: testSetup.tempDir.path);

      await copyDir(testSetup.fixtures.appV101Dir, testSetup.tempDir);
      testSetup.setVersion(TestConstants.patchVersion);
      await testSetup.commitChanges('fix: API changes for v${TestConstants.patchVersion}');
      await runProcess('git', ['tag', 'v${TestConstants.patchVersion}'], workingDir: testSetup.tempDir.path);

      await testSetup.runApiGuard('changelog', ['--regenerate', '--ignore-lagging-tags']);

      final changelog = await File(p.join(testSetup.tempDir.path, 'CHANGELOG.md')).readAsString();
      printOnFailure('Regenerated changelog:\n$changelog');

      final versionHeaders = RegExp(r'^## (.+)$', multiLine: true).allMatches(changelog).map((m) => m.group(1)).toList();
      expect(versionHeaders, contains(TestConstants.initialVersion));
      expect(versionHeaders, contains(TestConstants.patchVersion));
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('regenerate fails when local tags lag behind origin', () async {
      final bareDir = await Directory.systemTemp.createTemp('api_guard_bare_');
      await runProcess('git', ['init', '--bare'], workingDir: bareDir.path);

      await testSetup.setupGitRepo();
      await runProcess('git', ['remote', 'set-url', 'origin', bareDir.path], workingDir: testSetup.tempDir.path);
      await testSetup.setupFlutterPackage();
      await copyDir(testSetup.fixtures.appV100Dir, testSetup.tempDir);

      await testSetup.commitChanges('chore!: Initial release v${TestConstants.initialVersion}');
      await runProcess('git', ['tag', 'v${TestConstants.initialVersion}'], workingDir: testSetup.tempDir.path);
      await runProcess('git', ['push', '-u', 'origin', 'HEAD'], workingDir: testSetup.tempDir.path);
      await runProcess('git', ['push', 'origin', 'v${TestConstants.initialVersion}'], workingDir: testSetup.tempDir.path);

      await copyDir(testSetup.fixtures.appV101Dir, testSetup.tempDir);
      testSetup.setVersion(TestConstants.minorVersion);
      await testSetup.commitChanges('feat: API changes for v${TestConstants.minorVersion}');
      await runProcess('git', ['tag', 'v${TestConstants.minorVersion}'], workingDir: testSetup.tempDir.path);
      await runProcess('git', ['push', 'origin', 'v${TestConstants.minorVersion}'], workingDir: testSetup.tempDir.path);
      await runProcess('git', ['tag', '-d', 'v${TestConstants.minorVersion}'], workingDir: testSetup.tempDir.path);

      await expectLater(
        testSetup.runApiGuard('changelog', ['--regenerate']),
        throwsA(predicate<Object>((error) => error.toString().contains('v${TestConstants.minorVersion}'))),
      );

      await testSetup.runApiGuard('changelog', ['--regenerate', '--ignore-lagging-tags']);

      final changelog = await File(p.join(testSetup.tempDir.path, 'CHANGELOG.md')).readAsString();
      expect(changelog, contains('## ${TestConstants.initialVersion}'));
      expect(changelog, isNot(contains('## ${TestConstants.minorVersion}')));
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('regenerate includes unreleased section when pubspec is ahead of latest tag', () async {
      await testSetup.setupGitRepo();
      await testSetup.setupFlutterPackage();
      await copyDir(testSetup.fixtures.appV100Dir, testSetup.tempDir);

      await testSetup.commitChanges('chore!: Initial release v${TestConstants.initialVersion}');
      await runProcess('git', ['tag', 'v${TestConstants.initialVersion}'], workingDir: testSetup.tempDir.path);

      testSetup.setVersion(TestConstants.patchVersion);
      await copyDir(testSetup.fixtures.appV101Dir, testSetup.tempDir);
      await testSetup.commitChanges('fix: unreleased API changes');

      await testSetup.runApiGuard('changelog', ['--regenerate', '--ignore-lagging-tags']);

      final changelog = await File(p.join(testSetup.tempDir.path, 'CHANGELOG.md')).readAsString();
      printOnFailure('Regenerated changelog:\n$changelog');

      expect(changelog.startsWith('## Unreleased'), isTrue);
      expect(changelog, contains('## ${TestConstants.initialVersion}'));
    }, timeout: const Timeout(Duration(minutes: 3)));
  });
}
