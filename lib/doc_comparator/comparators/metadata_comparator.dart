import 'package:mtrust_api_guard/mtrust_api_guard.dart';
import 'comparator_helpers.dart';

extension MetadataComparator on PackageMetadata {
  List<ApiChange> compareTo(PackageMetadata newMeta) {
    final changes = <ApiChange>[];

    // Compare dependencies
    compareLists<PackageDependency>(
      oldList: dependencies,
      newList: newMeta.dependencies,
      keyExtractor: (d) => d.packageName,
      onRemoved: (d) => changes.add(MetaApiChange.dependencyRemoved(dependencyName: d.packageName)),
      onAdded: (d) => changes.add(MetaApiChange.dependencyAdded(
        dependencyName: d.packageName,
        version: d.packageVersion,
      )),
      onMatched: (oldD, newD) {
        if (oldD.packageVersion != newD.packageVersion) {
          changes.add(MetaApiChange.dependencyVersionChange(
            dependencyName: oldD.packageName,
            version: newD.packageVersion,
            previousVersion: oldD.packageVersion,
          ));
        }
      },
    );

    // Compare SDK constraints
    compareVersionConstraints(
      oldVersion: sdkVersion,
      newVersion: newMeta.sdkVersion,
      callbacks: VersionConstraintCallbacks(
        onMinIncrease: (version, previousVersion) =>
            MetaApiChange.minDartSdkVersionIncrease(version: version, previousVersion: previousVersion),
        onMinDecrease: (version, previousVersion) =>
            MetaApiChange.minDartSdkVersionDecrease(version: version, previousVersion: previousVersion),
        onMaxIncrease: (version, previousVersion) =>
            MetaApiChange.maxDartSdkVersionIncrease(version: version, previousVersion: previousVersion),
        onMaxDecrease: (version, previousVersion) =>
            MetaApiChange.maxDartSdkVersionDecrease(version: version, previousVersion: previousVersion),
      ),
      changes: changes,
    );

    // Compare Flutter SDK constraints
    compareVersionConstraints(
      oldVersion: flutterVersion,
      newVersion: newMeta.flutterVersion,
      callbacks: VersionConstraintCallbacks(
        onMinIncrease: (version, previousVersion) =>
            MetaApiChange.minFlutterSdkVersionIncrease(version: version, previousVersion: previousVersion),
        onMinDecrease: (version, previousVersion) =>
            MetaApiChange.minFlutterSdkVersionDecrease(version: version, previousVersion: previousVersion),
        onMaxIncrease: (version, previousVersion) =>
            MetaApiChange.maxFlutterSdkVersionIncrease(version: version, previousVersion: previousVersion),
        onMaxDecrease: (version, previousVersion) =>
            MetaApiChange.maxFlutterSdkVersionDecrease(version: version, previousVersion: previousVersion),
      ),
      changes: changes,
    );

    // Compare Android constraints
    if (androidConstraints != null || newMeta.androidConstraints != null) {
      final baseMin = androidConstraints?.minSdkVersion;
      final newMin = newMeta.androidConstraints?.minSdkVersion;
      if (baseMin != newMin) {
        if (baseMin == null && newMin != null) {
          // No previous constraint, now there is one
          changes.add(MetaApiChange.minAndroidSdkVersionIncrease(
            version: newMin,
            previousVersion: 0,
          ));
        } else if (baseMin != null && newMin == null) {
          // Had a constraint, now removed
          changes.add(MetaApiChange.minAndroidSdkVersionDecrease(
            version: 0,
            previousVersion: baseMin,
          ));
        } else if (baseMin != null && newMin != null) {
          // Compare versions
          if (newMin > baseMin) {
            changes.add(MetaApiChange.minAndroidSdkVersionIncrease(
              version: newMin,
              previousVersion: baseMin,
            ));
          } else if (newMin < baseMin) {
            changes.add(MetaApiChange.minAndroidSdkVersionDecrease(
              version: newMin,
              previousVersion: baseMin,
            ));
          }
        }
      }
      // Add other android constraints checks if needed
    }

    // Compare iOS constraints
    if (iosConstraints != null || newMeta.iosConstraints != null) {
      final baseMin = iosConstraints?.minimumOsVersion;
      final newMin = newMeta.iosConstraints?.minimumOsVersion;
      if (baseMin != newMin) {
        if (baseMin == null && newMin != null) {
          // No previous constraint, now there is one
          changes.add(MetaApiChange.minIosSdkVersionIncrease(
            version: newMin,
            previousVersion: 0,
          ));
        } else if (baseMin != null && newMin == null) {
          // Had a constraint, now removed
          changes.add(MetaApiChange.minIosSdkVersionDecrease(
            version: 0,
            previousVersion: baseMin,
          ));
        } else if (baseMin != null && newMin != null) {
          // Compare versions
          if (newMin > baseMin) {
            changes.add(MetaApiChange.minIosSdkVersionIncrease(
              version: newMin,
              previousVersion: baseMin,
            ));
          } else if (newMin < baseMin) {
            changes.add(MetaApiChange.minIosSdkVersionDecrease(
              version: newMin,
              previousVersion: baseMin,
            ));
          }
        }
      }
    }

    return changes;
  }
}
