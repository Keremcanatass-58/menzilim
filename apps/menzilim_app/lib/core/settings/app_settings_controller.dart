import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulama geneli dil ve tema tercihi. Tercihler cihazda
/// (SharedPreferences) saklanır; değişiklik anında uygulanır, yeniden
/// başlatma gerekmez.
class AppSettingsController extends ChangeNotifier {
  static const String localeKey = 'app_locale';
  static const String themeModeKey = 'app_theme_mode';

  static const Locale defaultLocale = Locale('tr');
  static const ThemeMode defaultThemeMode = ThemeMode.system;

  static const List<Locale> supportedLocales = [
    Locale('tr'),
    Locale('en'),
  ];

  Locale _locale;
  ThemeMode _themeMode;

  AppSettingsController({
    this._locale = defaultLocale,
    this._themeMode = defaultThemeMode,
  });

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;

  /// Kayıtlı tercihleri okur; yoksa veya geçersizse varsayılanlar kullanılır.
  static Future<AppSettingsController> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();

      return AppSettingsController(
        locale: _parseLocale(preferences.getString(localeKey)),
        themeMode: _parseThemeMode(preferences.getString(themeModeKey)),
      );
    } catch (_) {
      // Depolama erişilemezse uygulama varsayılanlarla açılır.
      return AppSettingsController();
    }
  }

  Future<void> setLocale(Locale locale) async {
    final supported = _parseLocale(locale.languageCode);
    if (supported == _locale) return;

    _locale = supported;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(localeKey, supported.languageCode);
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    if (themeMode == _themeMode) return;

    _themeMode = themeMode;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(themeModeKey, themeMode.name);
  }

  static Locale _parseLocale(String? languageCode) {
    return supportedLocales.firstWhere(
      (locale) => locale.languageCode == languageCode,
      orElse: () => defaultLocale,
    );
  }

  static ThemeMode _parseThemeMode(String? name) {
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => defaultThemeMode,
    );
  }
}
