import 'dart:io';

import 'package:mtrust_api_guard/doc_generator/cache.dart';
import 'package:mtrust_api_guard/doc_generator/git_utils.dart';
import 'package:mtrust_api_guard/doc_generator/resolve_ref_sdk.dart';
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
///
/// With a non-ambient [sdk], its Flutter binary runs `pub get` even for a Dart
/// package, and no probe for a Flutter on `PATH` is made because the SDK is
/// already known to exist.
void resolveDependencies(String packagePath, {ResolvedSdk? sdk}) {
  final flutterProject = isFlutterProject(packagePath);
  final pinnedExecutable = sdk == null || sdk.isAmbient ? null : sdk.executable;

  // Only a Flutter package needs to know whether Flutter is there, and finding
  // out costs a subprocess.
  final useFlutter = pinnedExecutable != null || (flutterProject && isFlutterAvailable());
  if (flutterProject && !useFlutter) {
    logger.warn('Flutter project detected but Flutter is not available, falling back to dart pub get');
  }

  final command = pinnedExecutable ?? (useFlutter ? 'flutter' : 'dart');
  logger.detail('SDK for $packagePath: ${sdk?.source ?? ResolvedSdk.ambientSource}');
  logger.info('Detected ${flutterProject ? 'Flutter' : 'Dart'} project, running $command pub get in $packagePath');

  final result = Process.runSync(command, ['pub', 'get'], workingDirectory: packagePath);
  if (result.exitCode != 0) {
    throw Exception('Failed to run $command pub get in $packagePath (exit ${result.exitCode}): ${result.stderr}');
  }
}

/// A concise description of [sdk] for the per-ref log line, naming the version
/// and where it came from.
///
/// FVM keeps every SDK at `<cache>/<version>/bin/flutter`, so the parent of the
/// `bin` directory names the version.
String _describeSdk(ResolvedSdk sdk) {
  if (sdk.isAmbient) return sdk.source;

  final version = basename(dirname(sdk.executable));
  const prefix = 'fvm (';
  if (sdk.source.startsWith(prefix) && sdk.source.endsWith(')')) {
    return '$version (fvm: ${sdk.source.substring(prefix.length, sdk.source.length - 1)})';
  }
  return '$version (${sdk.source})';
}

/// [options] with the `--ref-sdk` entry for [ref] re-keyed to [packageRoot].
///
/// The CLI names overrides by the git ref the user typed, while
/// [resolveRefSdk] matches them against the worktree path it receives. This
/// bridges the two without either side having to know about the other.
SdkOverrideOptions sdkOptionsForRef(String ref, String packageRoot, [SdkOverrideOptions? options]) {
  final resolved = options ?? const SdkOverrideOptions();
  final version = resolved.refSdkOverrides[ref]?.trim();
  if (version == null || version.isEmpty) return resolved;

  return SdkOverrideOptions(
    refSdkOverrides: {...resolved.refSdkOverrides, packageRoot: version},
    autodetect: resolved.autodetect,
  );
}

/// Runs [body] against a checkout of [ref] and cleans up after itself.
///
/// When [ref] already is the current HEAD the working tree is handed over as it
/// stands, since checking out a second copy of it would only cost time. Any
/// other ref is materialized as a git worktree under the cache directory, with
/// its dependencies resolved, and removed again once [body] returns.
///
/// With [committed], a working tree that has uncommitted changes is not handed
/// over either, since it is not what [ref] names.
Future<T> withRefWorktree<T>({
  required String ref,
  required Directory dartRoot,
  required Directory gitRoot,
  required Future<T> Function(Directory packageRoot) body,
  bool committed = false,
  SdkOverrideOptions? sdkOptions,
}) async {
  if (!await GitUtils.isGitRepository(gitRoot.path)) {
    throw Exception('Not a git repository: ${gitRoot.path}');
  }

  final repoPath = GitUtils.getRepositoryRoot(gitRoot.path);
  final currentHead = await GitUtils.getCurrentRef(gitRoot.path);
  final resolved = ref == 'HEAD' ? currentHead : await GitUtils.resolveRef(ref, gitRoot.path);

  if (resolved == currentHead && !(committed && GitUtils.hasUncommittedChanges(gitRoot.path))) {
    logger.detail('$ref is the current HEAD, using the working tree');
    return body(dartRoot);
  }

  final worktree = Cache().getWorktreeDir(repoPath, resolved);
  final relativeDartRoot = GitUtils.getPathInRepository(dartRoot.path, gitRoot.path);

  logger.detail('Creating worktree for $ref ($resolved) at ${worktree.path}');
  // By commit, since git refuses to check out a branch a second time.
  await GitUtils.createWorktree(repoPath, resolved, worktree.path);

  try {
    final packageRoot = Directory(join(worktree.path, relativeDartRoot));
    final sdk = resolveRefSdk(packageRoot.path, options: sdkOptionsForRef(ref, packageRoot.path, sdkOptions));
    logger.detail('$ref → ${_describeSdk(sdk)}');
    resolveDependencies(packageRoot.path, sdk: sdk);
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
