import 'package:flutter/material.dart';

import '../../../core/design/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../models/skill_gap_response.dart';

/// Dashboard'daki küçük beceri açığı özeti: kaç beceri geliştiriliyor ve
/// öncelikli üç beceri. Ayrıntı Yolum ekranındadır.
class SkillGapSummary extends StatelessWidget {
  final SkillGapResponse gap;
  final VoidCallback onViewPath;

  static const int _previewCount = 3;

  const SkillGapSummary({
    super.key,
    required this.gap,
    required this.onViewPath,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final priority = gap.priority(_previewCount);

    return MenzilimCard(
      onTap: onViewPath,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.skillGapDashboardTitle,
            style: context.textStyles.labelLarge?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            priority.isEmpty
                ? l10n.skillGapAllReached
                : l10n.skillGapDeveloping(gap.remainingCount),
            style: context.textStyles.titleMedium,
          ),
          if (priority.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final item in priority)
                  MenzilimChip(
                    label: item.skillName,
                    tone: item.isNotStarted
                        ? MenzilimChipTone.neutral
                        : MenzilimChipTone.primary,
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onViewPath,
              child: Text(l10n.skillGapViewPath),
            ),
          ),
        ],
      ),
    );
  }
}
