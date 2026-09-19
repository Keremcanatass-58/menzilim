import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menzilim_app/core/network/api_client.dart';
import 'package:menzilim_app/features/skills/models/skill_progress_response.dart';
import 'package:menzilim_app/features/skills/screens/skills_screen.dart';
import 'package:menzilim_app/features/skills/services/skill_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Her çağrıda sıradaki sonucu döndüren sahte servis.
class _FakeSkillService extends SkillService {
  final List<Future<List<SkillProgressResponse>> Function()> responses;
  int calls = 0;

  _FakeSkillService(this.responses) : super(ApiClient());

  @override
  Future<List<SkillProgressResponse>> getMySkills(String token) {
    final response = responses[calls.clamp(0, responses.length - 1)];
    calls++;
    return response();
  }
}

SkillProgressResponse _skill({
  required String name,
  String category = 'Web',
  int progress = 0,
  int totalContent = 0,
  int completedContent = 0,
  int totalQuiz = 0,
  int attemptedQuiz = 0,
  int? best,
  int? latest,
}) {
  return SkillProgressResponse(
    skillId: name,
    skillName: name,
    category: category,
    progressPercent: progress,
    totalContentCount: totalContent,
    completedContentCount: completedContent,
    inProgressContentCount: 0,
    totalQuizCount: totalQuiz,
    attemptedQuizCount: attemptedQuiz,
    quizAttemptCount: attemptedQuiz,
    bestQuizScore: best,
    latestQuizScore: latest,
  );
}

Widget _app(SkillService service) {
  return MaterialApp(
    home: SkillsScreen(skillService: service),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': 'test-token'});
  });

  testWidgets('yüklenirken progress indicator gösterir', (tester) async {
    final completer = Completer<List<SkillProgressResponse>>();
    final service = _FakeSkillService([() => completer.future]);

    await tester.pumpWidget(_app(service));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete([]);
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('başarılı yanıtta skill kartlarını ve bilgileri gösterir', (tester) async {
    final service = _FakeSkillService([
      () async => [
            _skill(
              name: 'ASP.NET Core',
              progress: 50,
              totalContent: 1,
              completedContent: 1,
              totalQuiz: 1,
            ),
            _skill(
              name: 'SQL',
              category: 'Veritabanı',
              progress: 90,
              totalContent: 1,
              completedContent: 1,
              totalQuiz: 1,
              attemptedQuiz: 1,
              best: 100,
              latest: 80,
            ),
            _skill(name: 'İstatistik', category: 'Veri'),
          ],
    ]);

    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    expect(find.text('ASP.NET Core'), findsOneWidget);
    expect(find.text('%50'), findsOneWidget);
    expect(find.text('İçerik: 1 / 1'), findsNWidgets(2));
    expect(find.text('Quiz: 0 / 1'), findsOneWidget);

    // Quiz çözülen skill'de skorlar görünür.
    expect(find.text('Quiz: 1 / 1'), findsOneWidget);
    expect(find.text('En iyi skor: %100'), findsOneWidget);
    expect(find.text('Son skor: %80'), findsOneWidget);

    // %0 skill de düzgün gösterilir.
    expect(find.text('İstatistik'), findsOneWidget);
    expect(find.text('%0'), findsOneWidget);
    expect(
      find.text('Bu yetenek için henüz içerik veya quiz eklenmedi.'),
      findsOneWidget,
    );

    expect(find.text('3 yetenekten 2 tanesinde ilerleme kaydettin.'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
  });

  testWidgets('skor yoksa skor satırları gösterilmez', (tester) async {
    final service = _FakeSkillService([
      () async => [_skill(name: 'SQL', totalQuiz: 1)],
    ]);

    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    expect(find.textContaining('En iyi skor'), findsNothing);
    expect(find.textContaining('Son skor'), findsNothing);
  });

  testWidgets('hata olursa mesaj ve Tekrar Dene gösterir, tekrar deneme çalışır',
      (tester) async {
    final service = _FakeSkillService([
      () async => throw ApiException(statusCode: 500, message: 'Sunucu hatası'),
      () async => [_skill(name: 'SQL', progress: 40, totalContent: 1)],
    ]);

    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    expect(find.text('Yetenekler yüklenemedi.'), findsOneWidget);
    expect(find.text('Tekrar Dene'), findsOneWidget);

    await tester.tap(find.text('Tekrar Dene'));
    await tester.pumpAndSettle();

    expect(service.calls, 2);
    expect(find.text('SQL'), findsOneWidget);
    expect(find.text('%40'), findsOneWidget);
    expect(find.text('Yetenekler yüklenemedi.'), findsNothing);
  });

  testWidgets('oturum yoksa API çağırmadan hata gösterir', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final service = _FakeSkillService([() async => []]);

    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    expect(service.calls, 0);
    expect(find.text('Yetenekler yüklenemedi.'), findsOneWidget);
  });

  testWidgets('boş listede empty state gösterir', (tester) async {
    final service = _FakeSkillService([() async => []]);

    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    expect(
      find.text('Uzmanlık alanın için henüz yetenek bulunmuyor.'),
      findsOneWidget,
    );
  });

  testWidgets('dar ekranda uzun isimlerle taşma olmaz', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final service = _FakeSkillService([
      () async => [
            _skill(
              name: 'Çok Uzun Bir Yetenek Adı ile Taşma Kontrolü ve '
                  'Veri Temizleme ve Hazırlama Süreçleri',
              category: 'Veri',
              progress: 100,
              totalContent: 12,
              completedContent: 12,
              totalQuiz: 10,
              attemptedQuiz: 10,
              best: 100,
              latest: 100,
            ),
          ],
    ]);

    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('%100'), findsOneWidget);
  });
}
