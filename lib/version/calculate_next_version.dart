import 'dart:io';

import 'package:mtrust_api_guard/doc_comparator/api_change.dart';
import 'package:mtrust_api_guard/doc_generator/git_utils.dart';
import 'package:mtrust_api_guard/logger.dart';
import 'package:pub_semver/pub_semver.dart';

Version stableVersion(Version version) => Version(version.major, version.minor, version.patch);

Version targetStableForPreRelease(Version original, ApiChangeMagnitude magnitude) {
  final stable = stableVersion(original);
  if (original.isPreRelease && magnitude == ApiChangeMagnitude.patch) {
    return stable;
  }
  return bumpStable(stable, magnitude);
}

Version bumpStable(Version stable, ApiChangeMagnitude magnitude) {
  switch (magnitude) {
    case ApiChangeMagnitude.major:
      return stable.nextMajor;
    case ApiChangeMagnitude.minor:
      return stable.nextMinor;
    case ApiChangeMagnitude.patch:
      return stable.nextPatch;
    case ApiChangeMagnitude.ignore:
      return stable;
  }
}

Version incrementPreRelease(Version version) {
  final parts = List<Object>.from(version.preRelease);
  final last = parts.last;
  final incremented = last is int ? last + 1 : int.parse(last.toString()) + 1;
  parts[parts.length - 1] = incremented;
  final pre = parts.map((part) => part.toString()).join('.');
  return Version(version.major, version.minor, version.patch, pre: pre);
}

Version initialPreRelease(Version stable, Version? template, String preReleasePrefix) {
  if (template != null && template.isPreRelease) {
    final parts = List<Object>.from(template.preRelease);
    if (parts.length == 1 && parts[0] is int) {
      return Version(stable.major, stable.minor, stable.patch, pre: '1');
    }
    final newParts = List<Object>.from(parts);
    newParts[newParts.length - 1] = 1;
    final pre = newParts.map((part) => part.toString()).join('.');
    return Version(stable.major, stable.minor, stable.patch, pre: pre);
  }

  final normalizedPrefix = preReleasePrefix.trim();
  final separator = normalizedPrefix.isEmpty || normalizedPrefix.endsWith('.') ? '' : '.';
  final pre = normalizedPrefix.isEmpty ? '1' : '$normalizedPrefix${separator}1';
  return Version(stable.major, stable.minor, stable.patch, pre: pre);
}

Version applyMagnitudeBump(Version version, ApiChangeMagnitude magnitude) {
  switch (magnitude) {
    case ApiChangeMagnitude.major:
      logger.info('Incrementing major version');
      return version.nextMajor;
    case ApiChangeMagnitude.minor:
      logger.info('Incrementing minor version');
      return version.nextMinor;
    case ApiChangeMagnitude.patch:
      logger.info('Incrementing patch version');
      return version.nextPatch;
    case ApiChangeMagnitude.ignore:
      logger.info('No version increment for ignore magnitude');
      return version;
  }
}

Future<String> calculateNextVersion(
  Version version,
  ApiChangeMagnitude highestMagnitudeChange,
  bool isPreRelease,
  Directory gitRoot,
  String tagPrefix,
  String preReleasePrefix,
) async {
  logger.info('Current version: $version');
  final originalVersion = version;

  if (isPreRelease) {
    if (highestMagnitudeChange == ApiChangeMagnitude.ignore) {
      return originalVersion.toString();
    }

    final originalStable = stableVersion(originalVersion);
    final bumpedStable = targetStableForPreRelease(originalVersion, highestMagnitudeChange);

    logger.info('New version: $bumpedStable');

    if (originalVersion.isPreRelease && bumpedStable == originalStable) {
      final next = incrementPreRelease(originalVersion);
      logger.info('Pre-release version: $next');
      return next.toString();
    }

    var candidate = initialPreRelease(
      bumpedStable,
      originalVersion.isPreRelease ? originalVersion : null,
      preReleasePrefix,
    );
    while (await GitUtils.gitTagExists('$tagPrefix$candidate', gitRoot.path)) {
      candidate = incrementPreRelease(candidate);
    }
    logger.info('Pre-release version: $candidate');
    return candidate.toString();
  }

  final newVersion = applyMagnitudeBump(version, highestMagnitudeChange).toString();

  logger.info('New version: $newVersion');

  if (await GitUtils.gitTagExists('$tagPrefix$newVersion', gitRoot.path)) {
    logger.err('Version tag $tagPrefix$newVersion already exists');
    throw Exception('Version tag $tagPrefix$newVersion already exists');
  }

  return newVersion;
}
