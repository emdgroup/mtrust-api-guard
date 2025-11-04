import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mtrust_api_guard/api_guard_command_mixin.dart';
import 'package:mtrust_api_guard/badges/badge_generator.dart';
import 'package:mtrust_api_guard/logger.dart';
import 'package:mtrust_api_guard/pubspec_utils.dart';

class BadgeGeneratorCommand extends Command with ApiGuardCommandMixinWithRoot {
  @override
  String get description => "Generate version badge from current pubspec version";

  @override
  String get name => "badge";

  @override
  ArgParser get argParser {
    final argParser = super.argParser;

    if (!argParser.hasOptionWithKey('out')) {
      argParser.addOption(
        'out',
        defaultsTo: 'version_badge.svg',
        help: 'Write the generated badge to a file',
      );
    }

    return argParser;
  }

  String? get out {
    return argResults?['out'] as String?;
  }

  bool get help {
    return argResults?['help'] as bool;
  }

  @override
  FutureOr? run() async {
    if (help) {
      logger.info(argParser.usage);
      return null;
    }

    try {
      // Find pubspec.yaml in the root directory
      final pubspecFile = File('${root.path}/pubspec.yaml');
      if (!pubspecFile.existsSync()) {
        logger.err('pubspec.yaml not found in ${root.path}');
        return 1;
      }

      // Read current version from pubspec
      final pubspecContent = await pubspecFile.readAsString();
      final version = PubspecUtils.getVersion(pubspecContent);
      logger.info('Current version: ${version.toString()}');

      // Generate badge
      final badgeContent = await generateVersionBadge(version.toString());
      logger.info('Badge generated successfully');

      // Output to file if specified, otherwise to console
      if (out != null) {
        final outputFile = File(out!);
        await outputFile.writeAsString(badgeContent);
        logger.info('Badge written to: ${outputFile.path}');
      }

      return 0;
    } catch (e) {
      logger.err('Failed to generate badge: $e');
      return 1;
    }
  }
}
