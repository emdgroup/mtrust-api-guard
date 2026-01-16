// Version 1.0.0 of the API
// This fixture represents the "After" state of the API for testing the diff tool.
// It contains changes relative to app_v110 (Version 2).

// Removed Product class (should be detected as removed)

class User {
  final String name;
  final int age;
  final String _internalId;
  final String? email; // changed: Property became final
  String? phone;
  String? mobilePhone; // new property (should be detected as added)

  // Changed constructor: added required _internalId, phone is now optional named
  // Changed: _internalId became positional (was named in v110)
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

  // Method updated: changed order of parameters, added optional named param 'notifyUserViaEmail'
  // and changed return type to bool (was void in v110)
  bool updatePhone(
    String mobilePhone, 
    String phone, {
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

mixin TimestampMixin {
  // Removed createdAt
  void setTimestamp() {}
}

enum Status {
  active,
  // Removed inactive
  pending,
}

typedef UserID = int; // Changed underlying type from String to int

extension StringExt on String {
  // Removed isValid
  bool get isEmail => contains('@');
}

abstract class BaseClass {}

abstract class AnotherBaseClass {}

abstract class InterfaceA {}

mixin MixinA {}

class ClassWithSuper extends AnotherBaseClass {}

// Changed: Added type bound (extends num), value became final, constructor became const
class GenericClass<T extends num> {
  final T value;

  const GenericClass(this.value);
}

// Changed: return type V, new type bound K extends num (implied or changed), params changed
V genericMethod<V extends num>(V input) {
  return input;
}

void wideningParams(num a) {}

void narrowingParams(int a) {}

// Test scenarios for modifier changes
// This class demonstrates the "After" state of modifier changes.
class Modifiers {
  // Static
  static int willBecomeStatic = 1;
  int willLoseStatic = 1;

  // Final
  final int willBecomeFinal = 1;
  int willLoseFinal = 1;

  // Const
  static const int willBecomeConst = 1;
  static int willLoseConst = 1;

  // Late
  late int willBecomeLate = 1;
  int willLoseLate = 1;

  // Methods
  static void willBecomeStaticMethod() {}
  void willLoseStaticMethod() {}
  
  // Constructors
  const Modifiers();
  Modifiers.named();
}

abstract class AbstractModifiers {
  abstract void willBecomeAbstract();
  void willLoseAbstract() {}
}

class MagnitudeOverrideTest {
  // removed fields

  @internal
  String internalField; // new field with @internal annotation

  @experimental
  String experimentalField; // new field with @experimental annotation

  void paramWillBeRenamedAsBreaking(String newName) {}
}