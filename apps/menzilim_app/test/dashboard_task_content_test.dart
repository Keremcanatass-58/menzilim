import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menzilim_app/core/network/api_client.dart';
import 'package:menzilim_app/features/content/models/content_recommendation_response.dart';
import 'package:menzilim_app/features/content/models/content_response.dart';
import 'package:menzilim_app/features/content/screens/discover_screen.dart';
import 'package:menzilim_app/features/content/services/content_service.dart';
import 'package:menzilim_app/features/daily_plan/models/daily_plan_response.dart';
import 'package:menzilim_app/features/daily_plan/services/daily_plan_service.dart';
import 'package:menzilim_app/features/dashboard/models/dashboard_response.dart';
import 'package:menzilim_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:menzilim_app/features/dashboard/services/dashboard_service.dart';
import 'package:menzilim_app/features/quiz/screens/quiz_screen.dart';
import 'package:menzilim_app/features/skills/models/skill_progress_response.dart';
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
      dailyLearningMinutes: 60,
      totalTasks: 3,
      completedTasks: 0,
      totalMinutes: 60,
      completedMinutes: 0,
      dailyProgressPercent: 0,
      completedContentCount: 0,
      inProgressContentCount: 0,
    );
  }
}

class _FakeDailyPlanService extends DailyPlanService {
  final List<DailyTaskResponse> tasks;
  final List<String> completedTaskIds = [];

  _FakeDailyPlanService(this.tasks) : super(ApiClient());

  DailyPlanResponse _plan() => DailyPlanResponse(
        id: 'plan',
        date: '2026-09-19',
        title: 'Backend · Günlük Plan',
        isCompleted: false,
        totalMinutes: tasks.fold(0, (sum, t) => sum + t.estimatedMinutes),
        completedMinutes: 0,
        tasks: tasks,
      );

  @override
  Future<DailyPlanResponse> getToday(String token) async => _plan();

  @override
  Future<DailyPlanResponse> completeTask(String token, String taskId) async {
    completedTaskIds.add(taskId);
    return _plan();
  }
}

class _FakeContentService extends ContentService {
  final Map<String, ContentResponse> contents;
  final List<String> openedIds = [];
  bool contentCompleted;

  _FakeContentService(this.contents, {this.contentCompleted = false})
      : super(ApiClient());

  @override
  Future<List<ContentRecommendationResponse>> getRecommendations(
    String token,
  ) async =>
      [];

  @override
  Future<ContentResponse> getById(String token, String contentId) async {
    openedIds.add(contentId);
    return contents[contentId]!;
  }

  @override
  Future<Map<String, dynamic>> getProgress(
    String token,
    String contentId,
  ) async =>
      {
        'contentId': contentId,
        'isStarted': true,
        'isCompleted': contentCompleted,
      };
}

class _FakeSkillService extends SkillService {
  _FakeSkillService() : super(ApiClient());

  @override
  Future<List<SkillProgressResponse>> getMySkills(String token) async => [];
}

ContentResponse _content(String id, String title) => ContentResponse(
      id: id,
      title: title,
      description: 'Açıklama',
      url: 'https://example.com/$id',
      source: 'Test',
      publishedAt: DateTime(2026, 9, 1),
      readingTimeMinutes: 10,
      level: 'Beginner',
    );

DailyTaskResponse _task(
  String id,
  String type,
  String title, {
  String? contentId,
  String? description,
}) =>
    DailyTaskResponse(
      id: id,
      title: title,
      description: description ?? '$title açıklaması',
      taskType: type,
      estimatedMinutes: 20,
      isCompleted: false,
      completedAt: null,
      contentId: contentId,
    );

class _Harness {
  final _FakeDailyPlanService plan;
  final _FakeContentService content;

  _Harness(this.plan, this.content);

  Widget build() => MaterialApp(
        home: DashboardScreen(
          dashboardService: _FakeDashboardService(),
          dailyPlanService: plan,
          contentService: content,
          skillService: _FakeSkillService(),
        ),
      );
}

_Harness _standardPlan({String? practiceContentId, bool contentCompleted = false}) {
  final contents = {
    'c-learn': _content('c-learn', 'ASP.NET Core Web API Development'),
    'c-practice': _content('c-practice', 'C# Temelleri'),
  };

  return _Harness(
    _FakeDailyPlanService([
      _task('t-learn', 'Learn', 'Bugünün Konusunu Öğren (Backend)', contentId: 'c-learn'),
      _task('t-practice', 'Practice', 'Uygulama Yap (Backend)', contentId: practiceContentId),
      _task('t-quiz', 'Quiz', 'Bilgini Test Et (Backend)'),
    ]),
    _FakeContentService(contents, contentCompleted: contentCompleted),
  );
}

