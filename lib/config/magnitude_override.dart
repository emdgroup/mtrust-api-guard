/// Represents a configured override for a specific rule.
class MagnitudeOverride {
  final String rule;
  final String magnitude;
  final String? operation;
  final OverrideSelection? selection;

  MagnitudeOverride({
    required this.rule,
    required this.magnitude,
    this.operation,
    this.selection,
  });

  factory MagnitudeOverride.fromMap(Map<String, dynamic> map) {
    return MagnitudeOverride(
      rule: map['rule'] as String,
      magnitude: map['magnitude'] as String,
      operation: map['operation'] as String?,
      selection: map['selection'] != null
          ? OverrideSelection.fromMap(Map<String, dynamic>.from(map['selection'] as Map))
          : null,
    );
  }

  @override
  toString() {
    return 'MagnitudeOverride(rule: $rule, magnitude: $magnitude, operation: $operation, selection: $selection)';
  }
}

/// Defines criteria for selecting elements (e.g., public methods in mixins).
class OverrideSelection {
  final List<String>? elementKind;
  final String? namePattern;
  final List<String>? hasAnnotation;
  final OverrideSelection? enclosing;

  OverrideSelection({
    this.elementKind,
    this.namePattern,
    this.hasAnnotation,
    this.enclosing,
  });

  factory OverrideSelection.fromMap(Map<String, dynamic> map) {
    return OverrideSelection(
      elementKind: _parseListOrString(map['element_kind']),
      namePattern: map['name_pattern'] as String?,
      hasAnnotation: _parseListOrString(map['has_annotation']),
      enclosing: map['enclosing'] != null
          ? OverrideSelection.fromMap(Map<String, dynamic>.from(map['enclosing'] as Map))
          : null,
    );
  }

  static List<String>? _parseListOrString(dynamic value) {
    if (value == null) return null;
    if (value is String) return [value];
    if (value is List) return value.map((e) => e.toString()).toList();
    return null;
  }

  @override
  String toString() {
    return 'OverrideSelection(elementKind: $elementKind, namePattern: $namePattern, hasAnnotation: $hasAnnotation, enclosing: $enclosing)';
  }
}
