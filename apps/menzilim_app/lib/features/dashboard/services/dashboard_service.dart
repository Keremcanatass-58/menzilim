import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/dashboard_response.dart';

class DashboardService {
  final ApiClient _apiClient;

  DashboardService(this._apiClient);

  Future<DashboardResponse> getDashboard(String token) async {
    final response = await _apiClient.get(
      ApiConstants.dashboard,
      token: token,
    );

    return DashboardResponse.fromJson(
      response as Map<String, dynamic>,
    );
  }
}
