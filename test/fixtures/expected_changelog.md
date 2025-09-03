## 1.0.0



### Features

- implement compatibility with v1.0.0 

### API Changes

#### 💣 Breaking changes

**Product** (lib/src/api.dart)
- ❌ Class removed: `Product`

**User** (lib/src/api.dart)
- ⚠️ Param became required in constructor new: `_internalId`
- 🔢 Param became positional in constructor new: `_internalId`

#### ✨ Minor changes

**User** (lib/src/api.dart)
- ❇️ Param added in constructor new: `mobilePhone`
- ❇️ Property added: `mobilePhone`


## 0.1.0


### API Changes

#### ✨ Minor changes

**Order** (lib/src/api.dart)
- ❇️ Class added: `Order`

**User** (lib/src/api.dart)
- ❇️ Params added in constructor new: `_internalId`, `phone`
- ❇️ Property added: `phone`

#### 👀 Patch changes

**Product** (lib/src/api.dart)
- ❌ Property removed: `_internalId`

**User** (lib/src/api.dart)
- ❇️ Property added: `_internalId`


## 0.0.2


### API Changes

#### 👀 Patch changes

**Product** (lib/src/api.dart)
- ❇️ Property added: `_internalId`

**_PrivateClass** (lib/src/api.dart)
- ❌ Class removed: `_PrivateClass`


## 0.0.1

* TODO: Describe initial release.
