// Version 2 of the API

// Removed Product class (should be detected as removed)

class User {
  final String name;
  final int age;
  final String _internalId; // new private property (should be detected as added, private)
  String? email;
  String? phone; // new property (should be detected as added)

  // Changed constructor: added required _internalId, phone is now optional named
  User(this.name, this.age, {this._internalId, this.email, this.phone});

  // Added factory constructor:
  User.fromJson(Map<String, dynamic> json) :
    throw UnimplementedError();

  // Updated method: Add some optional named parameters with default values
  void updateEmail(String email, {
    bool notifyUserViaEmail = false,
    bool logChange = true,
  }) {
    this.email = email;
  }

  // New methods:
  void updatePhone(String phone, String mobilePhone) {
    this.phone = phone;
  }
}

// Keep the Product class for compatibility with previous versions, but mark it as deprecated
@deprecated
class Product {
  @deprecated
  final String id;
  @deprecated
  final double price;

  Product(this.id, this.price);
}

// Added new class
class Order {
  final String orderId;
  final double total;

  Order(this.orderId, this.total);
}

// Add new top-level functions
double calculateDiscount(double price, double percentage) {
  return price * (percentage / 100);
}

String formatUserInfo(String name, int age, {String? email}) {
  return 'Name: $name, Age: $age, Email: ${email ?? "N/A"}';
}

mixin TimestampMixin {
  DateTime? createdAt;
  void setTimestamp() {}
}

enum Status {
  active,
  inactive,
  pending,
}

typedef UserID = String;

extension StringExt on String {
  bool get isValid => true;
  bool get isEmail => contains('@');
}

abstract class BaseClass {}

abstract class InterfaceA {}

abstract class InterfaceB {}

mixin MixinA {}

mixin MixinB {}

class ClassWithSuper extends BaseClass with MixinA, MixinB implements InterfaceA, InterfaceB {}

class GenericClass<T> {
  T value;

  GenericClass(this.value);
}

void genericMethod<K, V>(K key, V value) {
  // Do something generic
}