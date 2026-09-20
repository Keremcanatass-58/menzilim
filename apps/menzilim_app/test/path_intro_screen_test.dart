import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menzilim_app/core/network/api_client.dart';
import 'package:menzilim_app/core/settings/app_settings_controller.dart';
import 'package:menzilim_app/features/dashboard/models/dashboard_response.dart';
import 'package:menzilim_app/features/dashboard/services/dashboard_service.dart';
import 'package:menzilim_app/features/onboarding/screens/path_intro_screen.dart';
import 'package:menzilim_app/features/projects/models/user_project.dart';
import 'package:menzilim_app/features/projects/services/project_service.dart';
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
      totalTasks: 0,
      completedTasks: 0,
      totalMinutes: 0,
      completedMinutes: 0,
      dailyProgressPercent: 0,
      completedContentCount: 0,
      inProgressContentCount: 0,
    );
  }
}

class _FakeProjectService extends ProjectService {
  final bool fails;

  _FakeProjectService({this.fails = false}) : super(ApiClient());

  @override
  Future<List<UserProject>> getMyProjects(String token) async {
    if (fails) {
      throw ApiException(statusCode: 500, message: 'Sunucu hatası');
    }

    return [
      UserProject(
        id: 'p-1',
        name: 'REST API + Veritabanı Uygulaması',
        description: 'Bu yolun sonunda çalışan bir API geliştirmiş olacaksın.',
        status: 'NotStarted',
        totalSteps: 2,
        completedSteps: 0,
        progressPercent: 0,
        totalMinutes: 60,
        nextStep: null,
        steps: [
          UserProjectStep(
            id: 's-1',
            order: 1,
            title: 'Gereksinimleri belirle',
            description: null,
            status: 'Available',
            estimatedMinutes: 20,
            contentId: null,
            contentTitle: null,
            skillName: null,
          ),
          UserProjectStep(
            id: 's-2',
            order: 2,
            title: 'Veritabanını tasarla',
            description: null,
            status: 'Locked',
            estimatedMinutes: 40,
            contentId: null,
            contentTitle: null,
            skillName: null,
          ),
        ],
      ),
    ];
  }
}

Widget _app({
  required VoidCallback onStart,
  bool projectFails = false,
}) =>
    MenzilimApp(
      settings: AppSettingsController(),
      home: PathIntroScreen(
        onStart: onStart,
        dashboardService: _FakeDashboardService(),
        projectService: _FakeProjectService(fails: projectFails),
      ),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': 'test-token'});
  });

  testWidgets('profil özeti, yol adımları ve proje çıktısı gösterilir',
      (tester) async {
    // Ekran kaydırılabilir; tüm bölümler tek karede kurulsun.
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(onStart: () {}));
    await tester.pumpAndSettle();

    expect(find.text('İşte senin yolun.'), findsOneWidget);

    // Profil özeti.
    expect(find.text('Yazılım Geliştirici'), findsOneWidget);
    expect(find.text('Backend'), findsOneWidget);
    expect(find.text('Günlük 60 dakika'), findsOneWidget);
    expect(find.text('Backend geliştirici olmak'), findsOneWidget);

    // Yol adımları ve çıktı.
    expect(find.text('Gereksinimleri belirle'), findsOneWidget);
    expect(find.text('Veritabanını tasarla'), findsOneWidget);
    expect(find.text('Bu yolun sonunda'), findsOneWidget);
    expect(find.text('REST API + Veritabanı Uygulaması'), findsOneWidget);
  });

  testWidgets('CTA uygulamaya geçirir', (tester) async {
    var started = 0;

    await tester.pumpWidget(_app(onStart: () => started++));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Yolculuğa Başla'));
    await tester.pumpAndSettle();

    expect(started, 1);
  });

  testWidgets('proje yüklenemezse akış tıkanmaz', (tester) async {
    await tester.pumpWidget(_app(onStart: () {}, projectFails: true));
    await tester.pumpAndSettle();

    expect(find.text('İşte senin yolun.'), findsOneWidget);
    expect(find.text('Yolculuğa Başla'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
