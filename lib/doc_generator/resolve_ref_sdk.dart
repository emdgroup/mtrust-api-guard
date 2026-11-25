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
  /// `fvm (.fvmrc)`, `fvm (.fvm/fvm_config.json)`, `fvm (workflow)`,
  /// `fvm (pubspec.yaml)` or `fvm (--ref-sdk)`.
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
  /// ambient SDK is used regardless of `.fvmrc`, FVM config, workflows or
  /// pubspec.
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

/// Signature of [ambientFlutterVersionReader].
typedef AmbientFlutterVersionReader = String? Function();

/// How the module shells out to the `fvm` CLI.
///
/// The single place an FVM invocation goes through, so tests can replace it and
/// never install a real Flutter SDK.
FvmProcessRunner fvmProcessRunner = _runFvm;

/// How the ambient Flutter version is determined, replaceable in tests.
AmbientFlutterVersionReader ambientFlutterVersionReader = _readAmbientFlutterVersion;

/// Test seam for the environment variables FVM is configured through.
///
/// `null` reads the real [Platform.environment]. Tests set this so the default
/// cache paths are exercised without touching the developer's home directory.
Map<String, String>? environmentOverride;

/// Overrides the directory FVM installs SDKs into.
///
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
/// 4. `flutter-version:` / `flutter-version-file:` of the checkout's
///    `.github/workflows/*.y(a)ml`, because tags created before FVM adoption
///    usually only pin the SDK there.
/// 5. The `environment.flutter` constraint of the `pubspec.yaml`, but only when
///    the ambient SDK does not satisfy it and the lower bound happens to be in
///    the FVM cache.
/// 6. The ambient `flutter` on `PATH`.
///
/// With [SdkOverrideOptions.autodetect] off, steps 2 to 5 are skipped.
///
/// The pin files are also looked up in ancestors up to the git worktree root,
/// because a workspace's `.fvmrc` usually lives at the repository root while
/// the analysed package sits further down.
///
/// Explicit pins ([SdkOverrideOptions.refSdkOverrides], `.fvmrc`,
/// `.fvm/fvm_config.json` and a workflow pin) are mandatory: if the version is
/// missing from the FVM cache it is installed through `fvm install`, and when
/// that is impossible (no `fvm` CLI or a failed install) resolution throws
/// [SdkResolutionException]. The `environment.flutter` constraint of a pubspec
/// is only a hint: it never downloads an SDK and the ambient SDK is used
/// whenever it already satisfies the constraint, so packages that never
/// adopted FVM keep working.
ResolvedSdk resolveRefSdk(String worktreePath, {SdkOverrideOptions? options}) {
  final resolvedOptions = options ?? const SdkOverrideOptions();

  final override = resolvedOptions.versionFor(worktreePath);
  if (override != null) {
    final executable = findOrInstallFvmFlutter(override, pinnedBy: '--ref-sdk', projectDir: worktreePath);
    return _resolved(executable, 'fvm (--ref-sdk)', worktreePath);
  }

  if (!resolvedOptions.autodetect) {
    logger.detail('SDK autodetection disabled for $worktreePath, using the ambient SDK');
    return _ambient(worktreePath);
  }

  final dirs = _configSearchDirs(worktreePath).toList();

  // Source order is the precedence: any `.fvmrc` beats any `.fvm` config, which
  // beats any workflow pin, which beats any pubspec constraint. Within a source
  // the nearest directory wins.
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

  final workflowPin = _workflowPin(dirs);
  if (workflowPin != null) {
    final sdk = _resolvePinned(
      workflowPin.version,
      'fvm (workflow)',
      worktreePath,
      mandatory: true,
      pinnedBy: workflowPin.pinnedBy,
    );
    if (sdk != null) return sdk;
  }

  return _resolvePubspecHint(dirs, worktreePath) ?? _ambient(worktreePath);
}

