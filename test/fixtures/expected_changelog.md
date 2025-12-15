## 1.0.0

### Features

- implement compatibility with v1.0.0

### API Changes

#### 💣 Breaking changes

**`class` Product** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/blob/v1.0.0/lib/src/api.dart))

- ❌ Class removed: `Product`

**`enum` Status** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/blob/v1.0.0/lib/src/api.dart))

- ❌ Property removed: `inactive`

**`extension` StringExt** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/blob/v1.0.0/lib/src/api.dart))

- ❌ Property removed: `isValid`

**`mixin` TimestampMixin** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/blob/v1.0.0/lib/src/api.dart))

- ❌ Property removed: `createdAt`

**`class` User** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/blob/v1.0.0/lib/src/api.dart))

- ⚠️ Param became required in default constructor: `_internalId (named, optional)`
- 🔢 Param became positional in default constructor: `_internalId (named, optional)`
- ❌ Method removed: `updateEmail`
- 🔄 Method type changed: `updatePhone` (void -> bool)
- ❇️ Param added in method `updatePhone`: `mobilePhone (positional, required)`

**`typedef` UserID** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/blob/v1.0.0/lib/src/api.dart))

- 🔄 Typedef type changed: `UserID`

**`function` formatUserInfo** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/blob/v1.0.0/lib/src/api.dart))

- ❌ Function removed: `formatUserInfo`

#### ✨ Minor changes

**`class` User** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/blob/v1.0.0/lib/src/api.dart))

- ❇️ Param added in default constructor: `mobilePhone (named, optional)`
- ❇️ Params added in constructor `fromJson`: `fallbackName (named, optional)`, `fallbackAge (named, optional, default: 25)`
- ❇️ Property added: `mobilePhone`
- ❇️ Param added in method `updatePhone`: `notifyUserViaEmail (named, optional, default: false)`

**`function` calculateDiscount** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/blob/v1.0.0/lib/src/api.dart))

- ❇️ Param added in function `calculateDiscount`: `roundUp (named, optional, default: false)`

#### 👀 Patch changes

**`class` User** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/blob/v1.0.0/lib/src/api.dart))

- ✏️ Param renamed in method `updatePhone`: `newPhone -> phone`

## 0.1.0

### API Changes

#### ✨ Minor changes

**`class` Order** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/blob/v0.1.0/lib/src/api.dart))

- ❇️ Class added: `Order`

**`enum` Status** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/blob/v0.1.0/lib/src/api.dart))

- ❇️ Property added: `pending`

**`extension` StringExt** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/blob/v0.1.0/lib/src/api.dart))

- ❇️ Property added: `isEmail`

**`mixin` TimestampMixin** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/blob/v0.1.0/lib/src/api.dart))

- ❇️ Method added: `setTimestamp`

**`class` User** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/blob/v0.1.0/lib/src/api.dart))

- ❇️ Params added in default constructor: `_internalId (named, optional)`, `phone (named, optional)`
- ❇️ Constructor added: `fromJson`
- ❇️ Property added: `phone`
- ❇️ Methods added: `UnimplementedError`, `updateEmail`, `updatePhone`

**`function` calculateDiscount** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/blob/v0.1.0/lib/src/api.dart))

- ❇️ Function added: `calculateDiscount`

**`function` formatUserInfo** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/blob/v0.1.0/lib/src/api.dart))

- ❇️ Function added: `formatUserInfo`

#### 👀 Patch changes

**`class` Product** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/blob/v0.1.0/lib/src/api.dart))

- ➕ Class annotation added: `Product` (@deprecated)
- ➕ Properties annotation added: `id` (@deprecated), `price` (@deprecated)
- ❌ Property removed: `_internalId`
- ❌ Method removed: `_generateInternalId`

**`extension` StringExt** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/blob/v0.1.0/lib/src/api.dart))

- ❌ Method removed: `_isInternal`

**`mixin` TimestampMixin** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/blob/v0.1.0/lib/src/api.dart))

- ❌ Method removed: `_updateTimestamp`

**`class` User** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/blob/v0.1.0/lib/src/api.dart))

- ❇️ Property added: `_internalId`

## 0.0.2

### API Changes

#### 👀 Patch changes

**`class` Product** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/blob/v0.0.2/lib/src/api.dart))

- ❇️ Property added: `_internalId`
- ❇️ Method added: `_generateInternalId`

**`extension` StringExt** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/blob/v0.0.2/lib/src/api.dart))

- ❇️ Method added: `_isInternal`

**`mixin` TimestampMixin** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/blob/v0.0.2/lib/src/api.dart))

- ❇️ Method added: `_updateTimestamp`

**`class` _PrivateClass** ([lib/src/api.dart](https://github.com/emdgroup/mtrust-api-guard/blob/v0.0.2/lib/src/api.dart))

- ❌ Class removed: `_PrivateClass`

## 0.0.1

* TODO: Describe initial release.