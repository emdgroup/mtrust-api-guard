// Not exported from lib/src/api.dart, the entry point this fixture configures,
// and not referenced from anywhere. It exists so the step from app_v110 to
// app_v200 introduces dead code rather than only resolving it, which is the
// case a reviewer actually gets warned about.

class OrphanedHelper {
  String describe() => 'nothing constructs this';
}

void orphanedFunction() {}
