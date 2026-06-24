import 'dart:io';

import 'package:path/path.dart' as p;

/// Resolves the Dart SDK path for analyzer use, including when running as a compiled executable.
String? getSdkPath() {
  final envSdk = Platform.environment['DART_SDK'];
  if (envSdk != null && envSdk.isNotEmpty && Directory(envSdk).existsSync()) {
    return p.normalize(envSdk);
  }

  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null && flutterRoot.isNotEmpty) {
    final flutterSdk = p.join(flutterRoot, 'bin', 'cache', 'dart-sdk');
    if (Directory(flutterSdk).existsSync()) {
      return p.normalize(flutterSdk);
    }
  }

  final executable = Platform.resolvedExecutable;
  final executableName = p.basename(executable);
  if (executableName == 'dart' || executableName == 'dart.exe') {
    return p.normalize(p.dirname(p.dirname(executable)));
  }

  final dartOnPath = _dartExecutableOnPath();
  if (dartOnPath != null) {
    final binDir = p.dirname(dartOnPath);
    final flutterCacheSdk = p.join(binDir, 'cache', 'dart-sdk');
    if (Directory(flutterCacheSdk).existsSync()) {
      return p.normalize(flutterCacheSdk);
    }

    if (p.basename(dartOnPath) == 'dart' || p.basename(dartOnPath) == 'dart.exe') {
      return p.normalize(p.dirname(p.dirname(dartOnPath)));
    }
  }

  return null;
}

String? _dartExecutableOnPath() {
  try {
    final result = Process.runSync(Platform.isWindows ? 'where' : 'which', ['dart'], runInShell: true);
    if (result.exitCode != 0) {
      return null;
    }

    final dartPath = result.stdout.toString().trim().split(RegExp(r'\r?\n')).first.trim();
    if (dartPath.isEmpty || !File(dartPath).existsSync()) {
      return null;
    }

    return dartPath;
  } catch (_) {
    return null;
  }
}
