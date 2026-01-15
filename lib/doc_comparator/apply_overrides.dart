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
            'to ${magnitude.name} (Rule: ${override.rule})',
          );
        }
        break; // Stop after the first matching override
      }
    }
  }
}

bool _matches(MagnitudeOverride override, ApiChange change) {
  final operationName = change.operation.name;

  // Determine if we should check 'rule' or 'operation' against the change operation
  bool operationMatched = false;

  // If 'operation' is explicitly provided, it must match.
  // We treat 'rule' as just a label in this case.
  // But strictly, if operation is provided, we use it for matching the op.
  if (override.operation != null) {
    if (override.operation == operationName) {
      operationMatched = true;
    }
  } else {
    // If no operation provided, 'rule' must match the operation
    if (override.rule == operationName) {
      operationMatched = true;
    }
  }

  if (!operationMatched) return false;

  if (override.selection != null) {
    String? elementKind;
    bool? isPublic;

    if (change is PropertyApiChange) {
      elementKind = 'property';
      isPublic = !change.property.name.startsWith('_');
    } else if (change is MethodApiChange) {
      elementKind = change.isFunctionChange() ? 'function' : 'method';
      isPublic = !change.method.name.startsWith('_');
    } else {
      // Top level component change
      elementKind = _getComponentKind(change.component.type);
      isPublic = !change.component.name.startsWith('_');
    }

    final sel = override.selection!;

    if (sel.isPublic != null && sel.isPublic != isPublic) return false;

    if (sel.elementKind != null) {
      if (!sel.elementKind!.contains(elementKind.toLowerCase())) return false;
    }
  }

  return true;
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
