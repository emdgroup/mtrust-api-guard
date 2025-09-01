import 'package:args/command_runner.dart';

// ignore: implementation_imports
import 'package:args/src/arg_parser.dart';

extension ArgParserExt on ArgParser {
  /// Checks if the parser contains an option with the given key.
  bool hasOptionWithKey(String key) {
    return options.entries.any((e) => e.key == key);
  }
}

mixin ApiGuardCommandMixinWithRoot on Command {
  @override
  ArgParser get argParser {
    final argParser = super.argParser;
    if (!argParser.hasOptionWithKey('root')) {
      argParser.addOption(
        'root',
        abbr: 'r',
        help: 'Root directory of the Dart project.'
            ' Defaults to auto-detect from the current directory.',
        defaultsTo: null,
      );
    }
    return argParser;
  }
}

mixin ApiGuardCommandMixinWithBaseNew on Command {
  @override
  ArgParser get argParser {
    final argParser = super.argParser;
    if (!argParser.hasOptionWithKey('base')) {
      argParser.addOption(
        'base',
        abbr: 'b',
        help: 'Base documentation file',
      );
    }
    if (!argParser.hasOptionWithKey('new')) {
      argParser.addOption(
        'new',
        abbr: 'n',
        help: "New documentation file",
      );
    }
    return argParser;
  }
}
