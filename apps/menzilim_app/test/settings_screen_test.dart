import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menzilim_app/core/settings/app_settings_controller.dart';
import 'package:menzilim_app/features/auth/screens/login_screen.dart';
import 'package:menzilim_app/features/settings/screens/settings_screen.dart';
import 'package:menzilim_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpSettings(WidgetTester tester, AppSettingsController settings) async {
    await tester.pumpWidget(
      MenzilimApp(settings: settings, home: const SettingsScreen()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('dil ve tema seçeneklerini gösterir', (tester) async {
    await pumpSettings(tester, AppSettingsController());

    expect(find.text('Ayarlar'), findsOneWidget);
    expect(find.text('Dil'), findsOneWidget);
    expect(find.text('Türkçe'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Tema'), findsOneWidget);
    expect(find.text('Sistem'), findsOneWidget);
    expect(find.text('Açık'), findsOneWidget);
    expect(find.text('Koyu'), findsOneWidget);
  });

  testWidgets('English seçimi arayüzü anında çevirir ve kaydedilir', (tester) async {
    final settings = AppSettingsController();
    await pumpSettings(tester, settings);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(settings.locale, const Locale('en'));
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(AppSettingsController.localeKey), 'en');

    // Türkçeye geri dönüş.
    await tester.tap(find.text('Türkçe'));
    await tester.pumpAndSettle();

    expect(find.text('Ayarlar'), findsOneWidget);
    expect(preferences.getString(AppSettingsController.localeKey), 'tr');
  });

  testWidgets('Koyu tema seçimi temayı anında değiştirir ve kaydedilir', (tester) async {
    final settings = AppSettingsController();
    await pumpSettings(tester, settings);

    await tester.tap(find.text('Koyu'));
    await tester.pumpAndSettle();

    expect(settings.themeMode, ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
      Brightness.dark,
    );

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(AppSettingsController.themeModeKey), 'dark');

    await tester.tap(find.text('Açık'));
    await tester.pumpAndSettle();

    expect(settings.themeMode, ThemeMode.light);
    expect(preferences.getString(AppSettingsController.themeModeKey), 'light');
  });

  for (final locale in const [Locale('tr'), Locale('en')]) {
    testWidgets('400px genişlikte taşmaz (${locale.languageCode})', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpSettings(tester, AppSettingsController(locale: locale));

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('giriş ekranından ayarlara gidilebilir', (tester) async {
    await tester.pumpWidget(
      MenzilimApp(settings: AppSettingsController()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Ayarlar'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}
