import 'package:mtrust_api_guard/mtrust_api_guard.dart';
import 'package:pub_semver/pub_semver.dart';

/// Compares two lists of items and invokes callbacks for added, removed, and matched items.
///
/// [oldList] The list of items from the old version.
/// [newList] The list of items from the new version.
/// [keyExtractor] A function that returns a unique key for each item (e.g. name).
/// [onRemoved] Callback invoked for items present in [oldList] but missing in [newList].
/// [onAdded] Callback invoked for items present in [newList] but missing in [oldList].
/// [onMatched] Callback invoked for items present in both lists.
void compareLists<T>({
  required List<T> oldList,
  required List<T> newList,
  required String Function(T) keyExtractor,
  required void Function(T) onRemoved,
  required void Function(T) onAdded,
  required void Function(T oldItem, T newItem) onMatched,
}) {
  final newMap = {for (var item in newList) keyExtractor(item): item};
  final oldMap = {for (var item in oldList) keyExtractor(item): item};

  // Check for removed and matched items
  for (final oldItem in oldList) {
    final key = keyExtractor(oldItem);
    if (!newMap.containsKey(key)) {
      onRemoved(oldItem);
    } else {
      onMatched(oldItem, newMap[key]!);
    }
  }

  // Check for added items
  for (final newItem in newList) {
    final key = keyExtractor(newItem);
    if (!oldMap.containsKey(key)) {
      onAdded(newItem);
    }
  }
}

/// Compares two lists of features (modifiers) and invokes callbacks for added and removed features.
void compareFeatures({
  required List<String> oldFeatures,
  required List<String> newFeatures,
  required void Function(String feature) onRemoved,
  required void Function(String feature) onAdded,
}) {
  final oldSet = oldFeatures.toSet();
  final newSet = newFeatures.toSet();

  for (final feature in oldSet) {
    if (!newSet.contains(feature)) {
      onRemoved(feature);
    }
  }

  for (final feature in newSet) {
    if (!oldSet.contains(feature)) {
      onAdded(feature);
    }
  }
}

/// Compares two lists of annotations and invokes callbacks for added and removed annotations.
///
/// [oldAnnotations] The list of annotations from the old version.
/// [newAnnotations] The list of annotations from the new version.
/// [onRemoved] Callback invoked for annotations present in [oldAnnotations] but missing in [newAnnotations].
/// [onAdded] Callback invoked for annotations present in [newAnnotations] but missing in [oldAnnotations].
void compareAnnotations({
  required List<String> oldAnnotations,
  required List<String> newAnnotations,
  required void Function(String) onRemoved,
  required void Function(String) onAdded,
}) {
  for (final annotation in oldAnnotations) {
    if (!newAnnotations.contains(annotation)) {
      onRemoved(annotation);
    }
  }
  for (final annotation in newAnnotations) {
    if (!oldAnnotations.contains(annotation)) {
      onAdded(annotation);
    }
  }
}

/// Callbacks for creating version constraint change events.
class VersionConstraintCallbacks {
  final ApiChange Function(String version, String previousVersion) onMinIncrease;
  final ApiChange Function(String version, String previousVersion) onMinDecrease;
  final ApiChange Function(String version, String previousVersion) onMaxIncrease;
  final ApiChange Function(String version, String previousVersion) onMaxDecrease;

  const VersionConstraintCallbacks({
    required this.onMinIncrease,
    required this.onMinDecrease,
    required this.onMaxIncrease,
    required this.onMaxDecrease,
  });
}

