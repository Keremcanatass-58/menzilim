import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menzilim_app/core/network/api_client.dart';
import 'package:menzilim_app/features/content/models/content_recommendation_response.dart';
import 'package:menzilim_app/features/content/services/content_service.dart';
import 'package:menzilim_app/features/daily_plan/models/daily_plan_response.dart';
import 'package:menzilim_app/features/daily_plan/services/daily_plan_service.dart';
import 'package:menzilim_app/features/dashboard/models/dashboard_response.dart';
import 'package:menzilim_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:menzilim_app/features/dashboard/services/dashboard_service.dart';
import 'package:menzilim_app/features/dashboard/widgets/dashboard_skills_summary.dart';
import 'package:menzilim_app/features/skills/models/skill_progress_response.dart';
import 'package:menzilim_app/features/skills/screens/skills_screen.dart';
import 'package:menzilim_app/features/skills/services/skill_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeDashboardService extends DashboardService {
  _FakeDashboardService() : super(ApiClient());

  @override
  Future<DashboardResponse> getDashboard(String token) async {
    return DashboardResponse(
      userId: 'user',
      profession: 'Yazılım Geliştirici',
      specialization: 'Backend',
      experienceLevel: 'Beginner',
      careerGoal: 'Backend geliştirici olmak',
      dailyLearningMinutes: 30,
      totalTasks: 0,
      completedTasks: 0,
      totalMinutes: 0,
      completedMinutes: 0,
      dailyProgressPercent: 0,
      completedContentCount: 1,
      inProgressContentCount: 0,
    );
  }
}

class _FakeDailyPlanService extends DailyPlanService {
  _FakeDailyPlanService() : super(ApiClient());

  @override
  Future<DailyPlanResponse> getToday(String token) async {
    return DailyPlanResponse(
      id: 'plan',
      date: '2026-09-19',
      title: 'Plan',
      isCompleted: false,
      totalMinutes: 30,
      completedMinutes: 0,
      tasks: [],
    );
  }
}

class _FakeContentService extends ContentService {
  _FakeContentService() : super(ApiClient());

  @override
  Future<List<ContentRecommendationResponse>> getRecommendations(
    String token,
  ) async {
    return [];
  }
}

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

SkillProgressResponse _skill(String name, int progress) {
  return SkillProgressResponse(
    skillId: name,
    skillName: name,
    category: 'Web',
    progressPercent: progress,
    totalContentCount: 1,
    completedContentCount: progress > 0 ? 1 : 0,
    inProgressContentCount: 0,
    totalQuizCount: 1,
    attemptedQuizCount: 0,
    quizAttemptCount: 0,
  );
}

