import 'package:json_annotation/json_annotation.dart';

part 'doc_type.g.dart';

@JsonSerializable()
class DocType {
  final String name;
  final List<String> superTypes;
  final bool isNullable;

  const DocType({
    required this.name,
    this.superTypes = const [],
    this.isNullable = false,
  });

  factory DocType.fromJson(Map<String, dynamic> json) => _$DocTypeFromJson(json);

  Map<String, dynamic> toJson() => _$DocTypeToJson(this);

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocType && runtimeType == other.runtimeType && name == other.name && isNullable == other.isNullable;

  @override
  int get hashCode => name.hashCode ^ isNullable.hashCode;

  /// Returns true if this type is assignable to [other].
  ///
  /// This is a simplified check. It returns true if:
  /// 1. The types are equal.
  /// 2. [other] is a supertype of this type.
  /// 3. [other] is nullable and this type is not nullable (and satisfies 1 or 2).
  ///
  /// Note: This does not handle generic type arguments deep comparison yet.
  bool isAssignableTo(DocType other) {
    if (other.name == 'dynamic' || other.name == 'Object?') return true;

    // If target is not nullable, but source is, it's not assignable (unless source is Null and target is nullable, but here source is nullable type)
    if (!other.isNullable && isNullable) return false;

    if (name == other.name) return true;

    return superTypes.contains(other.name);
  }
}
