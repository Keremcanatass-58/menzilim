import 'package:flutter_test/flutter_test.dart';
import 'package:menzilim_app/features/skills/models/skill_progress_response.dart';

void main() {
  group('SkillProgressResponse.fromJson', () {
    test('API yanıtındaki tüm camelCase alanları okur', () {
      final skill = SkillProgressResponse.fromJson({
        'skillId': '3c40f7ce-479b-4726-8c0c-adc337823ff9',
        'skillName': 'ASP.NET Core',
        'category': 'Web',
        'progressPercent': 75,
        'totalContentCount': 2,
        'completedContentCount': 1,
        'inProgressContentCount': 1,
        'totalQuizCount': 1,
        'attemptedQuizCount': 1,
        'quizAttemptCount': 3,
        'bestQuizScore': 100,
        'latestQuizScore': 67,
      });

      expect(skill.skillId, '3c40f7ce-479b-4726-8c0c-adc337823ff9');
      expect(skill.skillName, 'ASP.NET Core');
      expect(skill.category, 'Web');
      expect(skill.progressPercent, 75);
      expect(skill.totalContentCount, 2);
      expect(skill.completedContentCount, 1);
      expect(skill.inProgressContentCount, 1);
      expect(skill.totalQuizCount, 1);
      expect(skill.attemptedQuizCount, 1);
      expect(skill.quizAttemptCount, 3);
      expect(skill.bestQuizScore, 100);
      expect(skill.latestQuizScore, 67);
      expect(skill.hasLearningMaterial, isTrue);
    });

    test('quiz skorları null ise null kalır', () {
      final skill = SkillProgressResponse.fromJson({
        'skillId': 'id',
        'skillName': 'İstatistik',
        'category': 'Veri',
        'progressPercent': 0,
        'totalContentCount': 0,
        'completedContentCount': 0,
        'inProgressContentCount': 0,
        'totalQuizCount': 0,
        'attemptedQuizCount': 0,
        'quizAttemptCount': 0,
        'bestQuizScore': null,
        'latestQuizScore': null,
      });

      expect(skill.skillName, 'İstatistik');
      expect(skill.bestQuizScore, isNull);
      expect(skill.latestQuizScore, isNull);
      expect(skill.hasLearningMaterial, isFalse);
    });

    test('eksik alanlarda güvenli varsayılanlar, yüzde 0-100 aralığında', () {
      final missing = SkillProgressResponse.fromJson({});
      final tooHigh = SkillProgressResponse.fromJson({'progressPercent': 150});

      expect(missing.skillId, '');
      expect(missing.skillName, '');
      expect(missing.progressPercent, 0);
      expect(missing.quizAttemptCount, 0);
      expect(missing.bestQuizScore, isNull);
      expect(tooHigh.progressPercent, 100);
    });
  });
}
