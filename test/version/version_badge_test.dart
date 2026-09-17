import 'package:mtrust_api_guard/badges/badge_generator.dart';
import 'package:test/test.dart';

void main() {
  group('versionBadgeUrl', () {
    test('puts a release version into the message', () {
      expect(versionBadgeUrl('8.2.0'), 'https://img.shields.io/badge/version-8.2.0-blue');
    });

    test('doubles the dashes of a pre-release, which shields.io reads as separators', () {
      expect(versionBadgeUrl('3.0.0-dev.1'), 'https://img.shields.io/badge/version-3.0.0--dev.1-blue');
    });

    test('doubles underscores and encodes build metadata', () {
      expect(versionBadgeUrl('1.0.0-beta_2+7'), 'https://img.shields.io/badge/version-1.0.0--beta__2%2B7-blue');
    });
  });
}
