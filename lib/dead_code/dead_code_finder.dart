import 'dart:convert';
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
import 'package:mtrust_api_guard/logger.dart';
import 'package:mtrust_api_guard/pubspec_utils.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

/// Finds declarations that nothing in the package reaches.
///
/// The scan resolves every library under `lib/` and the other directories
/// holding the package's code once, and builds a graph from the resolved ASTs:
/// the declarations each file makes, and what the code of each one refers to.
/// Tests, executables and examples are roots, and so is whatever a consumer
/// can reach. A declaration a walk from the roots never gets to is dead, even
/// when other dead code refers to it.
///
/// Being unreferenced inside the package is not the same as being dead. For a
/// published package the entire exported API is unreferenced from its own
/// perspective. So findings are split against the export closure computed from
/// the configured entry points: anything a consumer can reach is reported as
/// API surface, and only the rest is reported as dead.
class DeadCodeFinder {
  DeadCodeFinder({required this.root});

  /// Package root to analyze.
  final Directory root;

  late final String _normalizedRoot = normalize(absolute(root.path));

  /// Declarations found, keyed by element, with their source position.
  final Map<Element, DeclarationSite> _declarations = {};

  /// What the code of each tracked declaration refers to.
  final Map<Element, Set<Element>> _references = {};

  /// What code outside every tracked declaration refers to: tests,
  /// executables, examples, and anything else that is read but never reported.
  final Set<Element> _rootReferences = {};

  /// Elements dartdoc `[Foo]` links mention.
  final Set<Element> _docReferences = {};

  /// The files behind each conditional import or export, default included.
  final List<Set<String>> _conditionalBranches = [];

  /// Declarations that stand in for each other across the branches of a
  /// conditional import or export, like the `io` and the `web` version of one
  /// function.
  ///
  /// The analyzer resolves such a directive to one branch, so declarations in
  /// the others are never referenced, although another platform compiles them
  /// instead. Each counts as referenced, or as reachable, when its counterpart
  /// is.
  final Map<Element, Set<Element>> _counterparts = {};

  /// The tracked members of each container.
  final Map<Element, List<Element>> _membersOf = {};

  /// The tracked declarations that override each member.
  final Map<Element, List<Element>> _overridesOf = {};

  /// Everything a walk from the roots has got to.
  final Set<Element> _live = {};

  /// Everything live code refers to. A root, or the container of a live
  /// member, is live without being used.
  final Set<Element> _used = {};

  /// Live elements whose own references the walk has yet to follow.
  final List<Element> _pending = [];

