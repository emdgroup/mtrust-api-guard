import 'package:collection/collection.dart';
import 'package:mtrust_api_guard/mtrust_api_guard.dart';

/// Formatter to display API changes in a hierarchical format
class ApiChangeFormatter {
  final List<ApiChange> changes;

  final Set<ApiChangeMagnitude> magnitudes;

  final int markdownHeaderLevel;

  final String? fileBaseUrl;

  ApiChangeFormatter(
    this.changes, {
    this.markdownHeaderLevel = 1,
    this.magnitudes = const {
      ApiChangeMagnitude.major,
      ApiChangeMagnitude.minor,
      ApiChangeMagnitude.patch,
    },
    this.fileBaseUrl,
  });

  bool get hasRelevantChanges => changes.any(
        (changes) => magnitudes.contains(changes.getMagnitude()),
      );

  String get highestMagnitudeText => _getHighestMagnitudeText(getHighestMagnitude(changes));

  String format() {
    final changelogBuffer = StringBuffer();

    // Group changes by magnitude and process them in order
    final changesByMagnitude = _groupByMagnitude();

    for (final magnitude in magnitudes) {
      if (!changesByMagnitude.containsKey(magnitude)) continue;

      changelogBuffer.writeln();
      changelogBuffer.writeln(_getMagnitudeHeader(magnitude));

      // Group by component and process them in alphabetical order
      final componentChanges = _groupByComponent(
        changesByMagnitude[magnitude]!,
      );
      final sortedComponents = componentChanges.keys.toList()..sort();
      for (final component in sortedComponents) {
        final firstChange = componentChanges[component]!.first;
        final componentObj = firstChange.component;
        final typeLabel = _getComponentTypeLabel(componentObj.type);
        final filePath = componentObj.filePath;
        final linkTarget = fileBaseUrl != null ? '$fileBaseUrl/$filePath' : filePath;

        changelogBuffer.writeln();
        changelogBuffer.writeln('**`${typeLabel.toLowerCase()}` $component** ([$filePath]($linkTarget))');

        // Group by category (i.e. type, operation, etc.) and process them
        final categorizedChanges = _groupByChangeCategory(componentChanges[component]!);
        final categories = categorizedChanges.keys.toList();
        for (final category in categories) {
          final changes = categorizedChanges[category]!;
          changelogBuffer.writeln("- ${_formatChanges(changes)}");
        }
      }
    }

    return "$changelogBuffer";
  }

  // Group changes by magnitude
  Map<ApiChangeMagnitude, List<ApiChange>> _groupByMagnitude() {
    return groupBy(changes, (change) => change.getMagnitude());
  }

  // Group changes by component
  Map<String, List<ApiChange>> _groupByComponent(List<ApiChange> changes) {
    return groupBy(changes, (change) => change.component.name);
  }

  // Group changes by generating a change category that considers the type,
  // operation (and other properties if needed)
  Map<int, List<ApiChange>> _groupByChangeCategory(List<ApiChange> changes) {
    return groupBy(
      changes,
      // calculate the "change category key" based on the change type, operation
      // and, for parameter changes, the parent (constructor/method) name
      (change) {
        var hashCode = change.runtimeType.hashCode ^ change.operation.hashCode;
        if (change is ConstructorParameterApiChange) {
          hashCode ^= change.constructor.name.hashCode;
        } else if (change is MethodParameterApiChange) {
          hashCode ^= change.method.name.hashCode;
        }
        return hashCode;
      },
    );
  }

  /// Format the result of the comparison
  String _getHighestMagnitudeText(ApiChangeMagnitude? highestMagnitude) {
    switch (highestMagnitude) {
      case ApiChangeMagnitude.major:
        return "💣 **Breaking changes detected.** Bump the major version.";
      case ApiChangeMagnitude.minor:
        return '✨ **Minor changes detected.** Increment the minor version.';
      case ApiChangeMagnitude.patch:
        return '👀 **Internal changes detected.** Increment the patch version.';
      default:
        return '🎉 **No API changes detected.** Increment the patch version.';
    }
  }

  /// Format a header for the magnitude section
  String _getMagnitudeHeader(ApiChangeMagnitude magnitude) {
    switch (magnitude) {
      case ApiChangeMagnitude.major:
        return '${'#' * markdownHeaderLevel} 💣 Breaking changes';
      case ApiChangeMagnitude.minor:
        return '${'#' * markdownHeaderLevel} ✨ Minor changes';
      case ApiChangeMagnitude.patch:
        return '${'#' * markdownHeaderLevel} 👀 Patch changes';
    }
  }

