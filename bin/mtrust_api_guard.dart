import 'package:args/command_runner.dart';
import 'package:mtrust_api_guard/doc_comparator/doc_comparator.dart';
import 'package:mtrust_api_guard/doc_generator/doc_generator.dart';

main(List<String> args) async {
  final commandRunner = CommandRunner(
    'mtrust_api_guard',
    'A documentation generator and comparator for Dart APIs',
  )
    ..addCommand(DocGeneratorCommand())
    ..addCommand(DocComparatorCommand());

  if (args.isEmpty) {
    print(commandRunner.usage);
    return;
  }

  commandRunner.run(args);
}
