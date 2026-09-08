import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:mtrust_api_guard/bootstrap.dart';
import 'package:mtrust_api_guard/config/config.dart';
import 'package:mtrust_api_guard/dead_code/dead_code_report.dart';
import 'package:mtrust_api_guard/dead_code/dead_code_rules.dart';
import 'package:mtrust_api_guard/dead_code/dead_code_visitor.dart';
import 'package:mtrust_api_guard/doc_generator/detect_exclusions.dart';
import 'package:mtrust_api_guard/doc_generator/entry_points.dart';
import 'package:mtrust_api_guard/doc_generator/get_sdk_path.dart';
import 'package:mtrust_api_guard/doc_generator/pubspec_analyzer.dart';
import 'package:mtrust_api_guard/logger.dart';
import 'package:path/path.dart';

/// Finds declarations that no code in the package references.
///
/// The scan resolves every library under `lib/` and `test/` once and collects
/// two sets from the resolved ASTs: the declarations each file makes, and the
/// elements each file refers to. Whatever is declared but never referred to is
/// unreferenced.
///
/// Being unreferenced inside the package is not the same as being dead. For a
/// published package the entire exported API is unreferenced from its own
/// perspective. So findings are split against the export closure computed from
/// the configured entry points: anything a consumer can reach is reported as
/// API surface, and only the rest is reported as dead.
class DeadCodeFinder {
  DeadCodeFinder({required this.root, ApiGuardConfig? config}) : config = config ?? ApiGuardConfig.load(root);

  /// Package root to analyze.
  final Directory root;

  final ApiGuardConfig config;

  late final String _normalizedRoot = normalize(absolute(root.path));

  /// Declarations found, keyed by element, with their source position.
  final Map<Element, DeclarationSite> _declarations = {};

  /// Elements referenced from code.
  final Set<Element> _codeReferences = {};

  /// Elements referenced only from dartdoc `[Foo]` links so far.
  final Set<Element> _docReferences = {};

  Future<DeadCodeReport> run() async {
    final reportable = _reportableFiles;
    final analyzable = _analyzableFiles;

    if (analyzable.isEmpty) {
      logger.warn('No Dart files found to analyze.');
      return const DeadCodeReport(dead: [], apiSurface: [], docOnly: [], filesScanned: 0, declarationsChecked: 0);
    }

    // An unresolved package still analyzes, it just cannot follow its own
    // `package:` imports, so every declaration reached only through one looks
    // unreferenced. Saying so is better than reporting a tree of false
    // findings and leaving the reader to work out why.
    if (!File(join(_normalizedRoot, '.dart_tool', 'package_config.json')).existsSync()) {
      logger.warn(
        'No .dart_tool/package_config.json in ${root.path}. Run pub get first, '
        'otherwise anything referenced only through a package: import is '
        'reported as dead.',
      );
    }

    final collection = AnalysisContextCollection(
      includedPaths: [_normalizedRoot],
      excludedPaths: _exclusions.toList(),
      sdkPath: getSdkPath(),
    );

    final progress = logger.progress('Scanning ${analyzable.length} files for dead code');
    var scanned = 0;

    try {
      for (final file in analyzable) {
        final ResolvedUnitResult unit;
        try {
          final context = collection.contextFor(file);
          final result = await context.currentSession.getResolvedUnit(file);
          if (result is! ResolvedUnitResult) {
            logger.detail('Skipping unresolved unit: $file');
            continue;
          }
          unit = result;
        } catch (e) {
          logger.detail('Skipping $file: $e');
          continue;
        }

        scanned++;

        // References are collected from every analyzable file, including
        // generated files and tests. Something used only by a test or only by
        // a `.g.dart` is used.
        final visitor = ReferenceVisitor(
          declarations: _declarations,
          codeReferences: _codeReferences,
          docReferences: _docReferences,
          filePath: _relative(file),
          lineInfo: unit.lineInfo,
          collectDeclarations: reportable.contains(file) && !isGeneratedFile(file),
          packageRoot: _normalizedRoot,
        );
        unit.unit.accept(visitor);
      }

      final exported = await _exportedElements(collection);
      progress.complete();

      return _classify(exported: exported, filesScanned: scanned);
    } finally {
      await collection.dispose();
    }
  }

  /// Directories that hold code belonging to this package. A declaration used
  /// only by a test, an example or the package's own executable is used.
  static const _referenceRoots = ['lib', 'bin', 'test', 'tool', 'example', 'benchmark', 'integration_test'];

  /// The configured `include` set minus `api_guard.exclude`, resolved the same
  /// way the doc generator resolves it.
  late final (ApiGuardConfig, Set<String>) _target = evaluateTargetFiles(_normalizedRoot);

  /// Files whose declarations may be reported. Defaults to `lib/**.dart`.
  late final Set<String> _reportableFiles = _target.$2.difference(_exclusions);

  /// Files that are read for references: everything reportable, plus every
  /// other directory holding this package's code.
  late final Set<String> _analyzableFiles = {
    ..._reportableFiles,
    ..._glob(_referenceRoots.map((directory) => '$directory/**.dart')),
  }.difference(_exclusions);

  /// `analyzer.exclude` on top of the `api_guard.exclude` that
  /// [evaluateTargetFiles] already applied. A repository that excludes a
  /// directory from analysis (test fixtures, vendored code) does not want it
  /// reported here either.
  late final Set<String> _exclusions = detectExclusionsFromAnalyzer(_normalizedRoot);

  Set<String> _glob(Iterable<String> patterns) => {
    for (final pattern in patterns) ...Glob(pattern).listSync(root: _normalizedRoot).map(_normalize),
  };

