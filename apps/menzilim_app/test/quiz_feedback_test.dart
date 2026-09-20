import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menzilim_app/core/network/api_client.dart';
import 'package:menzilim_app/core/settings/app_settings_controller.dart';
import 'package:menzilim_app/features/quiz/models/quiz_models.dart';
import 'package:menzilim_app/features/quiz/screens/quiz_screen.dart';
import 'package:menzilim_app/features/quiz/services/quiz_service.dart';
import 'package:menzilim_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeQuizService extends QuizService {
  final QuizSubmitResultResponse result;

  _FakeQuizService(this.result) : super(ApiClient());

  @override
  Future<QuizDetailResponse> getActiveQuiz(String token) async => _quiz();

  @override
  Future<QuizDetailResponse> getQuizDetail(String token, String quizId) async =>
      _quiz();

  @override
  Future<QuizSubmitResultResponse> submitQuiz(
    String token,
    String quizId,
    Map<String, String> answers,
  ) async {
    return result;
  }

  QuizDetailResponse _quiz() => QuizDetailResponse(
        id: 'q-1',
        title: 'Backend Temelleri',
        description: 'Test',
        questions: [
          QuestionResponse(
            id: 'question-1',
            text: 'REST\'te yeni kaynak hangi metotla oluşturulur?',
            optionA: 'GET',
            optionB: 'POST',
            optionC: 'DELETE',
            optionD: 'HEAD',
          ),
        ],
      );
}

QuizSubmitResultResponse _result({required bool correct}) =>
    QuizSubmitResultResponse(
      attemptId: 'a-1',
      quizId: 'q-1',
      score: correct ? 100 : 0,
      correctAnswers: correct ? 1 : 0,
      wrongAnswers: correct ? 0 : 1,
      totalQuestions: 1,
      successRate: correct ? 100 : 0,
      results: [
        QuestionResultResponse(
          questionId: 'question-1',
          text: 'REST\'te yeni kaynak hangi metotla oluşturulur?',
          selectedOption: correct ? 'B' : 'A',
          correctOption: 'B',
          correctOptionText: 'POST',
          isCorrect: correct,
          explanation: 'Yeni kaynak POST ile oluşturulur.',
        ),
      ],
    );

Widget _app(QuizService service) => MenzilimApp(
      settings: AppSettingsController(),
      home: QuizScreen(quizService: service),
    );

Future<void> _answerAndSubmit(WidgetTester tester) async {
  await tester.tap(find.textContaining('GET'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Quiz\'i Bitir'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': 'test-token'});
  });

  testWidgets('yanlış cevapta doğru şık ve açıklama gösterilir',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(_FakeQuizService(_result(correct: false))));
    await tester.pumpAndSettle();

    await _answerAndSubmit(tester);

    expect(find.text('Yanlış yaptığın sorular'), findsOneWidget);
    expect(find.text('Bu cevap doğru değil'), findsOneWidget);
    expect(find.text('Doğru cevap: B · POST'), findsOneWidget);
    expect(find.text('Yeni kaynak POST ile oluşturulur.'), findsOneWidget);
  });

  testWidgets('hepsi doğruysa yanlış listesi yerine onay mesajı çıkar',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(_FakeQuizService(_result(correct: true))));
    await tester.pumpAndSettle();

    await _answerAndSubmit(tester);

    expect(find.text('Tüm soruları doğru bildin.'), findsOneWidget);
    expect(find.text('Bu cevap doğru değil'), findsNothing);
  });
}
