import 'package:flutter/material.dart';

import '../../../core/design/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../content/models/content_response.dart';
import '../../content/screens/discover_screen.dart';
import '../../content/services/content_service.dart';
import '../../quiz/screens/quiz_screen.dart';
import '../models/user_project.dart';
import '../services/project_service.dart';
import '../widgets/step_completed_sheet.dart';

/// Günün ana görevinin (proje adımı) detayı: ne yapılacağı, neden önemli
/// olduğu, destekleyici içerik ve tamamlama.
class ProjectStepDetailScreen extends StatefulWidget {
  final UserProject project;
  final UserProjectStep step;

  /// Adıma bağlı quiz varsa (günlük plandan gelir).
  final String? quizId;

  // Testlerde sahte servisler verilebilir.
  final ProjectService? projectService;
  final ContentService? contentService;

  const ProjectStepDetailScreen({
    super.key,
    required this.project,
    required this.step,
    this.quizId,
    this.projectService,
    this.contentService,
  });

  @override
  State<ProjectStepDetailScreen> createState() =>
      _ProjectStepDetailScreenState();
}

class _ProjectStepDetailScreenState extends State<ProjectStepDetailScreen> {
  late final ProjectService _projectService =
      widget.projectService ?? ProjectService(ApiClient());

  late final ContentService _contentService =
      widget.contentService ?? ContentService(ApiClient());

  final TokenStorage _tokenStorage = TokenStorage();

  late UserProject _project = widget.project;
  late UserProjectStep _step = widget.step;

  bool _isCompleting = false;
  bool _isOpeningContent = false;

  /// Bu ekranda ilerleme oldu mu? Kapanışta çağırana bildirilir.
  bool _changed = false;

  Future<void> _complete() async {
    if (_isCompleting) return;

    setState(() {
      _isCompleting = true;
    });

    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Oturum bilgisi bulunamadı.');
      }

      final updated = await _projectService.completeStep(token, _step.id);

      if (!mounted) return;

      final completedOrder = _step.order;

      setState(() {
        _project = updated;
        _step = updated.steps.firstWhere(
          (s) => s.id == _step.id,
          orElse: () => _step,
        );
        _isCompleting = false;
        _changed = true;
      });

      final next = await showStepCompletedSheet(
        context: context,
        project: updated,
        completedStepOrder: completedOrder,
        skillName: widget.step.skillName,
      );

      if (!mounted) return;

      // "Sonraki adıma geç": aynı ekran sıradaki adımla devam eder.
      if (next != null) {
        setState(() {
          _step = next;
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isCompleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.projectCompleteError)),
      );
    }
  }

  Future<void> _openContent() async {
    final contentId = _step.contentId;

    if (contentId == null || _isOpeningContent) return;

    setState(() {
      _isOpeningContent = true;
    });

    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Oturum bilgisi bulunamadı.');
      }

      final ContentResponse content =
          await _contentService.getById(token, contentId);

      if (!mounted) return;

      setState(() {
        _isOpeningContent = false;
      });

      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ContentDetailScreen(content: content)),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isOpeningContent = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.contentOpenError)),
      );
    }
  }

  Future<void> _openQuiz() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => QuizScreen(quizId: widget.quizId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {},
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.stepDetailTitle),
          leading: BackButton(
            onPressed: () => Navigator.of(context).pop(_changed),
          ),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppBreakpoints.maxReadingWidth,
                ),
                child: ListView(
                  padding: AppSpacing.screen(constraints.maxWidth),
                  children: [
                    // Proje ve adım sırası: kullanıcı nerede olduğunu görür.
                    Text(
                      _project.name,
                      style: context.textStyles.labelLarge?.copyWith(
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(_step.title, style: context.textStyles.headlineSmall),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        MenzilimChip(
                          label: l10n.stepDetailOrderOfTotal(
                            _step.order,
                            _project.totalSteps,
                          ),
                          icon: Icons.flag_outlined,
                          tone: MenzilimChipTone.primary,
                        ),
                        MenzilimChip(
                          label: l10n.commonMinutesShort(
                            _step.estimatedMinutes,
                          ),
                          icon: Icons.schedule_outlined,
                        ),
                        if (_step.skillName != null)
                          MenzilimChip(
                            label: _step.skillName!,
                            icon: Icons.bolt_outlined,
                            tone: MenzilimChipTone.secondary,
                          ),
                        if (_step.isCompleted)
                          MenzilimChip(
                            label: l10n.projectStepStatusCompleted,
                            icon: Icons.check,
                            tone: MenzilimChipTone.success,
                          ),
                      ],
                    ),
                    if (_step.description != null) ...[
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        _step.description!,
                        style: context.textStyles.bodyLarge,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.section),

                    // Neden önemli?
                    MenzilimCard(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.stepDetailWhyTitle,
                            style: context.textStyles.titleSmall,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _step.skillName == null
                                ? l10n.stepDetailWhyBodyGeneric
                                : l10n.stepDetailWhyBody(_step.skillName!),
                            style: context.textStyles.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.section),

                    // Yapılacaklar
                    MenzilimSectionHeader(
                      title: l10n.stepDetailChecklistTitle,
                    ),
                    _ChecklistItem(
                      text: l10n.stepDetailChecklistRead,
                      enabled: _step.contentId != null,
                    ),
                    _ChecklistItem(text: l10n.stepDetailChecklistApply),
                    _ChecklistItem(text: l10n.stepDetailChecklistVerify),

                    if (_step.contentId != null) ...[
                      const SizedBox(height: AppSpacing.section),
                      MenzilimSectionHeader(
                        title: l10n.stepDetailContentTitle,
                      ),
                      MenzilimCard(
                        onTap: _openContent,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Row(
                          children: [
                            Icon(
                              Icons.menu_book_outlined,
                              color: colors.primary,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                _step.contentTitle ?? l10n.contentOpen,
                                style: context.textStyles.titleSmall,
                              ),
                            ),
                            if (_isOpeningContent)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              Icon(
                                Icons.chevron_right,
                                color: colors.onSurfaceVariant,
                              ),
                          ],
                        ),
                      ),
                    ],

                    if (widget.quizId != null) ...[
                      const SizedBox(height: AppSpacing.section),
                      MenzilimSectionHeader(title: l10n.stepDetailQuizTitle),
                      MenzilimButton(
                        label: l10n.stepDetailOpenQuiz,
                        icon: Icons.quiz_outlined,
                        variant: MenzilimButtonVariant.secondary,
                        onPressed: _openQuiz,
                      ),
                    ],

                    const SizedBox(height: AppSpacing.section),
                    if (_step.isLocked)
                      MenzilimInlineEmpty(
                        message: l10n.stepDetailLockedTitle,
                        hint: l10n.projectStepLockedHint,
                      )
                    else if (!_step.isCompleted)
                      MenzilimButton(
                        label: l10n.projectStepCompleteAction,
                        icon: Icons.check,
                        isLoading: _isCompleting,
                        onPressed: _complete,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final String text;
  final bool enabled;

  const _ChecklistItem({required this.text, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_box_outline_blank,
            size: 18,
            color: context.colors.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(text, style: context.textStyles.bodyMedium),
          ),
        ],
      ),
    );
  }
}
