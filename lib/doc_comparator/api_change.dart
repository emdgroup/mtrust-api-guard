import 'package:mtrust_api_guard/mtrust_api_guard.dart';

/// The type of change that was detected in the API.
/// A [patch] change is a change that does not break the API.
/// A [minor] change is a change that adds new features to the API or introduces
/// backwards-compatible changes.
/// A [major] change is a change that breaks the API or removes features.
enum ApiChangeMagnitude {
  patch,
  minor,
  major;

  ApiChangeMagnitude atLeast(ApiChangeMagnitude other) {
    return index >= other.index ? this : other;
  }

  ApiChangeMagnitude atMost(ApiChangeMagnitude other) {
    return index <= other.index ? this : other;
  }
}

ApiChangeMagnitude getHighestMagnitude(List<ApiChange> changes) {
  var highestMagnitude = ApiChangeMagnitude.patch;
  for (final change in changes) {
    if (change.getMagnitude() == ApiChangeMagnitude.major) {
      return ApiChangeMagnitude.major;
    }
    if (change.getMagnitude() == ApiChangeMagnitude.minor) {
      highestMagnitude = ApiChangeMagnitude.minor;
    }
  }

  return highestMagnitude;
}

enum ApiChangeOperation {
  // General changes if something is added or removed
  // This operation can be used for classes, mixins, interfaces, methods, properties, etc.
  addition(ApiChangeMagnitude.minor),
  removal(ApiChangeMagnitude.major),
  // Renaming is usually difficult to detect automatically.
  renaming(ApiChangeMagnitude.major),

  // Type changes
  typeChange(ApiChangeMagnitude.major),

  // Generics changes
  typeParametersChange(ApiChangeMagnitude.major),

  // Privacy changes
  becomingPrivate(ApiChangeMagnitude.major),
  becomingPublic(ApiChangeMagnitude.major),

  // Parameter changes
  becomingOptional(ApiChangeMagnitude.minor),
  becomingRequired(ApiChangeMagnitude.major),
  becomingNullable(ApiChangeMagnitude.minor),
  becomingNonNullable(ApiChangeMagnitude.major),
  becomingNamed(ApiChangeMagnitude.major),
  becomingPositional(ApiChangeMagnitude.major),
  reordering(ApiChangeMagnitude.major),

  // Annotation changes
  annotationAddition(ApiChangeMagnitude.patch),
  annotationRemoval(ApiChangeMagnitude.patch),

  // Inheritance changes
  superClassChange(ApiChangeMagnitude.major),
  interfaceImplementation(ApiChangeMagnitude.minor),
  interfaceRemoval(ApiChangeMagnitude.major),
  mixinApplication(ApiChangeMagnitude.minor),
  mixinRemoval(ApiChangeMagnitude.major),

  // Pubspec-specific changes
  dependencyVersionChange(ApiChangeMagnitude.patch),
  dependencyAddition(ApiChangeMagnitude.patch),
  dependencyRemoval(ApiChangeMagnitude.minor),
  platformConstraintChange(ApiChangeMagnitude.major),

  // Feature changes
  featureAddition(ApiChangeMagnitude.minor),
  featureRemoval(ApiChangeMagnitude.minor);

  const ApiChangeOperation(this.defaultMagnitude);

  /// The default magnitude associated with this operation.
  final ApiChangeMagnitude defaultMagnitude;
}

/// A change description in the API that belongs to a specific component.
class ApiChange {
  final DocComponent component;
  final ApiChangeOperation operation;
  final String? annotation;
  final String? changedValue;

  ApiChange._({
    required this.component,
    required this.operation,
    this.annotation,
    this.changedValue,
  });

  ApiChangeMagnitude getMagnitude() {
    if (component.name.startsWith('_')) {
      // if the component is private, it's a patch change
      return ApiChangeMagnitude.patch;
    }

    // Use the operation's default magnitude by default. Subclasses may
    // override this to refine the magnitude depending on context.
    return operation.defaultMagnitude;
  }
}

class MetaApiChange extends ApiChange {
  MetaApiChange({
    required super.operation,
    required String title,
    required String description,
    String filePath = 'pubspec.yaml',
  })  : assert(_allowedOperations.contains(operation), 'Operation $operation not allowed for pubspec changes'),
        super._(
          component: DocComponent.meta(
            name: title,
            description: description,
            filePath: filePath,
          ),
          changedValue: description,
        );

  static const Set<ApiChangeOperation> _allowedOperations = {
    ApiChangeOperation.dependencyVersionChange,
    ApiChangeOperation.dependencyAddition,
    ApiChangeOperation.dependencyRemoval,
    ApiChangeOperation.platformConstraintChange,
  };

  factory MetaApiChange.dependencyVersionChange({
    required String dependencyName,
    required String? version,
    required String? previousVersion,
  }) {
    return MetaApiChange(
      operation: ApiChangeOperation.dependencyVersionChange,
      title: "dependency `$dependencyName`",
      description: 'from `$previousVersion` to `$version`',
    );
  }

