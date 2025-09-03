import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:mtrust_api_guard/bootstrap.dart';
import 'package:mtrust_api_guard/doc_comparator/parse_doc_file.dart';
import 'package:mtrust_api_guard/doc_generator/cache.dart';
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
        return parseDocComponentsFile(cachedContent);
      }
    }
  }

  try {
    final (dartFiles, exclusions) = evaluateTargetFiles(dartRoot.path);

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

        final classesInLibrary = library.element2.classes;

        for (final classItem in classesInLibrary) {
          classes.add(DocComponent(
            name: classItem.name3.toString(),
            filePath: relative(
              file,
              from: contextCollection.contextFor(file).contextRoot.root.path,
            ),
            isNullSafe: true,
            description: classItem.documentationComment?.replaceAll("///", "") ?? "",
            constructors: classItem.constructors2
                .map((e) => DocConstructor(
                      name: e.name3.toString(),
                      signature: e.formalParameters
                          .map((param) => DocParameter(
                                description: param.documentationComment ?? "",
                                name: param.name3.toString(),
                                type: param.type.toString(),
                                named: param.isNamed,
                                required: param.isRequired,
                              ))
                          .toList(),
                      features: [
                        if (e.isConst) "const",
                        if (e.isFactory) "factory",
                        if (e.isExternal) "external",
                      ],
                    ))
                .toList(),
            properties: classItem.fields2
                .map((e) => DocProperty(
                      name: e.name3.toString(),
                      type: e.type.toString(),
                      description: e.documentationComment ?? "",
                      features: [
                        if (e.isStatic) "static",
                        if (e.isCovariant) "covariant",
                        if (e.isFinal) "final",
                        if (e.isConst) "const",
                        if (e.isLate) "late",
                      ],
                    ))
                .toList(),
            methods: classItem.methods2.map((e) => e.name3.toString()).toList(),
          ));
        }
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
    final output = jsonEncode(classes);

    outputProgress.complete();

    // Cache the generated documentation if requested
    if (shouldCache) {
      await cache.storeApiFile(repoPath, effectiveRef, output);
      logger.success('Cached documentation for ref: $effectiveRef');
    }

    // Write the generated documentation to a file if requested
    if (out != null) {
      await File(out).writeAsString(output);
      logger.success('Wrote generated documentation to $out');
    }
  } finally {
    restoreOriginalState();
  }

  return classes;
}
