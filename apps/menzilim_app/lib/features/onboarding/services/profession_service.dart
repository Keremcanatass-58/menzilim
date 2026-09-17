import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/profession.dart';

class ProfessionService {
  final ApiClient _apiClient;

  ProfessionService(this._apiClient);

  Future<List<Profession>> getProfessions() async {
    final response = await _apiClient.get(ApiConstants.professions);

    final items = response is List
        ? response
        : response['value'] as List<dynamic>;

    return items
        .map((item) => Profession.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}