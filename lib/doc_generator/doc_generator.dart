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
import 'package:mtrust_api_guard/models/doc_items.dart';
import 'package:mtrust_api_guard/mtrust_api_guard.dart';
import 'package:path/path.dart';

Future<List<DocComponent>> generateDocs({
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
    } catch (e) {
      logger.err('Failed to create worktree: $e');
      rethrow;
    }
  }

  final classes = <DocComponent>[];

  if (shouldCache) {
    if (cache.hasApiFile(repoPath, effectiveRef)) {
      logger.success('Using cached API documentation for $effectiveRef');
      final cachedContent = await cache.retrieveApiFile(repoPath, effectiveRef);
      if (cachedContent != null) {
        logger.success('Using cached API documentation for $effectiveRef');

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

        return parseDocComponentsFile(cachedContent);
      }
    }
  }

  // Determine the root path to use for analysis
  // If using a worktree, calculate the dartRoot path relative to the worktree
  final analysisDartRoot = worktreePath != null
      ? () {
          final gitRootAbs = Directory(gitRoot.path).absolute.path;
          final dartRootAbs = Directory(dartRoot.path).absolute.path;
          final relativePath = relative(dartRootAbs, from: gitRootAbs);
          // Handle case where dartRoot == gitRoot (relative path would be ".")
          if (relativePath == '.' || relativePath.isEmpty) {
            return Directory(worktreePath!);
          }
          return Directory(join(worktreePath!, relativePath));
        }()
      : dartRoot;

  try {
    final (dartFiles, exclusions) = evaluateTargetFiles(analysisDartRoot.path);

    if (dartFiles.isEmpty) {
      logger.err('No Dart files found in the specified paths. Exiting');
      exit(1);
    }

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

    // Generate output
    final output = const JsonEncoder.withIndent('  ').convert(classes);

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
  } finally {
    // Clean up worktree if it was created
    if (worktreeCreated && worktreePath != null) {
      try {
        logger.detail('Cleaning up worktree at $worktreePath');
        await GitUtils.removeWorktree(repoPath, worktreePath);
        logger.detail('Successfully cleaned up worktree');
      } catch (e) {
        logger.err('Warning: Failed to clean up worktree at $worktreePath: $e');
        logger.err('You may need to manually remove the worktree');
      }
    }
  }

  return classes;
}
