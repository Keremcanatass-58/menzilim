import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menzilim_app/core/network/api_client.dart';
import 'package:menzilim_app/features/news/models/news_item.dart';
import 'package:menzilim_app/features/news/screens/news_screen.dart';
import 'package:menzilim_app/features/news/services/news_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeNewsService extends NewsService {
  final List<Future<List<NewsItem>> Function()> responses;
  int calls = 0;

  _FakeNewsService(this.responses) : super(ApiClient());

  @override
  Future<List<NewsItem>> getMyNews(String token) {
    final response = responses[calls.clamp(0, responses.length - 1)];
    calls++;
    return response();
  }
}

NewsItem _news(
  String id, {
  String title = 'Başlık',
  String summary = 'Kısa özet',
  String sourceName = '.NET Blog',
  String sourceUrl = 'https://devblogs.microsoft.com/dotnet/announcing-dotnet-10/',
}) =>
    NewsItem(
      id: id,
      title: title,
      summary: summary,
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      publishedAt: DateTime(2025, 11, 11),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': 'test-token'});
  });

  testWidgets('haber kartlarını kaynak, tarih, başlık, özet ve adresle gösterir',
      (tester) async {
    final service = _FakeNewsService([
      () async => [
            _news('1', title: '.NET 10 yayınlandı', summary: 'LTS sürümü'),
            _news(
              '2',
              title: 'React 19.2 yayınlandı',
              sourceName: 'React Blog',
              sourceUrl: 'https://react.dev/blog/2025/10/01/react-19-2',
            ),
          ],
    ]);

    await tester.pumpWidget(MaterialApp(home: NewsScreen(newsService: service)));
    await tester.pumpAndSettle();

    expect(find.text('Senin Alanında Gündem'), findsOneWidget);
    expect(find.text('.NET 10 yayınlandı'), findsOneWidget);
    expect(find.text('LTS sürümü'), findsOneWidget);
    expect(find.text('.NET Blog'), findsOneWidget);
    expect(find.text('React Blog'), findsOneWidget);
    expect(find.text('11 Kasım 2025'), findsNWidgets(2));
    expect(find.text('devblogs.microsoft.com'), findsOneWidget);
    expect(find.text('react.dev'), findsOneWidget);
    expect(find.text('Haberi İncele'), findsNWidgets(2));
  });

  testWidgets('Haberi İncele kaynağın URL\'sini açar', (tester) async {
    final opened = <Uri>[];
    final service = _FakeNewsService([
      () async => [
            _news('1',
                sourceUrl: 'https://react.dev/blog/2025/10/01/react-19-2'),
          ],
    ]);

    await tester.pumpWidget(MaterialApp(
      home: NewsScreen(
        newsService: service,
        openLink: (uri) async {
          opened.add(uri);
          return true;
        },
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Haberi İncele'));
    await tester.pumpAndSettle();

    expect(opened, [Uri.parse('https://react.dev/blog/2025/10/01/react-19-2')]);
    expect(find.text('Haber açılamadı.'), findsNothing);
  });

  testWidgets('bağlantı açılamazsa kullanıcıya bildirir', (tester) async {
    final service = _FakeNewsService([() async => [_news('1')]]);

    await tester.pumpWidget(MaterialApp(
      home: NewsScreen(newsService: service, openLink: (_) async => false),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Haberi İncele'));
    await tester.pumpAndSettle();

    expect(find.text('Haber açılamadı.'), findsOneWidget);
  });

  testWidgets('haber yoksa boş durum mesajı gösterir', (tester) async {
    final service = _FakeNewsService([() async => []]);

    await tester.pumpWidget(MaterialApp(home: NewsScreen(newsService: service)));
    await tester.pumpAndSettle();

    expect(find.text('Şu an alanında gösterilecek haber yok.'), findsOneWidget);
  });

  testWidgets('hata durumunda Tekrar Dene ile yeniden yükler', (tester) async {
    final service = _FakeNewsService([
      () async => throw ApiException(statusCode: 500, message: 'Hata'),
      () async => [_news('1', title: 'Yeniden yüklendi')],
    ]);

    await tester.pumpWidget(MaterialApp(home: NewsScreen(newsService: service)));
    await tester.pumpAndSettle();

    expect(find.text('Haberler yüklenemedi.'), findsOneWidget);

    await tester.tap(find.text('Tekrar Dene'));
    await tester.pumpAndSettle();

    expect(service.calls, 2);
    expect(find.text('Haberler yüklenemedi.'), findsNothing);
    expect(find.text('Yeniden yüklendi'), findsOneWidget);
  });

  testWidgets('400px genişlikte uzun metinlerle taşmaz', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final service = _FakeNewsService([
      () async => [
            _news(
              '1',
              title: 'Çok uzun bir haber başlığı: ' * 6,
              summary: 'Çok uzun bir özet metni. ' * 20,
              sourceName: 'Microsoft SQL Server Blog ve daha uzun bir kaynak adı',
              sourceUrl:
                  'https://www.microsoft.com/en-us/sql-server/blog/2025/05/19/announcing-sql-server-2025-preview/',
            ),
          ],
    ]);

    await tester.pumpWidget(MaterialApp(home: NewsScreen(newsService: service)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Haberi İncele'), findsOneWidget);
  });
}
