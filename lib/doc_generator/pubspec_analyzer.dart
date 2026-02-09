import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:mtrust_api_guard/models/package_info.dart';

class PubspecAnalyzer {
  final String packagePath;

  PubspecAnalyzer(this.packagePath);

  Future<PackageMetadata> analyze() async {
    final pubspecFile = File(path.join(packagePath, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      throw Exception('pubspec.yaml not found at ${pubspecFile.path}');
    }

    final pubspecContent = await pubspecFile.readAsString();
    final pubspecYaml = loadYaml(pubspecContent);

    final packageName = pubspecYaml['name'] as String?;
    final packageVersion = pubspecYaml['version'] as String?;
    final sdkVersion = _getSdkVersion(pubspecYaml);
    final dependencies = _getDependencies(pubspecYaml);

    final androidConstraints = await _getAndroidConstraints();
    final iosConstraints = await _getIOSConstraints();

    return PackageMetadata(
      packageName: packageName,
      packageVersion: packageVersion,
      sdkVersion: sdkVersion,
      dependencies: dependencies,
      androidConstraints: androidConstraints,
      iosConstraints: iosConstraints,
    );
  }

  String? _getSdkVersion(dynamic pubspecYaml) {
    final environment = pubspecYaml['environment'];
    if (environment is Map) {
      return environment['sdk']?.toString();
    }
    return null;
  }

  List<PackageDependency> _getDependencies(dynamic pubspecYaml) {
    final dependencies = <PackageDependency>[];
    final depsMap = pubspecYaml['dependencies'];
    if (depsMap is Map) {
      depsMap.forEach((key, value) {
        String? version;
        if (value is String) {
          version = value;
        } else if (value is Map && value.containsKey('version')) {
          version = value['version']?.toString();
        }
        // Ignore path/git dependencies for version tracking if needed,
        // or include them with null version.
        // dart_apitool includes hosted, path, and git.
        dependencies.add(PackageDependency(
          packageName: key.toString(),
          packageVersion: version,
        ));
      });
    }
    return dependencies;
  }

  Future<AndroidPlatformConstraints?> _getAndroidConstraints() async {
    final androidDir = Directory(path.join(packagePath, 'android'));
    if (!await androidDir.exists()) return null;

    final gradleFiles =
        await androidDir.list(recursive: true).where((file) => path.extension(file.path) == '.gradle').toList();

    AndroidPlatformConstraints? constraints;

    for (final file in gradleFiles) {
      if (file is File) {
        final content = await file.readAsString();
        final fileConstraints = _parseGradleFile(content);
        if (fileConstraints != null) {
          constraints = _mergeAndroidConstraints(constraints, fileConstraints);
        }
      }
    }
    return constraints;
  }

  AndroidPlatformConstraints? _parseGradleFile(String content) {
    final minSdkVersionMatches = RegExp(r'minSdkVersion (\d+)').allMatches(content);
    final targetSdkVersionMatches = RegExp(r'targetSdkVersion (\d+)').allMatches(content);
    final compileSdkVersionMatches = RegExp(r'compileSdkVersion (\d+)').allMatches(content);

    int? getMax(Iterable<RegExpMatch> matches) {
      int? maxVal;
      for (final m in matches) {
        final val = int.tryParse(m.group(1)!);
        if (val != null) {
          if (maxVal == null || val > maxVal) maxVal = val;
        }
      }
      return maxVal;
    }

    final minSdk = getMax(minSdkVersionMatches);
    final targetSdk = getMax(targetSdkVersionMatches);
    final compileSdk = getMax(compileSdkVersionMatches);

    if (minSdk != null || targetSdk != null || compileSdk != null) {
      return AndroidPlatformConstraints(
        minSdkVersion: minSdk,
        targetSdkVersion: targetSdk,
        compileSdkVersion: compileSdk,
      );
    }
    return null;
  }

  AndroidPlatformConstraints _mergeAndroidConstraints(AndroidPlatformConstraints? a, AndroidPlatformConstraints b) {
    if (a == null) return b;
    return AndroidPlatformConstraints(
      minSdkVersion: (a.minSdkVersion ?? 0) > (b.minSdkVersion ?? 0) ? a.minSdkVersion : b.minSdkVersion,
      compileSdkVersion:
          (a.compileSdkVersion ?? 0) > (b.compileSdkVersion ?? 0) ? a.compileSdkVersion : b.compileSdkVersion,
      targetSdkVersion: (a.targetSdkVersion ?? 0) > (b.targetSdkVersion ?? 0) ? a.targetSdkVersion : b.targetSdkVersion,
    );
  }

  Future<IOSPlatformConstraints?> _getIOSConstraints() async {
    final iosDir = Directory(path.join(packagePath, 'ios'));
    if (!await iosDir.exists()) return null;

    IOSPlatformConstraints? constraints;

    // Check Info.plist files
    final plistFiles =
        await iosDir.list(recursive: true).where((file) => path.extension(file.path) == '.plist').toList();

    for (final file in plistFiles) {
      if (file is File) {
        final content = await file.readAsString();
        final minVersion = _parsePlistFile(content);
        if (minVersion != null) {
          if (constraints == null || (constraints.minimumOsVersion ?? 0) < minVersion) {
            constraints = IOSPlatformConstraints(minimumOsVersion: minVersion);
          }
        }
      }
    }

    // Check Podspec files
    final podspecFiles =
        await iosDir.list(recursive: true).where((file) => path.extension(file.path) == '.podspec').toList();

    for (final file in podspecFiles) {
      if (file is File) {
        final content = await file.readAsString();
        final minVersion = _parsePodspecFile(content);
        if (minVersion != null) {
          if (constraints == null || (constraints.minimumOsVersion ?? 0) < minVersion) {
            constraints = IOSPlatformConstraints(minimumOsVersion: minVersion);
          }
        }
      }
    }

    return constraints;
  }

  num? _parsePlistFile(String content) {
    // Simple regex for <key>MinimumOSVersion</key> followed by <string>...</string>
    // This is brittle but avoids adding xml/plist parser deps.
    final regex = RegExp(r'<key>MinimumOSVersion</key>\s*<string>([\d\.]+)</string>');
    final match = regex.firstMatch(content);
    if (match != null) {
      return num.tryParse(match.group(1)!);
    }
    return null;
  }

  num? _parsePodspecFile(String content) {
    final regex = RegExp(r"platform\s*=\s*:ios\s*,\s*'(?<num>[0-9.]+)'");
    final match = regex.firstMatch(content);
    if (match != null) {
      return num.tryParse(match.namedGroup('num')!);
    }
    return null;
  }
}
