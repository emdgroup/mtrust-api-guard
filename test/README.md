# Test Structure

This directory contains the test files for the mtrust-api-guard project, organized into a modular structure for better maintainability and organization.

## Directory Structure

```
test/
├── README.md                    # This file
├── test_config.dart            # Global test configuration
├── helpers/                    # Common test utilities
│   ├── test_bootstrap.dart    # Auto compile binary + Flutter scaffolds
│   ├── test_helpers.dart      # Helper functions and constants
│   └── test_setup.dart        # Test setup and teardown utilities
└── commands/                   # Command-specific test files
    ├── generate_command_test.dart
    ├── compare_command_test.dart
    └── version_command_test.dart
```

## Running Tests

No manual setup is required. Integration tests bootstrap automatically on first `setUp()`:

- Compiles `build/mtrust_api_guard` when missing or when `lib/` / `bin/` changed
- Generates `.test_scaffolds/package_base/` and `plugin_base/` when missing (always on CI)

```bash
flutter test
```

`test/flutter_test_config.dart` bootstraps binaries and fixtures and removes any legacy scaffolds under `test/fixtures/` before tests run.

To run specific integration test files:

```bash
flutter test test/commands/generate_command_test.dart
flutter test test/commands/compare_command_test.dart
flutter test test/commands/version_command_test.dart
```

## Test Constants

Common test constants are defined in `TestConstants` class:
- Version numbers for testing
- Test user credentials
- Common paths

## Test Fixtures

Test fixtures are managed through the `TestFixtures` class, which provides access to:
- Different app versions for testing (`app_v100`, `app_v101`, etc.)
- Generated Flutter scaffolds (`package_base`, `plugin_base` in `.test_scaffolds/`) — not committed, created by bootstrap
- Expected output files

If scaffold drift occurs after a Flutter SDK upgrade locally, delete `.test_scaffolds/` and re-run tests.

## Benefits of This Structure

1. **Modularity**: Each command's tests are isolated and focused
2. **Maintainability**: Common utilities are centralized and reusable
3. **Readability**: Tests are easier to understand and navigate
4. **Scalability**: Easy to add new command tests or modify existing ones
5. **Reusability**: Helper functions can be shared across different test files
