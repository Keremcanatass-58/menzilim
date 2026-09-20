import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  /// Oturumlu bir istek 401 dönerse çağrılır (AuthController bağlar).
  /// Token gönderilmeyen isteklerde (giriş/kayıt) tetiklenmez.
  static Future<void> Function()? onUnauthorized;

  /// Testlerde sahte istemci verilebilir; normalde http paketi kullanılır.
  final http.Client? _client;

  ApiClient({this._client});

  Future<dynamic> get(
    String endpoint, {
    String? token,
  }) async {
    final uri = Uri.parse(endpoint);
    final headers = _headers(token);

    final response = _client == null
        ? await http.get(uri, headers: headers)
        : await _client.get(uri, headers: headers);

    return _handleResponse(response, token);
  }

  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final uri = Uri.parse(endpoint);
    final headers = _headers(token);
    final payload = body == null ? null : jsonEncode(body);

    final response = _client == null
        ? await http.post(uri, headers: headers, body: payload)
        : await _client.post(uri, headers: headers, body: payload);

    return _handleResponse(response, token);
  }

  Map<String, String> _headers(String? token) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  dynamic _handleResponse(http.Response response, String? token) {
    final data = response.body.isEmpty
        ? null
        : jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    // Oturum süresi dolmuş/geçersiz: uygulama girişe döner. Giriş denemesinin
    // 401'i (token'sız istek) bu akışı tetiklemez.
    if (response.statusCode == 401 && token != null && token.isNotEmpty) {
      onUnauthorized?.call();
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Bir hata oluştu.',
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}