Widget _app(SkillService skillService) {
  return MaterialApp(
    home: DashboardScreen(
      dashboardService: _FakeDashboardService(),
      dailyPlanService: _FakeDailyPlanService(),
      contentService: _FakeContentService(),
      skillService: skillService,
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': 'test-token'});
  });

  testWidgets('beceri verisi gelince özet bölümü görünür', (tester) async {
    final skills = _FakeSkillService([
      () async => [
            _skill('ASP.NET Core', 50),
            _skill('C#', 0),
            _skill('SQL', 0),
          ],
    ]);

    await tester.pumpWidget(_app(skills));
    await tester.pumpAndSettle();

    expect(find.text('Becerilerim'), findsOneWidget);
    expect(find.text('3 yetenek · 1 tanesinde ilerleme'), findsOneWidget);
    expect(find.text('Tüm Yetenekleri Gör'), findsOneWidget);
  });

  testWidgets('yalnızca ilerleme olan beceriler, en fazla 3 tane, ilerlemeye göre sıralı',
      (tester) async {
    final skills = _FakeSkillService([
      () async => [
            _skill('ASP.NET Core', 50),
            _skill('C#', 0),
            _skill('Entity Framework Core', 20),
            _skill('REST API', 90),
            _skill('SQL', 20),
            _skill('Web Uygulama Güvenliği', 10),
          ],
    ]);

    await tester.pumpWidget(_app(skills));
    await tester.pumpAndSettle();

    expect(find.text('6 yetenek · 5 tanesinde ilerleme'), findsOneWidget);

    // İlk 3: REST API 90, ASP.NET Core 50, eşitlikte ada göre EF Core 20.
    expect(find.text('REST API'), findsOneWidget);
    expect(find.text('%90'), findsOneWidget);
    expect(find.text('ASP.NET Core'), findsOneWidget);
    expect(find.text('%50'), findsOneWidget);
    expect(find.text('Entity Framework Core'), findsOneWidget);

    // 4. ve sonrası ile %0 olanlar gösterilmez.
    expect(find.text('SQL'), findsNothing);
    expect(find.text('Web Uygulama Güvenliği'), findsNothing);
    expect(find.text('C#'), findsNothing);

    // Özet kartındaki progress bar sayısı = gösterilen beceri sayısı.
    final summaryBars = find.descendant(
      of: find.ancestor(
        of: find.text('Becerilerim'),
        matching: find.byType(Container),
      ).first,
      matching: find.byType(LinearProgressIndicator),
    );
    expect(summaryBars, findsNWidgets(3));
  });

  testWidgets('ilerleme yoksa boş mesajı gösterir', (tester) async {
    final skills = _FakeSkillService([
      () async => [_skill('ASP.NET Core', 0), _skill('SQL', 0)],
    ]);

    await tester.pumpWidget(_app(skills));
    await tester.pumpAndSettle();

    expect(find.text('2 yetenek · 0 tanesinde ilerleme'), findsOneWidget);
    expect(find.text('Henüz bir yetenekte ilerleme kaydetmedin.'), findsOneWidget);
    expect(find.text('Tüm Yetenekleri Gör'), findsOneWidget);
  });

  testWidgets('beceri API hatası dashboard\'un geri kalanını bozmaz, tekrar dene çalışır',
      (tester) async {
    final skills = _FakeSkillService([
      () async => throw ApiException(statusCode: 500, message: 'Sunucu hatası'),
      () async => [_skill('ASP.NET Core', 50)],
    ]);

    await tester.pumpWidget(_app(skills));
    await tester.pumpAndSettle();

    // Dashboard'un diğer bölümleri çalışıyor.
    expect(find.text('Dashboard bilgileri yüklenemedi.'), findsNothing);
    expect(find.text('Gelişim yolculuğuna devam et.'), findsOneWidget);
    expect(find.text('Bugünün Yol Haritası'), findsOneWidget);
    expect(find.text('Sana Özel İçerikler'), findsOneWidget);

    // Hata yalnızca beceri kartında.
    expect(find.text('Becerilerim'), findsOneWidget);
    expect(find.text('Beceriler yüklenemedi.'), findsOneWidget);

    final retry = find.descendant(
      of: find.ancestor(
        of: find.text('Beceriler yüklenemedi.'),
        matching: find.byType(Wrap),
      ),
      matching: find.text('Tekrar Dene'),
    );
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(skills.calls, 2);
    expect(find.text('Beceriler yüklenemedi.'), findsNothing);
    expect(find.text('ASP.NET Core'), findsOneWidget);
  });

  testWidgets('Tüm Yetenekleri Gör SkillsScreen\'e götürür', (tester) async {
    final skills = _FakeSkillService([
      () async => [_skill('ASP.NET Core', 50)],
    ]);

    await tester.pumpWidget(_app(skills));
    await tester.pumpAndSettle();

    final action = find.text('Tüm Yetenekleri Gör');
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(find.byType(SkillsScreen), findsOneWidget);
    expect(find.text('Yeteneklerim'), findsOneWidget);
  });

  // Dashboard'un tamamı test fontuyla 400px'te zaten (mevcut, bu adımla
  // ilgisiz satırlarda) taşıyor; bu yüzden özet kartı Dashboard ile aynı
  // koşullarda (400px, 32px kenar boşluğu) tek başına test edilir.
  testWidgets('400px genişlikte uzun isimlerle özet kartı taşmaz', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: DashboardSkillsSummary(
              skills: [
                _skill(
                  'Çok Uzun Bir Yetenek Adı: Veri Temizleme ve Hazırlama Süreçleri',
                  100,
                ),
                _skill('MLOps ve Model Dağıtımı', 75),
                _skill('Güvenlik Duvarı ve IDS/IPS', 5),
                _skill('İstatistik', 0),
              ],
              isLoading: false,
              errorMessage: null,
              onRetry: () {},
              onViewAll: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('4 yetenek · 3 tanesinde ilerleme'), findsOneWidget);
    expect(find.text('%100'), findsOneWidget);
  });

  testWidgets('400px genişlikte hata durumu da taşmaz', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: DashboardSkillsSummary(
              skills: const [],
              isLoading: false,
              errorMessage: 'Beceriler yüklenemedi.',
              onRetry: () {},
              onViewAll: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Tekrar Dene'), findsOneWidget);
  });
}
