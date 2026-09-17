class ContentResponse {
  final String id;
  final String title;
  final String? description;
  final String url;
  final String source;
  final DateTime publishedAt;
  final int readingTimeMinutes;
  final String level;

  const ContentResponse({
    required this.id,
    required this.title,
    this.description,
    required this.url,
    required this.source,
    required this.publishedAt,
    required this.readingTimeMinutes,
    required this.level,
  });

  factory ContentResponse.fromJson(Map<String, dynamic> json) {
    return ContentResponse(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      url: json['url']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      publishedAt: DateTime.parse(json['publishedAt'].toString()),
      readingTimeMinutes:
          (json['readingTimeMinutes'] as num?)?.toInt() ?? 0,
      level: json['level']?.toString() ?? '',
    );
  }
}
