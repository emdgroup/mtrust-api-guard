import 'package:args/command_runner.dart';
import 'package:mtrust_api_guard/changelog_generator/changelog_generator_command.dart';
import 'package:mtrust_api_guard/doc_comparator/doc_comparator_command.dart';
import 'package:mtrust_api_guard/doc_generator/doc_generator_command.dart';
import 'package:mtrust_api_guard/version/version_command.dart';

main(List<String> args) async {
  final commandRunner = CommandRunner(
    'mtrust_api_guard',
    'A documentation generator and comparator for Dart APIs',
  )
    ..addCommand(DocGeneratorCommand())
    ..addCommand(DocComparatorCommand())
    ..addCommand(ChangelogGeneratorCommand())
    ..addCommand(VersionCommand());

  commandRunner.argParser.addFlag(
    "verbose",
    help: "Verbose output.",
    defaultsTo: false,
  );

  if (args.isEmpty) {
    print(commandRunner.usage);
    return;
  }

  commandRunner.run(args);
}
