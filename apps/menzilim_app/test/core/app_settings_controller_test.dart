import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menzilim_app/core/settings/app_settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppSettingsController.load', () {
    test('kayıt yoksa varsayılan Türkçe ve sistem teması', () async {
      SharedPreferences.setMockInitialValues({});

      final settings = await AppSettingsController.load();

      expect(settings.locale, const Locale('tr'));
      expect(settings.themeMode, ThemeMode.system);
    });

    test('kayıtlı dil ve temayı okur', () async {
      SharedPreferences.setMockInitialValues({
        AppSettingsController.localeKey: 'en',
        AppSettingsController.themeModeKey: 'dark',
      });

      final settings = await AppSettingsController.load();

      expect(settings.locale, const Locale('en'));
      expect(settings.themeMode, ThemeMode.dark);
    });

    test('geçersiz kayıtta varsayılanlara döner', () async {
      SharedPreferences.setMockInitialValues({
        AppSettingsController.localeKey: 'de',
        AppSettingsController.themeModeKey: 'sepia',
      });

      final settings = await AppSettingsController.load();

      expect(settings.locale, const Locale('tr'));
      expect(settings.themeMode, ThemeMode.system);
    });
  });

  group('AppSettingsController değişiklikleri', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('dil değişikliği dinleyicilere bildirilir ve kalıcıdır', () async {
      final settings = AppSettingsController();
      var notified = 0;
      settings.addListener(() => notified++);

      await settings.setLocale(const Locale('en'));

      expect(settings.locale, const Locale('en'));
      expect(notified, 1);

      // Uygulamanın yeniden açılması.
      final reloaded = await AppSettingsController.load();
      expect(reloaded.locale, const Locale('en'));
    });

    test('tema değişikliği dinleyicilere bildirilir ve kalıcıdır', () async {
      final settings = AppSettingsController();
      var notified = 0;
      settings.addListener(() => notified++);

      await settings.setThemeMode(ThemeMode.light);

      expect(settings.themeMode, ThemeMode.light);
      expect(notified, 1);

      final reloaded = await AppSettingsController.load();
      expect(reloaded.themeMode, ThemeMode.light);
    });

    test('aynı değer tekrar seçilirse bildirim yapılmaz', () async {
      final settings = AppSettingsController();
      var notified = 0;
      settings.addListener(() => notified++);

      await settings.setLocale(const Locale('tr'));
      await settings.setThemeMode(ThemeMode.system);

      expect(notified, 0);
    });

    test('desteklenmeyen dil Türkçeye düşer', () async {
      final settings = AppSettingsController(locale: const Locale('en'));

      await settings.setLocale(const Locale('de'));

      expect(settings.locale, const Locale('tr'));
    });
  });
}
