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
        operation: ApiChangeOperation.removed,
      )),
      onAdded: (c) => changes.add(ComponentApiChange(
        component: c,
        operation: ApiChangeOperation.added,
      )),
      onMatched: (oldC, newC) => changes.addAll(oldC.compareTo(newC)),
    );

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

    compareAnnotations(
      oldAnnotations: annotations,
      newAnnotations: newComponent.annotations,
      onRemoved: (a) => changes.add(ComponentApiChange(
        component: this,
        operation: ApiChangeOperation.annotationRemoved,
        annotation: a,
      )),
      onAdded: (a) => changes.add(ComponentApiChange(
        component: this,
        operation: ApiChangeOperation.annotationAdded,
        annotation: a,
      )),
    );

    if (superClass != newComponent.superClass) {
      changes.add(ComponentApiChange(
        component: this,
        operation: ApiChangeOperation.superClassChanged,
        changedValue: '`${superClass ?? 'null'}` → `${newComponent.superClass ?? 'null'}`',
      ));
    }

    compareLists<String>(
      oldList: interfaces,
      newList: newComponent.interfaces,
      keyExtractor: (i) => i,
      onRemoved: (i) => changes.add(ComponentApiChange(
        component: this,
        operation: ApiChangeOperation.interfaceRemoved,
        changedValue: i,
      )),
      onAdded: (i) => changes.add(ComponentApiChange(
        component: this,
        operation: ApiChangeOperation.interfaceAdded,
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
        operation: ApiChangeOperation.mixinRemoved,
        changedValue: m,
      )),
      onAdded: (m) => changes.add(ComponentApiChange(
        component: this,
        operation: ApiChangeOperation.mixinAdded,
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
