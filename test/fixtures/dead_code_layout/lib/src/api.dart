import 'model.dart';

class Api {
  String describe() => Model.fromMap({'value': 1}).toMap().toString();
}
