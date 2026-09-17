// Deliberately not named `*_test.dart`: this repository's own `dart test` run
// globs `test/**_test.dart`, and a fixture file is not a test of this package.
// The dead code scan globs `test/**.dart`, so the name changes nothing.

import 'package:api_guard_test/src/dead_code_cases.dart';

void main() {
  // ignore: unnecessary_statements
  UsedOnlyByTest().ok;
}
