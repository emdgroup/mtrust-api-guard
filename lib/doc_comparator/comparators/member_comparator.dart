import 'package:collection/collection.dart';
import 'package:mtrust_api_guard/mtrust_api_guard.dart';
import 'comparator_helpers.dart';

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

    _addChange(DocParameter parameter, ApiChangeOperation operation, {String? annotation}) {
      changes.add(ConstructorParameterApiChange(
        component: component,
        constructor: this,
        operation: operation,
        parameter: parameter,
        annotation: annotation,
      ));
    }

    for (var i = 0; i < signature.length; i++) {
      final oldParam = signature[i];
      final newParam = newConstructor.signature.firstWhereOrNull((element) => element.name == oldParam.name);
      if (newParam == null) {
        _addChange(oldParam, ApiChangeOperation.removed);
        continue;
      }
      if (oldParam.required != newParam.required) {
        _addChange(
          oldParam,
          oldParam.required ? ApiChangeOperation.becameOptional : ApiChangeOperation.becameRequired,
        );
      }
      if (oldParam.named != newParam.named) {
        _addChange(
          oldParam,
          oldParam.named ? ApiChangeOperation.becamePositional : ApiChangeOperation.becameNamed,
        );
      }
      if (oldParam.type != newParam.type) {
        _addChange(oldParam, ApiChangeOperation.typeChanged);
      }

      compareAnnotations(
        oldAnnotations: oldParam.annotations,
        newAnnotations: newParam.annotations,
        onRemoved: (a) => _addChange(oldParam, ApiChangeOperation.annotationRemoved, annotation: a),
        onAdded: (a) => _addChange(oldParam, ApiChangeOperation.annotationAdded, annotation: a),
      );
    }

    for (var i = 0; i < newConstructor.signature.length; i++) {
      final newParam = newConstructor.signature[i];
      final oldParam = signature.firstWhereOrNull((element) => element.name == newParam.name);
      if (oldParam == null) {
        _addChange(newParam, ApiChangeOperation.added);
      }
    }

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
    _addChange(DocParameter parameter, ApiChangeOperation operation, {String? oldName, String? annotation}) {
      changes.add(MethodParameterApiChange(
        component: component,
        method: this,
        operation: operation,
        parameter: parameter,
        oldName: oldName,
        annotation: annotation,
      ));
    }

    void _checkParamAnnotations(DocParameter oldP, DocParameter newP) {
      compareAnnotations(
        oldAnnotations: oldP.annotations,
        newAnnotations: newP.annotations,
        onRemoved: (a) => _addChange(oldP, ApiChangeOperation.annotationRemoved, annotation: a),
        onAdded: (a) => _addChange(oldP, ApiChangeOperation.annotationAdded, annotation: a),
      );
    }

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

    final oldPositional = signature.where((p) => !p.named).toList();
    final oldNamed = signature.where((p) => p.named).toList();
    final newPositional = newMethod.signature.where((p) => !p.named).toList();
    final newNamed = newMethod.signature.where((p) => p.named).toList();

    final processedOld = <DocParameter>{};
    final processedNew = <DocParameter>{};

    // Check old named → new positional
    for (final oldP in oldNamed) {
      final newP = newPositional.firstWhereOrNull((p) => p.name == oldP.name);
      if (newP != null) {
        _addChange(oldP, ApiChangeOperation.becamePositional);
        if (oldP.type != newP.type) {
          _addChange(oldP, ApiChangeOperation.typeChanged);
        }
        if (oldP.required != newP.required) {
          _addChange(
            oldP,
            oldP.required ? ApiChangeOperation.becameOptional : ApiChangeOperation.becameRequired,
          );
        }
        _checkParamAnnotations(oldP, newP);
        processedOld.add(oldP);
        processedNew.add(newP);
      }
    }

    // Check old positional → new named
    for (final oldP in oldPositional) {
      final newP = newNamed.firstWhereOrNull((p) => p.name == oldP.name);
      if (newP != null) {
        _addChange(oldP, ApiChangeOperation.becameNamed);
        if (oldP.type != newP.type) {
          _addChange(oldP, ApiChangeOperation.typeChanged);
        }
        if (oldP.required != newP.required) {
          _addChange(
            oldP,
            oldP.required ? ApiChangeOperation.becameOptional : ApiChangeOperation.becameRequired,
          );
        }
        _checkParamAnnotations(oldP, newP);
        processedOld.add(oldP);
        processedNew.add(newP);
      }
    }

    // Compare remaining named parameters
    for (final oldP in oldNamed) {
      if (processedOld.contains(oldP)) continue;
      final newP = newNamed.firstWhereOrNull((p) => p.name == oldP.name);
      if (newP == null) {
        _addChange(oldP, ApiChangeOperation.removed);
      } else {
        processedNew.add(newP);
        if (oldP.type != newP.type) {
          _addChange(oldP, ApiChangeOperation.typeChanged);
        }
        if (oldP.required != newP.required) {
          _addChange(
            oldP,
            oldP.required ? ApiChangeOperation.becameOptional : ApiChangeOperation.becameRequired,
          );
        }
        _checkParamAnnotations(oldP, newP);
      }
    }

    for (final newP in newNamed) {
      if (processedNew.contains(newP)) continue;
      _addChange(newP, ApiChangeOperation.added);
    }

    // Compare remaining positional parameters by index
    final remainingOldPositional = oldPositional.where((p) => !processedOld.contains(p)).toList();
    final remainingNewPositional = newPositional.where((p) => !processedNew.contains(p)).toList();

    final maxPos = remainingOldPositional.length > remainingNewPositional.length
        ? remainingOldPositional.length
        : remainingNewPositional.length;

    for (var i = 0; i < maxPos; i++) {
      if (i < remainingOldPositional.length && i < remainingNewPositional.length) {
        final oldP = remainingOldPositional[i];
        final newP = remainingNewPositional[i];

        if (oldP.name != newP.name) {
          _addChange(newP, ApiChangeOperation.renamed, oldName: oldP.name);
        }
        if (oldP.type != newP.type) {
          _addChange(oldP, ApiChangeOperation.typeChanged);
        }
        if (oldP.required != newP.required) {
          _addChange(
            oldP,
            oldP.required ? ApiChangeOperation.becameOptional : ApiChangeOperation.becameRequired,
          );
        }
        _checkParamAnnotations(oldP, newP);
      } else if (i >= remainingOldPositional.length) {
        _addChange(remainingNewPositional[i], ApiChangeOperation.added);
      } else {
        _addChange(remainingOldPositional[i], ApiChangeOperation.removed);
      }
    }

    return changes;
  }
}
