import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menzilim_app/core/auth/auth_controller.dart';
import 'package:menzilim_app/core/design/design_system.dart';
import 'package:menzilim_app/core/network/api_client.dart';
import 'package:menzilim_app/core/settings/app_settings_controller.dart';
import 'package:menzilim_app/core/storage/token_storage.dart';
import 'package:menzilim_app/features/auth/models/auth_response.dart';
import 'package:menzilim_app/features/auth/models/login_request.dart';
import 'package:menzilim_app/features/auth/models/register_request.dart';
import 'package:menzilim_app/features/auth/screens/auth_gate.dart';
import 'package:menzilim_app/features/auth/screens/login_screen.dart';
import 'package:menzilim_app/features/auth/screens/register_screen.dart';
import 'package:menzilim_app/features/auth/services/auth_service.dart';
import 'package:menzilim_app/features/home/screens/main_shell.dart';
import 'package:menzilim_app/features/onboarding/screens/path_intro_screen.dart';
import 'package:menzilim_app/features/onboarding/screens/onboarding_screen.dart';
import 'package:menzilim_app/features/onboarding/services/onboarding_service.dart';
import 'package:menzilim_app/features/settings/screens/settings_screen.dart';
import 'package:menzilim_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/auth/auth_controller_test.dart' show fakeJwt;

class _FakeOnboardingService extends OnboardingService {
  /// Onboarding kaydedildikten sonra değişebilir.
  bool hasProfileResult;

  _FakeOnboardingService({this.hasProfileResult = true}) : super(ApiClient());

  @override
  Future<bool> hasProfile(String token) async {
    return hasProfileResult;
  }
}

class _FakeAuthService extends AuthService {
  final AuthResponse? response;
  final Object? error;

  _FakeAuthService({this.response, this.error}) : super(ApiClient());

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    if (error != null) throw error!;
    return response!;
  }

  @override
  Future<AuthResponse> register(RegisterRequest request) async {
    if (error != null) throw error!;
    return response!;
  }
}

AuthResponse _authResponse(String token) => AuthResponse(
      token: token,
      userId: 'user-1',
      email: 'test@menzilim.test',
    );

