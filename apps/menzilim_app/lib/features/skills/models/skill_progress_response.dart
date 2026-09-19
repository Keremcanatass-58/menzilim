class SkillProgressResponse {
  final String skillId;
  final String skillName;
  final String category;
  final int progressPercent;
  final int totalContentCount;
  final int completedContentCount;
  final int inProgressContentCount;
  final int totalQuizCount;
  final int attemptedQuizCount;
  final int quizAttemptCount;
  final int? bestQuizScore;
  final int? latestQuizScore;

  const SkillProgressResponse({
    required this.skillId,
    required this.skillName,
    required this.category,
    required this.progressPercent,
    required this.totalContentCount,
    required this.completedContentCount,
    required this.inProgressContentCount,
    required this.totalQuizCount,
    required this.attemptedQuizCount,
    required this.quizAttemptCount,
    this.bestQuizScore,
    this.latestQuizScore,
  });

  bool get hasLearningMaterial =>
      totalContentCount > 0 || totalQuizCount > 0;

  factory SkillProgressResponse.fromJson(Map<String, dynamic> json) {
    return SkillProgressResponse(
      skillId: json['skillId']?.toString() ?? '',
      skillName: json['skillName']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      progressPercent:
          ((json['progressPercent'] as num?)?.toInt() ?? 0).clamp(0, 100),
      totalContentCount: (json['totalContentCount'] as num?)?.toInt() ?? 0,
      completedContentCount:
          (json['completedContentCount'] as num?)?.toInt() ?? 0,
      inProgressContentCount:
          (json['inProgressContentCount'] as num?)?.toInt() ?? 0,
      totalQuizCount: (json['totalQuizCount'] as num?)?.toInt() ?? 0,
      attemptedQuizCount: (json['attemptedQuizCount'] as num?)?.toInt() ?? 0,
      quizAttemptCount: (json['quizAttemptCount'] as num?)?.toInt() ?? 0,
      bestQuizScore: (json['bestQuizScore'] as num?)?.toInt(),
      latestQuizScore: (json['latestQuizScore'] as num?)?.toInt(),
    );
  }
}
