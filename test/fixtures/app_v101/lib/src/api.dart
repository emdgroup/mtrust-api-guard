// Version 1 of the API

class User {
  final String name;
  final int age;
  String? email;

  User(this.name, this.age, {this.email});
}

class Product {
  final String id;
  final double price;
  final String
      _internalId; // new private property (should be detected as added, private)

  Product(this.id, this.price) : _internalId = _generateInternalId();

  static String _generateInternalId() {
    // Generate a unique internal ID
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

// Removed _PrivateClass
