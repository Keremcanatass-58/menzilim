import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/daily_plan_response.dart';

class DailyPlanService {
  final ApiClient _apiClient;

  DailyPlanService(this._apiClient);

  Future<DailyPlanResponse> getToday(String token) async {
    final response = await _apiClient.get(
      ApiConstants.dailyPlan,
      token: token,
    );

    return DailyPlanResponse.fromJson(
      response as Map<String, dynamic>,
    );
  }

  Future<DailyPlanResponse> completeTask(
    String token,
    String taskId,
  ) async {
    final response = await _apiClient.post(
      '${ApiConstants.baseUrl}/api/daily-plan/tasks/$taskId/complete',
      token: token,
    );

    return DailyPlanResponse.fromJson(
      response as Map<String, dynamic>,
    );
  }
}
