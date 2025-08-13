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
      final appV100Dir = Directory(p.join(fixturesDir.path, 'app_v100'));
      final appV101Dir = Directory(p.join(fixturesDir.path, 'app_v101'));
      final appV110Dir = Directory(p.join(fixturesDir.path, 'app_v110'));
      final appV200Dir = Directory(p.join(fixturesDir.path, 'app_v200'));
      final expectedDiffFile = File(
        p.join(fixturesDir.path, 'expected_diff.txt'),
      );
      final expectedChangelogFile = File(
        p.join(fixturesDir.path, 'expected_changelog.md'),
      );

      setUp(() async {
        tempDir = await Directory.systemTemp.createTemp('api_guard_test_');
        tempDir = Directory(p.join(tempDir.path, 'api_guard_test'));
        print(tempDir.path);
      });

      tearDown(() async {
        //await tempDir.delete(recursive: true);
      });

      Future<void> _runApiGuard(String command, List<String> args) async {
        final result = await Process.run(
          'dart',
          ["${rootDir.path}/bin/mtrust_api_guard.dart", command, ...args],
          workingDirectory: tempDir.path,
        );

        if (result.exitCode != 0) {
          throw Exception('Command failed: $command ${args.join(' ')}\n'
              'stdout: ${result.stdout}\n'
              'stderr: ${result.stderr}');
        }
      }

      test('detects API changes between versions', () async {
        // 1. Copy app_v1 to tempDir
        await _copyDir(appV100Dir, tempDir);

        // 2. Initialize git
        await _run('git', ['init'], workingDir: tempDir.path);
        await _run('git', ['config', 'user.email', 'test@example.com'],
            workingDir: tempDir.path);
        await _run('git', ['config', 'user.name', 'Test User'],
            workingDir: tempDir.path);

        await _run('flutter', ['create', '.', '--template', 'package'],
            workingDir: tempDir.path);

        // Set the initial version in pubspec.yaml to 1.0.0
        final yaml = File(p.join(tempDir.path, 'pubspec.yaml'));
        yaml.writeAsStringSync(
          yaml.readAsStringSync().replaceFirst(
              RegExp(r'version: \d+\.\d+\.\d+'), 'version: 1.0.0'),
        );

        // Write the initial CHANGELOG.md
        final changelog = File(p.join(tempDir.path, 'CHANGELOG.md'));
        changelog.writeAsStringSync(
          '## 1.0.0\n'
          'Initial release.\n',
        );

        await _runApiGuard('generate', []);

        // 4. Commit initial state
        await _run('git', ['add', '.'], workingDir: tempDir.path);
        await _run('git', ['commit', '-m', 'chore!: Initial release v1.0.0'],
            workingDir: tempDir.path);
        await _run('git', ['tag', 'v1.0.0'], workingDir: tempDir.path);

        YamlMap pubspec = loadYaml(yaml.readAsStringSync());
        expect(pubspec['version'], '1.0.0');

        // 5. Copy app_v1_0_1 over tempDir
        await _copyDir(appV101Dir, tempDir);

        // 6. Commit changes
        await _run('git', ['add', '.'], workingDir: tempDir.path);
        await _run('git', ['commit', '-m', 'API change to v1.0.1'],
            workingDir: tempDir.path);

        await _runApiGuard('generate', []);
        await _runApiGuard('version', []);
        await _runApiGuard('changelog', []);

        pubspec = loadYaml(yaml.readAsStringSync());
        expect(pubspec['version'], '1.0.1');

        // 6. Copy app_v2 over tempDir
        await _copyDir(appV110Dir, tempDir);

        // 7. Commit changes
        await _run('git', ['add', '.'], workingDir: tempDir.path);
        await _run('git', ['commit', '-m', 'API change to v1.1.0'],
            workingDir: tempDir.path);

        await _runApiGuard('generate', []);
        await _runApiGuard('version', []);
        await _runApiGuard('changelog', []);

        pubspec = loadYaml(yaml.readAsStringSync());
        expect(pubspec['version'], '1.1.0');

        // 8. Copy app_v3 over tempDir
        await _copyDir(appV200Dir, tempDir);
        await _run('git', ['add', '.'], workingDir: tempDir.path);
        await _run('git',
            ['commit', '-m', 'feat: implement compatibility with v2.0.0'],
            workingDir: tempDir.path);

        await _runApiGuard('generate', []);
        await _runApiGuard('version', []);
        await _runApiGuard('changelog', []);

        pubspec = loadYaml(yaml.readAsStringSync());
        expect(pubspec['version'], '2.0.0');

        // Compare the tags
        final tags = await _run(
          'git',
          ['tag'],
          workingDir: tempDir.path,
          captureOutput: true,
        );
        expect(tags, contains('v1.0.0'));
        expect(tags, contains('v1.0.1'));
        expect(tags, contains('v1.1.0'));
        expect(tags, contains('v2.0.0'));

        // 9. Compare output to expected snapshot
        final changelogFile = File(p.join(tempDir.path, 'CHANGELOG.md'));
        final changelogContent = _stripChangelog(
          await changelogFile.readAsString(),
        );
        final expectedChangelog = _stripChangelog(
          await expectedChangelogFile.readAsString(),
        );
        print('Changelog content:\n$changelogContent');
        print('Expected changelog:\n$expectedChangelog');
        expect(changelogContent, equalsIgnoringWhitespace(expectedChangelog));
      });
    },
    timeout: Timeout(Duration(minutes: 5)),
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
Future<String> _run(String cmd, List<String> args,
    {String? workingDir, bool captureOutput = false}) async {
  final result = await Process.run(cmd, args, workingDirectory: workingDir);

  final stdout = result.stdout.toString();
  final stderr = result.stderr.toString();

  if (stdout.isNotEmpty) {
    print('stdout: $stdout');
  }
  if (stderr.isNotEmpty) {
    print('stderr: $stderr');
  }

  if (result.exitCode != 0) {
    throw Exception('Command failed: $cmd ${args.join(' ')}');
  }

  return captureOutput ? stdout : '';
}
// TODO: Add test/fixtures/app_v1, app_v2, and expected_diff.txt for this test to work.

String _stripChangelog(String changelog) {
  final commitLinkRegexp =
      RegExp(r'\(\[([a-z0-9]{7})\]\(commit/[a-z0-9]{7}\)\)');
  final releasedOnLineRegexp = RegExp(
      r'Released on: \d{1,2}/\d{1,2}/\d{4}, changelog automatically generated.');
  return changelog
      .replaceAll(commitLinkRegexp, '')
      .replaceAll(releasedOnLineRegexp, '');
}
