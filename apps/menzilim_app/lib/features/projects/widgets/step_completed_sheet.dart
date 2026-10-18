import 'package:flutter/material.dart';

import '../../../core/design/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../models/user_project.dart';
import '../screens/project_summary_screen.dart';

/// Adım tamamlandığında gösterilen kısa başarı geri bildirimi.
/// "Sonraki adıma geç" seçilirse o adım döner, aksi halde null.
Future<UserProjectStep?> showStepCompletedSheet({
  required BuildContext context,
  required UserProject project,
  required int completedStepOrder,
  String? skillName,
}) {
  return showModalBottomSheet<UserProjectStep>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _StepCompletedSheet(
      project: project,
      completedStepOrder: completedStepOrder,
      skillName: skillName,
    ),
  );
}

class _StepCompletedSheet extends StatelessWidget {
  final UserProject project;
  final int completedStepOrder;
  final String? skillName;

  const _StepCompletedSheet({
    required this.project,
    required this.completedStepOrder,
    this.skillName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final status = context.statusColors;

    final next = project.nextStep;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Kısa ve ölçülü kutlama: büyüyen onay işareti.
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.6, end: 1),
                duration: AppDurations.medium,
                curve: Curves.easeOutBack,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: status.successContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: status.success),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  l10n.stepDoneTitle,
                  style: context.textStyles.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          MenzilimProgressBar(value: project.progressPercent / 100),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.stepDoneProgress(project.completedSteps, project.totalSteps),
            style: context.textStyles.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          if (skillName != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.stepDoneSkill(skillName!),
              style: context.textStyles.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          if (project.isCompleted) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.projectCompletedTitle,
              style: context.textStyles.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.projectCompletedPortfolioHint,
              style: context.textStyles.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            MenzilimButton(
              label: l10n.projectOpenSummary,
              icon: Icons.workspace_premium_outlined,
              onPressed: () {
                // Sayfayı kapat, ardından özet ekranını aç.
                Navigator.of(context).pop();

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProjectSummaryScreen(project: project),
                  ),
                );
              },
            ),
          ] else if (next != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.stepDoneUnlocked,
              style: context.textStyles.bodyMedium?.copyWith(
                color: status.success,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            MenzilimCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.stepDoneNextLabel,
                    style: context.textStyles.labelLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(next.title, style: context.textStyles.titleMedium),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            MenzilimButton(
              label: l10n.stepDoneNextCta,
              icon: Icons.arrow_forward,
              onPressed: () => Navigator.of(context).pop(next),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                project.isCompleted
                    ? l10n.projectBackToProject
                    : l10n.stepDoneClose,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
