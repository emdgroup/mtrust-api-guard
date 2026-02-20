import 'dart:io';

import 'package:mtrust_api_guard/doc_comparator/parse_doc_file.dart';
import 'package:mtrust_api_guard/doc_generator/cache.dart';
import 'package:mtrust_api_guard/doc_generator/doc_generator.dart';
import 'package:mtrust_api_guard/doc_generator/git_utils.dart';
import 'package:mtrust_api_guard/logger.dart';
import 'package:mtrust_api_guard/models/package_info.dart';
import 'package:path/path.dart';

Future<PackageApi> getRef({
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
    return parsePackageApiFile(content);
  }

  // Handle git refs
  if (cache) {
    final cacheInstance = Cache();
    final repoPath = GitUtils.getRepositoryRoot(gitRoot.path);
    final dartRelativePath = relative(dartRoot.path, from: gitRoot.path);

    if (cacheInstance.hasApiFileForRef(repoPath, ref, dartRelativePath)) {
      logger.success('Using cached API documentation for $ref');
      final cachedContent = await cacheInstance.retrieveApiFile(
        repoPath,
        ref,
        dartRelativePath,
      );
      if (cachedContent != null) {
        return parsePackageApiFile(cachedContent);
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