Future<void> _tapTask(WidgetTester tester, String title) async {
  final finder = find.text(title);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _goBack(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': 'test-token'});
  });

  testWidgets('Learn görevi ContentId ile ContentDetailScreen açar', (tester) async {
    final h = _standardPlan(practiceContentId: 'c-practice');
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();

    await _tapTask(tester, 'Bugünün Konusunu Öğren (Backend)');

    expect(find.byType(ContentDetailScreen), findsOneWidget);
    expect(find.text('ASP.NET Core Web API Development'), findsOneWidget);
    expect(h.content.openedIds, ['c-learn']);
  });

  testWidgets('Practice görevi ContentId ile doğru ContentDetailScreen\'i açar', (tester) async {
    final h = _standardPlan(practiceContentId: 'c-practice');
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();

    // Practice kartı artık içeriğe gittiğini gösterir.
    expect(find.text('İçeriğe Git'), findsNWidgets(2));

    await _tapTask(tester, 'Uygulama Yap (Backend)');

    expect(find.byType(ContentDetailScreen), findsOneWidget);
    expect(find.text('C# Temelleri'), findsOneWidget);
    expect(h.content.openedIds, ['c-practice']);
    // Açmak görevi tamamlamaz.
    expect(h.plan.completedTaskIds, isEmpty);
  });

  testWidgets('Practice ContentId null ise içerik açılmaz, görev eskisi gibi tamamlanır', (tester) async {
    final h = _standardPlan(practiceContentId: null);
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();

    expect(find.text('İçeriğe Git'), findsOneWidget); // sadece Learn

    await _tapTask(tester, 'Uygulama Yap (Backend)');

    expect(tester.takeException(), isNull);
    expect(find.byType(ContentDetailScreen), findsNothing);
    expect(h.content.openedIds, isEmpty);
    expect(h.plan.completedTaskIds, ['t-practice']);
  });

  testWidgets('Quiz görevi ContentDetailScreen\'e yönlenmez', (tester) async {
    final h = _standardPlan(practiceContentId: 'c-practice');
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();

    await _tapTask(tester, 'Bilgini Test Et (Backend)');

    expect(find.byType(ContentDetailScreen), findsNothing);
    expect(find.byType(QuizScreen), findsOneWidget);
    expect(h.content.openedIds, isEmpty);
  });

  testWidgets('içerik tamamlandıysa dönüşte görev de tamamlanır', (tester) async {
    final h = _standardPlan(practiceContentId: 'c-practice', contentCompleted: true);
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();

    await _tapTask(tester, 'Uygulama Yap (Backend)');
    await _goBack(tester);

    expect(find.byType(ContentDetailScreen), findsNothing);
    expect(h.plan.completedTaskIds, ['t-practice']);
    expect(find.text('Uygulama Yap (Backend) tamamlandı! 🎉'), findsOneWidget);
  });

  testWidgets('içerik tamamlanmadıysa dönüşte görev tamamlanmaz (Learn)', (tester) async {
    final h = _standardPlan(practiceContentId: 'c-practice', contentCompleted: false);
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();

    await _tapTask(tester, 'Bugünün Konusunu Öğren (Backend)');
    await _goBack(tester);

    expect(find.byType(ContentDetailScreen), findsNothing);
    expect(h.plan.completedTaskIds, isEmpty);
  });

  testWidgets('uzun içerik başlıklı görev kartlarında taşma olmaz', (tester) async {
    const longTitle =
        'Çok Uzun Bir İçerik Başlığı: ASP.NET Core ile Katmanlı Mimari, Entity '
        'Framework Core, Kimlik Doğrulama ve Üretim Ortamına Dağıtım Rehberi';

    final h = _Harness(
      _FakeDailyPlanService([
        _task('t-learn', 'Learn', 'Bugünün Konusunu Öğren (Backend)',
            contentId: 'c-learn',
            description: 'Bugün için önerilen içerik: "$longTitle". Odak beceri: ASP.NET Core.'),
        _task('t-practice', 'Practice', 'Uygulama Yap (Backend)',
            contentId: 'c-practice',
            description: 'C# becerin için "$longTitle" içeriği üzerinden küçük bir uygulama gerçekleştir.'),
      ]),
      _FakeContentService({
        'c-learn': _content('c-learn', longTitle),
        'c-practice': _content('c-practice', longTitle),
      }),
    );

    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();

    final practice = find.text('Uygulama Yap (Backend)');
    await tester.ensureVisible(practice);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('İçeriğe Git'), findsNWidgets(2));
  });
}
