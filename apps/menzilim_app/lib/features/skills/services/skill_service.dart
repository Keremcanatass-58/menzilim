import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/skill_progress_response.dart';

class SkillService {
  final ApiClient _apiClient;

  SkillService(this._apiClient);

  Future<List<SkillProgressResponse>> getMySkills(String token) async {
    final response = await _apiClient.get(
      '${ApiConstants.baseUrl}/api/skills/me',
      token: token,
    );

    final data = response as List<dynamic>;

    return data
        .map(
          (item) => SkillProgressResponse.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}
