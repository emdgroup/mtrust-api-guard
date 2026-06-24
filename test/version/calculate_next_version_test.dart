import 'dart:io';

import 'package:mtrust_api_guard/doc_comparator/api_change.dart';
import 'package:mtrust_api_guard/version/calculate_next_version.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  group('incrementPreRelease', () {
    test('increments numeric pre-release suffix', () {
      final version = Version.parse('23.0.0-3');
      expect(incrementPreRelease(version).toString(), '23.0.0-4');
    });

    test('increments dev pre-release suffix', () {
      final version = Version.parse('0.1.0-dev.1');
      expect(incrementPreRelease(version).toString(), '0.1.0-dev.2');
    });
  });

  group('calculateNextVersion pre-release', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('calculate_next_version_test_');
      await Process.run('git', ['init'], workingDirectory: tempDir.path);
      await Process.run('git', ['config', 'user.email', 'test@example.com'], workingDirectory: tempDir.path);
      await Process.run('git', ['config', 'user.name', 'Test'], workingDirectory: tempDir.path);
      await Process.run('git', ['config', 'commit.gpgsign', 'false'], workingDirectory: tempDir.path);
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    Future<void> createTag(String tag) async {
      final commitResult = await Process.run('git', [
        'commit',
        '--allow-empty',
        '-m',
        tag,
      ], workingDirectory: tempDir.path);
      expect(commitResult.exitCode, 0, reason: commitResult.stderr.toString());
      final tagResult = await Process.run('git', ['tag', tag], workingDirectory: tempDir.path);
      expect(tagResult.exitCode, 0, reason: tagResult.stderr.toString());
    }

    test('increments numeric pre-release on same stable base', () async {
      await createTag('liquid_flutter/v23.0.0-1');
      await createTag('liquid_flutter/v23.0.0-2');
      await createTag('liquid_flutter/v23.0.0-3');

      final next = await calculateNextVersion(
        Version.parse('23.0.0-3'),
        ApiChangeMagnitude.patch,
        true,
        tempDir,
        'liquid_flutter/v',
        '',
      );

      expect(next, '23.0.0-4');
    });

    test('starts pre-release for first pre-release bump', () async {
      final next = await calculateNextVersion(Version.parse('0.0.1'), ApiChangeMagnitude.minor, true, tempDir, 'v', '');

      expect(next, '0.1.0-1');
    });

    test('starts dev pre-release with custom prefix', () async {
      final next = await calculateNextVersion(
        Version.parse('0.0.1'),
        ApiChangeMagnitude.minor,
        true,
        tempDir,
        'v',
        'dev',
      );

      expect(next, '0.1.0-dev.1');
    });

    test('bumps stable base and restarts pre-release suffix', () async {
      final next = await calculateNextVersion(
        Version.parse('0.1.0-dev.3'),
        ApiChangeMagnitude.minor,
        true,
        tempDir,
        'v',
        'dev',
      );

      expect(next, '0.2.0-dev.1');
    });

    test('increments dev pre-release on same stable base', () async {
      final next = await calculateNextVersion(
        Version.parse('0.1.0-dev.1'),
        ApiChangeMagnitude.patch,
        true,
        tempDir,
        'v',
        'dev',
      );

      expect(next, '0.1.0-dev.2');
    });

    test('skips existing tags when choosing next pre-release', () async {
      await createTag('v0.1.0-1');

      final next = await calculateNextVersion(Version.parse('0.0.1'), ApiChangeMagnitude.minor, true, tempDir, 'v', '');

      expect(next, '0.1.0-2');
    });
  });

  group('calculateNextVersion release', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('calculate_next_version_release_test_');
      await Process.run('git', ['init'], workingDirectory: tempDir.path);
      await Process.run('git', ['config', 'commit.gpgsign', 'false'], workingDirectory: tempDir.path);
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('finalizes pre-release to stable version', () async {
      final next = await calculateNextVersion(
        Version.parse('1.0.0-dev.1'),
        ApiChangeMagnitude.patch,
        false,
        tempDir,
        'v',
        'dev',
      );

      expect(next, '1.0.0');
    });
  });
}
