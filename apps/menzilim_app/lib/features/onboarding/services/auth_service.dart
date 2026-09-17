import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/auth_response.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  Future<AuthResponse> register(RegisterRequest request) async {
    final response = await _apiClient.post(
      ApiConstants.register,
      body: request.toJson(),
    );

    return AuthResponse.fromJson(
      response as Map<String, dynamic>,
    );
  }

  Future<AuthResponse> login(LoginRequest request) async {
    final response = await _apiClient.post(
      ApiConstants.login,
      body: request.toJson(),
    );

    return AuthResponse.fromJson(
      response as Map<String, dynamic>,
    );
  }
}