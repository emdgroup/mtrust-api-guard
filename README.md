# 🔢 M-Trust API Guard

<img src="version_badge.svg" />

Automated semantic versioning for dart 🎯 packages.

This CLI tool allows you to maintain correct versioning, changelog for your dart / flutter packages. It automatically asseses your source code to detect changes in the API signatures exposed by your code.

You can use API Guard to completely manage versioning of packages, it will bump the version number, generate a changelog and commit tagged releases automatically.

## Installation

To install the package, run the following command:

```bash
dart pub global activate mtrust_api_guard
```

## Usage

After activating the package, you can run the following command to generate the files:

```bash
$ mtrust_api_guard

A documentation generator and comparator for Dart APIs

Usage: mtrust_api_guard <command> [arguments]

Global options:
-h, --help            Print this usage information.
    --[no-]verbose    Verbose output.

Available commands:
  badge       Generate version badge from current pubspec version
  changelog   Generate a changelog entry based on API changes
  compare     Compare two API documentation files
  generate    Generate API documentation from Dart files
  version     Calculate and output the next version based on API changes

Run "mtrust_api_guard help <command>" for more information about a command.
```

## Configuration

You can configure the api_guard using the analysis_options.yaml file as we treat api guard as an extension to the linter.

```yaml
api_guard:
  include: # defaults to lib/**.dart
  exclude: # ignore files from being tracked by api_guard. Note that files in analyzer.exclude are always ignored.

  # Specify entry points to only analyze files reachable from these files (and not internal implementation details)
  entry_points:
    - lib/main.dart
    - lib/another_entry_point.dart
```

> ⚠️ **Note**: If `entry_points` are configured, the `include` option is ignored. The analyzer will start at the entry points and recursively visit all exported elements. If no entry points are specified, the analyzer will include all files matching the `include` patterns. If neither `entry_points` nor `include` are specified, it defaults to `lib/**.dart`.

### Magnitude Overrides

You can customize the severity of detected API changes by defining rules in your `analysis_options.yaml`. This is useful for ignoring internal elements, relaxing rules for experimental features, or enforcing stricter rules for core components.

```yaml
api_guard:
  magnitude_overrides:
    # Example: Ignore removals of elements starting with underscore
    - operation: removal
      magnitude: ignore
      selection:
        name_pattern: "^_.*"

    # Example: Treat any change to @experimental elements as a patch change
    - operation: "*"
      magnitude: patch
      selection:
        has_annotation:
          - "experimental"

    # Example: Consider changes to descendants of 'InternalBase' as patch
    - operation: "*"
      magnitude: patch
      selection:
        subtype_of:
          - InternalBase

    # Example: Treat property additions in mixins as patch instead of minor
    - operation: addition
      magnitude: patch
      selection:
        entity:
          - property
        enclosing:
          entity:
            - mixin

    # Example: Allow removing parameters named 'key' from constructors of Widget subclasses
    - operation: removal
      magnitude: minor
      description: "Widget keys are optional"
      selection:
        entity: parameter
        name_pattern: "^key$"
        enclosing:
          entity: constructor
          enclosing:
            subtype_of: Widget

    # Example: Ignore changes in classes that extend Widgets from the Flutter package
    - operation: "*"
      magnitude: ignore
      description: "Ignore changes in Flutter Widgets"
      selection:
        from_package:
          - flutter
```

#### Override Options

