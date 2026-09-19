class DailyPlanResponse {
  final String id;
  final String date;
  final String title;
  final bool isCompleted;
  final int totalMinutes;
  final int completedMinutes;
  final List<DailyTaskResponse> tasks;

  DailyPlanResponse({
    required this.id,
    required this.date,
    required this.title,
    required this.isCompleted,
    required this.totalMinutes,
    required this.completedMinutes,
    required this.tasks,
  });

  factory DailyPlanResponse.fromJson(Map<String, dynamic> json) {
    return DailyPlanResponse(
      id: json['id'].toString(),
      date: json['date'].toString(),
      title: json['title']?.toString() ?? '',
      isCompleted: json['isCompleted'] == true,
      totalMinutes: (json['totalMinutes'] as num?)?.toInt() ?? 0,
      completedMinutes: (json['completedMinutes'] as num?)?.toInt() ?? 0,
      tasks: (json['tasks'] as List<dynamic>? ?? [])
          .map(
            (task) => DailyTaskResponse.fromJson(
              task as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  double get progress {
    if (totalMinutes <= 0) {
      return 0;
    }

    return completedMinutes / totalMinutes;
  }
}

class DailyTaskResponse {
  final String id;
  final String title;
  final String? description;
  final String taskType;
  final int estimatedMinutes;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? contentId;

  // Yalnızca Quiz görevlerinde: backend'in kullanıcının uzmanlığına göre
  // seçtiği quiz. Yoksa QuizScreen varsayılan aktif quiz'i açar.
  final String? quizId;

  DailyTaskResponse({
    required this.id,
    required this.title,
    required this.description,
    required this.taskType,
    required this.estimatedMinutes,
    required this.isCompleted,
    required this.completedAt,
    this.contentId,
    this.quizId,
  });

  factory DailyTaskResponse.fromJson(Map<String, dynamic> json) {
    return DailyTaskResponse(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      taskType: json['taskType']?.toString() ?? '',
      estimatedMinutes:
          (json['estimatedMinutes'] as num?)?.toInt() ?? 0,
      isCompleted: json['isCompleted'] == true,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.tryParse(json['completedAt'].toString()),
      contentId: json['contentId']?.toString(),
      quizId: json['quizId']?.toString(),
    );
  }
}
