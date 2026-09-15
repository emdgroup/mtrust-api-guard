// Nothing here is reachable from lib/src/api.dart, the entry point this
// fixture configures, so none of it reaches the generated API documentation.
// It exercises the rules the dead code scan applies to avoid false positives.

/// Referenced from `bin/`, so it stays alive.
class UsedInternally {
  String get label => 'used';
}

/// Nothing references this and nothing exports it.
class DeadInternal {
  void neverCalled() {}

  int neverRead = 0;
}

/// Private and unreferenced.
class _DeadPrivate {
  const _DeadPrivate();
}

/// Only ever calls itself, which is not a use by anyone.
void _recursivelyDead() {
  _recursivelyDead();
}

/// Used from `test/`, which counts.
class UsedOnlyByTest {
  bool get ok => true;
}

/// Used from `bin/`, which counts.
class UsedOnlyByBin {
  void execute() {}
}

/// Constructed, so the class is alive, while `unreadField` is only written.
class Holder {
  Holder(this.unreadField) : readField = unreadField * 2;

  final int unreadField;
  final int readField;
}

/// The `+` operator is applied in `bin/`, and the resolved AST maps `a + b`
/// back to this declaration.
class Vec {
  const Vec(this.x);

  final int x;

  Vec operator +(Vec other) => Vec(x + other.x);
}

/// `toJson` is dispatched dynamically by `jsonEncode`, so an unreferenced one
/// is not evidence of anything.
class Serializable {
  Map<String, dynamic> toJson() => {};
}

class Base {
  void hook() {}
}

/// Overrides a hook that is called through [Base], so it is reached
/// polymorphically.
class Subclass extends Base {
  @override
  void hook() {}
}

/// Applied as `'x'.shouted`, where the extension's own name never appears.
extension StringShouting on String {
  String get shouted => toUpperCase();
}

/// Nothing applies this extension.
extension DeadExtension on int {
  int get doubled => this * 2;
}

/// Reachable from native code, so never reported.
@pragma('vm:entry-point')
void nativeCallback() {}

/// An entry point is never unused.
void main() {}

/// Mentioned in the doc comment below and nowhere in code.
class DocumentedOnly {}

/// Refers to [DocumentedOnly], which is a mention rather than a use.
class DocumentationCarrier {
  const DocumentationCarrier();
}

/// Referenced only from a generated file, which still counts as a reference.
class UsedByGenerated {
  void help() {}
}

/// Constructed from `bin/`. `_ticks` is only ever read by the increment that
/// compares it.
class Ticker {
  int _ticks = 0;

  bool tick() => ++_ticks > 3;
}
