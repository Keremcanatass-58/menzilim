import 'package:flutter/material.dart';

import '../../../core/auth/auth_scope.dart';
import '../../../core/design/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../dashboard/models/dashboard_response.dart';
import '../../dashboard/services/dashboard_service.dart';
import '../../onboarding/models/onboarding_profile.dart';
import '../../onboarding/models/onboarding_request.dart';
import '../../onboarding/models/specialization.dart';
import '../../onboarding/services/onboarding_service.dart';
import '../../onboarding/services/specialization_service.dart';
import '../../progress/models/progress_response.dart';
import '../../progress/screens/progress_screen.dart';
import '../../progress/services/progress_service.dart';
import '../../settings/screens/settings_screen.dart';

/// "Profil" sekmesi: kimlik, yol bilgileri, ilerleme özeti ve ayarlar.
/// Uzmanlık/seviye/hedef/günlük süre mevcut onboarding ucuyla güncellenir.
class ProfileScreen extends StatefulWidget {
  // Testlerde sahte servisler verilebilir.
  final DashboardService? dashboardService;
  final OnboardingService? onboardingService;
  final SpecializationService? specializationService;
  final ProgressService? progressService;

  const ProfileScreen({
    super.key,
    this.dashboardService,
    this.onboardingService,
    this.specializationService,
    this.progressService,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final DashboardService _dashboardService =
      widget.dashboardService ?? DashboardService(ApiClient());

  late final OnboardingService _onboardingService =
      widget.onboardingService ?? OnboardingService(ApiClient());

  late final SpecializationService _specializationService =
      widget.specializationService ?? SpecializationService(ApiClient());

  late final ProgressService _progressService =
      widget.progressService ?? ProgressService(ApiClient());

  final TokenStorage _tokenStorage = TokenStorage();

  DashboardResponse? _dashboard;
  OnboardingProfile? _profile;
  ProgressResponse? _progress;
  String? _email;

  bool _isLoading = true;
  String? _errorMessage;

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

      final email = await _tokenStorage.getEmail();
      final dashboard = await _dashboardService.getDashboard(token);
      final profile = await _onboardingService.getProfile(token);

      ProgressResponse? progress;
      try {
        progress = await _progressService.getMyProgress(token);
      } catch (_) {
        // İlerleme özeti alınamazsa profil yine gösterilir.
      }

      if (!mounted) return;

      setState(() {
        _email = email;
        _dashboard = dashboard;
        _profile = profile;
        _progress = progress;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = context.l10n.profileLoadError;
      });
    }
  }

  Future<void> _openEditor() async {
    final profile = _profile;

    if (profile == null) return;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ProfileEditorSheet(
        profile: profile,
        specializationService: _specializationService,
        onSave: _save,
      ),
    );

