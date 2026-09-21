import 'package:flutter/material.dart';

import '../../../core/design/design_system.dart';
import '../../../core/localization/domain_labels.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../models/skill_gap_response.dart';

/// Yolum ekranındaki "Becerilerim": her beceri için mevcut durum, hedef
/// durum ve ilerleme. Yüzde tek başına gösterilmez; ne anlama geldiği yazılır.
class SkillGapList extends StatelessWidget {
  final SkillGapResponse gap;

  const SkillGapList({super.key, required this.gap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (gap.items.isEmpty) {
      return MenzilimInlineEmpty(
        message: l10n.skillGapEmptyTitle,
        hint: l10n.skillGapSubtitle,
      );
    }

    final priority = gap.priority(3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (priority.isNotEmpty) ...[
          Text(
            l10n.skillGapPriorityTitle,
            style: context.textStyles.labelLarge?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final item in priority)
                MenzilimChip(
                  label: item.skillName,
                  tone: MenzilimChipTone.primary,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        ...gap.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _SkillGapCard(item: item),
          ),
        ),
      ],
    );
  }
}

class _SkillGapCard extends StatelessWidget {
  final SkillGapItem item;

  const _SkillGapCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final status = context.statusColors;

    final (icon, iconColor) = switch (item.status) {
      'Reached' => (Icons.check_circle, status.success),
      'Developing' => (Icons.incomplete_circle, colors.primary),
      'NeedsWork' => (Icons.trending_up, colors.primary),
      _ => (Icons.circle_outlined, colors.onSurfaceVariant),
    };

    return MenzilimCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  item.skillName,
                  style: context.textStyles.titleSmall,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                context.gapStatusLabel(item.status),
                style: context.textStyles.labelMedium?.copyWith(
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Hedefe ne kadar yaklaşıldığı; çubuk hedef eşiğine göre doludur.
          MenzilimProgressBar(value: item.targetProgress),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              Text(
                '${l10n.skillGapCurrentLabel}: '
                '${context.skillLevelLabel(item.currentLevel)}',
                style: context.textStyles.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              Text(
                '${l10n.skillGapTargetLabel}: '
                '${context.skillLevelLabel(item.targetLevel)}',
                style: context.textStyles.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              Text(
                l10n.skillGapProgressExplained(item.progressPercent),
                style: context.textStyles.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
