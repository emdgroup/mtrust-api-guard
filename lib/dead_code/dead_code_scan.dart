import 'dart:io';

import 'package:mtrust_api_guard/dead_code/dead_code_delta.dart';
import 'package:mtrust_api_guard/dead_code/dead_code_report.dart';

/// Scans for dead code and returns the renderer for what it found.
///
/// Given a [baseRef] the scan reports what changed since that revision, which
/// is what a reviewer can act on: they can do something about a declaration
/// this branch orphaned, and nothing about debt that predates it. Without one
/// it reports everything currently dead. [newRef] is the other side of that
/// comparison, and defaults to the working tree.
///
/// [baseUrl] is where the tree is browsable, which turns the file names in a
/// markdown report into links.
Future<DeadCodeMarkdown> scanDeadCode({
  required Directory dartRoot,
  required Directory gitRoot,
  String? baseRef,
  String? newRef,
  String? baseUrl,
  int markdownHeaderLevel = 1,
}) async {
  final fileUrlBuilder = baseUrl == null ? null : (String path) => '$baseUrl/$path';

  if (baseRef == null) {
    final report = await scanRevision(ref: newRef, dartRoot: dartRoot, gitRoot: gitRoot);
    return DeadCodeFormatter(report, fileUrlBuilder: fileUrlBuilder, markdownHeaderLevel: markdownHeaderLevel);
  }

  final delta = await compareDeadCode(baseRef: baseRef, newRef: newRef, dartRoot: dartRoot, gitRoot: gitRoot);
  return DeadCodeDeltaFormatter(delta, fileUrlBuilder: fileUrlBuilder, markdownHeaderLevel: markdownHeaderLevel);
}