/// Uses the `environment.flutter` lower bound of a pubspec as a hint.
///
/// The ambient SDK wins when it satisfies the constraint, which keeps packages
/// without an explicit pin on the behaviour they had before per-ref SDKs. A
/// lower bound is only used when it is already in the FVM cache: a hint must
/// never download an SDK, and installing an old lower bound could make
/// `pub get` fail where the ambient SDK worked.
ResolvedSdk? _resolvePubspecHint(List<String> dirs, String worktreePath) {
  for (final dir in dirs) {
    final path = p.join(dir, 'pubspec.yaml');
    final constraint = _flutterConstraint(path);
    if (constraint == null) continue;

    final ambient = _parseVersion(ambientFlutterVersion());
    if (ambient != null && constraint.allows(ambient)) {
      logger.detail('The ambient Flutter $ambient satisfies "$constraint" in $path, so no pinned SDK is needed');
      continue;
    }

    final min = _constraintLowerBound(constraint);
    if (min == null) {
      logger.detail('The Flutter constraint "$constraint" in $path has no usable lower bound, using the ambient SDK');
      continue;
    }

    final cached = findFvmFlutterBinary(min, projectDir: worktreePath);
    if (cached != null) return _resolved(cached, 'fvm (pubspec.yaml)', worktreePath);

    logger.detail('Flutter $min from $path is only a hint and is not cached, using the ambient SDK');
  }
  return null;
}

/// The Flutter binary of the FVM-managed [version], or `null` when it is not
/// installed.
///
/// Probes every directory in [fvmCacheRoots].
String? findFvmFlutterBinary(String version, {String? projectDir}) {
  if (!_isSafeVersion(version)) return null;

  for (final root in fvmCacheRoots(projectDir: projectDir)) {
    final binary = p.join(root, version, 'bin', Platform.isWindows ? 'flutter.bat' : 'flutter');
    if (File(binary).existsSync()) return binary;
  }
  return null;
}

