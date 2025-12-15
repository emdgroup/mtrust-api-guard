import 'dart:io';

import 'package:conventional/conventional.dart';
import 'package:mtrust_api_guard/doc_comparator/api_change.dart';
import 'package:mtrust_api_guard/doc_comparator/api_change_formatter.dart';
import 'package:mtrust_api_guard/logger.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

/// Generates a changelog entry based on the API changes and the current version from pubspec.yaml
class ChangelogGenerator {
  final List<ApiChange> apiChanges;
  final Directory projectRoot;
  final String? fileBaseUrl;

  ChangelogGenerator({
    required this.apiChanges,
    required this.projectRoot,
    this.fileBaseUrl,
  });

  /// Gets the commits since the last version tag
  Future<List<Commit>> _getCommitsSinceLastVersion() async {
    try {
      logger.detail("Getting commits since last version");
      // Get all tags sorted by creation date (newest first)
      final tagsResult = await Process.run(
        'git',
        ['tag', '--sort=-creatordate'],
        workingDirectory: projectRoot.path,
      );

      final commits = <Commit>[];
      if (tagsResult.exitCode == 0) {
        final tags = tagsResult.stdout.toString().trim().split('\n').where((tag) => tag.isNotEmpty).toList();

        String? previousTag;
        if (tags.length > 1) {
          // Get the second tag (previous version)
          previousTag = tags[1];
        }

        // Get commits since the previous tag (or all commits if no previous tag)
        final gitArgs = ['--no-pager', 'log', '--no-decorate'];
        if (previousTag != null) {
          gitArgs.add('$previousTag..HEAD');
        }

        final commitResult = await Process.run(
          'git',
          gitArgs,
          workingDirectory: projectRoot.path,
        );

        if (commitResult.exitCode == 0) {
          commits.addAll(_parseCommitLog(commitResult.stdout.toString().trim()));
        }
      } else {
        logger.detail(
          "No tags exist, this is treated as first release. "
          "Changelog will contain all commits.",
        );
        // If no tags exist, get all commits
        final commitResult = await Process.run(
          'git',
          ['--no-pager', 'log', '--no-decorate'],
          workingDirectory: projectRoot.path,
        );
        if (commitResult.exitCode == 0) {
          commits.addAll(_parseCommitLog(commitResult.stdout.toString().trim()));
        }
      }

      return commits;
    } catch (e) {
      logger.err('Error retrieving commits: $e');
      return [];
    }
  }

  /// Parses the git log output into CommitInfo objects
  List<Commit> _parseCommitLog(String log) {
    return Commit.parseCommits(log);
  }

  /// These are the commit types that should trigger a release.
  final releasableCommitTypes = <String>{'feat', 'fix', 'perf'};

  /// Checks whether a list of commits has commits that can be released.
  bool _hasReleasableCommits(List<Commit> commits) {
    return commits.any((commit) => releasableCommitTypes.contains(commit.type));
  }

  /// Generates a changelog entry, including the version from pubspec.yaml
  /// and the formatted API changes
  Future<String> generateChangelogEntry() async {
    final pubspecInfo = await _getPubspecInfo();
    final version = pubspecInfo['version']!;
    final homepage = pubspecInfo['homepage'];

    var effectiveBaseUrl = fileBaseUrl;
    if (effectiveBaseUrl == null && homepage != null) {
      var url = homepage;
      if (url.endsWith('/')) {
        url = url.substring(0, url.length - 1);
      }
      effectiveBaseUrl = '$url/blob/v$version';
    }

    final apiChangesFormatter = ApiChangeFormatter(
      apiChanges,
      markdownHeaderLevel: 4,
      fileBaseUrl: effectiveBaseUrl,
    );
    final formattedChanges = apiChangesFormatter.format();
    final commits = await _getCommitsSinceLastVersion();

    logger.detail("Commits since last version: ${commits.length}");

    final buffer = StringBuffer();
    final time = DateTime.now();

    buffer.writeln('## $version');
    buffer.writeln(
      'Released on: ${time.month}/${time.day}/${time.year}, changelog automatically generated.',
    );

    if (_hasReleasableCommits(commits)) {
      logger.detail("Has releasable commits, generating changelog summary");
      final summary = await changelogSummary(commits: commits, version: version);
      if (summary is ChangeSummary) {
        buffer.writeln('\n');
        buffer.writeln(_filterSectionsFromMarkdown(summary.toMarkdown()));
      }
    }

    if (formattedChanges.isNotEmpty) {
      buffer.writeln('\n### API Changes');
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

  /// Retrieves the package version and homepage from pubspec.yaml
  Future<Map<String, String?>> _getPubspecInfo() async {
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

      final homepage = pubspec['homepage']?.toString() ?? pubspec['repository']?.toString();

      return {
        'version': version.toString(),
        'homepage': homepage,
      };
    } catch (e) {
      logger.err('Error retrieving package info: $e');
      rethrow;
    }
  }

  String _filterSectionsFromMarkdown(
    String markdown, {
    List<String> sections = const ["Features", "Bug Fixes"],
    int headerLevel = 3,
  }) {
    final sectionHeader = '${'#' * headerLevel} ';
    final filteredLines = <String>[];

    bool inSection = false;
    for (final line in markdown.split('\n')) {
      if (line.trim().isEmpty) {
        continue;
      }

      if (line.startsWith("#")) {
        for (String section in sections) {
          if (line.endsWith(section)) {
            filteredLines.add('$sectionHeader$section');
            filteredLines.add(''); // Add a blank line after the header
            inSection = true;
            continue;
          }
        }
      } else if (line.startsWith("- ")) {
        if (inSection) {
          filteredLines.add(line);
        }
      } else {
        inSection = false;
      }
    }

    return filteredLines.join('\n');
  }
}