  /// Get the text representation of an operation using a prefix (e.g.
  /// "Properties", "Params", etc. depending on the type of change)
  String _getOperationText(
    ApiChangeOperation operation, {
    required String prefix,
  }) {
    switch (operation) {
      case ApiChangeOperation.added:
        return '❇️ $prefix added';
      case ApiChangeOperation.removed:
        return '❌ $prefix removed';
      case ApiChangeOperation.becameOptional:
        return '✅ $prefix became optional';
      case ApiChangeOperation.becameNullSafe:
        return '✅ $prefix became null safe';
      case ApiChangeOperation.becameRequired:
        return '⚠️ $prefix became required';
      case ApiChangeOperation.becameNullUnsafe:
        return '⚠️ $prefix became null unsafe';
      case ApiChangeOperation.becameNamed:
        return '🔠 $prefix became named';
      case ApiChangeOperation.becamePositional:
        return '🔢 $prefix became positional';
      case ApiChangeOperation.renamed:
        return '✏️ $prefix renamed';
      case ApiChangeOperation.typeChanged:
        return '🔄 $prefix type changed';
      case ApiChangeOperation.annotationAdded:
        return '➕ $prefix annotation added';
      case ApiChangeOperation.annotationRemoved:
        return '➖ $prefix annotation removed';
      case ApiChangeOperation.superClassChanged:
        return '🔄 Superclass changed';
      case ApiChangeOperation.interfaceAdded:
        return '➕ Interface added';
      case ApiChangeOperation.interfaceRemoved:
        return '➖ Interface removed';
      case ApiChangeOperation.mixinAdded:
        return '➕ Mixin added';
      case ApiChangeOperation.mixinRemoved:
        return '➖ Mixin removed';
      default:
        return '';
    }
  }

