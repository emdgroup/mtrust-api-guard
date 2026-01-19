// Now, instead of explicitly using 'lib/src/api.dart' as the entry point,
// we re-export it in 'lib/main.dart' and use 'lib/main.dart' as the entry point.
// Note that we do not export 'lib/internal.dart' to keep it private.
export 'src/api.dart';
