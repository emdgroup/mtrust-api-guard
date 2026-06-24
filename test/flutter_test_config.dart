import 'dart:async';
import 'dart:io';

import 'helpers/test_bootstrap.dart';

/// Runs before the test suite to remove stale scaffolds and bootstrap binaries/fixtures.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  _removeLegacyScaffoldDirsSync();
  await TestBootstrap.ensureReady();
  await testMain();
}

void _removeLegacyScaffoldDirsSync() {
  for (final path in ['test/fixtures/package_base', 'test/fixtures/plugin_base']) {
    final dir = Directory(path);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  }
}
