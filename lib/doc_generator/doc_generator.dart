// ignore_for_file: experimental_member_use

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

  if (gitRef == 'HEAD') {
    logger.info('HEAD is not a valid git ref. Cannot cache documentation for current HEAD.');
    shouldCache = false;
  }

  // Check if we're in a git repository
  if (!await GitUtils.isGitRepository(gitRoot.path)) {
    logger.err('Not in a git repository. Cannot proceed with ref-based generation.');
    exit(1);
  }

  final repoPath = GitUtils.getRepositoryRoot(gitRoot.path);
  final currentHeadRef = await GitUtils.getCurrentRef(gitRoot.path);

  // Resolve the target ref to a commit hash
  String effectiveRef;
  if (gitRef == 'HEAD') {
    effectiveRef = currentHeadRef;
  } else {
    effectiveRef = await GitUtils.resolveRef(gitRef, gitRoot.path);
  }

  // Check if we're analyzing the current HEAD - if so, skip worktree creation
  final isCurrentHead = effectiveRef == currentHeadRef;
  String? worktreePath;
  Directory? worktreeDir;
  bool worktreeCreated = false;

  final dartRelativePath = relative(dartRoot.path, from: gitRoot.path);

  if (isCurrentHead) {
    logger.info('Analyzing current HEAD ($effectiveRef), using current working directory');
    worktreePath = null; // Use current directory
  } else {
    // Create worktree in cache directory
    worktreeDir = cache.getWorktreeDir(repoPath, effectiveRef);
    worktreePath = worktreeDir.path;

    logger.info('Creating worktree for ref $gitRef ($effectiveRef) at $worktreePath');

    try {
      await GitUtils.createWorktree(repoPath, gitRef, worktreePath);
      worktreeCreated = true;
      logger.info('Successfully created worktree at $worktreePath');
      final result = Process.runSync(
        "dart",
        ["pub", "get"],
        workingDirectory: join(worktreePath, dartRelativePath),
      );
      if (result.exitCode != 0) {
        logger.err('Failed to run dart pub get: ${result.stderr}');
        exit(1);
      }
    } catch (e) {
      logger.err('Failed to create worktree: $e');
      rethrow;
    }
  }

  final classes = <DocComponent>[];

  if (shouldCache) {
    if (cache.hasApiFile(repoPath, effectiveRef, dartRelativePath)) {
      logger.success('Using cached API documentation for $effectiveRef');
      final cachedContent = await cache.retrieveApiFile(
        repoPath,
        effectiveRef,
        dartRelativePath,
      );
      if (cachedContent != null) {
        logger.success('Using cached API documentation for $effectiveRef in $dartRelativePath');

        // Clean up worktree if it was created
        if (worktreeCreated && worktreePath != null) {
          try {
            await GitUtils.removeWorktree(repoPath, worktreePath);
            logger.detail('Cleaned up worktree at $worktreePath');
          } catch (e) {
            logger.err('Warning: Failed to clean up worktree: $e');
          }
        }

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

  logger.info('determining analysis dart root');
  logger.info('dartRoot: ${dartRoot.path}');
  logger.info('gitRoot: ${gitRoot.path}');
  logger.info('worktreePath: $worktreePath');

  // Determine the root path to use for analysis
  // If using a worktree, calculate the dartRoot path relative to the worktree
  Directory analysisDartRoot = dartRoot;
  if (worktreePath != null) {
    final gitRootAbs = Directory(gitRoot.path).absolute.path;
    final dartRootAbs = Directory(dartRoot.path).absolute.path;
    final relativePath = relative(dartRootAbs, from: gitRootAbs);
    analysisDartRoot = Directory(join(worktreePath, relativePath));
  }

  try {
    final (config, globbedFiles) = evaluateTargetFiles(analysisDartRoot.path);

    // Analyze pubspec
    final pubspecAnalyzer = PubspecAnalyzer(analysisDartRoot.path);
    final packageMetadata = await pubspecAnalyzer.analyze();

    final filesToAnalyze = <String>{};
    bool useRecursiveAnalysis = false;

    if (config.entryPoints.isNotEmpty) {
      useRecursiveAnalysis = true;
      for (final point in config.entryPoints) {
        filesToAnalyze.add(normalize(absolute(join(analysisDartRoot.path, point))));
      }
    } else {
      // Check if we should default to the main library file
      // We do this only if the include configuration is the default one
      final isDefaultInclude = config.include.length == 1 && config.include.contains('lib/**.dart');

      final mainLibrary = normalize(join(analysisDartRoot.path, 'lib', '${packageMetadata.packageName}.dart'));

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
      includedPaths: [normalize(absolute(analysisDartRoot.path))],
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
          // Attempt to resolve to relative path if within project.
          // For external packages (e.g. Flutter), we keep the package: URI
          // as the file path, as it provides a stable reference compared to
          // local pub-cache paths.
          final sourcePath = library.firstFragment.source.fullName;
          if (isWithin(analysisDartRoot.path, sourcePath)) {
            filePath = relative(sourcePath, from: analysisDartRoot.path);
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
            relative(file, from: analysisDartRoot.path),
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
      await cache.storeApiFile(repoPath, effectiveRef, dartRelativePath, output);
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
    // Clean up worktree if it was created
    if (worktreeCreated) {
      try {
        logger.detail('Cleaning up worktree at $worktreePath');
        await GitUtils.removeWorktree(repoPath, worktreePath!);
        logger.detail('Successfully cleaned up worktree');
      } catch (e) {
        logger.err('Warning: Failed to clean up worktree at $worktreePath: $e');
        logger.err('You may need to manually remove the worktree');
      }
    }
  }
}
