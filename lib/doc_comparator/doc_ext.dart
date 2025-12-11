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

extension MethodListApiChangesExt on List<String> {
  /// Compares [this] list of methods with [newMethods] and returns a list
  /// of [ApiChange]s that have been detected between the two lists.
  List<ApiChange> compareTo(
    List<String> newMethods, {
    required DocComponent component,
  }) {
    final changes = <ApiChange>[];

    for (var i = 0; i < length; i++) {
      final newMethod = newMethods.firstWhereOrNull((element) => element == this[i]);
      if (newMethod == null) {
        changes.add(MethodApiChange(
          component: component,
          methodName: this[i],
          operation: ApiChangeOperation.removed,
        ));
      }
    }

    for (var i = 0; i < newMethods.length; i++) {
      final oldMethod = firstWhereOrNull((element) => element == newMethods[i]);
      if (oldMethod == null) {
        changes.add(MethodApiChange(
          component: component,
          methodName: newMethods[i],
          operation: ApiChangeOperation.added,
        ));
      }
    }

    return changes;
  }
}
