import 'package:collection/collection.dart';
import 'package:mtrust_api_guard/doc_comparator/comparators/comparator_helpers.dart';
import 'package:mtrust_api_guard/doc_comparator/comparators/member_comparator.dart';
import 'package:mtrust_api_guard/mtrust_api_guard.dart';

extension DocComponentListApiChangesExt on List<DocComponent> {
  List<ApiChange> compareTo(List<DocComponent> newComponents) {
    final changes = <ApiChange>[];

    compareLists<DocComponent>(
      oldList: this,
      newList: newComponents,
      keyExtractor: (c) => c.name,
      onRemoved: (c) => changes.add(ComponentApiChange(
        component: c,
        operation: ApiChangeOperation.removal,
      )),
      onAdded: (c) => changes.add(ComponentApiChange(
        component: c,
        operation: ApiChangeOperation.addition,
      )),
      onMatched: (oldC, newC) => changes.addAll(oldC.compareTo(newC)),
    );

    return changes;
  }
}

extension DocComponentApiChangesExt on DocComponent {
  List<ApiChange> compareTo(DocComponent newComponent) {
    final changes = <ApiChange>[];

    if (aliasedType != newComponent.aliasedType) {
      changes.add(
        ComponentApiChange(
          component: this,
          operation: ApiChangeOperation.typeChange,
        ),
      );
    }

    compareAnnotations(
      oldAnnotations: annotations,
      newAnnotations: newComponent.annotations,
      onRemoved: (a) => changes.add(ComponentApiChange(
        component: this,
        operation: ApiChangeOperation.annotationRemoval,
        annotation: a,
      )),
      onAdded: (a) => changes.add(ComponentApiChange(
        component: this,
        operation: ApiChangeOperation.annotationAddition,
        annotation: a,
      )),
    );

    if (superClass != newComponent.superClass) {
      changes.add(ComponentApiChange(
        component: this,
        operation: ApiChangeOperation.superClassChange,
        changedValue: '`${superClass ?? 'null'}` → `${newComponent.superClass ?? 'null'}`',
      ));
    }

    compareLists<String>(
      oldList: interfaces,
      newList: newComponent.interfaces,
      keyExtractor: (i) => i,
      onRemoved: (i) => changes.add(ComponentApiChange(
        component: this,
        operation: ApiChangeOperation.interfaceRemoval,
        changedValue: i,
      )),
      onAdded: (i) => changes.add(ComponentApiChange(
        component: this,
        operation: ApiChangeOperation.interfaceImplementation,
        changedValue: i,
      )),
      onMatched: (_, __) {},
    );

    compareLists<String>(
      oldList: mixins,
      newList: newComponent.mixins,
      keyExtractor: (m) => m,
      onRemoved: (m) => changes.add(ComponentApiChange(
        component: this,
        operation: ApiChangeOperation.mixinRemoval,
        changedValue: m,
      )),
      onAdded: (m) => changes.add(ComponentApiChange(
        component: this,
        operation: ApiChangeOperation.mixinApplication,
        changedValue: m,
      )),
      onMatched: (_, __) {},
    );

    // Skip type parameter comparison for functions to prevent duplicate reports, as they are
    // already handled in MethodApiChangesExt.
    if (type != DocComponentType.functionType &&
        !const ListEquality().equals(typeParameters, newComponent.typeParameters)) {
      changes.add(ComponentApiChange(
        component: this,
        operation: ApiChangeOperation.typeParametersChange,
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
