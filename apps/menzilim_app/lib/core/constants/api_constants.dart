class ApiConstants {
  static String get baseUrl {
    return Uri(
      scheme: 'http',
      host: '127.0.0.1',
      port: 5205,
    ).toString();
  }

  static String get login => '$baseUrl/api/auth/login';

  static String get register => '$baseUrl/api/auth/register';

  static String get professions => '$baseUrl/api/professions';

  static String specializations(String professionId) =>
      '$baseUrl/api/professions/$professionId/specializations';

  static String get onboarding => '$baseUrl/api/onboarding';

  static String get myOnboarding => '$baseUrl/api/onboarding/me';

  static String get dashboard => '$baseUrl/api/dashboard/me';

  static String get dailyPlan => '$baseUrl/api/daily-plan/me';

  static String get quizzes => '$baseUrl/api/quizzes';

  static String get activeQuiz => '$baseUrl/api/quizzes/active';

  static String quizDetail(String quizId) => '$baseUrl/api/quizzes/$quizId';

  static String submitQuiz(String quizId) =>
      '$baseUrl/api/quizzes/$quizId/submit';

  static String get aiCoachAsk => '$baseUrl/api/ai-coach/ask';

  static String get progress => '$baseUrl/api/progress/me';

  static String get myNews => '$baseUrl/api/news/me';

  static String get mySkillGap => '$baseUrl/api/skills/gap/me';

  static String get myProjects => '$baseUrl/api/projects/me';

  static String projectDetail(String projectId) =>
      '$baseUrl/api/projects/me/$projectId';

  static String completeProjectStep(String stepId) =>
      '$baseUrl/api/projects/me/steps/$stepId/complete';

  static String projectStepEvidence(String stepId) =>
      '$baseUrl/api/projects/me/steps/$stepId/evidence';

  static String get myStreak => '$baseUrl/api/progress/streak/me';

  static String get profileTimeZone => '$baseUrl/api/profile/timezone';
}