/// The kind of declaration a [DeadDeclaration] refers to.
enum DeadCodeKind {
  classKind('class'),
  mixinKind('mixin'),
  enumKind('enum'),
  extensionKind('extension'),
  extensionTypeKind('extension type'),
  typedefKind('typedef'),
  functionKind('function'),
  methodKind('method'),
  getterKind('getter'),
  setterKind('setter'),
  fieldKind('field'),
  variableKind('variable'),
  constructorKind('constructor'),
  enumValueKind('enum value');

  const DeadCodeKind(this.label);

  /// Human readable label used in reports.
  final String label;
}

/// A declaration that no code in the package references.
class DeadDeclaration {
  const DeadDeclaration({
    required this.name,
    required this.kind,
    required this.filePath,
    required this.line,
    required this.column,
    this.container,
  });

  /// Simple (unqualified) name of the declaration.
  final String name;

  /// Enclosing declaration name (the class for a method), if any.
  final String? container;

  final DeadCodeKind kind;

  /// Path relative to the package root, using `/` separators.
  final String filePath;

  /// One-based line of the declaration's name.
  final int line;

  /// One-based column of the declaration's name.
  final int column;

  /// Whether the declaration is library-private.
  bool get isPrivate => name.startsWith('_');

  /// `Container.name` when the declaration has an enclosing type, `name`
  /// otherwise.
  String get qualifiedName => container == null ? name : '$container.$name';

  Map<String, dynamic> toJson() => {
    'name': name,
    'qualifiedName': qualifiedName,
    'kind': kind.label,
    'file': filePath,
    'line': line,
    'column': column,
    'isPrivate': isPrivate,
    if (container != null) 'container': container,
  };

  @override
  String toString() => '$filePath:$line:$column ${kind.label} $qualifiedName';
}

/// The result of a dead code scan.
class DeadCodeReport {
  const DeadCodeReport({
    required this.dead,
    required this.apiSurface,
    required this.docOnly,
    required this.filesScanned,
    this.declarations = const [],
  });

  /// Declarations nothing live refers to and that no consumer can reach,
  /// because they are not part of the package's export closure.
  final List<DeadDeclaration> dead;

  /// Declarations nothing inside the package references, but that the package
  /// exports. A consumer can call these, so they are reported separately and
  /// never counted as dead.
  final List<DeadDeclaration> apiSurface;

  /// Declarations referenced only from doc comments. A `[Foo]` link resolves
  /// to a real element, but a comment mentioning something is not code using
  /// it.
  final List<DeadDeclaration> docOnly;

  /// Number of files that contributed declarations or references.
  final int filesScanned;

  /// Number of declarations that were checked for references.
  int get declarationsChecked => declarations.length;

  /// Every declaration the scan checked, whichever bucket it landed in.
  ///
  /// A delta reads it to tell a finding whose declaration was deleted from one
  /// that is still there and is not dead any more. Left out of [toJson], where
  /// it would repeat most of the package for no reader.
  final List<DeadDeclaration> declarations;

  bool get isEmpty => dead.isEmpty && docOnly.isEmpty;

  Map<String, dynamic> toJson() => {
    'summary': {
      'filesScanned': filesScanned,
      'declarationsChecked': declarationsChecked,
      'deadCount': dead.length,
      'apiSurfaceCount': apiSurface.length,
      'docOnlyCount': docOnly.length,
    },
    'dead': dead.map((e) => e.toJson()).toList(),
    'apiSurface': apiSurface.map((e) => e.toJson()).toList(),
    'docOnly': docOnly.map((e) => e.toJson()).toList(),
  };
}
