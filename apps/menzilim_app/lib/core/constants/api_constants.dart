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
}
