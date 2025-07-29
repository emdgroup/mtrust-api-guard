import 'dart:io';

String? getSdkPath() {
  return Platform.environment['FLUTTER_ROOT'] != null
      ? '${Platform.environment['FLUTTER_ROOT']}/bin/cache/dart-sdk'
      : null;
}
