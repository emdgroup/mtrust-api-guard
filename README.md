# mtrust_api_guard

## Installation

To install the package, run the following command:

```bash
dart pub global activate mtrust_api_guard
```

## Usage

After activating the package, you can run the following command to generate the files:

```bash
mtrust_api_guard
```

```
A documentation generator and comparator for Dart APIs

Usage: mtrust_api_guard <command> [arguments]

Global options:
-h, --help    Print this usage information.

Available commands:
  compare    Compare two API documentation files
  generate   Generate API documentation from Dart files
  changelog  Generate a changelog entry based on API changes
  version    Calculate and output the next version based on API changes

Run "mtrust_api_guard help <command>" for more information about a command.
```

### Configuration

You can configure the api_guard using the analysis_options.yaml file as we treat api guard as an extension to the linter.

```yaml
api_guard:
  include: # defaults to lib/**.dart
  exclude: # ignore files from being tracked by api_guard. Note that files in analyzer.exclude are always ignored.
  documentation_file: # defaults to lib/documentation.g.dart
```

### Generate

```bash
Generate API documentation from Dart files

Usage: mtrust_api_guard generate [arguments]
-h, --help      Print this usage information.
-p, --path      Path(s) to scan for Dart files
                (defaults to "lib/src")
-o, --output    Output file path
                (defaults to "documentation.g.dart")
```

### Compare

```bash
Compare two API documentation files

Usage: mtrust_api_guard compare [arguments]
-h, --help         Print this usage information.
-b, --base         Base documentation file
                   (defaults to "origin/main:documentation.g..dart")
-n, --new          New documentation file
                   Hint: For 'base' and 'new', you can use:
                   - local file paths (e.g. './documentation.g.dart'),
                   - remote URLs (e.g. 'https://example.com/documentation.dart'),
                   - or even Git references (e.g. 'HEAD:./documentation.g.dart').
                   (defaults to "documentation.g.dart")
-m, --magnitude    Show only changes up to the specified magnitude
                   [major, minor, patch (default), none]
```

### Version

```bash
Calculate and output the next version based on API changes

Usage: mtrust_api_guard version [arguments]
-h, --help         Print this usage information.
-b, --base         Base documentation file
                   (defaults to previous version from git history)
-n, --new          New documentation file
                   (defaults to "documentation.g.dart")
-p, --pre-release  Add pre-release suffix (-dev.N)
                   (defaults to false)
```

The version command will:

1. Compare the API changes between the base and new documentation files
2. Determine the highest magnitude of changes (major, minor, or patch)
3. Get the current version from pubspec.yaml
4. Calculate the next version based on the magnitude
5. If --pre-release is set, add -dev.N suffix where N is incremented if the version already exists
6. Output the new version number

## Use in CI/CD

For convenience, you can use the [action](action.yaml) of this repository, that generates the API
documentation and compares it with the reference base file.

Just add the following step to your workflow:

```yaml
- name: Run M-Trust API Guard for dev branch
  uses: emdgroup/mtrust-api-guard # Or pin to a commit/tag
  with:
    src_path: "./lib"
    base_doc: "origin/dev:./lib/documentation.dart"
    new_doc: "./lib/documentation.dart"
    # e.g. use the version from the semver action to be validated
    new_version: "${{ steps.get_new_version.outputs.result }}"
    comment_on_pr: true # will post a change log comment on the PR
    pr_comment_message: "New *DEV* version {version} 🚀\n\nDetected API changes:\n{changelog}"
    fail_on_error: false
```

## License

This project is licensed under the Apache-2.0 license. See the [LICENSE](LICENSE) file for details.
