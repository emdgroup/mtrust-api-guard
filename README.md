# 🔢  M-Trust API Guard 

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
```

## Usage in CI

* It is reccommended to version on the target branch you release from (e.g. main). 
* To facilitate branch protection we recommend setting up a GitHub App and using its token to push to main. (https://github.com/orgs/community/discussions/25305#discussioncomment-8256560)
* You can run the `compare` command in your PR workflow and comment the API changes to the Pull request to increase transparency of the effects a PR has. 



## License
This project is licensed under the Apache-2.0 license. See the [LICENSE](LICENSE) file for details.
