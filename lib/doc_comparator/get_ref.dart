import 'dart:io';

import 'package:mtrust_api_guard/doc_comparator/parse_doc_file.dart';
import 'package:mtrust_api_guard/doc_generator/cache.dart';
import 'package:mtrust_api_guard/doc_generator/doc_generator.dart';
import 'package:mtrust_api_guard/logger.dart';
import 'package:mtrust_api_guard/models/doc_items.dart';

Future<List<DocComponent>> getRef({
  required String ref,
  required Directory dartRoot,
  required Directory gitRoot,
  required bool cache,
}) async {
  // Check if ref is a local file path
  final file = File(ref);
  if (file.existsSync()) {
    logger.info('Reading API documentation from local file: $ref');
    final content = await file.readAsString();
    return parseDocComponentsFile(content);
  }

  // Handle git refs
  if (cache) {
    final cache = Cache();

    if (cache.hasApiFile(gitRoot.path, ref)) {
      logger.success('Using cached API documentation for $ref');
      final cachedContent = await cache.retrieveApiFile(gitRoot.path, ref);
      if (cachedContent != null) {
        return parseDocComponentsFile(cachedContent);
      }
    } else {
      logger.info("Cache miss for $ref");
    }
  } else {
    logger.info("Cache is disabled for $ref");
  }

  // Generate the API documentation for the ref
  return generateDocs(
    gitRef: ref,
    out: null,
    dartRoot: dartRoot,
    gitRoot: gitRoot,
    shouldCache: cache,
  );
}
