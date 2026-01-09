// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackageApi _$PackageApiFromJson(Map<String, dynamic> json) => PackageApi(
      metadata:
          PackageMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      components: (json['components'] as List<dynamic>)
          .map((e) => DocComponent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PackageApiToJson(PackageApi instance) =>
    <String, dynamic>{
      'metadata': instance.metadata,
      'components': instance.components,
    };

PackageMetadata _$PackageMetadataFromJson(Map<String, dynamic> json) =>
    PackageMetadata(
      packageName: json['packageName'] as String?,
      packageVersion: json['packageVersion'] as String?,
      sdkVersion: json['sdkVersion'] as String?,
      dependencies: (json['dependencies'] as List<dynamic>?)
              ?.map(
                  (e) => PackageDependency.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      androidConstraints: json['androidConstraints'] == null
          ? null
          : AndroidPlatformConstraints.fromJson(
              json['androidConstraints'] as Map<String, dynamic>),
      iosConstraints: json['iosConstraints'] == null
          ? null
          : IOSPlatformConstraints.fromJson(
              json['iosConstraints'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PackageMetadataToJson(PackageMetadata instance) =>
    <String, dynamic>{
      'packageName': instance.packageName,
      'packageVersion': instance.packageVersion,
      'sdkVersion': instance.sdkVersion,
      'dependencies': instance.dependencies,
      'androidConstraints': instance.androidConstraints,
      'iosConstraints': instance.iosConstraints,
    };

PackageDependency _$PackageDependencyFromJson(Map<String, dynamic> json) =>
    PackageDependency(
      packageName: json['packageName'] as String,
      packageVersion: json['packageVersion'] as String?,
    );

Map<String, dynamic> _$PackageDependencyToJson(PackageDependency instance) =>
    <String, dynamic>{
      'packageName': instance.packageName,
      'packageVersion': instance.packageVersion,
    };

AndroidPlatformConstraints _$AndroidPlatformConstraintsFromJson(
        Map<String, dynamic> json) =>
    AndroidPlatformConstraints(
      minSdkVersion: (json['minSdkVersion'] as num?)?.toInt(),
      compileSdkVersion: (json['compileSdkVersion'] as num?)?.toInt(),
      targetSdkVersion: (json['targetSdkVersion'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AndroidPlatformConstraintsToJson(
        AndroidPlatformConstraints instance) =>
    <String, dynamic>{
      'minSdkVersion': instance.minSdkVersion,
      'compileSdkVersion': instance.compileSdkVersion,
      'targetSdkVersion': instance.targetSdkVersion,
    };

IOSPlatformConstraints _$IOSPlatformConstraintsFromJson(
        Map<String, dynamic> json) =>
    IOSPlatformConstraints(
      minimumOsVersion: json['minimumOsVersion'] as num?,
    );

Map<String, dynamic> _$IOSPlatformConstraintsToJson(
        IOSPlatformConstraints instance) =>
    <String, dynamic>{
      'minimumOsVersion': instance.minimumOsVersion,
    };
