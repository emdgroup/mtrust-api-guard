// ignore_for_file: avoid_print

import 'dart:io';

import 'package:mtrust_api_guard/doc_comparator/doc_ext.dart';
import 'package:mtrust_api_guard/doc_comparator/get_ref.dart';

import 'package:mtrust_api_guard/mtrust_api_guard.dart';

Future<List<ApiChange>> compare({
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

  return apiChanges;
}
