// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mtrust_api_guard/api_guard_command_mixin.dart';
import 'package:mtrust_api_guard/changelog_generator/changelog_generator.dart';
import 'package:mtrust_api_guard/doc_comparator/doc_comparator.dart';

import 'package:mtrust_api_guard/doc_generator/git_utils.dart';
import 'package:mtrust_api_guard/logger.dart';

class ChangelogGeneratorCommand extends Command
    with ApiGuardCommandMixinWithRoot, ApiGuardCommandMixinWithBaseNew, ApiGuardCommandMixinWithCache {
  @override
  String get description => "Generate a changelog entry based on API changes";

  @override
  String get name => "changelog";

  static final ChangelogGeneratorCommand _instance = ChangelogGeneratorCommand._internal();

  factory ChangelogGeneratorCommand() => _instance;

  @override
  String get usage {
    return super.usage +
        "\n\n"
            "Generates a changelog entry based on API changes between versions and updates CHANGELOG.md.\n"
            "Uses the current package version from pubspec.yaml.\n";
  }

  ChangelogGeneratorCommand._internal() {
    argParser.addFlag(
      'update',
      abbr: 'u',
      help: 'Update the CHANGELOG.md file',
      defaultsTo: true,
    );
  }

  bool get update {
    return argResults?['update'] as bool;
  }

  @override
  FutureOr? run() async {
    final resolvedBaseRef = baseRef ?? await GitUtils.getPreviousRef(Directory.current.path);
    final changes = await compare(
      baseRef: resolvedBaseRef,
      newRef: newRef,
      dartRoot: root,
      gitRoot: Directory.current,
      cache: cache,
    );

    // Generate changelog
    final changelogGenerator = ChangelogGenerator(
      apiChanges: changes,
      projectRoot: root,
      baseRef: resolvedBaseRef,
      newRef: newRef,
    );

    if (update) {
      logger.info('Updating CHANGELOG.md file');
      await changelogGenerator.updateChangelogFile();
    } else {
      final changelogEntry = await changelogGenerator.generateChangelogEntry();
      print('\n$changelogEntry');
    }
  }
}
