import 'dart:io';

import 'package:mtrust_api_guard/doc_generator/git_utils.dart';
import 'package:mtrust_api_guard/logger.dart';
import 'package:mtrust_api_guard/pubspec_utils.dart';
import 'package:mtrust_api_guard/version/version.dart';
import 'package:mtrust_api_guard/version/workspace_utils.dart';
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';

class WorkspaceVersionResult {
  final Map<String, VersionResult> packageResults;
  final Map<String, Version> packageVersions;

  WorkspaceVersionResult({
    required this.packageResults,
    required this.packageVersions,
  });

  Map<String, dynamic> toJson() {
    return {
      'packages': packageResults.map((key, value) => MapEntry(key, value.toJson())),
    };
  }
}

/// Versions all packages in a workspace
Future<WorkspaceVersionResult> versionWorkspace({
  required Directory gitRoot,
  required WorkspaceInfo workspace,
  String? baseRef,
  required bool tag,
  String? newRef,
  required bool isPreRelease,
  required String preReleasePrefix,
  required bool commit,
  required bool badge,
  required bool generateChangelog,
  required bool cache,
  String? dartFile,
}) async {
  final packages = getWorkspacePackages(workspace);
  final effectiveNewRef = newRef ?? 'HEAD';

  logger.info('Found ${packages.length} packages in workspace');

  // Track which packages were versioned and their new versions
  final packageResults = <String, VersionResult>{};
  final packageVersions = <String, Version>{};

  // Step 1: Version each changed package
  for (final package in packages) {
    logger.info('Processing package: ${package.name}');

    // Determine the base ref for this package
    // If baseRef is provided, use it; otherwise get the previous tag for this package
    final packageBaseRef = baseRef ??
        (await GitUtils.getPreviousRefForPackage(gitRoot.path, package.name, tagPrefix: 'v') ?? effectiveNewRef);

    // Check if package has changes
    final hasChanges = await packageHasChanges(
      package.relativePath,
      packageBaseRef,
      effectiveNewRef,
      gitRoot,
    );

    if (!hasChanges) {
      logger.info('Package ${package.name} has no changes, skipping versioning');
      continue;
    }

    logger.info('Package ${package.name} has changes, versioning...');

    // Determine tag prefix for this package (format: package-name/v)
    final tagPrefix = '${package.name}/v';

    // Version the package
    try {
      final result = await version(
        gitRoot: gitRoot,
        dartRoot: package.directory,
        baseRef: baseRef,
        tag: tag,
        newRef: effectiveNewRef,
        isPreRelease: isPreRelease,
        preReleasePrefix: preReleasePrefix,
        commit: commit,
        badge: badge,
        generateChangelog: generateChangelog,
        cache: cache,
        tagPrefix: tagPrefix,
        dartFile: dartFile != null ? path.join(package.directory.path, dartFile) : null,
        packageName: package.name,
      );

      packageResults[package.name] = result;
      packageVersions[package.name] = result.version;
      logger.success('Versioned ${package.name} to ${result.version}');
    } catch (e) {
      logger.err('Failed to version package ${package.name}: $e');
      rethrow;
    }
  }

  // Step 2: Update dependencies between workspace packages
  if (packageVersions.isNotEmpty) {
    logger.info('Updating workspace dependencies...');
    await updateWorkspaceDependencies(
      workspace: workspace,
      packages: packages,
      updatedVersions: packageVersions,
    );
    logger.success('Updated workspace dependencies');
  }

  return WorkspaceVersionResult(
    packageResults: packageResults,
    packageVersions: packageVersions,
  );
}

/// Updates dependencies in workspace packages that reference other workspace packages
Future<void> updateWorkspaceDependencies({
  required WorkspaceInfo workspace,
  required List<WorkspacePackage> packages,
  required Map<String, Version> updatedVersions,
}) async {
  // Create a map of package names to their directories for quick lookup
  final packageMap = <String, WorkspacePackage>{};
  for (final package in packages) {
    packageMap[package.name] = package;
  }

  // Update dependencies in all packages
  for (final package in packages) {
    final pubspecFile = File(path.join(package.directory.path, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      continue;
    }

    final pubspecContent = await pubspecFile.readAsString();
    final dependencies = PubspecUtils.getAllDependencies(pubspecContent);

    bool needsUpdate = false;

    // Check if this package depends on any of the updated packages
    for (final dependencyName in dependencies.keys) {
      if (updatedVersions.containsKey(dependencyName) && packageMap.containsKey(dependencyName)) {
        // This is a workspace dependency that was updated
        needsUpdate = true;
        break;
      }
    }

    if (needsUpdate) {
      // Update each workspace dependency
      for (final entry in updatedVersions.entries) {
        final dependencyName = entry.key;
        final newVersion = entry.value;

        // Check if this package depends on this workspace package
        if (dependencies.containsKey(dependencyName)) {
          try {
            await PubspecUtils.updateWorkspaceDependency(
              pubspecFile,
              dependencyName,
              newVersion,
            );
            logger.info('Updated dependency $dependencyName to $newVersion in ${package.name}');
          } catch (e) {
            logger.warn('Failed to update dependency $dependencyName in ${package.name}: $e');
          }
        }
      }
    }
  }
}