/// Compares two version constraint strings and adds appropriate API changes.
///
/// [oldVersion] The old version constraint string (e.g., "^3.0.0" or ">=3.0.0 <4.0.0").
/// [newVersion] The new version constraint string.
/// [callbacks] Callbacks for creating the appropriate MetaApiChange instances.
/// [changes] The list to add changes to.
void compareVersionConstraints({
  required String? oldVersion,
  required String? newVersion,
  required VersionConstraintCallbacks callbacks,
  required List<ApiChange> changes,
}) {
  if (oldVersion == newVersion) return;

  if (oldVersion == null) {
    // No previous constraint, but now there is one
    changes.add(callbacks.onMinIncrease(newVersion!, 'not constrained'));
    return;
  }

  if (newVersion == null) {
    // No new constraint, but there was one before
    changes.add(callbacks.onMinDecrease(oldVersion, 'constrained to `$oldVersion`'));
    return;
  }

  // Compare the versions using pub_semver
  final oldConstraint = VersionConstraint.parse(oldVersion);
  final newConstraint = VersionConstraint.parse(newVersion);

  // Extract min and max versions from VersionRange
  Version? oldMin, oldMax, newMin, newMax;
  bool oldIncludeMin = false, oldIncludeMax = false;
  bool newIncludeMin = false, newIncludeMax = false;

  if (oldConstraint is VersionRange) {
    oldMin = oldConstraint.min;
    oldMax = oldConstraint.max;
    oldIncludeMin = oldConstraint.includeMin;
    oldIncludeMax = oldConstraint.includeMax;
  } else if (oldConstraint is Version) {
    // Exact version constraint
    oldMin = oldConstraint;
    oldMax = oldConstraint;
    oldIncludeMin = true;
    oldIncludeMax = true;
  }

  if (newConstraint is VersionRange) {
    newMin = newConstraint.min;
    newMax = newConstraint.max;
    newIncludeMin = newConstraint.includeMin;
    newIncludeMax = newConstraint.includeMax;
  } else if (newConstraint is Version) {
    // Exact version constraint
    newMin = newConstraint;
    newMax = newConstraint;
    newIncludeMin = true;
    newIncludeMax = true;
  }

  // Compare minimum versions
  if (oldMin != null && newMin != null) {
    final minComparison = newMin.compareTo(oldMin);
    if (minComparison > 0) {
      // New minimum version is greater
      changes.add(callbacks.onMinIncrease(newVersion, oldVersion));
    } else if (minComparison < 0) {
      // New minimum version is less
      changes.add(callbacks.onMinDecrease(newVersion, oldVersion));
    } else if (minComparison == 0) {
      // Versions are equal, check include flags
      // If old was exclusive (>) and new is inclusive (>=), minimum effectively decreased
      if (!oldIncludeMin && newIncludeMin) {
        changes.add(callbacks.onMinDecrease(newVersion, oldVersion));
      } else if (oldIncludeMin && !newIncludeMin) {
        // If old was inclusive (>=) and new is exclusive (>), minimum effectively increased
        changes.add(callbacks.onMinIncrease(newVersion, oldVersion));
      }
      // If both have same include flag, no change
    }
  } else if (oldMin == null && newMin != null) {
    // Was unbounded, now has a minimum
    changes.add(callbacks.onMinIncrease(newVersion, oldVersion));
  } else if (oldMin != null && newMin == null) {
    // Had a minimum, now unbounded
    changes.add(callbacks.onMinDecrease(newVersion, oldVersion));
  }

  // Compare maximum versions
  if (oldMax != null && newMax != null) {
    final maxComparison = newMax.compareTo(oldMax);
    if (maxComparison > 0) {
      // New maximum version is greater
      changes.add(callbacks.onMaxIncrease(newVersion, oldVersion));
    } else if (maxComparison < 0) {
      // New maximum version is less
      changes.add(callbacks.onMaxDecrease(newVersion, oldVersion));
    } else if (maxComparison == 0) {
      // Versions are equal, check include flags
      // If old was inclusive (<=) and new is exclusive (<), maximum effectively decreased
      if (oldIncludeMax && !newIncludeMax) {
        changes.add(callbacks.onMaxDecrease(newVersion, oldVersion));
      } else if (!oldIncludeMax && newIncludeMax) {
        // If old was exclusive (<) and new is inclusive (<=), maximum effectively increased
        changes.add(callbacks.onMaxIncrease(newVersion, oldVersion));
      }
      // If both have same include flag, no change
    }
  } else if (oldMax == null && newMax != null) {
    // Was unbounded, now has a maximum
    changes.add(callbacks.onMaxDecrease(newVersion, oldVersion));
  } else if (oldMax != null && newMax == null) {
    // Had a maximum, now unbounded
    changes.add(callbacks.onMaxIncrease(newVersion, oldVersion));
  }
}
