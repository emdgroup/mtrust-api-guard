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
  final bool? isPublic;
  final List<String>? elementKind;

  OverrideSelection({
    this.isPublic,
    this.elementKind,
  });

  factory OverrideSelection.fromMap(Map<String, dynamic> map) {
    return OverrideSelection(
      isPublic: map['is_public'] as bool?,
      elementKind: (map['element_kind'] as List?)?.cast<String>(),
    );
  }
}
