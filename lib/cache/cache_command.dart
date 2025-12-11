import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mtrust_api_guard/api_guard_command_mixin.dart';
import 'package:mtrust_api_guard/doc_generator/cache.dart';
import 'package:mtrust_api_guard/logger.dart';

class CacheCommand extends Command with ApiGuardCommandMixinWithRoot {
  @override
  String get description => "Manage the API documentation cache";

  @override
  String get name => "cache";

  @override
  ArgParser get argParser {
    final argParser = super.argParser;

    if (!argParser.hasOptionWithKey('clear')) {
      argParser.addFlag(
        'clear',
        help: 'Clear all cached API documentation',
        negatable: false,
      );
    }

    if (!argParser.hasOptionWithKey('clear-repo')) {
      argParser.addFlag(
        'clear-repo',
        help: 'Clear cached API documentation for the current repository only',
        negatable: false,
      );
    }

    if (!argParser.hasOptionWithKey('list')) {
      argParser.addFlag(
        'list',
        help: 'List all cached refs for the current repository',
        negatable: false,
      );
    }

    return argParser;
  }

  bool get clear {
    return argResults?['clear'] as bool? ?? false;
  }

  bool get clearRepo {
    return argResults?['clear-repo'] as bool? ?? false;
  }

  bool get list {
    return argResults?['list'] as bool? ?? false;
  }

  @override
  FutureOr? run() async {
    final cache = Cache();

    if (clear) {
      // Clear all cache
      final cacheDir = cache.getCacheDir();
      if (cacheDir.existsSync()) {
        logger.info('Clearing all cache at ${cacheDir.path}...');
        cacheDir.deleteSync(recursive: true);
        logger.success('✓ Cache cleared successfully');
      } else {
        logger.info('Cache directory does not exist');
      }
      return;
    }

    if (clearRepo) {
      // Clear cache for current repo only
      final repoPath = root.path;
      final repoCacheDir = cache.getRepositoryCacheDir(repoPath);
      if (repoCacheDir.existsSync()) {
        logger.info('Clearing cache for repository at ${repoCacheDir.path}...');
        repoCacheDir.deleteSync(recursive: true);
        logger.success('✓ Repository cache cleared successfully');
      } else {
        logger.info('No cache found for this repository');
      }
      return;
    }

    if (list) {
      // List cached refs for current repo
      final repoPath = root.path;
      final cachedRefs = cache.listCachedRefs(repoPath);

      if (cachedRefs.isEmpty) {
        logger.info('No cached API documentation found for this repository');
      } else {
        logger.info('Cached refs for this repository:');
        for (final ref in cachedRefs) {
          logger.info('  - $ref');
        }
        logger.success('✓ Found ${cachedRefs.length} cached ref(s)');
      }
      return;
    }

    // If no flags provided, show help
    logger.info(usage);
  }
}
