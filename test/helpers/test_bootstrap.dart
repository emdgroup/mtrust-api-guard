import 'dart:io';

import 'package:path/path.dart' as p;

/// Ensures compiled binary and Flutter scaffold fixtures exist before integration tests run.
class TestBootstrap {
  static const _lockRetries = 120;
  static const _lockRetryDelay = Duration(milliseconds: 500);

  static String get _rootDir => Directory.current.path;

  static String get binaryPath {
    final name = Platform.isWindows ? 'mtrust_api_guard.exe' : 'mtrust_api_guard';
    return p.join(_rootDir, 'build', name);
  }

  static String get _lockPath => p.join(_rootDir, 'build', '.test-bootstrap.lock');

  static String get _packageBaseMarker => p.join(_rootDir, '.test_scaffolds', 'package_base', 'pubspec.yaml');

  static String get _pluginBaseMarker => p.join(_rootDir, '.test_scaffolds', 'plugin_base', 'pubspec.yaml');

  static String get _regenerateScript => p.join(_rootDir, 'tool', 'regenerate_test_fixtures.sh');

  static String? _dartSdkPath;

  /// Resolved Dart SDK path for compiled binary invocations.
  static String? get dartSdkPath {
    _dartSdkPath ??= _resolveDartSdkPath();
    return _dartSdkPath;
  }

  static String? _resolveDartSdkPath() {
    final envSdk = Platform.environment['DART_SDK'];
    if (envSdk != null && envSdk.isNotEmpty && Directory(envSdk).existsSync()) {
      return p.normalize(envSdk);
    }

    try {
      final result = Process.runSync(Platform.isWindows ? 'where' : 'which', ['dart'], runInShell: true);
      if (result.exitCode != 0) {
        return null;
      }

      final dartPath = result.stdout.toString().trim().split(RegExp(r'\r?\n')).first.trim();
      if (dartPath.isEmpty) {
        return null;
      }

      final binDir = p.dirname(dartPath);
      final flutterCacheSdk = p.join(binDir, 'cache', 'dart-sdk');
      if (Directory(flutterCacheSdk).existsSync()) {
        return p.normalize(flutterCacheSdk);
      }

      return p.normalize(p.dirname(p.dirname(dartPath)));
    } catch (_) {
      return null;
    }
  }

  /// Prepares compiled API Guard binary and Flutter scaffold fixtures.
  static Future<void> ensureReady() async {
    await _removeLegacyScaffoldDirs();

    if (_isReady()) {
      return;
    }

    await _withFileLock(_bootstrap);
  }

  static bool _isReady() {
    return File(_packageBaseMarker).existsSync() &&
        File(_pluginBaseMarker).existsSync() &&
        File(binaryPath).existsSync() &&
        !_isBinaryStale();
  }

  static Future<void> _bootstrap() async {
    if (_isReady()) {
      return;
    }

    await _ensureFlutterFixtures();
    await _ensureCompiledBinary();
  }

  static Future<void> _removeLegacyScaffoldDirs() async {
    for (final legacyDir in [
      p.join(_rootDir, 'test', 'fixtures', 'package_base'),
      p.join(_rootDir, 'test', 'fixtures', 'plugin_base'),
    ]) {
      final dir = Directory(legacyDir);
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    }
  }

  static Future<void> _ensureFlutterFixtures() async {
    final inCi = Platform.environment['CI'] == 'true';
    final fixturesExist = File(_packageBaseMarker).existsSync() && File(_pluginBaseMarker).existsSync();

    if (!inCi && fixturesExist) {
      return;
    }

    final result = await Process.run('bash', [_regenerateScript], workingDirectory: _rootDir);
    if (result.exitCode != 0) {
      throw StateError(
        'Failed to regenerate test fixtures (exit ${result.exitCode})\n'
        'stdout: ${result.stdout}\n'
        'stderr: ${result.stderr}',
      );
    }
  }

  static Future<void> _ensureCompiledBinary() async {
    final binary = File(binaryPath);
    if (binary.existsSync() && !_isBinaryStale()) {
      return;
    }

    await Directory(p.dirname(binaryPath)).create(recursive: true);

    final result = await Process.run(
      'dart',
      ['compile', 'exe', p.join(_rootDir, 'bin', 'mtrust_api_guard.dart'), '-o', binaryPath],
      workingDirectory: _rootDir,
    );

    if (result.exitCode != 0) {
      throw StateError(
        'Failed to compile API Guard test binary (exit ${result.exitCode})\n'
        'stdout: ${result.stdout}\n'
        'stderr: ${result.stderr}',
      );
    }
  }

  static bool _isBinaryStale() {
    final binary = File(binaryPath);
    if (!binary.existsSync()) {
      return true;
    }

    final binaryModified = binary.lastModifiedSync();
    for (final dirName in ['lib', 'bin']) {
      final dir = Directory(p.join(_rootDir, dirName));
      if (!dir.existsSync()) {
        continue;
      }
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is File && entity.lastModifiedSync().isAfter(binaryModified)) {
          return true;
        }
      }
    }

    return false;
  }

  static Future<void> _withFileLock(Future<void> Function() action) async {
    await Directory(p.dirname(_lockPath)).create(recursive: true);

    for (var attempt = 0; attempt < _lockRetries; attempt++) {
      if (_isReady()) {
        return;
      }

      RandomAccessFile? lockFile;
      try {
        lockFile = await File(_lockPath).open(mode: FileMode.write);
        lockFile.lockSync(FileLock.exclusive);
        await action();
        return;
      } on FileSystemException {
        await Future<void>.delayed(_lockRetryDelay);
        if (_isReady()) {
          return;
        }
      } finally {
        try {
          lockFile?.unlockSync();
          await lockFile?.close();
        } catch (_) {
          // Another worker may hold the lock.
        }
      }
    }

    if (_isReady()) {
      return;
    }

    throw StateError('Timed out waiting for test bootstrap lock');
  }

  /// Resolves the API Guard executable for integration tests.
  static (String executable, List<String> prefixArgs) resolveApiGuardInvocation() {
    final envBinary = Platform.environment['MTRUST_API_GUARD_BINARY'];
    if (envBinary != null && envBinary.isNotEmpty) {
      return (envBinary, []);
    }

    if (File(binaryPath).existsSync()) {
      return (binaryPath, []);
    }

    return ('dart', [p.join(_rootDir, 'bin', 'mtrust_api_guard.dart')]);
  }
}
