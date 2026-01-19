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
    if (sdkVersion != newMeta.sdkVersion) {
      changes.add(ComponentApiChange(
        component: DocComponent.meta(
          name: 'sdk',
          description: 'Dart SDK Constraint',
          filePath: 'pubspec.yaml',
        ),
        operation: ApiChangeOperation.platformConstraintChange,
        changedValue: 'SDK constraint changed from `$sdkVersion` to `${newMeta.sdkVersion}`',
      ));
    }

    // Compare Android constraints
    if (androidConstraints != null || newMeta.androidConstraints != null) {
      final baseMin = androidConstraints?.minSdkVersion;
      final newMin = newMeta.androidConstraints?.minSdkVersion;
      if (baseMin != newMin) {
        changes.add(ComponentApiChange(
          component: DocComponent.meta(
            name: 'android:minSdkVersion',
            description: 'Android minSdkVersion',
            filePath: 'android/app/build.gradle',
          ),
          operation: ApiChangeOperation.platformConstraintChange,
          changedValue: 'Android minSdkVersion changed from `$baseMin` to `$newMin`',
        ));
      }
      // Add other android constraints checks if needed
    }

    // Compare iOS constraints
    if (iosConstraints != null || newMeta.iosConstraints != null) {
      final baseMin = iosConstraints?.minimumOsVersion;
      final newMin = newMeta.iosConstraints?.minimumOsVersion;
      if (baseMin != newMin) {
        changes.add(ComponentApiChange(
          component: DocComponent.meta(
            name: 'ios:minimumOsVersion',
            description: 'iOS minimumOsVersion',
            filePath: 'ios/Runner.xcodeproj/project.pbxproj',
          ),
          operation: ApiChangeOperation.platformConstraintChange,
          changedValue: 'iOS minimumOsVersion changed from `$baseMin` to `$newMin`',
        ));
      }
    }

    return changes;
  }
}
