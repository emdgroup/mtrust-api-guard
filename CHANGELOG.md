## 3.0.0
Released on: 1/7/2026, changelog automatically generated.


### Features

- add configurable tag prefix for version command ([#14](issues/14)) ([fa6fbdc](commit/fa6fbdc))

### API Changes

#### 💣 Breaking changes

**`function` calculateNextVersion** ([lib/version/calculate_next_version.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.1.0..v3.0.0#diff-45f37bc5cce6056e350a9f5f18aa3836326c7cf4e3001bf8b20127dc1d3c08af))
- ❇️ Param added in function `calculateNextVersion`: `tagPrefix (positional, required)`

**`function` version** ([lib/version/version.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.1.0..v3.0.0#diff-e531c933c8041cbda8d007f2711de3db1d4379a016724f9ef35c18bb06cb50f3))
- ❇️ Param added in function `version`: `tagPrefix (named, required)`

#### ✨ Minor changes

**`class` GitUtils** ([lib/doc_generator/git_utils.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.1.0..v3.0.0#diff-ac66fa073c89f0f601e8861f270d5d5a6bd3ce8c2fcbbfc804c554c5023653a0))
- ❇️ Param added in method `getVersions`: `tagPrefix (named, optional, default: 'v')`
- ❇️ Param added in method `getPreviousRef`: `tagPrefix (named, optional, default: 'v')`

**`class` VersionCommand** ([lib/version/version_command.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.1.0..v3.0.0#diff-1bd91b8c544635bcfb05c7b6fdf3b0661744e925b67a60b606bf8f89f56386fa))
- ❇️ Property added: `tagPrefix`


## 2.1.0
Released on: 12/17/2025, changelog automatically generated.


### Bug Fixes

- disable commit flag in PR workflow ([f4676e8](commit/f4676e8))
- correctly extract commits in changelog generation ([c15f23e](commit/c15f23e))
### Features

- support enums, extensions, mixins, typedefs, superclasses and annotations ([e2f7226](commit/e2f7226))
- enhance changelog generation with compare URLs ([b317b55](commit/b317b55))
- enhance API change detection with new operations for superclass, interfaces, and mixins ([e151ce9](commit/e151ce9))
- add base URL option for changelog and API change formatting ([7c38812](commit/7c38812))
- add support for annotation addition and removal in API changes ([50f71a3](commit/50f71a3))
- add support for mixins, extensions, typedefs and enums ([45c9e96](commit/45c9e96))

### API Changes

#### ✨ Minor changes

**`class` ApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Properties added: `annotation`, `changedValue`

**`class` ApiChangeFormatter** ([lib/doc_comparator/api_change_formatter.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-815909143c779039396d475a38df7855c72b6e9b4fafffeed5dcf7f0bf313b00))
- ❇️ Param added in default constructor: `fileUrlBuilder (named, optional)`
- ❇️ Property added: `fileUrlBuilder`

**`enum` ApiChangeOperation** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Properties added: `annotationAdded`, `annotationRemoved`, `superClassChanged`, `interfaceAdded`, `interfaceRemoved`, `mixinAdded`, `mixinRemoved`

**`class` ChangelogGenerator** ([lib/changelog_generator/changelog_generator.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-6af055ad1d50e44f94702f973834800bbcb02bee408a9a473ef3c9d36c8ea315))
- ❇️ Params added in default constructor: `baseRef (named, optional)`, `newRef (named, optional)`
- ❇️ Properties added: `baseRef`, `newRef`

**`class` ComponentApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Params added in default constructor: `annotation (named, optional)`, `changedValue (named, optional)`
- ❇️ Properties added: `annotation`, `changedValue`

**`class` ConstructorApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Param added in default constructor: `annotation (named, optional)`
- ❇️ Properties added: `annotation`, `changedValue`

**`class` ConstructorParameterApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Param added in default constructor: `annotation (named, optional)`
- ❇️ Properties added: `annotation`, `changedValue`

**`class` DocComparatorCommand** ([lib/doc_comparator/doc_comparator_command.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-999dbfd12b9cb9e8e119208558e2d6511ab63060f6f0bcb5abc8a8d7e96b6a42))
- ❇️ Property added: `baseUrl`

**`class` DocComponent** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Params added in default constructor: `aliasedType (named, optional)`, `annotations (named, optional, default: const [])`, `superClass (named, optional)`, `interfaces (named, optional, default: const [])`, `mixins (named, optional, default: const [])`
- ❇️ Properties added: `aliasedType`, `annotations`, `superClass`, `interfaces`, `mixins`

**`enum` DocComponentType** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Properties added: `mixinType`, `enumType`, `typedefType`, `extensionType`

**`class` DocConstructor** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Param added in default constructor: `annotations (named, optional, default: const [])`
- ❇️ Property added: `annotations`

**`class` DocMethod** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Param added in default constructor: `annotations (named, optional, default: const [])`
- ❇️ Property added: `annotations`

**`class` DocParameter** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Param added in default constructor: `annotations (named, optional, default: const [])`
- ❇️ Property added: `annotations`

**`class` DocProperty** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Param added in default constructor: `annotations (named, optional, default: const [])`
- ❇️ Property added: `annotations`

**`class` DocVisitor** ([lib/doc_generator/doc_visitor.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-c5d6dadddbd05895698f77e15f545cf92cae135301f04c0f3c8344a387754c8a))
- ❇️ Class added: `DocVisitor`

**`class` GitUtils** ([lib/doc_generator/git_utils.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-ac66fa073c89f0f601e8861f270d5d5a6bd3ce8c2fcbbfc804c554c5023653a0))
- ❇️ Methods added: `getCurrentCommitHash`, `getRemoteUrl`, `buildCompareUrl`, `getCommits`, `getCommitsSinceLastTag`

**`class` MethodApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Param added in default constructor: `annotation (named, optional)`
- ❇️ Properties added: `annotation`, `changedValue`

**`class` MethodParameterApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Param added in default constructor: `annotation (named, optional)`
- ❇️ Properties added: `annotation`, `changedValue`

**`class` ParameterApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Param added in default constructor: `annotation (named, optional)`
- ❇️ Properties added: `annotation`, `changedValue`

**`class` PropertyApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Param added in default constructor: `annotation (named, optional)`
- ❇️ Properties added: `annotation`, `changedValue`

#### 👀 Patch changes

**`class` ApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Params added in private constructor `_`: `annotation (named, optional)`, `changedValue (named, optional)`

**`class` ApiChangeFormatter** ([lib/doc_comparator/api_change_formatter.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-815909143c779039396d475a38df7855c72b6e9b4fafffeed5dcf7f0bf313b00))
- ❇️ Method added: `_getComponentTypeLabel`

**`class` ChangelogGenerator** ([lib/changelog_generator/changelog_generator.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-6af055ad1d50e44f94702f973834800bbcb02bee408a9a473ef3c9d36c8ea315))
- ❌ Methods removed: `_parseCommitLog`, `_getPackageVersion`
- ❇️ Method added: `_getPubspecInfo`


## 2.0.0
Released on: 12/11/2025, changelog automatically generated.


### Bug Fixes

- **git:** stage new files before committing version bump ([451dcb1](commit/451dcb1))
### Features

- enhance API change detection to include top-level functions ([bd902f3](commit/bd902f3))
- enhance API change detection with method parameter comparison logic ([2fa9470](commit/2fa9470))
- add MethodApiChange class and comparison logic for method changes ([f5f7254](commit/f5f7254))
- add CacheCommand to manage/clear cache ([547327a](commit/547327a))

### API Changes

#### 💣 Breaking changes

**ConstructorParameterApiChange** (lib/doc_comparator/api_change.dart)
- ❌ Property removed: `parameter`
- ❌ Method removed: `getMagnitude`

**DocComponent** (lib/models/doc_items.dart)
- 🔄 Param type changed in default constructor: `methods (named, required)`
- 🔄 Property type changed: `methods`

#### ✨ Minor changes

**Cache** (lib/doc_generator/cache.dart)
- ❇️ Method added: `getCacheDir`

**CacheCommand** (lib/cache/cache_command.dart)
- ❇️ Class added: `CacheCommand`

**ConstructorParameterApiChange** (lib/doc_comparator/api_change.dart)
- ❇️ Param added in default constructor: `oldName (named, optional)`

**DocComponent** (lib/models/doc_items.dart)
- ❇️ Param added in default constructor: `type (named, optional, default: DocComponentType.classType)`
- ❇️ Property added: `type`

**DocMethod** (lib/models/doc_items.dart)
- ❇️ Class added: `DocMethod`

**DocParameter** (lib/models/doc_items.dart)
- ❇️ Param added in default constructor: `defaultValue (named, optional)`
- ❇️ Property added: `defaultValue`

**MethodApiChange** (lib/doc_comparator/api_change.dart)
- ❇️ Class added: `MethodApiChange`

**MethodParameterApiChange** (lib/doc_comparator/api_change.dart)
- ❇️ Class added: `MethodParameterApiChange`

**ParameterApiChange** (lib/doc_comparator/api_change.dart)
- ❇️ Class added: `ParameterApiChange`

#### 👀 Patch changes

**_$DocMethodFromJson** (lib/models/doc_items.dart)
- ❇️ Function added: `_$DocMethodFromJson`

**_$DocMethodToJson** (lib/models/doc_items.dart)
- ❇️ Function added: `_$DocMethodToJson`


## 1.0.1
Released on: 12/8/2025, changelog automatically generated.


### Bug Fixes

- add annotation message to git tag command so that the --follow-tags param from the workflow succeeds ([e23fb1d](commit/e23fb1d))
- properly push version badge and tag from workflow ([ae2ffd9](commit/ae2ffd9))
- properly push version badge and tag from workflow ([452c9c2](commit/452c9c2))
- string escaping comment, honor analysis_options.yaml excludes and use mason_logger ([#1](issues/1)) ([99079e9](commit/99079e9))
- **git:** stage new files before committing version bump ([451dcb1](commit/451dcb1))
- remove examples/ dir in order to satisfy pub.dev package requirements ([da32b65](commit/da32b65))

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