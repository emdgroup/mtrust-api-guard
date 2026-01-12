// Version 1 of the API

class User {
  final String name;
  final int age;
  String? email;

  User(this.name, this.age, {this.email});

  // Parameter renamed from 'newEmail' to 'email'
  void updateEmail(String email) {
    this.email = email;
  }
}

class Product {
  final String id;
  final double price;
  final String _internalId; // new private property (should be detected as added, private)

  Product(this.id, this.price) : _internalId = _generateInternalId();

  static String _generateInternalId() {
    // Generate a unique internal ID
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

// Removed _PrivateClass

mixin TimestampMixin {
  DateTime? createdAt;
  void _updateTimestamp() {}
}

enum Status { active, inactive }

typedef UserID = String;

extension StringExt on String {
  bool get isValid => true;
  bool _isInternal() => false;
}

abstract class BaseClass {}

abstract class InterfaceA {}

mixin MixinA {}

class ClassWithSuper extends BaseClass with MixinA implements InterfaceA {}

void wideningParams(int a) {}
