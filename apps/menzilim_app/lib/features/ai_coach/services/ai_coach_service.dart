import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/ai_coach_models.dart';

class AiCoachService {
  final ApiClient _apiClient;

  AiCoachService(this._apiClient);

  Future<AiCoachResponse> ask(
    String token,
    String prompt,
  ) async {
    final response = await _apiClient.post(
      ApiConstants.aiCoachAsk,
      body: AiCoachAskRequest(prompt: prompt).toJson(),
      token: token,
    );

    return AiCoachResponse.fromJson(
      response as Map<String, dynamic>,
    );
  }
}
