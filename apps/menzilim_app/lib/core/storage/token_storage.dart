import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _emailKey = 'user_email';

  Future<void> saveAuth({
    required String token,
    required String userId,
    required String email,
  }) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_tokenKey, token);
    await preferences.setString(_userIdKey, userId);
    await preferences.setString(_emailKey, email);
  }

  Future<String?> getToken() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getString(_tokenKey);
  }

  Future<String?> getUserId() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getString(_userIdKey);
  }

  Future<String?> getEmail() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getString(_emailKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();

    return token != null && token.isNotEmpty;
  }

  Future<void> clearAuth() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_tokenKey);
    await preferences.remove(_userIdKey);
    await preferences.remove(_emailKey);
  }
}