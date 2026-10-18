import 'package:flutter/material.dart';

import '../../../core/design/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../news/services/news_link_opener.dart';
import '../models/user_project.dart';

/// Proje özeti: kullanıcının ürettiği işin paylaşılabilir görünümü.
/// Kalıcı bir portfolyo kaydı tutulmaz; mevcut proje verisinden üretilir.
class ProjectSummaryScreen extends StatelessWidget {
  final UserProject project;

  /// Testlerde sahte bağlantı açıcı verilebilir.
  final NewsLinkOpener? openLink;

  const ProjectSummaryScreen({
    super.key,
    required this.project,
    this.openLink,
  });

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    final opener = openLink ?? openNewsLinkExternally;

    if (uri == null || !await opener(uri)) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.evidenceOpenError)),
      );
    }
  }

  String _date(BuildContext context, DateTime? value) {
    if (value == null) return '—';

    final local = value.toLocal();

    return context.l10n.newsDate(
      local.day,
      context.l10n.monthName(local.month.toString()),
      local.year.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    final completed = project.completedStepList;
    final evidences = project.evidenceSteps;

    final elapsedDays = project.startedAt == null || project.completedAt == null
        ? null
        : project.completedAt!.difference(project.startedAt!).inDays;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.summaryTitle)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.maxReadingWidth,
              ),
              child: ListView(
                padding: AppSpacing.screen(constraints.maxWidth),
                children: [
                  // Başlık kartı
                  MenzilimCard(
                    tone: MenzilimCardTone.primary,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (project.isCompleted)
                          MenzilimChip(
                            label: l10n.projectCompletedBanner,
                            icon: Icons.verified_outlined,
                            tone: MenzilimChipTone.success,
                          ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          project.name,
                          style: context.textStyles.headlineSmall,
                        ),
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
                            ),
                            MenzilimChip(
                              label: l10n.commonMinutesShort(
                                project.totalMinutes,
                              ),
                              icon: Icons.schedule_outlined,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (!project.isCompleted) ...[
                    const SizedBox(height: AppSpacing.lg),
                    MenzilimInlineEmpty(
                      message: l10n.summaryInProgressTitle,
                      hint: l10n.summaryInProgressHint,
                    ),
                  ],

                  // Ne yaptım?
                  const SizedBox(height: AppSpacing.section),
                  MenzilimSectionHeader(title: l10n.summaryWhatIDidTitle),
                  MenzilimCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      _whatIDid(context),
                      style: context.textStyles.bodyLarge,
                    ),
                  ),

                  // Kullanılan beceriler
                  if (project.usedSkills.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.section),
                    MenzilimSectionHeader(title: l10n.summarySkillsTitle),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final skill in project.usedSkills)
                          MenzilimChip(
                            label: skill,
                            icon: Icons.bolt_outlined,
                            tone: MenzilimChipTone.secondary,
                          ),
                      ],
                    ),
                  ],

                  // Tamamlanan adımlar
                  const SizedBox(height: AppSpacing.section),
                  MenzilimSectionHeader(title: l10n.summaryStepsTitle),
                  if (completed.isEmpty)
                    MenzilimInlineEmpty(message: l10n.summaryInProgressHint)
                  else
                    ...completed.map(
                      (step) => _SummaryStepRow(
                        step: step,
                        date: _date(context, step.completedAt),
                      ),
                    ),

                  // Kanıtlar
                  const SizedBox(height: AppSpacing.section),
                  MenzilimSectionHeader(title: l10n.summaryEvidenceTitle),
                  if (evidences.isEmpty)
                    MenzilimInlineEmpty(message: l10n.summaryEvidenceEmpty)
                  else
                    ...evidences.map(
                      (step) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: MenzilimCard(
                          onTap: () => _open(context, step.evidenceUrl!),
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Row(
                            children: [
                              Icon(Icons.link, color: colors.primary),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      step.title,
                                      style: context.textStyles.titleSmall,
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      step.note ?? step.evidenceUrl!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.textStyles.bodySmall
                                          ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.open_in_new,
                                size: 18,
                                color: colors.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Öğrenme özeti + tarihler
                  const SizedBox(height: AppSpacing.section),
                  MenzilimSectionHeader(title: l10n.summaryLearningTitle),
                  MenzilimCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.summaryLearningBody(completed.length),
                          style: context.textStyles.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _SummaryFact(
                          label: l10n.summaryStartedAt,
                          value: _date(context, project.startedAt),
                        ),
                        _SummaryFact(
                          label: l10n.summaryCompletedAt,
                          value: _date(context, project.completedAt),
                        ),
                        _SummaryFact(
                          label: l10n.summaryPlannedDuration,
                          value: l10n.commonMinutes(project.totalMinutes),
                        ),
                        if (elapsedDays != null)
                          _SummaryFact(
                            label: l10n.summaryElapsedDays,
                            value: l10n.summaryDays(elapsedDays),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Center(child: MenzilimLogoMark(size: 28)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// "Ne yaptım?": kullanıcının notları varsa onlar, yoksa proje açıklaması.
  String _whatIDid(BuildContext context) {
    final notes = project.steps
        .where((step) => step.note != null && step.note!.isNotEmpty)
        .map((step) => step.note!)
        .toList();

    if (notes.isNotEmpty) {
      return notes.join('\n\n');
    }

    return project.description ?? context.l10n.summaryInProgressHint;
  }
}

class _SummaryStepRow extends StatelessWidget {
  final UserProjectStep step;
  final String date;

  const _SummaryStepRow({required this.step, required this.date});

  @override
  Widget build(BuildContext context) {
    final status = context.statusColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 18, color: status.success),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(step.title, style: context.textStyles.bodyLarge),
          ),
          Text(
            date,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryFact extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryFact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
          Text(value, style: context.textStyles.bodyMedium),
        ],
      ),
    );
  }
}
