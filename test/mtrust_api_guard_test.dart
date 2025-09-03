// Import all test files
import 'commands/generate_command_test.dart' as generate_tests;
import 'commands/compare_command_test.dart' as compare_tests;
import 'commands/version_command_test.dart' as version_tests;

void main() {
  // Run all test groups
  generate_tests.main();
  compare_tests.main();
  version_tests.main();
}
