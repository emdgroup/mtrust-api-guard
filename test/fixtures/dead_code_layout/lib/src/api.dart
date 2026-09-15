import 'model.dart';
import 'platform.dart';

/// Exported, and read by nothing in the package.
const greeting = 'hello';

class Api {
  String describe() => '${platformName()} ${Model.fromMap({'value': 1}).toMap()}';
}
