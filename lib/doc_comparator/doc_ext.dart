import 'package:collection/collection.dart';
import 'package:mtrust_api_guard/mtrust_api_guard.dart';

extension DocComponentListApiChangesExt on List<DocComponent> {
  List<ApiChange> compareTo(List<DocComponent> newComponents) {
    final changes = <ApiChange>[];

    for (var i = 0; i < length; i++) {
      final newComponent = newComponents.firstWhereOrNull((element) => element.name == this[i].name);
      if (newComponent == null) {
        changes.add(ComponentApiChange(
          component: this[i],
          operation: ApiChangeOperation.removed,
        ));
        continue;
      }
      changes.addAll(this[i].compareTo(newComponent));
    }

    for (var i = 0; i < newComponents.length; i++) {
      final oldComponent = firstWhereOrNull((element) => element.name == newComponents[i].name);
      if (oldComponent == null) {
        changes.add(ComponentApiChange(
          component: newComponents[i],
          operation: ApiChangeOperation.added,
        ));
      }
    }

    return changes;
  }
}

extension DocComponentApiChangesExt on DocComponent {
  List<ApiChange> compareTo(DocComponent newComponent) {
    final changes = <ApiChange>[];

    if (isNullSafe != newComponent.isNullSafe) {
      changes.add(
        ComponentApiChange(
          component: this,
          operation: newComponent.isNullSafe ? ApiChangeOperation.becameNullSafe : ApiChangeOperation.becameNullUnsafe,
        ),
      );
    }

    changes.addAll(
      constructors.compareTo(newComponent.constructors, component: this),
    );
    changes.addAll(
      properties.compareTo(newComponent.properties, component: this),
    );
    changes.addAll(
      methods.compareTo(newComponent.methods, component: this),
    );

    return changes;
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
    _addChange(DocParameter parameter, ApiChangeOperation operation) {
      changes.add(ConstructorParameterApiChange(
        component: component,
        constructor: this,
        operation: operation,
        parameter: parameter,
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

    for (var i = 0; i < length; i++) {
      final newConstructor = newConstructors.firstWhereOrNull((element) => element.name == this[i].name);
      if (newConstructor == null) {
        changes.add(ConstructorApiChange(
          component: component,
          constructor: this[i],
          operation: ApiChangeOperation.removed,
        ));
        continue;
      }
      changes.addAll(this[i].compareTo(newConstructor, component: component));
    }

    for (var i = 0; i < newConstructors.length; i++) {
      final oldConstructor = firstWhereOrNull((element) => element.name == newConstructors[i].name);
      if (oldConstructor == null) {
        changes.add(ConstructorApiChange(
          component: component,
          constructor: newConstructors[i],
          operation: ApiChangeOperation.added,
        ));
      }
    }

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

    for (var i = 0; i < length; i++) {
      final newProperty = newProperties.firstWhereOrNull((element) => element.name == this[i].name);
      if (newProperty == null) {
        changes.add(PropertyApiChange(
          component: component,
          property: this[i],
          operation: ApiChangeOperation.removed,
        ));
        continue;
      }
      if (this[i].type != newProperty.type) {
        changes.add(PropertyApiChange(
          component: component,
          property: this[i],
          operation: ApiChangeOperation.typeChanged,
        ));
      }
    }

    for (var i = 0; i < newProperties.length; i++) {
      final oldProperty = firstWhereOrNull((element) => element.name == newProperties[i].name);
      if (oldProperty == null) {
        changes.add(PropertyApiChange(
          component: component,
          property: newProperties[i],
          operation: ApiChangeOperation.added,
        ));
      }
    }

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

    for (var i = 0; i < length; i++) {
      final newMethod = newMethods.firstWhereOrNull((element) => element.name == this[i].name);
      if (newMethod == null) {
        changes.add(MethodApiChange(
          component: component,
          method: this[i],
          operation: ApiChangeOperation.removed,
        ));
        continue;
      }
      changes.addAll(this[i].compareTo(newMethod, component: component));
    }

    for (var i = 0; i < newMethods.length; i++) {
      final oldMethod = firstWhereOrNull((element) => element.name == newMethods[i].name);
      if (oldMethod == null) {
        changes.add(MethodApiChange(
          component: component,
          method: newMethods[i],
          operation: ApiChangeOperation.added,
        ));
      }
    }

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
    _addChange(DocParameter parameter, ApiChangeOperation operation, {String? oldName}) {
      changes.add(MethodParameterApiChange(
        component: component,
        method: this,
        operation: operation,
        parameter: parameter,
        oldName: oldName,
      ));
    }

    if (returnType != newMethod.returnType) {
      changes.add(MethodApiChange(
        component: component,
        method: this,
        operation: ApiChangeOperation.typeChanged,
        newType: newMethod.returnType,
      ));
    }

    final oldPositional = signature.where((p) => !p.named).toList();
    final oldNamed = signature.where((p) => p.named).toList();
    final newPositional = newMethod.signature.where((p) => !p.named).toList();
    final newNamed = newMethod.signature.where((p) => p.named).toList();

    final processedOld = <DocParameter>{};
    final processedNew = <DocParameter>{};

    // Check old named -> new positional
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
        processedOld.add(oldP);
        processedNew.add(newP);
      }
    }

    // Check old positional -> new named
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
      } else if (i >= remainingOldPositional.length) {
        _addChange(remainingNewPositional[i], ApiChangeOperation.added);
      } else {
        _addChange(remainingOldPositional[i], ApiChangeOperation.removed);
      }
    }

    return changes;
  }
}
