import 'package:json_annotation/json_annotation.dart';
import 'package:mtrust_api_guard/models/doc_type.dart';

part 'doc_items.g.dart';

enum DocComponentType {
  @JsonValue('class')
  classType,
  @JsonValue('function')
  functionType,
  @JsonValue('mixin')
  mixinType,
  @JsonValue('enum')
  enumType,
  @JsonValue('typedef')
  typedefType,
  @JsonValue('extension')
  extensionType,
  @JsonValue('meta')
  metaType,
}

@JsonSerializable()
class DocComponent {
  const DocComponent({
    required this.name,
    required this.description,
    required this.constructors,
    required this.properties,
    required this.methods,
    this.filePath,
    this.entryPoint,
    this.type = DocComponentType.classType,
    this.aliasedType,
    this.annotations = const [],
    this.superClasses = const [],
    this.superClassPackages = const [],
    this.interfaces = const [],
    this.mixins = const [],
    this.typeParameters = const [],
  });

  /// The relative path to the file that defines this component.
  final String? filePath;

  /// The entry point that exposed this component (optional).
  final String? entryPoint;
  final String name;
  final String description;
  final List<DocConstructor> constructors;
  final List<DocProperty> properties;
  final List<DocMethod> methods;
  final DocComponentType type;
  final String? aliasedType;
  final List<String> annotations;
  final List<String> superClasses;
  final List<String> superClassPackages;
  final List<String> interfaces;
  final List<String> mixins;
  final List<String> typeParameters;

  factory DocComponent.fromJson(Map<String, dynamic> json) => _$DocComponentFromJson(json);

  factory DocComponent.meta({
    required String name,
    required String description,
    String? filePath,
  }) {
    return DocComponent(
      name: name,
      type: DocComponentType.metaType,
      description: description,
      constructors: const [],
      properties: const [],
      methods: const [],
      filePath: filePath,
    );
  }

  Map<String, dynamic> toJson() => _$DocComponentToJson(this);

  String get genericName {
    if (typeParameters.isEmpty) {
      return name;
    }
    final params = typeParameters.join(', ');
    return '$name<$params>';
  }
}

@JsonSerializable()
class DocProperty {
  const DocProperty({
    required this.name,
    required this.type,
    required this.description,
    required this.features,
    this.annotations = const [],
  });

  final String name;
  final DocType type;
  final String description;
  final List<String> features;
  final List<String> annotations;

  factory DocProperty.fromJson(Map<String, dynamic> json) => _$DocPropertyFromJson(json);

  Map<String, dynamic> toJson() => _$DocPropertyToJson(this);
}

@JsonSerializable()
class DocConstructor {
  const DocConstructor({
    required this.name,
    required this.signature,
    required this.features,
    this.annotations = const [],
  });

  final String name;
  final List<DocParameter> signature;
  final List<String> features;
  final List<String> annotations;

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
    this.annotations = const [],
  });

  final String name;
  final String description;
  final DocType type;
  final bool named;
  final bool required;
  final String? defaultValue;
  final List<String> annotations;

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
    this.annotations = const [],
    this.typeParameters = const [],
  });

  final String name;
  final DocType returnType;
  final List<DocParameter> signature;
  final List<String> features;
  final String description;
  final List<String> annotations;
  final List<String> typeParameters;

  factory DocMethod.fromJson(Map<String, dynamic> json) => _$DocMethodFromJson(json);

  Map<String, dynamic> toJson() => _$DocMethodToJson(this);
}
