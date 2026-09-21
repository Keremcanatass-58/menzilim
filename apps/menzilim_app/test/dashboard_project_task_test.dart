import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menzilim_app/core/network/api_client.dart';
import 'package:menzilim_app/core/settings/app_settings_controller.dart';
import 'package:menzilim_app/features/content/models/content_recommendation_response.dart';
import 'package:menzilim_app/features/content/services/content_service.dart';
import 'package:menzilim_app/features/daily_plan/models/daily_plan_response.dart';
import 'package:menzilim_app/features/daily_plan/services/daily_plan_service.dart';
import 'package:menzilim_app/features/dashboard/models/dashboard_response.dart';
import 'package:menzilim_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:menzilim_app/features/dashboard/services/dashboard_service.dart';
import 'package:menzilim_app/features/news/models/news_item.dart';
import 'package:menzilim_app/features/news/services/news_service.dart';
import 'package:menzilim_app/features/projects/models/user_project.dart';
import 'package:menzilim_app/features/projects/screens/project_step_detail_screen.dart';
import 'package:menzilim_app/features/projects/services/project_service.dart';
import 'package:menzilim_app/features/skills/models/skill_progress_response.dart';
import 'package:menzilim_app/features/skills/services/skill_service.dart';
import 'package:menzilim_app/main.dart';
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
  _FakeDailyPlanService() : super(ApiClient());

  @override
  Future<DailyPlanResponse> getToday(String token) async => _plan();

  @override
  Future<DailyPlanResponse> completeTask(String token, String taskId) async =>
      _plan();

  DailyPlanResponse _plan() => DailyPlanResponse(
        id: 'plan',
        date: DateTime.now().toIso8601String(),
        title: 'Backend · Günlük Plan',
        isCompleted: false,
        totalMinutes: 60,
        completedMinutes: 0,
        tasks: [
          DailyTaskResponse(
            id: 't-project',
            title: 'İlk uç noktayı oluştur',
            description: 'Minimal API ile çalışan bir GET uç noktası yaz.',
            taskType: 'Project',
            estimatedMinutes: 35,
            isCompleted: false,
            completedAt: null,
            userProjectStepId: 'step-2',
            userProjectId: 'p-1',
            projectName: 'REST API + Veritabanı Uygulaması',
            projectStepOrder: 2,
            projectTotalSteps: 3,
            skillName: 'ASP.NET Core',
          ),
          DailyTaskResponse(
            id: 't-learn',
            title: 'Bugünün Konusunu Öğren (Backend)',
            description: 'Önerilen içerik.',
            taskType: 'Learn',
            estimatedMinutes: 15,
            isCompleted: false,
            completedAt: null,
            contentId: 'c-1',
          ),
          DailyTaskResponse(
            id: 't-quiz',
            title: 'Bilgini Test Et (Backend)',
            description: 'Kısa bir test.',
            taskType: 'Quiz',
            estimatedMinutes: 10,
            isCompleted: false,
            completedAt: null,
          ),
        ],
      );
}

class _FakeProjectService extends ProjectService {
  _FakeProjectService() : super(ApiClient());

  @override
  Future<List<UserProject>> getMyProjects(String token) async {
    final steps = [
      UserProjectStep(
        id: 'step-1',
        order: 1,
        title: 'Gereksinimleri belirle',
        description: null,
        status: 'Completed',
        estimatedMinutes: 20,
        contentId: null,
        contentTitle: null,
        skillName: null,
      ),
      UserProjectStep(
        id: 'step-2',
        order: 2,
        title: 'İlk uç noktayı oluştur',
        description: 'Minimal API ile çalışan bir GET uç noktası yaz.',
        status: 'Available',
        estimatedMinutes: 35,
        contentId: null,
        contentTitle: null,
        skillName: 'ASP.NET Core',
      ),
      UserProjectStep(
        id: 'step-3',
        order: 3,
        title: 'Veritabanını tasarla',
        description: null,
        status: 'Locked',
        estimatedMinutes: 60,
        contentId: null,
        contentTitle: null,
        skillName: 'SQL',
      ),
    ];

    return [
      UserProject(
        id: 'p-1',
        name: 'REST API + Veritabanı Uygulaması',
        description: 'Çalışan bir API geliştireceksin.',
        status: 'InProgress',
        totalSteps: steps.length,
        completedSteps: 1,
        progressPercent: 33,
        totalMinutes: 115,
        nextStep: steps[1],
        steps: steps,
      ),
    ];
  }
}

class _EmptySkillService extends SkillService {
  _EmptySkillService() : super(ApiClient());

  @override
  Future<List<SkillProgressResponse>> getMySkills(String token) async => [];
}

class _EmptyNewsService extends NewsService {
  _EmptyNewsService() : super(ApiClient());

  @override
  Future<List<NewsItem>> getMyNews(String token) async => [];
}

class _EmptyContentService extends ContentService {
  _EmptyContentService() : super(ApiClient());

  @override
  Future<List<ContentRecommendationResponse>> getRecommendations(
    String token,
  ) async =>
      [];
}

Widget _app() => MenzilimApp(
      settings: AppSettingsController(),
      home: DashboardScreen(
        dashboardService: _FakeDashboardService(),
        dailyPlanService: _FakeDailyPlanService(),
        contentService: _EmptyContentService(),
        skillService: _EmptySkillService(),
        newsService: _EmptyNewsService(),
        projectService: _FakeProjectService(),
      ),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': 'test-token'});
  });

  testWidgets('BUGÜN bloğu projenin sıradaki adımını gösterir',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Bugünün ana görevi'), findsOneWidget);
    expect(find.text('İlk uç noktayı oluştur'), findsWidgets);

    // Adım sırası, süre ve beceri.
    expect(find.text('Projenin 2. adımı'), findsOneWidget);
    expect(find.text('35 dk'), findsOneWidget);
    expect(find.text('ASP.NET Core'), findsWidgets);

    // Hedefe katkısı.
    expect(
      find.text('Bu adım seni şu hedefe götürüyor: Backend geliştirici olmak'),
      findsOneWidget,
    );

    // Tek güçlü aksiyon.
    expect(find.text('Başla'), findsOneWidget);
  });

  testWidgets('Başla proje adımı detayını açar', (tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Başla'));
    await tester.pumpAndSettle();

    expect(find.byType(ProjectStepDetailScreen), findsOneWidget);
    expect(find.text('Proje Adımı'), findsOneWidget);
    expect(find.text('2 / 3 adım'), findsOneWidget);
  });

  testWidgets('görev tipi etiketi yerelleştirilir', (tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Proje'), findsOneWidget);
    expect(find.text('Project'), findsNothing);
  });
}
