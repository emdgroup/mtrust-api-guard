import 'dart:io';

import 'package:mtrust_api_guard/changelog_generator/changelog_generator.dart';
import 'package:mtrust_api_guard/doc_comparator/api_change.dart';
import 'package:mtrust_api_guard/doc_comparator/doc_comparator.dart';
import 'package:mtrust_api_guard/doc_generator/git_utils.dart';
import 'package:mtrust_api_guard/logger.dart';
import 'package:mtrust_api_guard/pubspec_utils.dart';
import 'package:mtrust_api_guard/version/calculate_next_version.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';

Future<Version> version({
  required Directory gitRoot,
  required Directory dartRoot,
  String? baseRef,
  required bool tag,
  String? newRef,
  required bool isPreRelease,
  required bool commit,
  required bool generateChangelog,
  required bool cache,
}) async {
  final hasPreviousVersion = (await GitUtils.getVersions(gitRoot.path)).isNotEmpty;

  if (baseRef == null && !hasPreviousVersion) {
    logger.err('No previous version found. Please tag the first version. e.g. git tag v0.0.1');
    exit(1);
  }

  final effectiveBaseRef = baseRef ?? await GitUtils.getPreviousRef(gitRoot.path);

  final changes = await compare(
    magnitudes: {ApiChangeMagnitude.major, ApiChangeMagnitude.minor, ApiChangeMagnitude.patch},
    baseRef: effectiveBaseRef,
    newRef: "HEAD",
    dartRoot: dartRoot,
    gitRoot: gitRoot,
    cache: cache,
  );

  final basePubSpec = await GitUtils.gitShow(
    baseRef ?? await GitUtils.getPreviousRef(gitRoot.path),
    gitRoot.path,
    'pubspec.yaml',
  );

  final baseVersion = PubspecUtils.getVersion(basePubSpec);

  final highestMagnitudeChange = getHighestMagnitude(changes);

  logger.info('Highest magnitude change: $highestMagnitudeChange');

  final nextVersion = await calculateNextVersion(baseVersion, highestMagnitudeChange, isPreRelease, gitRoot);

  logger.info('Next version: $nextVersion');

  await PubspecUtils.setVersion(File(join(dartRoot.path, 'pubspec.yaml')), Version.parse(nextVersion));

  if (generateChangelog) {
    await ChangelogGenerator(apiChanges: changes, projectRoot: dartRoot).updateChangelogFile();
  }

  if (commit) {
    await GitUtils.commitVersion(nextVersion, gitRoot.path);
  }

  if (tag) {
    await GitUtils.gitTag("v$nextVersion", gitRoot.path);
  }

  return Version.parse(nextVersion);
}
