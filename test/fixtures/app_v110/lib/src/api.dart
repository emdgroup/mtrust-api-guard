// Version 0.1.0 of the API
// This fixture represents the "Before" state of the API for testing the diff tool.
// It contains various definitions that will be modified, removed, or kept in the "After" state (app_v200).

// Removed Product class (should be detected as removed)

class User {
  final String name;
  final int age;
  final String _internalId; // new private property (should be detected as added, private)
  String? email; // will become final in v200
  String? phone; // new property (should be detected as added)

  // Changed constructor: added required _internalId, phone is now optional named
  // in v200: _internalId becomes positional
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
  // in v200: return type changes to bool, params reordered
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

// in v200: GenericClass will constrain T to extend num, make value final, and constructor const
class GenericClass<T> {
  T value;

  GenericClass(this.value);
}

// in v200: signature changes significantly
void genericMethod<K, V>(K key, V value) {
  // Do something generic
}

// Test scenarios for parameter type changes
void wideningParams(num a) {}

void narrowingParams(num a) {}

// Test scenarios for modifier changes
// This class demonstrates various modifier changes (static, final, const, late) on fields and methods.
class Modifiers {
  // Static
  int willBecomeStatic = 1;
  static int willLoseStatic = 1;

  // Final
  int willBecomeFinal = 1;
  final int willLoseFinal = 1;

  // Const
  static int willBecomeConst = 1;
  static const int willLoseConst = 1;

  // Late
  int willBecomeLate = 1;
  late int willLoseLate = 1;

  // Methods
  void willBecomeStaticMethod() {}
  static void willLoseStaticMethod() {}
  
  // Constructors
  Modifiers();
  const Modifiers.named();
}

abstract class AbstractModifiers {
  void willBecomeAbstract() {}
  abstract void willLoseAbstract();
}

// Test scenarios for magnitude overrides, see analysis_options.yaml in app_v200
mixin MagnitudeOverrideTest {
  String? willBeRemovedAsNonBreaking;
  String? _willNotBeReportedInChangelog;

  void paramWillBeRenamedAsBreaking(String name) {}

  class InnerClass {
    void innerMethod() {}
  }
}

// Removal of this subclass will be considered minor change due to override
class ClassRemovalWillBeMinorBecauseExtendsClassWithSuper extends ClassWithSuper {}

// Mock, so we can test override based on superclass
class Widget {}

class CustomWidget extends Widget {
  CustomWidget({required Object key, required String title});
}