import 'dart:async';
import 'dart:io';

Future<Directory> findProjectRoot(String path) async {
  var currentDir = Directory(path);

  while (currentDir.path.split("/").length > 1) {
    if (File('${currentDir.path}/pubspec.yaml').existsSync()) {
      return currentDir;
    }
    currentDir = currentDir.parent;
  }

  throw Exception('pubspec.yaml not found in $path');
}