/// The Flutter binary of an FVM-managed [version], installing it through the
/// `fvm` CLI first if necessary.
///
/// [pinnedBy] names where the version came from (`.fvmrc`, `--ref-sdk`, ...) so
/// errors point at the pin. Throws [SdkResolutionException] when the version
/// cannot be provided: it is missing from the FVM cache and `fvm install` is
/// unavailable or fails.
String findOrInstallFvmFlutter(String version, {String? pinnedBy, String? projectDir}) {
  final pin = pinnedBy == null ? 'Flutter $version' : 'Flutter $version (pinned by $pinnedBy)';

  if (!_isSafeVersion(version)) {
    throw SdkResolutionException(
      'Cannot resolve $pin: "$version" is not a plain SDK version. Use a version such as 3.44.8.',
    );
  }

  final installed = findFvmFlutterBinary(version, projectDir: projectDir);
  if (installed != null) return installed;

  logger.detail('Flutter $version is not in the FVM cache, running fvm install $version');
  final result = fvmProcessRunner('fvm', ['install', version]);

  if (result.exitCode == 0) {
    final binary = findFvmFlutterBinary(version, projectDir: projectDir);
    if (binary != null) return binary;

    final roots = fvmCacheRoots(projectDir: projectDir).join(', ');
    throw SdkResolutionException(
      '$pin was installed with fvm, but no Flutter binary appeared in any of: $roots. '
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

/// Candidate directories FVM installs SDKs into, in probe order.
///
/// FVM 3/4 keep SDKs in `~/fvm/versions` (`kAppDirHome`), while older releases
/// and some setups use `$FVM_CACHE_PATH`, the legacy `$FVM_HOME/versions`,
/// `~/.fvm/versions` or a project-local `.fvmrc` `cachePath`. Probing all of
/// them avoids missing an SDK that `fvm` itself would find.
Iterable<String> fvmCacheRoots({String? projectDir}) sync* {
  final candidates = <String>[
    if (fvmCacheRootOverride?.trim().isNotEmpty ?? false) fvmCacheRootOverride!.trim(),
    if (projectDir != null) ..._projectCachePaths(projectDir),
    if (_environment['FVM_CACHE_PATH']?.trim().isNotEmpty ?? false) _environment['FVM_CACHE_PATH']!.trim(),
    if (_environment['FVM_HOME']?.trim().isNotEmpty ?? false) p.join(_environment['FVM_HOME']!.trim(), 'versions'),
    p.join(_homeDir(), 'fvm', 'versions'),
    p.join(_homeDir(), '.fvm', 'versions'),
  ];

  final seen = <String>{};
  for (final candidate in candidates) {
    final normalized = p.normalize(_expandHome(candidate));
    if (normalized.isEmpty || !seen.add(normalized)) continue;
    yield normalized;
  }
}

/// The primary directory FVM installs SDKs into.
String fvmCacheRoot() => fvmCacheRoots().first;

/// `cachePath` entries of `.fvmrc` files from the project upwards, if any.
Iterable<String> _projectCachePaths(String projectDir) sync* {
  for (final dir in _configSearchDirs(projectDir)) {
    final configured = _readJsonString(p.join(dir, '.fvmrc'), 'cachePath');
    if (configured == null) continue;

    final expanded = _expandHome(configured);
    yield p.isAbsolute(expanded) ? expanded : p.join(dir, expanded);
    return;
  }
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

/// The version of the `flutter` on `PATH`, or `null` when it cannot be read.
///
/// Memoized: a `version` run resolves several refs, and the ambient SDK cannot
/// change between them.
String? ambientFlutterVersion() {
  if (!_ambientFlutterVersionRead) {
    _ambientFlutterVersionRead = true;
    try {
      _ambientFlutterVersion = ambientFlutterVersionReader();
    } catch (e) {
      logger.detail('Could not determine the ambient Flutter version: $e');
      _ambientFlutterVersion = null;
    }
  }
  return _ambientFlutterVersion;
}

/// Test seam: forget the memoized ambient Flutter version.
void resetAmbientFlutterVersion() {
  _ambientFlutterVersion = null;
  _ambientFlutterVersionRead = false;
}

String? _ambientFlutterVersion;
bool _ambientFlutterVersionRead = false;

String? _readAmbientFlutterVersion() {
  try {
    final result = Process.runSync('flutter', ['--version', '--machine'], runInShell: Platform.isWindows);
    if (result.exitCode != 0) return null;

    final decoded = jsonDecode(result.stdout.toString());
    if (decoded is Map) {
      final value = decoded['flutterVersion'] ?? decoded['frameworkVersion'];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
  } catch (e) {
    logger.detail('Could not read the ambient Flutter version: $e');
  }
  return null;
}

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
    return _resolved(
      findOrInstallFvmFlutter(version, pinnedBy: pinnedBy, projectDir: worktreePath),
      source,
      worktreePath,
    );
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

/// The Flutter version pinned by the checkout's GitHub workflows.
///
/// Tags created before FVM adoption normally have no `.fvmrc`, so the only pin
/// left is the one their CI used. Both `flutter-version:` and
/// `flutter-version-file:` of `subosito/flutter-action` are understood, and
/// only an exact version counts: `stable`, `3.x` and `${{ ... }}` are channels
/// or expressions, not versions.
({String version, String pinnedBy})? _workflowPin(List<String> dirs) {
  for (final dir in dirs) {
    final workflowsDir = Directory(p.join(dir, '.github', 'workflows'));
    if (!workflowsDir.existsSync()) continue;

    final files =
        workflowsDir
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.yml') || file.path.endsWith('.yaml'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      final version = _workflowVersion(file, dir);
      if (version != null) {
        return (version: version, pinnedBy: p.relative(file.path, from: dir));
      }
    }
  }
  return null;
}

/// The exact Flutter version pinned in the workflow [file], if any.
String? _workflowVersion(File file, String repoDir) {
  try {
    final yaml = loadYaml(file.readAsStringSync());
    // An explicit `flutter-version` wins over a file reference, matching the
    // action: the version input takes precedence over the file input.
    return _findWorkflowVersion(yaml, repoDir, fileRefs: false) ?? _findWorkflowVersion(yaml, repoDir, fileRefs: true);
  } catch (e) {
    logger.detail('Could not read the workflow pin from ${file.path}: $e');
    return null;
  }
}

/// Walks a parsed workflow for a `flutter-version` (or, with [fileRefs], a
/// `flutter-version-file`) entry.
String? _findWorkflowVersion(Object? node, String repoDir, {required bool fileRefs}) {
  if (node is Map) {
    for (final entry in node.entries) {
      final key = entry.key.toString();
      final value = entry.value;

      if (!fileRefs && key == 'flutter-version' && value is String) {
        final version = _exactVersion(value);
        if (version != null) return version;
      }
      if (fileRefs && key == 'flutter-version-file' && value is String) {
        final version = _versionFromVersionFile(value, repoDir);
        if (version != null) return version;
      }

      final nested = _findWorkflowVersion(value, repoDir, fileRefs: fileRefs);
      if (nested != null) return nested;
    }
  } else if (node is Iterable) {
    for (final item in node) {
      final nested = _findWorkflowVersion(item, repoDir, fileRefs: fileRefs);
      if (nested != null) return nested;
    }
  }
  return null;
}

/// The version a `flutter-version-file:` entry names, resolved inside
/// [repoDir].
String? _versionFromVersionFile(String raw, String repoDir) {
  final expanded = _expandHome(raw.trim());
  if (expanded.isEmpty) return null;

  final path = p.normalize(p.isAbsolute(expanded) ? expanded : p.join(repoDir, expanded));
  // Keep the lookup inside the checkout instead of reading arbitrary files a
  // workflow happens to name.
  if (!p.isWithin(repoDir, path)) return null;

  final file = File(path);
  if (!file.existsSync()) return null;

  final name = p.basename(path);
  if (name == '.fvmrc') return _readJsonString(path, 'flutter');
  if (name == 'pubspec.yaml') {
    final constraint = _flutterConstraint(path);
    return constraint == null ? null : _constraintLowerBound(constraint);
  }

  try {
    final content = file.readAsStringSync();
    // A file that just holds the version, e.g. `.flutter-version`.
    final exact = _exactVersion(content.trim());
    if (exact != null) return exact;

    // `.tool-versions` style: `flutter 3.44.8`.
    for (final line in content.split('\n')) {
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2 && parts.first == 'flutter') {
        final version = _exactVersion(parts[1]);
        if (version != null) return version;
      }
    }
  } catch (e) {
    logger.detail('Could not read $path: $e');
  }
  return null;
}

/// [raw] as an exact Flutter version, or `null` when it is a channel,
/// range or expression.
String? _exactVersion(String raw) {
  var value = raw.trim();
  if (value.startsWith('v')) value = value.substring(1);
  if (value.isEmpty) return null;
  return _parseVersion(value)?.toString();
}

Version? _parseVersion(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  try {
    return Version.parse(raw.trim());
  } on FormatException {
    return null;
  }
}

/// The `environment.flutter` constraint of the pubspec at [path], if it
/// declares one.
VersionConstraint? _flutterConstraint(String path) {
  final file = File(path);
  if (!file.existsSync()) return null;

  try {
    final pubspec = loadYaml(file.readAsStringSync());
    if (pubspec is! Map) return null;

    final environment = pubspec['environment'];
    if (environment is! Map) return null;

    final constraint = environment['flutter'];
    if (constraint == null) return null;

    return VersionConstraint.parse(constraint.toString());
  } catch (e) {
    logger.detail('Could not read the Flutter constraint from $path: $e');
    return null;
  }
}

/// The one version a constraint names, if it is also the lowest one it allows.
///
/// A lower bound is inclusive for `>=3.10.0` and `^3.10.0`; for `>3.10.0` no
/// concrete version can be derived, since 3.10.0 itself does not satisfy it.
String? _constraintLowerBound(VersionConstraint constraint) {
  if (constraint is Version) return constraint.toString();
  if (constraint is VersionRange && constraint.includeMin) return constraint.min?.toString();
  return null;
}

/// Whether [version] can be used as a single path segment inside the FVM cache.
bool _isSafeVersion(String version) {
  if (version.isEmpty || version == '.' || version == '..') return false;
  return !version.contains('/') && !version.contains('\\');
}

Map<String, String> get _environment => environmentOverride ?? Platform.environment;

String _homeDir() => _environment['HOME'] ?? _environment['USERPROFILE'] ?? '.';

String _expandHome(String path) {
  if (path == '~') return _homeDir();
  if (path.startsWith('~/') || path.startsWith('~\\')) {
    return p.join(_homeDir(), path.substring(2));
  }
  return path;
}