Widget _app({
  required AuthController auth,
  Widget? home,
}) {
  return MenzilimApp(
    settings: AppSettingsController(),
    auth: auth,
    home: home,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.onUnauthorized = null;
  });

  group('Uygulama açılışı', () {
    testWidgets('token yoksa Login açılır', (tester) async {
      await tester.pumpWidget(
        _app(
          auth: AuthController(),
          home: AuthGate(onboardingService: _FakeOnboardingService()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(MainShell), findsNothing);
    });

    testWidgets('geçerli token ve onboarding varsa Dashboard açılır',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'auth_token': fakeJwt(expiresIn: const Duration(hours: 2)),
      });

      await tester.pumpWidget(
        _app(
          auth: AuthController(),
          home: AuthGate(
            onboardingService: _FakeOnboardingService(hasProfileResult: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MainShell), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('geçerli token ama onboarding yoksa Onboarding açılır',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'auth_token': fakeJwt(expiresIn: const Duration(hours: 2)),
      });

      await tester.pumpWidget(
        _app(
          auth: AuthController(),
          home: AuthGate(
            onboardingService: _FakeOnboardingService(hasProfileResult: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('süresi geçmiş token temizlenir ve Login açılır',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'auth_token': fakeJwt(expiresIn: const Duration(hours: -1)),
        'user_id': 'user-1',
      });

      await tester.pumpWidget(
        _app(
          auth: AuthController(),
          home: AuthGate(onboardingService: _FakeOnboardingService()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(await TokenStorage().getToken(), isNull);
    });
  });

  group('Giriş', () {
    testWidgets('başarılı giriş oturumu kurar ve token saklanır',
        (tester) async {
      final auth = AuthController();
      await auth.restore();
      final token = fakeJwt(expiresIn: const Duration(hours: 1));

      await tester.pumpWidget(
        _app(
          auth: auth,
          home: LoginScreen(
            authService: _FakeAuthService(response: _authResponse(token)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).first,
        'test@menzilim.test',
      );
      await tester.enterText(find.byType(TextField).last, 'Test1234!');
      await tester.tap(find.text('Giriş Yap'));
      await tester.pumpAndSettle();

      expect(auth.isAuthenticated, isTrue);
      expect(await TokenStorage().getToken(), token);
    });

    testWidgets('giriş 401 alırsa oturum açılmaz ve hata gösterilir',
        (tester) async {
      final auth = AuthController();
      await auth.restore();
      auth.attachToApiClient();

      await tester.pumpWidget(
        _app(
          auth: auth,
          home: LoginScreen(
            authService: _FakeAuthService(
              error: ApiException(statusCode: 401, message: 'Yetkisiz'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'a@b.c');
      await tester.enterText(find.byType(TextField).last, 'yanlis');
      await tester.tap(find.text('Giriş Yap'));
      await tester.pumpAndSettle();

      expect(auth.status, AuthStatus.unauthenticated);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(
        find.text('Giriş yapılamadı. E-posta veya şifreyi kontrol et.'),
        findsOneWidget,
      );
      expect(await TokenStorage().getToken(), isNull);
    });

    testWidgets('kayıt sonrası onboarding akışı korunur', (tester) async {
      final auth = AuthController();
      await auth.restore();
      final token = fakeJwt(expiresIn: const Duration(hours: 1));

      await tester.pumpWidget(
        _app(
          auth: auth,
          home: RegisterScreen(
            authService: _FakeAuthService(response: _authResponse(token)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'yeni@menzilim.test');
      await tester.enterText(fields.at(1), 'Test1234!');
      await tester.enterText(fields.at(2), 'Test1234!');
      final registerButton = find.text('Hesap Oluştur');
      await tester.ensureVisible(registerButton);
      await tester.pumpAndSettle();
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      expect(auth.isAuthenticated, isTrue);

      // Yeni hesapta profil yoktur: AuthGate Onboarding'e yönlendirir.
      await tester.pumpWidget(
        _app(
          auth: auth,
          home: AuthGate(
            onboardingService: _FakeOnboardingService(hasProfileResult: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('Login üstünde açılan kayıt ekranı oturum açılınca kapanır',
        (tester) async {
      final auth = AuthController();
      await auth.restore();

      await tester.pumpWidget(
        _app(
          auth: auth,
          home: AuthGate(
            onboardingService: _FakeOnboardingService(hasProfileResult: false),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);

      await tester.tap(find.text('Kayıt Ol'));
      await tester.pumpAndSettle();
      expect(find.byType(RegisterScreen), findsOneWidget);

      // Kayıt başarılı: AuthGate altta kaldığı için yönlendirme yapılabilir.
      await auth.signIn(
        token: fakeJwt(expiresIn: const Duration(hours: 1)),
        userId: 'user-1',
        email: 'yeni@menzilim.test',
      );
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsNothing);
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('onboarding tamamlanınca önce yol ekranı, sonra ana kabuk açılır',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'auth_token': fakeJwt(expiresIn: const Duration(hours: 2)),
      });
      final auth = AuthController();
      final onboardingService =
          _FakeOnboardingService(hasProfileResult: false);

      await tester.pumpWidget(
        _app(auth: auth, home: AuthGate(onboardingService: onboardingService)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);

      // Onboarding kaydedildi: profil artık var.
      onboardingService.hasProfileResult = true;
      tester
          .widget<OnboardingScreen>(find.byType(OnboardingScreen))
          .onCompleted!();
      await tester.pumpAndSettle();

      // Önce "İşte senin yolun" ekranı gösterilir.
      expect(find.byType(PathIntroScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);

      await tester.tap(find.text('Yolculuğa Başla'));
      await tester.pumpAndSettle();

      expect(find.byType(MainShell), findsOneWidget);

      // Kabuğu AuthGate gösterdiği için çıkışta Login'e dönülür.
      await auth.logout();
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(MainShell), findsNothing);
    });
  });

  group('Oturum kapatma', () {
    testWidgets('Ayarlar\'dan çıkış Login\'e döner ve yığını temizler',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'auth_token': fakeJwt(expiresIn: const Duration(hours: 2)),
      });
      final auth = AuthController();

      await tester.pumpWidget(
        _app(
          auth: auth,
          home: AuthGate(
            onboardingService: _FakeOnboardingService(hasProfileResult: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MainShell), findsOneWidget);

      // Dashboard'un üstüne ayarlar açılır (uygulamadaki gibi push ile).
      tester.state<NavigatorState>(find.byType(Navigator).last).push(
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);

      // Çıkış bölümü listenin altında; ayarlar listesi kaydırılır.
      await tester.scrollUntilVisible(
        find.widgetWithText(MenzilimButton, 'Çıkış Yap'),
        200,
        scrollable: find.descendant(
          of: find.byType(SettingsScreen),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.ensureVisible(
        find.widgetWithText(MenzilimButton, 'Çıkış Yap'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(MenzilimButton, 'Çıkış Yap'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      // Yığın temizlendi: geri dönülebilecek Dashboard/Ayarlar yok.
      expect(find.byType(SettingsScreen), findsNothing);
      expect(find.byType(MainShell), findsNothing);
      expect(await TokenStorage().getToken(), isNull);
    });

    testWidgets('korumalı istekte 401 oturumu kapatır ve Login açılır',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'auth_token': fakeJwt(expiresIn: const Duration(hours: 2)),
      });
      final auth = AuthController();

      await tester.pumpWidget(
        _app(
          auth: auth,
          home: AuthGate(
            onboardingService: _FakeOnboardingService(hasProfileResult: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MainShell), findsOneWidget);

      // Korumalı bir çağrı 401 döndü.
      await ApiClient.onUnauthorized!();
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(MainShell), findsNothing);
      expect(await TokenStorage().getToken(), isNull);
    });
  });
}
