import 'dart:convert';
import 'dart:io';

import 'package:mtrust_api_guard/logger.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

/// The SDK a ref is analysed with: the command to run and a label describing
/// where it came from.
class ResolvedSdk {
  const ResolvedSdk({required this.executable, required this.source});

  /// The `flutter` command, or an absolute path to the Flutter binary of an
  /// FVM-managed SDK.
  final String executable;

  /// Where [executable] came from, used in log lines: `ambient`,
  /// `fvm (.fvmrc)`, `fvm (.fvm/fvm_config.json)`, `fvm (pubspec.yaml)` or
  /// `fvm (--ref-sdk)`.
  final String source;

  /// The [source] label carried by the SDK that is already on `PATH`.
  static const String ambientSource = 'ambient';

  /// Whether this is the ambient SDK.
  ///
  /// Callers that still choose between `flutter` and `dart` for the ambient
  /// case should check this, since [executable] is always `flutter` here.
  bool get isAmbient => source == ambientSource;
}

/// Thrown when the SDK pinned by a ref cannot be provided.
///
/// The message names the pinned version and the command that provides it, so
/// the CLI surfaces an actionable error instead of a dependency-solving dump.
class SdkResolutionException implements Exception {
  const SdkResolutionException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// CLI escape hatches for [resolveRefSdk].
class SdkOverrideOptions {
  const SdkOverrideOptions({this.refSdkOverrides = const {}, this.autodetect = true});

  /// Explicit Flutter versions that win over anything pinned in the checkout,
  /// e.g. `{'liquid_flutter/v23.0.0-16': '3.44.8'}` from `--ref-sdk`.
  final Map<String, String> refSdkOverrides;

  /// Whether to inspect the checkout for an SDK pin at all. With `false` the
  /// ambient SDK is used regardless of `.fvmrc`, FVM config or pubspec.
  final bool autodetect;

