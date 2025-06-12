import 'dart:convert';
import 'dart:io';

import 'package:mtrust_api_guard/logger.dart';
import 'package:path/path.dart';

Future<String> getFileContent(String path) async {
  if (path.contains(':')) {
    logger.info('Fetching file from git: $path');
    return _getGitFileContent(path);
  } else {
    logger.info('Reading local file: $path');
    return _getLocalFileContent(path);
  }
}

Future<String> _getLocalFileContent(String path) async {
  final file = File(path);
  if (!file.existsSync()) {
    throw ArgumentError(
        'File not found: $path. Please check the path and try again.');
  }
  try {
    return File(path).readAsStringSync();
  } catch (e) {
    throw Exception('Failed to read local file at $path: $e');
  }
}

Future<String> _getGitFileContent(String fileIdentifier) async {
  final parts = fileIdentifier.split(':');
  if (parts.length < 2) {
    throw ArgumentError(
        'Invalid fileIdentifier format. Expected "<tree-ish>:<file-path>", got "$fileIdentifier".');
  }

  final treeIsh = parts.first;
  final path = parts.sublist(1).join(':'); // Handle file paths with colons

  logger.info('Running: git show $treeIsh:$path');
  final process = await Process.start(
    'git',
    ['show', '$treeIsh:$path'],
    mode: ProcessStartMode.normal, // Capture output instead of inheriting it
  );

  final stdoutFuture = process.stdout.transform(utf8.decoder).join();
  final stderrFuture = process.stderr.transform(utf8.decoder).join();

  final exitCode = await process.exitCode;
  final stdoutResult = await stdoutFuture;
  final stderrResult = await stderrFuture;

  if (exitCode != 0) {
    throw Exception(
        'git show failed for $treeIsh:$path with exit code $exitCode. Error: $stderrResult');
  }

  return stdoutResult;
}

Future<String> getPreviousGitFileContent(
    String filePath, Directory rootDir) async {
  // Get the previous two commit hashes that changed the file
  final relPath = relative(filePath, from: rootDir.path);
  logger.info('Finding previous commits that changed $relPath');
  final process = await Process.start(
    'git',
    ['log', '-n', '2', '--pretty=format:%H', '--', relPath],
    mode: ProcessStartMode.normal,
    workingDirectory: rootDir.path,
  );

  final stdoutFuture = process.stdout.transform(utf8.decoder).join();
  final stderrFuture = process.stderr.transform(utf8.decoder).join();
  final exitCode = await process.exitCode;
  final stdoutResult = await stdoutFuture;
  final stderrResult = await stderrFuture;
  if (exitCode != 0) {
    throw Exception(
        'git log failed for $relPath with exit code $exitCode. Error: $stderrResult');
  }
  final hashes = stdoutResult.split('\n').where((h) => h.isNotEmpty).toList();
  if (hashes.isEmpty) {
    throw Exception(
        'No git history found for $relPath. The file may not have enough history in git.');
  }

  // Read current file content
  final currentContent = await _getLocalFileContent(filePath);

  // Read content at latest commit
  final latestCommit = hashes[0];
  final latestCommitContent =
      await _getGitFileContent('$latestCommit:$relPath');

  // If current file matches latest commit, use previous commit
  if (currentContent == latestCommitContent) {
    if (hashes.length < 2) {
      throw Exception(
          'No previous version found for $relPath. The file may not have enough history in git.');
    }
    final previousCommit = hashes[1];
    logger.info(
        'Current file matches latest commit. Using previous commit $previousCommit for $relPath');
    return _getGitFileContent('$previousCommit:$relPath');
  } else {
    logger.info(
        'Current file does not match latest commit. Using latest commit $latestCommit for $relPath');
    return latestCommitContent;
  }
}
