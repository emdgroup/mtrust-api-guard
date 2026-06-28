import 'dart:io';

import 'package:mtrust_api_guard/logger.dart';
import 'package:mtrust_api_guard/pubspec_utils.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

class WorkspaceInfo {
  final Directory root;
  final List<String> memberPaths;

  WorkspaceInfo({required this.root, required this.memberPaths});
}

class WorkspacePackage {
  final String name;
  final Directory directory;
  final String relativePath;

  WorkspacePackage({required this.name, required this.directory, required this.relativePath});
}

/// Detects if the given directory is a Dart workspace root
WorkspaceInfo? detectWorkspace(Directory root) {
  final pubspecFile = File(path.join(root.path, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) {
    return null;
  }

  try {
    final pubspecContent = pubspecFile.readAsStringSync();
    final pubspec = loadYaml(pubspecContent) as Map;

    // Check if workspace property exists
    final workspace = pubspec['workspace'];
    if (workspace == null) {
      return null;
    }

    // Workspace can be a list of strings or a map with 'members' key
    List<String> memberPaths = [];
    if (workspace is YamlList) {
      memberPaths = workspace.map((e) => e.toString()).toList();
    } else if (workspace is Map && workspace.containsKey('members')) {
      final members = workspace['members'];
      if (members is YamlList) {
        memberPaths = members.map((e) => e.toString()).toList();
      }
    }

    if (memberPaths.isEmpty) {
      return null;
    }

    return WorkspaceInfo(root: root, memberPaths: memberPaths);
  } catch (e) {
    logger.detail('Error detecting workspace: $e');
    return null;
  }
}

/// Gets all workspace packages with their names and directories
List<WorkspacePackage> getWorkspacePackages(WorkspaceInfo workspace) {
  final packages = <WorkspacePackage>[];

  for (final memberPath in workspace.memberPaths) {
    // Resolve path relative to workspace root
    final packageDir = path.isAbsolute(memberPath)
        ? Directory(memberPath)
        : Directory(path.join(workspace.root.path, memberPath));

    if (!packageDir.existsSync()) {
      logger.warn('Workspace member path does not exist: ${packageDir.path}');
      continue;
    }

    final pubspecFile = File(path.join(packageDir.path, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      logger.warn('pubspec.yaml not found for workspace member: ${packageDir.path}');
      continue;
    }

    try {
      final pubspecContent = pubspecFile.readAsStringSync();
      final packageName = PubspecUtils.getPackageName(pubspecContent);
      final relativePath = path.relative(packageDir.path, from: workspace.root.path);

      packages.add(WorkspacePackage(name: packageName, directory: packageDir, relativePath: relativePath));
    } catch (e) {
      logger.warn('Error reading package name from ${packageDir.path}: $e');
      continue;
    }
  }

  return packages;
}

/// Returns the workspace packages sorted in topological order so that a package
/// always appears before any other package that depends on it.
/// Packages with no intra-workspace dependencies come first.
List<WorkspacePackage> sortPackagesTopologically(List<WorkspacePackage> packages) {
  // Build a name -> package map and a dependency graph
  final packageNames = {for (final p in packages) p.name};
  final deps = <String, Set<String>>{};

  for (final package in packages) {
    final pubspecFile = File(path.join(package.directory.path, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      deps[package.name] = {};
      continue;
    }
    try {
      final content = pubspecFile.readAsStringSync();
      final pubspec = loadYaml(content) as Map;
      final workspaceDeps = <String>{};
      for (final section in ['dependencies', 'dev_dependencies']) {
        final sectionMap = pubspec[section];
        if (sectionMap is Map) {
          for (final dep in sectionMap.keys) {
            if (packageNames.contains(dep as String)) {
              workspaceDeps.add(dep);
            }
          }
        }
      }
      deps[package.name] = workspaceDeps;
    } catch (e) {
      logger.warn('Error reading dependencies for ${package.name}: $e');
      deps[package.name] = {};
    }
  }

  // Kahn's algorithm for topological sort
  final inDegree = <String, int>{for (final p in packages) p.name: 0};
  for (final entry in deps.entries) {
    for (final _ in entry.value) {
      inDegree[entry.key] = (inDegree[entry.key] ?? 0) + 1;
    }
  }

  // Build reverse map: dependency -> list of packages that depend on it
  final dependents = <String, List<String>>{};
  for (final entry in deps.entries) {
    for (final dep in entry.value) {
      dependents.putIfAbsent(dep, () => []).add(entry.key);
    }
  }

  final queue = <String>[
    for (final p in packages)
      if ((inDegree[p.name] ?? 0) == 0) p.name,
  ];
  final sorted = <String>[];

  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    sorted.add(current);
    for (final dependent in (dependents[current] ?? [])) {
      inDegree[dependent] = (inDegree[dependent] ?? 1) - 1;
      if (inDegree[dependent] == 0) {
        queue.add(dependent);
      }
    }
  }

  if (sorted.length != packages.length) {
    logger.warn('Cycle detected in workspace dependency graph; falling back to original order');
    return packages;
  }

  final packageMap = {for (final p in packages) p.name: p};
  return sorted.map((name) => packageMap[name]!).toList();
}

/// Checks if a package directory has changes between two git refs
Future<bool> packageHasChanges(String packagePath, String baseRef, String newRef, Directory gitRoot) async {
  try {
    // Use git diff to check if any files in the package directory changed
    final result = await Process.run('git', [
      'diff',
      '--name-only',
      '$baseRef..$newRef',
      '--',
      packagePath,
    ], workingDirectory: gitRoot.path);

    if (result.exitCode != 0) {
      logger.warn('Git diff failed for package $packagePath: ${result.stderr}');
      // If diff fails, assume package has changes to be safe
      return true;
    }

    final changedFiles = result.stdout.toString().trim();
    return changedFiles.isNotEmpty;
  } catch (e) {
    logger.warn('Error checking changes for package $packagePath: $e');
    // If check fails, assume package has changes to be safe
    return true;
  }
}
