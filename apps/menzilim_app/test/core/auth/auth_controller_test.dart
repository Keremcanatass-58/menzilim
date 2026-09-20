import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:menzilim_app/core/auth/auth_controller.dart';
import 'package:menzilim_app/core/auth/jwt_token.dart';
import 'package:menzilim_app/core/network/api_client.dart';
import 'package:menzilim_app/core/storage/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Verilen bitiş zamanıyla imzasız ama biçimsel olarak geçerli bir JWT üretir.
String fakeJwt({required Duration expiresIn}) {
  String encode(Map<String, dynamic> part) =>
      base64Url.encode(utf8.encode(jsonEncode(part))).replaceAll('=', '');

  final exp = DateTime.now().toUtc().add(expiresIn).millisecondsSinceEpoch ~/ 1000;

  return '${encode({'alg': 'HS256', 'typ': 'JWT'})}'
      '.${encode({'sub': 'user-1', 'exp': exp})}'
      '.signature';
}

void main() {
  group('JwtToken', () {
    test('süresi geçmiş token için true döner', () {
      expect(JwtToken.isExpired(fakeJwt(expiresIn: const Duration(hours: -1))), isTrue);
    });

    test('geçerli token için false döner', () {
      expect(JwtToken.isExpired(fakeJwt(expiresIn: const Duration(hours: 1))), isFalse);
    });

    test('okunamayan token süresi dolmuş sayılmaz', () {
      expect(JwtToken.isExpired('not-a-jwt'), isFalse);
      expect(JwtToken.isExpired('a.b.c'), isFalse);
    });

    test('bitiş zamanını okur', () {
      final token = fakeJwt(expiresIn: const Duration(minutes: 30));
      final expiry = JwtToken.expiresAt(token);

      expect(expiry, isNotNull);
      expect(
        expiry!.difference(DateTime.now().toUtc()).inMinutes,
        closeTo(30, 1),
      );
    });
  });

  group('AuthController.restore', () {
    test('token yoksa oturum kapalı', () async {
      SharedPreferences.setMockInitialValues({});
      final auth = AuthController();

      await auth.restore();

      expect(auth.status, AuthStatus.unauthenticated);
      expect(auth.token, isNull);
    });

    test('geçerli token varsa oturum açık', () async {
      final token = fakeJwt(expiresIn: const Duration(hours: 2));
      SharedPreferences.setMockInitialValues({'auth_token': token});
      final auth = AuthController();

      await auth.restore();

      expect(auth.status, AuthStatus.authenticated);
      expect(auth.token, token);
    });

    test('süresi geçmiş token temizlenir ve oturum kapalı olur', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': fakeJwt(expiresIn: const Duration(minutes: -5)),
        'user_id': 'user-1',
      });
      final auth = AuthController();

      await auth.restore();

      expect(auth.status, AuthStatus.unauthenticated);
      expect(await TokenStorage().getToken(), isNull);
    });
  });

  group('AuthController oturum işlemleri', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('signIn token\'ı kaydeder ve durumu günceller', () async {
      final auth = AuthController();
      final token = fakeJwt(expiresIn: const Duration(hours: 1));
      var notified = 0;
      auth.addListener(() => notified++);

      await auth.signIn(token: token, userId: 'u1', email: 'a@b.c');

      expect(auth.isAuthenticated, isTrue);
      expect(notified, 1);

      final storage = TokenStorage();
      expect(await storage.getToken(), token);
      expect(await storage.getUserId(), 'u1');
      expect(await storage.getEmail(), 'a@b.c');
    });

    test('logout kaydı ve durumu temizler', () async {
      final auth = AuthController();
      await auth.signIn(
        token: fakeJwt(expiresIn: const Duration(hours: 1)),
        userId: 'u1',
        email: 'a@b.c',
      );

      await auth.logout();

      expect(auth.status, AuthStatus.unauthenticated);
      expect(auth.token, isNull);
      expect(await TokenStorage().getToken(), isNull);
    });

    test('oturum açıkken 401 oturumu kapatır', () async {
      final auth = AuthController();
      await auth.signIn(
        token: fakeJwt(expiresIn: const Duration(hours: 1)),
        userId: 'u1',
        email: 'a@b.c',
      );

      await auth.handleUnauthorized();

      expect(auth.status, AuthStatus.unauthenticated);
      expect(await TokenStorage().getToken(), isNull);
    });

    test('oturum kapalıyken 401 bir şey değiştirmez', () async {
      final auth = AuthController();
      await auth.restore();
      var notified = 0;
      auth.addListener(() => notified++);

      await auth.handleUnauthorized();

      expect(auth.status, AuthStatus.unauthenticated);
      expect(notified, 0);
    });
  });

  group('ApiClient 401 kancası', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));
    tearDown(() => ApiClient.onUnauthorized = null);

    test('oturumlu istekte 401 oturumu kapatır', () async {
      final auth = AuthController();
      await auth.signIn(
        token: fakeJwt(expiresIn: const Duration(hours: 1)),
        userId: 'u1',
        email: 'a@b.c',
      );
      auth.attachToApiClient();

      final client = ApiClient(
        client: MockClient(
          (_) async => http.Response('{"message":"Unauthorized"}', 401),
        ),
      );

      await expectLater(
        client.get('https://example.com/api/news/me', token: auth.token),
        throwsA(isA<ApiException>()),
      );
      // Kanca bekletmeden tetiklenir; oturum kapanışı bir sonraki turda biter.
      await Future<void>.delayed(Duration.zero);

      expect(auth.status, AuthStatus.unauthenticated);
    });

    test('giriş denemesindeki 401 oturumu etkilemez', () async {
      final auth = AuthController();
      await auth.signIn(
        token: fakeJwt(expiresIn: const Duration(hours: 1)),
        userId: 'u1',
        email: 'a@b.c',
      );
      auth.attachToApiClient();

      final client = ApiClient(
        client: MockClient((_) async => http.Response('', 401)),
      );

      // Token gönderilmeyen (giriş) isteği.
      await expectLater(
        client.post('https://example.com/api/auth/login', body: const {}),
        throwsA(isA<ApiException>()),
      );

      expect(auth.status, AuthStatus.authenticated);
    });

    test('kayıt doğrulama hatası (400) oturumu etkilemez', () async {
      final auth = AuthController();
      await auth.signIn(
        token: fakeJwt(expiresIn: const Duration(hours: 1)),
        userId: 'u1',
        email: 'a@b.c',
      );
      auth.attachToApiClient();

      final client = ApiClient(
        client: MockClient(
          (_) async => http.Response.bytes(
            utf8.encode('{"message":"Bu e-posta kayıtlı."}'),
            400,
          ),
        ),
      );

      await expectLater(
        client.post('https://example.com/api/auth/register', body: const {}),
        throwsA(isA<ApiException>()),
      );

      expect(auth.status, AuthStatus.authenticated);
    });
  });
}
