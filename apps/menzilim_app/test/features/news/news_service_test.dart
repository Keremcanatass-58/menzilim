import 'package:flutter_test/flutter_test.dart';
import 'package:menzilim_app/core/constants/api_constants.dart';
import 'package:menzilim_app/core/network/api_client.dart';
import 'package:menzilim_app/features/news/services/news_service.dart';

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
  group('NewsService.getMyNews', () {
    test('GET /api/news/me çağırır ve sırayı koruyarak dönüştürür', () async {
      final client = _FakeApiClient(() async => [
            {
              'id': 'a',
              'title': 'Birinci',
              'summary': 'Özet 1',
              'sourceName': 'React Blog',
              'sourceUrl': 'https://react.dev/blog/2025/10/01/react-19-2',
              'publishedAt': '2025-10-01T00:00:00',
              'imageUrl': null,
            },
            {
              'id': 'b',
              'title': 'İkinci',
              'summary': 'Özet 2',
              'sourceName': 'Node.js Blog',
              'sourceUrl': 'https://nodejs.org/en/blog/release/v24.0.0',
              'publishedAt': '2025-05-06T00:00:00',
              'imageUrl': null,
            },
          ]);

      final news = await NewsService(client).getMyNews('token-1');

      expect(client.lastEndpoint, ApiConstants.myNews);
      expect(client.lastEndpoint, endsWith('/api/news/me'));
      expect(client.lastToken, 'token-1');
      expect(news.map((n) => n.id), ['a', 'b']);
      expect(news.first.sourceName, 'React Blog');
    });

    test('boş liste döner', () async {
      final news =
          await NewsService(_FakeApiClient(() async => [])).getMyNews('t');

      expect(news, isEmpty);
    });

    test('API hatasını ApiException olarak iletir', () async {
      final client = _FakeApiClient(() async =>
          throw ApiException(statusCode: 401, message: 'Yetkisiz'));

      expect(
        () => NewsService(client).getMyNews('t'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
