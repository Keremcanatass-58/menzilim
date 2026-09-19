import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/progress_response.dart';

class ProgressService {
  final ApiClient _apiClient;

  ProgressService(this._apiClient);

  Future<ProgressResponse> getMyProgress(String token) async {
    final response = await _apiClient.get(
      ApiConstants.progress,
      token: token,
    );

    return ProgressResponse.fromJson(
      response as Map<String, dynamic>,
    );
  }
}