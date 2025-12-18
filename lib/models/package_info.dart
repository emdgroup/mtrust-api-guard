import 'package:json_annotation/json_annotation.dart';
import 'package:mtrust_api_guard/models/doc_items.dart';

part 'package_info.g.dart';

@JsonSerializable()
class PackageApi {
  final PackageMetadata metadata;
  final List<DocComponent> components;

  PackageApi({
    required this.metadata,
    required this.components,
  });

  factory PackageApi.fromJson(Map<String, dynamic> json) => _$PackageApiFromJson(json);
  Map<String, dynamic> toJson() => _$PackageApiToJson(this);
}

@JsonSerializable()
class PackageMetadata {
  final String? packageName;
  final String? packageVersion;
  final List<PackageDependency> dependencies;
  final AndroidPlatformConstraints? androidConstraints;
  final IOSPlatformConstraints? iosConstraints;

  PackageMetadata({
    this.packageName,
    this.packageVersion,
    this.dependencies = const [],
    this.androidConstraints,
    this.iosConstraints,
  });

  factory PackageMetadata.fromJson(Map<String, dynamic> json) => _$PackageMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$PackageMetadataToJson(this);
}

@JsonSerializable()
class PackageDependency {
  final String packageName;
  final String? packageVersion;

  PackageDependency({
    required this.packageName,
    this.packageVersion,
  });

  factory PackageDependency.fromJson(Map<String, dynamic> json) => _$PackageDependencyFromJson(json);
  Map<String, dynamic> toJson() => _$PackageDependencyToJson(this);
}

@JsonSerializable()
class AndroidPlatformConstraints {
  final int? minSdkVersion;
  final int? compileSdkVersion;
  final int? targetSdkVersion;

  AndroidPlatformConstraints({
    this.minSdkVersion,
    this.compileSdkVersion,
    this.targetSdkVersion,
  });

  factory AndroidPlatformConstraints.fromJson(Map<String, dynamic> json) => _$AndroidPlatformConstraintsFromJson(json);
  Map<String, dynamic> toJson() => _$AndroidPlatformConstraintsToJson(this);
}

@JsonSerializable()
class IOSPlatformConstraints {
  final num? minimumOsVersion;

  IOSPlatformConstraints({
    this.minimumOsVersion,
  });

  factory IOSPlatformConstraints.fromJson(Map<String, dynamic> json) => _$IOSPlatformConstraintsFromJson(json);
  Map<String, dynamic> toJson() => _$IOSPlatformConstraintsToJson(this);
}
