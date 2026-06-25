## 8.1.0
Released on: 6/25/2026, changelog automatically generated.


### Features

- **changelog:** parallelize regenerate and tolerate empty first commit ([010e09e](commit/010e09e))

### API Changes

#### ✨ Minor changes

**`class` ChangelogGenerator** ([lib/changelog_generator/changelog_generator.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v8.0.0..v8.1.0#diff-6af055ad1d50e44f94702f973834800bbcb02bee408a9a473ef3c9d36c8ea315))
- ❇️ Param added in method `regenerateFullChangelog`: `concurrency` (named, optional, default: 4)
- ❇️ Param added in method `regenerateChangelogFile`: `concurrency` (named, optional, default: 4)

#### 👀 Patch changes

**`class` ChangelogGenerator** ([lib/changelog_generator/changelog_generator.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v8.0.0..v8.1.0#diff-6af055ad1d50e44f94702f973834800bbcb02bee408a9a473ef3c9d36c8ea315))
- ❇️ Methods added: `_analyzeRefsInParallel`, `_tryAnalyzeRef`


## 8.0.0
Released on: 6/24/2026, changelog automatically generated.


### Bug Fixes

- **changelog:** remove unnecessary string interpolation braces ([fbac8e4](commit/fbac8e4))
### Features

- **changelog:** add --regenerate to rebuild CHANGELOG from tags ([4bab144](commit/4bab144))

### API Changes

#### 💣 Breaking changes

**`class` ChangelogGenerator** ([lib/changelog_generator/changelog_generator.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v7.0.1..v8.0.0#diff-6af055ad1d50e44f94702f973834800bbcb02bee408a9a473ef3c9d36c8ea315))
- ❇️ Modifier `static` added to property: `releasableCommitTypes`

#### ✨ Minor changes

**`class` ChangelogGenerator** ([lib/changelog_generator/changelog_generator.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v7.0.1..v8.0.0#diff-6af055ad1d50e44f94702f973834800bbcb02bee408a9a473ef3c9d36c8ea315))
- ❌ Modifier `final` removed from property: `releasableCommitTypes`
- ❇️ Modifier `const` added to property: `releasableCommitTypes`
- ❇️ Methods added: `regenerateFullChangelog`, `regenerateChangelogFile`

#### 👀 Patch changes

**`class` ChangelogGenerator** ([lib/changelog_generator/changelog_generator.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v7.0.1..v8.0.0#diff-6af055ad1d50e44f94702f973834800bbcb02bee408a9a473ef3c9d36c8ea315))
- ❇️ Method added: `_generateReleaseEntry`


## 7.0.1
Released on: 6/24/2026, changelog automatically generated.


### Bug Fixes

- **changelog:** group pubspec changes and fix dependency text ([10e59e0](commit/10e59e0))

## 7.0.0
Released on: 6/24/2026, changelog automatically generated.


### Bug Fixes

- **ci:** revert flutter_lints to ^1.0.0 ([e5cb918](commit/e5cb918))
- **doc_visitor:** use privateName for field formal params ([2037f0e](commit/2037f0e))
- **test:** bootstrap compiled binary and shared flutter scaffolds ([e6af2bf](commit/e6af2bf))

### API Changes

#### 💣 Breaking changes

**`meta` pubspec.yaml** ([pubspec.yaml](https://github.com/emdgroup/mtrust-api-guard/compare/v6.0.7..v7.0.0#diff-8b7e9df87668ffa6a04b32e1769a33434999e54ae081c52e5d943c541d4c0d25))
- 🎯 Minimum Dart SDK version increased: from `>=3.0.0 <4.0.0` to `>=3.11.0 <4.0.0`

#### 👀 Patch changes

**`meta` pubspec.yaml** ([pubspec.yaml](https://github.com/emdgroup/mtrust-api-guard/compare/v6.0.7..v7.0.0#diff-8b7e9df87668ffa6a04b32e1769a33434999e54ae081c52e5d943c541d4c0d25))
- 📦 `analyzer` version changed: from `^7.4.5` to `^13.3.0`
- 📦 Removed `build`
- 📦 Removed `code_builder`
- 📦 Removed `build_config`
- 📦 Removed `dart_style`
- 📦 `json_annotation` version changed: from `^4.9.0` to `^4.12.0`


## 6.0.7
Released on: 6/23/2026, changelog automatically generated.


### Bug Fixes

- **version:** increment pre-release suffix on same stable base ([1af74b7](commit/1af74b7))

## 6.0.6
Released on: 3/25/2026, changelog automatically generated.


### Bug Fixes

- stop recursing into re-exports of external packages ([0043941](commit/0043941))
- absolutize mainLibrary path for consistent relative computation ([477d7d1](commit/477d7d1))
- update stale comment and normalize sourcePath in host detection ([029a45e](commit/029a45e))
- normalize paths and stop following dart:/external file: re-exports ([a75aecb](commit/a75aecb))
- stop recursing into re-exports of external packages ([55d3b74](commit/55d3b74))

## 6.0.5
Released on: 3/25/2026, changelog automatically generated.


### Bug Fixes

- **overrides:** match from_package selection against component's own package ([e69885d](commit/e69885d))
- match from_package selection against component's own package ([1af5c40](commit/1af5c40))

## 6.0.4
Released on: 3/16/2026, changelog automatically generated.


### Bug Fixes

- implement empty release commit tagging to trigger workflows ([a034d19](commit/a034d19))

## 6.0.3
Released on: 3/16/2026, changelog automatically generated.

## 6.0.2
Released on: 3/16/2026, changelog automatically generated.

## 6.0.1
Released on: 2/23/2026, changelog automatically generated.


### Features

- parameterize pre-release prefix ([0a237bc](commit/0a237bc))
- add pre-release prefix option for versioning ([ce427f4](commit/ce427f4))

## 6.0.0
Released on: 2/20/2026, changelog automatically generated.


### Features

- Use git worktrees to generate analysis ([#15](issues/15)) ([0a14157](commit/0a14157))

### API Changes

#### 💣 Breaking changes

**`enum` ApiChangeOperation** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v5.1.0..v6.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❌ Property removed: `platformConstraintChange`

#### ✨ Minor changes

**`enum` ApiChangeOperation** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v5.1.0..v6.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Properties added: `minDartSdkVersionDecrease`, `minDartSdkVersionIncrease`, `maxDartSdkVersionDecrease`, `maxDartSdkVersionIncrease`, `minFlutterSdkVersionIncrease`, `maxFlutterSdkVersionDecrease`, `maxFlutterSdkVersionIncrease`, `minFlutterSdkVersionDecrease`, `minAndroidSdkVersionDecrease`, `minAndroidSdkVersionIncrease`, `minIosSdkVersionDecrease`, `minIosSdkVersionIncrease`

**`class` ComponentApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v5.1.0..v6.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Method added: `toString`

**`class` ConstructorApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v5.1.0..v6.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Method added: `toString`

**`class` ConstructorParameterApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v5.1.0..v6.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Method added: `toString`

**`class` MetaApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v5.1.0..v6.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Constructors added: `minDartSdkVersionDecrease`, `minDartSdkVersionIncrease`, `maxDartSdkVersionDecrease`, `maxDartSdkVersionIncrease`, `minFlutterSdkVersionDecrease`, `minFlutterSdkVersionIncrease`, `maxFlutterSdkVersionDecrease`, `maxFlutterSdkVersionIncrease`, `minAndroidSdkVersionDecrease`, `minAndroidSdkVersionIncrease`, `minIosSdkVersionDecrease`, `minIosSdkVersionIncrease`
- ❇️ Method added: `toString`

**`class` MethodApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v5.1.0..v6.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Method added: `toString`

**`class` MethodParameterApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v5.1.0..v6.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Method added: `toString`

**`class` PackageMetadata** ([lib/models/package_info.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v5.1.0..v6.0.0#diff-19e49251f73769c21a87c929cfbcd048e47853b79856e4274892b13df23b4334))
- ❇️ Param added in default constructor: `flutterVersion` (named, optional)
- ❇️ Property added: `flutterVersion`

**`class` ParameterApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v5.1.0..v6.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Method added: `toString`

**`class` PropertyApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v5.1.0..v6.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Method added: `toString`

#### 👀 Patch changes

**`meta` pubspec.yaml** ([pubspec.yaml](https://github.com/emdgroup/mtrust-api-guard/compare/v5.1.0..v6.0.0#diff-8b7e9df87668ffa6a04b32e1769a33434999e54ae081c52e5d943c541d4c0d25))
- 📦 Added `recase`: with version `^4.1.0`


## 5.1.0
Released on: 1/19/2026, changelog automatically generated.


### Features

- support entry point analysis and package selection for magnitude overrides ([2a25b12](commit/2a25b12))
- enhance API guard configuration with entry points and package selection for magnitude overrides ([fb31d32](commit/fb31d32))

### API Changes

#### ✨ Minor changes

**`class` DocComponent** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v5.0.0..v5.1.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Params added in default constructor: `entryPoint` (named, optional), `superClassPackages` (named, optional, default: const [])
- ❇️ Properties added: `entryPoint`, `superClassPackages`


## 5.0.0
Released on: 1/19/2026, changelog automatically generated.


### Bug Fixes

- update link to ApiChangeOperation documentation in README ([302d88a](commit/302d88a))
- correct entity name formatting in removal operation and update changelog parameter removal description ([e86651d](commit/e86651d))
### Features

- add support for granular magnitude overrides configuration ([1e8628a](commit/1e8628a))
- collect all super classes for components and enhance magnitude override configuration ([b3e81a8](commit/b3e81a8))
- collect all super classes for components and enhance magnitude override configuration ([6c5e162](commit/6c5e162))
- update MagnitudeOverride to support multiple operations and enhance matching logic ([f399fbb](commit/f399fbb))
- enhance magnitude override configuration with selection criteria ([d5e4d72](commit/d5e4d72))
- implement magnitude override configuration ([da4629c](commit/da4629c))

### API Changes

#### 💣 Breaking changes

**`enum` ApiChangeOperation** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Param added in default constructor: `defaultMagnitude` (positional, required)
- ❌ Properties removed: `added`, `removed`, `renamed`, `reordered`, `typeChanged`, `becameOptional`, `becameRequired`, `becameNamed`, `becamePositional`, `becameNullUnsafe`, `becameNullSafe`, `becamePrivate`, `becamePublic`, `annotationAdded`, `annotationRemoved`, `dependencyAdded`, `dependencyRemoved`, `dependencyChanged`, `platformConstraintChanged`, `superClassChanged`, `interfaceAdded`, `interfaceRemoved`, `mixinAdded`, `mixinRemoved`, `typeParametersChanged`, `featureAdded`, `featureRemoved`

**`class` DocComponent** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❌ Param removed in default constructor: `isNullSafe` (named, required)
- ❌ Constructor removed: `metadata`
- ❌ Properties removed: `isNullSafe`, `superClass`

**`enum` DocComponentType** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❌ Properties removed: `dependencyType`, `platformConstraintType`

#### ✨ Minor changes

**`class` ApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Method added: `overrideMagnitude`

**`enum` ApiChangeMagnitude** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Property added: `ignore`

**`enum` ApiChangeOperation** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Properties added: `addition`, `removal`, `renaming`, `typeChange`, `typeParametersChange`, `becomingPrivate`, `becomingPublic`, `becomingOptional`, `becomingRequired`, `becomingNullable`, `becomingNonNullable`, `becomingNamed`, `becomingPositional`, `reordering`, `annotationAddition`, `annotationRemoval`, `superClassChange`, `interfaceImplementation`, `interfaceRemoval`, `mixinApplication`, `mixinRemoval`, `dependencyVersionChange`, `dependencyAddition`, `dependencyRemoval`, `platformConstraintChange`, `featureAddition`, `featureRemoval`, `defaultMagnitude`

**`class` ComponentApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Method added: `overrideMagnitude`

**`class` ConstructorApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Method added: `overrideMagnitude`

**`class` ConstructorParameterApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Method added: `overrideMagnitude`

**`class` DocComponent** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❌ Param removed in default constructor: `superClass` (named, optional)
- ❇️ Param added in default constructor: `superClasses` (named, optional, default: const [])
- ❇️ Constructor added: `meta`
- ❇️ Property added: `superClasses`

**`enum` DocComponentType** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Property added: `metaType`

**`class` MetaApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Class added: `MetaApiChange`

**`class` MethodApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Methods added: `overrideMagnitude`, `isFunctionChange`

**`class` MethodParameterApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Method added: `overrideMagnitude`

**`class` ParameterApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Method added: `overrideMagnitude`

**`class` PropertyApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Method added: `overrideMagnitude`

#### 👀 Patch changes

**`class` ApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Property added: `_overriddenMagnitude`

**`class` ComponentApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Properties added: `_overriddenMagnitude`, `_allowedOperations`

**`class` ConstructorApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Properties added: `_overriddenMagnitude`, `_disallowedConstructorOperations`

**`class` ConstructorParameterApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Property added: `_overriddenMagnitude`

**`class` MethodApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Properties added: `_overriddenMagnitude`, `_allowedOperations`

**`class` MethodParameterApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Property added: `_overriddenMagnitude`

**`class` ParameterApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Properties added: `_overriddenMagnitude`, `_allowedParameterOperations`

**`class` PropertyApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Properties added: `_overriddenMagnitude`, `_allowedOperations`


## 4.0.0
Released on: 1/12/2026, changelog automatically generated.


### Bug Fixes

- filter out abstract methods in non-abstract classes during method collection ([a4764ae](commit/a4764ae))
### Features

- Semantic Type Analysis, Modifier Support, Pubspec Support, Comparator Refactor ([50d7a2e](commit/50d7a2e))
- add modifier change detection and enhance changelog formatting ([4db3dd8](commit/4db3dd8))
- implement semantic type comparison for accurate breaking change detection ([3da35cb](commit/3da35cb))
- enhance support for parameter reordering detection and update related tests ([528206a](commit/528206a))
- add SDK constraint comparison and update related tests ([c6f70cf](commit/c6f70cf))
- add package metadata support and pubspec.yaml analysis ([61a3ea4](commit/61a3ea4))
- add support for type parameter changes in API documentation ([317e646](commit/317e646))

### API Changes

#### 💣 Breaking changes

**`class` DocMethod** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- 🔄 Param type changed in default constructor: `returnType` (`String` → `DocType`)
- 🔄 Property type changed: `returnType`

**`class` DocParameter** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- 🔄 Param type changed in default constructor: `type` (`String` → `DocType`)
- 🔄 Property type changed: `type`

**`class` DocProperty** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- 🔄 Param type changed in default constructor: `type` (`String` → `DocType`)
- 🔄 Property type changed: `type`

**`class` MethodApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- 🔄 Param type changed in default constructor: `newType` (`String?` → `DocType?`)
- 🔄 Property type changed: `newType`

#### ✨ Minor changes

**`class` AndroidPlatformConstraints** ([lib/models/package_info.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-19e49251f73769c21a87c929cfbcd048e47853b79856e4274892b13df23b4334))
- ❇️ Class added: `AndroidPlatformConstraints`

**`enum` ApiChangeOperation** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Properties added: `reordered`, `dependencyAdded`, `dependencyRemoved`, `dependencyChanged`, `platformConstraintChanged`, `typeParametersChanged`, `featureAdded`, `featureRemoved`

**`class` ConstructorApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Param added in default constructor: `changedValue` (named, optional)

**`class` ConstructorParameterApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Param added in default constructor: `newType` (named, optional)
- ❇️ Property added: `newType`

**`class` DocComponent** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Param added in default constructor: `typeParameters` (named, optional, default: const [])
- ❇️ Constructor added: `metadata`
- ❇️ Properties added: `typeParameters`, `genericName`

**`enum` DocComponentType** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Properties added: `dependencyType`, `platformConstraintType`

**`class` DocMethod** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Param added in default constructor: `typeParameters` (named, optional, default: const [])
- ❇️ Property added: `typeParameters`

**`class` DocType** ([lib/models/doc_type.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-552b78d831afb63b4e6dc56eee4088761698a93347afbedcf491d43e5d550fce))
- ❇️ Class added: `DocType`

**`class` IOSPlatformConstraints** ([lib/models/package_info.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-19e49251f73769c21a87c929cfbcd048e47853b79856e4274892b13df23b4334))
- ❇️ Class added: `IOSPlatformConstraints`

**`class` MethodApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Param added in default constructor: `changedValue` (named, optional)

**`class` MethodParameterApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Param added in default constructor: `newType` (named, optional)
- ❇️ Property added: `newType`

**`class` PackageApi** ([lib/models/package_info.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-19e49251f73769c21a87c929cfbcd048e47853b79856e4274892b13df23b4334))
- ❇️ Class added: `PackageApi`

**`class` PackageDependency** ([lib/models/package_info.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-19e49251f73769c21a87c929cfbcd048e47853b79856e4274892b13df23b4334))
- ❇️ Class added: `PackageDependency`

**`class` PackageMetadata** ([lib/models/package_info.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-19e49251f73769c21a87c929cfbcd048e47853b79856e4274892b13df23b4334))
- ❇️ Class added: `PackageMetadata`

**`class` ParameterApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Param added in default constructor: `newType` (named, optional)
- ❇️ Property added: `newType`

**`class` PropertyApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Param added in default constructor: `changedValue` (named, optional)

#### 👀 Patch changes

**`function` _$AndroidPlatformConstraintsFromJson** ([lib/models/package_info.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-19e49251f73769c21a87c929cfbcd048e47853b79856e4274892b13df23b4334))
- ❇️ Function added: `_$AndroidPlatformConstraintsFromJson`

**`function` _$AndroidPlatformConstraintsToJson** ([lib/models/package_info.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-19e49251f73769c21a87c929cfbcd048e47853b79856e4274892b13df23b4334))
- ❇️ Function added: `_$AndroidPlatformConstraintsToJson`

**`function` _$DocTypeFromJson** ([lib/models/doc_type.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-552b78d831afb63b4e6dc56eee4088761698a93347afbedcf491d43e5d550fce))
- ❇️ Function added: `_$DocTypeFromJson`

**`function` _$DocTypeToJson** ([lib/models/doc_type.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-552b78d831afb63b4e6dc56eee4088761698a93347afbedcf491d43e5d550fce))
- ❇️ Function added: `_$DocTypeToJson`

**`function` _$IOSPlatformConstraintsFromJson** ([lib/models/package_info.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-19e49251f73769c21a87c929cfbcd048e47853b79856e4274892b13df23b4334))
- ❇️ Function added: `_$IOSPlatformConstraintsFromJson`

**`function` _$IOSPlatformConstraintsToJson** ([lib/models/package_info.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-19e49251f73769c21a87c929cfbcd048e47853b79856e4274892b13df23b4334))
- ❇️ Function added: `_$IOSPlatformConstraintsToJson`

**`function` _$PackageApiFromJson** ([lib/models/package_info.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-19e49251f73769c21a87c929cfbcd048e47853b79856e4274892b13df23b4334))
- ❇️ Function added: `_$PackageApiFromJson`

**`function` _$PackageApiToJson** ([lib/models/package_info.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-19e49251f73769c21a87c929cfbcd048e47853b79856e4274892b13df23b4334))
- ❇️ Function added: `_$PackageApiToJson`

**`function` _$PackageDependencyFromJson** ([lib/models/package_info.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-19e49251f73769c21a87c929cfbcd048e47853b79856e4274892b13df23b4334))
- ❇️ Function added: `_$PackageDependencyFromJson`

**`function` _$PackageDependencyToJson** ([lib/models/package_info.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-19e49251f73769c21a87c929cfbcd048e47853b79856e4274892b13df23b4334))
- ❇️ Function added: `_$PackageDependencyToJson`

**`function` _$PackageMetadataFromJson** ([lib/models/package_info.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-19e49251f73769c21a87c929cfbcd048e47853b79856e4274892b13df23b4334))
- ❇️ Function added: `_$PackageMetadataFromJson`

**`function` _$PackageMetadataToJson** ([lib/models/package_info.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-19e49251f73769c21a87c929cfbcd048e47853b79856e4274892b13df23b4334))
- ❇️ Function added: `_$PackageMetadataToJson`


## 3.0.0
Released on: 1/7/2026, changelog automatically generated.


### Features

- add configurable tag prefix for version command ([#14](issues/14)) ([fa6fbdc](commit/fa6fbdc))

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

**`enum` ApiChangeOperation** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Properties added: `annotationAdded`, `annotationRemoved`, `superClassChanged`, `interfaceAdded`, `interfaceRemoved`, `mixinAdded`, `mixinRemoved`

**`class` ChangelogGenerator** ([lib/changelog_generator/changelog_generator.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-6af055ad1d50e44f94702f973834800bbcb02bee408a9a473ef3c9d36c8ea315))
- ❇️ Params added in default constructor: `baseRef` (named, optional), `newRef` (named, optional)
- ❇️ Properties added: `baseRef`, `newRef`

**`class` ComponentApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Params added in default constructor: `annotation` (named, optional), `changedValue` (named, optional)
- ❇️ Properties added: `annotation`, `changedValue`

**`class` ConstructorApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Param added in default constructor: `annotation` (named, optional)
- ❇️ Properties added: `annotation`, `changedValue`

**`class` ConstructorParameterApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Param added in default constructor: `annotation` (named, optional)
- ❇️ Properties added: `annotation`, `changedValue`

**`class` DocComponent** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Params added in default constructor: `aliasedType` (named, optional), `annotations` (named, optional, default: const []), `superClass` (named, optional), `interfaces` (named, optional, default: const []), `mixins` (named, optional, default: const [])
- ❇️ Properties added: `aliasedType`, `annotations`, `superClass`, `interfaces`, `mixins`

**`enum` DocComponentType** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Properties added: `mixinType`, `enumType`, `typedefType`, `extensionType`

**`class` DocConstructor** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Param added in default constructor: `annotations` (named, optional, default: const [])
- ❇️ Property added: `annotations`

**`class` DocMethod** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Param added in default constructor: `annotations` (named, optional, default: const [])
- ❇️ Property added: `annotations`

**`class` DocParameter** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Param added in default constructor: `annotations` (named, optional, default: const [])
- ❇️ Property added: `annotations`

**`class` DocProperty** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Param added in default constructor: `annotations` (named, optional, default: const [])
- ❇️ Property added: `annotations`

**`class` MethodApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Param added in default constructor: `annotation` (named, optional)
- ❇️ Properties added: `annotation`, `changedValue`

**`class` MethodParameterApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Param added in default constructor: `annotation` (named, optional)
- ❇️ Properties added: `annotation`, `changedValue`

**`class` ParameterApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Param added in default constructor: `annotation` (named, optional)
- ❇️ Properties added: `annotation`, `changedValue`

**`class` PropertyApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Param added in default constructor: `annotation` (named, optional)
- ❇️ Properties added: `annotation`, `changedValue`

#### 👀 Patch changes

**`class` ApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Params added in private constructor `$name`: `annotation` (named, optional), `changedValue` (named, optional)

**`class` ChangelogGenerator** ([lib/changelog_generator/changelog_generator.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-6af055ad1d50e44f94702f973834800bbcb02bee408a9a473ef3c9d36c8ea315))
- ❌ Methods removed: `_parseCommitLog`, `_getPackageVersion`
- ❇️ Method added: `_getPubspecInfo`

**`meta` pubspec.yaml** ([pubspec.yaml](https://github.com/emdgroup/mtrust-api-guard/compare/v2.0.0..v2.1.0#diff-8b7e9df87668ffa6a04b32e1769a33434999e54ae081c52e5d943c541d4c0d25))
- 📦 Added `crypto`: with version `^3.0.7`


## 2.0.0
Released on: 12/11/2025, changelog automatically generated.


### Features

- enhance API change detection to include top-level functions ([bd902f3](commit/bd902f3))
- enhance API change detection with method parameter comparison logic ([2fa9470](commit/2fa9470))
- add MethodApiChange class and comparison logic for method changes ([f5f7254](commit/f5f7254))
- add CacheCommand to manage/clear cache ([547327a](commit/547327a))

### API Changes

#### 💣 Breaking changes

**`class` ConstructorParameterApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v1.0.1..v2.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- 🔄 Superclass changed: `ApiChange` → `ParameterApiChange`

**`class` DocComponent** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v1.0.1..v2.0.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- 🔄 Param type changed in default constructor: `methods` (`List<String>` → `List<DocMethod>`)
- 🔄 Property type changed: `methods`

#### ✨ Minor changes

**`enum` ApiChangeOperation** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v1.0.1..v2.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Property added: `renamed`

**`class` ConstructorParameterApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v1.0.1..v2.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Param added in default constructor: `oldName` (named, optional)
- ❇️ Properties added: `oldName`, `parentName`

**`class` DocComponent** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v1.0.1..v2.0.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Param added in default constructor: `type` (named, optional, default: DocComponentType.classType)
- ❇️ Property added: `type`

**`enum` DocComponentType** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v1.0.1..v2.0.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Enum added: `DocComponentType`

**`class` DocMethod** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v1.0.1..v2.0.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Class added: `DocMethod`

**`class` DocParameter** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v1.0.1..v2.0.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Param added in default constructor: `defaultValue` (named, optional)
- ❇️ Property added: `defaultValue`

**`class` MethodApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v1.0.1..v2.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Class added: `MethodApiChange`

**`class` MethodParameterApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v1.0.1..v2.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Class added: `MethodParameterApiChange`

**`class` ParameterApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v1.0.1..v2.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Class added: `ParameterApiChange`

#### 👀 Patch changes

**`class` ConstructorParameterApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v1.0.1..v2.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ➖ Method annotation removed: `getMagnitude` (@override)

**`function` _$DocMethodFromJson** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v1.0.1..v2.0.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Function added: `_$DocMethodFromJson`

**`function` _$DocMethodToJson** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v1.0.1..v2.0.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Function added: `_$DocMethodToJson`


## 1.0.1
Released on: 12/8/2025, changelog automatically generated.


### Bug Fixes

- **git:** stage new files before committing version bump ([451dcb1](commit/451dcb1))

## 1.0.0
Released on: 12/8/2025, changelog automatically generated.


### Bug Fixes

- add annotation message to git tag command so that the --follow-tags param from the workflow succeeds ([e23fb1d](commit/e23fb1d))
- properly push version badge and tag from workflow ([ae2ffd9](commit/ae2ffd9))
- properly push version badge and tag from workflow ([452c9c2](commit/452c9c2))
- string escaping comment, honor analysis_options.yaml excludes and use mason_logger ([#1](issues/1)) ([99079e9](commit/99079e9))
- remove examples/ dir in order to satisfy pub.dev package requirements ([da32b65](commit/da32b65))

### API Changes

#### 💣 Breaking changes

**`class` ApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.1..v1.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- 🔄 Property type changed: `component`

**`class` ComponentApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.1..v1.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- 🔄 Param type changed in default constructor: `component` (`String` → `DocComponent`)
- 🔄 Property type changed: `component`

**`class` ConstructorApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.1..v1.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- 🔄 Param type changed in default constructor: `component` (`String` → `DocComponent`)
- 🔄 Property type changed: `component`

**`class` ConstructorParameterApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.1..v1.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- 🔄 Param type changed in default constructor: `component` (`String` → `DocComponent`)
- 🔄 Property type changed: `component`

**`class` PropertyApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.1..v1.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- 🔄 Param type changed in default constructor: `component` (`String` → `DocComponent`)
- 🔄 Property type changed: `component`

**`meta` pubspec.yaml** ([pubspec.yaml](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.1..v1.0.0#diff-8b7e9df87668ffa6a04b32e1769a33434999e54ae081c52e5d943c541d4c0d25))
- 🎯 Minimum Dart SDK version increased: from `>=2.17.0 <4.0.0` to `>=3.0.0 <4.0.0`

#### ✨ Minor changes

**`class` ChangelogGenerator** ([lib/changelog_generator/changelog_generator.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.1..v1.0.0#diff-6af055ad1d50e44f94702f973834800bbcb02bee408a9a473ef3c9d36c8ea315))
- ❇️ Class added: `ChangelogGenerator`

**`class` DocComponent** ([lib/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.1..v1.0.0#diff-9061d18bef0270f99b71a5b17e42ccc91ac76070dd93f8f3b9ddbc88f8d3752a))
- ❇️ Param added in default constructor: `filePath` (named, optional)
- ❇️ Property added: `filePath`

**`function` getHighestMagnitude** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.1..v1.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Function added: `getHighestMagnitude`

#### 👀 Patch changes

**`class` ApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.1..v1.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- 🔄 Param type changed in private constructor `$name`: `component` (`String` → `DocComponent`)

**`class` DocComponent** ([lib/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.1..v1.0.0#diff-9061d18bef0270f99b71a5b17e42ccc91ac76070dd93f8f3b9ddbc88f8d3752a))
- ➕ Class annotation added: `DocComponent` (@JsonSerializable())

**`class` DocConstructor** ([lib/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.1..v1.0.0#diff-9061d18bef0270f99b71a5b17e42ccc91ac76070dd93f8f3b9ddbc88f8d3752a))
- ➕ Class annotation added: `DocConstructor` (@JsonSerializable())

**`class` DocParameter** ([lib/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.1..v1.0.0#diff-9061d18bef0270f99b71a5b17e42ccc91ac76070dd93f8f3b9ddbc88f8d3752a))
- ➕ Class annotation added: `DocParameter` (@JsonSerializable())

**`class` DocProperty** ([lib/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.1..v1.0.0#diff-9061d18bef0270f99b71a5b17e42ccc91ac76070dd93f8f3b9ddbc88f8d3752a))
- ➕ Class annotation added: `DocProperty` (@JsonSerializable())

**`function` _$DocComponentFromJson** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.1..v1.0.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Function added: `_$DocComponentFromJson`

**`function` _$DocComponentToJson** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.1..v1.0.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Function added: `_$DocComponentToJson`

**`function` _$DocConstructorFromJson** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.1..v1.0.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Function added: `_$DocConstructorFromJson`

**`function` _$DocConstructorToJson** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.1..v1.0.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Function added: `_$DocConstructorToJson`

**`function` _$DocParameterFromJson** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.1..v1.0.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Function added: `_$DocParameterFromJson`

**`function` _$DocParameterToJson** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.1..v1.0.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Function added: `_$DocParameterToJson`

**`function` _$DocPropertyFromJson** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.1..v1.0.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Function added: `_$DocPropertyFromJson`

**`function` _$DocPropertyToJson** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.1..v1.0.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Function added: `_$DocPropertyToJson`

**`meta` pubspec.yaml** ([pubspec.yaml](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.1..v1.0.0#diff-8b7e9df87668ffa6a04b32e1769a33434999e54ae081c52e5d943c541d4c0d25))
- 📦 `analyzer` version changed: from `^6.2.0` to `^7.4.5`
- 📦 `glob` version changed: from `^2.0.2` to `^2.1.3`
- 📦 Removed `source_gen`
- 📦 `dart_style` version changed: from `^2.3.4` to `^3.1.0`
- 📦 Removed `flutter_lints`
- 📦 Added `conventional`: with version `^0.4.0`
- 📦 Added `yaml`: with version `^3.1.3`
- 📦 Added `mason_logger`: with version `^0.3.3`
- 📦 Added `pub_semver`: with version `^2.2.0`
- 📦 Added `yaml_edit`: with version `^2.2.2`
- 📦 Added `json_annotation`: with version `^4.9.0`
- 📦 Added `http`: with version `^1.4.0`


## 0.0.1
Released on: 5/22/2025, changelog automatically generated.


### Bug Fixes

- update constructor reference in API change tracking ([4028006](commit/4028006))
### Features

- add JSON serialization methods for documentation types and move library types to a new file ([e04c07c](commit/e04c07c))
- add Git ref inputs for base documentation context ([fd47bb5](commit/fd47bb5))
- add customizable PR comment message template and prepare content dynamically ([6ed85f0](commit/6ed85f0))
- initial commit of M-Trust API Guard ([ed5f21d](commit/ed5f21d))

