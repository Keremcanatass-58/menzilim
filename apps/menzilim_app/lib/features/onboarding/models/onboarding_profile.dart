/// GET /api/onboarding/me yanıtı. Profil düzenleme için kimlikleri taşır
/// (dashboard yalnızca isimleri verir).
class OnboardingProfile {
  final String professionId;
  final String specializationId;
  final String experienceLevel;
  final String careerGoal;
  final int dailyLearningMinutes;

  const OnboardingProfile({
    required this.professionId,
    required this.specializationId,
    required this.experienceLevel,
    required this.careerGoal,
    required this.dailyLearningMinutes,
  });

  factory OnboardingProfile.fromJson(Map<String, dynamic> json) {
    final minutes = json['dailyLearningMinutes'];

    return OnboardingProfile(
      professionId: json['professionId']?.toString() ?? '',
      specializationId: json['specializationId']?.toString() ?? '',
      experienceLevel: json['experienceLevel']?.toString() ?? '',
      careerGoal: json['careerGoal']?.toString() ?? '',
      dailyLearningMinutes: minutes is int
          ? minutes
          : int.tryParse(minutes?.toString() ?? '') ?? 0,
    );
  }
}
