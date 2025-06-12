// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:mtrust_api_guard/mtrust_api_guard.dart';

List<DocComponent> parseDocComponentsFile(String content) {
  final docComponents = jsonDecode(content) as List<dynamic>;
  return docComponents.map((e) => DocComponent.fromJson(e)).toList();
}
