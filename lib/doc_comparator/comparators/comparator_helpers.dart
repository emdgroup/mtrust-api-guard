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
