import 'dart:io';

import 'package:mtrust_api_guard/doc_generator/ref_worktree.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('resolveDependencies', () {
    late Directory package;

    setUp(() => package = Directory.systemTemp.createTempSync('api_guard_resolve_'));
    tearDown(() => package.deleteSync(recursive: true));

    test('carries the reason pub gave into the error', () {
      File(p.join(package.path, 'pubspec.yaml')).writeAsStringSync('''
name: unresolvable
publish_to: none
environment:
  sdk: ">=3.11.0 <4.0.0"
dependencies:
  nowhere:
    path: ../does_not_exist
''');

      expect(
        () => resolveDependencies(package.path),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('does_not_exist'))),
      );
    });
  });
}
