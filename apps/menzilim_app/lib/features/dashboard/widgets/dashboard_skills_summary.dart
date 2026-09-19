import 'package:flutter/material.dart';

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(
          color: context.colors.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.insights_outlined,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.skillsSummaryTitle,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildBody(context),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    // Yenileme sırasında mevcut veri korunur; spinner yalnızca veri yokken.
    if (isLoading && skills.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
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

    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.skillsSummaryCounts(skills.length, started.length),
          style: TextStyle(
            color: context.colors.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 14),
        if (started.isEmpty)
          Text(
            context.l10n.skillsSummaryEmpty,
            style: const TextStyle(
              fontSize: 15,
            ),
          )
        else
          ...started.take(maxSkills).map(
                (skill) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SkillSummaryRow(skill: skill),
                ),
              ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onViewAll,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.skillsViewAll,
                  style: TextStyle(
                    color: primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: primary,
                ),
              ],
            ),
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
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              context.l10n.commonPercent(skill.progressPercent),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: const BorderRadius.all(
            Radius.circular(10),
          ),
          child: LinearProgressIndicator(
            value: skill.progressPercent / 100,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
