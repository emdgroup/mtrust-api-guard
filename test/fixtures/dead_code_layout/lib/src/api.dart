import 'model.dart';
import 'platform.dart';

class Api {
  String describe() => '${platformName()} ${Model.fromMap({'value': 1}).toMap()}';
}
