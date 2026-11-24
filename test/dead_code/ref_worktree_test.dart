import 'dart:convert';
import 'dart:io';

import 'package:mtrust_api_guard/doc_generator/ref_worktree.dart';
import 'package:mtrust_api_guard/doc_generator/resolve_ref_sdk.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('resolveDependencies', () {
    late Directory package;

    setUp(() => package = Directory.systemTemp.createTempSync('api_guard_resolve_'));
    tearDown(() => package.deleteSync(recursive: true));

    test('carries the reason pub gave into the error', () {
      File(p.join(package.path, 'pubspec.yaml')).writeAsStringSync('''
name: unresolvable
publish_to: none
environment:
  sdk: ">=3.11.0 <4.0.0"
dependencies:
  nowhere:
    path: ../does_not_exist
''');

      expect(
        () => resolveDependencies(package.path),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('does_not_exist'))),
      );
    });
  });

  group('resolveDependencies with a pinned SDK', () {
    late Directory package;
    late Directory fvmCache;
    String? previousCacheRoot;
    late FvmProcessRunner previousRunner;

    setUp(() {
      package = Directory.systemTemp.createTempSync('api_guard_pinned_');
      // Bound the SDK pin lookup to the package instead of walking up towards
      // the real filesystem root.
      Directory(p.join(package.path, '.git')).createSync();

      fvmCache = Directory.systemTemp.createTempSync('api_guard_fvm_');
      previousCacheRoot = fvmCacheRootOverride;
      previousRunner = fvmProcessRunner;
      fvmCacheRootOverride = fvmCache.path;
      fvmProcessRunner = (executable, arguments) {
        throw StateError('Unexpected fvm invocation: $executable ${arguments.join(' ')}');
      };
    });

    tearDown(() {
      fvmCacheRootOverride = previousCacheRoot;
      fvmProcessRunner = previousRunner;
      package.deleteSync(recursive: true);
      fvmCache.deleteSync(recursive: true);
    });

    /// Puts a fake Flutter binary for [version] in the FVM cache. Running it
    /// records its arguments in `pub_get_args.txt` in the working directory,
    /// which shows which SDK resolved the dependencies.
    void installFakeFlutter(String version) {
      final binary = File(p.join(fvmCache.path, version, 'bin', 'flutter'));
      binary.createSync(recursive: true);
      binary.writeAsStringSync('#!/bin/sh\nprintf "%s" "\$*" > pub_get_args.txt\n');
      Process.runSync('chmod', ['+x', binary.path]);
    }

    void writePubspec({required bool flutter}) {
      File(p.join(package.path, 'pubspec.yaml')).writeAsStringSync('''
name: pinned
publish_to: none
environment:
  sdk: ">=3.11.0 <4.0.0"
${flutter ? 'dependencies:\n  flutter:\n    sdk: flutter' : ''}
''');
    }

    void pinFvmrc(String version) {
      File(p.join(package.path, '.fvmrc')).writeAsStringSync(jsonEncode({'flutter': version}));
    }

    test('runs pub get with the Flutter binary pinned in .fvmrc', () {
      installFakeFlutter('3.24.0');
      pinFvmrc('3.24.0');
      writePubspec(flutter: true);

      resolveDependencies(package.path, sdk: resolveRefSdk(package.path));

      final invocation = File(p.join(package.path, 'pub_get_args.txt'));
      expect(invocation.existsSync(), isTrue, reason: 'the pinned SDK was not run');
      expect(invocation.readAsStringSync(), 'pub get');
    });

    test('does not probe for an ambient Flutter when an SDK is pinned', () {
      // A Dart package would normally use `dart pub get`; the pin has to win
      // without asking the ambient `flutter` whether it exists.
      installFakeFlutter('3.24.0');
      pinFvmrc('3.24.0');
      writePubspec(flutter: false);

      resolveDependencies(package.path, sdk: resolveRefSdk(package.path));

      final invocation = File(p.join(package.path, 'pub_get_args.txt'));
      expect(invocation.existsSync(), isTrue, reason: 'the pinned SDK was not run');
    });
  }, skip: Platform.isWindows ? 'the fake SDK binary is a POSIX shell script' : false);
}
