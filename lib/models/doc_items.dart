import 'package:json_annotation/json_annotation.dart';

part 'doc_items.g.dart';

enum DocComponentType {
  @JsonValue('class')
  classType,
  @JsonValue('function')
  functionType,
}

@JsonSerializable()
class DocComponent {
  const DocComponent({
    required this.name,
    required this.isNullSafe,
    required this.description,
    required this.constructors,
    required this.properties,
    required this.methods,
    this.filePath,
    this.type = DocComponentType.classType,
  });

  final String? filePath;
  final String name;
  final bool isNullSafe;
  final String description;
  final List<DocConstructor> constructors;
  final List<DocProperty> properties;
  final List<DocMethod> methods;
  final DocComponentType type;

  factory DocComponent.fromJson(Map<String, dynamic> json) => _$DocComponentFromJson(json);

  Map<String, dynamic> toJson() => _$DocComponentToJson(this);
}

@JsonSerializable()
class DocProperty {
  const DocProperty({
    required this.name,
    required this.type,
    required this.description,
    required this.features,
  });

  final String name;
  final String type;
  final String description;
  final List<String> features;

  factory DocProperty.fromJson(Map<String, dynamic> json) => _$DocPropertyFromJson(json);

  Map<String, dynamic> toJson() => _$DocPropertyToJson(this);
}

@JsonSerializable()
class DocConstructor {
  const DocConstructor({
    required this.name,
    required this.signature,
    required this.features,
  });

  final String name;
  final List<DocParameter> signature;
  final List<String> features;

  factory DocConstructor.fromJson(Map<String, dynamic> json) => _$DocConstructorFromJson(json);

  Map<String, dynamic> toJson() => _$DocConstructorToJson(this);
}

@JsonSerializable()
class DocParameter {
  const DocParameter({
    required this.name,
    required this.type,
    required this.description,
    required this.named,
    required this.required,
    this.defaultValue,
  });

  final String name;
  final String description;
  final String type;
  final bool named;
  final bool required;
  final String? defaultValue;

  factory DocParameter.fromJson(Map<String, dynamic> json) => _$DocParameterFromJson(json);

  Map<String, dynamic> toJson() => _$DocParameterToJson(this);
}

@JsonSerializable()
class DocMethod {
  const DocMethod({
    required this.name,
    required this.returnType,
    required this.signature,
    required this.features,
    required this.description,
  });

  final String name;
  final String returnType;
  final List<DocParameter> signature;
  final List<String> features;
  final String description;

  factory DocMethod.fromJson(Map<String, dynamic> json) => _$DocMethodFromJson(json);

  Map<String, dynamic> toJson() => _$DocMethodToJson(this);
}
