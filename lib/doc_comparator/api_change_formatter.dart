import 'package:collection/collection.dart';
import 'package:mtrust_api_guard/doc_comparator/api_change_formatting_extensions.dart';
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
    }
  }

  /// Format similar changes into a single line
  String _formatChanges(List<ApiChange> changes) {
    return changes.formatAsGroup();
  }
}
