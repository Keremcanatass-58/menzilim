import 'package:flutter/material.dart';

import '../../../core/design/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../daily_plan/services/daily_plan_service.dart';
import '../models/quiz_models.dart';
import '../services/quiz_service.dart';

class QuizScreen extends StatefulWidget {
  final String? quizId;
  final String? dailyTaskId;
  final bool isDailyTaskCompleted;

  /// Testlerde sahte servis verilebilir; normalde gerçek API kullanılır.
  final QuizService? quizService;

  const QuizScreen({
    super.key,
    this.quizId,
    this.dailyTaskId,
    this.isDailyTaskCompleted = false,
    this.quizService,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final QuizService _quizService =
      widget.quizService ?? QuizService(ApiClient());
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
        _errorMessage = context.l10n.quizLoadError;
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
        SnackBar(
          content: Text(context.l10n.quizSubmitError),
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
    final l10n = context.l10n;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _quiz == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.quizTitle)),
        body: MenzilimErrorView(
          message: _errorMessage ?? l10n.quizNotFound,
          onRetry: _loadQuiz,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_quiz!.title)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.maxReadingWidth,
              ),
              child: _result != null
                  ? _buildResultView(constraints)
                  : _buildQuizView(constraints),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizView(BoxConstraints constraints) {
    final l10n = context.l10n;
    final questions = _quiz!.questions;

    if (questions.isEmpty) {
      return MenzilimEmptyView(
        icon: Icons.quiz_outlined,
        message: l10n.quizNoQuestions,
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
      padding: AppSpacing.screen(constraints.maxWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Soru ilerlemesi
          Row(
            children: [
              Flexible(
                child: Text(
                  l10n.quizQuestionProgress(
                    _currentIndex + 1,
                    questions.length,
                  ),
                  style: context.textStyles.labelLarge?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                l10n.commonPercent(
                  (((_currentIndex + 1) / questions.length) * 100).round(),
                ),
                style: context.textStyles.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          MenzilimProgressBar(
            value: (_currentIndex + 1) / questions.length,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Soru
          MenzilimCard(
            tone: MenzilimCardTone.primary,
            child: Text(
              currentQuestion.text,
              style: context.textStyles.headlineSmall?.copyWith(
                color: context.colors.onPrimaryContainer,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Seçenekler
          ...options.map((option) {
            final key = option['key']!;
            final text = option['text']!;
            final isSelected = selectedOption == key;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _QuizOption(
                optionKey: key,
                text: text,
                isSelected: isSelected,
                onTap: _isSubmitting
                    ? null
                    : () => _onOptionSelected(currentQuestion.IdKey, key),
              ),
            );
          }),

          const SizedBox(height: AppSpacing.lg),

          MenzilimButton(
            label: isLastQuestion ? l10n.quizFinish : l10n.quizNext,
            isLoading: _isSubmitting,
            onPressed: !hasAnswered
                ? null
                : () {
                    if (isLastQuestion) {
                      _submitQuiz();
                    } else {
                      _nextQuestion();
                    }
                  },
            icon: isLastQuestion ? Icons.check : Icons.arrow_forward,
          ),
        ],
      ),
    );
  }

  Widget _buildResultView(BoxConstraints constraints) {
    final l10n = context.l10n;
    final result = _result!;
    final status = context.statusColors;

    return SingleChildScrollView(
      padding: AppSpacing.screen(constraints.maxWidth),
      child: MenzilimEntrance(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: status.warningContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events_outlined,
                size: 36,
                color: status.warning,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.quizResultTitle,
              style: context.textStyles.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.quizResultCorrectOfTotal(
                result.correctAnswers,
                result.totalQuestions,
              ),
              textAlign: TextAlign.center,
              style: context.textStyles.bodyLarge?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Başarı kartı
            MenzilimCard(
              child: Column(
                children: [
                  Text(
                    l10n.quizResultSuccess,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.commonPercent(result.score),
                    style: context.textStyles.displaySmall?.copyWith(
                      color: context.colors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  MenzilimProgressBar(value: result.score / 100, height: 10),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.sm,
                    children: [
                      MenzilimChip(
                        label: l10n.quizResultCorrect(result.correctAnswers),
                        icon: Icons.check,
                        tone: MenzilimChipTone.success,
                      ),
                      MenzilimChip(
                        label: l10n.quizResultWrong(result.wrongAnswers),
                        icon: Icons.close,
                        tone: MenzilimChipTone.neutral,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Soru bazlı geri bildirim: quiz yalnızca ölçmez, öğretir.
            if (result.results.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.section),
              Align(
                alignment: Alignment.centerLeft,
                child: MenzilimSectionHeader(
                  title: result.wrongResults.isEmpty
                      ? l10n.quizReviewAllCorrect
                      : l10n.quizReviewTitle,
                ),
              ),
              ...result.wrongResults.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _QuestionReviewCard(result: item),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),
            MenzilimButton(
              label: l10n.quizRetake,
              onPressed: _loadQuiz,
              icon: Icons.refresh,
            ),
            const SizedBox(height: AppSpacing.md),
            MenzilimButton(
              label: l10n.quizBackToDashboard,
              onPressed: () => Navigator.of(context).pop(),
              icon: Icons.arrow_back,
              variant: MenzilimButtonVariant.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Yanlış yapılan sorunun özeti: doğru cevap ve kısa açıklama.
class _QuestionReviewCard extends StatelessWidget {
  final QuestionResultResponse result;

  const _QuestionReviewCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final status = context.statusColors;

    final correctLabel = result.correctOptionText == null
        ? result.correctOption
        : '${result.correctOption} · ${result.correctOptionText}';

    return MenzilimCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.close, size: 18, color: colors.error),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.quizAnswerWrongTitle,
                  style: context.textStyles.labelLarge?.copyWith(
                    color: colors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(result.text, style: context.textStyles.titleSmall),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle_outline, size: 18, color: status.success),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.quizCorrectAnswerIs(correctLabel),
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: status.success,
                  ),
                ),
              ),
            ],
          ),
          if (result.explanation != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              result.explanation!,
              style: context.textStyles.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Quiz seçeneği: harf rozeti, metin ve seçili durumu.
class _QuizOption extends StatelessWidget {
  final String optionKey;
  final String text;
  final bool isSelected;
  final VoidCallback? onTap;

  const _QuizOption({
    required this.optionKey,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return MenzilimCard(
      onTap: onTap,
      selected: isSelected,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: AppDurations.fast,
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? colors.primary
                  : colors.surfaceContainerHighest,
            ),
            alignment: Alignment.center,
            child: Text(
              optionKey,
              style: context.textStyles.labelLarge?.copyWith(
                color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Text(
              text,
              style: context.textStyles.bodyLarge?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (isSelected)
            Icon(Icons.check_circle, size: 20, color: colors.primary),
        ],
      ),
    );
  }
}

extension on QuestionResponse {
  String get IdKey => id;
}
