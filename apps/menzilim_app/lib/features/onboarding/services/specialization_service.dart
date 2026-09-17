import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/specialization.dart';

class SpecializationService {
  final ApiClient _apiClient;

  SpecializationService(this._apiClient);

  Future<List<Specialization>> getSpecializations(
    String professionId,
  ) async {
    final response = await _apiClient.get(
      ApiConstants.specializations(professionId),
    );

    final items = response is List
        ? response
        : response['value'] as List<dynamic>;

    return items
        .map(
          (item) => Specialization.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}