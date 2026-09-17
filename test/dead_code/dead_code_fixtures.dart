import 'package:mtrust_api_guard/dead_code/dead_code_report.dart';

/// A declaration to render or diff, with everything the tests don't care about
/// already filled in.
DeadDeclaration declaration({
  String name = 'Widget',
  String? container,
  DeadCodeKind kind = DeadCodeKind.classKind,
  String filePath = 'lib/src/widget.dart',
  int line = 12,
}) => DeadDeclaration(name: name, container: container, kind: kind, filePath: filePath, line: line, column: 7);

DeadCodeReport report({
  List<DeadDeclaration> dead = const [],
  List<DeadDeclaration> apiSurface = const [],
  List<DeadDeclaration> docOnly = const [],
}) => DeadCodeReport(dead: dead, apiSurface: apiSurface, docOnly: docOnly, filesScanned: 4, declarationsChecked: 40);
