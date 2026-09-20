import 'package:flutter/material.dart';

import '../../../core/design/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/progress_response.dart';
import '../services/progress_service.dart';

/// Kullanıcının genel ilerleme panosu. Veriyi /api/progress/me sağlar;
/// ekran yalnızca gelen metrikleri görselleştirir.
class ProgressScreen extends StatefulWidget {
  final ProgressService? progressService;

  const ProgressScreen({
    super.key,
    this.progressService,
  });

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late final ProgressService _progressService =
      widget.progressService ?? ProgressService(ApiClient());

  final TokenStorage _tokenStorage = TokenStorage();

  ProgressResponse? _progress;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Oturum bilgisi bulunamadı.');
      }

      final progress = await _progressService.getMyProgress(token);

      if (!mounted) return;

      setState(() {
        _progress = progress;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = context.l10n.progressLoadError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.progressTitle)),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
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
          _loadProgress();
        },
      );
    }

    if (_progress == null) {
      return MenzilimEmptyView(
        icon: Icons.bar_chart_outlined,
        message: context.l10n.progressNoData,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppBreakpoints.tablet;

        return RefreshIndicator(
          onRefresh: _loadProgress,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.maxContentWidth,
              ),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppSpacing.screen(constraints.maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MenzilimEntrance(
                      order: 0,
                      child: _buildOverviewSection(isWide),
                    ),
                    const SizedBox(height: AppSpacing.section),
                    MenzilimEntrance(order: 1, child: _buildTodaySection()),
                    const SizedBox(height: AppSpacing.section),
                    MenzilimEntrance(
                      order: 2,
                      child: _buildContentAndQuizSection(isWide),
                    ),
                    const SizedBox(height: AppSpacing.section),
                    MenzilimEntrance(order: 3, child: _buildSkillsSection()),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewSection(bool isWide) {
    final overview = _progress!.overview;
    final l10n = context.l10n;

    final cards = [
      _OverviewCard(
        icon: Icons.check_circle_outline,
        label: l10n.progressCompletedTasks,
        value: overview.completedTaskCount.toString(),
        subtitle: l10n.progressUnitTotal,
      ),
      _OverviewCard(
        icon: Icons.timer_outlined,
        label: l10n.progressLearningTime,
        value: '${overview.estimatedLearningMinutes}',
        subtitle: l10n.progressUnitMinutes,
      ),
      _OverviewCard(
        icon: Icons.calendar_today_outlined,
        label: l10n.progressCompletedPlans,
        value: overview.completedPlanCount.toString(),
        subtitle: l10n.progressUnitPlans,
      ),
      _OverviewCard(
        icon: Icons.local_fire_department_outlined,
        label: l10n.progressActiveDays,
        value: overview.activeDayCount.toString(),
        subtitle: l10n.progressUnitDays,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MenzilimSectionHeader(title: l10n.progressOverview),
        // Dar ekranda 2x2, geniş ekranda tek sıra.
        if (isWide)
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: cards[1]),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: cards[2]),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: cards[3]),
            ],
          )
        else
          Column(
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: cards[3]),
                ],
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTodaySection() {
    final today = _progress!.today;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MenzilimSectionHeader(title: l10n.progressToday),
        MenzilimCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      today.hasPlan
                          ? l10n.progressTodayPlan
                          : l10n.progressNoPlanToday,
                      style: context.textStyles.titleMedium?.copyWith(
                        color: today.hasPlan
                            ? context.colors.primary
                            : context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    l10n.progressPercentSuffix(today.progressPercent),
                    style: context.textStyles.headlineSmall?.copyWith(
                      color: today.progressPercent > 0
                          ? context.colors.primary
                          : context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              MenzilimProgressBar(
                value: today.totalMinutes > 0
                    ? today.completedMinutes / today.totalMinutes
                    : 0,
                height: 10,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _TodayStat(
                    icon: Icons.task_outlined,
                    label: l10n.progressTasks,
                    value: '${today.completedTasks}/${today.totalTasks}',
                  ),
                  _TodayStat(
                    icon: Icons.timer,
                    label: l10n.progressDuration,
                    value: l10n.progressMinutesOfTotal(
                      today.completedMinutes,
                      today.totalMinutes,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentAndQuizSection(bool isWide) {
    final content = _progress!.content;
    final l10n = context.l10n;
    final status = context.statusColors;

    final contentSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MenzilimSectionHeader(title: l10n.progressContentTitle),
        Row(
          children: [
            Expanded(
              child: _ContentCard(
                icon: Icons.check_circle,
                color: status.success,
                background: status.successContainer,
                label: l10n.progressCompleted,
                value: content.completedCount.toString(),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _ContentCard(
                icon: Icons.play_circle_outline,
                color: status.warning,
                background: status.warningContainer,
                label: l10n.progressInProgress,
                value: content.inProgressCount.toString(),
              ),
            ),
          ],
        ),
      ],
    );

    final quizSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MenzilimSectionHeader(title: l10n.progressQuizTitle),
        _buildQuizCard(),
      ],
    );

    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          contentSection,
          const SizedBox(height: AppSpacing.section),
          quizSection,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: contentSection),
        const SizedBox(width: AppSpacing.xl),
        Expanded(child: quizSection),
      ],
    );
  }

  Widget _buildQuizCard() {
    final quiz = _progress!.quiz;
    final l10n = context.l10n;

    return MenzilimCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.progressQuizSummary,
                  style: context.textStyles.titleMedium,
                ),
              ),
              if (quiz.attemptCount > 0)
                MenzilimChip(
                  label: l10n.progressQuizAttempts(quiz.attemptCount),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (quiz.attemptCount == 0)
            Text(
              l10n.progressNoQuizAttempts,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _QuizStat(
                    icon: Icons.emoji_events_outlined,
                    label: l10n.progressBestScore,
                    value: quiz.bestScore != null
                        ? l10n.commonPercent(quiz.bestScore!)
                        : '-',
                  ),
                ),
                Expanded(
                  child: _QuizStat(
                    icon: Icons.calculate_outlined,
                    label: l10n.progressAverage,
                    value: quiz.averageScore != null
                        ? l10n.commonPercent(quiz.averageScore!)
                        : '-',
                  ),
                ),
                Expanded(
                  child: _QuizStat(
                    icon: Icons.history,
                    label: l10n.progressLatestScore,
                    value: quiz.latestScore != null
                        ? l10n.commonPercent(quiz.latestScore!)
                        : '-',
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection() {
    final skills = _progress!.skills;
    final l10n = context.l10n;
    final status = context.statusColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MenzilimSectionHeader(
          title: l10n.progressSkillsTitle,
          subtitle: l10n.progressSkillsSummary(
            skills.totalCount,
            skills.startedCount,
          ),
        ),
        if (skills.strongest.isNotEmpty) ...[
          _SkillGroupLabel(
            icon: Icons.trending_up,
            label: l10n.progressStrongestSkills,
            color: status.success,
          ),
          const SizedBox(height: AppSpacing.sm),
          ...skills.strongest.map(
            (skill) => _SkillRow(skill: skill, color: status.success),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        if (skills.focus.isNotEmpty) ...[
          _SkillGroupLabel(
            icon: Icons.flag_outlined,
            label: l10n.progressFocusSkills,
            color: status.warning,
          ),
          const SizedBox(height: AppSpacing.sm),
          ...skills.focus.map(
            (skill) => _SkillRow(skill: skill, color: status.warning),
          ),
        ],
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;

  const _OverviewCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return MenzilimCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.colors.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              icon,
              size: 20,
              color: context.colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(value, style: context.textStyles.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          Text(
            subtitle,
            style: context.textStyles.labelSmall?.copyWith(
              color: context.colors.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TodayStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: context.colors.onSurfaceVariant),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: context.textStyles.titleSmall),
        Text(
          label,
          textAlign: TextAlign.center,
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ContentCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final String label;
  final String value;

  const _ContentCard({
    required this.icon,
    required this.color,
    required this.background,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: context.textStyles.headlineSmall?.copyWith(color: color),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: context.textStyles.bodySmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _QuizStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _QuizStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: context.colors.tertiary),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: context.textStyles.titleMedium?.copyWith(
            color: context.colors.tertiary,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SkillGroupLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SkillGroupLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            label,
            style: context.textStyles.titleSmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _SkillRow extends StatelessWidget {
  final SkillProgressSnapshot skill;
  final Color color;

  const _SkillRow({
    required this.skill,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: MenzilimCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skill.skillName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (skill.category.isNotEmpty)
                    Text(
                      skill.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            SizedBox(
              width: 64,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    context.l10n.progressPercentSuffix(skill.progressPercent),
                    style: context.textStyles.labelLarge?.copyWith(color: color),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  MenzilimProgressBar(
                    value: skill.progressPercent / 100,
                    height: 4,
                    color: color,
                    trackColor: color.withValues(alpha: 0.2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
