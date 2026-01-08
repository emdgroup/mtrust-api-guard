import 'dart:io';

import 'package:mtrust_api_guard/badges/badge_generator.dart';
import 'package:mtrust_api_guard/changelog_generator/changelog_generator.dart';
import 'package:mtrust_api_guard/doc_comparator/api_change.dart';
import 'package:mtrust_api_guard/doc_comparator/doc_comparator.dart';
import 'package:mtrust_api_guard/doc_generator/git_utils.dart';
import 'package:mtrust_api_guard/logger.dart';
import 'package:mtrust_api_guard/pubspec_utils.dart';
import 'package:mtrust_api_guard/version/calculate_next_version.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';

class VersionResult {
  final Version version;
  final List<ApiChange> apiChanges;
  final String? changelog;
  final String? badge;

  VersionResult({
    required this.version,
    required this.apiChanges,
    required this.changelog,
    required this.badge,
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version.toString(),
      'changelog': changelog,
      'badge': badge,
    };
  }
}

Future<VersionResult> version({
  required Directory gitRoot,
  required Directory dartRoot,
  String? baseRef,
  required bool tag,
  String? newRef,
  required bool isPreRelease,
  required bool commit,
  required bool badge,
  required bool generateChangelog,
  required bool cache,
  required String tagPrefix,
}) async {
  logger.success("Starting versioning...");
  logger.info("--------------------------------");
  logger.info('Git root:    ${gitRoot.path}');
  logger.info('Dart root:   ${dartRoot.path}');
  logger.info('Base ref:    ${baseRef ?? "Auto"}');
  logger.info('New ref:     $newRef');
  logger.info('Pre-release: $isPreRelease');
  logger.info('Commit:      $commit');
  logger.info('Badge:       $badge');
  logger.info('Changelog:   $generateChangelog');
  logger.info('Cache:       $cache');
  logger.info('Tag prefix:  $tagPrefix');
  logger.info("--------------------------------");

  String? effectiveBaseRef;

  if (baseRef != null) {
    effectiveBaseRef = baseRef;
  } else {
    logger.info("No base ref provided, finding previous version...");
    var versions = await GitUtils.getVersions(gitRoot.path, tagPrefix: tagPrefix);
    logger.info('Versions: ');
    for (var version in versions) {
      logger.info("\t- ${version.$1}");
    }

    // We need to filter out pre-releases if we are not running in pre-release mode to ensure, that we compare with the last stable version.
    if (!isPreRelease) {
      versions = versions.where((version) => !version.$2.isPreRelease).toList();
      logger.info("Filtered out pre-releases, remaining versions: ");
      for (var version in versions) {
        logger.info("\t- ${version.$1}");
      }
    }
    if (versions.isEmpty) {
      logger.err('No previous version found. Please tag the first version. e.g. git tag ${tagPrefix}0.0.1');
      exit(1);
    }
    effectiveBaseRef = versions.last.$1;
    logger.info("Previous version: $effectiveBaseRef");
  }

  final changes = await compare(
    baseRef: effectiveBaseRef,
    newRef: "HEAD",
    dartRoot: dartRoot,
    gitRoot: gitRoot,
    cache: cache,
  );

  final basePubSpec = await GitUtils.gitShow(
    effectiveBaseRef,
    gitRoot.path,
    dartRoot.path + '/pubspec.yaml',
  );

  final baseVersion = PubspecUtils.getVersion(basePubSpec);

  final highestMagnitudeChange = getHighestMagnitude(changes);

  logger.info('Highest magnitude change: $highestMagnitudeChange');

  final nextVersion = await calculateNextVersion(baseVersion, highestMagnitudeChange, isPreRelease, gitRoot, tagPrefix);

  logger.info('Next version: $nextVersion');

  await PubspecUtils.setVersion(File(join(dartRoot.path, 'pubspec.yaml')), Version.parse(nextVersion));

  String? changelog;
  String? badgeContent;
  if (generateChangelog) {
    String changelogNewRef;
    // If we are committing, we use the new version tag as the new ref.
    // If we are not committing (e.g. dry run / PR), we use the current commit hash
    // so the link points to the specific commit.
    if (commit) {
      changelogNewRef = "$tagPrefix$nextVersion";
    } else {
      changelogNewRef = await GitUtils.getCurrentCommitHash(gitRoot.path) ?? "HEAD";
    }

    final generator = ChangelogGenerator(
      apiChanges: changes,
      projectRoot: dartRoot,
      baseRef: effectiveBaseRef,
      newRef: changelogNewRef,
    );
    await generator.updateChangelogFile();
    changelog = await generator.generateChangelogEntry();
    logger.info('Generated changelog entry for version $nextVersion');
  }

  if (badge) {
    final badgeContent = await generateVersionBadge(nextVersion);
    await File(join(dartRoot.path, 'version_badge.svg')).writeAsString(badgeContent);
    logger.info('Generated version badge for version $nextVersion');
  }

  if (commit) {
    await GitUtils.commitVersion(
      nextVersion,
      gitRoot.path,
      commitBadge: badge,
      commitChangelog: generateChangelog,
    );
    logger.info('Committed version $nextVersion');
  }

  if (tag) {
    await GitUtils.gitTag("$tagPrefix$nextVersion", gitRoot.path);
    logger.info('Tagged version $tagPrefix$nextVersion');
  }

  return VersionResult(
    version: Version.parse(nextVersion),
    apiChanges: changes,
    changelog: changelog,
    badge: badgeContent ?? '',
  );
}
