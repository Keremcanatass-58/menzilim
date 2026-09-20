import 'dart:convert';

/// JWT'nin `exp` (bitiş) alanını yerel olarak okur. İmza doğrulaması
/// backend'in işidir; burada yalnızca süresi geçmiş token'ı kullanmamak için
/// bakılır.
class JwtToken {
  JwtToken._();

  /// Saat farkları için küçük bir tolerans.
  static const Duration leeway = Duration(seconds: 30);

  /// Token okunamıyorsa veya `exp` yoksa süresi dolmuş sayılmaz; asıl karar
  /// yine sunucunun 401 yanıtıyla verilir.
  static bool isExpired(String token, {DateTime? now}) {
    final expiry = expiresAt(token);
    if (expiry == null) return false;

    final moment = now ?? DateTime.now().toUtc();

    return expiry.isBefore(moment.subtract(leeway));
  }

  static DateTime? expiresAt(String token) {
    final payload = _payload(token);
    final exp = payload?['exp'];

    if (exp is! int) return null;

    return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
  }

  static Map<String, dynamic>? _payload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    try {
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final json = jsonDecode(decoded);

      return json is Map<String, dynamic> ? json : null;
    } catch (_) {
      return null;
    }
  }
}
