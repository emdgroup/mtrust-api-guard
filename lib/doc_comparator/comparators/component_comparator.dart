import 'package:collection/collection.dart';
import 'package:mtrust_api_guard/doc_comparator/comparators/member_comparator.dart';
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

    if (aliasedType != newComponent.aliasedType) {
      changes.add(
        ComponentApiChange(
          component: this,
          operation: ApiChangeOperation.typeChanged,
        ),
      );
    }

    for (final annotation in annotations) {
      if (!newComponent.annotations.contains(annotation)) {
        changes.add(ComponentApiChange(
          component: this,
          operation: ApiChangeOperation.annotationRemoved,
          annotation: annotation,
        ));
      }
    }
    for (final annotation in newComponent.annotations) {
      if (!annotations.contains(annotation)) {
        changes.add(ComponentApiChange(
          component: this,
          operation: ApiChangeOperation.annotationAdded,
          annotation: annotation,
        ));
      }
    }

    if (superClass != newComponent.superClass) {
      changes.add(ComponentApiChange(
        component: this,
        operation: ApiChangeOperation.superClassChanged,
        changedValue: '`${superClass ?? 'null'}` → `${newComponent.superClass ?? 'null'}`',
      ));
    }

    for (final interface in interfaces) {
      if (!newComponent.interfaces.contains(interface)) {
        changes.add(ComponentApiChange(
          component: this,
          operation: ApiChangeOperation.interfaceRemoved,
          changedValue: interface,
        ));
      }
    }
    for (final interface in newComponent.interfaces) {
      if (!interfaces.contains(interface)) {
        changes.add(ComponentApiChange(
          component: this,
          operation: ApiChangeOperation.interfaceAdded,
          changedValue: interface,
        ));
      }
    }

    for (final mixin in mixins) {
      if (!newComponent.mixins.contains(mixin)) {
        changes.add(ComponentApiChange(
          component: this,
          operation: ApiChangeOperation.mixinRemoved,
          changedValue: mixin,
        ));
      }
    }
    for (final mixin in newComponent.mixins) {
      if (!mixins.contains(mixin)) {
        changes.add(ComponentApiChange(
          component: this,
          operation: ApiChangeOperation.mixinAdded,
          changedValue: mixin,
        ));
      }
    }

    // Skip type parameter comparison for functions to prevent duplicate reports, as they are
    // already handled in MethodApiChangesExt.
    if (type != DocComponentType.functionType &&
        !const ListEquality().equals(typeParameters, newComponent.typeParameters)) {
      changes.add(ComponentApiChange(
        component: this,
        operation: ApiChangeOperation.typeParametersChanged,
        changedValue: '`${typeParameters.join(', ')}` → `${newComponent.typeParameters.join(', ')}`',
      ));
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
