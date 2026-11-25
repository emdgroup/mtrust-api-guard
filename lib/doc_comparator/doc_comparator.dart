// ignore_for_file: avoid_print

import 'dart:io';

import 'package:mtrust_api_guard/doc_comparator/comparators/component_comparator.dart';
import 'package:mtrust_api_guard/doc_comparator/comparators/metadata_comparator.dart';
import 'package:mtrust_api_guard/doc_comparator/get_ref.dart';
import 'package:mtrust_api_guard/doc_generator/resolve_ref_sdk.dart';

import 'package:mtrust_api_guard/mtrust_api_guard.dart';

Future<List<ApiChange>> compare({
  required String baseRef,
  required String newRef,
  required Directory dartRoot,
  required Directory gitRoot,
  required bool cache,
  SdkOverrideOptions? sdkOptions,
}) async {
  // Load config and determine doc file path

  final baseApi = await getRef(
    ref: baseRef,
    dartRoot: dartRoot,
    gitRoot: gitRoot,
    cache: cache,
    sdkOptions: sdkOptions,
  );
  final newApi = await getRef(ref: newRef, dartRoot: dartRoot, gitRoot: gitRoot, cache: cache, sdkOptions: sdkOptions);

  return compareApis(baseApi, newApi);
}

/// Computes the API changes between two already-resolved package APIs.
List<ApiChange> compareApis(PackageApi baseApi, PackageApi newApi) {
  final apiChanges = baseApi.components.compareTo(newApi.components);

  apiChanges.addAll(baseApi.metadata.compareTo(newApi.metadata));

  return apiChanges;
}
