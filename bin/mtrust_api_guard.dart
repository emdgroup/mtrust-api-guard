import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mtrust_api_guard/badges/badge_generator_command.dart';
import 'package:mtrust_api_guard/cache/cache_command.dart';
import 'package:mtrust_api_guard/changelog_generator/changelog_generator_command.dart';
import 'package:mtrust_api_guard/doc_comparator/doc_comparator_command.dart';
import 'package:mtrust_api_guard/doc_generator/doc_generator_command.dart';
import 'package:mtrust_api_guard/logger.dart';
import 'package:mtrust_api_guard/version/version_command.dart';

main(List<String> args) async {
  final commandRunner = CommandRunner(
    'mtrust_api_guard',
    'A documentation generator and comparator for Dart APIs',
  )
    ..addCommand(BadgeGeneratorCommand())
    ..addCommand(CacheCommand())
    ..addCommand(DocGeneratorCommand())
    ..addCommand(DocComparatorCommand())
    ..addCommand(ChangelogGeneratorCommand())
    ..addCommand(VersionCommand());

  commandRunner.argParser.addFlag(
    "verbose",
    help: "Verbose output.",
    defaultsTo: false,
  );

  commandRunner.argParser.addFlag(
    "silent",
    help: "Dont print logs to the console.",
    defaultsTo: false,
  );

  if (args.isEmpty) {
    // ignore: avoid_print
    print(commandRunner.usage);
    return;
  }

  if (args.contains('--verbose')) {
    logger.level = Level.verbose;
  }
  if (args.contains('--silent')) {
    logger.level = Level.error;
  }
  commandRunner.run(args);
}
