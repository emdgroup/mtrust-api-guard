import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:mtrust_api_guard/api_guard_command_mixin.dart';
import 'package:mtrust_api_guard/doc_generator/doc_generator.dart';

class DocGeneratorCommand extends Command with ApiGuardCommandMixinWithRoot {
  @override
  String get description => "Generate API documentation from Dart files";

  @override
  String get name => "generate";

  @override
  FutureOr? run() {
    final args = argResults!.arguments;
    main(args);
  }
}
