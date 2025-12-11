// Version 3 of the API

// Removed Product class (should be detected as removed)

class User {
  final String name;
  final int age;
  final String _internalId; // new private property (should be detected as added, private)
  String? email;
  String? phone; // new property (should be detected as added)
  String? mobilePhone; // new property (should be detected as added)

  // Changed constructor: added required _internalId, phone is now optional named
  User(
    this.name,
    this.age,
    this._internalId, {
    this.email,
    this.phone,
    this.mobilePhone,
  });

  // Changed factory constructor: added optional fallback parameters
  User.fromJson(
    Map<String, dynamic> json, {
    String? fallbackName,
    int fallbackAge = 25
  })  : throw UnimplementedError();

  // Method removed: updateEmail

  // Method updated: renamed 'newPhone' param to 'phone', added 'mobilePhone' param
  // and added optional named param 'notifyUserViaEmail' with default value false.
  // Also changed return type from void to bool
  bool updatePhone(
    String phone,
    String mobilePhone, {
    bool notifyUserViaEmail = false,
  }) {
    this.phone = phone;
    this.mobilePhone = mobilePhone;
    return true;
  }
}

// Added new class
class Order {
  final String orderId;
  final double total;

  Order(this.orderId, this.total);
}

// Change top-level function: added optional named param 'roundUp' with default value false
double calculateDiscount(double price, double percentage, {bool roundUp = false}) {
  double discount = price * (percentage / 100);
  if (roundUp) {
    return discount.ceilToDouble();
  }
  return discount;
}

// Remove 'formatUserInfo' top-level function