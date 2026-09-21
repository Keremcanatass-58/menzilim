/// GET /api/skills/gap/me yanıtı. Seviye ve durum değerleri backend'in ham
/// değerleridir; kullanıcıya her zaman yerelleştirilmiş karşılıkları gösterilir.
class SkillGapResponse {
  final String specializationName;
  final int totalCount;
  final int reachedCount;
  final int developingCount;
  final int notStartedCount;
  final int remainingCount;
  final List<SkillGapItem> items;

  const SkillGapResponse({
    required this.specializationName,
    required this.totalCount,
    required this.reachedCount,
    required this.developingCount,
    required this.notStartedCount,
    required this.remainingCount,
    required this.items,
  });

  /// Hedefe ulaşmamış, öncelikli beceriler (hedefe en yakından başlayarak).
  List<SkillGapItem> priority(int count) => items
      .where((item) => !item.isReached)
      .take(count)
      .toList();

  factory SkillGapResponse.fromJson(Map<String, dynamic> json) {
    return SkillGapResponse(
      specializationName: json['specializationName']?.toString() ?? '',
      totalCount: _asInt(json['totalCount']),
      reachedCount: _asInt(json['reachedCount']),
      developingCount: _asInt(json['developingCount']),
      notStartedCount: _asInt(json['notStartedCount']),
      remainingCount: _asInt(json['remainingCount']),
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((item) => SkillGapItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SkillGapItem {
  final String skillId;
  final String skillName;
  final String category;

  /// None | Beginner | Intermediate | Advanced
  final String currentLevel;

  /// Beginner | Intermediate | Advanced
  final String targetLevel;

  final int progressPercent;
  final int targetProgressPercent;

  /// Reached | Developing | NeedsWork | NotStarted
  final String status;

  const SkillGapItem({
    required this.skillId,
    required this.skillName,
    required this.category,
    required this.currentLevel,
    required this.targetLevel,
    required this.progressPercent,
    required this.targetProgressPercent,
    required this.status,
  });

  bool get isReached => status == 'Reached';

  bool get isNotStarted => status == 'NotStarted';

  /// Hedefe ne kadar yaklaşıldığı (0-1). Hedef eşiği 0 ise tamamlanmış sayılır.
  double get targetProgress {
    if (targetProgressPercent <= 0) return 1;

    return (progressPercent / targetProgressPercent).clamp(0.0, 1.0);
  }

  factory SkillGapItem.fromJson(Map<String, dynamic> json) {
    return SkillGapItem(
      skillId: json['skillId']?.toString() ?? '',
      skillName: json['skillName']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      currentLevel: json['currentLevel']?.toString() ?? 'None',
      targetLevel: json['targetLevel']?.toString() ?? 'Intermediate',
      progressPercent: _asInt(json['progressPercent']).clamp(0, 100),
      targetProgressPercent: _asInt(json['targetProgressPercent']),
      status: json['status']?.toString() ?? 'NotStarted',
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();

  return int.tryParse(value?.toString() ?? '') ?? 0;
}
