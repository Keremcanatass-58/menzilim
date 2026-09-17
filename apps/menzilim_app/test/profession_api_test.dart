import 'package:flutter_test/flutter_test.dart';
import 'package:menzilim_app/core/network/api_client.dart';
import 'package:menzilim_app/features/onboarding/services/profession_service.dart';

void main() {
  test('API professions endpoint test', () async {
    final apiClient = ApiClient();
    final professionService = ProfessionService(apiClient);

    final professions = await professionService.getProfessions();

    expect(professions, isNotEmpty);
  });
}