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
import 'package:yaml/yaml.dart';

/// Checks if Flutter command is available
bool _isFlutterAvailable() {
  try {
    final result = Process.runSync('flutter', ['--version'], runInShell: true);
    return result.exitCode == 0;
  } catch (e) {
    return false;
  }
}

/// Checks if a project is a Flutter project by examining pubspec.yaml
bool _isFlutterProject(String packagePath) {
  final pubspecFile = File(join(packagePath, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) {
    return false;
  }

  try {
    final pubspecContent = pubspecFile.readAsStringSync();
    final pubspecYaml = loadYaml(pubspecContent);

    // Check for Flutter SDK dependency in dependencies
    if (pubspecYaml['dependencies'] is Map) {
      final deps = pubspecYaml['dependencies'] as Map;
      if (deps.containsKey('flutter')) {
        return true;
      }
    }

    // Check for Flutter SDK dependency in dev_dependencies
    if (pubspecYaml['dev_dependencies'] is Map) {
      final devDeps = pubspecYaml['dev_dependencies'] as Map;
      if (devDeps.containsKey('flutter')) {
        return true;
      }
    }

    // Check for Flutter environment constraint
    if (pubspecYaml['environment'] is Map) {
      final env = pubspecYaml['environment'] as Map;
      if (env.containsKey('flutter')) {
        return true;
      }
    }

    return false;
  } catch (e) {
    // If we can't parse the pubspec, default to dart pub get
    logger.detail('Failed to parse pubspec.yaml to detect Flutter project: $e');
    return false;
  }
}

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

      // Determine if this is a Flutter project and use the appropriate pub get command
      final packagePath = join(worktreePath, dartRelativePath);
      final isFlutterProject = _isFlutterProject(packagePath);
      final isFlutterAvailable = _isFlutterAvailable();

      // Only use flutter if the project is a Flutter project AND Flutter is available
      final useFlutter = isFlutterProject && isFlutterAvailable;
      final command = useFlutter ? 'flutter' : 'dart';
      final args = ['pub', 'get'];

      if (isFlutterProject && !isFlutterAvailable) {
        logger.warn('Flutter project detected but Flutter is not available, falling back to dart pub get');
      }

      logger.info(
          'Detected ${isFlutterProject ? "Flutter" : "Dart"} project, running $command ${args.join(' ')} in $packagePath');
      final result = Process.runSync(
        command,
        args,
        workingDirectory: packagePath,
      );
      if (result.exitCode != 0) {
        logger.err('Failed to run $command ${args.join(' ')}: ${result.stderr} in $packagePath');
        if (result.stdout.toString().isNotEmpty) {
          logger.err('stdout: ${result.stdout}');
        }
        throw Exception('Failed to run $command ${args.join(' ')} in $packagePath (exit code: ${result.exitCode})');
      }
    } catch (e) {
      logger.err('Failed to create worktree: $e');
      rethrow;
    }
  }

  final classes = <DocComponent>[];

  if (shouldCache) {
    if (cache.hasApiFileForRef(repoPath, effectiveRef, dartRelativePath)) {
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

      // Visit all libraries exported from this library. For host-package
      // libraries the export chain is followed recursively so that
      // re-exported symbols appear in the generated documentation.
      // External dependencies are visited (their symbols are part of the
      // public API) but their own re-exports are NOT followed to avoid
      // pulling in large transitive graphs (e.g. Flutter/vector_math).

      String filePath = library.uri.toString();
      bool isHostPackage = false;
      final normalizedRoot = normalize(absolute(analysisDartRoot.path));
      try {
        if (library.uri.isScheme('package') || library.uri.isScheme('file')) {
          // Attempt to resolve to relative path if within project.
          // For external packages (e.g. Flutter), we keep the package: URI
          // as the file path, as it provides a stable reference compared to
          // local pub-cache paths.
          final sourcePath = normalize(absolute(library.firstFragment.source.fullName));
          if (isWithin(normalizedRoot, sourcePath)) {
            filePath = relative(sourcePath, from: normalizedRoot);
            isHostPackage = true;
          }
        }
        // dart: URIs and file: URIs outside the project root are not host
        // packages — do not follow their re-exports.
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
        // Only follow re-exports from within the host package.
        // External packages (e.g. patrol, flutter) may themselves re-export
        // large transitive graphs (vector_math, dart:ui, etc.) — we don't
        // want those pulled into the API doc.
        if (!isHostPackage) continue;

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

        final normalizedRoot = normalize(absolute(analysisDartRoot.path));
        if (useRecursiveAnalysis) {
          visitLibraryRecursive(
            libraryResult.element2,
            relative(file, from: normalizedRoot),
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
