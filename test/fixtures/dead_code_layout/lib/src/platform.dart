// The analyzer resolves this to one branch, but a different platform compiles
// the other, so neither is dead.
export 'platform_web.dart' if (dart.library.io) 'platform_io.dart';
