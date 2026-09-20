class QuizSummaryResponse {
  final String id;
  final String title;
  final String? description;
  final int questionCount;

  QuizSummaryResponse({
    required this.id,
    required this.title,
    this.description,
    required this.questionCount,
  });

  factory QuizSummaryResponse.fromJson(Map<String, dynamic> json) {
    return QuizSummaryResponse(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class QuestionResponse {
  final String id;
  final String text;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;

  QuestionResponse({
    required this.id,
    required this.text,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
  });

  factory QuestionResponse.fromJson(Map<String, dynamic> json) {
    return QuestionResponse(
      id: json['id'].toString(),
      text: json['text']?.toString() ?? '',
      optionA: json['optionA']?.toString() ?? '',
      optionB: json['optionB']?.toString() ?? '',
      optionC: json['optionC']?.toString() ?? '',
      optionD: json['optionD']?.toString() ?? '',
    );
  }
}

class QuizDetailResponse {
  final String id;
  final String title;
  final String? description;
  final List<QuestionResponse> questions;

  QuizDetailResponse({
    required this.id,
    required this.title,
    this.description,
    required this.questions,
  });

  factory QuizDetailResponse.fromJson(Map<String, dynamic> json) {
    return QuizDetailResponse(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map((q) => QuestionResponse.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Gönderim sonrası tek sorunun sonucu: doğru şık ve kısa açıklama.
class QuestionResultResponse {
  final String questionId;
  final String text;
  final String? selectedOption;
  final String correctOption;
  final String? correctOptionText;
  final bool isCorrect;
  final String? explanation;

  QuestionResultResponse({
    required this.questionId,
    required this.text,
    required this.selectedOption,
    required this.correctOption,
    required this.correctOptionText,
    required this.isCorrect,
    required this.explanation,
  });

  factory QuestionResultResponse.fromJson(Map<String, dynamic> json) {
    final selected = json['selectedOption']?.toString();
    final explanation = json['explanation']?.toString();
    final correctText = json['correctOptionText']?.toString();

    return QuestionResultResponse(
      questionId: json['questionId'].toString(),
      text: json['text']?.toString() ?? '',
      selectedOption: selected == null || selected.isEmpty ? null : selected,
      correctOption: json['correctOption']?.toString() ?? '',
      correctOptionText:
          correctText == null || correctText.isEmpty ? null : correctText,
      isCorrect: json['isCorrect'] == true,
      explanation:
          explanation == null || explanation.isEmpty ? null : explanation,
    );
  }
}

class QuizSubmitResultResponse {
  final String attemptId;
  final String quizId;
  final int score;
  final int correctAnswers;
  final int wrongAnswers;
  final int totalQuestions;
  final double successRate;
  final List<QuestionResultResponse> results;

  QuizSubmitResultResponse({
    required this.attemptId,
    required this.quizId,
    required this.score,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.totalQuestions,
    required this.successRate,
    this.results = const [],
  });

  /// Yanlış yapılan (veya boş bırakılan) sorular.
  List<QuestionResultResponse> get wrongResults =>
      results.where((result) => !result.isCorrect).toList();

  factory QuizSubmitResultResponse.fromJson(Map<String, dynamic> json) {
    return QuizSubmitResultResponse(
      attemptId: json['attemptId'].toString(),
      quizId: json['quizId'].toString(),
      score: (json['score'] as num?)?.toInt() ?? 0,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
      wrongAnswers: (json['wrongAnswers'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      successRate: (json['successRate'] as num?)?.toDouble() ?? 0.0,
      results: (json['results'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                QuestionResultResponse.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
