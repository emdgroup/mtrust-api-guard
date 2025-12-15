import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/visitor2.dart';
import 'package:mtrust_api_guard/models/doc_items.dart';

class DocVisitor extends RecursiveElementVisitor2<void> {
  final String filePath;
  final List<DocComponent> components = [];

  DocVisitor({required this.filePath});

  @override
  void visitClassElement(ClassElement2 element) {
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
      methodMap[method.name3!] = method;
    }

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

    components.add(DocComponent(
      name: element.name3!,
      filePath: filePath,
      isNullSafe: true,
      description: element.documentationComment?.replaceAll("///", "") ?? "",
      constructors: element.constructors2
          .map((e) => DocConstructor(
                name: e.name3!,
                signature: e.formalParameters
                    .map((param) => DocParameter(
                          description: param.documentationComment ?? "",
                          name: param.name3!,
                          type: param.type.toString(),
                          named: param.isNamed,
                          required: param.isRequired,
                          defaultValue: param.defaultValueCode,
                        ))
                    .toList(),
                features: [
                  if (e.isConst) "const",
                  if (e.isFactory) "factory",
                  if (e.isExternal) "external",
                ],
              ))
          .toList(),
      properties: propertyMap.values
          .map((e) => DocProperty(
                name: e.name3!,
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
      methods: methodMap.values
          .map((e) => DocMethod(
                name: e.name3!,
                returnType: e.returnType.toString(),
                description: e.documentationComment ?? "",
                signature: e.formalParameters
                    .map((param) => DocParameter(
                          description: param.documentationComment ?? "",
                          name: param.name3!,
                          type: param.type.toString(),
                          named: param.isNamed,
                          required: param.isRequired,
                          defaultValue: param.defaultValueCode,
                        ))
                    .toList(),
                features: [
                  if (e.isStatic) "static",
                  if (e.isAbstract) "abstract",
                  if (e.isExternal) "external",
                ],
              ))
          .toList(),
      type: DocComponentType.classType,
    ));
    super.visitClassElement(element);
  }

  @override
  void visitTopLevelFunctionElement(TopLevelFunctionElement element) {
    components.add(DocComponent(
      name: element.name3!,
      filePath: filePath,
      isNullSafe: true,
      description: element.documentationComment?.replaceAll("///", "") ?? "",
      constructors: [],
      properties: [],
      methods: [
        DocMethod(
          name: element.name3!,
          returnType: element.returnType.toString(),
          description: element.documentationComment ?? "",
          signature: element.formalParameters
              .map((param) => DocParameter(
                    description: param.documentationComment ?? "",
                    name: param.name3!,
                    type: param.type.toString(),
                    named: param.isNamed,
                    required: param.isRequired,
                    defaultValue: param.defaultValueCode,
                  ))
              .toList(),
          features: [
            if (element.isStatic) "static",
            if (element.isExternal) "external",
          ],
        )
      ],
      type: DocComponentType.functionType,
    ));
    super.visitTopLevelFunctionElement(element);
  }
}