  /// Every element a consumer of this package can reach, computed from the
  /// export closure of the configured entry points.
  ///
  /// Returns `null` when no entry point can be determined, which means the
  /// closure is unknown and no finding can be suppressed as API surface.
  Future<Set<Element>?> _exportedElements(AnalysisContextCollection collection) async {
    final entryPoints = await _entryPoints();
    if (entryPoints == null) return null;

    final exported = <Element>{};
    for (final entryPoint in entryPoints) {
      try {
        final context = collection.contextFor(entryPoint);
        final result = await context.currentSession.getResolvedLibrary(entryPoint);
        if (result is! ResolvedLibraryResult) continue;
        for (final element in result.element.exportNamespace.definedNames2.values) {
          exported.add(element.baseElement);
        }
      } catch (e) {
        logger.detail('Could not resolve entry point $entryPoint: $e');
      }
    }
    return exported;
  }

  /// The entry points whose export closure defines the public API.
  ///
  /// Resolved by the same code the doc generator enters a package with, so the
  /// closure a finding is checked against is the closure the generated API
  /// documentation describes. If the two ever disagreed, this whole
  /// classification would be checking findings against the wrong thing.
  ///
  /// Returns `null` when the resolution does not follow exports, which is the
  /// case for a package with neither `entry_points` nor a main library. There
  /// is no closure then, and nothing can be proven unreachable.
  Future<List<String>?> _entryPoints() async {
    final metadata = await PubspecAnalyzer(_normalizedRoot).analyze();
    final resolution = resolveEntryPoints(
      root: _normalizedRoot,
      config: config,
      packageName: metadata.packageName,
      globbedFiles: _reportableFiles,
    );

    if (!resolution.followsExports) {
      logger.warn(
        'No entry points configured and no main library found. Findings cannot '
        'be checked against the export closure, so public declarations are '
        'reported as unreferenced rather than as dead.',
      );
      return null;
    }

    return resolution.files.toList();
  }

  DeadCodeReport _classify({required Set<Element>? exported, required int filesScanned}) {
    final dead = <DeadDeclaration>[];
    final apiSurface = <DeadDeclaration>[];
    final docOnly = <DeadDeclaration>[];

    final unreferenced = <Element, DeclarationSite>{};

    for (final entry in _declarations.entries) {
      final element = entry.key;
      if (_codeReferences.contains(element)) continue;
      if (_shouldSkip(element, entry.value)) continue;
      unreferenced[element] = entry.value;
    }

    // A member of a declaration that is itself dead adds nothing: reporting
    // `Foo` and then every member of `Foo` buries the one line that matters.
    final deadContainers = unreferenced.keys.toSet();

    for (final entry in unreferenced.entries) {
      final element = entry.key;
      final site = entry.value;

      final container = element.enclosingElement;
      if (container != null && deadContainers.contains(container.baseElement)) continue;

      final declaration = site.toDeclaration();

      if (_docReferences.contains(element)) {
        docOnly.add(declaration);
      } else if (exported != null && _isApiSurface(element, exported)) {
        apiSurface.add(declaration);
      } else if (exported == null && !site.isPrivate) {
        // Without a known export closure a public declaration cannot be
        // proven unreachable, so it is reported as API surface rather than
        // asserted to be dead.
        apiSurface.add(declaration);
      } else {
        dead.add(declaration);
      }
    }

    int byPosition(DeadDeclaration a, DeadDeclaration b) {
      final byFile = a.filePath.compareTo(b.filePath);
      return byFile != 0 ? byFile : a.line.compareTo(b.line);
    }

    return DeadCodeReport(
      dead: dead..sort(byPosition),
      apiSurface: apiSurface..sort(byPosition),
      docOnly: docOnly..sort(byPosition),
      filesScanned: filesScanned,
      declarationsChecked: _declarations.length,
    );
  }

  /// Whether a consumer can reach [element]: it is exported itself, or it is a
  /// member of something exported.
  bool _isApiSurface(Element element, Set<Element> exported) {
    if (exported.contains(element.baseElement)) return true;
    final container = element.enclosingElement;
    return container != null && exported.contains(container.baseElement);
  }

  bool _shouldSkip(Element element, DeclarationSite site) {
    if (site.hasVmEntryPoint) return true;

    // An extension is applied implicitly: `value.helper()` resolves to the
    // member, and the extension's own name never appears at the call site. So
    // a used extension looks unreferenced unless its members are consulted.
    if (element is ExtensionElement && _hasReferencedMember(element)) return true;
    if (implicitlyInvokedNames.contains(site.name)) return true;

    // The entry point of a program or a test is never unused.
    if (site.kind == DeadCodeKind.functionKind && site.name == 'main') return true;

    // A member that implements or overrides something inherited is reached
    // through the supertype, which a per-element reference set does not see.
    // It counts as live when anything the override chain is reachable through
    // is referenced, or when the chain leaves this package, where a framework
    // may be the caller.
    if (site.overridesInherited) {
      if (site.overriddenOutsidePackage) return true;
      if (site.overriddenElements.any(_codeReferences.contains)) return true;
    }

    return false;
  }

  /// Whether anything inside [element] is referenced.
  bool _hasReferencedMember(InstanceElement element) {
    return [
      ...element.methods,
      ...element.getters,
      ...element.setters,
      ...element.fields,
    ].any((member) => _codeReferences.contains(member.baseElement));
  }

  String _relative(String file) => relative(file, from: _normalizedRoot).replaceAll(r'\', '/');

  static String _normalize(FileSystemEntity entity) => normalize(absolute(entity.path));
}
