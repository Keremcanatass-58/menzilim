import 'package:flutter_test/flutter_test.dart';
import 'package:menzilim_app/features/content/models/content_recommendation_response.dart';

void main() {
  group('ContentRecommendationResponse.fromJson', () {
    test('API yanıtındaki tüm alanları okur', () {
      final response = ContentRecommendationResponse.fromJson({
        'contentId': '18f104e8-34a9-4a21-972e-c5467451468c',
        'title': 'ASP.NET Core Web API Development',
        'description': 'Learn the basics of building Web APIs.',
        'url': 'https://learn.microsoft.com/aspnet/core/web-api/',
        'isStarted': true,
        'isCompleted': false,
        'recommendationReason':
            'Uzmanlığın Backend ile ilgili bu içeriğe başlamışsın, '
            'kaldığın yerden devam edebilirsin.',
      });

      expect(response.contentId, '18f104e8-34a9-4a21-972e-c5467451468c');
      expect(response.title, 'ASP.NET Core Web API Development');
      expect(response.description, 'Learn the basics of building Web APIs.');
      expect(
        response.url,
        'https://learn.microsoft.com/aspnet/core/web-api/',
      );
      expect(response.isStarted, isTrue);
      expect(response.isCompleted, isFalse);
      expect(
        response.recommendationReason,
        'Uzmanlığın Backend ile ilgili bu içeriğe başlamışsın, '
        'kaldığın yerden devam edebilirsin.',
      );
    });

    test('eksik veya null alanlarda güvenli varsayılanlar kullanır', () {
      final response = ContentRecommendationResponse.fromJson({
        'contentId': null,
        'description': null,
      });

      expect(response.contentId, '');
      expect(response.title, '');
      expect(response.description, isNull);
      expect(response.url, '');
      expect(response.isStarted, isFalse);
      expect(response.isCompleted, isFalse);
      expect(response.recommendationReason, '');
    });
  });
}
