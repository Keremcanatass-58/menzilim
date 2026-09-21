import 'package:flutter/widgets.dart';

import 'l10n.dart';

/// Backend'in ham değerlerini (Beginner, Developing, Learn…) kullanıcının
/// diline çevirir. Ham değer hiçbir ekranda doğrudan gösterilmez.
extension DomainLabels on BuildContext {
  /// Beceri/deneyim seviyesi: Beginner → "Başlangıç". Mevcut deneyim
  /// seviyesi etiketleri yeniden kullanılır; "None" ayrıca karşılanır.
  String skillLevelLabel(String? level) {
    final value = level?.trim() ?? '';

    if (value.isEmpty || value.toLowerCase() == 'none') {
      return l10n.levelNone;
    }

    return l10n.experienceLevelLabel(value);
  }

  /// Beceri açığı durumu: Developing → "Gelişiyor".
  String gapStatusLabel(String? status) {
    final l10n = this.l10n;

    return switch (status?.trim().toLowerCase()) {
      'reached' => l10n.gapStatusReached,
      'developing' => l10n.gapStatusDeveloping,
      'needswork' => l10n.gapStatusNeedsWork,
      'notstarted' => l10n.gapStatusNotStarted,
      _ => l10n.gapStatusNotStarted,
    };
  }

  /// Günlük görev tipi: Project → "Proje".
  String taskTypeLabel(String taskType) {
    final l10n = this.l10n;

    return switch (taskType.trim().toLowerCase()) {
      'project' => l10n.taskTypeProject,
      'learn' => l10n.taskTypeLearn,
      'practice' => l10n.taskTypePractice,
      'quiz' => l10n.taskTypeQuiz,
      'review' => l10n.taskTypeReview,
      _ => taskType,
    };
  }
}
