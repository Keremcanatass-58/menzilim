/// Living Project: kullanıcının gelişen projesi. Adım kilidi, ilerleme ve
/// sıradaki adım backend'de hesaplanır; model yalnızca veriyi taşır.
class UserProject {
  final String id;
  final String name;
  final String? description;
  final String status;
  final int totalSteps;
  final int completedSteps;
  final int progressPercent;
  final int totalMinutes;
  final UserProjectStep? nextStep;
  final List<UserProjectStep> steps;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const UserProject({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.totalSteps,
    required this.completedSteps,
    required this.progressPercent,
    required this.totalMinutes,
    required this.nextStep,
    required this.steps,
    this.startedAt,
    this.completedAt,
  });

  /// Özette gösterilecek beceriler (tekrarsız, sırayla).
  List<String> get usedSkills => {
        for (final step in steps)
          if (step.skillName != null) step.skillName!,
      }.toList();

  List<UserProjectStep> get completedStepList =>
      steps.where((step) => step.isCompleted).toList();

  List<UserProjectStep> get evidenceSteps =>
      steps.where((step) => step.hasEvidence).toList();

  bool get isCompleted => status == 'Completed';

  factory UserProject.fromJson(Map<String, dynamic> json) {
    final steps = (json['steps'] as List<dynamic>? ?? const [])
        .map((item) => UserProjectStep.fromJson(item as Map<String, dynamic>))
        .toList();

    final next = json['nextStep'];

    return UserProject(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'NotStarted',
      totalSteps: _asInt(json['totalSteps']) ?? steps.length,
      completedSteps: _asInt(json['completedSteps']) ?? 0,
      progressPercent: (_asInt(json['progressPercent']) ?? 0).clamp(0, 100),
      totalMinutes: _asInt(json['totalMinutes']) ?? 0,
      nextStep: next == null
          ? null
          : UserProjectStep.fromJson(next as Map<String, dynamic>),
      steps: steps,
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.tryParse(json['startedAt'].toString()),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.tryParse(json['completedAt'].toString()),
    );
  }
}

class UserProjectStep {
  final String id;
  final int order;
  final String title;
  final String? description;
  final String status;
  final int estimatedMinutes;
  final String? contentId;
  final String? contentTitle;
  final String? skillName;

  /// Adımın becerisine bağlı quiz (yoksa null).
  final String? quizId;
  final String? quizTitle;

  /// Kullanıcının eklediği çıktı.
  final String? evidenceUrl;
  final String? note;

  final DateTime? completedAt;

  const UserProjectStep({
    required this.id,
    required this.order,
    required this.title,
    required this.description,
    required this.status,
    required this.estimatedMinutes,
    required this.contentId,
    required this.contentTitle,
    required this.skillName,
    this.quizId,
    this.quizTitle,
    this.evidenceUrl,
    this.note,
    this.completedAt,
  });

  bool get hasEvidence => evidenceUrl != null && evidenceUrl!.isNotEmpty;

  bool get isCompleted => status == 'Completed';

  bool get isAvailable => status == 'Available';

  bool get isLocked => status == 'Locked';

  factory UserProjectStep.fromJson(Map<String, dynamic> json) {
    final contentId = json['contentId']?.toString();

    return UserProjectStep(
      id: json['id']?.toString() ?? '',
      order: _asInt(json['order']) ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'Locked',
      estimatedMinutes: _asInt(json['estimatedMinutes']) ?? 0,
      contentId: contentId == null || contentId.isEmpty ? null : contentId,
      contentTitle: json['contentTitle']?.toString(),
      skillName: json['skillName']?.toString(),
      quizId: _text(json['quizId']),
      quizTitle: _text(json['quizTitle']),
      evidenceUrl: _text(json['evidenceUrl']),
      note: _text(json['note']),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.tryParse(json['completedAt'].toString()),
    );
  }
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();

  return int.tryParse(value?.toString() ?? '');
}

String? _text(Object? value) {
  final text = value?.toString();

  return text == null || text.isEmpty ? null : text;
}
