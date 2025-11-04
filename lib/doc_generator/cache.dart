import 'dart:io';
import 'package:path/path.dart';

class Cache {
  static const cacheDir = "\$HOME/.mtrust_api_guard/cache";

  Directory get _cacheDir {
    final homeDir = Platform.environment['HOME'] ?? '';
    return Directory(cacheDir.replaceAll("\$HOME", homeDir));
  }

  /// Gets the cache directory for a specific repository
  Directory getRepositoryCacheDir(String repoPath) {
    final repoName = basename(repoPath);
    return Directory(join(_cacheDir.path, repoName));
  }

  /// Gets the path for an API file cached for a specific git ref
  File getApiFileForRef(String repoPath, String ref) {
    final repoCacheDir = getRepositoryCacheDir(repoPath);
    return File(join(repoCacheDir.path, '${ref}_api.json'));
  }

  /// Stores API documentation for a specific git ref
  Future<void> storeApiFile(String repoPath, String ref, String content) async {
    final repoCacheDir = getRepositoryCacheDir(repoPath);
    if (!repoCacheDir.existsSync()) {
      repoCacheDir.createSync(recursive: true);
    }

    final apiFile = getApiFileForRef(repoPath, ref);
    await apiFile.writeAsString(content);
  }

  bool hasApiFileForRef(String repoPath, String ref) {
    final apiFile = getApiFileForRef(repoPath, ref);
    return apiFile.existsSync();
  }

  /// Retrieves API documentation for a specific git ref
  Future<String?> retrieveApiFile(String repoPath, String ref) async {
    final apiFile = getApiFileForRef(repoPath, ref);
    if (apiFile.existsSync()) {
      return await apiFile.readAsString();
    }
    return null;
  }

  /// Checks if API documentation exists for a specific git ref
  bool hasApiFile(String repoPath, String ref) {
    final apiFile = getApiFileForRef(repoPath, ref);
    return apiFile.existsSync();
  }

  /// Lists all cached refs for a repository
  List<String> listCachedRefs(String repoPath) {
    final repoCacheDir = getRepositoryCacheDir(repoPath);
    if (!repoCacheDir.existsSync()) {
      return [];
    }

    return repoCacheDir
        .listSync()
        .where((entity) => entity is File && entity.path.endsWith('_api.json'))
        .map((file) => basename(file.path).replaceAll('_api.json', ''))
        .toList();
  }
}
