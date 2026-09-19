import 'package:flutter_test/flutter_test.dart';
import 'package:menzilim_app/core/constants/api_constants.dart';
import 'package:menzilim_app/core/network/api_client.dart';
import 'package:menzilim_app/features/onboarding/services/profession_service.dart';

/// Gerçek HTTP yapmadan ApiClient.get'i taklit eder; test çalışan bir
/// backend'e bağlı kalmaz.
class _FakeApiClient extends ApiClient {
  final dynamic response;
  String? lastEndpoint;

  _FakeApiClient(this.response);

  @override
  Future<dynamic> get(String endpoint, {String? token}) async {
    lastEndpoint = endpoint;
    return response;
  }
}

void main() {
  test('GET /api/professions listesini dönüştürür', () async {
    final client = _FakeApiClient([
      {'id': 'p1', 'name': 'Yazılım Geliştirici', 'description': 'Yazılım'},
      {'id': 'p2', 'name': 'Siber Güvenlik', 'description': 'Güvenlik'},
    ]);

    final professions = await ProfessionService(client).getProfessions();

    expect(client.lastEndpoint, ApiConstants.professions);
    expect(professions.map((p) => p.name),
        ['Yazılım Geliştirici', 'Siber Güvenlik']);
  });

  test('"value" ile sarılmış yanıtı da okur', () async {
    final client = _FakeApiClient({
      'value': [
        {'id': 'p1', 'name': 'Veri Uzmanı', 'description': 'Veri'},
      ],
    });

    final professions = await ProfessionService(client).getProfessions();

    expect(professions, hasLength(1));
    expect(professions.single.id, 'p1');
  });
}
