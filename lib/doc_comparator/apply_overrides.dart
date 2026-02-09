import 'package:collection/collection.dart';
import 'package:mtrust_api_guard/config/config.dart';
import 'package:mtrust_api_guard/config/magnitude_override.dart';
import 'package:mtrust_api_guard/doc_comparator/api_change.dart';
import 'package:mtrust_api_guard/logger.dart';
import 'package:mtrust_api_guard/models/doc_items.dart';

void applyMagnitudeOverrides(List<ApiChange> changes, ApiGuardConfig config) {
  for (final change in changes) {
    for (final override in config.magnitudeOverrides) {
      if (_matches(override, change)) {
        final magnitude = ApiChangeMagnitude.values.firstWhereOrNull(
          (e) => e.name == override.magnitude,
        );
        if (magnitude != null) {
          final originalMagnitude = change.getMagnitude();
          change.overrideMagnitude(magnitude);
          logger.detail(
            'Overriding magnitude for ${change.component.name} '
            '(${change.operation.name}) from ${originalMagnitude.name} '
            'to ${magnitude.name} (Rule: ${override.description ?? override.operations.join(", ")})',
          );
        } else {
          logger.detail(
            'WARNING: Invalid magnitude "${override.magnitude}" in override for '
            '${change.component.name} (${change.operation.name}). Skipping magnitude override.',
          );
        }
        break; // Stop after the first matching override
      }
    }
  }
}

bool _matches(MagnitudeOverride override, ApiChange change) {
  final operationName = change.operation.name;
  bool operationMatched = false;

  if (override.operations.contains('*') || override.operations.contains('all')) {
    operationMatched = true;
  } else if (override.operations.contains(operationName)) {
    operationMatched = true;
  }

  if (!operationMatched) return false;

  if (override.selection != null) {
    final context = _createContext(change);
    if (!_matchesSelection(override.selection!, context)) return false;
  }

  return true;
}

bool _matchesSelection(OverrideSelection selection, _SelectionContext context) {
  if (selection.entity != null) {
    // Check if any of the kinds match (case-insensitive)
    if (!selection.entity!.any((k) => k.toLowerCase() == context.kind)) {
      return false;
    }
  }

  if (selection.namePattern != null) {
    try {
      final regex = RegExp(selection.namePattern!);
      if (!regex.hasMatch(context.name)) return false;
    } on FormatException catch (e) {
      // Provide a clearer error message when an invalid regex pattern is configured.
      throw FormatException(
        'Invalid namePattern regex "${selection.namePattern}": ${e.message}',
      );
    }
  }

  if (selection.hasAnnotation != null) {
    bool anyAnnotationMatched = false;
    for (final required in selection.hasAnnotation!) {
      if (context.annotations.any((a) => a.contains(required))) {
        anyAnnotationMatched = true;
        break;
      }
    }
    if (!anyAnnotationMatched) return false;
  }

  if (selection.subtypeOf != null) {
    bool subtypeMatched = false;
    for (final parentType in selection.subtypeOf!) {
      // Direct types check (extends, implements, with)
      // Note: This is an exact string check against the type names in the code
      if (context.superTypes.contains(parentType)) {
        subtypeMatched = true;
        break;
      }
    }
    if (!subtypeMatched) return false;
  }

  if (selection.fromPackage != null) {
    bool packageMatched = false;
    for (final package in selection.fromPackage!) {
      // Direct package check
      if (context.superClassPackages.contains(package)) {
        packageMatched = true;
        break;
      }
    }
    if (!packageMatched) return false;
  }

  if (selection.enclosing != null) {
    if (context.enclosing == null) return false;
    if (!_matchesSelection(selection.enclosing!, context.enclosing!)) {
      return false;
    }
  }

  return true;
}

class _SelectionContext {
  final String name;
  final String kind;
  final List<String> annotations;
  final List<String> superTypes;
  final List<String> superClassPackages;
  final _SelectionContext? enclosing;

