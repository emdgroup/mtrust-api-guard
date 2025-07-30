import 'dart:convert';
import 'dart:io';

import 'package:mtrust_api_guard/doc_comparator/api_change.dart';
import 'package:mtrust_api_guard/doc_comparator/api_change_formatter.dart';
import 'package:mtrust_api_guard/logger.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

/// Represents a single commit's information
class CommitInfo {
  final String hash;
  final String author;
  final String message;
  final DateTime date;

  CommitInfo({
    required this.hash,
    required this.author,
    required this.message,
    required this.date,
  });

  @override
  String toString() {
    final shortHash = hash.substring(0, 7);
    final formattedDate = '${date.month}/${date.day}/${date.year}';
    return '- **$shortHash** ($formattedDate) by $author: $message';
  }
}

/// Generates a changelog entry based on the API changes and the current version from pubspec.yaml
class ChangelogGenerator {
  final List<ApiChange> apiChanges;
  final Directory projectRoot;

  ChangelogGenerator({
    required this.apiChanges,
    required this.projectRoot,
  });

  /// Gets the commits since the last version tag
  Future<List<CommitInfo>> _getCommitsSinceLastVersion() async {
    try {
      // Get the last version tag
      final lastTagResult = await Process.run(
        'git',
        ['describe', '--tags', '--abbrev=0'],
        workingDirectory: projectRoot.path,
      );

      final commits = <CommitInfo>[];
      final gitLogFormat =
          '%H%n%an%n%at%n%s'; // hash, author name, author date (unix timestamp), subject

      if (lastTagResult.exitCode == 0) {
        final lastTag = lastTagResult.stdout.toString().trim();
        // Get commits since the last tag
        final commitResult = await Process.run(
          'git',
          [
            'log',
            '$lastTag..HEAD',
            '--pretty=format:$gitLogFormat',
            '--no-merges'
          ],
          workingDirectory: projectRoot.path,
        );
        if (commitResult.exitCode == 0) {
          commits
              .addAll(_parseCommitLog(commitResult.stdout.toString().trim()));
        }
      } else {
        // If no tags exist, get all commits
        final commitResult = await Process.run(
          'git',
          ['log', '--pretty=format:$gitLogFormat', '--no-merges'],
          workingDirectory: projectRoot.path,
        );
        if (commitResult.exitCode == 0) {
          commits
              .addAll(_parseCommitLog(commitResult.stdout.toString().trim()));
        }
      }

      return commits;
    } catch (e) {
      logger.err('Error retrieving commits: $e');
      return [];
    }
  }

  /// Parses the git log output into CommitInfo objects
  List<CommitInfo> _parseCommitLog(String log) {
    if (log.isEmpty) return [];

    final commits = <CommitInfo>[];
    final lines = LineSplitter.split(log).toList();

    for (var i = 0; i < lines.length; i += 4) {
      if (i + 3 >= lines.length) break;

      final hash = lines[i];
      final author = lines[i + 1];
      final timestamp = int.parse(lines[i + 2]);
      final message = lines[i + 3];

      commits.add(CommitInfo(
        hash: hash,
        author: author,
        message: message,
        date: DateTime.fromMillisecondsSinceEpoch(timestamp * 1000),
      ));
    }

    return commits;
  }

  /// Generates a changelog entry, including the version from pubspec.yaml
  /// and the formatted API changes
  Future<String> generateChangelogEntry() async {
    final version = await _getPackageVersion();
    final apiChangesFormatter = ApiChangeFormatter(
      apiChanges,
      markdownHeaderLevel: 4,
    );
    final formattedChanges = apiChangesFormatter.format();
    final commits = await _getCommitsSinceLastVersion();

    final buffer = StringBuffer();
    final time = DateTime.now();

    buffer.writeln('## $version');
    buffer.writeln(
      'Released on: ${time.month}/${time.day}/${time.year}, changelog automatically generated.',
    );

    if (commits.isNotEmpty) {
      buffer.writeln('\n### Commits\n');
      for (final commit in commits) {
        buffer.writeln(commit.toString());
      }
      buffer.writeln();
    }

    if (formattedChanges.isNotEmpty) {
      buffer.writeln('\n### API Changes\n');
      buffer.writeln(formattedChanges);
    }

    buffer.writeln();

    return buffer.toString();
  }

  /// Updates the CHANGELOG.md file with the new entry at the top
  Future<void> updateChangelogFile() async {
    final changelogFile = File(join(projectRoot.path, 'CHANGELOG.md'));
    final newEntry = await generateChangelogEntry();

    String existingContent = '';
    if (changelogFile.existsSync()) {
      existingContent = await changelogFile.readAsString();
    }

    // Remove the first line if it's empty to avoid double line breaks
    final contentLines = existingContent.split('\n');
    if (contentLines.isNotEmpty && contentLines.first.trim().isEmpty) {
      contentLines.removeAt(0);
      existingContent = contentLines.join('\n');
    }

    final updatedContent = '$newEntry$existingContent';
    await changelogFile.writeAsString(updatedContent);

    logger.info('CHANGELOG.md updated successfully.');
  }

  /// Retrieves the package version from pubspec.yaml
  Future<String> _getPackageVersion() async {
    try {
      final pubspecFile = File(join(projectRoot.path, 'pubspec.yaml'));
      if (!pubspecFile.existsSync()) {
        throw Exception('pubspec.yaml not found at ${pubspecFile.path}');
      }

      final pubspecContent = await pubspecFile.readAsString();
      final pubspec = loadYaml(pubspecContent);

      final version = pubspec['version'];
      if (version == null) {
        throw Exception('Version not found in pubspec.yaml');
      }

      return version.toString();
    } catch (e) {
      logger.err('Error retrieving package version: $e');
      rethrow;
    }
  }
}
