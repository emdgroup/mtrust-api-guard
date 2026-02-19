// ignore_for_file: avoid_print

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'test_helpers.dart';

/// Helper class for managing test setup and teardown.
class TestSetup {
  late Directory tempDir;
  late Directory cacheDir;
  final Directory rootDir = Directory.current;
  final TestFixtures fixtures = TestFixtures();

  /// Set up the test environment with a temporary directory.
  Future<void> setUp() async {
    tempDir = await Directory.systemTemp.createTemp('api_guard_test_');
    tempDir = Directory(p.join(tempDir.path, 'api_guard_test'));
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true); // Ensure a clean state
    }
    await tempDir.create();
    
    // Create a unique cache directory for this test
    cacheDir = Directory(p.join(tempDir.path, 'cache'));
    await cacheDir.create(recursive: true);
    
    await runApiGuard('cache', ['--clear']); // Clear cache before each test
  }

  /// Clean up the test environment.
  Future<void> tearDown() async {
    await tempDir.delete(recursive: true);
  }

  /// Set up a git repository with user configuration.
  Future<void> setupGitRepo() async {
    await runProcess('git', ['init'], workingDir: tempDir.path);
    try {
      await runProcess('git', ['remote', 'get-url', 'origin'], workingDir: tempDir.path);
    } catch (_) {
      await runProcess(
        'git',
        ['remote', 'add', 'origin', 'https://github.com/emdgroup/mtrust-api-guard.git'],
        workingDir: tempDir.path,
      );
    }
    await runProcess(
      'git',
      ['config', 'user.email', TestConstants.testEmail],
      workingDir: tempDir.path,
    );
    await runProcess(
      'git',
      ['config', 'user.name', TestConstants.testUser],
      workingDir: tempDir.path,
    );
  }

  /// Set version in pubspec.yaml.
  void setVersion(String version) {
    final yaml = File(p.join(tempDir.path, 'pubspec.yaml'));
    yaml.writeAsStringSync(
      yaml.readAsStringSync().replaceFirst(
            RegExp(r'version: \d+\.\d+\.\d+'),
            'version: $version',
          ),
    );
  }

  /// Get current version from pubspec.yaml.
  String getCurrentVersion() {
    final yaml = File(p.join(tempDir.path, 'pubspec.yaml'));
    final pubspec = loadYaml(yaml.readAsStringSync()) as YamlMap;
    return pubspec['version'] as String;
  }

  /// Commit all changes with a message.
  Future<void> commitChanges(String message) async {
    await runProcess('git', ['add', '.'], workingDir: tempDir.path);
    await runProcess('git', ['commit', '-m', message], workingDir: tempDir.path);
  }

  /// Run the API Guard command and handle output.
  Future<void> runApiGuard(String command, List<String> args) async {
    printOnFailure('Running API Guard: $command ${args.join(' ')} on ${tempDir.path}');
    printOnFailure("dart ${rootDir.path}/bin/mtrust_api_guard.dart $command ${args.join(' ')}");

    // Set the cache directory environment variable for this test
    final environment = Map<String, String>.from(Platform.environment);
    environment['MTRUST_API_GUARD_CACHE_DIR'] = cacheDir.path;

    final result = await Process.run(
      'dart',
      ["${rootDir.path}/bin/mtrust_api_guard.dart", command, ...args],
      workingDirectory: tempDir.path,
      environment: environment,
    );

    final stdout = result.stdout.toString().trim();
    final stderr = result.stderr.toString().trim();

    if (stdout.isNotEmpty) {
      result.stdout
          .toString()
          .trim()
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .forEach((line) => printOnFailure('\t$line'));
    }
    if (stderr.isNotEmpty) {
      result.stderr
          .toString()
          .trim()
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .forEach((line) => printOnFailure('\t$line'));
    }

    if (result.exitCode != 0) {
      printOnFailure('Command failed: $command ${args.join(' ')}');
      throw Exception(
        'API Guard command "$command ${args.join(' ')}" failed with exit code ${result.exitCode}\n'
        'stdout: ${result.stdout}\n'
        'stderr: ${result.stderr}',
      );
    }
  }

  Future<void> _clearDir(String dirName) async {
    final dir = Directory(p.join(tempDir.path, dirName));
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
      await dir.create();
    }
  }

  /// Set up a Flutter package in the test directory.
  Future<void> setupFlutterPackage() async {
    await runProcess(
      'flutter',
      ['create', '.', '--template', 'package', '--project-name', 'api_guard_test'],
      workingDir: tempDir.path,
    );

    // remove the contents of lib/ and test/ directories
    await _clearDir('lib');
    await _clearDir('test');
  }

  /// Set up a Flutter plugin in the test directory.
  Future<void> setupFlutterPlugin() async {
    await runProcess(
      'flutter',
      ['create', '.', '--template', 'plugin', '--project-name', 'api_guard_test'],
      workingDir: tempDir.path,
    );
    // remove the contents of lib/ and test/ directories
    await _clearDir('lib');
    await _clearDir('test');
  }
}
