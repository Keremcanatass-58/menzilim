import 'package:flutter/material.dart';

import '../../../core/design/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../content/models/content_response.dart';
import '../../content/screens/discover_screen.dart';
import '../../content/services/content_service.dart';
import '../models/user_project.dart';
import '../services/project_service.dart';
import '../widgets/path_roadmap.dart';

/// "Yolum" sekmesi: gelişen proje, adımları ve yol haritası.
class ProjectScreen extends StatefulWidget {
  // Testlerde sahte servisler verilebilir.
  final ProjectService? projectService;
  final ContentService? contentService;

  /// Sekme değiştirme isteği (ör. boş durumda "Bugüne Dön").
  final VoidCallback? onGoToToday;

  /// Proje ilerleyince çağrılır; kabuk diğer sekmeleri tazeler.
  final VoidCallback? onProjectChanged;

  const ProjectScreen({
    super.key,
    this.projectService,
    this.contentService,
    this.onGoToToday,
    this.onProjectChanged,
  });

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  late final ProjectService _projectService =
      widget.projectService ?? ProjectService(ApiClient());

  late final ContentService _contentService =
      widget.contentService ?? ContentService(ApiClient());

  final TokenStorage _tokenStorage = TokenStorage();

  UserProject? _project;
  bool _isLoading = true;
  String? _errorMessage;
  String? _completingStepId;
  String? _openingContentId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Oturum bilgisi bulunamadı.');
      }

      final projects = await _projectService.getMyProjects(token);

      if (!mounted) return;

      setState(() {
        _project = projects.isEmpty ? null : projects.first;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = context.l10n.projectLoadError;
      });
    }
  }

  Future<void> _completeStep(UserProjectStep step) async {
    if (_completingStepId != null) return;

    setState(() {
      _completingStepId = step.id;
    });

    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Oturum bilgisi bulunamadı.');
      }

      final updated = await _projectService.completeStep(token, step.id);

      if (!mounted) return;

      setState(() {
        _project = updated;
        _completingStepId = null;
      });

      widget.onProjectChanged?.call();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _completingStepId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.projectCompleteError)),
      );
    }
  }

  Future<void> _openStepContent(UserProjectStep step) async {
    final contentId = step.contentId;

    if (contentId == null || _openingContentId != null) return;

    setState(() {
      _openingContentId = contentId;
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
        _openingContentId = null;
      });

      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ContentDetailScreen(content: content)),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _openingContentId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.contentOpenError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.projectTitle)),
      body: SafeArea(child: _buildBody(l10n)),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return MenzilimErrorView(
        message: _errorMessage!,
        onRetry: () {
          setState(() {
            _isLoading = true;
            _errorMessage = null;
          });

          _load();
        },
      );
    }

    final project = _project;

    if (project == null) {
      return MenzilimEmptyView(
        icon: Icons.flag_outlined,
        message: l10n.projectEmptyTitle,
        hint: l10n.projectEmptyHint,
        actionLabel: widget.onGoToToday == null ? null : l10n.projectEmptyAction,
        onAction: widget.onGoToToday,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.maxReadingWidth,
          ),
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSpacing.screen(constraints.maxWidth),
              children: [
                _ProjectHeader(project: project),
                const SizedBox(height: AppSpacing.section),
                MenzilimSectionHeader(title: l10n.projectRoadmapTitle),
                PathRoadmap(project: project),
                const SizedBox(height: AppSpacing.section),
                MenzilimSectionHeader(title: l10n.projectStepsTitle),
                ...project.steps.map(
                  (step) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _StepCard(
                      step: step,
                      isCompleting: _completingStepId == step.id,
                      isOpeningContent: _openingContentId == step.contentId,
                      onComplete: () => _completeStep(step),
                      onOpenContent:
                          step.contentId == null ? null : () => _openStepContent(step),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectHeader extends StatelessWidget {
  final UserProject project;

  const _ProjectHeader({required this.project});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return MenzilimCard(
      tone: MenzilimCardTone.primary,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(project.name, style: context.textStyles.headlineSmall),
          if (project.description != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              project.description!,
              style: context.textStyles.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: MenzilimProgressBar(
                  value: project.progressPercent / 100,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                l10n.commonPercent(project.progressPercent),
                style: context.textStyles.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              MenzilimChip(
                label: l10n.projectStepsProgress(
                  project.completedSteps,
                  project.totalSteps,
                ),
                icon: Icons.flag_outlined,
                tone: MenzilimChipTone.primary,
              ),
              MenzilimChip(
                label: l10n.commonMinutesShort(project.totalMinutes),
                icon: Icons.schedule_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final UserProjectStep step;
  final bool isCompleting;
  final bool isOpeningContent;
  final VoidCallback onComplete;
  final VoidCallback? onOpenContent;

  const _StepCard({
    required this.step,
    required this.isCompleting,
    required this.isOpeningContent,
    required this.onComplete,
    this.onOpenContent,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final status = context.statusColors;

    final (label, tone) = switch (step.status) {
      'Completed' => (l10n.projectStepStatusCompleted, MenzilimChipTone.success),
      'Available' => (l10n.projectStepStatusAvailable, MenzilimChipTone.primary),
      _ => (l10n.projectStepStatusLocked, MenzilimChipTone.neutral),
    };

    return Opacity(
      opacity: step.isLocked ? 0.62 : 1,
      child: MenzilimCard(
        tone: step.isAvailable
            ? MenzilimCardTone.primary
            : MenzilimCardTone.surface,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: step.isCompleted
                        ? status.successContainer
                        : colors.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: step.isCompleted
                      ? Icon(Icons.check, size: 18, color: status.success)
                      : step.isLocked
                          ? Icon(
                              Icons.lock_outline,
                              size: 16,
                              color: colors.onSurfaceVariant,
                            )
                          : Text(
                              '${step.order}',
                              style: context.textStyles.labelLarge,
                            ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(step.title, style: context.textStyles.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          MenzilimChip(label: label, tone: tone),
                          MenzilimChip(
                            label: l10n.commonMinutesShort(
                              step.estimatedMinutes,
                            ),
                            icon: Icons.schedule_outlined,
                          ),
                          if (step.skillName != null)
                            MenzilimChip(
                              label: step.skillName!,
                              icon: Icons.bolt_outlined,
                              tone: MenzilimChipTone.secondary,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (step.description != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                step.description!,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
            if (step.isLocked) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.projectStepLockedHint,
                style: context.textStyles.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
            if (!step.isLocked && !step.isCompleted) ...[
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: [
                  MenzilimButton(
                    label: l10n.projectStepCompleteAction,
                    icon: Icons.check,
                    isLoading: isCompleting,
                    onPressed: onComplete,
                  ),
                  if (onOpenContent != null)
                    MenzilimButton(
                      label: l10n.projectStepOpenContent,
                      icon: Icons.menu_book_outlined,
                      variant: MenzilimButtonVariant.secondary,
                      isLoading: isOpeningContent,
                      onPressed: onOpenContent,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
