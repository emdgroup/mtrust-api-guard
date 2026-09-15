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

/// Copies a fixture package into a temporary directory, gives it a pubspec and
/// resolves it, so the analyzer can follow its `package:` imports.
///
/// [packageName] has to match the `package:` imports the fixture makes of
/// itself, which for the `app_v*` fixtures is the scaffold's `api_guard_test`.
///
/// Pass [initGit] for the commands that read the tree through git rather than
/// off disk.
Future<Directory> materializeFixturePackage(Directory fixture, String packageName, {bool initGit = false}) async {
  final temp = await Directory.systemTemp.createTemp('api_guard_fixture_');
  final target = Directory(p.join(temp.path, packageName))..createSync(recursive: true);

  await copyDir(fixture, target);

  File(p.join(target.path, 'pubspec.yaml')).writeAsStringSync('''
name: $packageName
description: Fixture package, resolved so the commands can read it.
version: 1.0.0
publish_to: none

environment:
  sdk: ">=3.11.0 <4.0.0"
''');

  final result = await Process.run('dart', ['pub', 'get'], workingDirectory: target.path);
  if (result.exitCode != 0) {
    throw StateError('dart pub get failed in ${target.path}: ${result.stderr}');
  }

  if (initGit) {
    for (final command in [
      ['init', '-q', '.'],
      ['add', '-A'],
      ['-c', 'user.email=fixtures@example.test', '-c', 'user.name=fixtures', 'commit', '-qm', 'fixture'],
    ]) {
      await Process.run('git', command, workingDirectory: target.path);
    }
  }

  return target;
}
