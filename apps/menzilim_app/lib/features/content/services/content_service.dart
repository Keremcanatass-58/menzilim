import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/content_response.dart';

class ContentService {
  final ApiClient _apiClient;

  ContentService(this._apiClient);

  Future<List<ContentResponse>> getMyContent(String token) async {
    final response = await _apiClient.get(
      '${ApiConstants.baseUrl}/api/content/me',
      token: token,
    );

    final data = response as List<dynamic>;

    return data
        .map(
          (item) => ContentResponse.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<ContentResponse> getById(
    String token,
    String contentId,
  ) async {
    final response = await _apiClient.get(
      '${ApiConstants.baseUrl}/api/content/$contentId',
      token: token,
    );

    return ContentResponse.fromJson(
      response as Map<String, dynamic>,
    );
  }

  Future<Map<String, dynamic>> getProgress(
    String token,
    String contentId,
  ) async {
    final response = await _apiClient.get(
      '${ApiConstants.baseUrl}/api/content/$contentId/progress',
      token: token,
    );

    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> startContent(
    String token,
    String contentId,
  ) async {
    final response = await _apiClient.post(
      '${ApiConstants.baseUrl}/api/content/$contentId/start',
      token: token,
    );

    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> completeContent(
    String token,
    String contentId,
  ) async {
    final response = await _apiClient.post(
      '${ApiConstants.baseUrl}/api/content/$contentId/complete',
      token: token,
    );

    return response as Map<String, dynamic>;
  }
}