  factory MetaApiChange.dependencyAdded({
    required String dependencyName,
    required String? version,
  }) {
    return MetaApiChange(
      operation: ApiChangeOperation.dependencyAddition,
      title: "dependency `$dependencyName`",
      description: 'with version `$version`',
    );
  }

  factory MetaApiChange.dependencyRemoved({
    required String dependencyName,
  }) {
    return MetaApiChange(
      operation: ApiChangeOperation.dependencyRemoval,
      title: "dependency `$dependencyName`",
      description: 'removed',
    );
  }
}

/// A change that belongs to a specific component.
/// A component can be a class, mixin, interface or typedef.
class ComponentApiChange extends ApiChange {
  ComponentApiChange({
    required super.component,
    required super.operation,
    super.annotation,
    super.changedValue,
  })  : assert(_allowedOperations.contains(operation), 'Operation $operation not allowed for component changes'),
        super._();

  static const Set<ApiChangeOperation> _allowedOperations = {
    ApiChangeOperation.addition,
    ApiChangeOperation.removal,
    ApiChangeOperation.renaming,
    ApiChangeOperation.typeChange,
    ApiChangeOperation.typeParametersChange,
    ApiChangeOperation.becomingPrivate,
    ApiChangeOperation.becomingPublic,
    ApiChangeOperation.annotationAddition,
    ApiChangeOperation.annotationRemoval,
    ApiChangeOperation.interfaceImplementation,
    ApiChangeOperation.interfaceRemoval,
    ApiChangeOperation.mixinApplication,
    ApiChangeOperation.mixinRemoval,
    ApiChangeOperation.superClassChange,
  };
}

/// A change that belongs to a specific property of a component.
class PropertyApiChange extends ApiChange {
  final DocProperty property;

  PropertyApiChange({
    required super.component,
    required super.operation,
    required this.property,
    super.annotation,
    super.changedValue,
  })  : assert(_allowedOperations.contains(operation), 'Operation $operation not allowed for property changes'),
        super._();

  static const Set<ApiChangeOperation> _allowedOperations = {
    ApiChangeOperation.addition,
    ApiChangeOperation.removal,
    ApiChangeOperation.renaming,
    ApiChangeOperation.typeChange,
    ApiChangeOperation.featureAddition,
    ApiChangeOperation.featureRemoval,
    ApiChangeOperation.becomingPrivate,
    ApiChangeOperation.becomingPublic,
    ApiChangeOperation.annotationAddition,
    ApiChangeOperation.annotationRemoval,
  };

  @override
  ApiChangeMagnitude getMagnitude() {
    // Check privacy first - private members are always patch changes
    if (property.name.startsWith('_')) {
      return ApiChangeMagnitude.patch;
    }

    if (operation == ApiChangeOperation.featureAddition) {
      if (changedValue == 'final' || changedValue == 'static') {
        return ApiChangeMagnitude.major;
      }
      return ApiChangeMagnitude.minor;
    }

    if (operation == ApiChangeOperation.featureRemoval) {
      if (changedValue == 'static' || changedValue == 'const' || changedValue == 'covariant') {
        return ApiChangeMagnitude.major;
      }
      return ApiChangeMagnitude.minor;
    }

    return super.getMagnitude();
  }
}

/// A change that belongs to a specific method of a component or a top-level function.
class MethodApiChange extends ApiChange {
  final DocMethod method;
  final DocType? newType;

  MethodApiChange({
    required super.component,
    required super.operation,
    required this.method,
    this.newType,
    super.annotation,
    super.changedValue,
  })  : assert(_allowedOperations.contains(operation), 'Operation $operation not allowed for method changes'),
        super._();

  static const Set<ApiChangeOperation> _allowedOperations = {
    ApiChangeOperation.addition,
    ApiChangeOperation.removal,
    ApiChangeOperation.renaming,
    ApiChangeOperation.typeChange,
    ApiChangeOperation.typeParametersChange,
    ApiChangeOperation.featureAddition,
    ApiChangeOperation.featureRemoval,
    ApiChangeOperation.becomingPrivate,
    ApiChangeOperation.becomingPublic,
    ApiChangeOperation.annotationAddition,
    ApiChangeOperation.annotationRemoval,
  };

  @override
  ApiChangeMagnitude getMagnitude() {
    // Check privacy first - private methods are always patch changes
    if (method.name.startsWith('_')) {
      return ApiChangeMagnitude.patch;
    }

    if (operation == ApiChangeOperation.featureAddition) {
      if (changedValue == 'static' || changedValue == 'abstract') {
        return ApiChangeMagnitude.major;
      }
      return ApiChangeMagnitude.minor;
    }

    if (operation == ApiChangeOperation.featureRemoval) {
      if (changedValue == 'static') {
        return ApiChangeMagnitude.major;
      }
      return ApiChangeMagnitude.minor;
    }

    return super.getMagnitude();
  }
}

