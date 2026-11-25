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
    Future<void> updatePubspec(String filePath, List<Object> path, dynamic value) async {
      final pubspecFile = File(filePath);
      final pubspecContent = await pubspecFile.readAsString();
      final editor = YamlEditor(pubspecContent);
      editor.update(path, value);
      await pubspecFile.writeAsString(editor.toString());
    }

    Future<Directory> setupWorkspacePackage({
      required String packageName,
      required String version,
      Map<String, String>? dependencies,
    }) async {
      final packageDir = Directory(p.join(testSetup.tempDir.path, 'packages', packageName));
      await packageDir.create(recursive: true);
      await copyPackageBase(packageDir, packageName: packageName);

      final pubspecFile = File(p.join(packageDir.path, 'pubspec.yaml'));
      await updatePubspec(pubspecFile.path, ['version'], version);
      await updatePubspec(pubspecFile.path, ['resolution'], 'workspace');

      for (final entry in dependencies?.entries ?? const <MapEntry<String, String>>[]) {
        await updatePubspec(pubspecFile.path, ['dependencies', entry.key], entry.value);
      }

      final libDir = Directory(p.join(packageDir.path, 'lib'));
      await libDir.create(recursive: true);
      await copyDir(Directory(p.join(testSetup.fixtures.appV100Dir.path, 'lib')), libDir);

      final v100AnalysisOptions = File(p.join(testSetup.fixtures.appV100Dir.path, 'analysis_options.yaml'));
      if (v100AnalysisOptions.existsSync()) {
        await v100AnalysisOptions.copy(p.join(packageDir.path, 'analysis_options.yaml'));
      }

      return packageDir;
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
      final sharedDir = await setupWorkspacePackage(packageName: 'shared', version: '0.0.1');
      final sharedLibDir = Directory(p.join(sharedDir.path, 'lib'));

      // 4. Create consumer package that depends on shared
      await setupWorkspacePackage(packageName: 'consumer', version: '0.0.1', dependencies: {'shared': '^0.0.1'});

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
      final consumerDir = Directory(p.join(testSetup.tempDir.path, 'packages', 'consumer'));
      final consumerPubspecAfter = File(p.join(consumerDir.path, 'pubspec.yaml'));
      final consumerPubspecYaml = loadYaml(await consumerPubspecAfter.readAsString()) as YamlMap;
      expect(consumerPubspecYaml['version'], '0.0.1');

      // 12. Verify tags were created correctly
      final tags = await runProcess('git', ['tag'], workingDir: testSetup.tempDir.path, captureOutput: true);
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
      final packageADir = await setupWorkspacePackage(packageName: 'package_a', version: '0.0.1');
      final packageALibDir = Directory(p.join(packageADir.path, 'lib'));

      // 4. Create package_b
      await setupWorkspacePackage(packageName: 'package_b', version: '0.0.1');

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
      final packageBDir = Directory(p.join(testSetup.tempDir.path, 'packages', 'package_b'));
      final packageBPubspecAfter = File(p.join(packageBDir.path, 'pubspec.yaml'));
      final packageBPubspecYaml = loadYaml(await packageBPubspecAfter.readAsString()) as YamlMap;
      expect(packageBPubspecYaml['version'], '0.0.1');

      // 10. Verify only package_a tag was created
      final tags = await runProcess('git', ['tag'], workingDir: testSetup.tempDir.path, captureOutput: true);
      expect(tags, contains('package_a/v0.0.2'));
      expect(tags, isNot(contains('package_b/v0.0.2')));
    });

    test('supports melos style tags via --tag-format', () async {
      // 1. Initialize git repo
      await testSetup.setupGitRepo();

      // 2. Create workspace structure
      final rootPubspec = File(p.join(testSetup.tempDir.path, 'pubspec.yaml'));
      await rootPubspec.writeAsString('''
name: test_workspace
environment:
  sdk: '>=3.5.0 <4.0.0'
workspace:
  - packages/shared
  - packages/consumer
''');

      // 3. Create packages
      final sharedDir = await setupWorkspacePackage(packageName: 'shared', version: '0.0.1');
      final sharedLibDir = Directory(p.join(sharedDir.path, 'lib'));
      await setupWorkspacePackage(packageName: 'consumer', version: '0.0.1');

      // 4. Commit and tag initial versions in melos format ({package}-v{version})
      await testSetup.commitChanges('chore!: Initial workspace setup');
      await runProcess('git', ['tag', 'shared-v0.0.1'], workingDir: testSetup.tempDir.path);
      await runProcess('git', ['tag', 'consumer-v0.0.1'], workingDir: testSetup.tempDir.path);

      // 5. Make changes only to shared package (patch-level change)
      await copyDir(Directory(p.join(testSetup.fixtures.appV101Dir.path, 'lib')), sharedLibDir);
      final v101AnalysisOptions = File(p.join(testSetup.fixtures.appV101Dir.path, 'analysis_options.yaml'));
      if (v101AnalysisOptions.existsSync()) {
        await v101AnalysisOptions.copy(p.join(sharedDir.path, 'analysis_options.yaml'));
      }
      await testSetup.commitChanges('fix: update shared package');

      // 6. Run version-workspace with the melos tag format
      await testSetup.runApiGuard('version-workspace', ['--tag-format', '{package}-v{version}']);

      // 7. Verify shared was versioned against its melos style tag (0.0.1 -> 0.0.2)
      final sharedPubspecAfter = File(p.join(sharedDir.path, 'pubspec.yaml'));
      final sharedPubspecYaml = loadYaml(await sharedPubspecAfter.readAsString()) as YamlMap;
      expect(sharedPubspecYaml['version'], '0.0.2');

      // 8. Verify consumer was not versioned
      final consumerDir = Directory(p.join(testSetup.tempDir.path, 'packages', 'consumer'));
      final consumerPubspecYaml =
          loadYaml(await File(p.join(consumerDir.path, 'pubspec.yaml')).readAsString()) as YamlMap;
      expect(consumerPubspecYaml['version'], '0.0.1');

      // 9. Verify the new tag uses the melos format and no slash tags were created
      final tags = await runProcess('git', ['tag'], workingDir: testSetup.tempDir.path, captureOutput: true);
      expect(tags, contains('shared-v0.0.2'));
      expect(tags, isNot(contains('shared/v0.0.2')));
      expect(tags, isNot(contains('consumer-v0.0.2')));
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
      expect(() async => await testSetup.runApiGuard('version-workspace', []), throwsA(isA<Exception>()));
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
      final baseDir = await setupWorkspacePackage(packageName: 'base', version: '0.0.1');
      final baseLibDir = Directory(p.join(baseDir.path, 'lib'));

      // 4. Create shared package (depends on base)
      await setupWorkspacePackage(packageName: 'shared', version: '0.0.1', dependencies: {'base': '^0.0.1'});

      // 5. Create consumer package (depends on shared)
      await setupWorkspacePackage(packageName: 'consumer', version: '0.0.1', dependencies: {'shared': '^0.0.1'});

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
      final sharedDir = Directory(p.join(testSetup.tempDir.path, 'packages', 'shared'));
      final sharedPubspecAfter = File(p.join(sharedDir.path, 'pubspec.yaml'));
      final sharedPubspecYaml = loadYaml(await sharedPubspecAfter.readAsString()) as YamlMap;
      final sharedDeps = sharedPubspecYaml['dependencies'] as YamlMap;
      final baseDep = sharedDeps['base'];
      if (baseDep is String) {
        expect(baseDep, '^0.1.0');
      }

      // 11. Verify consumer dependency on shared was NOT updated (shared didn't change)
      final consumerDir = Directory(p.join(testSetup.tempDir.path, 'packages', 'consumer'));
      final consumerPubspecAfter = File(p.join(consumerDir.path, 'pubspec.yaml'));
      final consumerPubspecYaml = loadYaml(await consumerPubspecAfter.readAsString()) as YamlMap;
      final consumerDeps = consumerPubspecYaml['dependencies'] as YamlMap;
      final sharedDepInConsumer = consumerDeps['shared'];
      if (sharedDepInConsumer is String) {
        expect(sharedDepInConsumer, '^0.0.1'); // Should remain unchanged
      }
    });

    /// Creates a one-package workspace whose root pins [sdkPin] in `.fvmrc`,
    /// commits it and tags the package's initial version.
    Future<Directory> setupPinnedWorkspace(String sdkPin) async {
      await testSetup.setupGitRepo();

      final rootPubspec = File(p.join(testSetup.tempDir.path, 'pubspec.yaml'));
      await rootPubspec.writeAsString('''
name: test_workspace
environment:
  sdk: '>=3.5.0 <4.0.0'
workspace:
  - packages/shared
''');

      final sharedDir = await setupWorkspacePackage(packageName: 'shared', version: '0.0.1');
      File(p.join(testSetup.tempDir.path, '.fvmrc')).writeAsStringSync('{"flutter": "$sdkPin"}');

      await testSetup.commitChanges('chore!: Initial workspace setup');
      await runProcess('git', ['tag', 'shared/v0.0.1'], workingDir: testSetup.tempDir.path);

      return sharedDir;
    }

    /// Applies a patch-level change to [sharedDir] and commits it.
    Future<void> commitSharedPatch(Directory sharedDir) async {
      await copyDir(
        Directory(p.join(testSetup.fixtures.appV101Dir.path, 'lib')),
        Directory(p.join(sharedDir.path, 'lib')),
      );
      final v101AnalysisOptions = File(p.join(testSetup.fixtures.appV101Dir.path, 'analysis_options.yaml'));
      if (v101AnalysisOptions.existsSync()) {
        await v101AnalysisOptions.copy(p.join(sharedDir.path, 'analysis_options.yaml'));
      }
      await testSetup.commitChanges('fix: update shared package');
    }

    /// The version in the package's pubspec after the command ran.
    String sharedVersion(Directory sharedDir) {
      final pubspec = loadYaml(File(p.join(sharedDir.path, 'pubspec.yaml')).readAsStringSync()) as YamlMap;
      return pubspec['version'] as String;
    }

    test('--ref-sdk resolves the base ref with the given SDK', () async {
      final sharedDir = await setupPinnedWorkspace('1.2.3');

      final fvmCache = Directory.systemTemp.createTempSync('api_guard_fvm_');
      addTearDown(() => fvmCache.deleteSync(recursive: true));
      final log = File(p.join(fvmCache.path, 'sdk_invocations.log'));

      // Only the override SDK exists, and it hands over to the ambient Flutter
      // so the run can finish. The pin in .fvmrc is therefore unusable, which
      // makes a successful run proof that the override won.
      installFakeFvmSdk(fvmCache, '9.9.9', log, body: 'exec flutter "\$@"');

      await commitSharedPatch(sharedDir);

      await testSetup.runApiGuard(
        'version-workspace',
        ['--ref-sdk', 'shared/v0.0.1=9.9.9'],
        environment: {'FVM_CACHE_PATH': fvmCache.path},
      );

      expect(log.readAsStringSync(), contains('9.9.9'));
      expect(sharedVersion(sharedDir), '0.0.2');
    }, skip: Platform.isWindows ? 'the fake SDK binary is a POSIX shell script' : false);

    test('--no-sdk-autodetect ignores the SDK pinned by the ref', () async {
      final sharedDir = await setupPinnedWorkspace('1.2.3');

      final fvmCache = Directory.systemTemp.createTempSync('api_guard_fvm_');
      addTearDown(() => fvmCache.deleteSync(recursive: true));
      final log = File(p.join(fvmCache.path, 'sdk_invocations.log'));

      // Resolving the pin would run this binary and fail the command, so
      // success plus an empty log proves the pin was skipped.
      installFakeFvmSdk(fvmCache, '1.2.3', log, body: 'exit 1');

      await commitSharedPatch(sharedDir);

      await testSetup.runApiGuard(
        'version-workspace',
        ['--no-sdk-autodetect'],
        environment: {'FVM_CACHE_PATH': fvmCache.path},
      );

      expect(log.existsSync(), isFalse, reason: 'the pinned SDK should not have been resolved');
      expect(sharedVersion(sharedDir), '0.0.2');
    }, skip: Platform.isWindows ? 'the fake SDK binary is a POSIX shell script' : false);
  }, timeout: const Timeout(Duration(minutes: 10)));
}
