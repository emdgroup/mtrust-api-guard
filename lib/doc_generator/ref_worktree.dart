import 'dart:io';

import 'package:mtrust_api_guard/doc_generator/cache.dart';
import 'package:mtrust_api_guard/doc_generator/git_utils.dart';
import 'package:mtrust_api_guard/logger.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

/// Whether the `flutter` command can be run.
bool isFlutterAvailable() {
  try {
    return Process.runSync('flutter', ['--version'], runInShell: true).exitCode == 0;
  } catch (e) {
    return false;
  }
}

/// Whether the package at [packagePath] depends on the Flutter SDK, which
/// decides whether its dependencies come from `flutter pub get` or `dart pub
/// get`.
bool isFlutterProject(String packagePath) {
  final pubspecFile = File(join(packagePath, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) {
    return false;
  }

  try {
    final pubspec = loadYaml(pubspecFile.readAsStringSync());
    if (pubspec is! Map) return false;

    for (final section in ['dependencies', 'dev_dependencies', 'environment']) {
      final content = pubspec[section];
      if (content is Map && content.containsKey('flutter')) {
        return true;
      }
    }
    return false;
  } catch (e) {
    logger.detail('Failed to parse pubspec.yaml to detect Flutter project: $e');
    return false;
  }
}

/// Resolves the dependencies of the package at [packagePath].
void resolveDependencies(String packagePath) {
  final flutterProject = isFlutterProject(packagePath);
  // Only a Flutter package needs to know whether Flutter is there, and finding
  // out costs a subprocess.
  final useFlutter = flutterProject && isFlutterAvailable();
  if (flutterProject && !useFlutter) {
    logger.warn('Flutter project detected but Flutter is not available, falling back to dart pub get');
  }

  final command = useFlutter ? 'flutter' : 'dart';
  logger.info('Detected ${flutterProject ? 'Flutter' : 'Dart'} project, running $command pub get in $packagePath');

  final result = Process.runSync(command, ['pub', 'get'], workingDirectory: packagePath);
  if (result.exitCode != 0) {
    throw Exception('Failed to run $command pub get in $packagePath (exit ${result.exitCode}): ${result.stderr}');
  }
}

/// Runs [body] against a checkout of [ref] and cleans up after itself.
///
/// When [ref] already is the current HEAD the working tree is handed over as it
/// stands, since checking out a second copy of it would only cost time. Any
/// other ref is materialized as a git worktree under the cache directory, with
/// its dependencies resolved, and removed again once [body] returns.
Future<T> withRefWorktree<T>({
  required String ref,
  required Directory dartRoot,
  required Directory gitRoot,
  required Future<T> Function(Directory packageRoot) body,
}) async {
  if (!await GitUtils.isGitRepository(gitRoot.path)) {
    throw Exception('Not a git repository: ${gitRoot.path}');
  }

  final repoPath = GitUtils.getRepositoryRoot(gitRoot.path);
  final currentHead = await GitUtils.getCurrentRef(gitRoot.path);
  final resolved = ref == 'HEAD' ? currentHead : await GitUtils.resolveRef(ref, gitRoot.path);

  if (resolved == currentHead) {
    logger.detail('$ref is the current HEAD, using the working tree');
    return body(dartRoot);
  }

  final worktree = Cache().getWorktreeDir(repoPath, resolved);
  final relativeDartRoot = relative(dartRoot.path, from: gitRoot.path);

  logger.detail('Creating worktree for $ref ($resolved) at ${worktree.path}');
  await GitUtils.createWorktree(repoPath, ref, worktree.path);

  try {
    final packageRoot = Directory(join(worktree.path, relativeDartRoot));
    resolveDependencies(packageRoot.path);
    return await body(packageRoot);
  } finally {
    try {
      await GitUtils.removeWorktree(repoPath, worktree.path);
      logger.detail('Cleaned up worktree at ${worktree.path}');
    } catch (e) {
      logger.err('Warning: failed to clean up worktree at ${worktree.path}: $e');
    }
  }
}
