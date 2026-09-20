import 'package:flutter/material.dart';

import '../../../core/design/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/onboarding_request.dart';
import '../models/profession.dart';
import '../models/specialization.dart';
import '../services/onboarding_service.dart';
import '../services/profession_service.dart';
import '../services/specialization_service.dart';
import '../../dashboard/screens/dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  /// Onboarding tamamlandığında çağrılır. AuthGate bunu verir ve sonraki
  /// ekrana geçişi kendisi yapar; verilmezse ekran Dashboard'ı kendisi açar.
  final VoidCallback? onCompleted;

  const OnboardingScreen({super.key, this.onCompleted});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final ApiClient _apiClient = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage();

  late final ProfessionService _professionService;
  late final SpecializationService _specializationService;
  late final OnboardingService _onboardingService;

  List<Profession> _professions = [];
  List<Specialization> _specializations = [];

  Profession? _selectedProfession;
  Specialization? _selectedSpecialization;

  String? _selectedExperienceLevel;
  String? _careerGoal;
  int? _selectedDailyMinutes;

  int _currentStep = 0;

  bool _isLoadingProfessions = true;
  bool _isLoadingSpecializations = false;
  bool _isSaving = false;

  String? _errorMessage;

  final TextEditingController _careerGoalController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    _professionService = ProfessionService(_apiClient);
    _specializationService = SpecializationService(_apiClient);
    _onboardingService = OnboardingService(_apiClient);

    _loadProfessions();
  }

  @override
  void dispose() {
    _careerGoalController.dispose();
    super.dispose();
  }

  Future<void> _loadProfessions() async {
    try {
      final professions = await _professionService.getProfessions();

      if (!mounted) return;

      setState(() {
        _professions = professions;
        _isLoadingProfessions = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingProfessions = false;
        _errorMessage = context.l10n.onboardingProfessionsLoadError;
      });
    }
  }

  Future<void> _selectProfession(Profession profession) async {
    setState(() {
      _selectedProfession = profession;
      _selectedSpecialization = null;
      _specializations = [];
      _currentStep = 1;
      _isLoadingSpecializations = true;
      _errorMessage = null;
    });

    try {
      final specializations =
          await _specializationService.getSpecializations(profession.id);

      if (!mounted) return;

      setState(() {
        _specializations = specializations;
        _isLoadingSpecializations = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingSpecializations = false;
        _errorMessage = context.l10n.onboardingSpecializationsLoadError;
      });
    }
  }

  void _selectSpecialization(Specialization specialization) {
    setState(() {
      _selectedSpecialization = specialization;
    });
  }

  void _selectExperienceLevel(String level) {
    setState(() {
      _selectedExperienceLevel = level;
    });
  }

  void _selectDailyMinutes(int minutes) {
    setState(() {
      _selectedDailyMinutes = minutes;
    });
  }

  void _goNext() {
    if (_currentStep == 0) {
      if (_selectedProfession == null) {
        _showMessage(context.l10n.onboardingSelectProfession);
        return;
      }

      return;
    }

    if (_currentStep == 1) {
      if (_selectedSpecialization == null) {
        _showMessage(context.l10n.onboardingSelectSpecialization);
        return;
      }

      setState(() {
        _currentStep = 2;
      });

      return;
    }

    if (_currentStep == 2) {
      if (_selectedExperienceLevel == null) {
        _showMessage(context.l10n.onboardingSelectExperience);
        return;
      }

      setState(() {
        _currentStep = 3;
      });

      return;
    }

    if (_currentStep == 3) {
      final goal = _careerGoalController.text.trim();

      if (goal.isEmpty) {
        _showMessage(context.l10n.onboardingEnterCareerGoal);
        return;
      }

      setState(() {
        _careerGoal = goal;
        _currentStep = 4;
      });

      return;
    }

    if (_currentStep == 4) {
      if (_selectedDailyMinutes == null) {
        _showMessage(context.l10n.onboardingSelectDailyTime);
        return;
      }

      _finishOnboarding();
    }
  }

  void _goBack() {
    if (_currentStep == 0 || _isSaving) {
      return;
    }

    setState(() {
      _currentStep--;
    });
  }

  Future<void> _finishOnboarding() async {
    if (_selectedProfession == null ||
        _selectedSpecialization == null ||
        _selectedExperienceLevel == null ||
        _careerGoal == null ||
        _selectedDailyMinutes == null) {
      return;
    }

    final token = await _tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      if (!mounted) return;

      _showMessage(
        context.l10n.commonSessionMissing,
      );

      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final request = OnboardingRequest(
        professionId: _selectedProfession!.id,
        specializationId: _selectedSpecialization!.id,
        experienceLevel: _selectedExperienceLevel!,
        careerGoal: _careerGoal!,
        dailyLearningMinutes: _selectedDailyMinutes!,
      );

      await _onboardingService.saveOnboarding(
        request,
        token,
      );

      if (!mounted) return;

      _showMessage(
        context.l10n.onboardingSaved,
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) return;

      final onCompleted = widget.onCompleted;
      if (onCompleted != null) {
        // Yönlendirmenin tek sahibi AuthGate'tir: profil kontrolünü
        // yeniler ve sonraki ekranı gösterir.
        onCompleted();
        return;
      }

      // pushReplacement kullanılmaz: altta AuthGate kalmazsa çıkış yapınca
      // Login'e dönülemez.
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        context.l10n.onboardingSaveFailed,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxReadingWidth,
            ),
            child: Padding(
              padding: AppSpacing.screen(
                MediaQuery.sizeOf(context).width,
              ),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildProgress(),
                  const SizedBox(height: 40),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _buildCurrentStep(),
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

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildProfessionStep();

      case 1:
        return _buildSpecializationStep();

      case 2:
        return _buildExperienceStep();

      case 3:
        return _buildCareerGoalStep();

      case 4:
        return _buildDailyTimeStep();

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const MenzilimLogo(markSize: 32),
        const Spacer(),
        MenzilimChip(
          label: context.l10n.onboardingStep(_currentStep + 1, 5),
        ),
      ],
    );
  }

  Widget _buildProgress() {
    return Row(
      children: List.generate(
        5,
        (index) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index == 4 ? 0 : 8,
              ),
              child: _ProgressBar(
                isActive: index <= _currentStep,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfessionStep() {
    if (_isLoadingProfessions) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState(
        onRetry: () {
          setState(() {
            _isLoadingProfessions = true;
            _errorMessage = null;
          });

          _loadProfessions();
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.onboardingProfessionTitle,
          style: context.textStyles.headlineMedium,
        ),
        const SizedBox(height: 12),
        Text(
          context.l10n.onboardingProfessionSubtitle,
          style: context.textStyles.bodyLarge?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: ListView.separated(
            itemCount: _professions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final profession = _professions[index];

              return _SelectionCard(
                title: profession.name,
                description: profession.isAvailable
                    ? profession.description
                    : context.l10n.onboardingComingSoonHint,
                icon: Icons.work_outline,
                isSelected:
                    _selectedProfession?.id == profession.id,
                // Hazır olmayan meslek seçilemez: kullanıcı boş bir
                // deneyime düşmez.
                isDisabled: !profession.isAvailable,
                badgeLabel: profession.isAvailable
                    ? null
                    : context.l10n.onboardingComingSoon,
                onTap: () {
                  _selectProfession(profession);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSpecializationStep() {
    if (_isLoadingSpecializations) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState(
        onRetry: () {
          if (_selectedProfession != null) {
            _selectProfession(_selectedProfession!);
          }
        },
      );
    }

    return _buildSelectionStep(
      title: context.l10n.onboardingSpecializationTitle,
      subtitle: context.l10n.onboardingSpecializationSubtitle(
        _selectedProfession?.name ?? '',
      ),
      items: _specializations
          .map(
            (specialization) => _SelectionCard(
              title: specialization.name,
              description: specialization.description,
              icon: Icons.code,
              isSelected:
                  _selectedSpecialization?.id == specialization.id,
              onTap: () {
                _selectSpecialization(specialization);
              },
            ),
          )
          .toList(),
    );
  }

  Widget _buildExperienceStep() {
    final l10n = context.l10n;

    // value backend'e gönderilir ve çevrilmez; yalnızca etiketler yerelleşir.
    final levels = [
      (
        value: 'Beginner',
        title: l10n.experienceBeginner,
        description: l10n.experienceBeginnerDescription,
        icon: Icons.eco_outlined,
      ),
      (
        value: 'Intermediate',
        title: l10n.experienceIntermediate,
        description: l10n.experienceIntermediateDescription,
        icon: Icons.trending_up,
      ),
      (
        value: 'Advanced',
        title: l10n.experienceAdvanced,
        description: l10n.experienceAdvancedDescription,
        icon: Icons.rocket_launch_outlined,
      ),
    ];

    return _buildSelectionStep(
      title: l10n.onboardingExperienceTitle,
      subtitle: l10n.onboardingExperienceSubtitle,
      items: levels
          .map(
            (level) => _SelectionCard(
              title: level.title,
              description: level.description,
              icon: level.icon,
              isSelected:
                  _selectedExperienceLevel == level.value,
              onTap: () {
                _selectExperienceLevel(level.value);
              },
            ),
          )
          .toList(),
    );
  }

  Widget _buildCareerGoalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBackButton(),
        const SizedBox(height: 24),
        Text(
          context.l10n.onboardingCareerGoalTitle,
          style: context.textStyles.headlineMedium,
        ),
        const SizedBox(height: 12),
        Text(
          context.l10n.onboardingCareerGoalSubtitle,
          style: context.textStyles.bodyLarge?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _careerGoalController,
          maxLines: 5,
          onChanged: (_) {
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: context.l10n.onboardingCareerGoalHint,
          ),
        ),
        const Spacer(),
        _buildNextButton(),
      ],
    );
  }

  Widget _buildDailyTimeStep() {
    final l10n = context.l10n;

    final times = [
      (30, l10n.dailyTime30, l10n.dailyTime30Description),
      (60, l10n.dailyTime60, l10n.dailyTime60Description),
      (90, l10n.dailyTime90, l10n.dailyTime90Description),
      (120, l10n.dailyTime120, l10n.dailyTime120Description),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBackButton(),
        const SizedBox(height: 24),
        Text(
          l10n.onboardingDailyTimeTitle,
          style: context.textStyles.headlineMedium,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.onboardingDailyTimeSubtitle,
          style: context.textStyles.bodyLarge?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: ListView.separated(
            itemCount: times.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final time = times[index];

              return _SelectionCard(
                title: time.$2,
                description: time.$3,
                icon: Icons.schedule_outlined,
                isSelected:
                    _selectedDailyMinutes == time.$1,
                onTap: () {
                  _selectDailyMinutes(time.$1);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        _buildNextButton(
          text: _isSaving
              ? l10n.onboardingSaving
              : l10n.onboardingFinish,
        ),
      ],
    );
  }

  Widget _buildSelectionStep({
    required String title,
    required String subtitle,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBackButton(),
        const SizedBox(height: 24),
        Text(
          title,
          style: context.textStyles.headlineMedium,
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: context.textStyles.bodyLarge?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              return items[index];
            },
          ),
        ),
        const SizedBox(height: 20),
        _buildNextButton(),
      ],
    );
  }

  Widget _buildNextButton({
    String? text,
  }) {
    final canContinue = _canContinue();

    return MenzilimButton(
      label: text ?? context.l10n.commonContinue,
      onPressed: canContinue && !_isSaving ? _goNext : null,
      icon: Icons.arrow_forward,
    );
  }

  bool _canContinue() {
    switch (_currentStep) {
      case 0:
        return _selectedProfession != null;

      case 1:
        return _selectedSpecialization != null;

      case 2:
        return _selectedExperienceLevel != null;

      case 3:
        return _careerGoalController.text.trim().isNotEmpty;

      case 4:
        return _selectedDailyMinutes != null;

      default:
        return false;
    }
  }

  Widget _buildBackButton() {
    return TextButton.icon(
      onPressed: _isSaving ? null : _goBack,
      icon: const Icon(Icons.arrow_back),
      label: Text(context.l10n.commonBack),
    );
  }

  Widget _buildErrorState({
    required VoidCallback onRetry,
  }) {
    return MenzilimErrorView(
      message: _errorMessage ?? context.l10n.commonErrorGeneric,
      onRetry: onRetry,
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final String title;
  final String? description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  /// Seçilemeyen kart (ör. hazır olmayan meslek).
  final bool isDisabled;

  /// Kartın sağında gösterilen kısa etiket (ör. "Yakında").
  final String? badgeLabel;

  const _SelectionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.isDisabled = false,
    this.badgeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;

    return Opacity(
      opacity: isDisabled ? 0.55 : 1,
      child: MenzilimCard(
      onTap: isDisabled ? null : onTap,
      selected: isSelected,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          AnimatedContainer(
            duration: AppDurations.fast,
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              icon,
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textStyles.titleMedium,
                ),
                if (description != null && description!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description!,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (badgeLabel != null)
            MenzilimChip(label: badgeLabel!)
          else
            Icon(
              isSelected ? Icons.check_circle : Icons.arrow_forward_ios,
              size: isSelected ? 24 : 16,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
        ],
      ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final bool isActive;

  const _ProgressBar({
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.medium,
      height: 6,
      decoration: BoxDecoration(
        color: isActive
            ? context.colors.primary
            : context.colors.surfaceContainerHighest,
        borderRadius: AppRadius.pillRadius,
      ),
    );
  }
}