    if (saved == true && mounted) {
      setState(() {
        _isLoading = true;
      });

      await _load();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.profileSaved)),
      );
    }
  }

  Future<void> _save(OnboardingRequest request) async {
    final token = await _tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Oturum bilgisi bulunamadı.');
    }

    await _onboardingService.saveOnboarding(request, token);
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _openProgress() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProgressScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileScreenTitle)),
      body: SafeArea(child: _buildBody(l10n)),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
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

          _load();
        },
      );
    }

    final dashboard = _dashboard!;
    final progress = _progress;

    return LayoutBuilder(
      builder: (context, constraints) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.maxReadingWidth,
          ),
          child: ListView(
            padding: AppSpacing.screen(constraints.maxWidth),
            children: [
              _IdentityCard(email: _email),
              const SizedBox(height: AppSpacing.section),
              MenzilimSectionHeader(
                title: l10n.profileEditTitle,
                subtitle: l10n.profileEditSubtitle,
                actionLabel: _profile == null ? null : l10n.profileEditAction,
                onAction: _profile == null ? null : _openEditor,
              ),
              MenzilimCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.work_outline,
                      label: l10n.profileProfession,
                      value: dashboard.profession,
                    ),
                    const Divider(),
                    _InfoRow(
                      icon: Icons.alt_route,
                      label: l10n.profileSpecialization,
                      value: dashboard.specialization,
                    ),
                    const Divider(),
                    _InfoRow(
                      icon: Icons.stairs_outlined,
                      label: l10n.profileLevel,
                      value: dashboard.experienceLevel,
                    ),
                    const Divider(),
                    _InfoRow(
                      icon: Icons.schedule_outlined,
                      label: l10n.profileDailyTime,
                      value: l10n.commonMinutes(dashboard.dailyLearningMinutes),
                    ),
                    const Divider(),
                    _InfoRow(
                      icon: Icons.flag_outlined,
                      label: l10n.profileCareerGoal,
                      value: dashboard.careerGoal,
                    ),
                  ],
                ),
              ),
              if (progress != null) ...[
                const SizedBox(height: AppSpacing.section),
                MenzilimSectionHeader(
                  title: l10n.profileProgressTitle,
                  actionLabel: l10n.dashboardViewProgress,
                  onAction: _openProgress,
                ),
                MenzilimCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Wrap(
                    spacing: AppSpacing.xl,
                    runSpacing: AppSpacing.lg,
                    children: [
                      _ProgressStat(
                        value: '${progress.overview.completedTaskCount}',
                        label: l10n.progressCompletedTasks,
                      ),
                      _ProgressStat(
                        value: '${progress.overview.estimatedLearningMinutes}',
                        label: l10n.progressLearningTime,
                      ),
                      _ProgressStat(
                        value: '${progress.content.completedCount}',
                        label: l10n.progressContentTitle,
                      ),
                      _ProgressStat(
                        value: '${progress.quiz.attemptCount}',
                        label: l10n.progressQuizTitle,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.section),
              MenzilimSectionHeader(
                title: l10n.profileSettingsTitle,
                subtitle: l10n.profileSettingsSubtitle,
              ),
              MenzilimCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MenzilimButton(
                      label: l10n.profileOpenSettings,
                      icon: Icons.settings_outlined,
                      variant: MenzilimButtonVariant.secondary,
                      onPressed: _openSettings,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Oturumu kapatır; yönlendirmeyi AuthGate yapar.
                    MenzilimButton(
                      label: l10n.settingsLogout,
                      icon: Icons.logout,
                      variant: MenzilimButtonVariant.text,
                      onPressed: () => AuthScope.of(context).logout(),
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
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final String? email;

  const _IdentityCard({this.email});

  @override
  Widget build(BuildContext context) {
    return MenzilimCard(
      tone: MenzilimCardTone.primary,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: [
          const MenzilimLogoMark(size: 44, boxed: true),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email ?? context.l10n.profileScreenTitle,
                  style: context.textStyles.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.l10n.appTagline,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: context.colors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(value, style: context.textStyles.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final String value;
  final String label;

  const _ProgressStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: context.textStyles.headlineSmall),
        Text(
          label,
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Uzmanlık, seviye, hedef ve günlük süreyi güncelleyen alt sayfa.
class _ProfileEditorSheet extends StatefulWidget {
  final OnboardingProfile profile;
  final SpecializationService specializationService;
  final Future<void> Function(OnboardingRequest request) onSave;

  const _ProfileEditorSheet({
    required this.profile,
    required this.specializationService,
    required this.onSave,
  });

  @override
  State<_ProfileEditorSheet> createState() => _ProfileEditorSheetState();
}

class _ProfileEditorSheetState extends State<_ProfileEditorSheet> {
  static const List<int> _minuteOptions = [30, 60, 90, 120];
  static const List<String> _levels = ['Beginner', 'Intermediate', 'Advanced'];

  late final TextEditingController _goalController =
      TextEditingController(text: widget.profile.careerGoal);

  late String _specializationId = widget.profile.specializationId;
  late String _level = _levels.contains(widget.profile.experienceLevel)
      ? widget.profile.experienceLevel
      : _levels.first;
  late int _minutes = _minuteOptions.contains(widget.profile.dailyLearningMinutes)
      ? widget.profile.dailyLearningMinutes
      : _minuteOptions[1];

  List<Specialization> _specializations = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSpecializations();
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _loadSpecializations() async {
    try {
      final items = await widget.specializationService
          .getSpecializations(widget.profile.professionId);

      if (!mounted) return;

      setState(() {
        _specializations = items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  String _levelLabel(String level) {
    final l10n = context.l10n;

    return switch (level) {
      'Beginner' => l10n.experienceBeginner,
      'Intermediate' => l10n.experienceIntermediate,
      'Advanced' => l10n.experienceAdvanced,
      _ => level,
    };
  }

  Future<void> _submit() async {
    final goal = _goalController.text.trim();

    if (goal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.onboardingEnterCareerGoal)),
      );

      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSave(
        OnboardingRequest(
          professionId: widget.profile.professionId,
          specializationId: _specializationId,
          experienceLevel: _level,
          careerGoal: goal,
          dailyLearningMinutes: _minutes,
        ),
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.profileSaveError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: CircularProgressIndicator(),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.profileEditTitle,
                    style: context.textStyles.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.profileSpecialization,
                    style: context.textStyles.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: _specializations.any(
                      (item) => item.id == _specializationId,
                    )
                        ? _specializationId
                        : null,
                    items: _specializations
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.id,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _specializationId = value;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.profileLevel,
                    style: context.textStyles.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: _levels
                          .map(
                            (level) => ButtonSegment(
                              value: level,
                              label: Text(_levelLabel(level)),
                            ),
                          )
                          .toList(),
                      selected: {_level},
                      onSelectionChanged: (selection) => setState(() {
                        _level = selection.first;
                      }),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.profileDailyTime,
                    style: context.textStyles.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: _minuteOptions
                        .map(
                          (minutes) => ChoiceChip(
                            label: Text(l10n.commonMinutesShort(minutes)),
                            selected: _minutes == minutes,
                            onSelected: (_) => setState(() {
                              _minutes = minutes;
                            }),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.profileCareerGoal,
                    style: context.textStyles.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _goalController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: l10n.onboardingCareerGoalHint,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  MenzilimButton(
                    label: l10n.profileSaveAction,
                    icon: Icons.check,
                    isLoading: _isSaving,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
    );
  }
}
