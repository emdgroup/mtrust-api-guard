import 'package:collection/collection.dart';
import 'package:mtrust_api_guard/mtrust_api_guard.dart';

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
        final typeLabel = componentObj.type.name.replaceAll("Type", "").toLowerCase();
        final filePath = componentObj.filePath;

        final linkTarget =
            (fileUrlBuilder != null && filePath != null) ? fileUrlBuilder!(filePath) ?? filePath : filePath;

        changelogBuffer.writeln();
        changelogBuffer.writeln(
          '**`${typeLabel.toLowerCase()}` ${componentObj.genericName}** '
          '${filePath != null ? '([$filePath]($linkTarget))' : ''}',
        );

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
        } else if (change.operation == ApiChangeOperation.featureAddition ||
            change.operation == ApiChangeOperation.featureRemoval) {
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
      default:
        return '';
    }
  }

  /// Format similar changes into a single line
  String _formatChanges(List<ApiChange> changes) {
    return changes.formatAsGroup();
  }
}

/// Shared formatting utilities for all API changes
extension ApiChangeFormattingHelpers on List<ApiChange> {
  /// Get the operation text with emoji and derived entity name
  String formatAsGroup() {
    if (isEmpty) return '';

    // throw Error if mixed types or operations
    if (length > 1) {
      final type = first.runtimeType;
      final operation = first.operation;
      for (final change in this) {
        if (change.runtimeType != type || change.operation != operation) {
          throw StateError('Cannot format mixed change types or operations as group.');
        }
      }
    }

    final change = first;
    final entityName = _formatEntity();

    switch (change.operation) {
      case ApiChangeOperation.addition:
        if (change is ParameterApiChange) {
          return '❇️ $entityName added ${_formatParent()}: ${_formatChanges()}';
        }
        return '❇️ $entityName added: ${_formatChanges()}';

      case ApiChangeOperation.removal:
        if (change is ParameterApiChange) {
          return '❌ $entityName removed ${_formatParent()}: ${_formatChanges()}';
        }
        return '❌ $entityName removed: ${_formatChanges()}';

      case ApiChangeOperation.typeChange:
        if (change is ComponentApiChange && change.component.type == DocComponentType.typedefType) {
          return '🔄 Typedef type changed: ${change.component.name}';
        }
        if (change is MethodApiChange) {
          final isFunction = change.component.type == DocComponentType.functionType;
          return '🔄 ${isFunction ? "Function" : "Method"} type changed: ${_formatChanges()}';
        }
        if (change is ParameterApiChange) {
          return '🔄 Param type changed ${_formatParent()}: ${_formatChanges()}';
        }
        return '🔄 $entityName type changed: ${_formatChanges()}';

      case ApiChangeOperation.typeParametersChange:
        return '🔄 Type parameters changed: ${change.changedValue}';

      case ApiChangeOperation.annotationAddition:
        return '➕ $entityName annotation added: ${_formatAnnotations()}';

      case ApiChangeOperation.annotationRemoval:
        return '➖ $entityName annotation removed: ${_formatAnnotations()}';

      case ApiChangeOperation.featureAddition:
        return '❇️ Modifier `${change.changedValue}` added to ${entityName.toLowerCase()}: ${_formatChanges()}';

      case ApiChangeOperation.featureRemoval:
        return '❌ Modifier `${change.changedValue}` removed from ${entityName.toLowerCase()}: ${_formatChanges()}';

      case ApiChangeOperation.becomingOptional:
        return '✅ $entityName became optional ${_formatParent()}: ${_formatChanges()}';

      case ApiChangeOperation.becomingRequired:
        return '⚠️ $entityName became required ${_formatParent()}: ${_formatChanges()}';

      case ApiChangeOperation.becomingNullable:
        return '⚠️ $entityName became nullable ${_formatParent()}: ${_formatChanges()}';

      case ApiChangeOperation.becomingNonNullable:
        return '✅ $entityName became non-nullable ${_formatParent()}: ${_formatChanges()}';

      case ApiChangeOperation.becomingNamed:
        return '🔠 $entityName became named ${_formatParent()}: ${_formatChanges()}';

      case ApiChangeOperation.becomingPositional:
        return '🔢 $entityName became positional ${_formatParent()}: ${_formatChanges()}';

      case ApiChangeOperation.reordering:
        return '🔢 $entityName reordered ${_formatParent()}: ${_formatChanges()}';

      case ApiChangeOperation.renaming:
        if (change is ParameterApiChange) {
          return '✏️ $entityName renamed ${_formatParent()}: ${_formatChanges()}';
        }
        return '✏️ $entityName renamed: ${_formatChanges()}';

      case ApiChangeOperation.superClassChange:
        return '🔄 Superclass changed: ${change.changedValue}';

      case ApiChangeOperation.interfaceImplementation:
        return '➕ Interface added: ${_formatChangedValues()}';

      case ApiChangeOperation.interfaceRemoval:
        return '➖ Interface removed: ${_formatChangedValues()}';

      case ApiChangeOperation.mixinApplication:
        return '➕ Mixin added: ${_formatChangedValues()}';

      case ApiChangeOperation.mixinRemoval:
        return '➖ Mixin removed: ${_formatChangedValues()}';

      case ApiChangeOperation.dependencyAddition:
        return '📦 Dependency added: ${change.changedValue}';

      case ApiChangeOperation.dependencyRemoval:
        return '📦 Dependency removed: ${change.changedValue}';

      case ApiChangeOperation.dependencyVersionChange:
        return '📦 Dependency version changed: ${change.changedValue}';

      case ApiChangeOperation.minDartSdkVersionDecrease:
        return '🎯 Minimum Dart SDK version decreased: ${change.changedValue}';
      case ApiChangeOperation.minDartSdkVersionIncrease:
        return '🎯 Minimum Dart SDK version increased: ${change.changedValue}';
      case ApiChangeOperation.maxDartSdkVersionDecrease:
        return '🎯 Maximum Dart SDK version decreased: ${change.changedValue}';
      case ApiChangeOperation.maxDartSdkVersionIncrease:
        return '🎯 Maximum Dart SDK version increased: ${change.changedValue}';

      case ApiChangeOperation.minFlutterSdkVersionDecrease:
        return '🎯 Minimum Flutter SDK version decreased: ${change.changedValue}';
      case ApiChangeOperation.minFlutterSdkVersionIncrease:
        return '🎯 Minimum Flutter SDK version increased: ${change.changedValue}';
      case ApiChangeOperation.maxFlutterSdkVersionDecrease:
        return '🎯 Maximum Flutter SDK version decreased: ${change.changedValue}';
      case ApiChangeOperation.maxFlutterSdkVersionIncrease:
        return '🎯 Maximum Flutter SDK version increased: ${change.changedValue}';

      case ApiChangeOperation.minAndroidSdkVersionDecrease:
        return '🤖 Minimum Android SDK version decreased: ${change.changedValue}';
      case ApiChangeOperation.minAndroidSdkVersionIncrease:
        return '🤖 Minimum Android SDK version increased: ${change.changedValue}';
      case ApiChangeOperation.minIosSdkVersionDecrease:
        return '🍎 Minimum iOS SDK version decreased: ${change.changedValue}';
      case ApiChangeOperation.minIosSdkVersionIncrease:
        return '🍎 Minimum iOS SDK version increased: ${change.changedValue}';

      default:
        return '$entityName changed';
    }
  }

