import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mtrust_api_guard/doc_comparator/doc_comparator_command.dart';
import 'package:mtrust_api_guard/doc_generator/doc_generator_command.dart';
import 'package:mtrust_api_guard/logger.dart';

main(List<String> args) async {
  final commandRunner = CommandRunner(
    'mtrust_api_guard',
    'A documentation generator and comparator for Dart APIs',
  )
    ..addCommand(DocGeneratorCommand())
    ..addCommand(DocComparatorCommand());

  commandRunner.argParser
    ..addOption(
      "root",
      help: "Root directory of the project. The root of the dart project.",
      defaultsTo: null,
    )
    ..addFlag(
      "verbose",
      help: "Verbose output.",
      defaultsTo: false,
    );

  if (args.isEmpty) {
    print(commandRunner.usage);
    return;
  }

  final argResults = commandRunner.parse(args);

  if (argResults.flag("verbose")) {
    logger.level = Level.verbose;
    logger.info("Verbose output enabled");
  }

  commandRunner.run(args);
}
