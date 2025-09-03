import 'dart:io';

import 'package:path/path.dart' as p;

/// Recursively copy [src] directory to [dst].
Future<void> copyDir(Directory src, Directory dst) async {
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
Future<String> runProcess(String cmd, List<String> args, {String? workingDir, bool captureOutput = false}) async {
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

/// Strip changelog content for comparison by removing dynamic content like commit hashes and dates.
String stripChangelog(String changelog) {
  final commitLinkRegexp = RegExp(r'\(\[([a-z0-9]{7})\]\(commit/[a-z0-9]{7}\)\)');
  final releasedOnLineRegexp = RegExp(r'Released on: \d{1,2}/\d{1,2}/\d{4}, changelog automatically generated.');
  return changelog.replaceAll(commitLinkRegexp, '').replaceAll(releasedOnLineRegexp, '');
}

/// Test constants for better maintainability.
class TestConstants {
  static const String initialVersion = '0.0.1';
  static const String patchVersion = '0.0.2';
  static const String minorVersion = '0.1.0';
  static const String majorVersion = '1.0.0';
  static const String testEmail = 'test@example.com';
  static const String testUser = 'Test User';
}

/// Helper class for managing test fixtures and directories.
class TestFixtures {
  final Directory fixturesDir;
  final Directory appV100Dir;
  final Directory appV101Dir;
  final Directory appV110Dir;
  final Directory appV200Dir;
  final File expectedChangelogFile;

  TestFixtures()
      : fixturesDir = Directory('test/fixtures'),
        appV100Dir = Directory('test/fixtures/app_v100'),
        appV101Dir = Directory('test/fixtures/app_v101'),
        appV110Dir = Directory('test/fixtures/app_v110'),
        appV200Dir = Directory('test/fixtures/app_v200'),
        expectedChangelogFile = File('test/fixtures/expected_changelog.md');
}