  String _formatParent() {
    if (first is ConstructorParameterApiChange) {
      final constructorChange = first as ConstructorParameterApiChange;
      final name = constructorChange.constructor.name;
      if (name == 'new' || name.isEmpty) return "in default constructor";
      if (name.startsWith('_')) return "in private constructor `\$name`";
      return "in constructor `$name`";
    } else if (first is MethodParameterApiChange) {
      final methodChange = first as MethodParameterApiChange;
      final isFunction = methodChange.component.type == DocComponentType.functionType;
      final methodType = isFunction ? 'function' : 'method';
      return 'in $methodType `${methodChange.method.name}`';
    }
    return '';
  }

  String _formatChangedValues() {
    return map((change) => change.changedValue).join(', ');
  }

  String _formatAnnotations() {
    return map((change) {
      var name = '';
      if (change is PropertyApiChange) {
        name = change.property.name;
      } else if (change is MethodApiChange) {
        name = change.method.name;
      } else if (change is ConstructorApiChange) {
        name = change.constructor.name;
      } else if (change is ComponentApiChange) {
        name = change.component.name;
      }
      return '`$name` (${change.annotation})';
    }).join(', ');
  }

  /// Get the appropriate entity name for this change type
  String _formatEntity() {
    final type = first.runtimeType;
    final isPlural = length > 1;
    if (type == PropertyApiChange) {
      return isPlural ? 'Properties' : 'Property';
    }
    if (type == MethodApiChange) {
      final methodChange = first as MethodApiChange;
      final isFunction = methodChange.component.type == DocComponentType.functionType;
      if (isFunction) {
        return isPlural ? 'Functions' : 'Function';
      }
      return isPlural ? 'Methods' : 'Method';
    }
    if (type == ConstructorApiChange) {
      return isPlural ? 'Constructors' : 'Constructor';
    }
    if (type == ComponentApiChange) {
      final componentChange = first as ComponentApiChange;
      switch (componentChange.component.type) {
        case DocComponentType.classType:
          return isPlural ? 'Classes' : 'Class';
        case DocComponentType.mixinType:
          return isPlural ? 'Mixins' : 'Mixin';
        case DocComponentType.extensionType:
          return isPlural ? 'Extensions' : 'Extension';
        case DocComponentType.enumType:
          return isPlural ? 'Enums' : 'Enum';
        case DocComponentType.typedefType:
          return isPlural ? 'Typedefs' : 'Typedef';
        case DocComponentType.functionType:
          return isPlural ? 'Functions' : 'Function';
        case DocComponentType.metaType:
          return isPlural ? 'Pubspecs' : 'Pubspec';
      }
    }
    // Else, parameter changes
    return isPlural ? 'Params' : 'Param';
  }

