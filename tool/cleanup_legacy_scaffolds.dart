import 'dart:io';

/// Removes legacy Flutter scaffolds from test/fixtures before test discovery.
void main() {
  for (final path in ['test/fixtures/package_base', 'test/fixtures/plugin_base']) {
    final dir = Directory(path);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
      stdout.writeln('Removed legacy scaffold: $path');
    }
  }
}
