// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:mtrust_api_guard/doc_comparator/api_change_formatter.dart';
import 'package:mtrust_api_guard/doc_comparator/doc_comparator_command.dart';
import 'package:mtrust_api_guard/doc_comparator/doc_ext.dart';
import 'package:mtrust_api_guard/doc_comparator/doc_parser.dart';
import 'package:mtrust_api_guard/logger.dart';
import 'package:mtrust_api_guard/mtrust_api_guard.dart';

void main(List<String> args) async {
  final cmd = DocComparatorCommand();
  final argResults = cmd.argResults ?? cmd.argParser.parse(args);

  final magArg = argResults['magnitude'] as String;
  final magnitude = ApiChangeMagnitude.values.firstWhereOrNull(
    (element) => element.toString().contains(magArg),
  );

  final baseFile = argResults['base'] as String;
  final newFile = argResults['new'] as String;
  final newContent = await _getFileContent(newFile);
  final baseContent = await _getFileContent(baseFile);

  final apiChanges = parseDocComponentsFile(baseContent).compareTo(
    parseDocComponentsFile(newContent),
  );
  logger.info(
      ApiChangeFormatter(apiChanges, showUpToMagnitude: magnitude).format());
}

Future<String> _getFileContent(String path) {
  if (path.startsWith('https://')) {
    return _getRemoteContent(Uri.parse(path));
  } else if (path.contains(':')) {
    return _getGitFileContent(path);
  } else {
    return _getLocalFileContent(path);
  }
}

Future<String> _getLocalFileContent(String path) async {
  final file = File(path);
  if (!file.existsSync()) {
    throw ArgumentError('File not found: $path');
  }
  return File(path).readAsStringSync();
}

Future<String> _getRemoteContent(Uri uri) async {
  final response = HttpClient().getUrl(uri);
  return await response.then((value) => value.close()).then((value) {
    return value.transform(const Utf8Decoder()).join();
  });
}

Future<String> _getGitFileContent(String fileIdentifier) async {
  final parts = fileIdentifier.split(':');
  if (parts.length < 2) {
    throw ArgumentError(
        'Invalid fileIdentifier format. Expected "<tree-ish>:<file-path>".');
  }

  final treeIsh = parts.first;
  final path = parts.sublist(1).join(':'); // Handle file paths with colons

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
    throw Exception('git show failed: $stderrResult');
  }

  return stdoutResult;
}
