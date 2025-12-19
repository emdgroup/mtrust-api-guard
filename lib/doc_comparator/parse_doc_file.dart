import 'dart:convert';
import 'package:mtrust_api_guard/models/doc_items.dart';
import 'package:mtrust_api_guard/models/package_info.dart';

PackageApi parsePackageApiFile(String content) {
  final json = jsonDecode(content);
  if (json is List) {
    // Handle legacy format (List<DocComponent>)
    return PackageApi(
      metadata: PackageMetadata(),
      components: json.map((e) => DocComponent.fromJson(e)).toList(),
    );
  }
  return PackageApi.fromJson(json);
}
