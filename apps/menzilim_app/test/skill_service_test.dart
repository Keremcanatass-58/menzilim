import 'package:flutter_test/flutter_test.dart';
import 'package:menzilim_app/core/constants/api_constants.dart';
import 'package:menzilim_app/core/network/api_client.dart';
import 'package:menzilim_app/features/skills/services/skill_service.dart';

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
  group('SkillService.getMySkills', () {
    test('GET /api/skills/me çağırır ve listeyi dönüştürür', () async {
      final client = _FakeApiClient(() async => [
            {
              'skillId': 'a',
              'skillName': 'ASP.NET Core',
              'category': 'Web',
              'progressPercent': 50,
              'totalContentCount': 1,
              'completedContentCount': 1,
              'inProgressContentCount': 0,
              'totalQuizCount': 1,
              'attemptedQuizCount': 0,
              'quizAttemptCount': 0,
              'bestQuizScore': null,
              'latestQuizScore': null,
            },
            {
              'skillId': 'b',
              'skillName': 'SQL',
              'category': 'Veritabanı',
              'progressPercent': 0,
              'totalContentCount': 0,
              'completedContentCount': 0,
              'inProgressContentCount': 0,
              'totalQuizCount': 0,
              'attemptedQuizCount': 0,
              'quizAttemptCount': 0,
              'bestQuizScore': null,
              'latestQuizScore': null,
            },
          ]);

      final skills = await SkillService(client).getMySkills('jwt-token');

      expect(client.lastEndpoint, '${ApiConstants.baseUrl}/api/skills/me');
      expect(client.lastToken, 'jwt-token');
      expect(skills.map((s) => s.skillName), ['ASP.NET Core', 'SQL']);
      expect(skills.first.progressPercent, 50);
      expect(skills.last.category, 'Veritabanı');
    });

    test('boş liste döner', () async {
      final client = _FakeApiClient(() async => <dynamic>[]);

      final skills = await SkillService(client).getMySkills('jwt-token');

      expect(skills, isEmpty);
    });

    test('API hatasını ApiException olarak iletir', () async {
      final client = _FakeApiClient(() async => throw ApiException(
            statusCode: 404,
            message: 'Kullanıcı profili bulunamadı.',
          ));

      expect(
        () => SkillService(client).getMySkills('jwt-token'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.message, 'message', 'Kullanıcı profili bulunamadı.'),
        ),
      );
    });
  });
}
