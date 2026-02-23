import 'dart:io';

import 'package:mtrust_api_guard/badges/badge_generator.dart';
import 'package:mtrust_api_guard/changelog_generator/changelog_generator.dart';
import 'package:mtrust_api_guard/config/config.dart';
import 'package:mtrust_api_guard/doc_comparator/api_change.dart';
import 'package:mtrust_api_guard/doc_comparator/apply_overrides.dart';
import 'package:mtrust_api_guard/doc_comparator/doc_comparator.dart';
import 'package:mtrust_api_guard/doc_generator/git_utils.dart';
import 'package:mtrust_api_guard/logger.dart';
import 'package:mtrust_api_guard/pubspec_utils.dart';
import 'package:mtrust_api_guard/version/calculate_next_version.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:recase/recase.dart';

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
  required String preReleasePrefix,
  required bool commit,
  required bool badge,
  required bool generateChangelog,
  required bool cache,
  required String tagPrefix,
  String? dartFile,
  String? packageName,
}) async {
  // For workspace packages, use package-specific tag methods
  final hasPreviousVersion = packageName != null
      ? (await GitUtils.getVersionsForPackage(gitRoot.path, packageName, tagPrefix: 'v')).isNotEmpty
      : (await GitUtils.getVersions(gitRoot.path, tagPrefix: tagPrefix)).isNotEmpty;

  if (baseRef == null && !hasPreviousVersion) {
    final exampleTag = packageName != null ? '$packageName/v0.0.1' : '${tagPrefix}0.0.1';
    logger.err('No previous version found. Please tag the first version. e.g. git tag $exampleTag');
    exit(1);
  }

  final effectiveBaseRef = baseRef ??
      (packageName != null
          ? await GitUtils.getPreviousRefForPackage(gitRoot.path, packageName, tagPrefix: 'v') ??
              (throw Exception('No previous version found for package $packageName'))
          : await GitUtils.getPreviousRef(gitRoot.path, tagPrefix: tagPrefix));

  final changes = await compare(
    baseRef: effectiveBaseRef,
    newRef: "HEAD",
    dartRoot: dartRoot,
    gitRoot: gitRoot,
    cache: cache,
  );

  final pubspecPath =
      packageName != null ? join(relative(dartRoot.path, from: gitRoot.path), 'pubspec.yaml') : 'pubspec.yaml';

  // Load config and apply magnitude overrides
  final config = ApiGuardConfig.load(dartRoot);
  applyMagnitudeOverrides(changes, config);

  final basePubSpec = await GitUtils.gitShow(
    effectiveBaseRef,
    gitRoot.path,
    pubspecPath,
  );

  final baseVersion = PubspecUtils.getVersion(basePubSpec);

  logger.info('Base version: $baseVersion');
  logger.info('Changes: $changes');

  final highestMagnitudeChange = getHighestMagnitude(changes);

  logger.info('Highest magnitude change: $highestMagnitudeChange');

  // For workspace packages, extract the 'v' prefix from tagPrefix (which is like 'package/v')
  final versionTagPrefix = packageName != null ? 'v' : tagPrefix;
  final nextVersion = await calculateNextVersion(
    baseVersion,
    highestMagnitudeChange,
    isPreRelease,
    gitRoot,
    versionTagPrefix,
    preReleasePrefix,
  );

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
    badgeContent = await generateVersionBadge(nextVersion);
    await File(join(dartRoot.path, 'version_badge.svg')).writeAsString(badgeContent);
    logger.info('Generated version badge for version $nextVersion');
  }

  if (commit) {
    // For workspace packages, commit from the package directory
    // For single packages, commit from git root
    final commitRoot = packageName != null ? dartRoot.path : gitRoot.path;
    await GitUtils.commitVersion(
      nextVersion,
      commitRoot,
      commitBadge: badge,
      commitChangelog: generateChangelog,
    );
    logger.info('Committed version $nextVersion');
  }

  if (tag) {
    await GitUtils.gitTag("$tagPrefix$nextVersion", gitRoot.path);
    logger.info('Tagged version $tagPrefix$nextVersion');
  }

  if (dartFile != null) {
    final pubspecFile = File(join(dartRoot.path, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      throw Exception('pubspec.yaml not found at ${pubspecFile.path}');
    }
    final pubspecContent = await pubspecFile.readAsString();
    final safePackageName = packageName ?? PubspecUtils.getPackageName(pubspecContent);
    final camelCasePackageName = ReCase(safePackageName).camelCase;
    final constantName = '${camelCasePackageName}Version';

    final dartFileContent = "const String $constantName = '$nextVersion';\n";
    final dartOutputFile = File(dartFile);
    if (!dartOutputFile.existsSync()) {
      dartOutputFile.createSync(recursive: true);
    }
    await dartOutputFile.writeAsString(dartFileContent);
    logger.info('Generated Dart file with version constant at $dartFile');
  }

  return VersionResult(
    version: Version.parse(nextVersion),
    apiChanges: changes,
    changelog: changelog,
    badge: badgeContent ?? '',
  );
}
