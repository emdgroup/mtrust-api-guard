import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('mtrust_api_guard integration', () {
    late Directory tempDir;
    final fixturesDir = Directory('test/fixtures');
    final appV1Dir = Directory(p.join(fixturesDir.path, 'app_v1'));
    final appV2Dir = Directory(p.join(fixturesDir.path, 'app_v2'));
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

      // 3. Run flutter create if needed (TODO: may not be needed if app_v1 is a full app)
      await _run('flutter', ['create', '.', '--template', 'package'],
          workingDir: tempDir.path);

      // 5. Run api guard to generate documentation (TODO: replace with actual command)
      final apiGuardOut1 = await _run(
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

      // 8. Run api guard to generate documentation (TODO: replace with actual command)
      final apiGuardOut2 = await _run(
        'mtrust_api_guard',
        ['generate'],
        workingDir: tempDir.path,
        captureOutput: true,
      );

      // 9. Run api guard again to detect changes (TODO: replace with actual command)
      final apiGuardOut3 = await _run(
        'mtrust_api_guard',
        ['compare'],
        workingDir: tempDir.path,
        captureOutput: true,
      );

      // 9. Compare output to expected snapshot
      final expectedDiff = await expectedDiffFile.readAsString();
      expect(apiGuardOut2.trim(), expectedDiff.trim());
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
