import 'dart:io';

import 'package:mtrust_api_guard/doc_comparator/api_change.dart';
import 'package:mtrust_api_guard/doc_generator/git_utils.dart';
import 'package:mtrust_api_guard/logger.dart';
import 'package:pub_semver/pub_semver.dart';

Future<String> calculateNextVersion(
  Version version,
  ApiChangeMagnitude highestMagnitudeChange,
  bool isPreRelease,
  Directory gitRoot,
  String tagPrefix,
) async {
  logger.info('Current version: $version');

  switch (highestMagnitudeChange) {
    case ApiChangeMagnitude.major:
      logger.info('Incrementing major version');
      version = version.nextMajor;
      break;
    case ApiChangeMagnitude.minor:
      logger.info('Incrementing minor version');
      version = version.nextMinor;
      break;
    case ApiChangeMagnitude.patch:
      logger.info('Incrementing patch version');
      version = version.nextPatch;
      break;
  }

  final newVersion = version.toString();

  logger.info('New version: $newVersion');

  if (isPreRelease) {
    var preReleaseNum = 1;
    while (await GitUtils.gitTagExists('$tagPrefix$newVersion-dev.$preReleaseNum', gitRoot.path)) {
      preReleaseNum++;
    }
    logger.info('Pre-release version: $newVersion-dev.$preReleaseNum');
    return '$newVersion-dev.$preReleaseNum';
  } else if (await GitUtils.gitTagExists('$tagPrefix$newVersion', gitRoot.path)) {
    logger.err('Version $newVersion already exists as a git tag');
    throw Exception('Version $newVersion already exists as a git tag');
  }

  return newVersion;
}
