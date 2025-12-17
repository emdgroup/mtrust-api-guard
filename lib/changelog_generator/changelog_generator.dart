import 'dart:io';

import 'package:conventional/conventional.dart';
import 'package:mtrust_api_guard/doc_comparator/api_change.dart';
import 'package:mtrust_api_guard/doc_comparator/api_change_formatter.dart';
import 'package:mtrust_api_guard/doc_generator/git_utils.dart';
import 'package:mtrust_api_guard/logger.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

/// Generates a changelog entry based on the API changes and the current version from pubspec.yaml
class ChangelogGenerator {
  final List<ApiChange> apiChanges;
  final Directory projectRoot;

  /// The git reference of the previous version (e.g. v1.0.0).
  /// Used for generating comparison URLs.
  final String? baseRef;

  /// The git reference of the new version (e.g. v1.1.0 or a commit hash).
  /// Used for generating comparison URLs.
  final String? newRef;

  ChangelogGenerator({
    required this.apiChanges,
    required this.projectRoot,
    this.baseRef,
    this.newRef,
  });

  /// Gets the commits since the last version tag
  /// If the latest tag matches the current version (e.g. CI running on tagged commit),
  /// it gets the commits since the previous tag.
  /// If they do not match (e.g. preparing for a new release), it gets commits since the latest tag.
  Future<List<Commit>> _getCommitsSinceLastVersion() async {
    logger.detail("Getting commits since last version");

    final pubspecInfo = await _getPubspecInfo();
    final currentVersion = pubspecInfo['version']!;

    return GitUtils.getCommitsSinceLastTag(projectRoot.path, currentVersion);
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

    final remoteUrl = await GitUtils.getRemoteUrl(projectRoot.path);

    String? fileUrlBuilder(String filePath) {
      return GitUtils.buildCompareUrl(remoteUrl, baseRef, newRef, filePath);
    }

    final apiChangesFormatter = ApiChangeFormatter(
      apiChanges,
      markdownHeaderLevel: 4,
      fileUrlBuilder: fileUrlBuilder,
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
