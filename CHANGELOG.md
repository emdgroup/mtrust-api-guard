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

**`meta` dependency `recase`** ([pubspec.yaml](https://github.com/emdgroup/mtrust-api-guard/compare/v5.1.0..v6.0.0#diff-8b7e9df87668ffa6a04b32e1769a33434999e54ae081c52e5d943c541d4c0d25))
- 📦 Dependency added: with version `^4.1.0`


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

**`enum` ApiChangeTarget** ([lib/doc_comparator/api_change_formatter.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-815909143c779039396d475a38df7855c72b6e9b4fafffeed5dcf7f0bf313b00))
- ❌ Enum removed: `ApiChangeTarget`

**`class` DocComponent** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❌ Param removed in default constructor: `isNullSafe` (named, required)
- ❌ Constructor removed: `metadata`
- ❌ Properties removed: `isNullSafe`, `superClass`

**`enum` DocComponentType** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❌ Properties removed: `dependencyType`, `platformConstraintType`

#### ✨ Minor changes

**`class` ApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Method added: `overrideMagnitude`

**`extension` ApiChangeFormattingHelpers** ([lib/doc_comparator/api_change_formatter.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-815909143c779039396d475a38df7855c72b6e9b4fafffeed5dcf7f0bf313b00))
- ❇️ Extension added: `ApiChangeFormattingHelpers`

**`enum` ApiChangeMagnitude** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Property added: `ignore`

**`enum` ApiChangeOperation** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Properties added: `addition`, `removal`, `renaming`, `typeChange`, `typeParametersChange`, `becomingPrivate`, `becomingPublic`, `becomingOptional`, `becomingRequired`, `becomingNullable`, `becomingNonNullable`, `becomingNamed`, `becomingPositional`, `reordering`, `annotationAddition`, `annotationRemoval`, `superClassChange`, `interfaceImplementation`, `interfaceRemoval`, `mixinApplication`, `mixinRemoval`, `dependencyVersionChange`, `dependencyAddition`, `dependencyRemoval`, `platformConstraintChange`, `featureAddition`, `featureRemoval`, `defaultMagnitude`

**`class` ApiGuardConfig** ([lib/config/config.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-5bead1ff1803e084ead45182f2afeb584cbd1abf4ad02df44870848c9b6ae360))
- ❇️ Param added in default constructor: `magnitudeOverrides` (named, optional, default: const [])
- ❇️ Property added: `magnitudeOverrides`
- ❇️ Param added in method `copyWith`: `magnitudeOverrides` (named, optional)
- ❇️ Method added: `load`

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

**`class` MagnitudeOverride** ([lib/config/magnitude_override.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-d6970f79c8574689443872ccb954dbc839bd4bae899cf88ef5588bfdb9262e24))
- ❇️ Class added: `MagnitudeOverride`

**`class` MetaApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Class added: `MetaApiChange`

**`class` MethodApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Methods added: `overrideMagnitude`, `isFunctionChange`

**`class` MethodParameterApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Method added: `overrideMagnitude`

**`class` OverrideSelection** ([lib/config/magnitude_override.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-d6970f79c8574689443872ccb954dbc839bd4bae899cf88ef5588bfdb9262e24))
- ❇️ Class added: `OverrideSelection`

**`class` ParameterApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Method added: `overrideMagnitude`

**`class` PropertyApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Method added: `overrideMagnitude`

**`function` applyMagnitudeOverrides** ([lib/doc_comparator/apply_overrides.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-baffdbfb7ed3c531b882144a33b807bb8d6bb0bc5facab076d2a7922e7a65581))
- ❇️ Function added: `applyMagnitudeOverrides`

#### 👀 Patch changes

**`class` ApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Property added: `_overriddenMagnitude`

**`class` ApiChangeFormatter** ([lib/doc_comparator/api_change_formatter.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-815909143c779039396d475a38df7855c72b6e9b4fafffeed5dcf7f0bf313b00))
- ❌ Methods removed: `_getOperationDescription`, `_formatTypeChange`, `_getComponentTypeLabel`

**`class` ComponentApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Properties added: `_overriddenMagnitude`, `_allowedOperations`

**`class` ConstructorApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Properties added: `_overriddenMagnitude`, `_disallowedConstructorOperations`

**`class` ConstructorParameterApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Property added: `_overriddenMagnitude`

**`class` DocVisitor** ([lib/doc_generator/doc_visitor.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-c5d6dadddbd05895698f77e15f545cf92cae135301f04c0f3c8344a387754c8a))
- ❇️ Method added: `_getSuperClasses`

**`class` MethodApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Properties added: `_overriddenMagnitude`, `_allowedOperations`

**`class` MethodParameterApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Property added: `_overriddenMagnitude`

**`class` ParameterApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Properties added: `_overriddenMagnitude`, `_allowedParameterOperations`

**`class` PropertyApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Properties added: `_overriddenMagnitude`, `_allowedOperations`

**`class` _SelectionContext** ([lib/doc_comparator/apply_overrides.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-baffdbfb7ed3c531b882144a33b807bb8d6bb0bc5facab076d2a7922e7a65581))
- ❇️ Class added: `_SelectionContext`

**`function` _createContext** ([lib/doc_comparator/apply_overrides.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-baffdbfb7ed3c531b882144a33b807bb8d6bb0bc5facab076d2a7922e7a65581))
- ❇️ Function added: `_createContext`

**`function` _getComponentKind** ([lib/doc_comparator/apply_overrides.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-baffdbfb7ed3c531b882144a33b807bb8d6bb0bc5facab076d2a7922e7a65581))
- ❇️ Function added: `_getComponentKind`

**`function` _matches** ([lib/doc_comparator/apply_overrides.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-baffdbfb7ed3c531b882144a33b807bb8d6bb0bc5facab076d2a7922e7a65581))
- ❇️ Function added: `_matches`

**`function` _matchesSelection** ([lib/doc_comparator/apply_overrides.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v4.0.0..v5.0.0#diff-baffdbfb7ed3c531b882144a33b807bb8d6bb0bc5facab076d2a7922e7a65581))
- ❇️ Function added: `_matchesSelection`


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

**`function` generateDocs** ([lib/doc_generator/doc_generator.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-afdfca1610f1cf1d0207c15fd5db188b343b0587b9fd463620c69fd0d33f6a08))
- 🔄 Function type changed: `generateDocs` (`Future<List<DocComponent>>` → `Future<PackageApi>`)

**`function` getRef** ([lib/doc_comparator/get_ref.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-ffc5bf859c0b96b9f37fb39ac0ad356f36068bc654155cf1c2cb95cb3b12af09))
- 🔄 Function type changed: `getRef` (`Future<List<DocComponent>>` → `Future<PackageApi>`)

**`function` parseDocComponentsFile** ([lib/doc_comparator/parse_doc_file.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-4fd6e8a5d203a523d9c059d876fd9910e088b7c3036cb74134fd735f228f030c))
- ❌ Function removed: `parseDocComponentsFile`

#### ✨ Minor changes

**`class` AndroidPlatformConstraints** ([lib/models/package_info.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-19e49251f73769c21a87c929cfbcd048e47853b79856e4274892b13df23b4334))
- ❇️ Class added: `AndroidPlatformConstraints`

**`enum` ApiChangeOperation** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Properties added: `reordered`, `dependencyAdded`, `dependencyRemoved`, `dependencyChanged`, `platformConstraintChanged`, `typeParametersChanged`, `featureAdded`, `featureRemoved`

**`enum` ApiChangeTarget** ([lib/doc_comparator/api_change_formatter.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-815909143c779039396d475a38df7855c72b6e9b4fafffeed5dcf7f0bf313b00))
- ❇️ Enum added: `ApiChangeTarget`

**`class` ConstructorApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Param added in default constructor: `changedValue (named, optional)`

**`class` ConstructorParameterApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Param added in default constructor: `newType (named, optional)`
- ❇️ Property added: `newType`

**`class` DocComponent** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Param added in default constructor: `typeParameters (named, optional, default: const [])`
- ❇️ Constructor added: `metadata`
- ❇️ Properties added: `typeParameters`, `genericName`

**`enum` DocComponentType** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Properties added: `dependencyType`, `platformConstraintType`

**`class` DocMethod** ([lib/models/doc_items.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-e861dc0986be85ff54e02c2da71f4efaaf4282de2bc415167fb3bdee08f74f6c))
- ❇️ Param added in default constructor: `typeParameters (named, optional, default: const [])`
- ❇️ Property added: `typeParameters`

**`class` DocType** ([lib/models/doc_type.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-552b78d831afb63b4e6dc56eee4088761698a93347afbedcf491d43e5d550fce))
- ❇️ Class added: `DocType`

**`class` IOSPlatformConstraints** ([lib/models/package_info.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-19e49251f73769c21a87c929cfbcd048e47853b79856e4274892b13df23b4334))
- ❇️ Class added: `IOSPlatformConstraints`

**`extension` MetadataComparator** ([lib/doc_comparator/comparators/metadata_comparator.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-3d6bbcd1d1a259645179a8e3dc9be610d469c9f0232337109dfaad495423e425))
- ❇️ Extension added: `MetadataComparator`

**`class` MethodApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Param added in default constructor: `changedValue (named, optional)`

**`class` MethodParameterApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Param added in default constructor: `newType (named, optional)`
- ❇️ Property added: `newType`

**`class` PackageApi** ([lib/models/package_info.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-19e49251f73769c21a87c929cfbcd048e47853b79856e4274892b13df23b4334))
- ❇️ Class added: `PackageApi`

**`class` PackageDependency** ([lib/models/package_info.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-19e49251f73769c21a87c929cfbcd048e47853b79856e4274892b13df23b4334))
- ❇️ Class added: `PackageDependency`

**`class` PackageMetadata** ([lib/models/package_info.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-19e49251f73769c21a87c929cfbcd048e47853b79856e4274892b13df23b4334))
- ❇️ Class added: `PackageMetadata`

**`class` ParameterApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Param added in default constructor: `newType (named, optional)`
- ❇️ Property added: `newType`

**`class` PropertyApiChange** ([lib/doc_comparator/api_change.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-78145d8eef8e04a4fa58ee7fbd1fd879acfee7e8e4530553d5bd6c57800bef09))
- ❇️ Param added in default constructor: `changedValue (named, optional)`

**`class` PubspecAnalyzer** ([lib/doc_generator/pubspec_analyzer.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-073160eaf09e5ea3e868ba0a472fce2518be9f4c885b08b0d0d72e39cf6ce9c2))
- ❇️ Class added: `PubspecAnalyzer`

**`function` compareAnnotations** ([lib/doc_comparator/comparators/comparator_helpers.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-44c3872188cef010a5d519bb6036015cb4b287dfa990f703cbcc5f7a2d67e511))
- ❇️ Function added: `compareAnnotations`

**`function` compareFeatures** ([lib/doc_comparator/comparators/comparator_helpers.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-44c3872188cef010a5d519bb6036015cb4b287dfa990f703cbcc5f7a2d67e511))
- ❇️ Function added: `compareFeatures`

**`function` compareLists<T>** ([lib/doc_comparator/comparators/comparator_helpers.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-44c3872188cef010a5d519bb6036015cb4b287dfa990f703cbcc5f7a2d67e511))
- ❇️ Function added: `compareLists`

**`function` parsePackageApiFile** ([lib/doc_comparator/parse_doc_file.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-4fd6e8a5d203a523d9c059d876fd9910e088b7c3036cb74134fd735f228f030c))
- ❇️ Function added: `parsePackageApiFile`

#### 👀 Patch changes

**`class` ApiChangeFormatter** ([lib/doc_comparator/api_change_formatter.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-815909143c779039396d475a38df7855c72b6e9b4fafffeed5dcf7f0bf313b00))
- 🔄 Method type changed: `_groupByChangeCategory` (`Map<int, List<ApiChange>>` → `Map<String, List<ApiChange>>`)
- ❌ Method removed: `_getOperationText`
- ❇️ Methods added: `_getOperationDescription`, `_formatTypeChange`

**`class` DocVisitor** ([lib/doc_generator/doc_visitor.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-c5d6dadddbd05895698f77e15f545cf92cae135301f04c0f3c8344a387754c8a))
- ❇️ Methods added: `_getTypeParameters`, `_getDocType`

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

**`function` _compareParameters** ([lib/doc_comparator/comparators/member_comparator.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v3.0.0..v4.0.0#diff-4772c3af431b3a73e98ddca164add4c5c83ca88afe4433ada26a477be5e0185e))
- ❇️ Function added: `_compareParameters`


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