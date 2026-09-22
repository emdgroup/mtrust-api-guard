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
  dead-code   Report declarations nothing live refers to and no consumer can reach
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

  # Let conventional commit types raise a version bump the API diff cannot see
  conventional_commits: false
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
    --base-url      Base URL for file links (e.g. https://github.com/org/repo/blob/v1.0.0)
    --[no-]dead-code
                    Append a warning section listing declarations nothing live refers to
                    and no consumer can reach. Never affects the exit code.
```

With `--dead-code`, `compare` reports what the change introduced rather than
everything currently dead, between the same two refs the API half compares.
A ref that is a generated api json file rather than a git ref has no tree behind
it to scan: the report then falls back to everything dead in the working tree,
and says so.

See an example output [here](./test/fixtures/expected_compare_v100_v101.txt)

## Changelog

Generate a changelog for the specified interval. Defaults to generating a changelog for everything since the last tagged release and the current head.

```sh
mtrust_api_guard changelog
```

Regenerate the entire `CHANGELOG.md` by walking version tags and comparing each consecutive release pair. This overwrites the file.

```sh
mtrust_api_guard changelog --regenerate
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
    --[no-]regenerate
                       Regenerate the entire CHANGELOG.md from version tags,
                       overwriting the file
    --tag-prefix=<prefix>
                       Prefix for version tags (defaults to "v")
    --package=<name>   Package name for workspace tags (package/vX.Y.Z)
    --concurrency=<count>
                       Number of refs to analyze in parallel when regenerating
                       (defaults to "4")
```

When regenerating, the API documentation for each tag is analyzed in parallel (bounded by `--concurrency`). The first tagged release is diffed against the repository's root commit; if that commit has no analyzable Dart project (e.g. an empty initial commit), the API diff for that release is skipped and only its commit summary is shown.

pub.dev rejects publishes when `CHANGELOG.md` exceeds **262144 bytes**. After updating or regenerating a changelog, older `##` version sections are moved into `CHANGELOG_ARCHIVE.md` (with a markdown link left in `CHANGELOG.md`) so the published changelog stays under that limit.

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
    --[no-]conventional-commits  Let the conventional commit types since the base ref
                                 raise the bump when the API diff asks for less.
```

### Bumping from conventional commits

The bump comes from the diff of the exported API, so a release that the exports
do not show comes out as a patch. A new command, a fix behind the entry points
or a rewrite of something internal all look the same from outside: nothing
changed.

`--conventional-commits` reads the commits between the base ref and HEAD as a
floor under that: `feat` asks for a minor, `fix` and `perf` for a patch, and a
`!` or a `BREAKING CHANGE:` footer for a major. Whichever of the two is higher
wins, so it can raise a bump and never lower one. Types the tool does not know
say nothing.

It is off by default, because switching it on changes the next version number of
every repo that releases with it. Turn it on per repo in `analysis_options.yaml`:

```yaml
api_guard:
  conventional_commits: true
```

The flag wins over the config, so `--no-conventional-commits` turns it off again
for a single release. In a workspace only the commits that touched a package
count towards that package's bump.

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

## Version Workspace

Same as `version`, but for Dart workspaces: every package listed in the root pubspec's `workspace` property is versioned and tagged individually. Only packages with changes since their last tag are versioned, and version constraints between workspace packages are updated automatically.

```sh
mtrust_api_guard version-workspace
```

Tags are created per package as `{package}/v{version}` (e.g. `my_pkg/v1.2.0`). The format can be changed with `--tag-format`, which also controls how existing tags are looked up. Useful when migrating from melos, which tags as `my_pkg-v1.2.0`:

```sh
mtrust_api_guard version-workspace --tag-format "{package}-v{version}"
```

The format must contain `{package}` and end with `{version}`.

## Dead Code

Reports declarations that nothing in the package reaches. Every library under
`lib/`, `bin/`, `test/`, `tool/`, `example/`, `benchmark/` and `integration_test/`
is resolved once, and the resolved ASTs give a graph: what each file declares,
and what the code of each declaration refers to. Tests, executables, examples
and whatever a consumer can reach are the roots. A declaration a walk from them
never gets to is dead, even when other dead code refers to it, so two classes
that only refer to each other are both reported. An `example/` with a pubspec of
its own is resolved as the separate package it is, and what it uses counts all
the same.

Entry points are resolved by the same code the `generate` command enters a
package with, so the closure a finding is checked against is the closure the
generated API documentation describes.

```sh
mtrust_api_guard dead-code
```

```
-r, --root        Root directory of the Dart project. Defaults to auto-detect from the current directory.
-h, --help        Print this usage information.
-f, --format      Output format
                  [text (default), markdown, json]
    --out         Write the report to a file. Repeat it to write several formats
                  from one scan, in which case the format comes from each file
                  extension (.json, .md) and falls back to --format.
    --base-url    Base URL for file links (e.g. https://github.com/org/repo/blob/main)
-b, --base-ref    Report only what changed since this git ref, rather than
                  everything currently dead. Costs a second analysis pass.
```

### Only what a change introduced

Everything currently dead is rarely what a reviewer needs. They can act on a
declaration this branch orphaned, and can do nothing about debt that predates
it. `--base-ref` scans that ref as well and splits the findings in four:

```sh
mtrust_api_guard dead-code --base-ref main
```

```
Dead code introduced since main:
  lib/src/report.dart:41  field Report.unusedField

Deleted:
  lib/src/legacy.dart  function oldHelper

No longer dead:
  lib/src/cache.dart  class CacheEntry

1 added, 1 deleted, 1 no longer dead, 9 already there.
```

A finding is matched across revisions by its file, qualified name and kind,
never by line number, so a declaration that moved down because someone added an
import is still the same finding rather than a new one. One that left the report
is listed as deleted when the declaration is gone from the new revision, and as
no longer dead when it is still there and live code reaches it now. A rename or
a move reads as a deletion, because a finding names a declaration in a file.

The base ref is materialized as a git worktree with its dependencies resolved,
the same way `generate --ref` does it, so the second scan sees the same thing
the first one does. `dead-code` scans the working tree as the other side of the
comparison; `compare --dead-code` scans its `--new-ref`, and only falls back to
the working tree when that ref is already the checkout. Run `pub get` before scanning: an unresolved package cannot
follow its own `package:` imports, and anything reached only through one then
looks dead. The scan warns when there is no package config, or when the one
there lists packages that have since gone from the pub cache. A pub workspace
member is resolved through the workspace root's config.

Unreferenced is not the same as dead. For a published package the whole exported
API is unreferenced from the package's own point of view, which is why a plain
dead code detector either buries you in findings or has to stop reporting public
ones. Findings are split against the export closure of the configured
`entry_points` instead:

- **dead**: nothing live refers to it and the package does not export it, so no
  consumer can reach it either. Exporting a class does not export its private
  members, so an unused one is dead even when the class is API surface.
- **API surface**: nothing inside uses it, but it is exported. A consumer can
  call it, so it is listed separately and never counted as dead.
- **doc-only**: the only thing referring to it is a dartdoc `[Link]`. A comment
  mentioning something is not code using it, but it is not silence either. What
  it uses is not reported as dead, because it is not reported as dead itself.

Without `entry_points`, the package's main library (`lib/<package_name>.dart`)
is used. If neither exists the closure is unknown, and public declarations are
reported as API surface rather than asserted to be dead.

The report never changes the exit code. It is there to tell a reviewer something,
not to block a merge, and nothing is ever deleted for you.

### What it skips

Each of these is a source of false positives that references in source cannot
settle on their own.

| Skipped | Why |
| --- | --- |
| `main` | An entry point is never unused. |
| Files matched by `analyzer.exclude` or `api_guard.exclude` | Excluded from analysis means excluded from the report. Both sections are honoured. A part is still read along with its library, so a generated part excluded to quiet lints still counts as a reference. |
| The untaken branches of a conditional import or export | The analyzer resolves one branch, but another platform compiles the others. A declaration there counts as referenced, or exported, when its namesake in another branch is. |
| Generated files | By filename (`.g.dart`, `.freezed.dart`, `.mocks.dart`, …) and by the `GENERATED CODE - DO NOT MODIFY BY HAND` banner. They are part of the graph all the same: what live generated code uses is live, and a class only its own `.g.dart` refers to is dead. |
| `@pragma('vm:entry-point')` | Reachable from native code or reflection. |
| `==`, `hashCode`, `toString`, `noSuchMethod`, `call`, `toJson`, `fromJson` | Invoked by the language or by `jsonEncode` with no source-level reference, once their class is live. |
| An override whose chain leaves the package | A framework may be the caller once the class is live. An override whose chain stays inside the package is live when its class is and a member it overrides is. |
| Members of a declaration that is itself reported | Only the outermost one is reported, so the finding names the thing to delete. A dead private member of a class that is API surface is the exception. |
| Local variables and functions, type parameters | The analyzer's own `unused_element` lint covers these. |

Operators are reported like anything else, because `a + b` resolves back to the
`operator +` declaration through the element model.

### In a pull request

Append the report to the API change comment that `compare` already produces:

```yaml
- name: Compare API changes
  run: |
    mtrust_api_guard compare \
      --base-ref main --new-ref ${{ github.sha }} \
      --dead-code --base-url https://github.com/${{ github.repository }}/blob/${{ github.sha }}
```

`--base-url` turns the file names into links. The section is omitted when the
change neither added dead code nor cleared any, so a clean pull request carries
no line about it. A failed scan is logged and skipped rather than failing the
comparison.

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
