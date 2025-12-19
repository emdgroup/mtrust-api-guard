import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/visitor2.dart';
import 'package:mtrust_api_guard/models/doc_items.dart';

/// A visitor that traverses the AST to collect documentation components.
///
/// This visitor extends [RecursiveElementVisitor2] to visit all elements in the
/// AST recursively. It collects [DocComponent]s for classes, mixins, enums,
/// type aliases, extensions, and top-level functions.
class DocVisitor extends RecursiveElementVisitor2<void> {
  final String filePath;
  final List<DocComponent> components = [];

  DocVisitor({required this.filePath});

  /// Visits a class element and extracts its documentation.
  @override
  void visitClassElement(ClassElement2 element) {
    components.add(DocComponent(
      name: element.name3!,
      filePath: filePath,
      isNullSafe: true,
      description: _getDescription(element),
      constructors: _mapConstructors(element.constructors2),
      properties: _mapProperties(_collectFieldsWithInheritance(element)),
      methods: _mapMethods(_collectMethodsWithInheritance(element)),
      type: DocComponentType.classType,
      annotations: _getAnnotations(element),
      superClass: (element.supertype != null && !element.supertype!.isDartCoreObject)
          ? element.supertype!.element3.name3
          : null,
      interfaces: element.interfaces.map((e) => e.element3.name3!).toList(),
      mixins: element.mixins.map((e) => e.element3.name3!).toList(),
      typeParameters: _getTypeParameters(element.typeParameters2),
    ));
    super.visitClassElement(element);
  }

  /// Visits a mixin element and extracts its documentation.
  @override
  void visitMixinElement(MixinElement2 element) {
    components.add(DocComponent(
      name: element.name3!,
      filePath: filePath,
      isNullSafe: true,
      description: _getDescription(element),
      constructors: [],
      properties: _mapProperties(_collectFieldsWithInheritance(element)),
      methods: _mapMethods(_collectMethodsWithInheritance(element)),
      type: DocComponentType.mixinType,
      annotations: _getAnnotations(element),
      interfaces: element.interfaces.map((e) => e.element3.name3!).toList(),
      typeParameters: _getTypeParameters(element.typeParameters2),
    ));
    super.visitMixinElement(element);
  }

  /// Visits an enum element and extracts its documentation.
  @override
  void visitEnumElement(EnumElement2 element) {
    components.add(DocComponent(
      name: element.name3!,
      filePath: filePath,
      isNullSafe: true,
      description: _getDescription(element),
      constructors: _mapConstructors(element.constructors2),
      properties: _mapProperties(element.fields2),
      methods: _mapMethods(element.methods2),
      type: DocComponentType.enumType,
      annotations: _getAnnotations(element),
      typeParameters: _getTypeParameters(element.typeParameters2),
    ));
    super.visitEnumElement(element);
  }

  /// Visits a type alias element and extracts its documentation.
  @override
  void visitTypeAliasElement(TypeAliasElement2 element) {
    components.add(DocComponent(
      name: element.name3!,
      filePath: filePath,
      isNullSafe: true,
      description: _getDescription(element),
      constructors: [],
      properties: [],
      methods: [],
      type: DocComponentType.typedefType,
      aliasedType: element.aliasedType.toString(),
      annotations: _getAnnotations(element),
      typeParameters: _getTypeParameters(element.typeParameters2),
    ));
    super.visitTypeAliasElement(element);
  }

  /// Visits an extension element and extracts its documentation.
  @override
  void visitExtensionElement(ExtensionElement2 element) {
    components.add(DocComponent(
      name: element.name3 ?? 'extension',
      filePath: filePath,
      isNullSafe: true,
      description: _getDescription(element),
      constructors: [],
      properties: _mapProperties(element.fields2),
      methods: _mapMethods(element.methods2),
      type: DocComponentType.extensionType,
      aliasedType: element.extendedType.toString(),
      annotations: _getAnnotations(element),
      typeParameters: _getTypeParameters(element.typeParameters2),
    ));
    super.visitExtensionElement(element);
  }

  /// Visits a top-level function element and extracts its documentation.
  @override
  void visitTopLevelFunctionElement(TopLevelFunctionElement element) {
    components.add(DocComponent(
      name: element.name3!,
      filePath: filePath,
      isNullSafe: true,
      description: _getDescription(element),
      constructors: [],
      properties: [],
      methods: [
        DocMethod(
          name: element.name3!,
          returnType: element.returnType.toString(),
          description: _getDescription(element),
          signature: _mapParameters(element.formalParameters),
          features: [
            if (element.isStatic) "static",
            if (element.isExternal) "external",
          ],
          annotations: _getAnnotations(element),
          typeParameters: _getTypeParameters(element.typeParameters2),
        )
      ],
      type: DocComponentType.functionType,
      annotations: _getAnnotations(element),
      typeParameters: _getTypeParameters(element.typeParameters2),
    ));
    super.visitTopLevelFunctionElement(element);
  }

