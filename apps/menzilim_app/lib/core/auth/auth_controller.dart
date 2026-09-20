import 'package:flutter/foundation.dart';

import '../network/api_client.dart';
import '../storage/token_storage.dart';
import 'jwt_token.dart';

enum AuthStatus {
  /// Açılışta kayıtlı oturum okunuyor.
  initializing,

  /// Geçerli token var.
  authenticated,

  /// Token yok, süresi dolmuş veya oturum kapatıldı.
  unauthenticated,
}

/// Uygulama geneli oturum durumu. Token cihazda [TokenStorage] ile saklanır;
/// ekranlar token'ı yine oradan okur. Durum değişince dinleyiciler
/// (AuthGate ve MenzilimApp) yönlendirmeyi yapar.
class AuthController extends ChangeNotifier {
  final TokenStorage _tokenStorage;

  AuthStatus _status = AuthStatus.initializing;
  String? _token;

  AuthController({TokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? TokenStorage();

  AuthStatus get status => _status;
  String? get token => _token;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Açılışta kayıtlı token okunur; yoksa veya süresi geçmişse oturum
  /// kapalı sayılır ve kayıt temizlenir.
  Future<void> restore() async {
    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        _set(AuthStatus.unauthenticated, null);
        return;
      }

      if (JwtToken.isExpired(token)) {
        await _tokenStorage.clearAuth();
        _set(AuthStatus.unauthenticated, null);
        return;
      }

      _set(AuthStatus.authenticated, token);
    } catch (_) {
      // Depolama okunamazsa kullanıcı giriş ekranında kalır.
      _set(AuthStatus.unauthenticated, null);
    }
  }

  /// Başarılı giriş/kayıt sonrası oturumu kurar ve kalıcı hale getirir.
  Future<void> signIn({
    required String token,
    required String userId,
    required String email,
  }) async {
    await _tokenStorage.saveAuth(
      token: token,
      userId: userId,
      email: email,
    );

    _set(AuthStatus.authenticated, token);
  }

  /// Kullanıcının başlattığı çıkış.
  Future<void> logout() async {
    await _tokenStorage.clearAuth();
    _set(AuthStatus.unauthenticated, null);
  }

  /// Korumalı bir istek 401 döndüğünde çağrılır. Zaten oturum kapalıysa
  /// (ör. giriş denemesi başarısız) hiçbir şey yapılmaz.
  Future<void> handleUnauthorized() async {
    if (_status != AuthStatus.authenticated) return;

    await logout();
  }

  /// ApiClient'in 401 kancasını bu denetleyiciye bağlar.
  void attachToApiClient() {
    ApiClient.onUnauthorized = handleUnauthorized;
  }

  void _set(AuthStatus status, String? token) {
    if (_status == status && _token == token) return;

    _status = status;
    _token = token;
    notifyListeners();
  }
}
