import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:mtrust_api_guard/bootstrap.dart';
import 'package:mtrust_api_guard/doc_comparator/parse_doc_file.dart';
import 'package:mtrust_api_guard/doc_generator/cache.dart';
import 'package:mtrust_api_guard/doc_generator/doc_visitor.dart';
import 'package:mtrust_api_guard/doc_generator/git_utils.dart';
import 'package:mtrust_api_guard/logger.dart';
import 'package:mtrust_api_guard/doc_generator/pubspec_analyzer.dart';
import 'package:mtrust_api_guard/mtrust_api_guard.dart';
import 'package:path/path.dart';

Future<PackageApi> generateDocs({
  required String gitRef,
  required String? out,
  required Directory dartRoot,
  required Directory gitRoot,
  required bool shouldCache,
}) async {
  final cache = Cache();
  // Check if we're in a git repository
  if (!await GitUtils.isGitRepository(gitRoot.path)) {
    logger.err('Not in a git repository. Cannot proceed with ref-based generation.');
    exit(1);
  }

  // Check for uncommitted changes if we're going to checkout a ref
  if (gitRef != 'HEAD' && GitUtils.hasUncommittedChanges(gitRoot.path)) {
    logger.err('Repository has uncommitted changes. Please commit or stash them before proceeding.');
    logger.err('This prevents potential data loss during ref checkout.');
    exit(1);
  }

  final originalRef = await GitUtils.getCurrentRef(gitRoot.path);
  final originalBranch = await GitUtils.getCurrentBranch(gitRoot.path);

  // If the ref is HEAD, get the current ref (commit hash)
  if (gitRef == 'HEAD') {
    gitRef = await GitUtils.getCurrentRef(gitRoot.path);
  }

  logger.info('Checking out ref: $gitRef');
  await GitUtils.checkoutRef(gitRef, gitRoot.path);
  logger.info('Successfully checked out ref: $gitRef');
  final effectiveRef = await GitUtils.getCurrentRef(gitRoot.path);

  final repoPath = GitUtils.getRepositoryRoot(gitRoot.path);
  final classes = <DocComponent>[];

  Future<void> restoreOriginalState() async {
    try {
      logger.info('Restoring original state...');
      if (originalBranch != null) {
        await GitUtils.checkoutRef(originalBranch, gitRoot.path);
      } else {
        await GitUtils.checkoutRef(originalRef, gitRoot.path);
      }
      logger.info('Successfully restored original state');
    } catch (e) {
      logger.err('Warning: Failed to restore original state: $e');
      logger.err('Please manually checkout your original branch/ref');
    }
  }

  if (shouldCache) {
    if (cache.hasApiFile(repoPath, effectiveRef)) {
      logger.success('Using cached API documentation for $effectiveRef');
      final cachedContent = await cache.retrieveApiFile(repoPath, effectiveRef);
      if (cachedContent != null) {
        logger.success('Using cached API documentation for $effectiveRef');
        await restoreOriginalState();

        // Write the cached content to file if requested
        if (out != null) {
          if (!File(out).existsSync()) {
            File(out).createSync();
          }
          await File(out).writeAsString(cachedContent);
          logger.success('Wrote cached documentation to $out');
        }

        return parsePackageApiFile(cachedContent);
      }
    }
  }

  try {
    final (dartFiles, exclusions) = evaluateTargetFiles(dartRoot.path);

    if (dartFiles.isEmpty) {
      logger.err('No Dart files found in the specified paths. Exiting');
      exit(1);
    }

    // Analyze pubspec
    final pubspecAnalyzer = PubspecAnalyzer(dartRoot.path);
    final packageMetadata = await pubspecAnalyzer.analyze();

    final contextCollection = AnalysisContextCollection(
      includedPaths: dartFiles.toList(),
      excludedPaths: exclusions.toList(),
    );

    final progress = logger.progress("Analyzing dart files");

    // Analyze each file
    for (final file in dartFiles) {
      try {
        final context = contextCollection.contextFor(file);
        final library = await context.currentSession.getResolvedLibrary(file);
        if (library is! ResolvedLibraryResult) {
          throw StateError('Library not resolved.');
        }

        final visitor = DocVisitor(
          filePath: relative(
            file,
            from: contextCollection.contextFor(file).contextRoot.root.path,
          ),
        );
        library.element2.accept2(visitor);
        classes.addAll(visitor.components);
      } catch (e) {
        logger.err('Error analyzing file $file: $e');
      }
      progress.update(
        "Analyzed $file [${dartFiles.toList().indexOf(file) + 1}/${dartFiles.length}]",
      );
    }

    progress.complete();

    logger.success(
      'Found ${classes.length} classes: ${classes.map((e) => e.name).join(', ')}',
    );
    contextCollection.dispose();

    final outputProgress = logger.progress("Generating output");

    final packageApi = PackageApi(
      metadata: packageMetadata,
      components: classes,
    );

    // Generate output
    final output = const JsonEncoder.withIndent('  ').convert(packageApi);

    outputProgress.complete();

    // Cache the generated documentation if requested
    if (shouldCache) {
      await cache.storeApiFile(repoPath, effectiveRef, output);
      logger.success('Cached documentation for ref: $effectiveRef');
    }

    // Write the generated documentation to a file if requested
    if (out != null) {
      if (!File(out).existsSync()) {
        File(out).createSync();
      }
      await File(out).writeAsString(output);
      logger.success('Wrote generated documentation to $out');
    }

    return packageApi;
  } finally {
    restoreOriginalState();
  }
}
