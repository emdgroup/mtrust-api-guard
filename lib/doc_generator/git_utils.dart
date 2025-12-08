import 'dart:io';

import 'package:mtrust_api_guard/logger.dart';
import 'package:pub_semver/pub_semver.dart';

/// Utility functions for Git operations
class GitUtils {
  /// Checks if the current repository has uncommitted changes
  /// Throws [GitException] if Git is not available or if there's an error.
  static bool hasUncommittedChanges(String? root) {
    try {
      // Check if we're in a Git repository
      final result = Process.runSync('git', ['status', '--porcelain'], workingDirectory: root);

      if (result.exitCode != 0) {
        throw const GitException('Not a Git repository or Git command failed');
      }

      // If there's any output, there are uncommitted changes
      return result.stdout.toString().trim().isNotEmpty;
    } on ProcessException catch (e) {
      throw GitException('Git command not found: ${e.message}');
    } catch (e) {
      throw GitException('Unexpected error: $e');
    }
  }

  /// Gets the current Git branch name
  /// Returns null if in detached HEAD state or throws [GitException] if there's an error.
  static Future<String?> getCurrentBranch(String? root) async {
    try {
      final result = await Process.run('git', ['branch', '--show-current'], workingDirectory: root);

      if (result.exitCode != 0) {
        // In detached HEAD state, this command returns empty output
        final output = result.stdout.toString().trim();
        if (output.isEmpty) {
          return null;
        }
        throw const GitException('Failed to get current branch');
      }

      final output = result.stdout.toString().trim();
      return output.isEmpty ? null : output;
    } on ProcessException catch (e) {
      throw GitException('Git command not found: ${e.message}');
    } catch (e) {
      throw GitException('Unexpected error: $e');
    }
  }

  /// Checks if the current directory is a Git repository
  static Future<bool> isGitRepository(String? root) async {
    try {
      final result = await Process.run(
        'git',
        ['rev-parse', '--git-dir'],
        workingDirectory: root,
      );
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Gets the current working directory path
  static String getCurrentWorkingDirectory() {
    return Directory.current.path;
  }

  /// Gets the repository root directory
  static String getRepositoryRoot(String? root) {
    try {
      final result = Process.runSync('git', ['rev-parse', '--show-toplevel'], workingDirectory: root);
      if (result.exitCode != 0) {
        throw const GitException('Failed to get repository root');
      }
      return result.stdout.toString().trim();
    } on ProcessException catch (e) {
      throw GitException('Git command not found: ${e.message}');
    } catch (e) {
      throw GitException('Unexpected error: $e');
    }
  }

  /// Checks out a specific git ref
  /// Throws [GitException] if the operation fails
  static Future<void> checkoutRef(String ref, String? root) async {
    try {
      final result = await Process.run('git', ['checkout', ref], workingDirectory: root);
      if (result.exitCode != 0) {
        throw GitException('Failed to checkout ref $ref: ${result.stderr}');
      }
    } on ProcessException catch (e) {
      throw GitException('Git command not found: ${e.message}');
    } catch (e) {
      throw GitException('Unexpected error: $e');
    }
  }

  /// Gets the current HEAD ref
  static Future<String> getCurrentRef(String? root) async {
    try {
      final result = await Process.run('git', ['rev-parse', 'HEAD'], workingDirectory: root);
      if (result.exitCode != 0) {
        throw GitException('Failed to get current HEAD ${result.stderr.toString()}');
      }
      return result.stdout.toString().trim();
    } on ProcessException catch (e) {
      throw GitException('Git command not found: ${e.message}');
    } catch (e) {
      throw GitException('Unexpected error: $e');
    }
  }

  static Future<List<String>> getTags(String? root) async {
    final result = await Process.run('git', ['tag', '--sort=-creatordate'], workingDirectory: root);
    if (result.exitCode != 0) {
      throw const GitException('Failed to get tags');
    }
    return result.stdout.toString().trim().split('\n');
  }

  static Future<List<(String, Version)>> getVersions(String? root) async {
    final tags = await getTags(root);
    if (tags.isEmpty) {
      throw const GitException('No tags found');
    }

    final versions = tags
        .where((tag) => tag.isNotEmpty)
        .map((tag) {
          String version = tag;
          if (tag.startsWith('v')) {
            version = tag.substring(1);
          }

          try {
            return (tag, Version.parse(version));
          } catch (e) {
            logger.detail('Skipping tag $tag . Not a valid version.');
            return null;
          }
        })
        .whereType<(String, Version)>()
        .toList();

    final sortedVersions = versions.toList()..sort((a, b) => a.$2.compareTo(b.$2));

    return sortedVersions;
  }

  static Future<bool> gitTagExists(String tag, String? root) async {
    final result = await Process.run('git', ['tag', '-l', tag], workingDirectory: root);
    return result.stdout.toString().trim().isNotEmpty;
  }

  static Future<void> commitVersion(String version, String? root, {bool? commitBadge}) async {
    final result = await Process.run(
        'git',
        [
          'commit',
          '-m',
          'chore: bump version to $version [skip ci]',
          'pubspec.yaml',
          'CHANGELOG.md',
          if (commitBadge == true) 'version_badge.svg',
        ],
        workingDirectory: root);
    if (result.exitCode != 0) {
      throw GitException('Failed to commit version $version: ${result.stderr.toString()}');
    }
  }

  static Future<void> gitTag(String tag, String? root) async {
    final result = await Process.run('git', ['tag', '-a', tag, '-m', 'Release $tag'], workingDirectory: root);
    if (result.exitCode != 0) {
      throw GitException('Failed to tag $tag: ${result.stderr.toString()}');
    }
  }

  static Future<String> getPreviousRef(String? root) async {
    final tags = await getVersions(root);
    if (tags.isEmpty) {
      throw const GitException('No tags found');
    }

    return tags.last.$1;
  }

  static Future<String> gitShow(String ref, String? root, String path) async {
    final result = await Process.run(
      'git',
      [
        'show',
        '$ref:$path',
      ],
      workingDirectory: root,
    );
    if (result.exitCode != 0) {
      throw GitException('Failed to show ref $ref:$path: ${result.stderr.toString()}');
    }
    return result.stdout.toString().trim();
  }
}

/// Exception thrown when Git operations fail
class GitException implements Exception {
  final String message;

  const GitException(this.message);

  @override
  String toString() => 'GitException: $message';
}
