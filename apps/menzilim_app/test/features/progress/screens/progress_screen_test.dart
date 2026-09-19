import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menzilim_app/core/network/api_client.dart';
import 'package:menzilim_app/features/progress/models/progress_response.dart';
import 'package:menzilim_app/features/progress/screens/progress_screen.dart';
import 'package:menzilim_app/features/progress/services/progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Her çağrıda sıradaki sonucu döndüren sahte servis.
class _FakeProgressService extends ProgressService {
  final List<Future<ProgressResponse> Function()> responses;
  int calls = 0;

  _FakeProgressService(this.responses) : super(ApiClient());

  @override
  Future<ProgressResponse> getMyProgress(String token) {
    final response = responses[calls.clamp(0, responses.length - 1)];
    calls++;
    return response();
  }
}

ProgressResponse _progress({
  ProgressOverview? overview,
  ProgressToday? today,
  ProgressContent? content,
  ProgressQuiz? quiz,
  ProgressSkills? skills,
}) {
  return ProgressResponse(
    overview: overview ?? const ProgressOverview(
      completedTaskCount: 0,
      estimatedLearningMinutes: 0,
      completedPlanCount: 0,
      activeDayCount: 0,
    ),
    today: today ?? const ProgressToday(
      hasPlan: false,
      totalTasks: 0,
      completedTasks: 0,
      totalMinutes: 0,
      completedMinutes: 0,
      progressPercent: 0,
    ),
    content: content ?? const ProgressContent(
      completedCount: 0,
      inProgressCount: 0,
    ),
    quiz: quiz ?? const ProgressQuiz(
      attemptCount: 0,
      distinctQuizCount: 0,
    ),
    skills: skills ?? const ProgressSkills(
      totalCount: 0,
      startedCount: 0,
      strongest: [],
      focus: [],
    ),
  );
}

ProgressOverview _overview({
  int completedTaskCount = 0,
  int estimatedLearningMinutes = 0,
  int completedPlanCount = 0,
  int activeDayCount = 0,
}) {
  return ProgressOverview(
    completedTaskCount: completedTaskCount,
    estimatedLearningMinutes: estimatedLearningMinutes,
    completedPlanCount: completedPlanCount,
    activeDayCount: activeDayCount,
  );
}

ProgressToday _today({
  bool hasPlan = false,
  int totalTasks = 0,
  int completedTasks = 0,
  int totalMinutes = 0,
  int completedMinutes = 0,
  int progressPercent = 0,
}) {
  return ProgressToday(
    hasPlan: hasPlan,
    totalTasks: totalTasks,
    completedTasks: completedTasks,
    totalMinutes: totalMinutes,
    completedMinutes: completedMinutes,
    progressPercent: progressPercent,
  );
}

ProgressContent _content({
  int completedCount = 0,
  int inProgressCount = 0,
}) {
  return ProgressContent(
    completedCount: completedCount,
    inProgressCount: inProgressCount,
  );
}

ProgressQuiz _quiz({
  int attemptCount = 0,
  int distinctQuizCount = 0,
  int? bestScore,
  int? averageScore,
  int? latestScore,
  DateTime? latestAttemptAt,
}) {
  return ProgressQuiz(
    attemptCount: attemptCount,
    distinctQuizCount: distinctQuizCount,
    bestScore: bestScore,
    averageScore: averageScore,
    latestScore: latestScore,
    latestAttemptAt: latestAttemptAt,
  );
}

ProgressSkills _skills({
  int totalCount = 0,
  int startedCount = 0,
  List<SkillProgressSnapshot> strongest = const [],
  List<SkillProgressSnapshot> focus = const [],
}) {
  return ProgressSkills(
    totalCount: totalCount,
    startedCount: startedCount,
    strongest: strongest,
    focus: focus,
  );
}

SkillProgressSnapshot _skillSnapshot({
  required String skillId,
  required String skillName,
  String category = 'Web',
  int progressPercent = 0,
  int totalContentCount = 0,
  int completedContentCount = 0,
  int totalQuizCount = 0,
  int attemptedQuizCount = 0,
}) {
  return SkillProgressSnapshot(
    skillId: skillId,
    skillName: skillName,
    category: category,
    progressPercent: progressPercent,
    totalContentCount: totalContentCount,
    completedContentCount: completedContentCount,
    totalQuizCount: totalQuizCount,
    attemptedQuizCount: attemptedQuizCount,
  );
}

