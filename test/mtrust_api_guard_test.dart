import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('mtrust_api_guard integration', () {
    late Directory tempDir;
    final fixturesDir = Directory('test/fixtures');
    final appV1Dir = Directory(p.join(fixturesDir.path, 'app_v1'));
    final appV2Dir = Directory(p.join(fixturesDir.path, 'app_v2'));
    final appV3Dir = Directory(p.join(fixturesDir.path, 'app_v3'));
    final expectedDiffFile = File(
      p.join(fixturesDir.path, 'expected_diff.txt'),
    );

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('api_guard_test_');
      tempDir = Directory(p.join(tempDir.path, 'api_guard_test'));
      print(tempDir.path);
    });

    tearDown(() async {
      //await tempDir.delete(recursive: true);
    });

    test('detects API changes between versions', () async {
      // 1. Copy app_v1 to tempDir
      await _copyDir(appV1Dir, tempDir);

      // 2. Initialize git
      await _run('git', ['init'], workingDir: tempDir.path);
      await _run('git', ['config', 'user.email', 'test@example.com'],
          workingDir: tempDir.path);
      await _run('git', ['config', 'user.name', 'Test User'],
          workingDir: tempDir.path);

      await _run('flutter', ['create', '.', '--template', 'package'],
          workingDir: tempDir.path);

      await _run(
        'mtrust_api_guard',
        ['generate'],
        workingDir: tempDir.path,
        captureOutput: true,
      );

      // 4. Commit initial state
      await _run('git', ['add', '.'], workingDir: tempDir.path);
      await _run('git', ['commit', '-m', 'Initial commit'],
          workingDir: tempDir.path);

      // 6. Copy app_v2 over tempDir
      await _copyDir(appV2Dir, tempDir);

      // 7. Commit changes
      await _run('git', ['add', '.'], workingDir: tempDir.path);
      await _run('git', ['commit', '-m', 'API change'],
          workingDir: tempDir.path);

      final apiGuardOut2 = await _run(
        'mtrust_api_guard',
        ['generate'],
        workingDir: tempDir.path,
        captureOutput: true,
      );

      await _run(
        'mtrust_api_guard',
        ['version'],
        workingDir: tempDir.path,
        captureOutput: true,
      );

      final yaml = File(p.join(tempDir.path, 'pubspec.yaml'));

      final pubspec = loadYaml(yaml.readAsStringSync());

      expect(pubspec['version'], '1.0.0');

      await _run(
        'mtrust_api_guard',
        ['changelog'],
        workingDir: tempDir.path,
        captureOutput: true,
      );

      await _copyDir(appV3Dir, tempDir);

      await _run('git', ['add', '.'], workingDir: tempDir.path);
      await _run('git', ['commit', '-m', 'API change 3'],
          workingDir: tempDir.path);

      await _run(
        'mtrust_api_guard',
        ['generate'],
        workingDir: tempDir.path,
        captureOutput: true,
      );

      await _run(
        'mtrust_api_guard',
        ['version'],
        workingDir: tempDir.path,
        captureOutput: true,
      );

      final yaml2 = File(p.join(tempDir.path, 'pubspec.yaml'));

      final pubspec2 = loadYaml(yaml2.readAsStringSync());

      expect(pubspec2['version'], '1.1.0');

      await _run(
        'mtrust_api_guard',
        ['changelog'],
        workingDir: tempDir.path,
        captureOutput: true,
      );

      // 9. Compare output to expected snapshot
    });
  });
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
