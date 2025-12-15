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

  Product(this.id, this.price);
}

class _PrivateClass {
  final String secret;

  _PrivateClass(this.secret);
}

mixin TimestampMixin {
  DateTime? createdAt;
}

enum Status {
  active,
  inactive,
}

typedef UserID = String;

extension StringExt on String {
  bool get isValid => true;
}