  // Helpers

  /// Extracts the documentation comment from an element.
  String _getDescription(dynamic element) {
    return element.documentationComment?.replaceAll("///", "") ?? "";
  }

  /// Extracts annotations from an element.
  List<String> _getAnnotations(dynamic element) {
    final meta = element.metadata2;
    if (meta is Metadata) {
      return meta.annotations.map((e) => e.toSource()).toList();
    }
    return [];
  }

  /// Collects all methods from the element and its supertypes, excluding [Object].
  Iterable<MethodElement2> _collectMethodsWithInheritance(InterfaceElement2 element) {
    final methodMap = <String, MethodElement2>{};
    for (final supertype in element.allSupertypes) {
      if (supertype.isDartCoreObject) continue;
      for (final method in supertype.methods2) {
        if (!method.isStatic) {
          methodMap[method.name3!] = method;
        }
      }
    }
    for (final method in element.methods2) {
      // Filter out abstract methods in non-abstract classes (likely parser artifacts from invalid code)
      if (element is ClassElement2 && !element.isAbstract && method.isAbstract) {
        continue;
      }
      methodMap[method.name3!] = method;
    }
    return methodMap.values;
  }

  /// Collects all fields from the element and its supertypes, excluding [Object].
  Iterable<FieldElement2> _collectFieldsWithInheritance(InterfaceElement2 element) {
    final propertyMap = <String, FieldElement2>{};
    for (final supertype in element.allSupertypes) {
      if (supertype.isDartCoreObject) continue;
      for (final field in supertype.element3.fields2) {
        if (!field.isStatic) {
          propertyMap[field.name3!] = field;
        }
      }
    }
    for (final field in element.fields2) {
      propertyMap[field.name3!] = field;
    }
    return propertyMap.values;
  }

  /// Maps a list of [ConstructorElement2] to [DocConstructor]s.
  List<DocConstructor> _mapConstructors(List<ConstructorElement2> constructors) {
    return constructors
        .map((e) => DocConstructor(
              name: e.name3!,
              signature: _mapParameters(e.formalParameters),
              features: [
                if (e.isConst) "const",
                if (e.isFactory) "factory",
                if (e.isExternal) "external",
              ],
              annotations: _getAnnotations(e),
            ))
        .toList();
  }

  /// Maps a list of [FieldElement2] to [DocProperty]s.
  List<DocProperty> _mapProperties(Iterable<FieldElement2> fields) {
    return fields
        .map((e) => DocProperty(
              name: e.name3!,
              type: e.type.toString(),
              description: _getDescription(e),
              features: [
                if (e.isStatic) "static",
                if (e.isCovariant) "covariant",
                if (e.isFinal) "final",
                if (e.isConst) "const",
                if (e.isLate) "late",
              ],
              annotations: _getAnnotations(e),
            ))
        .toList();
  }

  /// Maps a list of [MethodElement2] to [DocMethod]s.
  List<DocMethod> _mapMethods(Iterable<MethodElement2> methods) {
    return methods
        .map((e) => DocMethod(
              name: e.name3!,
              returnType: e.returnType.toString(),
              description: _getDescription(e),
              signature: _mapParameters(e.formalParameters),
              features: [
                if (e.isStatic) "static",
                if (e.isAbstract) "abstract",
                if (e.isExternal) "external",
              ],
              annotations: _getAnnotations(e),
              typeParameters: _getTypeParameters(e.typeParameters2),
            ))
        .toList();
  }

  /// Maps a list of [FormalParameterElement] to [DocParameter]s.
  List<DocParameter> _mapParameters(List<FormalParameterElement> parameters) {
    return parameters
        .map((param) => DocParameter(
              description: _getDescription(param),
              name: param.name3!,
              type: param.type.toString(),
              named: param.isNamed,
              required: param.isRequired,
              defaultValue: param.defaultValueCode,
              annotations: _getAnnotations(param),
            ))
        .toList();
  }

  /// Extracts type parameters from an element.
  List<String> _getTypeParameters(List<TypeParameterElement2> typeParameters) {
    return typeParameters.map((e) {
      final bound = e.bound;
      if (bound != null) {
        return '${e.name3} extends $bound';
      }
      return e.name3!;
    }).toList();
  }
}
