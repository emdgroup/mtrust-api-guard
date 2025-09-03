import 'package:test/test.dart';

/// Global test configuration
void configureTests() {
  // Set timeout for all tests
  setUpAll(() {
    // This will be applied to all test groups
  });
}

/// Common test timeout configuration
const testTimeout = Timeout(Duration(minutes: 5));
