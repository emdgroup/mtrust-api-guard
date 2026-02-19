import 'dart:io';
import 'package:path/path.dart';

class Cache {
  static const String _defaultCacheDir = "\$HOME/.mtrust_api_guard/cache";

  Directory get _cacheDir {
    // Check for environment variable first
    final envCacheDir = Platform.environment['MTRUST_API_GUARD_CACHE_DIR'];
    if (envCacheDir != null && envCacheDir.isNotEmpty) {
      return Directory(envCacheDir);
    }
    // Fall back to default location
    final homeDir = Platform.environment['HOME'] ?? '';
    return Directory(_defaultCacheDir.replaceAll("\$HOME", homeDir));
  }

  /// Gets the root cache directory
  Directory getCacheDir() {
    return _cacheDir;
  }

  /// Gets the cache directory for a specific repository
  Directory getRepositoryCacheDir(String repoPath) {
    final repoName = basename(repoPath);
    return Directory(join(_cacheDir.path, repoName));
  }

  /// Sanitizes a path for use in file names
  String _sanitizePath(String path) {
    if (path == '.' || path.isEmpty) {
      return 'root';
    }
    // Replace path separators and invalid characters with underscores
    return path.replaceAll(RegExp(r'[<>:"|?*\x00-\x1f/\\]'), '_');
  }

  /// Gets the path for an API file cached for a specific git ref and dart root
  File getApiFileForRef(String repoPath, String ref, String dartRelativePath) {
    final repoCacheDir = getRepositoryCacheDir(repoPath);
    final sanitizedDartPath = _sanitizePath(dartRelativePath);
    return File(join(repoCacheDir.path, '${ref}_${sanitizedDartPath}_api.json'));
  }

  /// Stores API documentation for a specific git ref and dart root
  Future<void> storeApiFile(
    String repoPath,
    String ref,
    String dartRelativePath,
    String content,
  ) async {
    final repoCacheDir = getRepositoryCacheDir(repoPath);
    if (!repoCacheDir.existsSync()) {
      repoCacheDir.createSync(recursive: true);
    }

    final apiFile = getApiFileForRef(repoPath, ref, dartRelativePath);
    await apiFile.writeAsString(content);
  }

  bool hasApiFileForRef(String repoPath, String ref, String dartRelativePath) {
    final apiFile = getApiFileForRef(repoPath, ref, dartRelativePath);
    return apiFile.existsSync();
  }

  /// Retrieves API documentation for a specific git ref and dart root
  Future<String?> retrieveApiFile(
    String repoPath,
    String ref,
    String dartRelativePath,
  ) async {
    final apiFile = getApiFileForRef(repoPath, ref, dartRelativePath);
    if (apiFile.existsSync()) {
      return await apiFile.readAsString();
    }
    return null;
  }

  /// Checks if API documentation exists for a specific git ref and dart root
  bool hasApiFile(String repoPath, String ref, String dartRelativePath) {
    final apiFile = getApiFileForRef(repoPath, ref, dartRelativePath);
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

  /// Gets the worktree directory for a specific git ref
  /// Sanitizes the ref name to be safe for use in file paths
  Directory getWorktreeDir(String repoPath, String ref) {
    final repoCacheDir = getRepositoryCacheDir(repoPath);
    // Sanitize ref name: replace invalid characters with underscores
    final sanitizedRef = ref.replaceAll(RegExp(r'[<>:"|?*\x00-\x1f]'), '_');
    return Directory(join(repoCacheDir.path, 'worktrees', sanitizedRef));
  }
}
