import 'dart:io';

import 'package:mtrust_api_guard/config/config.dart';
import 'package:path/path.dart';

/// Where an analysis of a package starts, and whether those starting points
/// describe what a consumer can reach.
class EntryPoints {
  const EntryPoints({required this.files, required this.followsExports});

  /// Absolute, normalized paths to start from.
  final Set<String> files;

  /// Whether [files] are entry points whose export closure is the package's
  /// public API.
  ///
  /// False when the package has neither `entry_points` nor a main library, in
  /// which case [files] is just everything the `include` globs matched and
  /// there is no closure to speak of. The doc generator then documents each
  /// file on its own, and the dead code scan cannot prove a public declaration
  /// unreachable.
  final bool followsExports;
}

/// Resolves where to enter [root] for analysis.
///
/// Explicit `entry_points` win. Failing that, a package that has not customised
/// `include` and ships a `lib/<package_name>.dart` is entered through that
/// library. Otherwise every file [globbedFiles] matched is analyzed on its own.
///
/// A [packageName] of `null` means the pubspec gave no name to build a main
/// library path from, which lands in the same place as not having one.
EntryPoints resolveEntryPoints({
  required String root,
  required ApiGuardConfig config,
  required String? packageName,
  required Set<String> globbedFiles,
}) {
  if (config.entryPoints.isNotEmpty) {
    return EntryPoints(
      files: {for (final point in config.entryPoints) normalize(absolute(join(root, point)))},
      followsExports: true,
    );
  }

  final isDefaultInclude = config.include.length == 1 && config.include.contains('lib/**.dart');

  if (isDefaultInclude && packageName != null) {
    final mainLibrary = normalize(absolute(join(root, 'lib', '$packageName.dart')));
    if (File(mainLibrary).existsSync()) {
      return EntryPoints(files: {mainLibrary}, followsExports: true);
    }
  }

  return EntryPoints(files: globbedFiles, followsExports: false);
}
