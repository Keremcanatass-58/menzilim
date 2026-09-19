/// GET /api/news/me yanıtındaki tek haber. Kişiselleştirme ve sıralama
/// backend'de yapılır; model yalnızca veriyi taşır.
class NewsItem {
  final String id;
  final String title;
  final String summary;
  final String sourceName;
  final String sourceUrl;
  final DateTime? publishedAt;
  final String? imageUrl;

  const NewsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.sourceName,
    required this.sourceUrl,
    required this.publishedAt,
    this.imageUrl,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    final imageUrl = json['imageUrl']?.toString();

    return NewsItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      sourceName: json['sourceName']?.toString() ?? '',
      sourceUrl: json['sourceUrl']?.toString() ?? '',
      publishedAt: json['publishedAt'] == null
          ? null
          : DateTime.tryParse(json['publishedAt'].toString()),
      imageUrl: imageUrl == null || imageUrl.isEmpty ? null : imageUrl,
    );
  }

  /// Kaynak alan adı (ör. devblogs.microsoft.com); geçersiz URL'de null.
  String? get sourceHost {
    final uri = Uri.tryParse(sourceUrl);
    return uri == null || uri.host.isEmpty ? null : uri.host;
  }
}
