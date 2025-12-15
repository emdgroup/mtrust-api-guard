## 1.0.0

### Features

- implement compatibility with v1.0.0

### API Changes

#### 💣 Breaking changes

**Product** (lib/src/api.dart)

- ❌ Class removed: `Product`

**Status** (lib/src/api.dart)

- ❌ Property removed: `inactive`

**StringExt** (lib/src/api.dart)

- ❌ Property removed: `isValid`

**TimestampMixin** (lib/src/api.dart)

- ❌ Property removed: `createdAt`

**User** (lib/src/api.dart)

- ⚠️ Param became required in default constructor: `_internalId (named, optional)`
- 🔢 Param became positional in default constructor: `_internalId (named, optional)`
- ❌ Method removed: `updateEmail`
- 🔄 Method type changed: `updatePhone` (void -> bool)
- ❇️ Param added in method `updatePhone`: `mobilePhone (positional, required)`

**UserID** (lib/src/api.dart)

- 🔄 Typedef type changed: `UserID`

**formatUserInfo** (lib/src/api.dart)

- ❌ Function removed: `formatUserInfo`

#### ✨ Minor changes

**User** (lib/src/api.dart)

- ❇️ Param added in default constructor: `mobilePhone (named, optional)`
- ❇️ Params added in constructor `fromJson`: `fallbackName (named, optional)`, `fallbackAge (named, optional, default: 25)`
- ❇️ Property added: `mobilePhone`
- ❇️ Param added in method `updatePhone`: `notifyUserViaEmail (named, optional, default: false)`

**calculateDiscount** (lib/src/api.dart)

- ❇️ Param added in function `calculateDiscount`: `roundUp (named, optional, default: false)`

#### 👀 Patch changes

**User** (lib/src/api.dart)

- ✏️ Param renamed in method `updatePhone`: `newPhone -> phone`

## 0.1.0

### API Changes

#### ✨ Minor changes

**Order** (lib/src/api.dart)

- ❇️ Class added: `Order`

**Status** (lib/src/api.dart)

- ❇️ Property added: `pending`

**StringExt** (lib/src/api.dart)

- ❇️ Property added: `isEmail`

**TimestampMixin** (lib/src/api.dart)

- ❇️ Method added: `setTimestamp`

**User** (lib/src/api.dart)

- ❇️ Params added in default constructor: `_internalId (named, optional)`, `phone (named, optional)`
- ❇️ Constructor added: `fromJson`
- ❇️ Property added: `phone`
- ❇️ Methods added: `UnimplementedError`, `updateEmail`, `updatePhone`

**calculateDiscount** (lib/src/api.dart)

- ❇️ Function added: `calculateDiscount`

**formatUserInfo** (lib/src/api.dart)

- ❇️ Function added: `formatUserInfo`

#### 👀 Patch changes

**Product** (lib/src/api.dart)

- ❌ Property removed: `_internalId`
- ❌ Method removed: `_generateInternalId`

**StringExt** (lib/src/api.dart)

- ❌ Method removed: `_isInternal`

**TimestampMixin** (lib/src/api.dart)

- ❌ Method removed: `_updateTimestamp`

**User** (lib/src/api.dart)

- ❇️ Property added: `_internalId`

## 0.0.2

### API Changes

#### 👀 Patch changes

**Product** (lib/src/api.dart)

- ❇️ Property added: `_internalId`
- ❇️ Method added: `_generateInternalId`

**StringExt** (lib/src/api.dart)

- ❇️ Method added: `_isInternal`

**TimestampMixin** (lib/src/api.dart)

- ❇️ Method added: `_updateTimestamp`

**_PrivateClass** (lib/src/api.dart)

- ❌ Class removed: `_PrivateClass`

## 0.0.1

* TODO: Describe initial release.
