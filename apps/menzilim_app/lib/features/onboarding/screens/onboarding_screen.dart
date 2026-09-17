import 'package:flutter/material.dart';

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
  const OnboardingScreen({super.key});

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
        _errorMessage = 'Meslekler yüklenirken bir hata oluştu.';
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
        _errorMessage = 'Uzmanlıklar yüklenirken bir hata oluştu.';
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
        _showMessage('Lütfen bir meslek seç.');
        return;
      }

      return;
    }

    if (_currentStep == 1) {
      if (_selectedSpecialization == null) {
        _showMessage('Lütfen bir uzmanlık alanı seç.');
        return;
      }

      setState(() {
        _currentStep = 2;
      });

      return;
    }

    if (_currentStep == 2) {
      if (_selectedExperienceLevel == null) {
        _showMessage('Lütfen deneyim seviyeni seç.');
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
        _showMessage('Lütfen kariyer hedefini yaz.');
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
        _showMessage('Lütfen günlük öğrenme süresini seç.');
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
        'Oturum bilgisi bulunamadı. Lütfen tekrar giriş yap.',
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
        'Profilin başarıyla oluşturuldu. MENZİLİM yolculuğun başlıyor!',
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Profilin kaydedilemedi. Lütfen tekrar dene.',
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
              maxWidth: 760,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 24,
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
        const Text(
          'MENZİLİM',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const Spacer(),
        Text(
          '${_currentStep + 1} / 5',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
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
        const Text(
          'Kariyer yolculuğuna başlayalım.',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Hangi alanda kendini geliştirmek istiyorsun?',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey.shade700,
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
                description: profession.description,
                icon: Icons.work_outline,
                isSelected:
                    _selectedProfession?.id == profession.id,
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
      title: 'Uzmanlık alanını seç.',
      subtitle:
          '${_selectedProfession?.name} alanında hangi yönde ilerlemek istiyorsun?',
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
    final levels = [
      (
        value: 'Beginner',
        title: 'Başlangıç',
        description: 'Temel seviyeden başlıyorum.',
        icon: Icons.eco_outlined,
      ),
      (
        value: 'Intermediate',
        title: 'Orta',
        description: 'Temelleri biliyorum, kendimi geliştiriyorum.',
        icon: Icons.trending_up,
      ),
      (
        value: 'Advanced',
        title: 'İleri',
        description: 'Deneyimliyim ve uzmanlaşmak istiyorum.',
        icon: Icons.rocket_launch_outlined,
      ),
    ];

    return _buildSelectionStep(
      title: 'Kendini hangi seviyede görüyorsun?',
      subtitle:
          'Böylece öğrenme planını mevcut seviyene göre oluşturabiliriz.',
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
        const Text(
          'Kariyer hedefin nedir?',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'MENZİLİM sana uygun bir yol oluşturabilsin.',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey.shade700,
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
            hintText:
                'Örn: Backend alanında profesyonelleşmek ve işe girmek istiyorum.',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: const EdgeInsets.all(20),
          ),
        ),
        const Spacer(),
        _buildNextButton(),
      ],
    );
  }

  Widget _buildDailyTimeStep() {
    final times = [
      (30, '30 dakika', 'Yoğun günler için'),
      (60, '1 saat', 'Düzenli gelişim için'),
      (90, '1,5 saat', 'Daha hızlı ilerlemek için'),
      (120, '2 saat', 'Yoğun öğrenme için'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBackButton(),
        const SizedBox(height: 24),
        const Text(
          'Günde ne kadar zaman ayırabilirsin?',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Gerçekçi bir süre seç. Önemli olan sürdürülebilirlik.',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey.shade700,
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
              ? 'Kaydediliyor...'
              : 'MENZİLİM Yolculuğuna Başla',
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
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey.shade700,
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
    String text = 'Devam Et',
  }) {
    final canContinue = _canContinue();

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed:
            canContinue && !_isSaving ? _goNext : null,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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
      label: const Text('Geri'),
    );
  }

  Widget _buildErrorState({
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Bir hata oluştu.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final String title;
  final String? description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (description != null &&
                        description!.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        description!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                isSelected
                    ? Icons.check_circle
                    : Icons.arrow_forward_ios,
                size: isSelected ? 25 : 18,
                color: isSelected
                    ? colorScheme.primary
                    : Colors.grey.shade600,
              ),
            ],
          ),
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
      duration: const Duration(milliseconds: 200),
      height: 5,
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
