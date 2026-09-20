import 'package:flutter/material.dart';

import '../../../core/design/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../models/user_project.dart';

/// Dashboard'daki "Projem" kartı: ad, ilerleme ve sıradaki adım.
class ProjectCard extends StatelessWidget {
  final UserProject project;
  final VoidCallback onOpen;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final next = project.nextStep;

    return MenzilimCard(
      onTap: onOpen,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  project.name,
                  style: context.textStyles.titleLarge,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              MenzilimChip(
                label: l10n.projectStepsProgress(
                  project.completedSteps,
                  project.totalSteps,
                ),
                tone: project.isCompleted
                    ? MenzilimChipTone.success
                    : MenzilimChipTone.primary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          MenzilimProgressBar(value: project.progressPercent / 100),
          const SizedBox(height: AppSpacing.lg),
          if (project.isCompleted) ...[
            Text(
              l10n.projectCompletedTitle,
              style: context.textStyles.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.projectCompletedHint,
              style: context.textStyles.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ] else if (next != null) ...[
            Text(
              l10n.projectNextStepLabel,
              style: context.textStyles.labelLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(next.title, style: context.textStyles.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            MenzilimButton(
              label: l10n.projectStepCompleteAction,
              icon: Icons.flag_outlined,
              variant: MenzilimButtonVariant.secondary,
              onPressed: onOpen,
            ),
          ],
        ],
      ),
    );
  }
}