  /// Format similar changes into a single line
  String _formatChanges(List<ApiChange> changes) {
    // we can rely that all changes are of the same operation
    final operation = changes.first.operation;
    if (changes.every((c) => c is PropertyApiChange)) {
      final prefix = changes.length > 1 ? 'Properties' : 'Property';
      final text = _getOperationText(operation, prefix: prefix);

      if (operation == ApiChangeOperation.annotationAdded || operation == ApiChangeOperation.annotationRemoved) {
        final details = changes.map((c) => '`${(c as PropertyApiChange).property.name}` (${c.annotation})').join(', ');
        return '$text: $details';
      }

      final props = changes.map((c) => (c as PropertyApiChange).property.name).toList();
      return '$text: `${props.join('`, `')}`';
    }

    if (changes.every((c) => c is MethodApiChange)) {
      final firstChange = changes.first as MethodApiChange;
      final isFunction = firstChange.component.type == DocComponentType.functionType;
      final prefix =
          isFunction ? (changes.length > 1 ? 'Functions' : 'Function') : (changes.length > 1 ? 'Methods' : 'Method');
      final text = _getOperationText(operation, prefix: prefix);

      if (operation == ApiChangeOperation.annotationAdded || operation == ApiChangeOperation.annotationRemoved) {
        final details = changes.map((c) => '`${(c as MethodApiChange).method.name}` (${c.annotation})').join(', ');
        return '$text: $details';
      }

      if (operation == ApiChangeOperation.typeChanged) {
        final details = changes.map((c) {
          final change = c as MethodApiChange;
          return '`${change.method.name}` (${change.method.returnType} -> ${change.newType})';
        }).join(', ');
        return '$text: $details';
      }

      final methods = changes.map((c) => (c as MethodApiChange).method.name).toList();
      return '$text: `${methods.join('`, `')}`';
    }

    if (changes.every((c) => c is ConstructorParameterApiChange)) {
      final prefix = changes.length > 1 ? 'Params' : 'Param';
      final text = _getOperationText(operation, prefix: prefix);

      final constructor = (changes.first as ConstructorParameterApiChange).constructor.name;
      String constructorLabel;
      if (constructor == 'new' || constructor.isEmpty) {
        constructorLabel = "default constructor";
      } else {
        constructorLabel = "constructor `$constructor`";
      }
      if (constructor.startsWith('_')) {
        constructorLabel = "private $constructorLabel";
      }

      if (operation == ApiChangeOperation.annotationAdded || operation == ApiChangeOperation.annotationRemoved) {
        final details = changes.map((c) {
          final change = c as ConstructorParameterApiChange;
          return '`${change.parameter.name}` (${change.annotation})';
        }).join(', ');
        return '$text in $constructorLabel: $details';
      }

      if (operation == ApiChangeOperation.renamed) {
        final details = changes.map((c) {
          final change = c as ConstructorParameterApiChange;
          return '`${change.oldName} -> ${change.parameter.name}`';
        }).join(', ');
        return '$text in $constructorLabel: $details';
      }

      final params = changes.map((c) {
        final change = c as ConstructorParameterApiChange;
        final param = change.parameter;
        final buffer = StringBuffer(param.name);
        if (param.named) {
          buffer.write(' (named');
        } else {
          buffer.write(' (positional');
        }

        if (param.required) {
          buffer.write(', required)');
        } else {
          buffer.write(', optional');
          if (param.defaultValue != null) {
            buffer.write(', default: ${param.defaultValue}');
          }
          buffer.write(')');
        }
        return buffer.toString();
      }).toList();

      return '$text in $constructorLabel: `${params.join('`, `')}`';
    }

    if (changes.every((c) => c is MethodParameterApiChange)) {
      final firstChange = changes.first as MethodParameterApiChange;
      final isFunction = firstChange.component.type == DocComponentType.functionType;
      final prefix = changes.length > 1 ? 'Params' : 'Param';
      final text = _getOperationText(operation, prefix: prefix);

      if (operation == ApiChangeOperation.annotationAdded || operation == ApiChangeOperation.annotationRemoved) {
        final details = changes.map((c) {
          final change = c as MethodParameterApiChange;
          return '`${change.parameter.name}` (${change.annotation})';
        }).join(', ');
        final method = (changes.first as MethodParameterApiChange).method.name;
        final label = isFunction ? 'function' : 'method';
        return '$text in $label `$method`: $details';
      }

      if (operation == ApiChangeOperation.renamed) {
        final details = changes.map((c) {
          final change = c as MethodParameterApiChange;
          return '`${change.oldName} -> ${change.parameter.name}`';
        }).join(', ');
        final method = (changes.first as MethodParameterApiChange).method.name;
        final label = isFunction ? 'function' : 'method';
        return '$text in $label `$method`: $details';
      }

      final params = changes.map((c) {
        final change = c as MethodParameterApiChange;
        final param = change.parameter;
        final buffer = StringBuffer(param.name);
        if (param.named) {
          buffer.write(' (named');
        } else {
          buffer.write(' (positional');
        }

        if (param.required) {
          buffer.write(', required)');
        } else {
          buffer.write(', optional');
          if (param.defaultValue != null) {
            buffer.write(', default: ${param.defaultValue}');
          }
          buffer.write(')');
        }
        return buffer.toString();
      }).toList();

      final method = (changes.first as MethodParameterApiChange).method.name;
      final label = isFunction ? 'function' : 'method';
      return '$text in $label `$method`: `${params.join('`, `')}`';
    }

    if (changes.every((c) => c is ConstructorApiChange)) {
      // This should always be a single change, so we use singular:
      final text = _getOperationText(operation, prefix: 'Constructor');

      if (operation == ApiChangeOperation.annotationAdded || operation == ApiChangeOperation.annotationRemoved) {
        final details =
            changes.map((c) => '`${(c as ConstructorApiChange).constructor.name}` (${c.annotation})').join(', ');
        return '$text: $details';
      }

      final constructors = changes.map((c) => (c as ConstructorApiChange).constructor.name).toList();
      return '$text: `${constructors.join('`, `')}`';
    }

    if (changes.every((c) => c is ComponentApiChange)) {
      // This should always be a single change, so we use singular:
      final component = (changes.first as ComponentApiChange).component;
      final prefix = _getComponentTypeLabel(component.type);
      final text = _getOperationText(operation, prefix: prefix);

      if (operation == ApiChangeOperation.annotationAdded || operation == ApiChangeOperation.annotationRemoved) {
        final details =
            changes.map((c) => '`${(c as ComponentApiChange).component.name}` (${c.annotation})').join(', ');
        return '$text: $details';
      }

      if (operation == ApiChangeOperation.superClassChanged ||
          operation == ApiChangeOperation.interfaceAdded ||
          operation == ApiChangeOperation.interfaceRemoved ||
          operation == ApiChangeOperation.mixinAdded ||
          operation == ApiChangeOperation.mixinRemoved) {
        final details = changes.map((c) => '`${(c as ComponentApiChange).changedValue}`').join(', ');
        return '$text: $details';
      }

      final components = changes.map((c) => (c as ComponentApiChange).component).toList();
      return '$text: `${components.map((c) => c.name).join('`, `')}`';
    }

    // This should actually never happen:
    return '${changes.length} unknown changes';
  }

  String _getComponentTypeLabel(DocComponentType type) {
    switch (type) {
      case DocComponentType.classType:
        return 'Class';
      case DocComponentType.functionType:
        return 'Function';
      case DocComponentType.mixinType:
        return 'Mixin';
      case DocComponentType.enumType:
        return 'Enum';
      case DocComponentType.typedefType:
        return 'Typedef';
      case DocComponentType.extensionType:
        return 'Extension';
    }
  }
}
