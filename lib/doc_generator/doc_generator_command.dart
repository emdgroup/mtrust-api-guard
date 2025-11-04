import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mtrust_api_guard/api_guard_command_mixin.dart';
import 'package:mtrust_api_guard/doc_generator/doc_generator.dart';
import 'package:mtrust_api_guard/logger.dart';

class DocGeneratorCommand extends Command with ApiGuardCommandMixinWithRoot, ApiGuardCommandMixinWithCache {
  @override
  String get description => "Generate API documentation from Dart files";

  @override
  String get name => "generate";

  @override
  ArgParser get argParser {
    final argParser = super.argParser;

    if (!argParser.hasOptionWithKey('ref')) {
      argParser.addOption(
        'ref',
        help:
            'Git reference (commit hash, branch, or tag) to generate documentation for. If not provided, uses current HEAD.',
        defaultsTo: 'HEAD',
      );
    }

    if (!argParser.hasOptionWithKey('out')) {
      argParser.addOption(
        'out',
        help: 'Write the generated documentation to a file',
      );
    }

    return argParser;
  }

  String? get out {
    return argResults?['out'] as String?;
  }

  String get ref {
    return argResults?['ref'] as String;
  }

  bool get help {
    return argResults?['help'] as bool;
  }

  @override
  FutureOr? run() {
    if (help) {
      logger.info('Documentation Generator');
      logger.info('Usage: dart doc_generator.dart [options]');
      logger.info(argParser.usage);
      return null;
    }
    generateDocs(
      gitRef: ref,
      out: out,
      dartRoot: root,
      gitRoot: Directory.current,
      shouldCache: cache,
    );
  }
}
