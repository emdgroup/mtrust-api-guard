import 'package:collection/collection.dart';
import 'package:mtrust_api_guard/mtrust_api_guard.dart';

/// Formatter to display API changes in a hierarchical format
class ApiChangeFormatter {
  final List<ApiChange> changes;

  final Set<ApiChangeMagnitude> magnitudes;

  final int markdownHeaderLevel;

  ApiChangeFormatter(
    this.changes, {
    this.markdownHeaderLevel = 1,
    this.magnitudes = const {
      ApiChangeMagnitude.major,
      ApiChangeMagnitude.minor,
      ApiChangeMagnitude.patch,
    },
  });

  String get highestMagnitudeText =>
      _getHighestMagnitudeText(getHighestMagnitude(changes));

  String format() {
    final changelogBuffer = StringBuffer();

    // Group changes by magnitude and process them in order
    final changesByMagnitude = _groupByMagnitude();

    for (final magnitude in magnitudes) {
      if (!changesByMagnitude.containsKey(magnitude)) continue;

      changelogBuffer.writeln(_getMagnitudeHeader(magnitude));

      // Group by component and process them in alphabetical order
      final componentChanges = _groupByComponent(
        changesByMagnitude[magnitude]!,
      );
      final sortedComponents = componentChanges.keys.toList()..sort();
      for (final component in sortedComponents) {
        changelogBuffer.writeln();
        changelogBuffer.writeln(
            '**$component** (${componentChanges[component]!.first.component.filePath})');

        // Group by category (i.e. type, operation, etc.) and process them
        final categorizedChanges =
            _groupByChangeCategory(componentChanges[component]!);
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
      (change) =>
          // calculate the "change category key" based on the change type, operation
          // and, for constructor parameters, the constructor name
          change.runtimeType.hashCode ^
          change.operation.hashCode ^
          (this is ConstructorParameterApiChange
              ? (this as ConstructorParameterApiChange)
                  .constructor
                  .name
                  .hashCode
              : 0),
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
      case ApiChangeOperation.typeChanged:
        return '🔄 $prefix type changed';
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
      final props =
          changes.map((c) => (c as PropertyApiChange).property.name).toList();
      return '$text: `${props.join('`, `')}`';
    }

    if (changes.every((c) => c is ConstructorParameterApiChange)) {
      final prefix = changes.length > 1 ? 'Params' : 'Param';
      final text = _getOperationText(operation, prefix: prefix);
      final params = changes
          .map((c) => (c as ConstructorParameterApiChange).parameter.name)
          .toList();
      final constructor =
          (changes.first as ConstructorParameterApiChange).constructor.name;
      final constructorLabel =
          "${constructor.startsWith("_") ? "private " : ""}"
          "constructor${constructor.isEmpty ? '' : " $constructor"}";
      return '$text in $constructorLabel: `${params.join('`, `')}`';
    }

    if (changes.every((c) => c is ConstructorApiChange)) {
      // This should always be a single change, so we use singular:
      final text = _getOperationText(operation, prefix: 'Constructor');
      final constructors = changes
          .map((c) => (c as ConstructorApiChange).constructor.name)
          .toList();
      return '$text: `${constructors.join('`, `')}`';
    }

    if (changes.every((c) => c is ComponentApiChange)) {
      // This should always be a single change, so we use singular:
      final text = _getOperationText(operation, prefix: 'Class');
      final components =
          changes.map((c) => (c as ComponentApiChange).component).toList();
      return '$text: `${components.map((c) => c.name).join('`, `')}`';
    }

    // This should actually never happen:
    return '${changes.length} unknown changes';
  }
}
