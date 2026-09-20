import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/onboarding_profile.dart';
import '../models/onboarding_request.dart';

class OnboardingService {
  final ApiClient _apiClient;

  OnboardingService(this._apiClient);

  Future<void> saveOnboarding(
    OnboardingRequest request,
    String token,
  ) async {
    await _apiClient.post(
      ApiConstants.onboarding,
      body: request.toJson(),
      token: token,
    );
  }

  /// Profil kimlikleriyle birlikte döner; onboarding yapılmamışsa null.
  Future<OnboardingProfile?> getProfile(String token) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.myOnboarding,
        token: token,
      );

      return OnboardingProfile.fromJson(response as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }

      rethrow;
    }
  }

  // Profil varsa true, backend 404 dönerse (onboarding yapılmamış) false.
  // Diğer hatalar çağırana iletilir.
  Future<bool> hasProfile(String token) async {
    try {
      await _apiClient.get(
        ApiConstants.myOnboarding,
        token: token,
      );

      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return false;
      }

      rethrow;
    }
  }
}
