import 'dart:math';

import 'package:collection/collection.dart';
import 'package:mtrust_api_guard/mtrust_api_guard.dart';
import 'comparator_helpers.dart';

/// Compares two lists of parameters and invokes [onDiff] for detected changes.
///
/// This implements "Smarter Parameter Matching" by:
/// 1. Matching parameters by name.
/// 2. Matching remaining parameters by type and order (to detect renames).
/// 3. Detecting additions and removals.
void _compareParameters({
  required List<DocParameter> oldParameters,
  required List<DocParameter> newParameters,
  required void Function(DocParameter param, ApiChangeOperation op,
          {String? oldName, String? annotation, DocType? newType})
      onDiff,
}) {
  final oldParamsCopy = [...oldParameters];
  final newParamsCopy = [...newParameters];

  final matchedByName = <DocParameter, DocParameter>{};

  // 1. Match by name
  for (final oldParam in oldParameters) {
    final matchingNewParam = newParameters.firstWhereOrNull((p) => p.name == oldParam.name);
    if (matchingNewParam != null) {
      matchedByName[oldParam] = matchingNewParam;
    }
  }

  // Remove matched by name from copies
  for (final oldParam in matchedByName.keys) {
    oldParamsCopy.remove(oldParam);
    newParamsCopy.remove(matchedByName[oldParam]!);
  }

  // 2. Match by type order (for remaining POSITIONAL parameters only)
  // We should not match named parameters by type/order because for named parameters, the name IS the identity.
  final oldPositionalRemaining = oldParamsCopy.where((p) => !p.named).toList();
  final newPositionalRemaining = newParamsCopy.where((p) => !p.named).toList();

  final matchedByTypeOrder = <DocParameter, DocParameter>{};
  final length = min(oldPositionalRemaining.length, newPositionalRemaining.length);
  for (int i = 0; i < length; i++) {
    if (oldPositionalRemaining[i].type != newPositionalRemaining[i].type) {
      break; // Stop at first mismatch to avoid false positives
    }
    matchedByTypeOrder[oldPositionalRemaining[i]] = newPositionalRemaining[i];
  }

  // Remove matched by type order from copies
  for (final oldParam in matchedByTypeOrder.keys) {
    oldParamsCopy.remove(oldParam);
    newParamsCopy.remove(matchedByTypeOrder[oldParam]!);
  }

  // Combine matches
  final allMatches = {...matchedByName, ...matchedByTypeOrder};

  // Check for reordering of positional parameters
  final oldPositional = oldParameters.where((p) => !p.named).toList();
  final newPositional = newParameters.where((p) => !p.named).toList();

  // Process matches
  for (final oldParam in allMatches.keys) {
    final newParam = allMatches[oldParam]!;

    if (oldParam.name != newParam.name) {
      onDiff(newParam, ApiChangeOperation.renamed, oldName: oldParam.name);
    }

    if (oldParam.type != newParam.type) {
      onDiff(oldParam, ApiChangeOperation.typeChanged, newType: newParam.type);
    }

    if (oldParam.required != newParam.required) {
      onDiff(
        oldParam,
        oldParam.required ? ApiChangeOperation.becameOptional : ApiChangeOperation.becameRequired,
      );
    }

    if (oldParam.named != newParam.named) {
      onDiff(
        oldParam,
        oldParam.named ? ApiChangeOperation.becamePositional : ApiChangeOperation.becameNamed,
      );
    } else if (!oldParam.named) {
      // Check for reordering (only for positional parameters)
      final oldIndex = oldPositional.indexOf(oldParam);
      final newIndex = newPositional.indexOf(newParam);
      if (oldIndex != -1 && newIndex != -1 && oldIndex != newIndex) {
        onDiff(oldParam, ApiChangeOperation.reordered);
      }
    }

    compareAnnotations(
      oldAnnotations: oldParam.annotations,
      newAnnotations: newParam.annotations,
      onRemoved: (a) => onDiff(oldParam, ApiChangeOperation.annotationRemoved, annotation: a),
      onAdded: (a) => onDiff(oldParam, ApiChangeOperation.annotationAdded, annotation: a),
    );
  }

  // Process removed
  for (final oldParam in oldParamsCopy) {
    onDiff(oldParam, ApiChangeOperation.removed);
  }

  // Process added
  for (final newParam in newParamsCopy) {
    onDiff(newParam, ApiChangeOperation.added);
  }
}

