import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/user_project.dart';

class ProjectService {
  final ApiClient _apiClient;

  ProjectService(this._apiClient);

  /// Kullanıcının projeleri. Uzmanlığa uygun şablon varsa proje ilk çağrıda
  /// backend tarafından oluşturulur.
  Future<List<UserProject>> getMyProjects(String token) async {
    final response = await _apiClient.get(
      ApiConstants.myProjects,
      token: token,
    );

    final data = response as List<dynamic>;

    return data
        .map((item) => UserProject.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Adımı tamamlar ve güncellenmiş projeyi döner.
  Future<UserProject> completeStep(String token, String stepId) async {
    final response = await _apiClient.post(
      ApiConstants.completeProjectStep(stepId),
      token: token,
      body: const <String, dynamic>{},
    );

    return UserProject.fromJson(response as Map<String, dynamic>);
  }

  /// Adımın çıktısını (bağlantı ve not) kaydeder; ikisi de boş bırakılabilir.
  Future<UserProject> updateStepEvidence(
    String token,
    String stepId, {
    String? evidenceUrl,
    String? note,
  }) async {
    final response = await _apiClient.put(
      ApiConstants.projectStepEvidence(stepId),
      token: token,
      body: {
        'evidenceUrl': evidenceUrl,
        'note': note,
      },
    );

    return UserProject.fromJson(response as Map<String, dynamic>);
  }
}
