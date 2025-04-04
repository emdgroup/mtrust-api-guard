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

Run "mtrust_api_guard help <command>" for more information about a command.
```

### Generate

```bash
Generate API documentation from Dart files

Usage: mtrust_api_guard generate [arguments]
-h, --help      Print this usage information.
-p, --path      Path(s) to scan for Dart files
                (defaults to "lib/src")
-o, --output    Output file path
                (defaults to "lib/documentation.g.dart")
```

### Compare

```bash
Compare two API documentation files

Usage: mtrust_api_guard compare [arguments]
-h, --help         Print this usage information.
-b, --base         Base documentation file
                   (defaults to "HEAD:./lib/documentation.dart")
-n, --new          New documentation file
                   Hint: For 'base' and 'new', you can use:
                   - local file paths (e.g. 'lib/documentation.dart'),
                   - remote URLs (e.g. 'https://example.com/documentation.dart'),
                   - or even Git references (e.g. 'HEAD:lib/documentation.dart').
                   (defaults to "origin/main:./lib/documentation.dart")
-m, --magnitude    Show only changes up to the specified magnitude
                   [major, minor, patch (default), none]
```

## Workflow

For convenience, you can use the following workflow, that generates the API documentation
and compares it with the reference base file:

```bash
  validate_api_docs_and_version:
    uses: emdgroup/mtrust-api-guard/.github/workflows/api_doc_validator.yml@main
    with:
      src_path: "./lib/src"
      base_doc: "origin/main:./lib/documentation.dart"
      new_doc: "./lib/documentation.dart"
      new_version: {{ steps.version.outputs.version }} # use the version from the semver action
```

## License

This project is licensed under the Apache-2.0 license. See the [LICENSE](LICENSE) file for details.