  _SelectionContext({
    required this.name,
    required this.kind,
    required this.annotations,
    required this.superTypes,
    this.superClassPackages = const [],
    this.enclosing,
  });

  @override
  String toString() {
    return 'SelectionContext(name: $name, kind: $kind, annotations: $annotations, superTypes: $superTypes, superClassPackages: $superClassPackages, enclosing: $enclosing)';
  }
}

_SelectionContext _createContext(ApiChange change) {
  // Component context (usually the enclosing class/mixin/etc.)
  final componentKind = _getComponentKind(change.component.type);

  final superTypes = <String>[];
  superTypes.addAll(change.component.superClasses);
  superTypes.addAll(change.component.interfaces);
  superTypes.addAll(change.component.mixins);

  final componentContext = _SelectionContext(
    name: change.component.name,
    kind: componentKind,
    annotations: change.component.annotations,
    superTypes: superTypes,
    superClassPackages: change.component.superClassPackages,
    enclosing: null,
  );

  if (change is PropertyApiChange) {
    // Add the property type and its supertypes to the check
    final propertySupertypes = [change.property.type.name, ...change.property.type.superTypes];

    return _SelectionContext(
      name: change.property.name,
      kind: 'property',
      annotations: change.property.annotations,
      superTypes: propertySupertypes,
      enclosing: componentContext,
    );
  } else if (change is MethodApiChange) {
    final kind = change.isFunctionChange() ? 'function' : 'method';

    // For methods, we consider the return type as the primary type for checking
    final returnTypeSupertypes = [change.method.returnType.name, ...change.method.returnType.superTypes];

    return _SelectionContext(
      name: change.method.name,
      kind: kind,
      annotations: change.method.annotations,
      superTypes: returnTypeSupertypes,
      enclosing: componentContext,
    );
  } else if (change is ParameterApiChange) {
    // Try to resolve the parent method/constructor context
    _SelectionContext? methodContext;
    final parentName = change.parentName;

    // Check methods
    final parentMethod = change.component.methods.firstWhereOrNull((m) => m.name == parentName);
    if (parentMethod != null) {
      final returnTypeSupertypes = [parentMethod.returnType.name, ...parentMethod.returnType.superTypes];
      methodContext = _SelectionContext(
        name: parentMethod.name,
        kind: 'method',
        annotations: parentMethod.annotations,
        superTypes: returnTypeSupertypes,
        enclosing: componentContext,
      );
    } else {
      // Check constructors
      final parentConstructor = change.component.constructors.firstWhereOrNull((c) => c.name == parentName);
      if (parentConstructor != null) {
        methodContext = _SelectionContext(
          name: parentConstructor.name,
          kind: 'constructor',
          annotations: parentConstructor.annotations,
          superTypes: [],
          enclosing: componentContext,
        );
      } else {
        // Fallback for unknown parent (should not happen normally)
        methodContext = _SelectionContext(
          name: parentName,
          kind: 'method', // assume method/constructor
          annotations: [],
          superTypes: [],
          enclosing: componentContext,
        );
      }
    }

    final parameterSupertypes = [change.parameter.type.name, ...change.parameter.type.superTypes];

    return _SelectionContext(
      name: change.parameter.name,
      kind: 'parameter',
      annotations: change.parameter.annotations,
      superTypes: parameterSupertypes,
      enclosing: methodContext,
    );
  } else {
    // Top-level component change
    return componentContext;
  }
}

String _getComponentKind(DocComponentType type) {
  switch (type) {
    case DocComponentType.classType:
      return 'class';
    case DocComponentType.functionType:
      return 'function';
    case DocComponentType.mixinType:
      return 'mixin';
    case DocComponentType.enumType:
      return 'enum';
    case DocComponentType.typedefType:
      return 'typedef';
    case DocComponentType.extensionType:
      return 'extension';
    case DocComponentType.metaType:
      return 'meta';
  }
}
