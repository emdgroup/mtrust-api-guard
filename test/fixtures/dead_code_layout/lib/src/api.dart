import 'model.dart';
import 'platform.dart';

/// Exported, and read by nothing in the package.
const greeting = 'hello';

class Api {
  String describe() => '${platformName()} ${Model.fromMap({'value': 1}).toMap()}';

  /// Private, so no consumer can call it either, and nothing here does.
  void _neverCalled() {}
}

/// Implemented by a class consumers cannot name, which they reach through the
/// factory. Nothing in the package calls `greet`.
abstract class Greeter {
  factory Greeter() = _PoliteGreeter;

  String greet();
}

class _PoliteGreeter implements Greeter {
  @override
  String greet() => 'hello';
}