Widget _app(ProgressService service) {
  return MaterialApp(
    home: ProgressScreen(progressService: service),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': 'test-token'});
  });

  testWidgets('yüklenirken progress indicator gösterir', (tester) async {
    final completer = Completer<ProgressResponse>();
    final service = _FakeProgressService([() => completer.future]);

    await tester.pumpWidget(_app(service));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(_progress());
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('başarılı yanıtta tüm bölümleri gösterir', (tester) async {
    final service = _FakeProgressService([
      () async => _progress(
        overview: _overview(
          completedTaskCount: 15,
          estimatedLearningMinutes: 480,
          completedPlanCount: 8,
          activeDayCount: 12,
        ),
        today: _today(
          hasPlan: true,
          totalTasks: 4,
          completedTasks: 2,
          totalMinutes: 60,
          completedMinutes: 30,
          progressPercent: 50,
        ),
        content: _content(
          completedCount: 7,
          inProgressCount: 2,
        ),
        quiz: _quiz(
          attemptCount: 5,
          distinctQuizCount: 3,
          bestScore: 90,
          averageScore: 75,
          latestScore: 80,
          latestAttemptAt: DateTime(2026, 9, 18),
        ),
        skills: _skills(
          totalCount: 6,
          startedCount: 4,
          strongest: [
            _skillSnapshot(
              skillId: '1',
              skillName: 'ASP.NET Core',
              category: 'Web',
              progressPercent: 85,
              totalContentCount: 5,
              completedContentCount: 4,
              totalQuizCount: 2,
              attemptedQuizCount: 2,
            ),
            _skillSnapshot(
              skillId: '2',
              skillName: 'C#',
              category: 'Dil',
              progressPercent: 70,
              totalContentCount: 3,
              completedContentCount: 2,
              totalQuizCount: 1,
              attemptedQuizCount: 1,
            ),
            _skillSnapshot(
              skillId: '3',
              skillName: 'SQL',
              category: 'Veritabanı',
              progressPercent: 60,
              totalContentCount: 2,
              completedContentCount: 1,
              totalQuizCount: 0,
              attemptedQuizCount: 0,
            ),
          ],
          focus: [
            _skillSnapshot(
              skillId: '4',
              skillName: 'Docker',
              category: 'DevOps',
              progressPercent: 10,
              totalContentCount: 1,
              completedContentCount: 0,
              totalQuizCount: 0,
              attemptedQuizCount: 0,
            ),
            _skillSnapshot(
              skillId: '5',
              skillName: 'Git',
              category: 'Araç',
              progressPercent: 25,
              totalContentCount: 2,
              completedContentCount: 0,
              totalQuizCount: 1,
              attemptedQuizCount: 1,
            ),
            _skillSnapshot(
              skillId: '6',
              skillName: 'Linux',
              category: 'Sistem',
              progressPercent: 5,
              totalContentCount: 0,
              completedContentCount: 0,
              totalQuizCount: 1,
              attemptedQuizCount: 0,
            ),
          ],
        ),
      ),
    ]);

    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    // Genel Bakış bölümü
    expect(find.text('Genel Bakış'), findsOneWidget);
    expect(find.text('Tamamlanan Görev'), findsOneWidget);
    expect(find.text('480'), findsOneWidget); // estimatedLearningMinutes
    expect(find.text('Tamamlanan Plan'), findsOneWidget);
    expect(find.text('Aktif Gün'), findsOneWidget);

    // Bugün bölümü
    expect(find.text('Bugün'), findsOneWidget);
    expect(find.text('Bugünkü Plan'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Görevler'), findsOneWidget);
    expect(find.text('Süre'), findsOneWidget);

    // İçerik İlerlemesi bölümü
    expect(find.text('İçerik İlerlemesi'), findsOneWidget);
    expect(find.text('Tamamlanan'), findsOneWidget);
    expect(find.text('Devam Eden'), findsOneWidget);

    // Quiz İlerlemesi bölümü
    expect(find.text('Quiz İlerlemesi'), findsOneWidget);
    expect(find.text('5 deneme'), findsOneWidget);
    expect(find.text('En İyi Skor'), findsOneWidget);
    expect(find.text('Ortalama'), findsOneWidget);
    expect(find.text('Son Skor'), findsOneWidget);

    // Beceriler bölümü
    expect(find.text('Beceriler'), findsOneWidget);
    expect(find.text('En Güçlü Beceriler'), findsOneWidget);
    expect(find.text('ASP.NET Core'), findsOneWidget);
    expect(find.text('Odak Beceriler (İlerlemesi Düşük)'), findsOneWidget);
    expect(find.text('Docker'), findsOneWidget);
  });

  testWidgets('boş aktivite durumunda sıfır değerlerini gösterir', (tester) async {
    final service = _FakeProgressService([
      () async => _progress(),
    ]);

    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    expect(find.text('Genel Bakış'), findsOneWidget);
    expect(find.text('Bugün Plan Yok'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('İçerik İlerlemesi'), findsOneWidget);
    expect(find.text('Quiz İlerlemesi'), findsOneWidget);
    expect(find.text('Henüz quiz denemesi yapmadın.'), findsOneWidget);
    expect(find.text('Beceriler'), findsOneWidget);
    expect(find.text('En Güçlü Beceriler'), findsNothing);
    expect(find.text('Odak Beceriler (İlerlemesi Düşük)'), findsNothing);
  });

  testWidgets('bugün plan yoksa uygun mesajı gösterir', (tester) async {
    final service = _FakeProgressService([
      () async => _progress(
        today: _today(
          hasPlan: false,
          totalTasks: 0,
          completedTasks: 0,
          totalMinutes: 0,
          completedMinutes: 0,
          progressPercent: 0,
        ),
      ),
    ]);

    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    expect(find.text('Bugün Plan Yok'), findsOneWidget);
    expect(find.text('Bugünkü Plan'), findsNothing);
  });

  testWidgets('quiz yoksa quiz bölümünde uygun mesajı gösterir', (tester) async {
    final service = _FakeProgressService([
      () async => _progress(
        quiz: _quiz(attemptCount: 0),
      ),
    ]);

    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    expect(find.text('Henüz quiz denemesi yapmadın.'), findsOneWidget);
    expect(find.text('En İyi Skor'), findsNothing);
  });

  testWidgets('quiz skorları null ise dash gösterilir', (tester) async {
    final service = _FakeProgressService([
      () async => _progress(
        quiz: _quiz(
          attemptCount: 1,
          distinctQuizCount: 1,
          bestScore: null,
          averageScore: null,
          latestScore: null,
        ),
      ),
    ]);

    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    // Skorlar null olduğu için dash (-) gösterilir
    expect(find.text('En İyi Skor'), findsOneWidget);
    expect(find.text('Ortalama'), findsOneWidget);
    expect(find.text('Son Skor'), findsOneWidget);
    // 3 adet dash widget'i olmalı (en iyi, ortalama, son)
    expect(find.text('-'), findsNWidgets(3));
  });

  testWidgets('strongest beceriler yoksa bölüm gösterilmez', (tester) async {
    final service = _FakeProgressService([
      () async => _progress(
        skills: _skills(
          totalCount: 3,
          startedCount: 0,
          strongest: [],
          focus: [
            _skillSnapshot(
              skillId: '1',
              skillName: 'Docker',
              progressPercent: 10,
            ),
          ],
        ),
      ),
    ]);

    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    expect(find.text('En Güçlü Beceriler'), findsNothing);
    expect(find.text('Odak Beceriler (İlerlemesi Düşük)'), findsOneWidget);
    expect(find.text('Docker'), findsOneWidget);
  });

  testWidgets('focus beceriler yoksa bölüm gösterilmez', (tester) async {
    final service = _FakeProgressService([
      () async => _progress(
        skills: _skills(
          totalCount: 3,
          startedCount: 3,
          strongest: [
            _skillSnapshot(
              skillId: '1',
              skillName: 'ASP.NET Core',
              progressPercent: 80,
            ),
          ],
          focus: [],
        ),
      ),
    ]);

    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    expect(find.text('En Güçlü Beceriler'), findsOneWidget);
    expect(find.text('ASP.NET Core'), findsOneWidget);
    expect(find.text('Odak Beceriler (İlerlemesi Düşük)'), findsNothing);
  });

  testWidgets('hata olursa mesaj ve Tekrar Dene gösterir, tekrar deneme çalışır',
      (tester) async {
    final service = _FakeProgressService([
      () async => throw ApiException(statusCode: 500, message: 'Sunucu hatası'),
      () async => _progress(
        overview: _overview(completedTaskCount: 5),
      ),
    ]);

    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    expect(find.text('İlerleme yüklenemedi.'), findsOneWidget);
    expect(find.text('Tekrar Dene'), findsOneWidget);

    await tester.tap(find.text('Tekrar Dene'));
    await tester.pumpAndSettle();

    expect(service.calls, 2);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('İlerleme yüklenemedi.'), findsNothing);
  });

  testWidgets('oturum yoksa API çağırmadan hata gösterir', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final service = _FakeProgressService([() async => _progress()]);

    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    expect(service.calls, 0);
    expect(find.text('İlerleme yüklenemedi.'), findsOneWidget);
  });

  testWidgets('dar ekranda uzun isimlerle taşma olmaz', (tester) async {
    // 420px genişliğinde bir telefon ekranı simüle et
    tester.view.physicalSize = const Size(420, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final service = _FakeProgressService([
      () async => _progress(
        skills: _skills(
          totalCount: 1,
          startedCount: 1,
          strongest: [
            _skillSnapshot(
              skillId: '1',
              skillName:
                  'Çok Uzun Bir Beceri Adı ile Taşma Kontrolü ve Veri Temizleme Süreçleri',
              category: 'Web',
              progressPercent: 100,
              totalContentCount: 12,
              completedContentCount: 12,
              totalQuizCount: 10,
              attemptedQuizCount: 10,
            ),
          ],
          focus: [],
        ),
      ),
    ]);

    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    // Overflow olmamalı - isim kısaltılmalı
    expect(tester.takeException(), isNull);
    // Beceri adı görünür olmalı (kısaltılmış olabilir)
    expect(find.byType(Text), findsWidgets);
  });
}