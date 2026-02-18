## 1.0.0



### Features

- implement compatibility with v1.0.0 

### API Changes

#### 💣 Breaking changes

**`class` AbstractModifiers** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Modifier `abstract` added to method: `willBecomeAbstract`

**`class` ClassWithSuper** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- 🔄 Superclass changed: `BaseClass` → `AnotherBaseClass`
- ➖ Interface removed: InterfaceA, InterfaceB
- ➖ Mixin removed: MixinA, MixinB

**`class` GenericClass<T>** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- 🔄 Type parameters changed: `T` → `T extends num`
- ❇️ Modifier `final` added to property: `value`

**`class` InterfaceB** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❌ Class removed: `InterfaceB`

**`mixin` MagnitudeOverrideTest** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ✏️ Param renamed in method `paramWillBeRenamedAsBreaking`: `name` → `newName`

**`mixin` MixinB** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❌ Mixin removed: `MixinB`

**`class` Modifiers** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❌ Modifier `const` removed from constructor: `named`
- ❇️ Modifier `static` added to property: `willBecomeStatic`
- ❌ Modifier `static` removed from property: `willLoseStatic`
- ❇️ Modifier `final` added to property: `willBecomeFinal`
- ❌ Modifier `const` removed from property: `willLoseConst`
- ❇️ Modifier `static` added to method: `willBecomeStaticMethod`
- ❌ Modifier `static` removed from method: `willLoseStaticMethod`

**`class` Product** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❌ Class removed: `Product`

**`enum` Status** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❌ Property removed: `inactive`

**`extension` StringExt** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❌ Property removed: `isValid`

**`class` User** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ⚠️ Param became required in default constructor: `_internalId` (named, optional)
- 🔢 Param became positional in default constructor: `_internalId` (named, optional)
- ❇️ Modifier `final` added to property: `email`
- ❌ Method removed: `updateEmail`
- 🔄 Method type changed: `updatePhone` (`void` → `bool`)
- 🔢 Params reordered in method `updatePhone`: `phone` (positional, required), `mobilePhone` (positional, required)

**`typedef` UserID** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- 🔄 Typedef type changed: UserID

**`function` formatUserInfo** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❌ Function removed: `formatUserInfo`

**`function` genericMethod<K, V>** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- 🔄 Function type changed: `genericMethod` (`void` → `V`)
- 🔄 Type parameters changed: `K, V` → `V extends num`
- ❌ Params removed in function `genericMethod`: `key` (positional, required), `value` (positional, required)
- ❇️ Param added in function `genericMethod`: `input` (positional, required)

**`function` narrowingParams** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- 🔄 Param type changed in function `narrowingParams`: `a` (`num` → `int`, narrowed)

#### ✨ Minor changes

**`class` AbstractModifiers** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❌ Modifier `abstract` removed from method: `willLoseAbstract`

**`class` AnotherBaseClass** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Class added: `AnotherBaseClass`

**`class` ClassRemovalWillBeMinorBecauseExtendsClassWithSuper** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❌ Class removed: `ClassRemovalWillBeMinorBecauseExtendsClassWithSuper`

**`class` CustomWidget** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❌ Param removed in default constructor: `key` (named, required)

**`class` GenericClass<T>** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Modifier `const` added to constructor: `new`

**`mixin` MagnitudeOverrideTest** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Constructor added: `new`

**`class` Modifiers** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Modifier `const` added to constructor: `new`
- ❌ Modifier `final` removed from property: `willLoseFinal`
- ❇️ Modifier `const` added to property: `willBecomeConst`
- ❇️ Modifier `late` added to property: `willBecomeLate`
- ❌ Modifier `late` removed from property: `willLoseLate`

**`class` User** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Param added in default constructor: `mobilePhone` (named, optional)
- ❇️ Params added in constructor `fromJson`: `fallbackName` (named, optional), `fallbackAge` (named, optional, default: 25)
- ❇️ Property added: `mobilePhone`
- ❇️ Param added in method `updatePhone`: `notifyUserViaEmail` (named, optional, default: false)

**`function` calculateDiscount** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Param added in function `calculateDiscount`: `roundUp` (named, optional, default: false)

#### 👀 Patch changes

**`mixin` MagnitudeOverrideTest** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❌ Property removed: `willBeRemovedAsNonBreaking`
- ❇️ Properties added: `internalField`, `experimentalField`

**`mixin` TimestampMixin** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❌ Property removed: `createdAt`


## 0.1.0


### API Changes

#### ✨ Minor changes

**`class` AbstractModifiers** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Class added: `AbstractModifiers`

**`class` ClassExtendingFromDartPackage** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Class added: `ClassExtendingFromDartPackage`

**`class` ClassRemovalWillBeMinorBecauseExtendsClassWithSuper** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Class added: `ClassRemovalWillBeMinorBecauseExtendsClassWithSuper`

**`class` ClassWithSuper** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ➕ Interface added: InterfaceB
- ➕ Mixin added: MixinB

**`class` CustomWidget** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Class added: `CustomWidget`

**`class` GenericClass<T>** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Class added: `GenericClass`

**`class` InterfaceB** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Class added: `InterfaceB`

**`mixin` MagnitudeOverrideTest** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Mixin added: `MagnitudeOverrideTest`

**`mixin` MixinB** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Mixin added: `MixinB`

**`class` Modifiers** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Class added: `Modifiers`

**`class` Order** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Class added: `Order`

**`enum` Status** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Property added: `pending`

**`extension` StringExt** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Property added: `isEmail`

**`mixin` TimestampMixin** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Method added: `setTimestamp`

**`class` User** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Params added in default constructor: `_internalId` (named, optional), `phone` (named, optional)
- ❇️ Constructor added: `fromJson`
- ❇️ Property added: `phone`
- ❇️ Params added in method `updateEmail`: `notifyUserViaEmail` (named, optional, default: false), `logChange` (named, optional, default: true)
- ❇️ Method added: `updatePhone`

**`class` Widget** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Class added: `Widget`

**`function` calculateDiscount** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Function added: `calculateDiscount`

**`function` formatUserInfo** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Function added: `formatUserInfo`

**`function` genericMethod<K, V>** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Function added: `genericMethod`

**`function` narrowingParams** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Function added: `narrowingParams`

**`function` wideningParams** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- 🔄 Param type changed in function `wideningParams`: `a` (`int` → `num`, widened)

#### 👀 Patch changes

**`class` Product** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ➕ Class annotation added: `Product` (@deprecated)
- ➕ Properties annotation added: `id` (@deprecated), `price` (@deprecated)
- ❌ Property removed: `_internalId`
- ❌ Method removed: `_generateInternalId`

**`extension` StringExt** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❌ Method removed: `_isInternal`

**`mixin` TimestampMixin** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❌ Method removed: `_updateTimestamp`

**`class` User** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Property added: `_internalId`


## 0.0.2



### Bug Fixes

- add _internalId to Product, remove _PrivateClass 

### API Changes

#### 👀 Patch changes

**`class` Product** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.1..v0.0.2#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Property added: `_internalId`
- ❇️ Method added: `_generateInternalId`

**`extension` StringExt** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.1..v0.0.2#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Method added: `_isInternal`

**`mixin` TimestampMixin** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.1..v0.0.2#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Method added: `_updateTimestamp`

**`class` User** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.1..v0.0.2#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ✏️ Param renamed in method `updateEmail`: `newEmail` → `email`

**`class` _PrivateClass** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.1..v0.0.2#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❌ Class removed: `_PrivateClass`


## 0.0.1

* TODO: Describe initial release.
