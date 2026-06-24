import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor2.dart';
import 'package:mtrust_api_guard/models/doc_items.dart';
import 'package:mtrust_api_guard/models/doc_type.dart';

/// A visitor that traverses the AST to collect documentation components.
///
/// This visitor extends [RecursiveElementVisitor2] to visit all elements in the
/// AST recursively. It collects [DocComponent]s for classes, mixins, enums,
/// type aliases, extensions, and top-level functions.
class DocVisitor extends RecursiveElementVisitor2<void> {
  final String filePath;
  final String? entryPoint;
  final List<DocComponent> components = [];

  DocVisitor({required this.filePath, this.entryPoint});

  /// Visits a class element and extracts its documentation.
  @override
  void visitClassElement(ClassElement element) {
    final superTypeInfo = _getSuperTypeInfo(element);

    components.add(
      DocComponent(
        name: element.name!,
        filePath: filePath,
        entryPoint: entryPoint,
        description: _getDescription(element),
        constructors: _mapConstructors(element.constructors),
        properties: _mapProperties(_collectFieldsWithInheritance(element)),
        methods: _mapMethods(_collectMethodsWithInheritance(element)),
        type: DocComponentType.classType,
        annotations: _getAnnotations(element),
        superClasses: superTypeInfo.superClasses,
        superClassPackages: superTypeInfo.superClassPackages,
        interfaces: element.interfaces.map((e) => e.element.name!).toList(),
        mixins: element.mixins.map((e) => e.element.name!).toList(),
        typeParameters: _getTypeParameters(element.typeParameters),
      ),
    );
    super.visitClassElement(element);
  }

  /// Visits a mixin element and extracts its documentation.
  @override
  void visitMixinElement(MixinElement element) {
    components.add(
      DocComponent(
        name: element.name!,
        filePath: filePath,
        description: _getDescription(element),
        constructors: [],
        properties: _mapProperties(_collectFieldsWithInheritance(element)),
        methods: _mapMethods(_collectMethodsWithInheritance(element)),
        type: DocComponentType.mixinType,
        annotations: _getAnnotations(element),
        interfaces: element.interfaces.map((e) => e.element.name!).toList(),
        typeParameters: _getTypeParameters(element.typeParameters),
      ),
    );
    super.visitMixinElement(element);
  }

  /// Visits an enum element and extracts its documentation.
  @override
  void visitEnumElement(EnumElement element) {
    components.add(
      DocComponent(
        name: element.name!,
        filePath: filePath,
        description: _getDescription(element),
        constructors: _mapConstructors(element.constructors),
        properties: _mapProperties(element.fields),
        methods: _mapMethods(element.methods),
        type: DocComponentType.enumType,
        annotations: _getAnnotations(element),
        typeParameters: _getTypeParameters(element.typeParameters),
      ),
    );
    super.visitEnumElement(element);
  }

  /// Visits a type alias element and extracts its documentation.
  @override
  void visitTypeAliasElement(TypeAliasElement element) {
    components.add(
      DocComponent(
        name: element.name!,
        filePath: filePath,
        description: _getDescription(element),
        constructors: [],
        properties: [],
        methods: [],
        type: DocComponentType.typedefType,
        aliasedType: element.aliasedType.toString(),
        annotations: _getAnnotations(element),
        typeParameters: _getTypeParameters(element.typeParameters),
      ),
    );
    super.visitTypeAliasElement(element);
  }

  /// Visits an extension element and extracts its documentation.
  @override
  void visitExtensionElement(ExtensionElement element) {
    components.add(
      DocComponent(
        name: element.name ?? 'extension',
        filePath: filePath,
        description: _getDescription(element),
        constructors: [],
        properties: _mapProperties(element.fields),
        methods: _mapMethods(element.methods),
        type: DocComponentType.extensionType,
        aliasedType: element.extendedType.toString(),
        annotations: _getAnnotations(element),
        typeParameters: _getTypeParameters(element.typeParameters),
      ),
    );
    super.visitExtensionElement(element);
  }

  /// Visits a top-level function element and extracts its documentation.
  @override
  void visitTopLevelFunctionElement(TopLevelFunctionElement element) {
    components.add(
      DocComponent(
        name: element.name!,
        filePath: filePath,
        description: _getDescription(element),
        constructors: [],
        properties: [],
        methods: [
          DocMethod(
            name: element.name!,
            returnType: _getDocType(element.returnType),
            description: _getDescription(element),
            signature: _mapParameters(element.formalParameters),
            features: [if (element.isStatic) "static", if (element.isExternal) "external"],
            annotations: _getAnnotations(element),
            typeParameters: _getTypeParameters(element.typeParameters),
          ),
        ],
        type: DocComponentType.functionType,
        annotations: _getAnnotations(element),
        typeParameters: _getTypeParameters(element.typeParameters),
      ),
    );
    super.visitTopLevelFunctionElement(element);
  }

  // Helpers

  /// Extracts the documentation comment from an element.
  String _getDescription(dynamic element) {
    return element.documentationComment?.replaceAll("///", "") ?? "";
  }

