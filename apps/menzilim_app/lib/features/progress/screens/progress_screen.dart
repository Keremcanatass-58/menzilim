import 'package:flutter/material.dart';

import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/progress_response.dart';
import '../services/progress_service.dart';

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
      appBar: AppBar(
        title: Text(
          context.l10n.progressTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _loadProgress();
                },
                child: Text(context.l10n.commonRetry),
              ),
            ],
          ),
        ),
      );
    }

    if (_progress == null) {
      return Center(
        child: Text(context.l10n.progressNoData),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProgress,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewSection(),
            const SizedBox(height: 24),
            _buildTodaySection(),
            const SizedBox(height: 24),
            _buildContentSection(),
            const SizedBox(height: 24),
            _buildQuizSection(),
            const SizedBox(height: 24),
            _buildSkillsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    final overview = _progress!.overview;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.progressOverview,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _OverviewCard(
                icon: Icons.check_circle_outline,
                label: context.l10n.progressCompletedTasks,
                value: overview.completedTaskCount.toString(),
                subtitle: context.l10n.progressUnitTotal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _OverviewCard(
                icon: Icons.timer_outlined,
                label: context.l10n.progressLearningTime,
                value: '${overview.estimatedLearningMinutes}',
                subtitle: context.l10n.progressUnitMinutes,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _OverviewCard(
                icon: Icons.calendar_today_outlined,
                label: context.l10n.progressCompletedPlans,
                value: overview.completedPlanCount.toString(),
                subtitle: context.l10n.progressUnitPlans,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _OverviewCard(
                icon: Icons.local_fire_department_outlined,
                label: context.l10n.progressActiveDays,
                value: overview.activeDayCount.toString(),
                subtitle: context.l10n.progressUnitDays,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodaySection() {
    final today = _progress!.today;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.progressToday,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        today.hasPlan
                            ? context.l10n.progressTodayPlan
                            : context.l10n.progressNoPlanToday,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: today.hasPlan
                              ? context.colors.primary
                              : context.colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      context.l10n.progressPercentSuffix(today.progressPercent),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: today.progressPercent > 0
                            ? context.colors.primary
                            : context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(10),
                  ),
                  child: LinearProgressIndicator(
                    value: today.totalMinutes > 0
                        ? today.completedMinutes / today.totalMinutes
                        : 0,
                    minHeight: 12,
                    backgroundColor: context.colors.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _TodayStat(
                      icon: Icons.task_outlined,
                      label: context.l10n.progressTasks,
                      value: '${today.completedTasks}/${today.totalTasks}',
                    ),
                    _TodayStat(
                      icon: Icons.timer,
                      label: context.l10n.progressDuration,
                      value: context.l10n.progressMinutesOfTotal(
                        today.completedMinutes,
                        today.totalMinutes,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection() {
    final content = _progress!.content;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.progressContentTitle,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ContentCard(
                icon: Icons.check_circle,
                color: context.statusColors.success,
                label: context.l10n.progressCompleted,
                value: content.completedCount.toString(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ContentCard(
                icon: Icons.play_circle_outline,
                color: context.statusColors.warning,
                label: context.l10n.progressInProgress,
                value: content.inProgressCount.toString(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuizSection() {
    final quiz = _progress!.quiz;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.progressQuizTitle,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        context.l10n.progressQuizSummary,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (quiz.attemptCount > 0)
                      Text(
                        context.l10n.progressQuizAttempts(quiz.attemptCount),
                        style: TextStyle(
                          color: context.colors.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (quiz.attemptCount == 0)
                  Text(
                    context.l10n.progressNoQuizAttempts,
                    style: TextStyle(
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
                          label: context.l10n.progressBestScore,
                          value: quiz.bestScore != null
                              ? context.l10n.commonPercent(quiz.bestScore!)
                              : '-',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuizStat(
                          icon: Icons.calculate_outlined,
                          label: context.l10n.progressAverage,
                          value: quiz.averageScore != null
                              ? context.l10n.commonPercent(quiz.averageScore!)
                              : '-',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuizStat(
                          icon: Icons.history,
                          label: context.l10n.progressLatestScore,
                          value: quiz.latestScore != null
                              ? context.l10n.commonPercent(quiz.latestScore!)
                              : '-',
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    final skills = _progress!.skills;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.progressSkillsTitle,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.progressSkillsSummary(
            skills.totalCount,
            skills.startedCount,
          ),
          style: TextStyle(
            color: context.colors.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        if (skills.strongest.isNotEmpty) ...[
          Text(
            context.l10n.progressStrongestSkills,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.statusColors.success,
            ),
          ),
          const SizedBox(height: 8),
          ...skills.strongest.map((skill) => _SkillCard(
                skill: skill,
                color: context.statusColors.success,
              )),
          const SizedBox(height: 24),
        ],
        if (skills.focus.isNotEmpty) ...[
          Text(
            context.l10n.progressFocusSkills,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.statusColors.warning,
            ),
          ),
          const SizedBox(height: 8),
          ...skills.focus.map((skill) => _SkillCard(
                skill: skill,
                color: context.statusColors.warning,
              )),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: context.colors.primary,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: context.colors.outline,
                fontSize: 10,
              ),
            ),
          ],
        ),
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
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: context.colors.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ContentCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _ContentCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
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
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: context.colors.tertiary,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.colors.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _SkillCard extends StatelessWidget {
  final SkillProgressSnapshot skill;
  final Color color;

  const _SkillCard({
    required this.skill,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skill.skillName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (skill.category.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      skill.category,
                      style: TextStyle(
                        color: context.colors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  Text(
                    context.l10n.progressPercentSuffix(skill.progressPercent),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    textAlign: TextAlign.end,
                  ),
                  const SizedBox(height: 1),
                  ClipRRect(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(2),
                    ),
                    child: LinearProgressIndicator(
                      value: skill.progressPercent / 100,
                      minHeight: 3,
                      backgroundColor: color.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
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