## 1.0.0
Released on: 12/8/2025, changelog automatically generated.


### Bug Fixes

- add annotation message to git tag command so that the --follow-tags param from the workflow succeeds ([e23fb1d](commit/e23fb1d))
- properly push version badge and tag from workflow ([ae2ffd9](commit/ae2ffd9))
- properly push version badge and tag from workflow ([452c9c2](commit/452c9c2))
- string escaping comment, honor analysis_options.yaml excludes and use mason_logger ([#1](issues/1)) ([99079e9](commit/99079e9))
- update constructor reference in API change tracking ([4028006](commit/4028006))
### Features

- add JSON serialization methods for documentation types and move library types to a new file ([e04c07c](commit/e04c07c))
- add Git ref inputs for base documentation context ([fd47bb5](commit/fd47bb5))
- add customizable PR comment message template and prepare content dynamically ([6ed85f0](commit/6ed85f0))
- initial commit of M-Trust API Guard ([ed5f21d](commit/ed5f21d))
- remove examples/ dir in order to satisfy pub.dev package requirements ([da32b65](commit/da32b65))

### API Changes

#### 💣 Breaking changes

**ApiChange** (lib/doc_comparator/api_change.dart)
- 🔄 Property type changed: `component`

**ApiChangeFormatter** (lib/doc_comparator/api_change_formatter.dart)
- ❌ Property removed: `showUpToMagnitude`

**ComponentApiChange** (lib/doc_comparator/api_change.dart)
- 🔄 Param type changed in constructor new: `component`

**ConstructorApiChange** (lib/doc_comparator/api_change.dart)
- 🔄 Param type changed in constructor new: `component`

**ConstructorParameterApiChange** (lib/doc_comparator/api_change.dart)
- 🔄 Param type changed in constructor new: `component`

**PropertyApiChange** (lib/doc_comparator/api_change.dart)
- 🔄 Param type changed in constructor new: `component`

#### ✨ Minor changes

**ApiChangeFormatter** (lib/doc_comparator/api_change_formatter.dart)
- ❌ Param removed in constructor new: `showUpToMagnitude`
- ❇️ Params added in constructor new: `markdownHeaderLevel`, `magnitudes`
- ❇️ Properties added: `magnitudes`, `markdownHeaderLevel`, `hasRelevantChanges`, `highestMagnitudeText`

**ApiGuardConfig** (lib/config/config.dart)
- ❇️ Class added: `ApiGuardConfig`

**BadgeGeneratorCommand** (lib/badges/badge_generator_command.dart)
- ❇️ Class added: `BadgeGeneratorCommand`

**Cache** (lib/doc_generator/cache.dart)
- ❇️ Class added: `Cache`

**ChangelogGenerator** (lib/changelog_generator/changelog_generator.dart)
- ❇️ Class added: `ChangelogGenerator`

**ChangelogGeneratorCommand** (lib/changelog_generator/changelog_generator_command.dart)
- ❇️ Class added: `ChangelogGeneratorCommand`

**DocComparatorCommand** (lib/doc_comparator/doc_comparator.dart)
- ❇️ Properties added: `out`, `magnitudes`

**DocComponent** (lib/doc_items.dart)
- ❇️ Param added in constructor new: `filePath`
- ❇️ Property added: `filePath`

**DocGeneratorCommand** (lib/doc_generator/doc_generator.dart)
- ❇️ Properties added: `argParser`, `out`, `ref`, `help`

**GitException** (lib/doc_generator/git_utils.dart)
- ❇️ Class added: `GitException`

**GitUtils** (lib/doc_generator/git_utils.dart)
- ❇️ Class added: `GitUtils`

**PubspecUtils** (lib/pubspec_utils.dart)
- ❇️ Class added: `PubspecUtils`

**VersionCommand** (lib/version/version_command.dart)
- ❇️ Class added: `VersionCommand`

**VersionResult** (lib/version/version.dart)
- ❇️ Class added: `VersionResult`

#### 👀 Patch changes

**ApiChange** (lib/doc_comparator/api_change.dart)
- 🔄 Param type changed in private constructor _: `component`


## 1.0.2
Released on: 12/8/2025, changelog automatically generated.


### Bug Fixes

- add annotation message to git tag command so that the --follow-tags param from the workflow succeeds ([e23fb1d](commit/e23fb1d))
- properly push version badge and tag from workflow ([ae2ffd9](commit/ae2ffd9))
- properly push version badge and tag from workflow ([452c9c2](commit/452c9c2))

## 1.0.1
Released on: 12/8/2025, changelog automatically generated.


### Bug Fixes

- properly push version badge and tag from workflow ([ae2ffd9](commit/ae2ffd9))
- properly push version badge and tag from workflow ([452c9c2](commit/452c9c2))
- string escaping comment, honor analysis_options.yaml excludes and use mason_logger ([#1](issues/1)) ([99079e9](commit/99079e9))

## 1.0.0
Released on: 11/4/2025, changelog automatically generated.


### Bug Fixes

- string escaping comment, honor analysis_options.yaml excludes and use mason_logger ([#1](issues/1)) ([99079e9](commit/99079e9))
- update constructor reference in API change tracking ([4028006](commit/4028006))
### Features

- add JSON serialization methods for documentation types and move library types to a new file ([e04c07c](commit/e04c07c))
- add Git ref inputs for base documentation context ([fd47bb5](commit/fd47bb5))
- add customizable PR comment message template and prepare content dynamically ([6ed85f0](commit/6ed85f0))
- initial commit of M-Trust API Guard ([ed5f21d](commit/ed5f21d))

### API Changes

#### 💣 Breaking changes

**ApiChange** (lib/doc_comparator/api_change.dart)
- 🔄 Property type changed: `component`

**ApiChangeFormatter** (lib/doc_comparator/api_change_formatter.dart)
- ❌ Property removed: `showUpToMagnitude`

**ComponentApiChange** (lib/doc_comparator/api_change.dart)
- 🔄 Param type changed in constructor new: `component`

**ConstructorApiChange** (lib/doc_comparator/api_change.dart)
- 🔄 Param type changed in constructor new: `component`

**ConstructorParameterApiChange** (lib/doc_comparator/api_change.dart)
- 🔄 Param type changed in constructor new: `component`

**PropertyApiChange** (lib/doc_comparator/api_change.dart)
- 🔄 Param type changed in constructor new: `component`

#### ✨ Minor changes

**ApiChangeFormatter** (lib/doc_comparator/api_change_formatter.dart)
- ❌ Param removed in constructor new: `showUpToMagnitude`
- ❇️ Params added in constructor new: `markdownHeaderLevel`, `magnitudes`
- ❇️ Properties added: `magnitudes`, `markdownHeaderLevel`, `hasRelevantChanges`, `highestMagnitudeText`

**ApiGuardConfig** (lib/config/config.dart)
- ❇️ Class added: `ApiGuardConfig`

**BadgeGeneratorCommand** (lib/badges/badge_generator_command.dart)
- ❇️ Class added: `BadgeGeneratorCommand`

**Cache** (lib/doc_generator/cache.dart)
- ❇️ Class added: `Cache`

**ChangelogGenerator** (lib/changelog_generator/changelog_generator.dart)
- ❇️ Class added: `ChangelogGenerator`

**ChangelogGeneratorCommand** (lib/changelog_generator/changelog_generator_command.dart)
- ❇️ Class added: `ChangelogGeneratorCommand`

**DocComparatorCommand** (lib/doc_comparator/doc_comparator.dart)
- ❇️ Properties added: `out`, `magnitudes`

**DocComponent** (lib/doc_items.dart)
- ❇️ Param added in constructor new: `filePath`
- ❇️ Property added: `filePath`

**DocGeneratorCommand** (lib/doc_generator/doc_generator.dart)
- ❇️ Properties added: `argParser`, `out`, `ref`, `help`

**GitException** (lib/doc_generator/git_utils.dart)
- ❇️ Class added: `GitException`

**GitUtils** (lib/doc_generator/git_utils.dart)
- ❇️ Class added: `GitUtils`

**PubspecUtils** (lib/pubspec_utils.dart)
- ❇️ Class added: `PubspecUtils`

**VersionCommand** (lib/version/version_command.dart)
- ❇️ Class added: `VersionCommand`

**VersionResult** (lib/version/version.dart)
- ❇️ Class added: `VersionResult`

#### 👀 Patch changes

**ApiChange** (lib/doc_comparator/api_change.dart)
- 🔄 Param type changed in private constructor _: `component`


## 0.0.1

* First release