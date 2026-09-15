import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:mtrust_api_guard/dead_code/dead_code_report.dart';
import 'package:path/path.dart';

/// A declaration and everything about its source position needed to report it.
class DeclarationSite {
  DeclarationSite({
    required this.name,
    required this.kind,
    required this.filePath,
    required this.line,
    required this.column,
    required this.container,
    required this.hasVmEntryPoint,
    required this.overriddenOutsidePackage,
    required this.overriddenElements,
  });

  final String name;
  final DeadCodeKind kind;
  final String filePath;
  final int line;
  final int column;
  final String? container;
  final bool hasVmEntryPoint;
  final bool overriddenOutsidePackage;
  final List<Element> overriddenElements;

  String get qualifiedName => container == null ? name : '$container.$name';

  DeadDeclaration toDeclaration() =>
      DeadDeclaration(name: name, kind: kind, filePath: filePath, line: line, column: column, container: container);
}

/// Walks one resolved compilation unit, recording the declarations it makes
/// and the elements it refers to.
///
/// Declaration names are tokens rather than identifiers in the analyzer AST,
/// so a declaration never counts as a reference to itself. References made
/// from inside the declaration they point at are dropped explicitly, which is
/// what keeps a recursive private function from looking alive.
class ReferenceVisitor extends RecursiveAstVisitor<void> {
  ReferenceVisitor({
    required this.declarations,
    required this.codeReferences,
    required this.docReferences,
    required this.conditionalBranches,
    required this.filePath,
    required this.lineInfo,
    required this.collectDeclarations,
    required this.packageRoot,
  });

  final Map<Element, DeclarationSite> declarations;
  final Set<Element> codeReferences;
  final Set<Element> docReferences;

  /// The files behind each conditional import or export, default included.
  final List<Set<String>> conditionalBranches;

  final String filePath;
  final LineInfo lineInfo;
  final bool collectDeclarations;
  final String packageRoot;

  /// Declarations enclosing the node being visited, innermost last.
  final List<Element> _enclosing = [];

  /// Whether the walk is currently inside a doc comment.
  bool _inDocComment = false;

