import 'package:mtrust_api_guard/mtrust_api_guard.dart';

extension MetadataComparator on PackageMetadata {
  List<ApiChange> compareTo(PackageMetadata newMeta) {
    final changes = <ApiChange>[];

    // Compare dependencies
    final baseDeps = {for (var d in dependencies) d.packageName: d};
    final newDeps = {for (var d in newMeta.dependencies) d.packageName: d};

    for (final pkg in baseDeps.keys) {
      if (!newDeps.containsKey(pkg)) {
        changes.add(ComponentApiChange(
          component: DocComponent.metadata(
            name: pkg,
            type: DocComponentType.dependencyType,
            description: 'Dependency',
            filePath: 'pubspec.yaml',
          ),
          operation: ApiChangeOperation.dependencyRemoved,
          changedValue: 'Dependency $pkg removed',
        ));
      } else {
        final baseDep = baseDeps[pkg]!;
        final newDep = newDeps[pkg]!;
        if (baseDep.packageVersion != newDep.packageVersion) {
          changes.add(ComponentApiChange(
            component: DocComponent.metadata(
              name: pkg,
              type: DocComponentType.dependencyType,
              description: 'Dependency',
              filePath: 'pubspec.yaml',
            ),
            operation: ApiChangeOperation.dependencyChanged,
            changedValue: 'Dependency $pkg changed from ${baseDep.packageVersion} to ${newDep.packageVersion}',
          ));
        }
      }
    }

    for (final pkg in newDeps.keys) {
      if (!baseDeps.containsKey(pkg)) {
        changes.add(ComponentApiChange(
          component: DocComponent.metadata(
            name: pkg,
            type: DocComponentType.dependencyType,
            description: 'Dependency',
            filePath: 'pubspec.yaml',
          ),
          operation: ApiChangeOperation.dependencyAdded,
          changedValue: 'Dependency $pkg added',
        ));
      }
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
          changedValue: 'Android minSdkVersion changed from $baseMin to $newMin',
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
          changedValue: 'iOS minimumOsVersion changed from $baseMin to $newMin',
        ));
      }
    }

    return changes;
  }
}
