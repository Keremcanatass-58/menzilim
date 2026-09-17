import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/quiz_models.dart';

class QuizService {
  final ApiClient _apiClient;

  QuizService(this._apiClient);

  Future<QuizDetailResponse> getActiveQuiz(String token) async {
    final response = await _apiClient.get(
      ApiConstants.activeQuiz,
      token: token,
    );

    return QuizDetailResponse.fromJson(
      response as Map<String, dynamic>,
    );
  }

  Future<QuizDetailResponse> getQuizDetail(
    String token,
    String quizId,
  ) async {
    final response = await _apiClient.get(
      ApiConstants.quizDetail(quizId),
      token: token,
    );

    return QuizDetailResponse.fromJson(
      response as Map<String, dynamic>,
    );
  }

  Future<QuizSubmitResultResponse> submitQuiz(
    String token,
    String quizId,
    Map<String, String> answers,
  ) async {
    final body = {
      'answers': answers.entries
          .map(
            (e) => {
              'questionId': e.key,
              'selectedOption': e.value,
            },
          )
          .toList(),
    };

    final response = await _apiClient.post(
      ApiConstants.submitQuiz(quizId),
      body: body,
      token: token,
    );

    return QuizSubmitResultResponse.fromJson(
      response as Map<String, dynamic>,
    );
  }
}
