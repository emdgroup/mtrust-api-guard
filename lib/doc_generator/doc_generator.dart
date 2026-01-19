import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element2.dart';
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
    final (config, globbedFiles) = evaluateTargetFiles(dartRoot.path);

    // Analyze pubspec
    final pubspecAnalyzer = PubspecAnalyzer(dartRoot.path);
    final packageMetadata = await pubspecAnalyzer.analyze();

    final filesToAnalyze = <String>{};
    bool useRecursiveAnalysis = false;

    if (config.entryPoints.isNotEmpty) {
      useRecursiveAnalysis = true;
      for (final point in config.entryPoints) {
        filesToAnalyze.add(normalize(absolute(join(dartRoot.path, point))));
      }
    } else {
      // Check if we should default to the main library file
      // We do this only if the include configuration is the default one
      final isDefaultInclude = config.include.length == 1 && config.include.contains('lib/**.dart');

      final mainLibrary = normalize(join(dartRoot.path, 'lib', '${packageMetadata.packageName}.dart'));

      if (isDefaultInclude && File(mainLibrary).existsSync()) {
        useRecursiveAnalysis = true;
        filesToAnalyze.add(mainLibrary);
      } else {
        filesToAnalyze.addAll(globbedFiles);
      }
    }

    if (filesToAnalyze.isEmpty) {
      logger.err('No Dart files found to analyze. Exiting');
      exit(1);
    }

    final contextCollection = AnalysisContextCollection(
      includedPaths: [dartRoot.path],
      excludedPaths: config.exclude.toList(),
    );

    final progress = logger.progress("Analyzing dart files");
    final visitedLibraries = <String>{};

    // Recursive visitor function
    void visitLibraryRecursive(LibraryElement2 library, String entryPoint) {
      if (visitedLibraries.contains(library.uri.toString())) return;
      visitedLibraries.add(library.uri.toString());

      // Visit all libraries exported from this library, including any
      // re-exported libraries from dependencies. Re-exported symbols are
      // considered part of this package's public API and must be included
      // in the generated documentation.

      String filePath = library.uri.toString();
      try {
        if (library.uri.isScheme('package')) {
          // Attempt to resolve to relative path if within project
          final sourcePath = library.firstFragment.source.fullName;
          if (isWithin(dartRoot.path, sourcePath)) {
            filePath = relative(sourcePath, from: dartRoot.path);
          }
        }
      } catch (e) {
        // Ignore resolution errors, fallback to uri
      }

      final visitor = DocVisitor(
        filePath: filePath,
        entryPoint: entryPoint,
      );
      library.accept2(visitor);
      classes.addAll(visitor.components);

      for (final exported in library.exportedLibraries2) {
        visitLibraryRecursive(exported, entryPoint);
      }
    }

    for (final file in filesToAnalyze) {
      try {
        final context = contextCollection.contextFor(file);
        final libraryResult = await context.currentSession.getResolvedLibrary(file);

        if (libraryResult is! ResolvedLibraryResult) {
          logger.err('Library not resolved: $file');
          continue;
        }

        if (useRecursiveAnalysis) {
          visitLibraryRecursive(
            libraryResult.element2,
            relative(file, from: dartRoot.path),
          );
        } else {
          // Legacy / Glob mode: non-recursive, just the file
          final visitor = DocVisitor(
            filePath: relative(
              file,
              from: contextCollection.contextFor(file).contextRoot.root.path,
            ),
            entryPoint: relative(
              file,
              from: contextCollection.contextFor(file).contextRoot.root.path,
            ),
          );
          libraryResult.element2.accept2(visitor);
          classes.addAll(visitor.components);
        }
      } catch (e) {
        logger.err('Error analyzing file $file: $e');
      }
      if (!useRecursiveAnalysis) {
        progress.update(
          "Analyzed $file [${filesToAnalyze.toList().indexOf(file) + 1}/${filesToAnalyze.length}]",
        );
      }
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
