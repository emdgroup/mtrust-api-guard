import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group(
    'mtrust_api_guard integration',
    () {
      late Directory tempDir;
      final rootDir = Directory.current;
      final fixturesDir = Directory('test/fixtures');

      // Constants for better maintainability
      const String initialVersion = '0.0.1';
      const String patchVersion = '0.0.2';
      const String minorVersion = '0.1.0';
      const String majorVersion = '1.0.0';
      const String testEmail = 'test@example.com';
      const String testUser = 'Test User';

      final appV100Dir = Directory(p.join(fixturesDir.path, 'app_v100'));
      final appV101Dir = Directory(p.join(fixturesDir.path, 'app_v101'));
      final appV110Dir = Directory(p.join(fixturesDir.path, 'app_v110'));
      final appV200Dir = Directory(p.join(fixturesDir.path, 'app_v200'));
      final expectedChangelogFile = File(
        p.join(fixturesDir.path, 'expected_changelog.md'),
      );

      setUp(() async {
        tempDir = await Directory.systemTemp.createTemp('api_guard_test_');
        tempDir = Directory(p.join(tempDir.path, 'api_guard_test'));
        await tempDir.create();
      });

      tearDown(() async {
        await tempDir.delete(recursive: true);
      });

      /// Helper method to setup git repository with user config
      Future<void> _setupGitRepo() async {
        await _run('git', ['init'], workingDir: tempDir.path);
        await _run('git', ['config', 'user.email', testEmail], workingDir: tempDir.path);
        await _run('git', ['config', 'user.name', testUser], workingDir: tempDir.path);
      }

      /// Helper method to set version in pubspec.yaml
      void _setVersion(String version) {
        final yaml = File(p.join(tempDir.path, 'pubspec.yaml'));
        yaml.writeAsStringSync(
          yaml.readAsStringSync().replaceFirst(RegExp(r'version: \d+\.\d+\.\d+'), 'version: $version'),
        );
      }

      /// Helper method to get current version from pubspec.yaml
      String _getCurrentVersion() {
        final yaml = File(p.join(tempDir.path, 'pubspec.yaml'));
        final pubspec = loadYaml(yaml.readAsStringSync()) as YamlMap;
        return pubspec['version'] as String;
      }

      /// Helper method to commit all changes with a message
      Future<void> _commitChanges(String message) async {
        await _run('git', ['add', '.'], workingDir: tempDir.path);
        await _run('git', ['commit', '-m', message], workingDir: tempDir.path);
      }

      Future<void> _runApiGuard(String command, List<String> args) async {
        print('Running API Guard: $command ${args.join(' ')} on ${tempDir.path}');
        print("dart ${rootDir.path}/bin/mtrust_api_guard.dart $command ${args.join(' ')}");
        final result = await Process.run(
          'dart',
          ["${rootDir.path}/bin/mtrust_api_guard.dart", command, ...args],
          workingDirectory: tempDir.path,
        );
        final stdout = result.stdout.toString().trim();
        final stderr = result.stderr.toString().trim();

        if (stdout.isNotEmpty) {
          result.stdout.toString().trim().split('\n').forEach((line) => print('\t$line'));
        }
        if (stderr.isNotEmpty) {
          result.stderr.toString().trim().split('\n').forEach((line) => print('\t$line'));
        }

        if (result.exitCode != 0) {
          print('Command failed: $command ${args.join(' ')}');
          fail('API Guard command "$command ${args.join(' ')}" failed with exit code ${result.exitCode}\n'
              'stdout: ${result.stdout}\n'
              'stderr: ${result.stderr}');
        }
      }

      test('detects API changes between versions', () async {
        // 1. Copy app_v1 to tempDir
        await _copyDir(appV100Dir, tempDir);

        // 2. Initialize git
        await _setupGitRepo();

        await _run('flutter', ['create', '.', '--template', 'package'], workingDir: tempDir.path);

        // 4. Commit initial state
        await _commitChanges('chore!: Initial release v$initialVersion');

        print('Initial version: ${_getCurrentVersion()}');

        await _run('git', ['tag', 'v$initialVersion'], workingDir: tempDir.path);

        expect(_getCurrentVersion(), initialVersion);

        // 5. Copy app_v1_0_1 over tempDir
        await _copyDir(appV101Dir, tempDir);

        // 6. Commit changes
        await _commitChanges('API change to v$patchVersion');

        await _runApiGuard('version', []);

        expect(_getCurrentVersion(), patchVersion);

        // 6. Copy app_v2 over tempDir
        await _copyDir(appV110Dir, tempDir);

        // 7. Commit changes
        await _commitChanges('API change to v$minorVersion');

        await _runApiGuard('version', []);

        expect(_getCurrentVersion(), minorVersion);

        // 8. Copy app_v3 over tempDir
        await _copyDir(appV200Dir, tempDir);
        await _commitChanges('feat: implement compatibility with v$majorVersion');

        await _runApiGuard('version', []);

        expect(_getCurrentVersion(), majorVersion);

        // Compare the tags
        final tags = await _run(
          'git',
          ['tag'],
          workingDir: tempDir.path,
          captureOutput: true,
        );
        expect(tags, contains('v$initialVersion'));
        expect(tags, contains('v$patchVersion'));
        expect(tags, contains('v$minorVersion'));
        expect(tags, contains('v$majorVersion'));

        // 9. Compare output to expected snapshot
        final changelogFile = File(p.join(tempDir.path, 'CHANGELOG.md'));
        final changelogContent = _stripChangelog(
          await changelogFile.readAsString(),
        );

        if (!expectedChangelogFile.existsSync()) {
          expectedChangelogFile.createSync();
          expectedChangelogFile.writeAsStringSync(changelogContent);
        }

        final expectedChangelog = _stripChangelog(
          await expectedChangelogFile.readAsString(),
        );

        expect(changelogContent, equalsIgnoringWhitespace(expectedChangelog));
      });

      test('version command fails  when no previous version is found', () async {
        // 1. Copy app_v1 to tempDir
        await _copyDir(appV100Dir, tempDir);

        // 2. Initialize git
        await _setupGitRepo();

        await _run('flutter', ['create', '.', '--template', 'package'], workingDir: tempDir.path);

        // 4. Commit initial state
        await _commitChanges('chore!: Initial release v$initialVersion');

        expect(_getCurrentVersion(), initialVersion);

        // 5. Copy app_v1_0_1 over tempDir
        await _copyDir(appV101Dir, tempDir);

        expect(() async => await _runApiGuard('version', []), throwsA(isA<Exception>()));

        expect(_getCurrentVersion(), initialVersion);
      });

      test('version command fails when uncommited changes are detected', () async {
        await _setupGitRepo();
        await _run('flutter', ['create', '.', '--template', 'package'], workingDir: tempDir.path);
        expect(() async => await _runApiGuard('version', []), throwsA(isA<Exception>()));
      });

      test('pre-relese flag on version command works as expected', () async {
        await _setupGitRepo();
        await _run('flutter', ['create', '.', '--template', 'package'], workingDir: tempDir.path);
        await _commitChanges('chore!: Initial release v$initialVersion');
        await _run('git', ['tag', 'v$initialVersion'], workingDir: tempDir.path);

        expect(_getCurrentVersion(), initialVersion);

        await _copyDir(appV110Dir, tempDir);

        // 7. Commit changes
        await _commitChanges('API change to v$minorVersion');

        await _runApiGuard('version', ['--pre-release']);
        expect(_getCurrentVersion(), '0.1.0-dev.1');

        // 8. Copy app_v3 over tempDir
        await _copyDir(appV200Dir, tempDir);
        await _commitChanges('feat: implement compatibility with v$majorVersion');

        await _runApiGuard('version', ['--pre-release']);
        expect(_getCurrentVersion(), '1.0.0-dev.1');

        await _runApiGuard('version', []);

        expect(_getCurrentVersion(), '1.0.0');
      });
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

/// Recursively copy [src] directory to [dst].
Future<void> _copyDir(Directory src, Directory dst) async {
  await for (var entity in src.list(recursive: true)) {
    final relPath = p.relative(entity.path, from: src.path);
    final newPath = p.join(dst.path, relPath);
    if (entity is File) {
      await File(newPath).create(recursive: true);
      await entity.copy(newPath);
    } else if (entity is Directory) {
      await Directory(newPath).create(recursive: true);
    }
  }
}

/// Run a process and optionally capture stdout.
Future<String> _run(String cmd, List<String> args, {String? workingDir, bool captureOutput = false}) async {
  print('Running: $cmd ${args.join(' ')} in $workingDir');
  final result = await Process.run(cmd, args, workingDirectory: workingDir);

  final stdout = result.stdout.toString();
  final stderr = result.stderr.toString();

  if (stdout.trim().isNotEmpty) {
    stdout.trim().split('\n').forEach((line) => print('\t$line'));
  }
  if (stderr.trim().isNotEmpty) {
    stderr.trim().split('\n').forEach((line) => print('\t$line'));
  }

  if (result.exitCode != 0) {
    throw Exception('Command failed: $cmd ${args.join(' ')}');
  }

  return captureOutput ? stdout : '';
}

String _stripChangelog(String changelog) {
  final commitLinkRegexp = RegExp(r'\(\[([a-z0-9]{7})\]\(commit/[a-z0-9]{7}\)\)');
  final releasedOnLineRegexp = RegExp(r'Released on: \d{1,2}/\d{1,2}/\d{4}, changelog automatically generated.');
  return changelog.replaceAll(commitLinkRegexp, '').replaceAll(releasedOnLineRegexp, '');
}
