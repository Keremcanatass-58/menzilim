class ContentRecommendationResponse {
  final String contentId;
  final String title;
  final String? description;
  final String url;
  final bool isStarted;
  final bool isCompleted;
  final String recommendationReason;

  const ContentRecommendationResponse({
    required this.contentId,
    required this.title,
    this.description,
    required this.url,
    required this.isStarted,
    required this.isCompleted,
    required this.recommendationReason,
  });

  factory ContentRecommendationResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return ContentRecommendationResponse(
      contentId: json['contentId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      url: json['url']?.toString() ?? '',
      isStarted: json['isStarted'] == true,
      isCompleted: json['isCompleted'] == true,
      recommendationReason:
          json['recommendationReason']?.toString() ?? '',
    );
  }
}
