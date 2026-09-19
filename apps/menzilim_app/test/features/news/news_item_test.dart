import 'package:flutter_test/flutter_test.dart';
import 'package:menzilim_app/features/news/models/news_item.dart';
import 'package:menzilim_app/features/news/widgets/news_card.dart';

void main() {
  group('NewsItem.fromJson', () {
    test('API yanıtındaki tüm camelCase alanları okur', () {
      final item = NewsItem.fromJson({
        'id': 'n1',
        'title': '.NET 10 yayınlandı: yeni LTS sürümü',
        'summary': 'Özet',
        'sourceName': '.NET Blog',
        'sourceUrl': 'https://devblogs.microsoft.com/dotnet/announcing-dotnet-10/',
        'publishedAt': '2025-11-11T15:38:00',
        'imageUrl': 'https://example.com/image.png',
      });

      expect(item.id, 'n1');
      expect(item.title, '.NET 10 yayınlandı: yeni LTS sürümü');
      expect(item.summary, 'Özet');
      expect(item.sourceName, '.NET Blog');
      expect(item.sourceUrl,
          'https://devblogs.microsoft.com/dotnet/announcing-dotnet-10/');
      expect(item.publishedAt, DateTime(2025, 11, 11, 15, 38));
      expect(item.imageUrl, 'https://example.com/image.png');
      expect(item.sourceHost, 'devblogs.microsoft.com');
    });

    test('imageUrl null veya boşsa null kalır', () {
      expect(NewsItem.fromJson({'imageUrl': null}).imageUrl, isNull);
      expect(NewsItem.fromJson({'imageUrl': ''}).imageUrl, isNull);
    });

    test('eksik alanlarda güvenli varsayılanlar', () {
      final item = NewsItem.fromJson({});

      expect(item.id, '');
      expect(item.title, '');
      expect(item.summary, '');
      expect(item.sourceName, '');
      expect(item.sourceUrl, '');
      expect(item.publishedAt, isNull);
      expect(item.imageUrl, isNull);
      expect(item.sourceHost, isNull);
    });
  });

  test('formatNewsDate Türkçe ay adıyla tarih üretir', () {
    expect(formatNewsDate(DateTime(2025, 11, 11)), '11 Kasım 2025');
    expect(formatNewsDate(DateTime(2025, 2, 1)), '1 Şubat 2025');
    expect(formatNewsDate(DateTime(2024, 12, 5)), '5 Aralık 2024');
  });
}
