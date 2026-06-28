import 'dart:io';

import 'package:mtrust_api_guard/version/workspace_utils.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

/// Creates a minimal temporary workspace package directory with a pubspec.yaml.
WorkspacePackage _makePackage(
  Directory tempDir,
  String name, {
  List<String> workspaceDeps = const [],
}) {
  final dir = Directory(path.join(tempDir.path, name))..createSync();
  final pubspec = StringBuffer()
    ..writeln('name: $name')
    ..writeln('version: 0.1.0')
    ..writeln('environment:')
    ..writeln('  sdk: ">=3.0.0 <4.0.0"');
  if (workspaceDeps.isNotEmpty) {
    pubspec.writeln('dependencies:');
    for (final dep in workspaceDeps) {
      pubspec.writeln('  $dep: ^0.1.0');
    }
  }
  File(path.join(dir.path, 'pubspec.yaml')).writeAsStringSync(pubspec.toString());
  return WorkspacePackage(
    name: name,
    directory: dir,
    relativePath: name,
  );
}

void main() {
  group('sortPackagesTopologically', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('workspace_sort_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('packages with no dependencies keep stable order', () {
      final a = _makePackage(tempDir, 'pkg_a');
      final b = _makePackage(tempDir, 'pkg_b');
      final c = _makePackage(tempDir, 'pkg_c');

      final sorted = sortPackagesTopologically([a, b, c]);

      expect(sorted.map((p) => p.name).toList(), equals(['pkg_a', 'pkg_b', 'pkg_c']));
    });

    test('dependency comes before dependent', () {
      // pkg_child depends on pkg_root
      final root = _makePackage(tempDir, 'pkg_root');
      final child = _makePackage(tempDir, 'pkg_child', workspaceDeps: ['pkg_root']);

      final sorted = sortPackagesTopologically([child, root]);

      expect(sorted.map((p) => p.name).toList(), equals(['pkg_root', 'pkg_child']));
    });

    test('diamond dependency: root before both mid packages before leaf', () {
      // leaf depends on mid_a and mid_b; both depend on root
      final root = _makePackage(tempDir, 'root');
      final midA = _makePackage(tempDir, 'mid_a', workspaceDeps: ['root']);
      final midB = _makePackage(tempDir, 'mid_b', workspaceDeps: ['root']);
      final leaf = _makePackage(tempDir, 'leaf', workspaceDeps: ['mid_a', 'mid_b']);

      final sorted = sortPackagesTopologically([leaf, midB, midA, root]);
      final names = sorted.map((p) => p.name).toList();

      expect(names.indexOf('root'), lessThan(names.indexOf('mid_a')));
      expect(names.indexOf('root'), lessThan(names.indexOf('mid_b')));
      expect(names.indexOf('mid_a'), lessThan(names.indexOf('leaf')));
      expect(names.indexOf('mid_b'), lessThan(names.indexOf('leaf')));
    });

    test('liquid_flutter scenario: liquid_flutter before test_utils and reactive_forms', () {
      final core = _makePackage(tempDir, 'liquid_flutter');
      final testUtils = _makePackage(tempDir, 'liquid_flutter_test_utils',
          workspaceDeps: ['liquid_flutter']);
      final reactiveForms = _makePackage(tempDir, 'liquid_flutter_reactive_forms',
          workspaceDeps: ['liquid_flutter']);

      // Deliberately pass in reverse order to verify sorting
      final sorted = sortPackagesTopologically([reactiveForms, testUtils, core]);
      final names = sorted.map((p) => p.name).toList();

      expect(names.first, equals('liquid_flutter'));
      expect(names.indexOf('liquid_flutter'), lessThan(names.indexOf('liquid_flutter_test_utils')));
      expect(names.indexOf('liquid_flutter'), lessThan(names.indexOf('liquid_flutter_reactive_forms')));
    });

    test('external (non-workspace) dependencies are ignored', () {
      final a = _makePackage(tempDir, 'pkg_a');
      // pkg_b depends on an external package that is not in the workspace
      final dir = Directory(path.join(tempDir.path, 'pkg_b'))..createSync();
      File(path.join(dir.path, 'pubspec.yaml')).writeAsStringSync('''
name: pkg_b
version: 0.1.0
environment:
  sdk: ">=3.0.0 <4.0.0"
dependencies:
  some_external_package: ^1.0.0
  pkg_a: ^0.1.0
''');
      final b = WorkspacePackage(name: 'pkg_b', directory: dir, relativePath: 'pkg_b');

      final sorted = sortPackagesTopologically([b, a]);
      expect(sorted.map((p) => p.name).toList(), equals(['pkg_a', 'pkg_b']));
    });

    test('falls back to original order on cycle', () {
      // Create a cycle: pkg_x depends on pkg_y, pkg_y depends on pkg_x
      final dirX = Directory(path.join(tempDir.path, 'pkg_x'))..createSync();
      File(path.join(dirX.path, 'pubspec.yaml')).writeAsStringSync('''
name: pkg_x
version: 0.1.0
environment:
  sdk: ">=3.0.0 <4.0.0"
dependencies:
  pkg_y: ^0.1.0
''');
      final dirY = Directory(path.join(tempDir.path, 'pkg_y'))..createSync();
      File(path.join(dirY.path, 'pubspec.yaml')).writeAsStringSync('''
name: pkg_y
version: 0.1.0
environment:
  sdk: ">=3.0.0 <4.0.0"
dependencies:
  pkg_x: ^0.1.0
''');
      final x = WorkspacePackage(name: 'pkg_x', directory: dirX, relativePath: 'pkg_x');
      final y = WorkspacePackage(name: 'pkg_y', directory: dirY, relativePath: 'pkg_y');

      // Should not throw; returns original order
      final sorted = sortPackagesTopologically([x, y]);
      expect(sorted.map((p) => p.name).toList(), equals(['pkg_x', 'pkg_y']));
    });
  });
}
