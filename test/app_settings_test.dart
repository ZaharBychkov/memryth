import 'package:flutter_test/flutter_test.dart';
import 'package:memryth_dart_project/settings/app_settings.dart';

void main() {
  group('AppSettings Pro entitlement', () {
    test('defaults keep Pro locked', () {
      expect(AppSettings.defaults.proUnlocked, isFalse);
      expect(AppSettings.defaults.proUnlockedAt, isNull);
    });

    test('copyWith stores Pro unlock state', () {
      final unlockedAt = DateTime.utc(2026, 5, 4, 12);
      final settings = AppSettings.defaults.copyWith(
        proUnlocked: true,
        proUnlockedAt: unlockedAt,
      );

      expect(settings.proUnlocked, isTrue);
      expect(settings.proUnlockedAt, unlockedAt);
    });
  });
}
