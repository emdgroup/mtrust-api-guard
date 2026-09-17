part 'model.g.dart';

class Model {
  Model(this.value);

  /// Read only by the generated part.
  final int value;

  factory Model.fromMap(Map<String, dynamic> map) => _$ModelFromMap(map);

  Map<String, dynamic> toMap() => _$ModelToMap(this);
}

/// Serialized the way `json_serializable` does it, and used by nothing but its
/// own generated code.
class Draft {
  Draft(this.value);

  final int value;

  factory Draft.fromJson(Map<String, dynamic> json) => _$DraftFromJson(json);

  Map<String, dynamic> toJson() => _$DraftToJson(this);
}
