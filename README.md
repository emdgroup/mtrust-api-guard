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
  docFile: # defaults to api_guard/generated_api.json
```

### Generate

```bash
Generate API documentation from Dart files

Usage: mtrust_api_guard generate [arguments]
-h, --help      Print this usage information.
-p, --path      Path(s) to scan for Dart files
                (defaults to "lib/src")
-o, --output    Output file path
                (defaults to "api_guard/generated_api.json")
--ref           Git reference (commit hash, branch, or tag) to generate documentation for.
                If not provided, uses current HEAD.
--cache         Cache the generated documentation for the specified ref
                (defaults to true)
```

**Important**: When using the `--ref` option, the tool will:
1. Check for uncommitted changes and error if any exist (to prevent data loss)
2. Checkout the specified git reference
3. Generate API documentation
4. Cache the result for future use
5. Restore the original git state

### Compare

```bash
Compare two API documentation files

Usage: mtrust_api_guard compare [arguments]
-h, --help         Print this usage information.
-b, --base         Base documentation file
                   (defaults to previous version from git history)
-n, --new          New documentation file
                   Hint: For 'base' and 'new', you can use:
                   - local file paths (e.g. './api_guard/generated_api.json'),
                   - remote URLs (e.g. 'https://example.com/documentation.dart'),
                   - Git references (e.g. 'main', 'v1.0.0', 'abc1234'),
                   - or even Git references with paths (e.g. 'HEAD:./api_guard/generated_api.json').
                   (defaults to "api_guard/generated_api.json")
-m, --magnitude    Show only changes up to the specified magnitude
                   [major, minor, patch (default), none]
--auto-generate    Automatically generate missing API documentation for git refs
                   (defaults to true)
```

**New Feature**: The compare command now supports git references directly! When you specify a git ref (like `main`, `v1.0.0`, or a commit hash), the tool will:

1. First check the cache for existing API documentation
2. If not found and `--auto-generate` is enabled, automatically generate and cache the documentation
3. Use the cached/generated documentation for comparison

This eliminates the need to check in `api.json` files and prevents merge conflicts.

### Version

```bash
Calculate and output the next version based on API changes

Usage: mtrust_api_guard version [arguments]
-h, --help         Print this usage information.
-b, --base         Base documentation file
                   (defaults to previous version from git history)
-n, --new          New documentation file
                   (defaults to "api_guard/generated_api.json")
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

## Caching

The tool now uses a local cache to store generated API documentation for different git references. This cache is located at `~/.mtrust_api_guard/cache/` and is organized by repository name and git reference.

**Benefits of caching:**
- Faster comparisons between known references
- No need to check in generated API files
- Prevents merge conflicts
- Automatic generation of missing documentation

**Cache management:**
- Cache is automatically populated when using `generate --ref`
- Cache is automatically used when comparing git references
- Cache can be manually cleared by deleting the cache directory

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
