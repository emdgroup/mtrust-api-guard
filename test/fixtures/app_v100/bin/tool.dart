import 'package:api_guard_test/src/dead_code_cases.dart';
import 'package:api_guard_test/src/dead_code_cases.g.dart';

void main() {
  UsedOnlyByBin().execute();

  final sum = Vec(1) + Vec(2);
  Base().hook();
  Subclass().hook();
  GeneratedHelper().help();
  Registers();
  Ticker().tick();

  if (const Point(1) case Point(:final doubled)) {
    // ignore: avoid_print
    print('$doubled ${Listed.values}');
  }

  // ignore: avoid_print
  print('${UsedInternally().label} ${'x'.shouted} ${Holder(7).readField} '
      '${sum.x} ${Serializable().hashCode}');
}