/// Base class for parameter changes to share magnitude logic
abstract class ParameterApiChange extends ApiChange {
  final DocParameter parameter;
  final String? oldName;
  final DocType? newType;
  final String parentName;

  ParameterApiChange({
    required super.component,
    required super.operation,
    required this.parameter,
    required this.parentName,
    this.oldName,
    this.newType,
    super.annotation,
  })  : assert(
            _allowedParameterOperations.contains(operation), 'Operation $operation not allowed for parameter changes'),
        super._();

  static const Set<ApiChangeOperation> _allowedParameterOperations = {
    ApiChangeOperation.addition,
    ApiChangeOperation.removal,
    ApiChangeOperation.renaming,
    ApiChangeOperation.reordering,
    ApiChangeOperation.typeChange,
    ApiChangeOperation.becomingOptional,
    ApiChangeOperation.becomingRequired,
    ApiChangeOperation.becomingNullable,
    ApiChangeOperation.becomingNonNullable,
    ApiChangeOperation.becomingNamed,
    ApiChangeOperation.becomingPositional,
    ApiChangeOperation.annotationAddition,
    ApiChangeOperation.annotationRemoval,
  };

  @override
  ApiChangeMagnitude getMagnitude() {
    if (parentName.startsWith('_')) {
      // if the parent method/constructor is private, it's a patch change
      return ApiChangeMagnitude.patch;
    }
    if (operation == ApiChangeOperation.renaming) {
      return ApiChangeMagnitude.patch;
    }

    if (operation == ApiChangeOperation.reordering) {
      return ApiChangeMagnitude.major;
    }

    if (operation == ApiChangeOperation.typeChange) {
      if (newType != null && parameter.type.isAssignableTo(newType!)) {
        return ApiChangeMagnitude.minor;
      }
      return ApiChangeMagnitude.major;
    }

    if (operation == ApiChangeOperation.becomingRequired ||
        operation == ApiChangeOperation.becomingPositional ||
        operation == ApiChangeOperation.becomingNonNullable ||
        (operation == ApiChangeOperation.removal && parameter.required) ||
        (operation == ApiChangeOperation.addition && parameter.required)) {
      return ApiChangeMagnitude.major;
    }

    if (operation == ApiChangeOperation.becomingNullable ||
        operation == ApiChangeOperation.becomingOptional ||
        (operation == ApiChangeOperation.removal && !parameter.required) ||
        (operation == ApiChangeOperation.addition && !parameter.required)) {
      return ApiChangeMagnitude.minor;
    }
    return super.getMagnitude();
  }
}

class MethodParameterApiChange extends ParameterApiChange {
  final DocMethod method;

  MethodParameterApiChange({
    required super.component,
    required super.operation,
    required this.method,
    required super.parameter,
    super.oldName,
    super.newType,
    super.annotation,
  }) : super(parentName: method.name);
}

class ConstructorApiChange extends ApiChange {
  final DocConstructor constructor;

  ConstructorApiChange({
    required super.component,
    required super.operation,
    required this.constructor,
    super.annotation,
    super.changedValue,
  })  : assert(
            !_disallowedConstructorOperations.contains(operation), 'Operation $operation not allowed for constructors'),
        super._();

  static const Set<ApiChangeOperation> _disallowedConstructorOperations = {
    ApiChangeOperation.mixinApplication,
    ApiChangeOperation.mixinRemoval,
    ApiChangeOperation.superClassChange,
    ApiChangeOperation.interfaceImplementation,
    ApiChangeOperation.interfaceRemoval,
    ApiChangeOperation.dependencyAddition,
    ApiChangeOperation.dependencyRemoval,
    ApiChangeOperation.dependencyVersionChange,
    ApiChangeOperation.platformConstraintChange,
  };

  @override
  ApiChangeMagnitude getMagnitude() {
    // Check privacy first - private constructors are always patch changes
    if (constructor.name.startsWith('_')) {
      return ApiChangeMagnitude.patch;
    }

    if (operation == ApiChangeOperation.featureRemoval) {
      if (changedValue == 'const') {
        return ApiChangeMagnitude.major;
      }
      return ApiChangeMagnitude.minor;
    }

    if (operation == ApiChangeOperation.featureAddition) {
      return ApiChangeMagnitude.minor;
    }

    return super.getMagnitude();
  }
}

class ConstructorParameterApiChange extends ParameterApiChange {
  final DocConstructor constructor;

  ConstructorParameterApiChange({
    required super.component,
    required super.operation,
    required this.constructor,
    required super.parameter,
    super.oldName,
    super.newType,
    super.annotation,
  }) : super(parentName: constructor.name);
}
