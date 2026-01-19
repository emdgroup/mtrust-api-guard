/// Represents a configured override for a specific rule.
class MagnitudeOverride {
  final List<String> operations;
  final String magnitude;
  final OverrideSelection? selection;
  final String? description;

  MagnitudeOverride({
    required this.operations,
    required this.magnitude,
    this.selection,
    this.description,
  });

  factory MagnitudeOverride.fromMap(Map<String, dynamic> map) {
    var ops = OverrideSelection._parseListOrString(map['operation']);

    return MagnitudeOverride(
      operations: ops ?? ['*'], // Default to wildcard if missing
      magnitude: map['magnitude'] as String,
      selection: map['selection'] != null
          ? OverrideSelection.fromMap(Map<String, dynamic>.from(map['selection'] as Map))
          : null,
      description: map['description'] as String?,
    );
  }

  @override
  toString() {
    return 'MagnitudeOverride(operations: $operations, magnitude: $magnitude, selection: $selection, description: $description)';
  }
}

/// Defines criteria for selecting elements (e.g., public methods in mixins).
class OverrideSelection {
  final List<String>? entity;
  final String? namePattern;
  final List<String>? hasAnnotation;
  final List<String>? subtypeOf;
  final List<String>? fromPackage;
  final OverrideSelection? enclosing;

  OverrideSelection({
    this.entity,
    this.namePattern,
    this.hasAnnotation,
    this.subtypeOf,
    this.fromPackage,
    this.enclosing,
  });

  factory OverrideSelection.fromMap(Map<String, dynamic> map) {
    return OverrideSelection(
      entity: _parseListOrString(map['entity']) ?? _parseListOrString(map['element_kind']),
      namePattern: map['name_pattern'] as String?,
      hasAnnotation: _parseListOrString(map['has_annotation']),
      subtypeOf: _parseListOrString(map['subtype_of']),
      fromPackage: _parseListOrString(map['from_package']),
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
    return 'OverrideSelection(entity: $entity, namePattern: $namePattern, hasAnnotation: $hasAnnotation, subtypeOf: $subtypeOf, fromPackage: $fromPackage, enclosing: $enclosing)';
  }
}
