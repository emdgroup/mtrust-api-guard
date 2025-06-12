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

  commandRunner.argParser
    ..addOption(
      "root",
      help: "Root directory of the project. The root of the dart project."
          "If omitted, walks up the directory tree until it finds a pubspec.yaml file.",
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

  commandRunner.run(args);
}
