// Version 2 of the API

// Removed Product class (should be detected as removed)

class User {
  final String name;
  final int age;
  final String
      _internalId; // new private property (should be detected as added, private)
  String? email;
  String? phone; // new property (should be detected as added)

  // Changed constructor: added required _internalId, phone is now optional named
  User(this.name, this.age, {this._internalId, this.email, this.phone});
}

// Keep the Product class for compatibility with previous versions
class Product {
  final String id;
  final double price;

  Product(this.id, this.price);
}

// Added new class
class Order {
  final String orderId;
  final double total;

  Order(this.orderId, this.total);
}
