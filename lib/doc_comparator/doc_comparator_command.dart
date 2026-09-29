import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:collection/collection.dart';
import 'package:mtrust_api_guard/api_guard_command_mixin.dart';
import 'package:mtrust_api_guard/doc_comparator/api_change.dart';
import 'package:mtrust_api_guard/doc_comparator/api_change_formatter.dart';
import 'package:mtrust_api_guard/doc_comparator/doc_comparator.dart';
import 'package:mtrust_api_guard/config/config.dart';
import 'package:mtrust_api_guard/dead_code/dead_code_scan.dart';
import 'package:mtrust_api_guard/doc_comparator/apply_overrides.dart';
import 'package:mtrust_api_guard/doc_generator/git_utils.dart';
import 'package:mtrust_api_guard/logger.dart';

class DocComparatorCommand extends Command
    with ApiGuardCommandMixinWithBaseNew, ApiGuardCommandMixinWithRoot, ApiGuardCommandMixinWithCache {
  @override
  String get description => "Compare two API documentation files";

  @override
  String get name => "compare";

  static final DocComparatorCommand _instance = DocComparatorCommand._internal();

  factory DocComparatorCommand() => _instance;

  DocComparatorCommand._internal() {
    argParser.addMultiOption(
      'magnitudes',
      abbr: 'm',
      help: 'Show only changes with the specified magnitudes',
      defaultsTo: ['major', 'minor', 'patch'],
      allowed: ['major', 'minor', 'patch'],
    );
    argParser.addOption('out', help: 'Write the comparison results to a file');
    argParser.addOption('base-url', help: 'Base URL for file links (e.g. https://github.com/org/repo/blob/v1.0.0)');
    argParser.addFlag(
      'dead-code',
      help:
          'Append a warning section listing declarations nothing live refers to '
          'and no consumer can reach. Never affects the exit code.',
      defaultsTo: false,
    );
  }

  bool get deadCode {
    return argResults?['dead-code'] as bool;
  }

  String? get out {
    return argResults?['out'] as String?;
  }

  String? get baseUrl {
    return argResults?['base-url'] as String?;
  }

  Set<ApiChangeMagnitude> get magnitudes {
    final magnitudes = argResults?['magnitudes'] as List<String>;
    return magnitudes
        .map((e) => ApiChangeMagnitude.values.firstWhereOrNull((element) => element.toString().contains(e)))
        .whereType<ApiChangeMagnitude>()
        .toSet();
  }

  @override
  FutureOr? run() async {
    final resolvedBaseRef = baseRef ?? await GitUtils.getPreviousRef(Directory.current.path);

    final changes = await compare(
      baseRef: resolvedBaseRef,
      newRef: newRef,
      dartRoot: root,
      gitRoot: Directory.current,
      cache: cache,
    );

    // Load config
    final config = ApiGuardConfig.load(root);
    applyMagnitudeOverrides(changes, config);

    final formatter = ApiChangeFormatter(changes, magnitudes: magnitudes);

    final deadCodeSection = deadCode ? await _deadCodeSection(resolvedBaseRef, newRef) : '';

    if (!formatter.hasRelevantChanges && deadCodeSection.isEmpty) {
      logger.info('No relevant changes detected');
      exit(0);
    }

    final formattedOutput = [
      if (formatter.hasRelevantChanges) formatter.format(),
      if (deadCodeSection.isNotEmpty) deadCodeSection,
    ].join();

    if (out != null) {
      if (!File(out!).existsSync()) {
        File(out!).createSync();
      }
      await File(out!).writeAsString(formattedOutput);
      logger.success('Wrote comparison results to $out');
    } else {
      // ignore: avoid_print
      print(formattedOutput);
    }
  }

  /// Renders the dead code section for the comparison.
  ///
  /// Reporting only. A finding never changes the exit code, so a false positive
  /// costs a reader a moment rather than blocking a merge.
  Future<String> _deadCodeSection(String? resolvedBaseRef, String newRef) async {
    try {
      // `compare` also accepts a path to a previously generated api json as a
      // ref. That is enough to diff an API against, but there is no tree behind
      // it to scan, so those fall back to what can be scanned: everything
      // currently dead, in the working tree.
      final scannableBase = resolvedBaseRef != null && await _isGitRef(resolvedBaseRef) ? resolvedBaseRef : null;
      if (resolvedBaseRef != null && scannableBase == null) {
        logger.warn('$resolvedBaseRef is not a git ref, reporting all dead code instead of the delta');
      }

      final scannableNew = await _isGitRef(newRef) ? newRef : null;
      if (scannableNew == null) {
        logger.warn('$newRef is not a git ref, scanning the working tree for dead code instead');
      }

      final scan = await scanDeadCode(
        dartRoot: root,
        gitRoot: Directory.current,
        baseRef: scannableBase,
        newRef: scannableNew,
        baseUrl: baseUrl,
      );
      return scan.formatMarkdown();
    } catch (e) {
      logger.warn('Dead code scan failed, continuing without it: $e');
      return '';
    }
  }

  /// Whether [ref] names something git can resolve, as opposed to a generated
  /// api json file.
  Future<bool> _isGitRef(String ref) async {
    if (File(ref).existsSync()) return false;
    try {
      await GitUtils.resolveRef(ref, Directory.current.path);
      return true;
    } catch (_) {
      return false;
    }
  }
}