  /// Extracts annotations from an element.
  List<String> _getAnnotations(dynamic element) {
    final meta = element.metadata;
    if (meta is Metadata) {
      return meta.annotations.map((e) => e.toSource()).toList();
    }
    return [];
  }

  /// Collects all methods from the element and its supertypes, excluding [Object].
  Iterable<MethodElement> _collectMethodsWithInheritance(InterfaceElement element) {
    final methodMap = <String, MethodElement>{};
    for (final supertype in element.allSupertypes) {
      if (supertype.isDartCoreObject) continue;
      for (final method in supertype.methods) {
        if (!method.isStatic) {
          methodMap[method.name!] = method;
        }
      }
    }
    for (final method in element.methods) {
      // Filter out abstract methods in non-abstract classes (likely parser artifacts from invalid code)
      if (element is ClassElement && !element.isAbstract && method.isAbstract) {
        continue;
      }
      methodMap[method.name!] = method;
    }
    return methodMap.values;
  }

  /// Collects all fields from the element and its supertypes, excluding [Object].
  Iterable<FieldElement> _collectFieldsWithInheritance(InterfaceElement element) {
    final propertyMap = <String, FieldElement>{};
    for (final supertype in element.allSupertypes) {
      if (supertype.isDartCoreObject) continue;
      for (final field in supertype.element.fields) {
        if (!field.isStatic) {
          propertyMap[field.name!] = field;
        }
      }
    }
    for (final field in element.fields) {
      propertyMap[field.name!] = field;
    }
    return propertyMap.values;
  }

  /// Maps a list of [ConstructorElement] to [DocConstructor]s.
  List<DocConstructor> _mapConstructors(List<ConstructorElement> constructors) {
    return constructors
        .map(
          (e) => DocConstructor(
            name: e.name!,
            signature: _mapParameters(e.formalParameters),
            features: [if (e.isConst) "const", if (e.isFactory) "factory", if (e.isExternal) "external"],
            annotations: _getAnnotations(e),
          ),
        )
        .toList();
  }

  /// Maps a list of [FieldElement] to [DocProperty]s.
  List<DocProperty> _mapProperties(Iterable<FieldElement> fields) {
    return fields
        .map(
          (e) => DocProperty(
            name: e.name!,
            type: _getDocType(e.type),
            description: _getDescription(e),
            features: [
              if (e.isStatic) "static",
              if (e.isCovariant) "covariant",
              if (e.isFinal) "final",
              if (e.isConst) "const",
              if (e.isLate) "late",
            ],
            annotations: _getAnnotations(e),
          ),
        )
        .toList();
  }

  /// Maps a list of [MethodElement] to [DocMethod]s.
  List<DocMethod> _mapMethods(Iterable<MethodElement> methods) {
    return methods
        .map(
          (e) => DocMethod(
            name: e.name!,
            returnType: _getDocType(e.returnType),
            description: _getDescription(e),
            signature: _mapParameters(e.formalParameters),
            features: [if (e.isStatic) "static", if (e.isAbstract) "abstract", if (e.isExternal) "external"],
            annotations: _getAnnotations(e),
            typeParameters: _getTypeParameters(e.typeParameters),
          ),
        )
        .toList();
  }

  /// Maps a list of [FormalParameterElement] to [DocParameter]s.
  List<DocParameter> _mapParameters(List<FormalParameterElement> parameters) {
    return parameters
        .map(
          (param) => DocParameter(
            description: _getDescription(param),
            name: param.name!,
            type: _getDocType(param.type),
            named: param.isNamed,
            required: param.isRequired,
            defaultValue: param.defaultValueCode,
            annotations: _getAnnotations(param),
          ),
        )
        .toList();
  }

  /// Extracts type parameters from an element.
  List<String> _getTypeParameters(List<TypeParameterElement> typeParameters) {
    return typeParameters.map((e) {
      final bound = e.bound;
      if (bound != null) {
        return '${e.name} extends $bound';
      }
      return e.name!;
    }).toList();
  }

  DocType _getDocType(DartType type) {
    final superTypes = <String>[];
    if (type is InterfaceType) {
      for (final superType in type.allSupertypes) {
        superTypes.add(superType.element.name!);
      }
    }
    return DocType(
      name: type.toString(),
      superTypes: superTypes,
      isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
    );
  }

  ({List<String> superClasses, List<String> superClassPackages}) _getSuperTypeInfo(ClassElement element) {
    var superClasses = <String>[];
    var superClassPackages = <String>[];
    var current = element.supertype;

    while (current != null && !current.isDartCoreObject) {
      // 1. Add Class Name
      superClasses.add(current.element.name!);

      // 2. Add Package Name
      final uri = current.element.library.uri;
      if (uri.isScheme('package')) {
        superClassPackages.add(uri.pathSegments.first);
      } else if (uri.isScheme('dart')) {
        superClassPackages.add(uri.toString().split('/').first);
      } else {
        superClassPackages.add('project');
      }

      current = current.superclass;
    }

    return (superClasses: superClasses, superClassPackages: superClassPackages);
  }
}