extension ConstructorApiChangesExt on DocConstructor {
  /// Compares [this] constructor with [newConstructor] and returns a list of
  /// [ApiChange]s that have been detected between the two constructors.
  List<ApiChange> compareTo(
    DocConstructor newConstructor, {
    required DocComponent component,
  }) {
    final changes = <ApiChange>[];

    compareAnnotations(
      oldAnnotations: annotations,
      newAnnotations: newConstructor.annotations,
      onRemoved: (a) => changes.add(ConstructorApiChange(
        component: component,
        constructor: this,
        operation: ApiChangeOperation.annotationRemoved,
        annotation: a,
      )),
      onAdded: (a) => changes.add(ConstructorApiChange(
        component: component,
        constructor: this,
        operation: ApiChangeOperation.annotationAdded,
        annotation: a,
      )),
    );

    compareFeatures(
      oldFeatures: features,
      newFeatures: newConstructor.features,
      onRemoved: (f) => changes.add(ConstructorApiChange(
        component: component,
        constructor: this,
        operation: ApiChangeOperation.featureRemoved,
        changedValue: f,
      )),
      onAdded: (f) => changes.add(ConstructorApiChange(
        component: component,
        constructor: this,
        operation: ApiChangeOperation.featureAdded,
        changedValue: f,
      )),
    );

    _compareParameters(
      oldParameters: signature,
      newParameters: newConstructor.signature,
      onDiff: (param, op, {oldName, annotation, newType}) {
        changes.add(ConstructorParameterApiChange(
          component: component,
          constructor: this,
          operation: op,
          parameter: param,
          oldName: oldName,
          newType: newType,
          annotation: annotation,
        ));
      },
    );

    return changes;
  }
}

extension ConstructorListApiChangesExt on List<DocConstructor> {
  /// Compares [this] list of constructors with [newConstructors] and returns a
  /// list of [ApiChange]s that have been detected between the two lists.
  List<ApiChange> compareTo(
    List<DocConstructor> newConstructors, {
    required DocComponent component,
  }) {
    final changes = <ApiChange>[];

    compareLists<DocConstructor>(
      oldList: this,
      newList: newConstructors,
      keyExtractor: (c) => c.name,
      onRemoved: (c) => changes.add(ConstructorApiChange(
        component: component,
        constructor: c,
        operation: ApiChangeOperation.removed,
      )),
      onAdded: (c) => changes.add(ConstructorApiChange(
        component: component,
        constructor: c,
        operation: ApiChangeOperation.added,
      )),
      onMatched: (oldC, newC) => changes.addAll(oldC.compareTo(newC, component: component)),
    );

    return changes;
  }
}

extension PropertyListApiChangesExt on List<DocProperty> {
  /// Compares [this] list of properties with [newProperties] and returns a list
  /// of [ApiChange]s that have been detected between the two lists.
  List<ApiChange> compareTo(
    List<DocProperty> newProperties, {
    required DocComponent component,
  }) {
    final changes = <ApiChange>[];

    compareLists<DocProperty>(
      oldList: this,
      newList: newProperties,
      keyExtractor: (p) => p.name,
      onRemoved: (p) => changes.add(PropertyApiChange(
        component: component,
        property: p,
        operation: ApiChangeOperation.removed,
      )),
      onAdded: (p) => changes.add(PropertyApiChange(
        component: component,
        property: p,
        operation: ApiChangeOperation.added,
      )),
      onMatched: (oldP, newP) {
        if (oldP.type != newP.type) {
          changes.add(PropertyApiChange(
            component: component,
            property: oldP,
            operation: ApiChangeOperation.typeChanged,
          ));
        }

        compareFeatures(
          oldFeatures: oldP.features,
          newFeatures: newP.features,
          onRemoved: (f) => changes.add(PropertyApiChange(
            component: component,
            property: oldP,
            operation: ApiChangeOperation.featureRemoved,
            changedValue: f,
          )),
          onAdded: (f) => changes.add(PropertyApiChange(
            component: component,
            property: oldP,
            operation: ApiChangeOperation.featureAdded,
            changedValue: f,
          )),
        );

        compareAnnotations(
          oldAnnotations: oldP.annotations,
          newAnnotations: newP.annotations,
          onRemoved: (a) => changes.add(PropertyApiChange(
            component: component,
            property: oldP,
            operation: ApiChangeOperation.annotationRemoved,
            annotation: a,
          )),
          onAdded: (a) => changes.add(PropertyApiChange(
            component: component,
            property: oldP,
            operation: ApiChangeOperation.annotationAdded,
            annotation: a,
          )),
        );
      },
    );

    return changes;
  }
}

