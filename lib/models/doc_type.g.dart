// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'doc_type.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocType _$DocTypeFromJson(Map<String, dynamic> json) => DocType(
      name: json['name'] as String,
      superTypes: (json['superTypes'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      isNullable: json['isNullable'] as bool? ?? false,
    );

Map<String, dynamic> _$DocTypeToJson(DocType instance) => <String, dynamic>{
      'name': instance.name,
      'superTypes': instance.superTypes,
      'isNullable': instance.isNullable,
    };