  /// The version explicitly pinned for [worktreePath], if any.
  ///
  /// A key is matched against [worktreePath] as given, its normalized absolute
  /// form and its basename. In this module the worktree path is the only
  /// handle on a ref, so Stage 3 maps `--ref-sdk <ref>=<version>` values onto
  /// that key space when it threads the options through the call chain.
  String? versionFor(String worktreePath) {
    if (refSdkOverrides.isEmpty) return null;

    final absolute = p.normalize(p.absolute(worktreePath));
    for (final key in [worktreePath, absolute, p.basename(absolute)]) {
      final version = refSdkOverrides[key]?.trim();
      if (version != null && version.isNotEmpty) return version;
    }
    return null;
  }
}

/// Signature of [fvmProcessRunner].
typedef FvmProcessRunner = ProcessResult Function(String executable, List<String> arguments);

/// How the module shells out to the `fvm` CLI.
///
/// The single place an FVM invocation goes through, so tests can replace it and
/// never install a real Flutter SDK.
FvmProcessRunner fvmProcessRunner = _runFvm;

/// Overrides the directory FVM installs SDKs into.
///
/// When `null`, `$FVM_CACHE_PATH` is used, falling back to `~/.fvm/versions`.
/// Tests point this at a temporary directory so the real cache is never read.
String? fvmCacheRootOverride;

/// Resolves the Flutter SDK the ref checked out at [worktreePath] should be
/// built with.
///
/// Precedence:
/// 1. An explicit entry in [SdkOverrideOptions.refSdkOverrides] for
///    [worktreePath]. An explicit pin wins even when autodetection is off.
/// 2. `.fvmrc` (`"flutter"`) in the checkout.
/// 3. `.fvm/fvm_config.json` (`"flutterSdkVersion"`).
/// 4. The `environment.flutter` lower bound of the `pubspec.yaml`.
/// 5. The ambient `flutter` on `PATH`.
///
/// With [SdkOverrideOptions.autodetect] off, steps 2 to 4 are skipped.
///
/// The pin files are also looked up in ancestors up to the git worktree root,
/// because a workspace's `.fvmrc` usually lives at the repository root while
/// the analysed package sits further down.
///
/// Explicit pins ([SdkOverrideOptions.refSdkOverrides], `.fvmrc` and
/// `.fvm/fvm_config.json`) are mandatory: if the version is missing from the
/// FVM cache it is installed through `fvm install`, and when that is impossible
/// (no `fvm` CLI or a failed install) resolution throws
/// [SdkResolutionException]. The `environment.flutter` lower bound of a
/// pubspec is only a hint — if FVM cannot provide it the ambient SDK is used,
/// so packages that never adopted FVM keep working.
ResolvedSdk resolveRefSdk(String worktreePath, {SdkOverrideOptions? options}) {
  final resolvedOptions = options ?? const SdkOverrideOptions();

  final override = resolvedOptions.versionFor(worktreePath);
  if (override != null) {
    final executable = findOrInstallFvmFlutter(override, pinnedBy: '--ref-sdk');
    return _resolved(executable, 'fvm (--ref-sdk)', worktreePath);
  }

  if (!resolvedOptions.autodetect) {
    logger.detail('SDK autodetection disabled for $worktreePath, using the ambient SDK');
    return _ambient(worktreePath);
  }

  final dirs = _configSearchDirs(worktreePath).toList();

  // Source order is the precedence: any `.fvmrc` beats any `.fvm` config, which
  // beats any pubspec constraint. Within a source the nearest directory wins.
  for (final dir in dirs) {
    final version = _readJsonString(p.join(dir, '.fvmrc'), 'flutter');
    final sdk = version == null
        ? null
        : _resolvePinned(version, 'fvm (.fvmrc)', worktreePath, mandatory: true, pinnedBy: '.fvmrc');
    if (sdk != null) return sdk;
  }

  for (final dir in dirs) {
    final version = _readJsonString(p.join(dir, '.fvm', 'fvm_config.json'), 'flutterSdkVersion');
    final sdk = version == null
        ? null
        : _resolvePinned(
            version,
            'fvm (.fvm/fvm_config.json)',
            worktreePath,
            mandatory: true,
            pinnedBy: '.fvm/fvm_config.json',
          );
    if (sdk != null) return sdk;
  }

  for (final dir in dirs) {
    final version = _flutterLowerBound(p.join(dir, 'pubspec.yaml'));
    final sdk = version == null
        ? null
        : _resolvePinned(version, 'fvm (pubspec.yaml)', worktreePath, mandatory: false, pinnedBy: 'pubspec.yaml');
    if (sdk != null) return sdk;
  }

  return _ambient(worktreePath);
}

/// The Flutter binary of the FVM-managed [version], or `null` when it is not
/// installed.
///
/// Probes `$FVM_CACHE_PATH/<version>/bin/flutter`, falling back to
/// `~/.fvm/versions` when the variable is unset.
String? findFvmFlutterBinary(String version) {
  if (!_isSafeVersion(version)) return null;

  final binary = p.join(fvmCacheRoot(), version, 'bin', Platform.isWindows ? 'flutter.bat' : 'flutter');
  return File(binary).existsSync() ? binary : null;
}

/// The Flutter binary of an FVM-managed [version], installing it through the
/// `fvm` CLI first if necessary.
///
/// [pinnedBy] names where the version came from (`.fvmrc`, `--ref-sdk`, ...) so
/// errors point at the pin. Throws [SdkResolutionException] when the version
/// cannot be provided: it is missing from the FVM cache and `fvm install` is
/// unavailable or fails.
String findOrInstallFvmFlutter(String version, {String? pinnedBy}) {
  final pin = pinnedBy == null ? 'Flutter $version' : 'Flutter $version (pinned by $pinnedBy)';

  if (!_isSafeVersion(version)) {
    throw SdkResolutionException(
      'Cannot resolve $pin: "$version" is not a plain SDK version. Use a version such as 3.44.8.',
    );
  }

  final installed = findFvmFlutterBinary(version);
  if (installed != null) return installed;

  logger.detail('Flutter $version is not in the FVM cache, running fvm install $version');
  final result = fvmProcessRunner('fvm', ['install', version]);

  if (result.exitCode == 0) {
    final binary = findFvmFlutterBinary(version);
    if (binary != null) return binary;

    throw SdkResolutionException(
      '$pin was installed with fvm, but no Flutter binary appeared in ${fvmCacheRoot()}. '
      'Re-run `fvm install $version` or set FVM_CACHE_PATH to the FVM versions directory.',
    );
  }

  if (_fvmMissing(result)) {
    throw SdkResolutionException(
      '$pin is not installed and the fvm CLI is not available. '
      'Install FVM (https://fvm.app), then run `fvm install $version`.',
    );
  }

  throw SdkResolutionException(
    '$pin is not installed and `fvm install $version` failed (exit ${result.exitCode}): '
    '${result.stderr.toString().trim()}. Run `fvm install $version` manually.',
  );
}

/// The directory FVM installs SDKs into.
String fvmCacheRoot() {
  final override = fvmCacheRootOverride?.trim();
  if (override != null && override.isNotEmpty) {
    return p.normalize(_expandHome(override));
  }

  final configured = Platform.environment['FVM_CACHE_PATH']?.trim();
  if (configured != null && configured.isNotEmpty) {
    return p.normalize(_expandHome(configured));
  }

  return p.join(_homeDir(), '.fvm', 'versions');
}

ProcessResult _runFvm(String executable, List<String> arguments) {
  try {
    // A shell is only needed on Windows, where the CLI is a `.bat` file.
    return Process.runSync(executable, arguments, runInShell: Platform.isWindows);
  } on ProcessException catch (e) {
    // `sh` reports a missing command as exit code 127; failing to start the
    // executable at all means the same thing.
    return ProcessResult(0, 127, '', e.message);
  }
}

/// Whether [result] means the `fvm` executable itself could not be found.
bool _fvmMissing(ProcessResult result) => result.exitCode == 127 || result.exitCode == 9009;

/// Resolves [version] for [source].
///
/// A [mandatory] pin propagates [SdkResolutionException]; a hint logs the
/// reason and returns `null` so resolution can fall back to the ambient SDK.
ResolvedSdk? _resolvePinned(
  String version,
  String source,
  String worktreePath, {
  required bool mandatory,
  required String pinnedBy,
}) {
  try {
    return _resolved(findOrInstallFvmFlutter(version, pinnedBy: pinnedBy), source, worktreePath);
  } on SdkResolutionException catch (e) {
    if (mandatory) rethrow;
    logger.warn('$e Using the ambient SDK instead.');
    return null;
  }
}

ResolvedSdk _resolved(String executable, String source, String worktreePath) {
  logger.detail('Resolved SDK for $worktreePath: $executable ($source)');
  return ResolvedSdk(executable: executable, source: source);
}

ResolvedSdk _ambient(String worktreePath) => _resolved('flutter', ResolvedSdk.ambientSource, worktreePath);

/// Directories to look for an SDK pin in, nearest first.
///
/// [worktreePath] itself plus the nearest ancestor carrying a `.git` marker, so
/// a workspace's repository-root `.fvmrc` applies to a nested package. Without
/// a `.git` marker only [worktreePath] is searched, which keeps lookups inside
/// the checkout.
Iterable<String> _configSearchDirs(String worktreePath) sync* {
  final start = p.normalize(p.absolute(worktreePath));
  yield start;
  if (_hasGitMarker(start)) return;

  var dir = start;
  while (true) {
    final parent = p.dirname(dir);
    if (parent == dir) return;
    dir = parent;
    if (_hasGitMarker(dir)) {
      yield dir;
      return;
    }
  }
}

bool _hasGitMarker(String dir) => Directory(p.join(dir, '.git')).existsSync() || File(p.join(dir, '.git')).existsSync();

/// Reads the string [key] of the JSON object at [path], if present and valid.
String? _readJsonString(String path, String key) {
  final file = File(path);
  if (!file.existsSync()) return null;

  try {
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is Map) {
      final value = decoded[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      logger.detail('No "$key" entry in $path');
    }
  } catch (e) {
    logger.detail('Could not parse $path as JSON: $e');
  }
  return null;
}

/// The `environment.flutter` lower bound of the pubspec at [path], if it
/// declares one.
String? _flutterLowerBound(String path) {
  final file = File(path);
  if (!file.existsSync()) return null;

  try {
    final pubspec = loadYaml(file.readAsStringSync());
    if (pubspec is! Map) return null;

    final environment = pubspec['environment'];
    if (environment is! Map) return null;

    final constraint = environment['flutter'];
    if (constraint == null) return null;

    final parsed = VersionConstraint.parse(constraint.toString());
    if (parsed is VersionRange) return parsed.min?.toString();
    if (parsed is Version) return parsed.toString();
    return null;
  } catch (e) {
    logger.detail('Could not read the Flutter constraint from $path: $e');
    return null;
  }
}

/// Whether [version] can be used as a single path segment inside the FVM cache.
bool _isSafeVersion(String version) {
  if (version.isEmpty || version == '.' || version == '..') return false;
  return !version.contains('/') && !version.contains('\\');
}

String _homeDir() => Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';

String _expandHome(String path) {
  if (path == '~') return _homeDir();
  if (path.startsWith('~/') || path.startsWith('~\\')) {
    return p.join(_homeDir(), path.substring(2));
  }
  return path;
}
