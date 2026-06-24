import 'dart:io';

import 'package:conventional/conventional.dart';
import 'package:mtrust_api_guard/doc_comparator/api_change.dart';
import 'package:mtrust_api_guard/doc_comparator/api_change_formatter.dart';
import 'package:mtrust_api_guard/doc_comparator/doc_comparator.dart';
import 'package:mtrust_api_guard/doc_generator/git_utils.dart';
import 'package:mtrust_api_guard/logger.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
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

  ChangelogGenerator({required this.apiChanges, required this.projectRoot, this.baseRef, this.newRef});

  /// These are the commit types that should trigger a release.
  static const releasableCommitTypes = <String>{'feat', 'fix', 'perf'};

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

  /// Generates a changelog entry, including the version from pubspec.yaml
  /// and the formatted API changes
  Future<String> generateChangelogEntry() async {
    final pubspecInfo = await _getPubspecInfo();
    final version = pubspecInfo['version']!;
    final commits = await _getCommitsSinceLastVersion();

    logger.detail("Commits since last version: ${commits.length}");

    return _generateReleaseEntry(
      version: version,
      apiChanges: apiChanges,
      commits: commits,
      baseRef: baseRef,
      newRef: newRef,
    );
  }

  /// Regenerates the entire CHANGELOG.md by walking version tags and comparing each release.
  Future<String> regenerateFullChangelog({
    required Directory gitRoot,
    required bool cache,
    String tagPrefix = 'v',
    String? packageName,
  }) async {
    final tags = packageName != null
        ? await GitUtils.getVersionsForPackage(gitRoot.path, packageName, tagPrefix: tagPrefix)
        : await GitUtils.getVersions(gitRoot.path, tagPrefix: tagPrefix);

    if (tags.isEmpty) {
      throw Exception('No version tags found to regenerate changelog from');
    }

    final rootCommit = await GitUtils.getRootCommit(gitRoot.path);
    final releasePairs = <({String tag, Version version, String baseRef})>[];

    String? previousTag;
    for (final (tag, version) in tags) {
      final compareBase = previousTag ?? rootCommit;
      if (compareBase == null) {
        throw Exception('Could not determine base ref for first release $tag');
      }
      releasePairs.add((tag: tag, version: version, baseRef: compareBase));
      previousTag = tag;
    }

    final buffer = StringBuffer();
    final pubspecInfo = await _getPubspecInfo();
    final pubspecVersion = Version.parse(pubspecInfo['version']!);
    final latestTaggedVersion = tags.last.$2;

    if (pubspecVersion > latestTaggedVersion) {
      final latestTag = tags.last.$1;
      logger.info('Regenerating unreleased section ($latestTag..HEAD)');

      final unreleasedChanges = await compare(
        baseRef: latestTag,
        newRef: 'HEAD',
        dartRoot: projectRoot,
        gitRoot: gitRoot,
        cache: cache,
      );

      final unreleasedCommits = await GitUtils.getCommits(
        root: gitRoot.path,
        fromRef: latestTag,
        toRef: 'HEAD',
      );

      buffer.write(
        await _generateReleaseEntry(
          version: 'Unreleased',
          apiChanges: unreleasedChanges,
          commits: unreleasedCommits,
          baseRef: latestTag,
          newRef: 'HEAD',
        ),
      );
    }

    for (final release in releasePairs.reversed) {
      logger.info('Regenerating changelog for ${release.version} (${release.baseRef}..${release.tag})');

      final changes = await compare(
        baseRef: release.baseRef,
        newRef: release.tag,
        dartRoot: projectRoot,
        gitRoot: gitRoot,
        cache: cache,
      );

      final commits = await GitUtils.getCommits(
        root: gitRoot.path,
        fromRef: release.baseRef,
        toRef: release.tag,
      );

      final releasedAt = await GitUtils.getTagDate(release.tag, gitRoot.path);

      buffer.write(
        await _generateReleaseEntry(
          version: release.version.toString(),
          apiChanges: changes,
          commits: commits,
          baseRef: release.baseRef,
          newRef: release.tag,
          releasedAt: releasedAt,
        ),
      );
    }

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

    logger.info('${changelogFile.absolute.path} updated successfully.');
  }

  /// Overwrites CHANGELOG.md with a full regeneration from git tags.
  Future<void> regenerateChangelogFile({
    required Directory gitRoot,
    required bool cache,
    String tagPrefix = 'v',
    String? packageName,
  }) async {
    final changelogFile = File(join(projectRoot.path, 'CHANGELOG.md'));
    final content = await regenerateFullChangelog(
      gitRoot: gitRoot,
      cache: cache,
      tagPrefix: tagPrefix,
      packageName: packageName,
    );
    await changelogFile.writeAsString(content);
    logger.info('${changelogFile.absolute.path} regenerated successfully.');
  }

  Future<String> _generateReleaseEntry({
    required String version,
    required List<ApiChange> apiChanges,
    required List<Commit> commits,
    String? baseRef,
    String? newRef,
    DateTime? releasedAt,
  }) async {
    final remoteUrl = await GitUtils.getRemoteUrl(projectRoot.path);

    String? fileUrlBuilder(String filePath) {
      return GitUtils.buildCompareUrl(remoteUrl, baseRef, newRef, filePath);
    }

    final apiChangesFormatter = ApiChangeFormatter(apiChanges, markdownHeaderLevel: 4, fileUrlBuilder: fileUrlBuilder);
    final formattedChanges = apiChangesFormatter.format();

    final buffer = StringBuffer();
    final time = releasedAt ?? DateTime.now();

    buffer.writeln('## $version');
    if (version == 'Unreleased') {
      buffer.writeln();
    } else {
      buffer.writeln('Released on: ${time.month}/${time.day}/${time.year}, changelog automatically generated.');
    }

    if (_hasReleasableCommits(commits)) {
      logger.detail("Has releasable commits for $version, generating changelog summary");
      final summaryVersion = version == 'Unreleased' ? (await _getPubspecInfo())['version']! : version;
      final summary = await changelogSummary(commits: commits, version: summaryVersion);
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

  /// Checks whether a list of commits has commits that can be released.
  bool _hasReleasableCommits(List<Commit> commits) {
    return commits.any((commit) => releasableCommitTypes.contains(commit.type));
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

      return {'version': version.toString(), 'homepage': homepage};
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
