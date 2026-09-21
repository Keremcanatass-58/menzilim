import 'package:flutter/material.dart';

import '../../../core/design/design_system.dart';
import '../../../core/localization/domain_labels.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../dashboard/models/dashboard_response.dart';
import '../../dashboard/services/dashboard_service.dart';
import '../../projects/models/user_project.dart';
import '../../projects/services/project_service.dart';

/// Onboarding'den sonra gösterilir: kullanıcı ilk kez "yolunu" görür.
/// Sakin, tek aksiyonlu bir ekrandır; CTA uygulamaya geçirir.
class PathIntroScreen extends StatefulWidget {
  final VoidCallback onStart;

  // Testlerde sahte servisler verilebilir.
  final DashboardService? dashboardService;
  final ProjectService? projectService;

  const PathIntroScreen({
    super.key,
    required this.onStart,
    this.dashboardService,
    this.projectService,
  });

  @override
  State<PathIntroScreen> createState() => _PathIntroScreenState();
}

class _PathIntroScreenState extends State<PathIntroScreen> {
  late final DashboardService _dashboardService =
      widget.dashboardService ?? DashboardService(ApiClient());

  late final ProjectService _projectService =
      widget.projectService ?? ProjectService(ApiClient());

  final TokenStorage _tokenStorage = TokenStorage();

  DashboardResponse? _dashboard;
  UserProject? _project;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Oturum bilgisi bulunamadı.');
      }

      final dashboard = await _dashboardService.getDashboard(token);

      List<UserProject> projects = const [];
      try {
        projects = await _projectService.getMyProjects(token);
      } catch (_) {
        // Proje yüklenemezse yol özeti yine gösterilir.
      }

      if (!mounted) return;

      setState(() {
        _dashboard = dashboard;
        _project = projects.isEmpty ? null : projects.first;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      // Özet alınamazsa kullanıcı akışta tıkanmaz: doğrudan devam eder.
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dashboard = _dashboard;
    final project = _project;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.maxReadingWidth,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: AppSpacing.screen(constraints.maxWidth),
                      children: [
                        const MenzilimLogo(markSize: 32),
                        const SizedBox(height: AppSpacing.xl),
                        MenzilimEntrance(
                          order: 0,
                          child: Text(
                            l10n.pathIntroTitle,
                            style: context.textStyles.headlineMedium,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.pathIntroSubtitle,
                          style: context.textStyles.bodyMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                        if (dashboard != null) ...[
                          const SizedBox(height: AppSpacing.xl),
                          MenzilimEntrance(
                            order: 1,
                            child: Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                MenzilimChip(
                                  label: dashboard.profession,
                                  icon: Icons.work_outline,
                                  tone: MenzilimChipTone.primary,
                                ),
                                MenzilimChip(
                                  label: dashboard.specialization,
                                  icon: Icons.alt_route,
                                ),
                                MenzilimChip(
                                  label: context.skillLevelLabel(
                                    dashboard.experienceLevel,
                                  ),
                                  icon: Icons.stairs_outlined,
                                ),
                                MenzilimChip(
                                  label: l10n.pathIntroDailyTime(
                                    dashboard.dailyLearningMinutes,
                                  ),
                                  icon: Icons.schedule_outlined,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.section),
                          MenzilimEntrance(
                            order: 2,
                            child: MenzilimCard(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.pathIntroGoalTitle,
                                    style: context.textStyles.labelLarge
                                        ?.copyWith(
                                      color: context.colors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    dashboard.careerGoal,
                                    style: context.textStyles.titleMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (project != null) ...[
                          const SizedBox(height: AppSpacing.section),
                          MenzilimEntrance(
                            order: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                MenzilimSectionHeader(
                                  title: l10n.projectRoadmapTitle,
                                ),
                                _PathSteps(project: project),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.section),
                          MenzilimEntrance(
                            order: 4,
                            child: MenzilimCard(
                              tone: MenzilimCardTone.primary,
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.pathIntroOutcomeTitle,
                                    style: context.textStyles.labelLarge
                                        ?.copyWith(
                                      color: context.colors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    project.name,
                                    style: context.textStyles.titleLarge,
                                  ),
                                  if (project.description != null) ...[
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      project.description!,
                                      style: context.textStyles.bodyMedium,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.screen(constraints.maxWidth).left,
                      AppSpacing.md,
                      AppSpacing.screen(constraints.maxWidth).right,
                      AppSpacing.xl,
                    ),
                    child: MenzilimButton(
                      label: l10n.pathIntroCta,
                      icon: Icons.arrow_forward,
                      onPressed: widget.onStart,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Yolun fazları: dikey, numaralı ve sakin.
class _PathSteps extends StatelessWidget {
  final UserProject project;

  const _PathSteps({required this.project});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        for (final step in project.steps)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${step.order}',
                    style: context.textStyles.labelMedium,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      step.title,
                      style: context.textStyles.bodyLarge,
                    ),
                  ),
                ),
                Text(
                  context.l10n.commonMinutesShort(step.estimatedMinutes),
                  style: context.textStyles.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
