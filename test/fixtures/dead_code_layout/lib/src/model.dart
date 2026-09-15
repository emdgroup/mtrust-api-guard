part 'model.g.dart';

class Model {
  Model(this.value);

  /// Read only by the generated part.
  final int value;

  factory Model.fromMap(Map<String, dynamic> map) => _$ModelFromMap(map);

  Map<String, dynamic> toMap() => _$ModelToMap(this);
}
