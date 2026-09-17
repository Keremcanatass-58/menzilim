class DashboardResponse {
  final String userId;
  final String profession;
  final String specialization;
  final String experienceLevel;
  final String careerGoal;
  final int dailyLearningMinutes;

  // Günlük Plan İlerlemesi
  final int totalTasks;
  final int completedTasks;
  final int totalMinutes;
  final int completedMinutes;
  final double dailyProgressPercent;

  // İçerik İlerlemesi
  final int completedContentCount;
  final int inProgressContentCount;

  DashboardResponse({
    required this.userId,
    required this.profession,
    required this.specialization,
    required this.experienceLevel,
    required this.careerGoal,
    required this.dailyLearningMinutes,
    required this.totalTasks,
    required this.completedTasks,
    required this.totalMinutes,
    required this.completedMinutes,
    required this.dailyProgressPercent,
    required this.completedContentCount,
    required this.inProgressContentCount,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    return DashboardResponse(
      userId: json['userId'].toString(),
      profession: json['profession'].toString(),
      specialization: json['specialization'].toString(),
      experienceLevel: json['experienceLevel'].toString(),
      careerGoal: json['careerGoal'].toString(),
      dailyLearningMinutes:
          (json['dailyLearningMinutes'] as num?)?.toInt() ?? 0,
      totalTasks: (json['totalTasks'] as num?)?.toInt() ?? 0,
      completedTasks: (json['completedTasks'] as num?)?.toInt() ?? 0,
      totalMinutes: (json['totalMinutes'] as num?)?.toInt() ?? 0,
      completedMinutes: (json['completedMinutes'] as num?)?.toInt() ?? 0,
      dailyProgressPercent:
          (json['dailyProgressPercent'] as num?)?.toDouble() ?? 0,
      completedContentCount:
          (json['completedContentCount'] as num?)?.toInt() ?? 0,
      inProgressContentCount:
          (json['inProgressContentCount'] as num?)?.toInt() ?? 0,
    );
  }
}
