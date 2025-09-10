/// The types used in the generated library. Same as in `doc_items.dart`.
/// It might be cleaner to load this from an asset file, but for now we
/// keep it here to avoid adding more dependencies.
const libraryTypes = """
class DocComponent {
  const DocComponent({
    required this.name,
    required this.isNullSafe,
    required this.description,
    required this.constructors,
    required this.properties,
    required this.methods,
  });

  final String name;
  final bool isNullSafe;
  final String description;
  final List<DocConstructor> constructors;
  final List<DocProperty> properties;
  final List<String> methods;

  // Convert a DocComponent instance to a Map<String, dynamic>
  Map<String, dynamic> toJson() => {
        'name': name,
        'isNullSafe': isNullSafe,
        'description': description,
        'constructors': constructors.map((constructor) => constructor.toJson()).toList(),
        'properties': properties.map((property) => property.toJson()).toList(),
        'methods': methods,
      };

  // Create a DocComponent instance from a Map<String, dynamic>
  factory DocComponent.fromJson(Map<String, dynamic> json) {
    return DocComponent(
      name: json['name'] as String,
      isNullSafe: json['isNullSafe'] as bool,
      description: json['description'] as String,
      constructors: (json['constructors'] as List)
          .map((item) => DocConstructor.fromJson(item as Map<String, dynamic>))
          .toList(),
      properties: (json['properties'] as List)
          .map((item) => DocProperty.fromJson(item as Map<String, dynamic>))
          .toList(),
      methods: (json['methods'] as List).map((item) => item as String).toList(),
    );
  }
}

class DocProperty {
  const DocProperty({
    required this.name,
    required this.type,
    required this.description,
    required this.features,
  });

  final String name;
  final String type;
  final String description;
  final List<String> features;

  // Convert a DocProperty instance to a Map<String, dynamic>
  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'description': description,
        'features': features,
      };

  // Create a DocProperty instance from a Map<String, dynamic>
  factory DocProperty.fromJson(Map<String, dynamic> json) {
    return DocProperty(
      name: json['name'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      features: (json['features'] as List).map((item) => item as String).toList(),
    );
  }
}

class DocConstructor {
  const DocConstructor({
    required this.name,
    required this.signature,
    required this.features,
  });

  final String name;
  final List<DocParameter> signature;
  final List<String> features;

  // Convert a DocConstructor instance to a Map<String, dynamic>
  Map<String, dynamic> toJson() => {
        'name': name,
        'signature': signature.map((parameter) => parameter.toJson()).toList(),
        'features': features,
      };

  // Create a DocConstructor instance from a Map<String, dynamic>
  factory DocConstructor.fromJson(Map<String, dynamic> json) {
    return DocConstructor(
      name: json['name'] as String,
      signature: (json['signature'] as List)
          .map((item) => DocParameter.fromJson(item as Map<String, dynamic>))
          .toList(),
      features: (json['features'] as List).map((item) => item as String).toList(),
    );
  }
}

class DocParameter {
  const DocParameter({
    required this.name,
    required this.type,
    required this.description,
    required this.named,
    required this.required,
  });

  final String name;
  final String description;
  final String type;
  final bool named;
  final bool required;

  // Convert a DocParameter instance to a Map<String, dynamic>
  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'description': description,
        'named': named,
        'required': required,
      };

  // Create a DocParameter instance from a Map<String, dynamic>
  factory DocParameter.fromJson(Map<String, dynamic> json) {
    return DocParameter(
      name: json['name'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      named: json['named'] as bool,
      required: json['required'] as bool,
    );
  }
}
""";
