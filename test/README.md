# Test Structure

This directory contains the test files for the mtrust-api-guard project, organized into a modular structure for better maintainability and organization.

## Directory Structure

```
test/
├── README.md                    # This file
├── test_config.dart            # Global test configuration
├── helpers/                    # Common test utilities
│   ├── fixture_package.dart   # Copy a fixture somewhere writable and resolve it
│   ├── test_bootstrap.dart    # Auto compile binary + Flutter scaffolds
│   ├── test_helpers.dart      # Helper functions and constants
│   └── test_setup.dart        # Test setup and teardown utilities
├── commands/                   # Command-specific test files
│   ├── generate_command_test.dart
│   ├── compare_command_test.dart
│   ├── dead_code_command_test.dart
│   └── version_command_test.dart
└── dead_code/                  # Dead code rule, delta and formatter tests
    ├── dead_code_fixtures.dart
    ├── dead_code_delta_test.dart
    ├── dead_code_finder_test.dart
    ├── dead_code_formatter_test.dart
    └── ref_worktree_test.dart
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
flutter test test/commands/dead_code_command_test.dart
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

### Dead code fixtures

`test/fixtures/app_v100` carries the dead code cases as well, in
`lib/src/dead_code_cases.dart` plus a `.g.dart`, a `bin/` and a `test/`
directory. None of it is reachable from `lib/src/api.dart`, the entry point
that fixture configures, so none of it reaches the generated API documentation
and the diff goldens (`apiV100.json`, `expected_compare_v100_v101.txt`,
`expected_changelog.md`) do not see it.

That constraint is the thing to respect when editing: anything added to
`lib/src/api.dart` **does** land in those goldens, private declarations
included, so the cases live beside it rather than in it.

`test/dead_code/dead_code_finder_test.dart` asserts one rule per test against
that fixture in process, and `test/commands/dead_code_command_test.dart` runs
the command end to end against `app_v100`, `app_v101` and `app_v110`.

## Looking at what the tool produces

Every pull request renders the tool's output on our own fixtures into the
workflow run's **Summary** tab: the `compare` diff between each consecutive
fixture version, and the `dead-code` report for each one. That is the
`Show what api_guard produces for the fixtures` step in the `validate-dart`
action, and it is the same thing you get locally from

```bash
dart run tool/dump_fixture_reports.dart
```

Pass or fail of the tests themselves is a separate `Flutter Tests` check,
published by `dorny/test-reporter` from `reports/test-results.json`.

Two of those outputs are also committed, as `test/fixtures/apiV100.json` and
`test/fixtures/expected_compare_v100_v101.txt`, because the tests assert against
them. A change in what the tool emits shows up as a diff on those files.

## Benefits of This Structure

1. **Modularity**: Each command's tests are isolated and focused
2. **Maintainability**: Common utilities are centralized and reusable
3. **Readability**: Tests are easier to understand and navigate
4. **Scalability**: Easy to add new command tests or modify existing ones
5. **Reusability**: Helper functions can be shared across different test files