  String _formatChanges() {
    return map(
      (change) {
        var changes = '';
        if (change is PropertyApiChange) {
          changes = "`" + change.property.name + "`";
        } else if (change is MethodApiChange) {
          changes = "`" + change.method.name + "`";
          if (change.operation == ApiChangeOperation.typeChange) {
            changes = "`" + change.method.name + "` " + _formatTypeChange(change.method.returnType, change.newType!);
          }
        } else if (change is ConstructorApiChange) {
          changes = "`" + change.constructor.name + "`";
        } else if (change is ComponentApiChange) {
          changes = "`" + change.component.name + "`";
        } else if (change is ParameterApiChange) {
          changes = _formatParam(change.parameter);
          if (change.operation == ApiChangeOperation.renaming) {
            changes = "`" + change.oldName! + "` → `" + change.parameter.name + "`";
          } else if (change.operation == ApiChangeOperation.typeChange) {
            changes = "`" + change.parameter.name + "` " + _formatTypeChange(change.parameter.type, change.newType!);
          }
        }
        return changes;
      },
    ).join(', ');
  }

  String _formatParam(DocParameter parameter) {
    final buffer = StringBuffer("`${parameter.name}`");
    if (parameter.named) {
      buffer.write(' (named');
    } else {
      buffer.write(' (positional');
    }

    if (parameter.required) {
      buffer.write(', required)');
    } else {
      buffer.write(', optional');
      if (parameter.defaultValue != null) {
        buffer.write(', default: ${parameter.defaultValue}');
      }
      buffer.write(')');
    }
    return buffer.toString();
  }

  /// Format a type change with direction indicator
  String _formatTypeChange(DocType oldType, DocType newType) {
    if (oldType.isAssignableTo(newType)) {
      return '(`$oldType` → `$newType`, widened)';
    } else if (newType.isAssignableTo(oldType)) {
      return '(`$oldType` → `$newType`, narrowed)';
    } else {
      return '(`$oldType` → `$newType`)';
    }
  }
}
