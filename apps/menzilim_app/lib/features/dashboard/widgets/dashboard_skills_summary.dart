import 'package:flutter/material.dart';

import '../../../core/design/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';

import '../../skills/models/skill_progress_response.dart';

/// Dashboard'daki "Becerilerim" özet kartı. Veriyi kendisi yüklemez;
/// yükleme/hata durumu DashboardScreen'den gelir.
class DashboardSkillsSummary extends StatelessWidget {
  static const int maxSkills = 3;

  final List<SkillProgressResponse> skills;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onViewAll;

  const DashboardSkillsSummary({
    super.key,
    required this.skills,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return MenzilimCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights_outlined,
                size: 20,
                color: context.colors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.skillsSummaryTitle,
                  style: context.textStyles.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildBody(context),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    // Yenileme sırasında mevcut veri korunur; spinner yalnızca veri yokken.
    if (isLoading && skills.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.sm,
        children: [
          Text(errorMessage!),
          TextButton(
            onPressed: onRetry,
            child: Text(context.l10n.commonRetry),
          ),
        ],
      );
    }

    final started = skills
        .where((skill) => skill.progressPercent > 0)
        .toList()
      // En çok ilerlenen önce; eşitlikte ada göre (List.sort kararlı değil).
      ..sort((a, b) {
        final byProgress = b.progressPercent.compareTo(a.progressPercent);
        return byProgress != 0
            ? byProgress
            : a.skillName.compareTo(b.skillName);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.skillsSummaryCounts(skills.length, started.length),
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (started.isEmpty)
          Text(
            context.l10n.skillsSummaryEmpty,
            style: context.textStyles.bodyMedium,
          )
        else
          ...started.take(maxSkills).map(
                (skill) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _SkillSummaryRow(skill: skill),
                ),
              ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onViewAll,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: Text(context.l10n.skillsViewAll),
          ),
        ),
      ],
    );
  }
}

class _SkillSummaryRow extends StatelessWidget {
  final SkillProgressResponse skill;

  const _SkillSummaryRow({
    required this.skill,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                skill.skillName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              context.l10n.commonPercent(skill.progressPercent),
              style: context.textStyles.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        MenzilimProgressBar(value: skill.progressPercent / 100),
      ],
    );
  }
}
