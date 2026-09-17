import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  Future<dynamic> get(
    String endpoint, {
    String? token,
  }) async {
    final response = await http.get(
      Uri.parse(endpoint),
      headers: _headers(token),
    );

    return _handleResponse(response);
  }

  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final response = await http.post(
      Uri.parse(endpoint),
      headers: _headers(token),
      body: body == null ? null : jsonEncode(body),
    );

    return _handleResponse(response);
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

  dynamic _handleResponse(http.Response response) {
    final data = response.body.isEmpty
        ? null
        : jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
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