  Future<DeadCodeReport> run() async {
    final reportable = _reportableFiles;
    final analyzable = _analyzableFiles;

    if (analyzable.isEmpty) {
      logger.warn('No Dart files found to analyze.');
      return const DeadCodeReport(dead: [], apiSurface: [], docOnly: [], filesScanned: 0, declarationsChecked: 0);
    }

    final unresolved = unresolvedPackageWarning(_normalizedRoot);
    if (unresolved != null) logger.warn(unresolved);

    final collection = AnalysisContextCollection(
      includedPaths: [_normalizedRoot],
      excludedPaths: _exclusions.toList(),
      sdkPath: getSdkPath(),
    );

    final progress = logger.progress('Scanning ${analyzable.length} files for dead code');
    final scanned = <String>{};

    try {
      for (final file in analyzable) {
        if (scanned.contains(file)) continue;

        // Resolved a library at a time, so a part is read along with its
        // library even where `analyzer.exclude` hides it. That is where
        // `json_serializable` and `freezed` put the code that reads the
        // fields they are generated for.
        final ResolvedLibraryResult library;
        try {
          final session = collection.contextFor(file).currentSession;
          final unit = await session.getResolvedUnit(file);
          final result = unit is ResolvedUnitResult
              ? await session.getResolvedLibraryByElement(unit.libraryElement)
              : unit;
          if (result is! ResolvedLibraryResult) {
            logger.detail('Skipping unresolved unit: $file');
            continue;
          }
          library = result;
        } catch (e) {
          logger.detail('Skipping $file: $e');
          continue;
        }

        for (final unit in library.units) {
          final path = normalize(unit.path);
          if (!scanned.add(path)) continue;

          // Generated code is part of the graph like reportable code is, so
          // what only dead generated code uses is dead too. Every other file,
          // tests and executables among them, is a root: whatever it refers
          // to is used.
          final generated = isGeneratedFile(path, unit.content);
          final visitor = ReferenceVisitor(
            declarations: _declarations,
            references: _references,
            rootReferences: _rootReferences,
            docReferences: _docReferences,
            conditionalBranches: _conditionalBranches,
            filePath: _relative(path),
            lineInfo: unit.lineInfo,
            trackDeclarations: generated || reportable.contains(path),
            reportDeclarations: !generated && reportable.contains(path),
            packageRoot: _normalizedRoot,
          );
          unit.unit.accept(visitor);
        }
      }

      _pairConditionalBranches();
      _indexMembers();

      final exported = await _exportedElements(collection);
      progress.complete();

      return _classify(exported: exported, filesScanned: scanned.length);
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
  ///
  /// Symlinks and hidden directories are left out. They hold tooling state
  /// rather than code: `.dart_tool/`, and the plugin links Flutter keeps under
  /// `ios/.symlinks/` that lead into the SDK.
  late final Set<String> _analyzableFiles = {
    ..._reportableFiles,
    for (final directory in _referenceRoots)
      for (final file in Glob('$directory/**.dart').listSync(root: _normalizedRoot, followLinks: false))
        if (!split(relative(file.path, from: _normalizedRoot)).any((segment) => segment.startsWith('.')))
          _normalize(file),
  }.difference(_exclusions);

  /// `analyzer.exclude` on top of the `api_guard.exclude` that
  /// [evaluateTargetFiles] already applied. A repository that excludes a
  /// directory from analysis (test fixtures, vendored code) does not want it
  /// reported here either.
  late final Set<String> _exclusions = detectExclusionsFromAnalyzer(_normalizedRoot);

  /// Every element a consumer of this package can reach, computed from the
  /// export closure of the configured entry points.
  ///
  /// Returns `null` when no entry point can be determined, which means the
  /// closure is unknown and no finding can be suppressed as API surface.
  Future<Set<Element>?> _exportedElements(AnalysisContextCollection collection) async {
    final entryPoints = _entryPoints();
    if (entryPoints == null) return null;

    final exported = <Element>{};
    for (final entryPoint in entryPoints) {
      try {
        final context = collection.contextFor(entryPoint);
        final result = await context.currentSession.getResolvedLibrary(entryPoint);
        if (result is! ResolvedLibraryResult) continue;
        for (final element in result.element.exportNamespace.definedNames2.values) {
          exported.add(element.baseElement);
          // A top-level variable is exported as its getter and setter, and
          // declared as the variable behind them.
          if (element is PropertyAccessorElement) exported.add(element.variable.baseElement);
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
  Set<String>? _entryPoints() {
    // The name is all this needs from the pubspec. `PubspecAnalyzer` would
    // also walk `ios/` for platform constraints, and Xcode leaves binary
    // plists there that it cannot read.
    final packageName = PubspecUtils.getPackageName(File(join(_normalizedRoot, 'pubspec.yaml')).readAsStringSync());
    final resolution = resolveEntryPoints(
      root: _normalizedRoot,
      config: _target.$1,
      packageName: packageName,
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

    return resolution.files;
  }

  /// The declaration [element] stands for.
  ///
  /// The analyzer resolves a nested package, such as an `example/` with a
  /// pubspec of its own, in an analysis context of its own, which builds its
  /// own element for every declaration it imports from this package. Those
  /// never equal the elements declared here, so they are matched by where they
  /// are declared instead.
  Element _adopt(Element element) => _adopted[element] ??= _declarations.containsKey(element)
      ? element
      : _declaredAt[_declarationKey(element)] ?? element;

  final Map<Element, Element> _adopted = {};

  late final Map<String, Element> _declaredAt = {
    for (final element in _declarations.keys) ?_declarationKey(element): element,
  };

  static String? _declarationKey(Element element) {
    final fragment = element.firstFragment;
    final source = fragment.libraryFragment?.source.fullName;
    final offset = fragment.nameOffset;
    if (source == null || offset == null) return null;
    return '$source:$offset';
  }

  /// Fills [_counterparts]: within each conditional directive, declarations
  /// with the same qualified name in different branches stand in for each
  /// other.
  void _pairConditionalBranches() {
    if (_conditionalBranches.isEmpty) return;

    final byFile = <String, List<Element>>{};
    for (final MapEntry(key: element, value: site) in _declarations.entries) {
      (byFile[site.filePath] ??= []).add(element);
    }

    for (final branches in _conditionalBranches) {
      final byName = <String, Set<Element>>{};
      for (final file in branches) {
        for (final element in byFile[_relative(file)] ?? const <Element>[]) {
          (byName[_declarations[element]!.qualifiedName] ??= {}).add(element);
        }
      }
      for (final group in byName.values) {
        for (final element in group) {
          (_counterparts[element] ??= {}).addAll(group.where((other) => other != element));
        }
      }
    }
  }

  /// Fills [_membersOf] and [_overridesOf].
  void _indexMembers() {
    for (final MapEntry(key: element, value: site) in _declarations.entries) {
      final container = element.enclosingElement?.baseElement;
      if (container is InstanceElement) (_membersOf[container] ??= []).add(element);
      for (final overridden in site.overriddenElements) {
        (_overridesOf[_adopt(overridden)] ??= []).add(element);
      }
    }
  }

  DeadCodeReport _classify({required Set<Element>? exported, required int filesScanned}) {
    // Walked from the roots first, and what that reaches is what counts as
    // used.
    _rootReferences.map(_adopt).forEach(_use);
    for (final MapEntry(key: element, value: site) in _declarations.entries) {
      if (_isEntryPoint(element, site) || _isApiSurface(element, exported)) _reach(element);
    }
    _propagate();
    final live = {..._live};
    final used = {..._used};

    // Then on from what only doc comments mention. That is reported as
    // doc-only rather than as dead, so what it uses is not asserted dead either.
    final mentioned = _docReferences.map(_adopt).toSet();
    mentioned.where(_declarations.containsKey).forEach(_reach);
    _propagate();

    final findings = <Element, ({DeclarationSite site, _Finding finding})>{};
    for (final MapEntry(key: element, value: site) in _declarations.entries) {
      if (!site.reportable || _isKept(element, site, live: live, used: used)) continue;
      final finding = mentioned.contains(element)
          ? _Finding.docOnly
          : [element, ...?_counterparts[element]].any((candidate) => _isApiSurface(candidate, exported))
          ? _Finding.apiSurface
          // Reached, but only through something the report lists rather than
          // uses, such as a declaration only a doc comment mentions.
          : _live.contains(element)
          ? null
          : _Finding.dead;
      if (finding != null) findings[element] = (site: site, finding: finding);
    }

    final dead = <DeadDeclaration>[];
    final apiSurface = <DeadDeclaration>[];
    final docOnly = <DeadDeclaration>[];

    for (final MapEntry(key: element, value: (:site, :finding)) in findings.entries) {
      // A member of a declaration that is itself reported adds nothing:
      // reporting `Foo` and then every member of `Foo` buries the one line that
      // matters. The exception is a dead member of API surface, which no
      // consumer reaches although they reach `Foo`.
      final container = findings[element.enclosingElement?.baseElement]?.finding;
      if (container != null && !(container == _Finding.apiSurface && finding == _Finding.dead)) continue;

      final bucket = switch (finding) {
        _Finding.dead => dead,
        _Finding.apiSurface => apiSurface,
        _Finding.docOnly => docOnly,
      };
      bucket.add(site.toDeclaration());
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
      declarationsChecked: _declarations.values.where((site) => site.reportable).length,
    );
  }

  void _reach(Element element) {
    if (_live.add(element)) _pending.add(element);
  }

  void _use(Element element) {
    _used.add(element);
    _reach(element);
  }

  /// Follows what is live until nothing new is reached.
  void _propagate() {
    while (_pending.isNotEmpty) {
      final element = _pending.removeLast();
      _references[element]?.map(_adopt).forEach(_use);
      _counterparts[element]?.forEach(_reach);

      // A member does not run without its container.
      final container = element.enclosingElement?.baseElement;
      if (container is InstanceElement) _reach(container);

      // A container that exists brings the members called on it implicitly,
      // and a live member brings the overrides whose container exists.
      for (final member in _membersOf[element] ?? const <Element>[]) {
        if (_isCalledImplicitly(_declarations[member]!, _live)) _reach(member);
      }
      for (final override in _overridesOf[element] ?? const <Element>[]) {
        if (_live.contains(override.enclosingElement?.baseElement)) _reach(override);
      }
    }
  }

  /// Whether [element] counts as used although no live code refers to it.
  bool _isKept(Element element, DeclarationSite site, {required Set<Element> live, required Set<Element> used}) {
    if (used.contains(element) || _isEntryPoint(element, site)) return true;

    final container = element.enclosingElement?.baseElement;
    if (container is InstanceElement && live.contains(container) && _isCalledImplicitly(site, live)) return true;

    // An extension is applied implicitly: `value.helper()` resolves to the
    // member, and the extension's own name never appears at the call site.
    if (element is ExtensionElement && (_membersOf[element]?.any(used.contains) ?? false)) return true;

    return _counterparts[element]?.any(used.contains) ?? false;
  }

  /// Whether something outside the source calls [element], which nothing in
  /// the package has to refer to then.
  static bool _isEntryPoint(Element element, DeclarationSite site) {
    if (site.hasVmEntryPoint) return true;
    // The entry point of a program or a test is never unused.
    if (site.kind == DeadCodeKind.functionKind && site.name == 'main') return true;
    // A member waits for its container to exist, see [_isCalledImplicitly]. A
    // top-level declaration has none to wait for.
    return element.enclosingElement is! InstanceElement && implicitlyInvokedNames.contains(site.name);
  }

  /// Whether [site]'s declaration, a member, is called without a reference in
  /// source once its container exists: by the language or by `jsonEncode`, or
  /// through a member it overrides. A caller reaches it through that member
  /// when the member is live, and a framework may when it is declared outside
  /// this package.
  bool _isCalledImplicitly(DeclarationSite site, Set<Element> live) =>
      implicitlyInvokedNames.contains(site.name) ||
      site.overriddenOutsidePackage ||
      site.overriddenElements.any((overridden) => live.contains(_adopt(overridden)));

  /// Whether a consumer can reach [element]: it is exported itself, or it is a
  /// public member of something exported. Without a known export closure a
  /// public declaration cannot be proven unreachable, so every one might be.
  bool _isApiSurface(Element element, Set<Element>? exported) {
    final container = element.enclosingElement;
    final isMember = container is InstanceElement;
    if (exported == null) return element.isPublic && (!isMember || container.isPublic);
    if (exported.contains(element.baseElement)) return true;
    return isMember && element.isPublic && exported.contains(container.baseElement);
  }

  String _relative(String file) => relative(file, from: _normalizedRoot).replaceAll(r'\', '/');

  static String _normalize(FileSystemEntity entity) => normalize(absolute(entity.path));
}

enum _Finding { dead, apiSurface, docOnly }

/// Why the package at [packageRoot] cannot be fully resolved, or `null` when
/// it can.
///
/// An unresolved package still analyzes, it just cannot follow `package:`
/// imports, so every declaration reached only through one looks unreferenced,
/// and an override of a member it cannot see looks like a method nobody calls.
/// Saying so is better than reporting a tree of false findings and leaving the
/// reader to work out why.
String? unresolvedPackageWarning(String packageRoot) {
  final config = _packageConfigFor(packageRoot);
  if (config == null) {
    return 'No .dart_tool/package_config.json for $packageRoot. Run pub get first, '
        'otherwise anything referenced only through a package: import is '
        'reported as dead.';
  }

  final missing = _missingPackages(config);
  if (missing.isEmpty) return null;
  final named = missing.length > 5
      ? '${missing.take(5).join(', ')} and ${missing.length - 5} more'
      : missing.join(', ');
  return '${config.path} points at packages that are not on disk ($named). '
      'Run pub get first, otherwise anything that depends on them is reported '
      'as dead.';
}

/// The package config the analyzer resolves [packageRoot] with. A pub
/// workspace member has none of its own and shares the workspace root's.
File? _packageConfigFor(String packageRoot) {
  final inWorkspace = _isWorkspaceMember(packageRoot);
  var directory = Directory(packageRoot);
  while (true) {
    final config = File(join(directory.path, '.dart_tool', 'package_config.json'));
    if (config.existsSync()) return config;
    if (!inWorkspace || directory.parent.path == directory.path) return null;
    directory = directory.parent;
  }
}

bool _isWorkspaceMember(String packageRoot) {
  try {
    final pubspec = loadYaml(File(join(packageRoot, 'pubspec.yaml')).readAsStringSync());
    return pubspec is Map && pubspec['resolution'] == 'workspace';
  } catch (_) {
    return false;
  }
}

/// Packages [config] lists whose directory is gone, which is what a pub cache
/// cleaned out from under a resolved package looks like.
List<String> _missingPackages(File config) {
  try {
    final packages = (jsonDecode(config.readAsStringSync()) as Map)['packages'] as List;
    return [
      for (final package in packages.cast<Map>())
        if (!Directory.fromUri(config.uri.resolve(package['rootUri'] as String)).existsSync())
          package['name'] as String,
    ];
  } catch (_) {
    return const [];
  }
}
