// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'doc_items.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocComponent _$DocComponentFromJson(Map<String, dynamic> json) => DocComponent(
      name: json['name'] as String,
      isNullSafe: json['isNullSafe'] as bool,
      description: json['description'] as String,
      constructors: (json['constructors'] as List<dynamic>)
          .map((e) => DocConstructor.fromJson(e as Map<String, dynamic>))
          .toList(),
      properties: (json['properties'] as List<dynamic>)
          .map((e) => DocProperty.fromJson(e as Map<String, dynamic>))
          .toList(),
      methods:
          (json['methods'] as List<dynamic>).map((e) => e as String).toList(),
      filePath: json['filePath'] as String?,
    );

Map<String, dynamic> _$DocComponentToJson(DocComponent instance) =>
    <String, dynamic>{
      'filePath': instance.filePath,
      'name': instance.name,
      'isNullSafe': instance.isNullSafe,
      'description': instance.description,
      'constructors': instance.constructors,
      'properties': instance.properties,
      'methods': instance.methods,
    };

DocProperty _$DocPropertyFromJson(Map<String, dynamic> json) => DocProperty(
      name: json['name'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      features:
          (json['features'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$DocPropertyToJson(DocProperty instance) =>
    <String, dynamic>{
      'name': instance.name,
      'type': instance.type,
      'description': instance.description,
      'features': instance.features,
    };

DocConstructor _$DocConstructorFromJson(Map<String, dynamic> json) =>
    DocConstructor(
      name: json['name'] as String,
      signature: (json['signature'] as List<dynamic>)
          .map((e) => DocParameter.fromJson(e as Map<String, dynamic>))
          .toList(),
      features:
          (json['features'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$DocConstructorToJson(DocConstructor instance) =>
    <String, dynamic>{
      'name': instance.name,
      'signature': instance.signature,
      'features': instance.features,
    };

DocParameter _$DocParameterFromJson(Map<String, dynamic> json) => DocParameter(
      name: json['name'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      named: json['named'] as bool,
      required: json['required'] as bool,
    );

Map<String, dynamic> _$DocParameterToJson(DocParameter instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'type': instance.type,
      'named': instance.named,
      'required': instance.required,
    };
