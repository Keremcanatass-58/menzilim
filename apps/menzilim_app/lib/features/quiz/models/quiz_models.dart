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

class QuizSubmitResultResponse {
  final String attemptId;
  final String quizId;
  final int score;
  final int correctAnswers;
  final int wrongAnswers;
  final int totalQuestions;
  final double successRate;

  QuizSubmitResultResponse({
    required this.attemptId,
    required this.quizId,
    required this.score,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.totalQuestions,
    required this.successRate,
  });

  factory QuizSubmitResultResponse.fromJson(Map<String, dynamic> json) {
    return QuizSubmitResultResponse(
      attemptId: json['attemptId'].toString(),
      quizId: json['quizId'].toString(),
      score: (json['score'] as num?)?.toInt() ?? 0,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
      wrongAnswers: (json['wrongAnswers'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      successRate: (json['successRate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
