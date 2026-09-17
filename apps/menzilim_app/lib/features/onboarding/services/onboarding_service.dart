import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
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
}
