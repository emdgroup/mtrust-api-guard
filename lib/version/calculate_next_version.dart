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
  String preReleasePrefix,
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
    case ApiChangeMagnitude.ignore:
      logger.info('No version increment for ignore magnitude');
      break;
  }

  final newVersion = version.toString();

  logger.info('New version: $newVersion');

  if (isPreRelease) {
    final normalizedPrefix = preReleasePrefix.trim();
    final separator = normalizedPrefix.isEmpty || normalizedPrefix.endsWith('.') ? '' : '.';
    String buildPreReleaseSuffix(int number) {
      if (normalizedPrefix.isEmpty) {
        return '$number';
      }
      return '$normalizedPrefix$separator$number';
    }

    var preReleaseNum = 1;
    while (await GitUtils.gitTagExists('$tagPrefix$newVersion-${buildPreReleaseSuffix(preReleaseNum)}', gitRoot.path)) {
      preReleaseNum++;
    }
    final preReleaseVersion = '$newVersion-${buildPreReleaseSuffix(preReleaseNum)}';
    logger.info('Pre-release version: $preReleaseVersion');
    return preReleaseVersion;
  } else if (await GitUtils.gitTagExists('$tagPrefix$newVersion', gitRoot.path)) {
    logger.err('Version tag $tagPrefix$newVersion already exists');
    throw Exception('Version tag $tagPrefix$newVersion already exists');
  }

  return newVersion;
}
