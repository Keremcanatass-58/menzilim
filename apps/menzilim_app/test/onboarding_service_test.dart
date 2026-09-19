import 'package:flutter_test/flutter_test.dart';
import 'package:menzilim_app/core/constants/api_constants.dart';
import 'package:menzilim_app/core/network/api_client.dart';
import 'package:menzilim_app/features/onboarding/services/onboarding_service.dart';

/// Gerçek HTTP yapmadan ApiClient.get'i taklit eder.
class _FakeApiClient extends ApiClient {
  final Future<dynamic> Function() handler;
  String? lastEndpoint;
  String? lastToken;

  _FakeApiClient(this.handler);

  @override
  Future<dynamic> get(String endpoint, {String? token}) {
    lastEndpoint = endpoint;
    lastToken = token;
    return handler();
  }
}

void main() {
  group('OnboardingService.hasProfile', () {
    test('profil varsa true döner ve GET /api/onboarding/me çağırır', () async {
      final client = _FakeApiClient(() async => {
            'userId': 'u',
            'professionId': 'p',
            'specializationId': 's',
          });

      final result = await OnboardingService(client).hasProfile('token-1');

      expect(result, isTrue);
      expect(client.lastEndpoint, ApiConstants.myOnboarding);
      expect(client.lastToken, 'token-1');
    });

    test('404 dönerse (onboarding yapılmamış) false döner', () async {
      final client = _FakeApiClient(() async => throw ApiException(
            statusCode: 404,
            message: 'Onboarding profili bulunamadı.',
          ));

      final result = await OnboardingService(client).hasProfile('token-1');

      expect(result, isFalse);
    });

    test('diğer API hatalarını iletir', () async {
      final client = _FakeApiClient(() async => throw ApiException(
            statusCode: 500,
            message: 'Bir hata oluştu.',
          ));

      expect(
        () => OnboardingService(client).hasProfile('token-1'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