- **operation**: The `ApiChangeOperation` to match (e.g., `addition`, `removal`, `renaming`, `typeChange`, or `*` for all). See [ApiChangeOperation](lib/doc_comparator/api_change.dart) for all options.
- **magnitude**: The target magnitude to apply: `major`, `minor`, `patch`, or `ignore`.
- **description** (optional): A human-readable description of why this override is in place.
- **selection**: Criteria to select the API elements to apply the rule to:
  - `name_pattern`: Regex pattern matching the element name.
  - `entity`: The type of element to match. One or more of: `class`, `mixin`, `enum`, `extension`, `method`, `function`, `property`, `constructor`, `parameter`, `typedef`.
  - `has_annotation`: List of annotation names (e.g. `deprecated`, `visibleForTesting`).
  - `subtype_of`: Matches if the element (or its parent) extends, implements, or mixes in any of the specified types. For parameters, matches if the parameter type is a subtype. For properties, matches if the property type is a subtype. For methods, matches if the return type is a subtype.
  - `from_package`: Matches if the element (or its parent) extends a class from the specified package.
    - For external packages, use the package name (e.g. `flutter`, `provider`).
    - For the Dart SDK, use the library uri (e.g. `dart:core`, `dart:async`).
  - `enclosing`: Recursive selection for the parent element (e.g. match a method only if it's within a specific class).

## Working with Git References

This tool supports generating documentation and comparing APIs across different git references (branches, commits, tags).

### Generate documentation for a specific ref

```bash
# Generate and cache API documentation for the 'main' branch
mtrust_api_guard generate --ref main

# Generate and cache API documentation for a feature branch
mtrust_api_guard generate --ref feature/new-api

# Generate and cache API documentation for a specific commit
mtrust_api_guard generate --ref abc1234

# Generate and cache API documentation for a tag
mtrust_api_guard generate --ref v1.0.0
```

### Compare References

```bash
# Compare main branch with current HEAD
mtrust_api_guard compare --base-ref main --new-ref HEAD

# Compare two specific branches
mtrust_api_guard compare --base-ref develop --new-ref feature/new-api

# Compare current state with a previous commit
mtrust_api_guard compare --base-ref abc1234 --new-ref HEAD

# Compare two specific commits
mtrust_api_guard compare --base-ref v1.0.0 --new-ref v1.1.0
```

### Safety Features

The tool includes several safety features to prevent data loss:

1. **Uncommitted Changes Check**: If you have uncommitted changes and try to use `--ref`, the tool will error out
2. **Automatic State Restoration**: After generating documentation for a ref, the tool automatically restores your original git state
3. **Cache Validation**: The tool validates that generated documentation is properly cached before proceeding

### Cache Management

The cache is automatically managed and located at `~/.mtrust_api_guard/cache/`:

```bash
# View cached references for current repository
ls ~/.mtrust_api_guard/cache/$(basename $(git rev-parse --show-toplevel))/

# Clear cache for current repository
rm -rf ~/.mtrust_api_guard/cache/$(basename $(git rev-parse --show-toplevel))/
```

## Generate

Generates the api description of a specific `--ref` the output is a json file based on analyzer. See an example [here](./test/fixtures/apiV100.json).

```sh
mtrust_api_guard generate
```

```
Usage: mtrust_api_guard generate [arguments]
-r, --root          Root directory of the Dart project. Defaults to auto-detect from the current directory.
-c, --[no-]cache    Cache the generated documentation for the specified ref
                    (defaults to on)
    --ref           Git reference (commit hash, branch, or tag) to generate documentation for. If not provided, uses current HEAD.
                    (defaults to "HEAD")
    --out           Write the generated documentation to a file
-h, --help          Print this usage information.
```

## Compare

Compare the APIs of two git refs (`--base-ref` and `--new-ref`) and outputs the API changes that occured.

```sh
mtrust_api_guard compare
```

```
Usage: mtrust_api_guard compare [arguments]
-b, --base-ref      The previous version to compare against.Defaults to previous version from git history.
-n, --new-ref       The new version to compare against defaulting to HEAD
                    (defaults to "HEAD")
-r, --root          Root directory of the Dart project. Defaults to auto-detect from the current directory.
-c, --[no-]cache    Cache the generated documentation for the specified ref
                    (defaults to on)
-h, --help          Print this usage information.
-m, --magnitudes    Show only changes with the specified magnitudes
                    [major (default), minor (default), patch (default)]
    --out           Write the comparison results to a file
```

See an example output [here](./test/fixtures/expected_compare_v100_v101.txt)

## Changelog

Generate a changelog for the specified interval. Defaults to generating a changelog for everything since the last tagged release and the current head.

```sh
mtrust_api_guard changelog
```

```
-r, --root           Root directory of the Dart project. Defaults to auto-detect from the current directory.
-b, --base-ref       The previous version to compare against. Defaults to previous version from git history.
-n, --new-ref        The new version to compare against defaulting to HEAD
                     (defaults to "HEAD")
-c, --[no-]cache     Cache the generated documentation for the specified ref
                     (defaults to on)
-h, --help           Print this usage information.
-u, --[no-]update    Update the CHANGELOG.md file
                     (defaults to on)
```

## Version

Detects the API changes that occured and creates a changelog, version bump, version badge and tag automatically.

```sh
mtrust_api_guard version
```

```
-r, --root                       Root directory of the Dart project. Defaults to auto-detect from the current directory.
-b, --base-ref                   The previous version to compare against.Defaults to previous version from git history.
-n, --new-ref                    The new version to compare against defaulting to HEAD
                                 (defaults to "HEAD")
-c, --[no-]cache                 Cache the generated documentation for the specified ref
                                 (defaults to on)
-h, --help                       Print this usage information.
-g, --[no-]badge                 Generate a badge for the version
    --[no-]commit                Commit the version to git
                                 (defaults to on)
-t, --[no-]tag                   Tag the version
                                 (defaults to on)
    --[no-]generate-changelog    Generate a changelog entry based on API changes
                                 (defaults to on)
-p, --[no-]pre-release           Add pre-release suffix (-dev.N)
    --tag-prefix=<prefix>        Prefix for version tags
                                 (defaults to "v")
```

### Custom Tag Prefixes

By default, version tags are prefixed with `v` (e.g., `v1.0.0`). You can customize this prefix using the `--tag-prefix` flag:

```sh
# Use a custom prefix like 'release/'
mtrust_api_guard version --tag-prefix release/

# This will create tags like: release/1.0.0, release/1.1.0, etc.

# Use no prefix at all
mtrust_api_guard version --tag-prefix ""

# This will create tags like: 1.0.0, 1.1.0, etc.
```

## Usage in CI

- It is reccommended to version on the target branch you release from (e.g. main).
- To facilitate branch protection we recommend setting up a GitHub App and using its token to push to main. (https://github.com/orgs/community/discussions/25305#discussioncomment-8256560)
- You can run the `compare` command in your PR workflow and comment the API changes to the Pull request to increase transparency of the effects a PR has.

In CI/CD pipelines, you can use git references directly:

```yaml
- name: Compare API changes
  run: |
    mtrust_api_guard compare --base-ref main --new-ref ${{ github.sha }}
```

This eliminates the need to check in generated API files and prevents merge conflicts.

## License

This project is licensed under the Apache-2.0 license. See the [LICENSE](LICENSE) file for details.
