import 'dart:convert';
import 'dart:io';

import 'package:mtrust_api_guard/doc_generator/resolve_ref_sdk.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('SDK resolution', () {
    late Directory worktree;
    late Directory cache;
    String? previousCacheRoot;
    late FvmProcessRunner previousRunner;

    setUp(() {
      worktree = Directory.systemTemp.createTempSync('api_guard_sdk_');
      // Mark the checkout root so the ancestor lookup stops here instead of
      // walking up towards the real filesystem root.
      Directory(p.join(worktree.path, '.git')).createSync();
      cache = Directory.systemTemp.createTempSync('api_guard_fvm_');

      previousCacheRoot = fvmCacheRootOverride;
      previousRunner = fvmProcessRunner;
      fvmCacheRootOverride = cache.path;
      fvmProcessRunner = (executable, arguments) {
        throw StateError('Unexpected fvm invocation: $executable ${arguments.join(' ')}');
      };
    });

    tearDown(() {
      fvmCacheRootOverride = previousCacheRoot;
      fvmProcessRunner = previousRunner;
      worktree.deleteSync(recursive: true);
      cache.deleteSync(recursive: true);
    });

    /// Puts a fake Flutter binary for [version] in the FVM cache and returns
    /// its path. File contents do not matter; only existence is probed.
    String installFlutter(String version) {
      final binary = File(p.join(cache.path, version, 'bin', 'flutter'));
      binary.createSync(recursive: true);
      return binary.path;
    }

    String packagePath(String relative) => p.join(worktree.path, relative);

    void writeFvmrc(String version, {String dir = ''}) {
      File(p.join(packagePath(dir), '.fvmrc')).writeAsStringSync(jsonEncode({'flutter': version}));
    }

    void writeFvmConfig(String version, {String dir = ''}) {
      final file = File(p.join(packagePath(dir), '.fvm', 'fvm_config.json'));
      file.createSync(recursive: true);
      file.writeAsStringSync(jsonEncode({'flutterSdkVersion': version}));
    }

    void writePubspec(String flutterConstraint, {String dir = ''}) {
      File(p.join(packagePath(dir), 'pubspec.yaml')).writeAsStringSync('''
name: example
environment:
  sdk: ">=3.11.0 <4.0.0"
  flutter: "$flutterConstraint"
''');
    }

    group('findFvmFlutterBinary', () {
      test('finds an installed SDK in the FVM cache', () {
        final binary = installFlutter('3.24.0');

        expect(findFvmFlutterBinary('3.24.0'), binary);
      });

      test('returns null for a version that is not cached', () {
        expect(findFvmFlutterBinary('9.9.9'), isNull);
      });

      test('refuses a version that would escape the cache', () {
        expect(findFvmFlutterBinary('../../outside'), isNull);
      });

      test('reports the configured FVM cache root', () {
        // The cache root override stands in for FVM_CACHE_PATH here: both feed
        // the same probe, and only the override can be pointed at a temp dir.
        final binary = installFlutter('3.19.6');

        expect(findFvmFlutterBinary('3.19.6'), binary);
        expect(fvmCacheRoot(), cache.path);
      });
    });

    group('resolveRefSdk', () {
      test('reads the version from .fvmrc', () {
        final binary = installFlutter('3.24.0');
        writeFvmrc('3.24.0');

        final sdk = resolveRefSdk(worktree.path);

        expect(sdk.executable, binary);
        expect(sdk.source, 'fvm (.fvmrc)');
        expect(sdk.isAmbient, isFalse);
      });

      test('reads the version from .fvm/fvm_config.json', () {
        final binary = installFlutter('3.22.0');
        writeFvmConfig('3.22.0');

        final sdk = resolveRefSdk(worktree.path);

        expect(sdk.executable, binary);
        expect(sdk.source, 'fvm (.fvm/fvm_config.json)');
      });

      for (final (constraint, version) in [
        ('>=3.24.0 <4.0.0', '3.24.0'),
        ('^3.22.1', '3.22.1'),
        ('3.19.6', '3.19.6'),
        ('>=3.20.0', '3.20.0'),
      ]) {
        test('uses the lower bound of the pubspec constraint "$constraint"', () {
          final binary = installFlutter(version);
          writePubspec(constraint);

          final sdk = resolveRefSdk(worktree.path);

          expect(sdk.executable, binary);
          expect(sdk.source, 'fvm (pubspec.yaml)');
        });
      }

      test('prefers .fvmrc over .fvm/fvm_config.json and pubspec.yaml', () {
        final fvmrc = installFlutter('3.24.0');
        installFlutter('3.22.0');
        installFlutter('3.20.0');
        writeFvmrc('3.24.0');
        writeFvmConfig('3.22.0');
        writePubspec('>=3.20.0 <4.0.0');

        final sdk = resolveRefSdk(worktree.path);

        expect(sdk.executable, fvmrc);
        expect(sdk.source, 'fvm (.fvmrc)');
      });

      test('prefers .fvm/fvm_config.json over pubspec.yaml', () {
        final config = installFlutter('3.22.0');
        installFlutter('3.20.0');
        writeFvmConfig('3.22.0');
        writePubspec('>=3.20.0 <4.0.0');

        final sdk = resolveRefSdk(worktree.path);

        expect(sdk.executable, config);
        expect(sdk.source, 'fvm (.fvm/fvm_config.json)');
      });

      test('finds a repository-root .fvmrc for a nested package', () {
        final binary = installFlutter('3.24.0');
        writeFvmrc('3.24.0');
        final package = Directory(packagePath(p.join('packages', 'liquid_flutter')))..createSync(recursive: true);

        final sdk = resolveRefSdk(package.path);

        expect(sdk.executable, binary);
        expect(sdk.source, 'fvm (.fvmrc)');
      });

      test('falls back to the ambient SDK when nothing is pinned', () {
        final sdk = resolveRefSdk(worktree.path);

        expect(sdk.executable, 'flutter');
        expect(sdk.source, 'ambient');
        expect(sdk.isAmbient, isTrue);
      });

      test('ignores an unparseable .fvmrc', () {
        File(p.join(worktree.path, '.fvmrc')).writeAsStringSync('not json at all');

        expect(resolveRefSdk(worktree.path).source, 'ambient');
      });

      test('ignores a pubspec without a Flutter constraint', () {
        File(p.join(worktree.path, 'pubspec.yaml')).writeAsStringSync('''
name: example
environment:
  sdk: ">=3.11.0 <4.0.0"
''');

        expect(resolveRefSdk(worktree.path).source, 'ambient');
      });

      test('uses the ambient SDK when autodetection is disabled', () {
        installFlutter('3.24.0');
        writeFvmrc('3.24.0');

        final sdk = resolveRefSdk(worktree.path, options: const SdkOverrideOptions(autodetect: false));

        expect(sdk.source, 'ambient');
        expect(sdk.executable, 'flutter');
      });

      test('lets an explicit override win over the checkout pin', () {
        installFlutter('3.24.0');
        final override = installFlutter('3.19.6');
        writeFvmrc('3.24.0');

        final sdk = resolveRefSdk(
          worktree.path,
          options: SdkOverrideOptions(refSdkOverrides: {worktree.path: '3.19.6'}),
        );

        expect(sdk.executable, override);
        expect(sdk.source, 'fvm (--ref-sdk)');
      });

      test('falls back to the ambient SDK when the pinned version cannot be provided', () {
        writeFvmrc('3.24.0');
        fvmProcessRunner = (executable, arguments) {
          expect(executable, 'fvm');
          expect(arguments, ['install', '3.24.0']);
          return ProcessResult(0, 127, '', 'fvm: command not found');
        };

        final sdk = resolveRefSdk(worktree.path);

        expect(sdk.source, 'ambient');
        expect(sdk.executable, 'flutter');
      });
    });

    group('findOrInstallFvmFlutter', () {
      test('returns a cached binary without invoking the fvm CLI', () {
        final binary = installFlutter('3.24.0');

        expect(findOrInstallFvmFlutter('3.24.0'), binary);
      });

      test('installs a missing version through the fvm CLI', () {
        final binaryPath = p.join(cache.path, '3.30.0', 'bin', 'flutter');
        final invocations = <List<String>>[];
        fvmProcessRunner = (executable, arguments) {
          invocations.add([executable, ...arguments]);
          File(binaryPath).createSync(recursive: true);
          return ProcessResult(0, 0, '', '');
        };

        expect(findOrInstallFvmFlutter('3.30.0'), binaryPath);
        expect(invocations, [
          ['fvm', 'install', '3.30.0'],
        ]);
      });

      test('returns null when the fvm CLI is absent', () {
        fvmProcessRunner = (executable, arguments) => ProcessResult(0, 127, '', 'fvm: command not found');

        expect(findOrInstallFvmFlutter('3.24.0'), isNull);
      });

      test('returns null when fvm install succeeds without producing a binary', () {
        fvmProcessRunner = (executable, arguments) => ProcessResult(0, 0, '', '');

        expect(findOrInstallFvmFlutter('3.24.0'), isNull);
      });

      test('returns null when fvm install fails', () {
        fvmProcessRunner = (executable, arguments) => ProcessResult(0, 1, '', 'network error');

        expect(findOrInstallFvmFlutter('3.24.0'), isNull);
      });

      test('refuses a version that would escape the cache', () {
        expect(findOrInstallFvmFlutter('../../outside'), isNull);
      });
    });
  });
}
