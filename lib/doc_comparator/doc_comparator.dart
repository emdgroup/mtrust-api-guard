// ignore_for_file: avoid_print

import 'dart:io';

import 'package:mtrust_api_guard/doc_comparator/doc_ext.dart';
import 'package:mtrust_api_guard/doc_comparator/get_ref.dart';

import 'package:mtrust_api_guard/mtrust_api_guard.dart';

Future<List<ApiChange>> compare({
  required String baseRef,
  required String newRef,
  required Directory dartRoot,
  required Directory gitRoot,
  required bool cache,
}) async {
  // Load config and determine doc file path

  final baseApi = await getRef(ref: baseRef, dartRoot: dartRoot, gitRoot: gitRoot, cache: cache);
  final newApi = await getRef(ref: newRef, dartRoot: dartRoot, gitRoot: gitRoot, cache: cache);

  final apiChanges = baseApi.components.compareTo(
    newApi.components,
  );

  apiChanges.addAll(_compareMetadata(baseApi.metadata, newApi.metadata));

  return apiChanges;
}

List<ApiChange> _compareMetadata(PackageMetadata base, PackageMetadata newMeta) {
  final changes = <ApiChange>[];

  // Compare dependencies
  final baseDeps = {for (var d in base.dependencies) d.packageName: d};
  final newDeps = {for (var d in newMeta.dependencies) d.packageName: d};

  for (final pkg in baseDeps.keys) {
    if (!newDeps.containsKey(pkg)) {
      changes.add(ComponentApiChange(
        component: DocComponent(
          name: pkg,
          type: DocComponentType.dependencyType,
          isNullSafe: true,
          description: 'Dependency',
          constructors: [],
          properties: [],
          methods: [],
        ),
        operation: ApiChangeOperation.dependencyRemoved,
        changedValue: 'Dependency $pkg removed',
      ));
    } else {
      final baseDep = baseDeps[pkg]!;
      final newDep = newDeps[pkg]!;
      if (baseDep.packageVersion != newDep.packageVersion) {
        changes.add(ComponentApiChange(
          component: DocComponent(
            name: pkg,
            type: DocComponentType.dependencyType,
            isNullSafe: true,
            description: 'Dependency',
            constructors: [],
            properties: [],
            methods: [],
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
        component: DocComponent(
          name: pkg,
          type: DocComponentType.dependencyType,
          isNullSafe: true,
          description: 'Dependency',
          constructors: [],
          properties: [],
          methods: [],
        ),
        operation: ApiChangeOperation.dependencyAdded,
        changedValue: 'Dependency $pkg added',
      ));
    }
  }

  // Compare Android constraints
  if (base.androidConstraints != null || newMeta.androidConstraints != null) {
    final baseMin = base.androidConstraints?.minSdkVersion;
    final newMin = newMeta.androidConstraints?.minSdkVersion;
    if (baseMin != newMin) {
      changes.add(ComponentApiChange(
        component: const DocComponent(
          name: 'android:minSdkVersion',
          type: DocComponentType.platformConstraintType,
          isNullSafe: true,
          description: 'Android Platform Constraint',
          constructors: [],
          properties: [],
          methods: [],
        ),
        operation: ApiChangeOperation.platformConstraintChanged,
        changedValue: 'Android minSdkVersion changed from $baseMin to $newMin',
      ));
    }
    // Add other android constraints checks if needed
  }

  // Compare iOS constraints
  if (base.iosConstraints != null || newMeta.iosConstraints != null) {
    final baseMin = base.iosConstraints?.minimumOsVersion;
    final newMin = newMeta.iosConstraints?.minimumOsVersion;
    if (baseMin != newMin) {
      changes.add(ComponentApiChange(
        component: const DocComponent(
          name: 'ios:minimumOsVersion',
          type: DocComponentType.platformConstraintType,
          isNullSafe: true,
          description: 'iOS Platform Constraint',
          constructors: [],
          properties: [],
          methods: [],
        ),
        operation: ApiChangeOperation.platformConstraintChanged,
        changedValue: 'iOS minimumOsVersion changed from $baseMin to $newMin',
      ));
    }
  }

  return changes;
}
