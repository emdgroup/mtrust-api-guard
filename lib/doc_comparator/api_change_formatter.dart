import 'package:collection/collection.dart';
import 'package:mtrust_api_guard/mtrust_api_guard.dart';

enum ApiChangeTarget {
  property,
  method,
  function,
  constructor,
  parameter,
  component, // For generic component
  ;

  String text({bool isPlural = false}) {
    switch (this) {
      case ApiChangeTarget.property:
        return isPlural ? 'Properties' : 'Property';
      case ApiChangeTarget.method:
        return isPlural ? 'Methods' : 'Method';
      case ApiChangeTarget.function:
        return isPlural ? 'Functions' : 'Function';
      case ApiChangeTarget.constructor:
        return isPlural ? 'Constructors' : 'Constructor';
      case ApiChangeTarget.parameter:
        return isPlural ? 'Params' : 'Param';
      case ApiChangeTarget.component:
        return isPlural ? 'Components' : 'Component';
    }
  }
}

/// Formatter to display API changes in a hierarchical format
class ApiChangeFormatter {
  final List<ApiChange> changes;

  final Set<ApiChangeMagnitude> magnitudes;

  final int markdownHeaderLevel;

  final String? Function(String filePath)? fileUrlBuilder;

  ApiChangeFormatter(
    this.changes, {
    this.markdownHeaderLevel = 1,
    this.magnitudes = const {
      ApiChangeMagnitude.major,
      ApiChangeMagnitude.minor,
      ApiChangeMagnitude.patch,
    },
    this.fileUrlBuilder,
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
        final linkTarget =
            (fileUrlBuilder != null && filePath != null) ? fileUrlBuilder!(filePath) ?? filePath : filePath;

        changelogBuffer.writeln();
        if (filePath != null) {
          changelogBuffer
              .writeln('**`${typeLabel.toLowerCase()}` ${componentObj.genericName}** ([$filePath]($linkTarget))');
        } else {
          changelogBuffer.writeln('**`${typeLabel.toLowerCase()}` ${componentObj.genericName}**');
        }

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
  Map<String, List<ApiChange>> _groupByChangeCategory(List<ApiChange> changes) {
    return groupBy(
      changes,
      // calculate the "change category key" based on the change type, operation
      // and, for parameter changes, the parent (constructor/method) name
      (change) {
        var key = '${change.runtimeType}-${change.operation}';
        if (change is ConstructorParameterApiChange) {
          key += '-${change.constructor.name}';
        } else if (change is MethodParameterApiChange) {
          key += '-${change.method.name}';
        } else if (change.operation == ApiChangeOperation.featureAdded ||
            change.operation == ApiChangeOperation.featureRemoved) {
          if (change.changedValue != null) {
            key += '-${change.changedValue}';
          }
        }
        return key;
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
  String _getOperationDescription(
    ApiChangeOperation operation,
    ApiChangeTarget target, {
    bool isPlural = false,
    String? changedValue,
    String? componentLabel,
  }) {
    final label = componentLabel ?? target.text(isPlural: isPlural);

    switch (operation) {
      case ApiChangeOperation.added:
        return '❇️ $label added';
      case ApiChangeOperation.removed:
        return '❌ $label removed';
      case ApiChangeOperation.becameOptional:
        return '✅ $label became optional';
      case ApiChangeOperation.becameNullSafe:
        return '✅ $label became null safe';
      case ApiChangeOperation.becameRequired:
        return '⚠️ $label became required';
      case ApiChangeOperation.becameNullUnsafe:
        return '⚠️ $label became null unsafe';
      case ApiChangeOperation.becameNamed:
        return '🔠 $label became named';
      case ApiChangeOperation.becamePositional:
        return '🔢 $label became positional';
      case ApiChangeOperation.reordered:
        return '🔢 $label reordered';
      case ApiChangeOperation.renamed:
        return '✏️ $label renamed';
      case ApiChangeOperation.typeChanged:
        return '🔄 $label type changed';
      case ApiChangeOperation.annotationAdded:
        return '➕ $label annotation added';
      case ApiChangeOperation.annotationRemoved:
        return '➖ $label annotation removed';
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
      case ApiChangeOperation.typeParametersChanged:
        return '🔄 Type parameters changed';
      case ApiChangeOperation.dependencyAdded:
        return '📦 Dependency added';
      case ApiChangeOperation.dependencyRemoved:
        return '📦 Dependency removed';
      case ApiChangeOperation.dependencyChanged:
        return '📦 Dependency changed';
      case ApiChangeOperation.platformConstraintChanged:
        return '📱 Platform constraint changed';
      case ApiChangeOperation.featureAdded:
        return '❇️ Modifier `$changedValue` added to ${label.toLowerCase()}';
      case ApiChangeOperation.featureRemoved:
        return '❌ Modifier `$changedValue` removed from ${label.toLowerCase()}';
      default:
        return '';
    }
  }

  String _formatTypeChange(DocType oldType, DocType newType) {
    if (oldType.isAssignableTo(newType)) {
      return '(`$oldType` → `$newType`, widened)';
    } else if (newType.isAssignableTo(oldType)) {
      return '(`$oldType` → `$newType`, narrowed)';
    } else {
      return '(`$oldType` → `$newType`)';
    }
  }

  /// Format similar changes into a single line
  String _formatChanges(List<ApiChange> changes) {
    // we can rely that all changes are of the same operation
    final operation = changes.first.operation;
    if (changes.every((c) => c is PropertyApiChange)) {
      final isPlural = changes.length > 1;
      final text = _getOperationDescription(
        operation,
        ApiChangeTarget.property,
        isPlural: isPlural,
        changedValue: changes.first.changedValue,
      );

      if (operation == ApiChangeOperation.annotationAdded || operation == ApiChangeOperation.annotationRemoved) {
        final details = changes.map((c) => '`${(c as PropertyApiChange).property.name}` (${c.annotation})').join(', ');
        return '$text: $details';
      }

      if (operation == ApiChangeOperation.featureAdded || operation == ApiChangeOperation.featureRemoved) {
        final details = changes.map((c) => '`${(c as PropertyApiChange).property.name}`').join(', ');
        return '$text: $details';
      }

      final props = changes.map((c) => (c as PropertyApiChange).property.name).toList();
      return '$text: `${props.join('`, `')}`';
    }

    if (changes.every((c) => c is MethodApiChange)) {
      final firstChange = changes.first as MethodApiChange;
      final isFunction = firstChange.component.type == DocComponentType.functionType;
      final isPlural = changes.length > 1;
      final target = isFunction ? ApiChangeTarget.function : ApiChangeTarget.method;

      final text = _getOperationDescription(
        operation,
        target,
        isPlural: isPlural,
        changedValue: firstChange.changedValue,
      );

      if (operation == ApiChangeOperation.annotationAdded || operation == ApiChangeOperation.annotationRemoved) {
        final details = changes.map((c) => '`${(c as MethodApiChange).method.name}` (${c.annotation})').join(', ');
        return '$text: $details';
      }

      if (operation == ApiChangeOperation.featureAdded || operation == ApiChangeOperation.featureRemoved) {
        final details = changes.map((c) => '`${(c as MethodApiChange).method.name}`').join(', ');
        return '$text: $details';
      }

      if (operation == ApiChangeOperation.typeChanged) {
        final details = changes.map((c) {
          final change = c as MethodApiChange;
          return '`${change.method.name}` ${_formatTypeChange(change.method.returnType, change.newType!)}';
        }).join(', ');
        return '$text: $details';
      }

      if (operation == ApiChangeOperation.typeParametersChanged) {
        final details = changes.map((c) {
          final change = c as MethodApiChange;
          return '`${change.method.name}` (${change.changedValue})';
        }).join(', ');
        return '$text: $details';
      }

      final methods = changes.map((c) => (c as MethodApiChange).method.name).toList();
      return '$text: `${methods.join('`, `')}`';
    }

    if (changes.every((c) => c is ConstructorParameterApiChange)) {
      final isPlural = changes.length > 1;
      final text = _getOperationDescription(operation, ApiChangeTarget.parameter, isPlural: isPlural);

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
          return '`${change.oldName}` → `${change.parameter.name}`';
        }).join(', ');
        return '$text in $constructorLabel: $details';
      }

      if (operation == ApiChangeOperation.typeChanged) {
        final details = changes.map((c) {
          final change = c as ConstructorParameterApiChange;
          return '`${change.parameter.name}` ${_formatTypeChange(change.parameter.type, change.newType!)}';
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
      final isPlural = changes.length > 1;
      final text = _getOperationDescription(operation, ApiChangeTarget.parameter, isPlural: isPlural);

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
          return '`${change.oldName}` → `${change.parameter.name}`';
        }).join(', ');
        final method = (changes.first as MethodParameterApiChange).method.name;
        final label = isFunction ? 'function' : 'method';
        return '$text in $label `$method`: $details';
      }

      if (operation == ApiChangeOperation.typeChanged) {
        final details = changes.map((c) {
          final change = c as MethodParameterApiChange;
          return '`${change.parameter.name}` ${_formatTypeChange(change.parameter.type, change.newType!)}';
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
      final isPlural = changes.length > 1;
      final text = _getOperationDescription(
        operation,
        ApiChangeTarget.constructor,
        isPlural: isPlural,
        changedValue: changes.first.changedValue,
      );

      if (operation == ApiChangeOperation.annotationAdded || operation == ApiChangeOperation.annotationRemoved) {
        final details =
            changes.map((c) => '`${(c as ConstructorApiChange).constructor.name}` (${c.annotation})').join(', ');
        return '$text: $details';
      }

      if (operation == ApiChangeOperation.featureAdded || operation == ApiChangeOperation.featureRemoved) {
        final details = changes.map((c) => '`${(c as ConstructorApiChange).constructor.name}`').join(', ');
        return '$text: $details';
      }

      final constructors = changes.map((c) => (c as ConstructorApiChange).constructor.name).toList();
      return '$text: `${constructors.join('`, `')}`';
    }

    if (changes.every((c) => c is ComponentApiChange)) {
      // This should always be a single change, so we use singular:
      final component = (changes.first as ComponentApiChange).component;
      final prefix = _getComponentTypeLabel(component.type);
      final isPlural = changes.length > 1;
      final text =
          _getOperationDescription(operation, ApiChangeTarget.component, isPlural: isPlural, componentLabel: prefix);

      if (operation == ApiChangeOperation.annotationAdded || operation == ApiChangeOperation.annotationRemoved) {
        final details =
            changes.map((c) => '`${(c as ComponentApiChange).component.name}` (${c.annotation})').join(', ');
        return '$text: $details';
      }

      if (operation == ApiChangeOperation.superClassChanged ||
          operation == ApiChangeOperation.interfaceAdded ||
          operation == ApiChangeOperation.interfaceRemoved ||
          operation == ApiChangeOperation.mixinAdded ||
          operation == ApiChangeOperation.mixinRemoved ||
          operation == ApiChangeOperation.typeParametersChanged ||
          operation == ApiChangeOperation.dependencyChanged ||
          operation == ApiChangeOperation.platformConstraintChanged) {
        final details = changes.map((c) => '${(c as ComponentApiChange).changedValue}').join(', ');
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
      case DocComponentType.dependencyType:
        return 'Dependency';
      case DocComponentType.platformConstraintType:
        return 'Platform Constraint';
    }
  }
}
