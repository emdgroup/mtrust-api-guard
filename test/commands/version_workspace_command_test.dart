// ignore_for_file: avoid_print

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../helpers/test_setup.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Version Workspace Command Tests', () {
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

    test('versions workspace packages with changes and updates dependencies', () async {
      // 1. Initialize git repo
      await testSetup.setupGitRepo();

      // 2. Create workspace structure with root pubspec.yaml
      final rootPubspec = File(p.join(testSetup.tempDir.path, 'pubspec.yaml'));
      await rootPubspec.writeAsString('''
name: test_workspace
environment:
  sdk: '>=3.5.0 <4.0.0'
workspace:
  - packages/shared
  - packages/consumer
''');

      // 3. Create shared package
      final sharedDir = Directory(p.join(testSetup.tempDir.path, 'packages', 'shared'));
      await sharedDir.create(recursive: true);
      await runProcess(
        'flutter',
        ['create', '.', '--template', 'package'],
        workingDir: sharedDir.path,
      );

      // Clear lib and test directories
      await Directory(p.join(sharedDir.path, 'lib')).delete(recursive: true);
      await Directory(p.join(sharedDir.path, 'lib')).create();
      await Directory(p.join(sharedDir.path, 'test')).delete(recursive: true);
      await Directory(p.join(sharedDir.path, 'test')).create();

      // Update shared package pubspec.yaml
      final sharedPubspec = File(p.join(sharedDir.path, 'pubspec.yaml'));
      await _updatePubspec(sharedPubspec.path, ['version'], '0.0.1');
      await _updatePubspec(sharedPubspec.path, ['resolution'], 'workspace');

      // Copy API files to shared package
      final sharedLibDir = Directory(p.join(sharedDir.path, 'lib'));
      await sharedLibDir.create(recursive: true);
      await copyDir(Directory(p.join(testSetup.fixtures.appV100Dir.path, 'lib')), sharedLibDir);
      
      // Copy analysis_options.yaml from fixtures to ensure consistent entry points
      final v100AnalysisOptions = File(p.join(testSetup.fixtures.appV100Dir.path, 'analysis_options.yaml'));
      if (v100AnalysisOptions.existsSync()) {
        await v100AnalysisOptions.copy(p.join(sharedDir.path, 'analysis_options.yaml'));
      }

      // 4. Create consumer package that depends on shared
      final consumerDir = Directory(p.join(testSetup.tempDir.path, 'packages', 'consumer'));
      await consumerDir.create(recursive: true);
      await runProcess(
        'flutter',
        ['create', '.', '--template', 'package'],
        workingDir: consumerDir.path,
      );

      // Clear lib and test directories
      await Directory(p.join(consumerDir.path, 'lib')).delete(recursive: true);
      await Directory(p.join(consumerDir.path, 'lib')).create();
      await Directory(p.join(consumerDir.path, 'test')).delete(recursive: true);
      await Directory(p.join(consumerDir.path, 'test')).create();

      // Update consumer package pubspec.yaml
      final consumerPubspec = File(p.join(consumerDir.path, 'pubspec.yaml'));
      await _updatePubspec(consumerPubspec.path, ['version'], '0.0.1');
      await _updatePubspec(consumerPubspec.path, ['resolution'], 'workspace');
      await _updatePubspec(consumerPubspec.path, ['dependencies', 'shared'], '^0.0.1');

      // Copy API files to consumer package
      final consumerLibDir = Directory(p.join(consumerDir.path, 'lib'));
      await consumerLibDir.create(recursive: true);
      await copyDir(Directory(p.join(testSetup.fixtures.appV100Dir.path, 'lib')), consumerLibDir);

      // 5. Commit initial state
      await testSetup.commitChanges('chore!: Initial workspace setup');

      // 6. Tag initial versions for both packages
      await runProcess('git', ['tag', 'shared/v0.0.1'], workingDir: testSetup.tempDir.path);
      await runProcess('git', ['tag', 'consumer/v0.0.1'], workingDir: testSetup.tempDir.path);

      // 7. Make changes only to shared package (patch-level change)
      await copyDir(Directory(p.join(testSetup.fixtures.appV101Dir.path, 'lib')), sharedLibDir);
      
      // Copy analysis_options.yaml from v101 fixtures to ensure consistent entry points
      final v101AnalysisOptions = File(p.join(testSetup.fixtures.appV101Dir.path, 'analysis_options.yaml'));
      if (v101AnalysisOptions.existsSync()) {
        await v101AnalysisOptions.copy(p.join(sharedDir.path, 'analysis_options.yaml'));
      }

      // 8. Commit changes
      await testSetup.commitChanges('fix: update shared package');

      // 9. Run version-workspace command
      await testSetup.runApiGuard('version-workspace', []);

      // 10. Verify shared package was versioned (0.0.1 -> 0.0.2)
      final sharedPubspecAfter = File(p.join(sharedDir.path, 'pubspec.yaml'));
      final sharedPubspecYaml = loadYaml(await sharedPubspecAfter.readAsString()) as YamlMap;
      expect(sharedPubspecYaml['version'], '0.0.2');

      // 11. Verify consumer package was NOT versioned (no changes)
      final consumerPubspecAfter = File(p.join(consumerDir.path, 'pubspec.yaml'));
      final consumerPubspecYaml = loadYaml(await consumerPubspecAfter.readAsString()) as YamlMap;
      expect(consumerPubspecYaml['version'], '0.0.1');

      // 12. Verify tags were created correctly
      final tags = await runProcess(
        'git',
        ['tag'],
        workingDir: testSetup.tempDir.path,
        captureOutput: true,
      );
      expect(tags, contains('shared/v0.0.1'));
      expect(tags, contains('shared/v0.0.2'));
      expect(tags, contains('consumer/v0.0.1'));
      expect(tags, isNot(contains('consumer/v0.0.2')));

      // 13. Verify consumer package dependency was updated
      final consumerDeps = consumerPubspecYaml['dependencies'] as YamlMap;
      final sharedDep = consumerDeps['shared'];
      expect(sharedDep, isNotNull);
      // Should be updated to ^0.0.2 (maintaining constraint format)
      if (sharedDep is String) {
        expect(sharedDep, '^0.0.2');
      }
    });

    test('skips unchanged packages in workspace', () async {
      // 1. Initialize git repo
      await testSetup.setupGitRepo();

      // 2. Create workspace structure
      final rootPubspec = File(p.join(testSetup.tempDir.path, 'pubspec.yaml'));
      await rootPubspec.writeAsString('''
name: test_workspace
environment:
  sdk: '>=3.5.0 <4.0.0'
workspace:
  - packages/package_a
  - packages/package_b
''');

      // 3. Create package_a
      final packageADir = Directory(p.join(testSetup.tempDir.path, 'packages', 'package_a'));
      await packageADir.create(recursive: true);
      await runProcess(
        'flutter',
        ['create', '.', '--template', 'package'],
        workingDir: packageADir.path,
      );

      await Directory(p.join(packageADir.path, 'lib')).delete(recursive: true);
      await Directory(p.join(packageADir.path, 'lib')).create();
      await Directory(p.join(packageADir.path, 'test')).delete(recursive: true);
      await Directory(p.join(packageADir.path, 'test')).create();

      final packageAPubspec = File(p.join(packageADir.path, 'pubspec.yaml'));
      await _updatePubspec(packageAPubspec.path, ['version'], '0.0.1');
      await _updatePubspec(packageAPubspec.path, ['resolution'], 'workspace');

      final packageALibDir = Directory(p.join(packageADir.path, 'lib'));
      await packageALibDir.create(recursive: true);
      await copyDir(Directory(p.join(testSetup.fixtures.appV100Dir.path, 'lib')), packageALibDir);
      
      // Copy analysis_options.yaml from fixtures to ensure consistent entry points
      final v100AnalysisOptions = File(p.join(testSetup.fixtures.appV100Dir.path, 'analysis_options.yaml'));
      if (v100AnalysisOptions.existsSync()) {
        await v100AnalysisOptions.copy(p.join(packageADir.path, 'analysis_options.yaml'));
      }

      // 4. Create package_b
      final packageBDir = Directory(p.join(testSetup.tempDir.path, 'packages', 'package_b'));
      await packageBDir.create(recursive: true);
      await runProcess(
        'flutter',
        ['create', '.', '--template', 'package'],
        workingDir: packageBDir.path,
      );

      await Directory(p.join(packageBDir.path, 'lib')).delete(recursive: true);
      await Directory(p.join(packageBDir.path, 'lib')).create();
      await Directory(p.join(packageBDir.path, 'test')).delete(recursive: true);
      await Directory(p.join(packageBDir.path, 'test')).create();

      final packageBPubspec = File(p.join(packageBDir.path, 'pubspec.yaml'));
      await _updatePubspec(packageBPubspec.path, ['version'], '0.0.1');
      await _updatePubspec(packageBPubspec.path, ['resolution'], 'workspace');

      final packageBLibDir = Directory(p.join(packageBDir.path, 'lib'));
      await packageBLibDir.create(recursive: true);
      await copyDir(Directory(p.join(testSetup.fixtures.appV100Dir.path, 'lib')), packageBLibDir);

      // 5. Commit initial state
      await testSetup.commitChanges('chore!: Initial workspace setup');
      await runProcess('git', ['tag', 'package_a/v0.0.1'], workingDir: testSetup.tempDir.path);
      await runProcess('git', ['tag', 'package_b/v0.0.1'], workingDir: testSetup.tempDir.path);

      // 6. Make changes only to package_a
      await copyDir(Directory(p.join(testSetup.fixtures.appV101Dir.path, 'lib')), packageALibDir);
      
      // Copy analysis_options.yaml from v101 fixtures to ensure consistent entry points
      final v101AnalysisOptions = File(p.join(testSetup.fixtures.appV101Dir.path, 'analysis_options.yaml'));
      if (v101AnalysisOptions.existsSync()) {
        await v101AnalysisOptions.copy(p.join(packageADir.path, 'analysis_options.yaml'));
      }
      
      await testSetup.commitChanges('fix: update package_a');

      // 7. Run version-workspace command
      await testSetup.runApiGuard('version-workspace', []);

      // 8. Verify package_a was versioned
      final packageAPubspecAfter = File(p.join(packageADir.path, 'pubspec.yaml'));
      final packageAPubspecYaml = loadYaml(await packageAPubspecAfter.readAsString()) as YamlMap;
      expect(packageAPubspecYaml['version'], '0.0.2');

      // 9. Verify package_b was NOT versioned
      final packageBPubspecAfter = File(p.join(packageBDir.path, 'pubspec.yaml'));
      final packageBPubspecYaml = loadYaml(await packageBPubspecAfter.readAsString()) as YamlMap;
      expect(packageBPubspecYaml['version'], '0.0.1');

      // 10. Verify only package_a tag was created
      final tags = await runProcess(
        'git',
        ['tag'],
        workingDir: testSetup.tempDir.path,
        captureOutput: true,
      );
      expect(tags, contains('package_a/v0.0.2'));
      expect(tags, isNot(contains('package_b/v0.0.2')));
    });

    test('fails when workspace is not detected', () async {
      // 1. Initialize git repo without workspace
      await testSetup.setupGitRepo();
      await testSetup.setupFlutterPackage();

      // 2. Set up a regular package (not workspace)
      await copyDir(testSetup.fixtures.appV100Dir, testSetup.tempDir);

      // 3. Commit initial state
      await testSetup.commitChanges('chore!: Initial release');

      // 4. Attempt to run version-workspace command (should fail)
      expect(
        () async => await testSetup.runApiGuard('version-workspace', []),
        throwsA(isA<Exception>()),
      );
    });

    test('handles multiple packages with dependencies correctly', () async {
      // 1. Initialize git repo
      await testSetup.setupGitRepo();

      // 2. Create workspace with three packages: base -> shared -> consumer
      final rootPubspec = File(p.join(testSetup.tempDir.path, 'pubspec.yaml'));
      await rootPubspec.writeAsString('''
name: test_workspace
environment:
  sdk: '>=3.5.0 <4.0.0'
workspace:
  - packages/base
  - packages/shared
  - packages/consumer
''');

      // 3. Create base package
      final baseDir = Directory(p.join(testSetup.tempDir.path, 'packages', 'base'));
      await baseDir.create(recursive: true);
      await runProcess('flutter', ['create', '.', '--template', 'package'], workingDir: baseDir.path);
      await Directory(p.join(baseDir.path, 'lib')).delete(recursive: true);
      await Directory(p.join(baseDir.path, 'lib')).create();
      await Directory(p.join(baseDir.path, 'test')).delete(recursive: true);
      await Directory(p.join(baseDir.path, 'test')).create();

      final basePubspec = File(p.join(baseDir.path, 'pubspec.yaml'));
      await _updatePubspec(basePubspec.path, ['version'], '0.0.1');
      await _updatePubspec(basePubspec.path, ['resolution'], 'workspace');

      final baseLibDir = Directory(p.join(baseDir.path, 'lib'));
      await baseLibDir.create(recursive: true);
      await copyDir(Directory(p.join(testSetup.fixtures.appV100Dir.path, 'lib')), baseLibDir);
      
      // Copy analysis_options.yaml from fixtures to ensure consistent entry points
      final v100AnalysisOptions = File(p.join(testSetup.fixtures.appV100Dir.path, 'analysis_options.yaml'));
      if (v100AnalysisOptions.existsSync()) {
        await v100AnalysisOptions.copy(p.join(baseDir.path, 'analysis_options.yaml'));
      }

      // 4. Create shared package (depends on base)
      final sharedDir = Directory(p.join(testSetup.tempDir.path, 'packages', 'shared'));
      await sharedDir.create(recursive: true);
      await runProcess('flutter', ['create', '.', '--template', 'package'], workingDir: sharedDir.path);
      await Directory(p.join(sharedDir.path, 'lib')).delete(recursive: true);
      await Directory(p.join(sharedDir.path, 'lib')).create();
      await Directory(p.join(sharedDir.path, 'test')).delete(recursive: true);
      await Directory(p.join(sharedDir.path, 'test')).create();

      final sharedPubspec = File(p.join(sharedDir.path, 'pubspec.yaml'));
      await _updatePubspec(sharedPubspec.path, ['version'], '0.0.1');
      await _updatePubspec(sharedPubspec.path, ['resolution'], 'workspace');
      await _updatePubspec(sharedPubspec.path, ['dependencies', 'base'], '^0.0.1');

      final sharedLibDir = Directory(p.join(sharedDir.path, 'lib'));
      await sharedLibDir.create(recursive: true);
      await copyDir(Directory(p.join(testSetup.fixtures.appV100Dir.path, 'lib')), sharedLibDir);
      
      // Copy analysis_options.yaml from fixtures to ensure consistent entry points
      final v100AnalysisOptionsShared = File(p.join(testSetup.fixtures.appV100Dir.path, 'analysis_options.yaml'));
      if (v100AnalysisOptionsShared.existsSync()) {
        await v100AnalysisOptionsShared.copy(p.join(sharedDir.path, 'analysis_options.yaml'));
      }

      // 5. Create consumer package (depends on shared)
      final consumerDir = Directory(p.join(testSetup.tempDir.path, 'packages', 'consumer'));
      await consumerDir.create(recursive: true);
      await runProcess('flutter', ['create', '.', '--template', 'package'], workingDir: consumerDir.path);
      await Directory(p.join(consumerDir.path, 'lib')).delete(recursive: true);
      await Directory(p.join(consumerDir.path, 'lib')).create();
      await Directory(p.join(consumerDir.path, 'test')).delete(recursive: true);
      await Directory(p.join(consumerDir.path, 'test')).create();

      final consumerPubspec = File(p.join(consumerDir.path, 'pubspec.yaml'));
      await _updatePubspec(consumerPubspec.path, ['version'], '0.0.1');
      await _updatePubspec(consumerPubspec.path, ['resolution'], 'workspace');
      await _updatePubspec(consumerPubspec.path, ['dependencies', 'shared'], '^0.0.1');

      final consumerLibDir = Directory(p.join(consumerDir.path, 'lib'));
      await consumerLibDir.create(recursive: true);
      await copyDir(Directory(p.join(testSetup.fixtures.appV100Dir.path, 'lib')), consumerLibDir);
      
      // Copy analysis_options.yaml from fixtures to ensure consistent entry points
      final v100AnalysisOptionsConsumer = File(p.join(testSetup.fixtures.appV100Dir.path, 'analysis_options.yaml'));
      if (v100AnalysisOptionsConsumer.existsSync()) {
        await v100AnalysisOptionsConsumer.copy(p.join(consumerDir.path, 'analysis_options.yaml'));
      }

      // 6. Commit initial state
      await testSetup.commitChanges('chore!: Initial workspace setup');
      await runProcess('git', ['tag', 'base/v0.0.1'], workingDir: testSetup.tempDir.path);
      await runProcess('git', ['tag', 'shared/v0.0.1'], workingDir: testSetup.tempDir.path);
      await runProcess('git', ['tag', 'consumer/v0.0.1'], workingDir: testSetup.tempDir.path);

      // 7. Make changes to base package (minor change)
      await copyDir(Directory(p.join(testSetup.fixtures.appV110Dir.path, 'lib')), baseLibDir);
      
      // Copy analysis_options.yaml from v110 fixtures to ensure consistent entry points
      final v110AnalysisOptions = File(p.join(testSetup.fixtures.appV110Dir.path, 'analysis_options.yaml'));
      if (v110AnalysisOptions.existsSync()) {
        await v110AnalysisOptions.copy(p.join(baseDir.path, 'analysis_options.yaml'));
      }
      
      await testSetup.commitChanges('feat: update base package');

      // 8. Run version-workspace command
      await testSetup.runApiGuard('version-workspace', []);

      // 9. Verify base was versioned
      final basePubspecAfter = File(p.join(baseDir.path, 'pubspec.yaml'));
      final basePubspecYaml = loadYaml(await basePubspecAfter.readAsString()) as YamlMap;
      expect(basePubspecYaml['version'], '0.1.0');

      // 10. Verify shared dependency on base was updated
      final sharedPubspecAfter = File(p.join(sharedDir.path, 'pubspec.yaml'));
      final sharedPubspecYaml = loadYaml(await sharedPubspecAfter.readAsString()) as YamlMap;
      final sharedDeps = sharedPubspecYaml['dependencies'] as YamlMap;
      final baseDep = sharedDeps['base'];
      if (baseDep is String) {
        expect(baseDep, '^0.1.0');
      }

      // 11. Verify consumer dependency on shared was NOT updated (shared didn't change)
      final consumerPubspecAfter = File(p.join(consumerDir.path, 'pubspec.yaml'));
      final consumerPubspecYaml = loadYaml(await consumerPubspecAfter.readAsString()) as YamlMap;
      final consumerDeps = consumerPubspecYaml['dependencies'] as YamlMap;
      final sharedDepInConsumer = consumerDeps['shared'];
      if (sharedDepInConsumer is String) {
        expect(sharedDepInConsumer, '^0.0.1'); // Should remain unchanged
      }
    });
  }, timeout: const Timeout(Duration(minutes: 10)));
}
