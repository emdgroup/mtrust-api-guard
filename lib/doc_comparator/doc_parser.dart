import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:mtrust_api_guard/mtrust_api_guard.dart';

/// Helper extension to extract properties from a `CollectionElement`.
extension CollectionElementExtension on CollectionElement {
  Map<String, dynamic> get properties {
    final map = <String, dynamic>{};
    for (var element in childEntities) {
      if (element is ArgumentList) {
        for (var arg in element.arguments) {
          if (arg is NamedExpression) {
            map[arg.name.label.name] = _extractValue(arg.expression);
          }
        }
      }
    }
    return map;
  }

  /// Helper method to extract a property from a `CollectionElement`.
  T get<T>(String name) {
    final property = properties[name];
    if ((T == List<String>) && property is ListLiteral) {
      return property.elements
          .map((e) => (e as StringLiteral).stringValue ?? '')
          .toList() as T;
    }
    return property as T;
  }

  /// Helper method to extract the value of an expression, if it is of a simple
  /// type.
  dynamic _extractValue(Expression expr) {
    if (expr is SimpleStringLiteral) {
      return expr.value;
    } else if (expr is BooleanLiteral) {
      return expr.value;
    }
    // if needed, we can add more types here
    return expr;
  }
}

/// Parse a `DocComponent` from a `MethodInvocation` AST node.
DocComponent parseDocComponent(MethodInvocation docExpr) {
  // Extract the component data
  final name = docExpr.get<String>('name');
  final isNullSafe = docExpr.get<bool?>('isNullSafe') ?? false;
  final description = docExpr.get<String>('description');
  final methods = docExpr.get<List<String>>('methods');

  // Parse constructors
  final constructors = <DocConstructor>[];
  final constructorsArg = docExpr.get<ListLiteral>('constructors');
  for (final constrExpr in constructorsArg.elements) {
    final signature = <DocParameter>[];
    final params = constrExpr.get<ListLiteral?>('signature');
    for (CollectionElement param in params?.elements ?? []) {
      signature.add(DocParameter(
        name: param.get<String>('name'),
        type: param.get<String>('type'),
        description: param.get<String>('description'),
        named: param.get<bool?>('named') ?? false,
        required: param.get<bool?>('required') ?? false,
      ));
    }
    constructors.add(DocConstructor(
      name: constrExpr.get<String>('name'),
      signature: signature,
      features: [],
    ));
  }

  // Parse properties
  final properties = <DocProperty>[];
  final propertiesArg = docExpr.get<ListLiteral>('properties');
  for (final propExpr in propertiesArg.elements) {
    properties.add(DocProperty(
      name: propExpr.get<String>('name'),
      type: propExpr.get<String>('type'),
      description: propExpr.get<String>('description'),
      features: propExpr.get<List<String>>('features'),
    ));
  }

  return DocComponent(
    name: name,
    isNullSafe: isNullSafe,
    description: description,
    constructors: constructors,
    properties: properties,
    methods: methods,
  );
}

/// Parses the content of a file containing `DocComponent` definitions.
List<DocComponent> parseDocComponentsFile(String fileContent) {
  final unit = parseString(content: fileContent).unit;
  final components = <DocComponent>[];

  // find "const docComponents = [...]" in the file
  unit.declarations.whereType<TopLevelVariableDeclaration>().forEach((decl) {
    final variable = decl.variables.variables.first;
    final variableName = variable.name.toString();
    if (variableName == 'docComponents' ||
        // backwards compatibility with old `liquid_flutter` package name:
        variableName == 'ldDocComponents') {
      final initializer = variable.initializer;
      if (initializer is ListLiteral) {
        for (var element in initializer.elements) {
          if (element is MethodInvocation) {
            final name = element.methodName.name;
            if (name == 'DocComponent' ||
                // backwards compatibility with old `liquid_flutter` package name:
                name == 'LdDocComponent') {
              final component = parseDocComponent(element);
              components.add(component);
            }
          }
        }
      }
    }
  });

  return components;
}