extension MethodListApiChangesExt on List<DocMethod> {
  /// Compares [this] list of methods with [newMethods] and returns a list
  /// of [ApiChange]s that have been detected between the two lists.
  List<ApiChange> compareTo(
    List<DocMethod> newMethods, {
    required DocComponent component,
  }) {
    final changes = <ApiChange>[];

    compareLists<DocMethod>(
      oldList: this,
      newList: newMethods,
      keyExtractor: (m) => m.name,
      onRemoved: (m) => changes.add(MethodApiChange(
        component: component,
        method: m,
        operation: ApiChangeOperation.removed,
      )),
      onAdded: (m) => changes.add(MethodApiChange(
        component: component,
        method: m,
        operation: ApiChangeOperation.added,
      )),
      onMatched: (oldM, newM) => changes.addAll(oldM.compareTo(newM, component: component)),
    );

    return changes;
  }
}

extension MethodApiChangesExt on DocMethod {
  /// Compares [this] method with [newMethod] and returns a list of
  /// [ApiChange]s that have been detected between the two methods.
  List<ApiChange> compareTo(
    DocMethod newMethod, {
    required DocComponent component,
  }) {
    final changes = <ApiChange>[];

    if (returnType != newMethod.returnType) {
      changes.add(MethodApiChange(
        component: component,
        method: this,
        operation: ApiChangeOperation.typeChanged,
        newType: newMethod.returnType,
      ));
    }

    if (!const ListEquality().equals(typeParameters, newMethod.typeParameters)) {
      changes.add(MethodApiChange(
        component: component,
        method: this,
        operation: ApiChangeOperation.typeParametersChanged,
        changedValue: '`${typeParameters.join(', ')}` → `${newMethod.typeParameters.join(', ')}`',
      ));
    }

    compareFeatures(
      oldFeatures: features,
      newFeatures: newMethod.features,
      onRemoved: (f) => changes.add(MethodApiChange(
        component: component,
        method: this,
        operation: ApiChangeOperation.featureRemoved,
        changedValue: f,
      )),
      onAdded: (f) => changes.add(MethodApiChange(
        component: component,
        method: this,
        operation: ApiChangeOperation.featureAdded,
        changedValue: f,
      )),
    );

    compareAnnotations(
      oldAnnotations: annotations,
      newAnnotations: newMethod.annotations,
      onRemoved: (a) => changes.add(MethodApiChange(
        component: component,
        method: this,
        operation: ApiChangeOperation.annotationRemoved,
        annotation: a,
      )),
      onAdded: (a) => changes.add(MethodApiChange(
        component: component,
        method: this,
        operation: ApiChangeOperation.annotationAdded,
        annotation: a,
      )),
    );

    _compareParameters(
      oldParameters: signature,
      newParameters: newMethod.signature,
      onDiff: (param, op, {oldName, annotation, newType}) {
        changes.add(MethodParameterApiChange(
          component: component,
          method: this,
          operation: op,
          parameter: param,
          oldName: oldName,
          newType: newType,
          annotation: annotation,
        ));
      },
    );

    return changes;
  }
}
