# Test Structure

This directory contains the test files for the mtrust-api-guard project, organized into a modular structure for better maintainability and organization.

## Directory Structure

```
test/
├── README.md                    # This file
├── mtrust_api_guard_test.dart  # Main test runner
├── test_config.dart            # Global test configuration
├── helpers/                    # Common test utilities
│   ├── test_helpers.dart      # Helper functions and constants
│   └── test_setup.dart        # Test setup and teardown utilities
└── commands/                   # Command-specific test files
    ├── generate_command_test.dart  # Tests for the generate command
    ├── compare_command_test.dart   # Tests for the compare command
    └── version_command_test.dart   # Tests for the version command
```

## Test Organization

### Main Test Runner
- `mtrust_api_guard_test.dart` - Imports and runs all test files

### Helper Files
- `test_helpers.dart` - Contains common utility functions like `copyDir`, `runProcess`, and `stripChangelog`
- `test_setup.dart` - Manages test environment setup, teardown, and common operations like git setup

### Command Tests
Each command has its own test file:
- **Generate Command**: Tests API documentation generation functionality
- **Compare Command**: Tests API comparison between different versions
- **Version Command**: Tests version management and changelog generation

## Running Tests

To run all tests:
```bash
dart test
```

To run specific test files:
```bash
dart test test/commands/generate_command_test.dart
dart test test/commands/compare_command_test.dart
dart test test/commands/version_command_test.dart
```

## Test Constants

Common test constants are defined in `TestConstants` class:
- Version numbers for testing
- Test user credentials
- Common paths

## Test Fixtures

Test fixtures are managed through the `TestFixtures` class, which provides access to:
- Different app versions for testing
- Expected output files
- Test data directories

## Benefits of This Structure

1. **Modularity**: Each command's tests are isolated and focused
2. **Maintainability**: Common utilities are centralized and reusable
3. **Readability**: Tests are easier to understand and navigate
4. **Scalability**: Easy to add new command tests or modify existing ones
5. **Reusability**: Helper functions can be shared across different test files