  @override
  void visitComment(Comment node) {
    final wasInDocComment = _inDocComment;
    _inDocComment = true;
    super.visitComment(node);
    _inDocComment = wasInDocComment;
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _record(node.element);
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitNamedType(NamedType node) {
    _record(node.element);
    super.visitNamedType(node);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    _record(node.element);
    super.visitConstructorName(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _record(node.element);
    super.visitBinaryExpression(node);
  }

  // `++x`, `x++` and `x += 1` read `x` as well as write it, but the operand
  // resolves to the setter only. The getter is the `readElement`.
  @override
  void visitPrefixExpression(PrefixExpression node) {
    _record(node.element);
    _record(node.readElement);
    super.visitPrefixExpression(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _record(node.element);
    _record(node.readElement);
    super.visitPostfixExpression(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _record(node.element);
    super.visitIndexExpression(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _record(node.element);
    _record(node.readElement);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _record(node.element);
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    _record(node.element);
    super.visitRedirectingConstructorInvocation(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _record(node.element);
    super.visitSuperConstructorInvocation(node);
  }

  /// `case Point(:final x)` reads `x` through a name that is a token, not an
  /// identifier.
  @override
  void visitPatternField(PatternField node) {
    _record(node.element);
    super.visitPatternField(node);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _recordBranches(node, node.libraryExport?.exportedLibrary);
    super.visitExportDirective(node);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _recordBranches(node, node.libraryImport?.importedLibrary);
    super.visitImportDirective(node);
  }

  /// Records the files a conditional directive picks between. The analyzer
  /// follows only the branch it [selected], so the default is located
  /// relative to this file.
  void _recordBranches(NamespaceDirective node, LibraryElement? selected) {
    if (node.configurations.isEmpty) return;
    final defaultUri = node.uri.stringValue;
    final branches = {
      ?selected?.firstFragment.source.fullName,
      if (defaultUri != null && Uri.tryParse(defaultUri)?.hasScheme == false)
        normalize(join(packageRoot, dirname(filePath), defaultUri)),
      for (final configuration in node.configurations)
        if (configuration.resolvedUri case DirectiveUriWithSource(:final source)) source.fullName,
    };
    if (branches.length > 1) conditionalBranches.add(branches);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _declare(node.declaredFragment?.element, node.namePart.typeName, DeadCodeKind.classKind, node.metadata, () {
      super.visitClassDeclaration(node);
    });
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _declare(node.declaredFragment?.element, node.name, DeadCodeKind.mixinKind, node.metadata, () {
      super.visitMixinDeclaration(node);
    });
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _declare(node.declaredFragment?.element, node.namePart.typeName, DeadCodeKind.enumKind, node.metadata, () {
      super.visitEnumDeclaration(node);
    });
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    final name = node.name;
    if (name == null) {
      // An unnamed extension cannot be referenced by name, so it is never
      // reportable, but its members still are.
      super.visitExtensionDeclaration(node);
      return;
    }
    _declare(node.declaredFragment?.element, name, DeadCodeKind.extensionKind, node.metadata, () {
      super.visitExtensionDeclaration(node);
    });
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    _declare(
      node.declaredFragment?.element,
      node.namePart.typeName,
      DeadCodeKind.extensionTypeKind,
      node.metadata,
      () => super.visitExtensionTypeDeclaration(node),
    );
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    _declare(node.declaredFragment?.element, node.name, DeadCodeKind.typedefKind, node.metadata, () {
      super.visitGenericTypeAlias(node);
    });
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _declare(node.declaredFragment?.element, node.name, DeadCodeKind.typedefKind, node.metadata, () {
      super.visitFunctionTypeAlias(node);
    });
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // Local functions are scoped to their body; an unused one is the
    // analyzer's `unused_element` lint, not an API concern.
    if (node.parent is! CompilationUnit) {
      super.visitFunctionDeclaration(node);
      return;
    }
    final kind = node.isGetter
        ? DeadCodeKind.getterKind
        : node.isSetter
        ? DeadCodeKind.setterKind
        : DeadCodeKind.functionKind;
    _declare(node.declaredFragment?.element, node.name, kind, node.metadata, () {
      super.visitFunctionDeclaration(node);
    });
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final kind = node.isGetter
        ? DeadCodeKind.getterKind
        : node.isSetter
        ? DeadCodeKind.setterKind
        : DeadCodeKind.methodKind;
    _declare(node.declaredFragment?.element, node.name, kind, node.metadata, () {
      super.visitMethodDeclaration(node);
    });
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    final name = node.name;
    if (name == null) {
      // An unnamed constructor is reached through its class, which is already
      // reported when nothing constructs it.
      super.visitConstructorDeclaration(node);
      return;
    }
    _declare(node.declaredFragment?.element, name, DeadCodeKind.constructorKind, node.metadata, () {
      super.visitConstructorDeclaration(node);
    });
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    _declare(
      node.declaredFragment?.element,
      node.name,
      DeadCodeKind.enumValueKind,
      node.metadata,
      () => super.visitEnumConstantDeclaration(node),
    );
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final list = node.parent;
    final owner = list?.parent;
    final kind = switch (owner) {
      FieldDeclaration() => DeadCodeKind.fieldKind,
      TopLevelVariableDeclaration() => DeadCodeKind.variableKind,
      _ => null,
    };
    if (kind == null) {
      // A local variable, handled by the analyzer's own lints.
      super.visitVariableDeclaration(node);
      return;
    }
    final metadata = owner is AnnotatedNode ? owner.metadata : const <Annotation>[];
    _declare(node.declaredFragment?.element, node.name, kind, metadata, () {
      super.visitVariableDeclaration(node);
    });
  }

  /// Records a declaration and visits its children with it pushed onto the
  /// enclosing stack.
  void _declare(
    Element? element,
    Token nameToken,
    DeadCodeKind kind,
    List<Annotation> metadata,
    void Function() visitChildren,
  ) {
    final canonical = element?.baseElement;

    if (canonical != null && collectDeclarations && !declarations.containsKey(canonical)) {
      final location = lineInfo.getLocation(nameToken.offset);
      final container = canonical.enclosingElement;
      final overridden = _overriddenMembers(canonical, nameToken.lexeme);
      declarations[canonical] = DeclarationSite(
        name: nameToken.lexeme,
        kind: kind,
        filePath: filePath,
        line: location.lineNumber,
        column: location.columnNumber,
        container: container is InstanceElement ? container.name : null,
        hasVmEntryPoint: _hasVmEntryPoint(metadata),
        overriddenOutsidePackage: overridden.any(_isOutsidePackage),
        overriddenElements: overridden,
      );
    }

    if (canonical != null) _enclosing.add(canonical);
    visitChildren();
    if (canonical != null) _enclosing.removeLast();
  }

  /// Records a reference to [element].
  ///
  /// A field is declared as a [FieldElement] but read through the getter the
  /// analyzer synthesises for it, while an explicitly written getter is its
  /// own declaration with a synthetic variable behind it. Which of the two is
  /// synthetic is not something the element model exposes, so both ends of the
  /// pair are recorded and whichever one was declared matches.
  void _record(Element? element) {
    if (element == null) return;
    _recordOne(element.baseElement);
    if (element is PropertyAccessorElement) {
      _recordOne(element.variable.baseElement);
    }
    // `values` lists every constant, and an enum is often only ever read
    // through it or through `byName`.
    if (element.enclosingElement case EnumElement(:final constants) when element.name == 'values') {
      for (final constant in constants) {
        _recordOne(constant.baseElement);
      }
    }
  }

  void _recordOne(Element element) {
    // A reference from inside the thing it points at is not use by anyone
    // else. Without this a recursive function keeps itself alive.
    if (_enclosing.contains(element)) return;

    if (_inDocComment) {
      docReferences.add(element);
    } else {
      codeReferences.add(element);
      // A doc-only finding is one with no code reference at all, so a later
      // code reference wins.
      docReferences.remove(element);
    }
  }

  bool _hasVmEntryPoint(List<Annotation> metadata) => metadata.any((annotation) {
    if (annotation.name.name != 'pragma') return false;
    final arguments = annotation.arguments?.arguments;
    if (arguments == null || arguments.isEmpty) return false;
    final first = arguments.first;
    return first is SimpleStringLiteral && first.value.startsWith('vm:entry-point');
  });

  /// Members of supertypes that [element] overrides or implements.
  List<Element> _overriddenMembers(Element element, String name) {
    final enclosing = element.enclosingElement;
    if (enclosing is! InterfaceElement) return const [];

    final overridden = <Element>[];
    for (final supertype in enclosing.allSupertypes) {
      final target = supertype.element;
      final member =
          target.getMethod(name) ??
          target.getField(name) ??
          target.getGetter(name) as Element? ??
          target.getSetter(name);
      if (member != null) overridden.add(member.baseElement);
    }
    return overridden;
  }

  /// Whether [element] is declared outside the package being scanned, in which
  /// case a framework or another package may be calling it.
  bool _isOutsidePackage(Element element) {
    try {
      final source = element.library?.firstFragment.source.fullName;
      if (source == null) return true;
      return !isWithin(packageRoot, normalize(source));
    } catch (_) {
      return true;
    }
  }
}
