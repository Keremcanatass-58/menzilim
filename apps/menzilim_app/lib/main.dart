import 'package:flutter/material.dart';

import 'core/localization/l10n.dart';
import 'core/settings/app_settings_controller.dart';
import 'core/settings/app_settings_scope.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Kayıtlı dil/tema tercihi ilk karede uygulanır.
  final settings = await AppSettingsController.load();

  runApp(MenzilimApp(settings: settings));
}

class MenzilimApp extends StatelessWidget {
  final AppSettingsController settings;

  /// Testlerde farklı bir başlangıç ekranı verilebilir.
  final Widget home;

  const MenzilimApp({
    super.key,
    required this.settings,
    this.home = const LoginScreen(),
  });

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      controller: settings,
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => context.l10n.appName,
          locale: settings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: settings.themeMode,
          home: home,
        ),
      ),
    );
  }
}
