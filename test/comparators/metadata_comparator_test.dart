import 'package:mtrust_api_guard/mtrust_api_guard.dart';
import 'package:mtrust_api_guard/doc_comparator/comparators/metadata_comparator.dart';
import 'package:test/test.dart';

void main() {
  group('MetadataComparator', () {
    group('Dart SDK Constraint Tests', () {
      test('minimum version increase creates major change', () {
        final oldMeta = PackageMetadata(sdkVersion: '^2.0.0');
        final newMeta = PackageMetadata(sdkVersion: '^3.0.0');

        final changes = oldMeta.compareTo(newMeta);

        expect(changes.length, greaterThanOrEqualTo(1));
        final minIncrease = changes.firstWhere(
          (c) => c.operation == ApiChangeOperation.minDartSdkVersionIncrease,
        );
        expect(minIncrease.getMagnitude(), ApiChangeMagnitude.major);
        expect(minIncrease.changedValue, contains('^3.0.0'));
        expect(minIncrease.changedValue, contains('^2.0.0'));
      });

      test('minimum version decrease creates patch change', () {
        final oldMeta = PackageMetadata(sdkVersion: '^3.0.0');
        final newMeta = PackageMetadata(sdkVersion: '^2.0.0');

        final changes = oldMeta.compareTo(newMeta);

        expect(changes.length, greaterThanOrEqualTo(1));
        final minDecrease = changes.firstWhere(
          (c) => c.operation == ApiChangeOperation.minDartSdkVersionDecrease,
        );
        expect(minDecrease.getMagnitude(), ApiChangeMagnitude.patch);
      });

      test('maximum version increase creates patch change', () {
        final oldMeta = PackageMetadata(sdkVersion: '<4.0.0');
        final newMeta = PackageMetadata(sdkVersion: '<5.0.0');

        final changes = oldMeta.compareTo(newMeta);

        expect(changes, hasLength(1));
        expect(changes.first.operation, ApiChangeOperation.maxDartSdkVersionIncrease);
        expect(changes.first.getMagnitude(), ApiChangeMagnitude.patch);
      });

      test('maximum version decrease creates major change', () {
        final oldMeta = PackageMetadata(sdkVersion: '<5.0.0');
        final newMeta = PackageMetadata(sdkVersion: '<4.0.0');

        final changes = oldMeta.compareTo(newMeta);

        expect(changes, hasLength(1));
        expect(changes.first.operation, ApiChangeOperation.maxDartSdkVersionDecrease);
        expect(changes.first.getMagnitude(), ApiChangeMagnitude.major);
      });

      test('adding constraint from null creates major change', () {
        final oldMeta = PackageMetadata(sdkVersion: null);
        final newMeta = PackageMetadata(sdkVersion: '^3.0.0');

        final changes = oldMeta.compareTo(newMeta);

        expect(changes, hasLength(1));
        expect(changes.first.operation, ApiChangeOperation.minDartSdkVersionIncrease);
        expect(changes.first.getMagnitude(), ApiChangeMagnitude.major);
        expect(changes.first.changedValue, contains('not constrained'));
      });

      test('removing constraint to null creates patch change', () {
        final oldMeta = PackageMetadata(sdkVersion: '^3.0.0');
        final newMeta = PackageMetadata(sdkVersion: null);

        final changes = oldMeta.compareTo(newMeta);

        expect(changes, hasLength(1));
        expect(changes.first.operation, ApiChangeOperation.minDartSdkVersionDecrease);
        expect(changes.first.getMagnitude(), ApiChangeMagnitude.patch);
      });

      test('range constraint with both min and max changes', () {
        final oldMeta = PackageMetadata(sdkVersion: '>=2.0.0 <4.0.0');
        final newMeta = PackageMetadata(sdkVersion: '>=3.0.0 <5.0.0');

        final changes = oldMeta.compareTo(newMeta);

        expect(changes, hasLength(2));
        expect(
          changes.any((c) => c.operation == ApiChangeOperation.minDartSdkVersionIncrease),
          isTrue,
        );
        expect(
          changes.any((c) => c.operation == ApiChangeOperation.maxDartSdkVersionIncrease),
          isTrue,
        );
      });

      test('exact version constraint change', () {
        final oldMeta = PackageMetadata(sdkVersion: '3.0.0');
        final newMeta = PackageMetadata(sdkVersion: '3.1.0');

        final changes = oldMeta.compareTo(newMeta);

        expect(changes, hasLength(2));
        expect(
          changes.any((c) => c.operation == ApiChangeOperation.minDartSdkVersionIncrease),
          isTrue,
        );
        expect(
          changes.any((c) => c.operation == ApiChangeOperation.maxDartSdkVersionIncrease),
          isTrue,
        );
      });

      test('no change when versions are identical', () {
        final oldMeta = PackageMetadata(sdkVersion: '^3.0.0');
        final newMeta = PackageMetadata(sdkVersion: '^3.0.0');

        final changes = oldMeta.compareTo(newMeta);

        expect(changes, isEmpty);
      });

      test('inclusive to exclusive minimum boundary change', () {
        final oldMeta = PackageMetadata(sdkVersion: '>2.0.0');
        final newMeta = PackageMetadata(sdkVersion: '>=2.0.0');

        final changes = oldMeta.compareTo(newMeta);

        expect(changes, hasLength(1));
        expect(changes.first.operation, ApiChangeOperation.minDartSdkVersionDecrease);
      });

      test('exclusive to inclusive maximum boundary change', () {
        final oldMeta = PackageMetadata(sdkVersion: '<4.0.0');
        final newMeta = PackageMetadata(sdkVersion: '<=4.0.0');

        final changes = oldMeta.compareTo(newMeta);

        expect(changes, hasLength(1));
        expect(changes.first.operation, ApiChangeOperation.maxDartSdkVersionIncrease);
      });
    });

    group('Flutter SDK Constraint Tests', () {
      test('minimum version increase creates major change', () {
        final oldMeta = PackageMetadata(flutterVersion: '^2.0.0');
        final newMeta = PackageMetadata(flutterVersion: '^3.0.0');

        final changes = oldMeta.compareTo(newMeta);

        expect(changes.length, greaterThanOrEqualTo(1));
        final minIncrease = changes.firstWhere(
          (c) => c.operation == ApiChangeOperation.minFlutterSdkVersionIncrease,
        );
        expect(minIncrease.getMagnitude(), ApiChangeMagnitude.major);
      });

      test('minimum version decrease creates patch change', () {
        final oldMeta = PackageMetadata(flutterVersion: '^3.0.0');
        final newMeta = PackageMetadata(flutterVersion: '^2.0.0');

        final changes = oldMeta.compareTo(newMeta);

        expect(changes.length, greaterThanOrEqualTo(1));
        final minDecrease = changes.firstWhere(
          (c) => c.operation == ApiChangeOperation.minFlutterSdkVersionDecrease,
        );
        expect(minDecrease.getMagnitude(), ApiChangeMagnitude.patch);
      });

      test('maximum version increase creates patch change', () {
        final oldMeta = PackageMetadata(flutterVersion: '<4.0.0');
        final newMeta = PackageMetadata(flutterVersion: '<5.0.0');

        final changes = oldMeta.compareTo(newMeta);

        expect(changes, hasLength(1));
        expect(changes.first.operation, ApiChangeOperation.maxFlutterSdkVersionIncrease);
        expect(changes.first.getMagnitude(), ApiChangeMagnitude.patch);
      });

      test('maximum version decrease creates major change', () {
        final oldMeta = PackageMetadata(flutterVersion: '<5.0.0');
        final newMeta = PackageMetadata(flutterVersion: '<4.0.0');

        final changes = oldMeta.compareTo(newMeta);

        expect(changes, hasLength(1));
        expect(changes.first.operation, ApiChangeOperation.maxFlutterSdkVersionDecrease);
        expect(changes.first.getMagnitude(), ApiChangeMagnitude.major);
      });

      test('adding constraint from null creates major change', () {
        final oldMeta = PackageMetadata(flutterVersion: null);
        final newMeta = PackageMetadata(flutterVersion: '^3.0.0');

        final changes = oldMeta.compareTo(newMeta);

        expect(changes, hasLength(1));
        expect(changes.first.operation, ApiChangeOperation.minFlutterSdkVersionIncrease);
        expect(changes.first.getMagnitude(), ApiChangeMagnitude.major);
      });

      test('removing constraint to null creates patch change', () {
        final oldMeta = PackageMetadata(flutterVersion: '^3.0.0');
        final newMeta = PackageMetadata(flutterVersion: null);

        final changes = oldMeta.compareTo(newMeta);

        expect(changes, hasLength(1));
        expect(changes.first.operation, ApiChangeOperation.minFlutterSdkVersionDecrease);
        expect(changes.first.getMagnitude(), ApiChangeMagnitude.patch);
      });

      test('range constraint with both min and max changes', () {
        final oldMeta = PackageMetadata(flutterVersion: '>=2.0.0 <4.0.0');
        final newMeta = PackageMetadata(flutterVersion: '>=3.0.0 <5.0.0');

        final changes = oldMeta.compareTo(newMeta);

        expect(changes, hasLength(2));
        expect(
          changes.any((c) => c.operation == ApiChangeOperation.minFlutterSdkVersionIncrease),
          isTrue,
        );
        expect(
          changes.any((c) => c.operation == ApiChangeOperation.maxFlutterSdkVersionIncrease),
          isTrue,
        );
      });

      test('exact version constraint change', () {
        final oldMeta = PackageMetadata(flutterVersion: '3.0.0');
        final newMeta = PackageMetadata(flutterVersion: '3.1.0');

        final changes = oldMeta.compareTo(newMeta);

        expect(changes, hasLength(2));
        expect(
          changes.any((c) => c.operation == ApiChangeOperation.minFlutterSdkVersionIncrease),
          isTrue,
        );
        expect(
          changes.any((c) => c.operation == ApiChangeOperation.maxFlutterSdkVersionIncrease),
          isTrue,
        );
      });

      test('no change when versions are identical', () {
        final oldMeta = PackageMetadata(flutterVersion: '^3.0.0');
        final newMeta = PackageMetadata(flutterVersion: '^3.0.0');

        final changes = oldMeta.compareTo(newMeta);

        expect(changes, isEmpty);
      });

      test('inclusive to exclusive minimum boundary change', () {
        final oldMeta = PackageMetadata(flutterVersion: '>2.0.0');
        final newMeta = PackageMetadata(flutterVersion: '>=2.0.0');

        final changes = oldMeta.compareTo(newMeta);

        expect(changes, hasLength(1));
        expect(changes.first.operation, ApiChangeOperation.minFlutterSdkVersionDecrease);
      });

      test('exclusive to inclusive maximum boundary change', () {
        final oldMeta = PackageMetadata(flutterVersion: '<4.0.0');
        final newMeta = PackageMetadata(flutterVersion: '<=4.0.0');

        final changes = oldMeta.compareTo(newMeta);

        expect(changes, hasLength(1));
        expect(changes.first.operation, ApiChangeOperation.maxFlutterSdkVersionIncrease);
      });
    });

    group('Android Constraint Tests', () {
      test('version increase creates major change', () {
        final oldMeta = PackageMetadata(
          androidConstraints: AndroidPlatformConstraints(minSdkVersion: 21),
        );
        final newMeta = PackageMetadata(
          androidConstraints: AndroidPlatformConstraints(minSdkVersion: 24),
        );

        final changes = oldMeta.compareTo(newMeta);

        expect(changes, hasLength(1));
        expect(changes.first.operation, ApiChangeOperation.minAndroidSdkVersionIncrease);
        expect(changes.first.getMagnitude(), ApiChangeMagnitude.major);
        expect(changes.first.changedValue, contains('24'));
        expect(changes.first.changedValue, contains('21'));
      });

      test('version decrease creates patch change', () {
        final oldMeta = PackageMetadata(
          androidConstraints: AndroidPlatformConstraints(minSdkVersion: 24),
        );
        final newMeta = PackageMetadata(
          androidConstraints: AndroidPlatformConstraints(minSdkVersion: 21),
        );

        final changes = oldMeta.compareTo(newMeta);

        expect(changes, hasLength(1));
        expect(changes.first.operation, ApiChangeOperation.minAndroidSdkVersionDecrease);
        expect(changes.first.getMagnitude(), ApiChangeMagnitude.patch);
      });

      test('adding constraint from null creates major change', () {
        final oldMeta = PackageMetadata(androidConstraints: null);
        final newMeta = PackageMetadata(
          androidConstraints: AndroidPlatformConstraints(minSdkVersion: 21),
        );

        final changes = oldMeta.compareTo(newMeta);

        expect(changes, hasLength(1));
        expect(changes.first.operation, ApiChangeOperation.minAndroidSdkVersionIncrease);
        expect(changes.first.getMagnitude(), ApiChangeMagnitude.major);
        expect(changes.first.changedValue, contains('21'));
        expect(changes.first.changedValue, contains('0'));
      });

      test('removing constraint to null creates patch change', () {
        final oldMeta = PackageMetadata(
          androidConstraints: AndroidPlatformConstraints(minSdkVersion: 21),
        );
        final newMeta = PackageMetadata(androidConstraints: null);

        final changes = oldMeta.compareTo(newMeta);

        expect(changes, hasLength(1));
        expect(changes.first.operation, ApiChangeOperation.minAndroidSdkVersionDecrease);
        expect(changes.first.getMagnitude(), ApiChangeMagnitude.patch);
        expect(changes.first.changedValue, contains('0'));
        expect(changes.first.changedValue, contains('21'));
      });

      test('no change when versions are identical', () {
        final oldMeta = PackageMetadata(
          androidConstraints: AndroidPlatformConstraints(minSdkVersion: 21),
        );
        final newMeta = PackageMetadata(
          androidConstraints: AndroidPlatformConstraints(minSdkVersion: 21),
        );

        final changes = oldMeta.compareTo(newMeta);

        expect(changes, isEmpty);
      });

      test('null to null creates no change', () {
        final oldMeta = PackageMetadata(androidConstraints: null);
        final newMeta = PackageMetadata(androidConstraints: null);

        final changes = oldMeta.compareTo(newMeta);

        expect(changes, isEmpty);
      });

      test('constraint with other fields unchanged still detects minSdkVersion change', () {
        final oldMeta = PackageMetadata(
          androidConstraints: AndroidPlatformConstraints(
            minSdkVersion: 21,
            compileSdkVersion: 33,
            targetSdkVersion: 33,
          ),
        );
        final newMeta = PackageMetadata(
          androidConstraints: AndroidPlatformConstraints(
            minSdkVersion: 24,
            compileSdkVersion: 33,
            targetSdkVersion: 33,
          ),
        );

        final changes = oldMeta.compareTo(newMeta);

        expect(changes, hasLength(1));
        expect(changes.first.operation, ApiChangeOperation.minAndroidSdkVersionIncrease);
      });
    });

    group('iOS Constraint Tests', () {
      test('version increase creates major change', () {
        final oldMeta = PackageMetadata(
          iosConstraints: IOSPlatformConstraints(minimumOsVersion: 12.0),
        );
        final newMeta = PackageMetadata(
          iosConstraints: IOSPlatformConstraints(minimumOsVersion: 13.0),
        );

        final changes = oldMeta.compareTo(newMeta);

        expect(changes, hasLength(1));
        expect(changes.first.operation, ApiChangeOperation.minIosSdkVersionIncrease);
        expect(changes.first.getMagnitude(), ApiChangeMagnitude.major);
        expect(changes.first.changedValue, contains('13'));
        expect(changes.first.changedValue, contains('12'));
      });

      test('version decrease creates patch change', () {
        final oldMeta = PackageMetadata(
          iosConstraints: IOSPlatformConstraints(minimumOsVersion: 13.0),
        );
        final newMeta = PackageMetadata(
          iosConstraints: IOSPlatformConstraints(minimumOsVersion: 12.0),
        );

        final changes = oldMeta.compareTo(newMeta);

        expect(changes, hasLength(1));
        expect(changes.first.operation, ApiChangeOperation.minIosSdkVersionDecrease);
        expect(changes.first.getMagnitude(), ApiChangeMagnitude.patch);
      });

      test('adding constraint from null creates major change', () {
        final oldMeta = PackageMetadata(iosConstraints: null);
        final newMeta = PackageMetadata(
          iosConstraints: IOSPlatformConstraints(minimumOsVersion: 12.0),
        );

        final changes = oldMeta.compareTo(newMeta);

        expect(changes, hasLength(1));
        expect(changes.first.operation, ApiChangeOperation.minIosSdkVersionIncrease);
        expect(changes.first.getMagnitude(), ApiChangeMagnitude.major);
        expect(changes.first.changedValue, contains('12'));
        expect(changes.first.changedValue, contains('0'));
      });

      test('removing constraint to null creates patch change', () {
        final oldMeta = PackageMetadata(
          iosConstraints: IOSPlatformConstraints(minimumOsVersion: 12.0),
        );
        final newMeta = PackageMetadata(iosConstraints: null);

        final changes = oldMeta.compareTo(newMeta);

        expect(changes, hasLength(1));
        expect(changes.first.operation, ApiChangeOperation.minIosSdkVersionDecrease);
        expect(changes.first.getMagnitude(), ApiChangeMagnitude.patch);
        expect(changes.first.changedValue, contains('0'));
        expect(changes.first.changedValue, contains('12'));
      });

      test('no change when versions are identical', () {
        final oldMeta = PackageMetadata(
          iosConstraints: IOSPlatformConstraints(minimumOsVersion: 12.0),
        );
        final newMeta = PackageMetadata(
          iosConstraints: IOSPlatformConstraints(minimumOsVersion: 12.0),
        );

        final changes = oldMeta.compareTo(newMeta);

        expect(changes, isEmpty);
      });

      test('null to null creates no change', () {
        final oldMeta = PackageMetadata(iosConstraints: null);
        final newMeta = PackageMetadata(iosConstraints: null);

        final changes = oldMeta.compareTo(newMeta);

        expect(changes, isEmpty);
      });

      test('decimal version changes are detected correctly', () {
        final oldMeta = PackageMetadata(
          iosConstraints: IOSPlatformConstraints(minimumOsVersion: 12.1),
        );
        final newMeta = PackageMetadata(
          iosConstraints: IOSPlatformConstraints(minimumOsVersion: 12.2),
        );

        final changes = oldMeta.compareTo(newMeta);

        expect(changes, hasLength(1));
        expect(changes.first.operation, ApiChangeOperation.minIosSdkVersionIncrease);
        expect(changes.first.getMagnitude(), ApiChangeMagnitude.major);
      });

      test('decimal version decrease is detected correctly', () {
        final oldMeta = PackageMetadata(
          iosConstraints: IOSPlatformConstraints(minimumOsVersion: 12.2),
        );
        final newMeta = PackageMetadata(
          iosConstraints: IOSPlatformConstraints(minimumOsVersion: 12.1),
        );

        final changes = oldMeta.compareTo(newMeta);

        expect(changes, hasLength(1));
        expect(changes.first.operation, ApiChangeOperation.minIosSdkVersionDecrease);
        expect(changes.first.getMagnitude(), ApiChangeMagnitude.patch);
      });
    });

    group('Combined Constraint Tests', () {
      test('multiple constraint changes are detected together', () {
        final oldMeta = PackageMetadata(
          sdkVersion: '^2.0.0',
          flutterVersion: '^2.0.0',
          androidConstraints: AndroidPlatformConstraints(minSdkVersion: 21),
          iosConstraints: IOSPlatformConstraints(minimumOsVersion: 12.0),
        );
        final newMeta = PackageMetadata(
          sdkVersion: '^3.0.0',
          flutterVersion: '^3.0.0',
          androidConstraints: AndroidPlatformConstraints(minSdkVersion: 24),
          iosConstraints: IOSPlatformConstraints(minimumOsVersion: 13.0),
        );

        final changes = oldMeta.compareTo(newMeta);

        expect(changes.length, greaterThanOrEqualTo(4));
        expect(
          changes.any((c) => c.operation == ApiChangeOperation.minDartSdkVersionIncrease),
          isTrue,
        );
        expect(
          changes.any((c) => c.operation == ApiChangeOperation.minFlutterSdkVersionIncrease),
          isTrue,
        );
        expect(
          changes.any((c) => c.operation == ApiChangeOperation.minAndroidSdkVersionIncrease),
          isTrue,
        );
        expect(
          changes.any((c) => c.operation == ApiChangeOperation.minIosSdkVersionIncrease),
          isTrue,
        );
      });
    });
  });
}
