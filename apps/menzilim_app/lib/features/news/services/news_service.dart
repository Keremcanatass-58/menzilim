import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/news_item.dart';

class NewsService {
  final ApiClient _apiClient;

  NewsService(this._apiClient);

  Future<List<NewsItem>> getMyNews(String token) async {
    final response = await _apiClient.get(
      ApiConstants.myNews,
      token: token,
    );

    final data = response as List<dynamic>;

    return data
        .map((item) => NewsItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
