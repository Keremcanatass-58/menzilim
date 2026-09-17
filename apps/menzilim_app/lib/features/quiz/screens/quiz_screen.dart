import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../daily_plan/services/daily_plan_service.dart';
import '../models/quiz_models.dart';
import '../services/quiz_service.dart';

class QuizScreen extends StatefulWidget {
  final String? quizId;
  final String? dailyTaskId;
  final bool isDailyTaskCompleted;

  const QuizScreen({
    super.key,
    this.quizId,
    this.dailyTaskId,
    this.isDailyTaskCompleted = false,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final QuizService _quizService = QuizService(ApiClient());
  final DailyPlanService _dailyPlanService = DailyPlanService(ApiClient());
  final TokenStorage _tokenStorage = TokenStorage();

  QuizDetailResponse? _quiz;
  QuizSubmitResultResponse? _result;

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  int _currentIndex = 0;
  final Map<String, String> _selectedAnswers = {};

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
      _currentIndex = 0;
      _selectedAnswers.clear();
    });

    try {
      final token = await _tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Oturum bilgisi bulunamadı.');
      }

      final QuizDetailResponse quiz;
      if (widget.quizId != null && widget.quizId!.isNotEmpty) {
        quiz = await _quizService.getQuizDetail(token, widget.quizId!);
      } else {
        quiz = await _quizService.getActiveQuiz(token);
      }

      if (!mounted) return;

      setState(() {
        _quiz = quiz;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Quiz yüklenirken bir hata oluştu.';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitQuiz() async {
    if (_quiz == null || _isSubmitting) return;

    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await _quizService.submitQuiz(
        token,
        _quiz!.id,
        _selectedAnswers,
      );

      // Görev henüz tamamlanmamışsa günlük planda görevi tamamla
      if (widget.dailyTaskId != null && !widget.isDailyTaskCompleted) {
        try {
          await _dailyPlanService.completeTask(token, widget.dailyTaskId!);
        } catch (_) {
          // Günlük görev tamamlanamazsa bile quiz sonucunu göster
        }
      }

      if (!mounted) return;

      setState(() {
        _result = result;
        _isSubmitting = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quiz gönderilirken bir hata oluştu.'),
        ),
      );
    }
  }

  void _onOptionSelected(String questionId, String option) {
    setState(() {
      _selectedAnswers[questionId] = option;
    });
  }

  void _nextQuestion() {
    if (_quiz == null) return;
    if (_currentIndex < _quiz!.questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null || _quiz == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Quiz'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Quiz bulunamadı.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loadQuiz,
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_quiz!.title),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1000,
            ),
            child: _result != null ? _buildResultView() : _buildQuizView(),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizView() {
    final questions = _quiz!.questions;
    if (questions.isEmpty) {
      return const Center(
        child: Text('Bu quiz için henüz soru bulunmuyor.'),
      );
    }

    final currentQuestion = questions[_currentIndex];
    final isLastQuestion = _currentIndex == questions.length - 1;
    final selectedOption = _selectedAnswers[currentQuestion.IdKey];
    final hasAnswered = selectedOption != null && selectedOption.isNotEmpty;

    final options = [
      {'key': 'A', 'text': currentQuestion.optionA},
      {'key': 'B', 'text': currentQuestion.optionB},
      {'key': 'C', 'text': currentQuestion.optionC},
      {'key': 'D', 'text': currentQuestion.optionD},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Soru Numarası ve İlerleme
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Soru ${_currentIndex + 1} / ${questions.length}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '%${(((_currentIndex + 1) / questions.length) * 100).round()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / questions.length,
              minHeight: 8,
            ),
          ),

          const SizedBox(height: 32),

          // Soru Metni
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              currentQuestion.text,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Seçenekler
          ...options.map((option) {
            final key = option['key']!;
            final text = option['text']!;
            final isSelected = selectedOption == key;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: InkWell(
                onTap: _isSubmitting
                    ? null
                    : () => _onOptionSelected(currentQuestion.IdKey, key),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade200,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          key,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          text,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Sonraki / Quiz'i Bitir Butonu
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: !hasAnswered || _isSubmitting
                  ? null
                  : () {
                      if (isLastQuestion) {
                        _submitQuiz();
                      } else {
                        _nextQuestion();
                      }
                    },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isLastQuestion ? "Quiz'i Bitir" : 'Sonraki',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    final result = _result!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 20),

          const Icon(
            Icons.emoji_events_outlined,
            size: 72,
            color: Colors.amber,
          ),

          const SizedBox(height: 16),

          const Text(
            'Quiz Sonucu',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            '${result.correctAnswers} / ${result.totalQuestions} Doğru',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 32),

          // Başarı Kartı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  'Başarı',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '%${result.score}',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check,
                          color: Colors.green,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${result.correctAnswers} Doğru',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.close,
                          color: Colors.red,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${result.wrongAnswers} Yanlış',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          // Tekrar Çöz Butonu
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _loadQuiz,
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Tekrar Çöz',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Dashboard'a Dön Butonu
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text(
                "Dashboard'a Dön",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension on QuestionResponse {
  String get IdKey => id;
}
