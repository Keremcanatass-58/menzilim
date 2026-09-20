import 'package:flutter/material.dart';

import '../../../core/design/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/skill_progress_response.dart';
import '../services/skill_service.dart';

class SkillsScreen extends StatefulWidget {
  // Testlerde sahte servis verilebilir; normalde gerçek API kullanılır.
  final SkillService? skillService;

  const SkillsScreen({
    super.key,
    this.skillService,
  });

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  late final SkillService _skillService =
      widget.skillService ?? SkillService(ApiClient());

  final TokenStorage _tokenStorage = TokenStorage();

  List<SkillProgressResponse> _skills = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Oturum bilgisi bulunamadı.');
      }

      final skills = await _skillService.getMySkills(token);

      if (!mounted) return;

      setState(() {
        _skills = skills;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = context.l10n.skillsLoadError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.skillsTitle)),
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

          _loadSkills();
        },
      );
    }

    if (_skills.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadSkills,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            MenzilimEmptyView(
              icon: Icons.insights_outlined,
              message: context.l10n.skillsEmpty,
            ),
          ],
        ),
      );
    }

    final startedCount =
        _skills.where((skill) => skill.progressPercent > 0).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppBreakpoints.tablet;

        return RefreshIndicator(
          onRefresh: _loadSkills,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.maxContentWidth,
              ),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppSpacing.screen(constraints.maxWidth),
                children: [
                  MenzilimSectionHeader(
                    title: context.l10n.skillsMapTitle,
                    subtitle: context.l10n.skillsMapSubtitle(
                      _skills.length,
                      startedCount,
                    ),
                  ),
                  // Geniş ekranda iki kolon; dar ekranda tek kolon.
                  if (isWide)
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: [
                        for (final skill in _skills)
                          SizedBox(
                            width: (constraints.maxWidth.clamp(
                                          0,
                                          AppBreakpoints.maxContentWidth,
                                        ) -
                                        AppSpacing.screenWide.horizontal -
                                        AppSpacing.md) /
                                    2 -
                                0.01,
                            child: _SkillCard(skill: skill),
                          ),
                      ],
                    )
                  else
                    ..._skills.map(
                      (skill) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _SkillCard(skill: skill),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SkillCard extends StatelessWidget {
  final SkillProgressResponse skill;

  const _SkillCard({
    required this.skill,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final started = skill.progressPercent > 0;

    return MenzilimCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.skillName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.titleMedium,
                    ),
                    if (skill.category.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      MenzilimChip(
                        label: skill.category,
                        tone: MenzilimChipTone.primary,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                context.l10n.commonPercent(skill.progressPercent),
                style: context.textStyles.headlineSmall?.copyWith(
                  color: started ? colors.primary : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          MenzilimProgressBar(
            value: skill.progressPercent / 100,
            height: 10,
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              _StatItem(
                icon: Icons.menu_book_outlined,
                label: context.l10n.skillsStatContent(
                  skill.completedContentCount,
                  skill.totalContentCount,
                ),
              ),
              _StatItem(
                icon: Icons.quiz_outlined,
                label: context.l10n.skillsStatQuiz(
                  skill.attemptedQuizCount,
                  skill.totalQuizCount,
                ),
              ),
              if (skill.inProgressContentCount > 0)
                _StatItem(
                  icon: Icons.timelapse_outlined,
                  label: context.l10n.skillsStatInProgress(
                    skill.inProgressContentCount,
                  ),
                ),
              if (skill.bestQuizScore != null)
                _StatItem(
                  icon: Icons.emoji_events_outlined,
                  label: context.l10n.skillsStatBestScore(skill.bestQuizScore!),
                ),
              if (skill.latestQuizScore != null)
                _StatItem(
                  icon: Icons.history,
                  label: context.l10n.skillsStatLatestScore(
                    skill.latestQuizScore!,
                  ),
                ),
            ],
          ),
          if (!skill.hasLearningMaterial) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.skillsNoMaterial,
              style: context.textStyles.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: context.colors.onSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        // Çok dar ekranda etiket taşmak yerine alt satıra geçer.
        Flexible(
          child: Text(
            label,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
