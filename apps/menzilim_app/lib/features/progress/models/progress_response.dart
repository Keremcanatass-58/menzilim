class ProgressResponse {
  final ProgressOverview overview;
  final ProgressToday today;
  final ProgressContent content;
  final ProgressQuiz quiz;
  final ProgressSkills skills;

  const ProgressResponse({
    required this.overview,
    required this.today,
    required this.content,
    required this.quiz,
    required this.skills,
  });

  factory ProgressResponse.fromJson(Map<String, dynamic> json) {
    return ProgressResponse(
      overview: ProgressOverview.fromJson(json['overview'] ?? {}),
      today: ProgressToday.fromJson(json['today'] ?? {}),
      content: ProgressContent.fromJson(json['content'] ?? {}),
      quiz: ProgressQuiz.fromJson(json['quiz'] ?? {}),
      skills: ProgressSkills.fromJson(json['skills'] ?? {}),
    );
  }
}

class ProgressOverview {
  final int completedTaskCount;
  final int estimatedLearningMinutes;
  final int completedPlanCount;
  final int activeDayCount;

  const ProgressOverview({
    required this.completedTaskCount,
    required this.estimatedLearningMinutes,
    required this.completedPlanCount,
    required this.activeDayCount,
  });

  factory ProgressOverview.fromJson(Map<String, dynamic> json) {
    return ProgressOverview(
      completedTaskCount: (json['completedTaskCount'] as num?)?.toInt() ?? 0,
      estimatedLearningMinutes: (json['estimatedLearningMinutes'] as num?)?.toInt() ?? 0,
      completedPlanCount: (json['completedPlanCount'] as num?)?.toInt() ?? 0,
      activeDayCount: (json['activeDayCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProgressToday {
  final bool hasPlan;
  final int totalTasks;
  final int completedTasks;
  final int totalMinutes;
  final int completedMinutes;
  final int progressPercent;

  const ProgressToday({
    required this.hasPlan,
    required this.totalTasks,
    required this.completedTasks,
    required this.totalMinutes,
    required this.completedMinutes,
    required this.progressPercent,
  });

  factory ProgressToday.fromJson(Map<String, dynamic> json) {
    return ProgressToday(
      hasPlan: json['hasPlan'] as bool? ?? false,
      totalTasks: (json['totalTasks'] as num?)?.toInt() ?? 0,
      completedTasks: (json['completedTasks'] as num?)?.toInt() ?? 0,
      totalMinutes: (json['totalMinutes'] as num?)?.toInt() ?? 0,
      completedMinutes: (json['completedMinutes'] as num?)?.toInt() ?? 0,
      progressPercent: (json['progressPercent'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProgressContent {
  final int completedCount;
  final int inProgressCount;

  const ProgressContent({
    required this.completedCount,
    required this.inProgressCount,
  });

  factory ProgressContent.fromJson(Map<String, dynamic> json) {
    return ProgressContent(
      completedCount: (json['completedCount'] as num?)?.toInt() ?? 0,
      inProgressCount: (json['inProgressCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProgressQuiz {
  final int attemptCount;
  final int distinctQuizCount;
  final int? bestScore;
  final int? averageScore;
  final int? latestScore;
  final DateTime? latestAttemptAt;

  const ProgressQuiz({
    required this.attemptCount,
    required this.distinctQuizCount,
    this.bestScore,
    this.averageScore,
    this.latestScore,
    this.latestAttemptAt,
  });

  factory ProgressQuiz.fromJson(Map<String, dynamic> json) {
    return ProgressQuiz(
      attemptCount: (json['attemptCount'] as num?)?.toInt() ?? 0,
      distinctQuizCount: (json['distinctQuizCount'] as num?)?.toInt() ?? 0,
      bestScore: (json['bestScore'] as num?)?.toInt(),
      averageScore: (json['averageScore'] as num?)?.toInt(),
      latestScore: (json['latestScore'] as num?)?.toInt(),
      latestAttemptAt: json['latestAttemptAt'] != null
          ? DateTime.tryParse(json['latestAttemptAt'] as String)
          : null,
    );
  }
}

class ProgressSkills {
  final int totalCount;
  final int startedCount;
  final List<SkillProgressSnapshot> strongest;
  final List<SkillProgressSnapshot> focus;

  const ProgressSkills({
    required this.totalCount,
    required this.startedCount,
    required this.strongest,
    required this.focus,
  });

  factory ProgressSkills.fromJson(Map<String, dynamic> json) {
    return ProgressSkills(
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      startedCount: (json['startedCount'] as num?)?.toInt() ?? 0,
      strongest: (json['strongest'] as List<dynamic>?)
              ?.map((e) => SkillProgressSnapshot.fromJson(e))
              .toList() ??
          [],
      focus: (json['focus'] as List<dynamic>?)
              ?.map((e) => SkillProgressSnapshot.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SkillProgressSnapshot {
  final String skillId;
  final String skillName;
  final String category;
  final int progressPercent;
  final int totalContentCount;
  final int completedContentCount;
  final int totalQuizCount;
  final int attemptedQuizCount;

  const SkillProgressSnapshot({
    required this.skillId,
    required this.skillName,
    required this.category,
    required this.progressPercent,
    required this.totalContentCount,
    required this.completedContentCount,
    required this.totalQuizCount,
    required this.attemptedQuizCount,
  });

  factory SkillProgressSnapshot.fromJson(Map<String, dynamic> json) {
    return SkillProgressSnapshot(
      skillId: json['skillId']?.toString() ?? '',
      skillName: json['skillName']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      progressPercent: (json['progressPercent'] as num?)?.toInt() ?? 0,
      totalContentCount: (json['totalContentCount'] as num?)?.toInt() ?? 0,
      completedContentCount:
          (json['completedContentCount'] as num?)?.toInt() ?? 0,
      totalQuizCount: (json['totalQuizCount'] as num?)?.toInt() ?? 0,
      attemptedQuizCount: (json['attemptedQuizCount'] as num?)?.toInt() ?? 0,
    );
  }
}