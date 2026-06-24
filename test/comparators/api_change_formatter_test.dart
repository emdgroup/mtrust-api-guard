import 'package:mtrust_api_guard/doc_comparator/api_change_formatter.dart';
import 'package:mtrust_api_guard/mtrust_api_guard.dart';
import 'package:test/test.dart';

void main() {
  group('ApiChangeFormatter', () {
    test('groups pubspec meta changes under a single header', () {
      final changes = [
        MetaApiChange.dependencyRemoved(dependencyName: 'build_config'),
        MetaApiChange.dependencyRemoved(dependencyName: 'build'),
        MetaApiChange.dependencyVersionChange(
          dependencyName: 'analyzer',
          version: '^13.3.0',
          previousVersion: '^7.4.5',
        ),
        MetaApiChange.minDartSdkVersionIncrease(
          version: '>=3.11.0 <4.0.0',
          previousVersion: '>=3.0.0 <4.0.0',
        ),
      ];

      final formatted = ApiChangeFormatter(changes, markdownHeaderLevel: 4).format();

      expect(formatted, contains('**`meta` pubspec.yaml**'));
      expect(formatted, isNot(contains('dependency `build_config`')));
      expect(formatted, contains('📦 Removed `build_config`'));
      expect(formatted, contains('📦 Removed `build`'));
      expect(formatted, contains('📦 `analyzer` version changed: from `^7.4.5` to `^13.3.0`'));
      expect(formatted, isNot(contains('removed: removed')));
      expect('**`meta` pubspec.yaml**'.allMatches(formatted).length, 2);
    });

    test('dependency removal is formatted as patch change', () {
      final change = MetaApiChange.dependencyRemoved(dependencyName: 'code_builder');

      expect(change.getMagnitude(), ApiChangeMagnitude.patch);
    });
  });
}
