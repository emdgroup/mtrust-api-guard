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
}

/// A change description in the API that belongs to a specific component.
class ApiChange {
  final DocComponent component;
  final ApiChangeOperation operation;

  ApiChange._({
    required this.component,
    required this.operation,
  });

  ApiChangeMagnitude getMagnitude() {
    if (component.name.startsWith('_')) {
      // if the component is private, it's a patch change
      return ApiChangeMagnitude.patch;
    }
    if (operation == ApiChangeOperation.added) {
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
  }) : super._();
}

class PropertyApiChange extends ApiChange {
  final DocProperty property;

  PropertyApiChange({
    required super.component,
    required super.operation,
    required this.property,
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

class ConstructorApiChange extends ApiChange {
  final DocConstructor constructor;

  ConstructorApiChange({
    required super.component,
    required super.operation,
    required this.constructor,
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

class ConstructorParameterApiChange extends ApiChange {
  final DocConstructor constructor;
  final DocParameter parameter;

  ConstructorParameterApiChange({
    required super.component,
    required super.operation,
    required this.constructor,
    required this.parameter,
  }) : super._();

  @override
  ApiChangeMagnitude getMagnitude() {
    if (constructor.name.startsWith('_') || parameter.name.startsWith('_')) {
      // if the constructor or parameter is private, it's a patch change
      return ApiChangeMagnitude.patch;
    }
    if (operation == ApiChangeOperation.becameNullSafe ||
        operation == ApiChangeOperation.becameOptional ||
        (operation == ApiChangeOperation.removed && !parameter.required)) {
      return ApiChangeMagnitude.minor;
    }
    return super.getMagnitude();
  }
}
