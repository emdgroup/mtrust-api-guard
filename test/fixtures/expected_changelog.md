## 1.0.0



### Features

- implement compatibility with v1.0.0 

### API Changes

#### 💣 Breaking changes

**`class` ClassWithSuper** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- 🔄 Superclass changed: `BaseClass -> AnotherBaseClass`
- ➖ Interface removed: `InterfaceA`, `InterfaceB`
- ➖ Mixin removed: `MixinA`, `MixinB`

**`class` GenericClass<T>** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- 🔄 Type parameters changed: `T -> T extends num`

**`class` InterfaceB** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❌ Class removed: `InterfaceB`

**`mixin` MixinB** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❌ Mixin removed: `MixinB`

**`class` Product** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❌ Class removed: `Product`

**`enum` Status** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❌ Property removed: `inactive`

**`extension` StringExt** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❌ Property removed: `isValid`

**`mixin` TimestampMixin** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❌ Property removed: `createdAt`

**`class` User** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ⚠️ Param became required in default constructor: `_internalId (named, optional)`
- 🔢 Param became positional in default constructor: `_internalId (named, optional)`
- ❌ Method removed: `updateEmail`
- 🔄 Method type changed: `updatePhone` (void -> bool)
- ❇️ Param added in method `updatePhone`: `mobilePhone (positional, required)`

**`typedef` UserID** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- 🔄 Typedef type changed: `UserID`

**`platform constraint` android:minSdkVersion** ([null](null))
- 📱 Platform constraint changed: `Android minSdkVersion changed from 19 to 21`

**`function` formatUserInfo** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❌ Function removed: `formatUserInfo`

**`function` genericMethod<K, V>** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- 🔄 Function type changed: `genericMethod` (void -> V)
- 🔄 Type parameters changed: `genericMethod` (K, V -> V extends num)
- 🔄 Param type changed in function `genericMethod`: `key (positional, required)`
- ❌ Param removed in function `genericMethod`: `value (positional, required)`

#### ✨ Minor changes

**`class` AnotherBaseClass** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Class added: `AnotherBaseClass`

**`class` User** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Param added in default constructor: `mobilePhone (named, optional)`
- ❇️ Params added in constructor `fromJson`: `fallbackName (named, optional)`, `fallbackAge (named, optional, default: 25)`
- ❇️ Property added: `mobilePhone`
- ❇️ Param added in method `updatePhone`: `notifyUserViaEmail (named, optional, default: false)`

**`function` calculateDiscount** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Param added in function `calculateDiscount`: `roundUp (named, optional, default: false)`

#### 👀 Patch changes

**`class` User** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ✏️ Param renamed in method `updatePhone`: `newPhone -> phone`

**`function` genericMethod<K, V>** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.1.0..v1.0.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ✏️ Param renamed in function `genericMethod`: `key -> input`


## 0.1.0


### API Changes

#### ✨ Minor changes

**`class` ClassWithSuper** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ➕ Interface added: `InterfaceB`
- ➕ Mixin added: `MixinB`

**`class` GenericClass<T>** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Class added: `GenericClass`

**`class` InterfaceB** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Class added: `InterfaceB`

**`mixin` MixinB** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Mixin added: `MixinB`

**`class` Order** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Class added: `Order`

**`enum` Status** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Property added: `pending`

**`extension` StringExt** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Property added: `isEmail`

**`mixin` TimestampMixin** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Method added: `setTimestamp`

**`class` User** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Params added in default constructor: `_internalId (named, optional)`, `phone (named, optional)`
- ❇️ Constructor added: `fromJson`
- ❇️ Property added: `phone`
- ❇️ Methods added: `UnimplementedError`, `updateEmail`, `updatePhone`

**`function` calculateDiscount** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Function added: `calculateDiscount`

**`function` formatUserInfo** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Function added: `formatUserInfo`

**`function` genericMethod<K, V>** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.2..v0.1.0#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❇️ Function added: `genericMethod`

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

**`dependency` path** ([null](null))
- 📦 Dependency removed: `path`


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

**`class` _PrivateClass** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/compare/v0.0.1..v0.0.2#diff-c816f176d594247f8735cee6e4679acac26e0c901ad6d693562f1f173244fd54))
- ❌ Class removed: `_PrivateClass`

**`dependency` path** ([null](null))
- 📦 Dependency added: `path`


## 0.0.1

* TODO: Describe initial release.
