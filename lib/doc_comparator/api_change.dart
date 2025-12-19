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
  added,
  removed,
  renamed,
  reordered,
  typeChanged,
  // Constructor Parameter changes:
  becameOptional,
  becameRequired,
  becameNamed,
  becamePositional,
  becameNullUnsafe,
  becameNullSafe,
  becamePrivate,
  becamePublic,
  annotationAdded,
  annotationRemoved,
  // Dependency changes:
  dependencyAdded,
  dependencyRemoved,
  dependencyChanged,
  // Platform constraint changes:
  platformConstraintChanged,
  superClassChanged,
  interfaceAdded,
  interfaceRemoved,
  mixinAdded,
  mixinRemoved,
  typeParametersChanged,
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
    if (operation == ApiChangeOperation.annotationAdded || operation == ApiChangeOperation.annotationRemoved) {
      // For now, let's treat annotation changes as patch changes.
      // (We can revisit this decision later if needed.)
      return ApiChangeMagnitude.patch;
    }
    if (operation == ApiChangeOperation.dependencyAdded ||
        operation == ApiChangeOperation.dependencyRemoved ||
        operation == ApiChangeOperation.dependencyChanged) {
      return ApiChangeMagnitude.patch;
    }
    if (operation == ApiChangeOperation.platformConstraintChanged) {
      return ApiChangeMagnitude.major;
    }
    if (operation == ApiChangeOperation.added ||
        operation == ApiChangeOperation.interfaceAdded ||
        operation == ApiChangeOperation.mixinAdded) {
      // if a parameter, class or property was added, it's usually a minor
      // change (unless it's private)
      return ApiChangeMagnitude.minor;
    }
    // if we don't know the magnitude, we default to major (better to be safe)
    return ApiChangeMagnitude.major;
  }
}

class ComponentApiChange extends ApiChange {
  ComponentApiChange({
    required super.component,
    required super.operation,
    super.annotation,
    super.changedValue,
  }) : super._();
}

class PropertyApiChange extends ApiChange {
  final DocProperty property;

  PropertyApiChange({
    required super.component,
    required super.operation,
    required this.property,
    super.annotation,
  }) : super._();

  @override
  ApiChangeMagnitude getMagnitude() {
    if (property.name.startsWith('_')) {
      // if the property is private, it's a patch change
      return ApiChangeMagnitude.patch;
    }
    return super.getMagnitude();
  }
}

class MethodApiChange extends ApiChange {
  final DocMethod method;
  final String? newType;

  MethodApiChange({
    required super.component,
    required super.operation,
    required this.method,
    this.newType,
    super.annotation,
    super.changedValue,
  }) : super._();

  @override
  ApiChangeMagnitude getMagnitude() {
    if (method.name.startsWith('_')) {
      // if the method is private, it's a patch change
      return ApiChangeMagnitude.patch;
    }
    return super.getMagnitude();
  }
}

/// Base class for parameter changes to share magnitude logic
abstract class ParameterApiChange extends ApiChange {
  final DocParameter parameter;
  final String? oldName;
  final String parentName;

  ParameterApiChange({
    required super.component,
    required super.operation,
    required this.parameter,
    required this.parentName,
    this.oldName,
    super.annotation,
  }) : super._();

  @override
  ApiChangeMagnitude getMagnitude() {
    if (parentName.startsWith('_')) {
      // if the parent method/constructor is private, it's a patch change
      return ApiChangeMagnitude.patch;
    }

    if (operation == ApiChangeOperation.renamed) {
      return ApiChangeMagnitude.patch;
    }

    if (operation == ApiChangeOperation.reordered) {
      return ApiChangeMagnitude.major;
    }

    if (operation == ApiChangeOperation.becameRequired ||
        operation == ApiChangeOperation.becamePositional ||
        operation == ApiChangeOperation.becameNullUnsafe ||
        (operation == ApiChangeOperation.removed && parameter.required) ||
        (operation == ApiChangeOperation.added && parameter.required)) {
      return ApiChangeMagnitude.major;
    }

    if (operation == ApiChangeOperation.becameNullSafe ||
        operation == ApiChangeOperation.becameOptional ||
        (operation == ApiChangeOperation.removed && !parameter.required) ||
        (operation == ApiChangeOperation.added && !parameter.required)) {
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
  }) : super._();

  @override
  ApiChangeMagnitude getMagnitude() {
    if (constructor.name.startsWith('_')) {
      // if the constructor is private, it's a patch change
      return ApiChangeMagnitude.patch;
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
    super.annotation,
  }) : super(parentName: constructor.name);
}
