import 'package:flutter/material.dart';

import 'core/auth/auth_controller.dart';
import 'core/auth/auth_scope.dart';
import 'core/localization/l10n.dart';
import 'core/settings/app_settings_controller.dart';
import 'core/settings/app_settings_scope.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Kayıtlı dil/tema tercihi ilk karede uygulanır.
  final settings = await AppSettingsController.load();
  final auth = AuthController();

  runApp(MenzilimApp(settings: settings, auth: auth));
}

class MenzilimApp extends StatefulWidget {
  final AppSettingsController settings;

  /// Oturum durumu. Verilmezse (testlerde) yeni bir denetleyici oluşturulur.
  final AuthController? auth;

  /// Testlerde farklı bir başlangıç ekranı verilebilir.
  final Widget? home;

  const MenzilimApp({
    super.key,
    required this.settings,
    this.auth,
    this.home,
  });

  @override
  State<MenzilimApp> createState() => _MenzilimAppState();
}

class _MenzilimAppState extends State<MenzilimApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  late final AuthController _auth = widget.auth ?? AuthController();

  @override
  void initState() {
    super.initState();

    // 401 gelen korumalı istekler oturumu kapatır.
    _auth.attachToApiClient();
    _auth.addListener(_onAuthChanged);

    if (_auth.status == AuthStatus.initializing) {
      _auth.restore();
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  /// Oturum durumu değişince açık ekranlar kapatılır ve AuthGate'e dönülür:
  /// çıkışta geri tuşuyla eski verilere dönülemez, girişte (ör. Kayıt Ol
  /// ekranından) yönlendirmeyi AuthGate yapabilir.
  void _onAuthChanged() {
    if (_auth.status == AuthStatus.initializing) return;

    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      controller: widget.settings,
      child: AuthScope(
        controller: _auth,
        child: ListenableBuilder(
          listenable: widget.settings,
          builder: (context, _) => MaterialApp(
            navigatorKey: _navigatorKey,
            debugShowCheckedModeBanner: false,
            onGenerateTitle: (context) => context.l10n.appName,
            locale: widget.settings.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: widget.settings.themeMode,
            home: widget.home ?? const AuthGate(),
          ),
        ),
      ),
    );
  }
}
