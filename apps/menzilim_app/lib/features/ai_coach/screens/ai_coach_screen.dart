import 'package:flutter/material.dart';

import '../../../core/design/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/ai_coach_models.dart';
import '../services/ai_coach_service.dart';

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  final AiCoachService _aiCoachService = AiCoachService(ApiClient());
  final TokenStorage _tokenStorage = TokenStorage();
  final TextEditingController _promptController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  AiCoachResponse? _response;

  /// Yalnızca görünüm için: sorulan son soru balonda gösterilir.
  String? _askedPrompt;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _response = null;
      _askedPrompt = prompt;
    });

    try {
      final token = await _tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Oturum bilgisi bulunamadı.');
      }

      final result = await _aiCoachService.ask(token, prompt);

      if (!mounted) return;

      setState(() {
        _response = result;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = context.l10n.coachUnreachable;
        _isLoading = false;
      });
    }
  }

  void _useSuggestion(String prompt) {
    _promptController.text = prompt;
    _ask();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.coachTitle)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.maxReadingWidth,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: AppSpacing.screen(constraints.maxWidth),
                      child: _buildConversation(),
                    ),
                  ),
                  _buildComposer(constraints.maxWidth),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConversation() {
    final l10n = context.l10n;

    // Henüz soru sorulmadı: karşılama + örnek sorular.
    if (_askedPrompt == null && _errorMessage == null) {
      return MenzilimEntrance(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: context.colors.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 28,
                color: context.colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.coachEmptyTitle,
              style: context.textStyles.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.coachIntro,
              style: context.textStyles.bodyLarge?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.coachSuggestionsTitle,
              style: context.textStyles.titleSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...[
              l10n.coachSuggestion1,
              l10n.coachSuggestion2,
              l10n.coachSuggestion3,
            ].map(
              (suggestion) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: MenzilimCard(
                  onTap: _isLoading ? null : () => _useSuggestion(suggestion),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 18,
                        color: context.colors.primary,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: context.textStyles.bodyMedium,
                        ),
                      ),
                      Icon(
                        Icons.north_east,
                        size: 16,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_askedPrompt != null) _UserBubble(text: _askedPrompt!),
        const SizedBox(height: AppSpacing.md),
        if (_isLoading)
          const _CoachTypingBubble()
        else if (_errorMessage != null)
          _CoachErrorBubble(message: _errorMessage!)
        else if (_response != null)
          _CoachBubble(answer: _response!.answer),
      ],
    );
  }

  Widget _buildComposer(double width) {
    final l10n = context.l10n;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen(width).left,
        AppSpacing.md,
        AppSpacing.screen(width).right,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          top: BorderSide(color: context.colors.outlineVariant),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _promptController,
              minLines: 1,
              maxLines: 4,
              enabled: !_isLoading,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _ask(),
              decoration: InputDecoration(
                hintText: l10n.coachHint,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.pillRadius,
                  borderSide: BorderSide(color: context.colors.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.pillRadius,
                  borderSide: BorderSide(color: context.colors.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.pillRadius,
                  borderSide: BorderSide(
                    color: context.colors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 52,
            height: 52,
            child: IconButton.filled(
              tooltip: l10n.coachSend,
              onPressed: _isLoading ? null : _ask,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_upward),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  final String text;

  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: context.colors.primary,
            borderRadius: BorderRadius.circular(AppRadius.lg).copyWith(
              bottomRight: const Radius.circular(AppRadius.sm),
            ),
          ),
          child: Text(
            text,
            style: context.textStyles.bodyLarge?.copyWith(
              color: context.colors.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _CoachBubbleShell extends StatelessWidget {
  final Widget child;
  final Color? background;

  const _CoachBubbleShell({required this.child, this.background});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: background ?? context.colors.surfaceContainerLow,
            border: Border.all(color: context.colors.outlineVariant),
            borderRadius: BorderRadius.circular(AppRadius.lg).copyWith(
              bottomLeft: const Radius.circular(AppRadius.sm),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CoachBubble extends StatelessWidget {
  final String answer;

  const _CoachBubble({required this.answer});

  @override
  Widget build(BuildContext context) {
    return MenzilimEntrance(
      child: _CoachBubbleShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: context.colors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  context.l10n.coachTitle,
                  style: context.textStyles.labelLarge?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SelectableText(
              answer,
              style: context.textStyles.bodyLarge?.copyWith(height: 1.55),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachErrorBubble extends StatelessWidget {
  final String message;

  const _CoachErrorBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return _CoachBubbleShell(
      background: context.colors.errorContainer,
      child: Row(
        children: [
          Icon(Icons.error_outline, color: context.colors.error),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: context.textStyles.bodyLarge?.copyWith(
                color: context.colors.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Yanıt beklenirken yanıp sönen üç nokta.
class _CoachTypingBubble extends StatefulWidget {
  const _CoachTypingBubble();

  @override
  State<_CoachTypingBubble> createState() => _CoachTypingBubbleState();
}

class _CoachTypingBubbleState extends State<_CoachTypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _CoachBubbleShell(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final t = (_controller.value * 3 - i).clamp(0.0, 1.0);
                  final opacity = 0.35 + 0.65 * (1 - (t - 0.5).abs() * 2);

                  return Opacity(
                    opacity: opacity.clamp(0.35, 1.0),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: context.colors.onSurfaceVariant,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            context.l10n.coachAnswering,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
