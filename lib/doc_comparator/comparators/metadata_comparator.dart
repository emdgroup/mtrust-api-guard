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
      onRemoved: (d) => changes.add(ComponentApiChange(
        component: DocComponent.metadata(
          name: d.packageName,
          type: DocComponentType.dependencyType,
          description: 'Dependency',
          filePath: 'pubspec.yaml',
        ),
        operation: ApiChangeOperation.dependencyRemoved,
        changedValue: 'Dependency `${d.packageName}` removed',
      )),
      onAdded: (d) => changes.add(ComponentApiChange(
        component: DocComponent.metadata(
          name: d.packageName,
          type: DocComponentType.dependencyType,
          description: 'Dependency',
          filePath: 'pubspec.yaml',
        ),
        operation: ApiChangeOperation.dependencyAdded,
        changedValue: 'Dependency `${d.packageName}` added',
      )),
      onMatched: (oldD, newD) {
        if (oldD.packageVersion != newD.packageVersion) {
          changes.add(ComponentApiChange(
            component: DocComponent.metadata(
              name: oldD.packageName,
              type: DocComponentType.dependencyType,
              description: 'Dependency',
              filePath: 'pubspec.yaml',
            ),
            operation: ApiChangeOperation.dependencyChanged,
            changedValue:
                'Dependency `${oldD.packageName}` changed from `${oldD.packageVersion}` to `${newD.packageVersion}`',
          ));
        }
      },
    );

    // Compare SDK constraints
    if (sdkVersion != newMeta.sdkVersion) {
      changes.add(ComponentApiChange(
        component: DocComponent.metadata(
          name: 'sdk',
          type: DocComponentType.platformConstraintType,
          description: 'Dart SDK Constraint',
          filePath: 'pubspec.yaml',
        ),
        operation: ApiChangeOperation.platformConstraintChanged,
        changedValue: 'SDK constraint changed from `$sdkVersion` to `${newMeta.sdkVersion}`',
      ));
    }

    // Compare Android constraints
    if (androidConstraints != null || newMeta.androidConstraints != null) {
      final baseMin = androidConstraints?.minSdkVersion;
      final newMin = newMeta.androidConstraints?.minSdkVersion;
      if (baseMin != newMin) {
        changes.add(ComponentApiChange(
          component: DocComponent.metadata(
            name: 'android:minSdkVersion',
            type: DocComponentType.platformConstraintType,
            description: 'Android minSdkVersion',
            filePath: 'android/app/build.gradle',
          ),
          operation: ApiChangeOperation.platformConstraintChanged,
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
          component: DocComponent.metadata(
            name: 'ios:minimumOsVersion',
            type: DocComponentType.platformConstraintType,
            description: 'iOS minimumOsVersion',
            filePath: 'ios/Runner.xcodeproj/project.pbxproj',
          ),
          operation: ApiChangeOperation.platformConstraintChanged,
          changedValue: 'iOS minimumOsVersion changed from `$baseMin` to `$newMin`',
        ));
      }
    }

    return changes;
  }
}
