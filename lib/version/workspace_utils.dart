import 'dart:io';

import 'package:mtrust_api_guard/logger.dart';
import 'package:mtrust_api_guard/pubspec_utils.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

class WorkspaceInfo {
  final Directory root;
  final List<String> memberPaths;

  WorkspaceInfo({
    required this.root,
    required this.memberPaths,
  });
}

class WorkspacePackage {
  final String name;
  final Directory directory;
  final String relativePath;

  WorkspacePackage({
    required this.name,
    required this.directory,
    required this.relativePath,
  });
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

    return WorkspaceInfo(
      root: root,
      memberPaths: memberPaths,
    );
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
    final packageDir =
        path.isAbsolute(memberPath) ? Directory(memberPath) : Directory(path.join(workspace.root.path, memberPath));

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

      packages.add(WorkspacePackage(
        name: packageName,
        directory: packageDir,
        relativePath: relativePath,
      ));
    } catch (e) {
      logger.warn('Error reading package name from ${packageDir.path}: $e');
      continue;
    }
  }

  return packages;
}

/// Checks if a package directory has changes between two git refs
Future<bool> packageHasChanges(
  String packagePath,
  String baseRef,
  String newRef,
  Directory gitRoot,
) async {
  try {
    // Use git diff to check if any files in the package directory changed
    final result = await Process.run(
      'git',
      [
        'diff',
        '--name-only',
        '$baseRef..$newRef',
        '--',
        packagePath,
      ],
      workingDirectory: gitRoot.path,
    );

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
