class OnboardingRequest {
  final String professionId;
  final String specializationId;
  final String experienceLevel;
  final String careerGoal;
  final int dailyLearningMinutes;

  OnboardingRequest({
    required this.professionId,
    required this.specializationId,
    required this.experienceLevel,
    required this.careerGoal,
    required this.dailyLearningMinutes,
  });

  Map<String, dynamic> toJson() {
    return {
      'professionId': professionId,
      'specializationId': specializationId,
      'experienceLevel': experienceLevel,
      'careerGoal': careerGoal,
      'dailyLearningMinutes': dailyLearningMinutes,
    };
  }
}
