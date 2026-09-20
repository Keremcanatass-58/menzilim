import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/auth/auth_scope.dart';
import '../../../core/design/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/screens/main_shell.dart';
import '../../onboarding/screens/onboarding_screen.dart';
import '../../onboarding/screens/path_intro_screen.dart';
import '../../onboarding/services/onboarding_service.dart';
import 'login_screen.dart';

/// Uygulamanın giriş noktası: oturum durumuna göre açılış ekranını seçer.
///   initializing  → kısa açılış ekranı
///   unauthenticated → Login
///   authenticated → onboarding profili varsa Dashboard, yoksa Onboarding
class AuthGate extends StatefulWidget {
  /// Testlerde sahte servis verilebilir.
  final OnboardingService? onboardingService;

  const AuthGate({super.key, this.onboardingService});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final OnboardingService _onboardingService =
      widget.onboardingService ?? OnboardingService(ApiClient());

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    return switch (auth.status) {
      AuthStatus.initializing => const AuthSplashScreen(),
      AuthStatus.unauthenticated => const LoginScreen(),
      AuthStatus.authenticated => _OnboardingRouter(
          // Token değişince (yeni giriş) kontrol yeniden yapılır.
          key: ValueKey(auth.token),
          token: auth.token!,
          onboardingService: _onboardingService,
        ),
    };
  }
}

/// Oturum açık: kullanıcı onboarding'i tamamlamış mı?
class _OnboardingRouter extends StatefulWidget {
  final String token;
  final OnboardingService onboardingService;

  const _OnboardingRouter({
    super.key,
    required this.token,
    required this.onboardingService,
  });

  @override
  State<_OnboardingRouter> createState() => _OnboardingRouterState();
}

class _OnboardingRouterState extends State<_OnboardingRouter> {
  late Future<bool> _hasProfile = _check();

  /// Onboarding bu oturumda tamamlandıysa önce "İşte senin yolun" gösterilir.
  bool _showPathIntro = false;

  Future<bool> _check() async {
    try {
      return await widget.onboardingService.hasProfile(widget.token);
    } catch (_) {
      // Profil kontrolü yapılamazsa onboarding'e düşülür (mevcut davranış).
      // 401 ise ApiClient kancası zaten oturumu kapatır.
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasProfile,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AuthSplashScreen();
        }

        if (snapshot.data != true) {
          return OnboardingScreen(
            // Onboarding bitti: profil kontrolü yenilenir, sonraki ekrana
            // geçişi bu yapı yapar.
            onCompleted: () {
              setState(() {
                _showPathIntro = true;
                _hasProfile = _check();
              });
            },
          );
        }

        if (_showPathIntro) {
          return PathIntroScreen(
            onStart: () {
              setState(() {
                _showPathIntro = false;
              });
            },
          );
        }

        return const MainShell();
      },
    );
  }
}

/// Oturum okunurken gösterilen kısa açılış ekranı (marka + yükleniyor).
class AuthSplashScreen extends StatelessWidget {
  const AuthSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MenzilimLogoMark(size: 64, boxed: true),
            const SizedBox(height: AppSpacing.lg),
            MenzilimWordmark(style: context.textStyles.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.appTagline,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
