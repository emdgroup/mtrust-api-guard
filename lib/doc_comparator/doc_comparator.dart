// ignore_for_file: avoid_print

import 'dart:io';

import 'package:mtrust_api_guard/doc_comparator/api_change_formatter.dart';
import 'package:mtrust_api_guard/doc_comparator/doc_ext.dart';
import 'package:mtrust_api_guard/doc_comparator/get_ref.dart';

import 'package:mtrust_api_guard/logger.dart';
import 'package:mtrust_api_guard/mtrust_api_guard.dart';

Future<List<ApiChange>> compare({
  required Set<ApiChangeMagnitude> magnitudes,
  required String baseRef,
  required String newRef,
  required Directory dartRoot,
  required Directory gitRoot,
  required bool cache,
}) async {
  // Load config and determine doc file path

  final baseDoc = await getRef(ref: baseRef, dartRoot: dartRoot, gitRoot: gitRoot, cache: cache);
  final newDoc = await getRef(ref: newRef, dartRoot: dartRoot, gitRoot: gitRoot, cache: cache);

  final apiChanges = baseDoc.compareTo(
    newDoc,
  );
  final formatter = ApiChangeFormatter(
    apiChanges,
    magnitudes: magnitudes,
  );
  logger.info(formatter.highestMagnitudeText);
  logger.info(formatter.format());

  return apiChanges;
}
