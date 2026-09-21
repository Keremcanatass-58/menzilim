import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menzilim_app/core/network/api_client.dart';
import 'package:menzilim_app/core/settings/app_settings_controller.dart';
import 'package:menzilim_app/features/projects/models/user_project.dart';
import 'package:menzilim_app/features/projects/screens/project_step_detail_screen.dart';
import 'package:menzilim_app/features/projects/services/project_service.dart';
import 'package:menzilim_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeProjectService extends ProjectService {
  final UserProject afterComplete;
  final List<String> completedStepIds = [];

  _FakeProjectService(this.afterComplete) : super(ApiClient());

  @override
  Future<UserProject> completeStep(String token, String stepId) async {
    completedStepIds.add(stepId);
    return afterComplete;
  }
}

UserProjectStep _step(
  int order,
  String title,
  String status, {
  String? contentId,
  String? skillName,
}) =>
    UserProjectStep(
      id: 'step-$order',
      order: order,
      title: title,
      description: '$title için kısa açıklama.',
      status: status,
      estimatedMinutes: 30,
      contentId: contentId,
      contentTitle: contentId == null ? null : 'Destekleyici içerik $order',
      skillName: skillName,
    );

UserProject _project(List<UserProjectStep> steps) {
  final completed = steps.where((s) => s.isCompleted).length;

  return UserProject(
    id: 'p-1',
    name: 'REST API + Veritabanı Uygulaması',
    description: 'Çalışan bir API geliştireceksin.',
    status: completed == 0 ? 'NotStarted' : 'InProgress',
    totalSteps: steps.length,
    completedSteps: completed,
    progressPercent: ((completed / steps.length) * 100).round(),
    totalMinutes: steps.length * 30,
    nextStep: steps.where((s) => s.isAvailable).firstOrNull,
    steps: steps,
  );
}

Widget _app({
  required UserProject project,
  required UserProjectStep step,
  ProjectService? service,
  String? quizId,
}) =>
    MenzilimApp(
      settings: AppSettingsController(),
      home: ProjectStepDetailScreen(
        project: project,
        step: step,
        quizId: quizId,
        projectService: service,
      ),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': 'test-token'});
  });

  Future<void> pumpTall(WidgetTester tester, Widget app) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
  }

  testWidgets('adım detayı proje, sıra, süre, beceri ve içeriği gösterir',
      (tester) async {
    final steps = [
      _step(1, 'Gereksinimleri belirle', 'Completed'),
      _step(2, 'İlk uç noktayı oluştur', 'Available',
          contentId: 'c-1', skillName: 'ASP.NET Core'),
      _step(3, 'Veritabanını tasarla', 'Locked'),
    ];

    await pumpTall(
      tester,
      _app(project: _project(steps), step: steps[1]),
    );

    expect(find.text('REST API + Veritabanı Uygulaması'), findsOneWidget);
    expect(find.text('İlk uç noktayı oluştur'), findsOneWidget);
    expect(find.text('2 / 3 adım'), findsOneWidget);
    expect(find.text('30 dk'), findsOneWidget);
    expect(find.text('ASP.NET Core'), findsWidgets);

    // Neden önemli + yapılacaklar.
    expect(find.text('Bu adım neden önemli?'), findsOneWidget);
    expect(find.text('Yapılacaklar'), findsOneWidget);
    expect(find.text('İlgili içeriği oku'), findsOneWidget);

    // Destekleyici içerik.
    expect(find.text('Öğrenmen gereken içerik'), findsOneWidget);
    expect(find.text('Destekleyici içerik 2'), findsOneWidget);

    expect(find.text('Adımı Tamamla'), findsOneWidget);
  });

  testWidgets('quiz bağlıysa quiz bölümü görünür', (tester) async {
    final steps = [_step(1, 'Gereksinimleri belirle', 'Available')];

    await pumpTall(
      tester,
      _app(project: _project(steps), step: steps[0], quizId: 'q-1'),
    );

    expect(find.text('Bilgini test et'), findsOneWidget);
    expect(find.text("Quiz'i Aç"), findsOneWidget);
  });

  testWidgets('kilitli adımda tamamlama yok, neden kilitli olduğu yazıyor',
      (tester) async {
    final steps = [
      _step(1, 'Gereksinimleri belirle', 'Available'),
      _step(2, 'Veritabanını tasarla', 'Locked'),
    ];

    await pumpTall(
      tester,
      _app(project: _project(steps), step: steps[1]),
    );

    expect(find.text('Bu adım henüz açılmadı.'), findsOneWidget);
    expect(find.text('Adımı Tamamla'), findsNothing);
  });

  testWidgets('adım tamamlanınca başarı geri bildirimi ve sonraki adım gelir',
      (tester) async {
    final before = [
      _step(1, 'Gereksinimleri belirle', 'Available', skillName: 'SQL'),
      _step(2, 'İlk uç noktayı oluştur', 'Locked'),
    ];

    final after = [
      _step(1, 'Gereksinimleri belirle', 'Completed', skillName: 'SQL'),
      _step(2, 'İlk uç noktayı oluştur', 'Available'),
    ];

    final service = _FakeProjectService(_project(after));

    await pumpTall(
      tester,
      _app(project: _project(before), step: before[0], service: service),
    );

    await tester.tap(find.text('Adımı Tamamla'));
    await tester.pumpAndSettle();

    expect(service.completedStepIds, ['step-1']);

    // Başarı geri bildirimi.
    expect(find.text('Adım tamamlandı.'), findsOneWidget);
    expect(find.text('1 / 2 adım tamamlandı.'), findsOneWidget);
    expect(find.text('Sonraki adım açıldı.'), findsOneWidget);
    expect(find.text('SQL becerinde ilerleme kaydettin.'), findsOneWidget);
    expect(find.text('İlk uç noktayı oluştur'), findsWidgets);

    // "Sonraki adıma geç" aynı ekranda sıradaki adıma taşır.
    await tester.tap(find.text('Sonraki adıma geç'));
    await tester.pumpAndSettle();

    expect(find.text('2 / 2 adım'), findsOneWidget);
  });

  testWidgets('proje bitince kapanış mesajı gösterilir', (tester) async {
    final before = [_step(1, 'Son adım', 'Available')];
    final after = [_step(1, 'Son adım', 'Completed')];

    final finished = UserProject(
      id: 'p-1',
      name: 'REST API + Veritabanı Uygulaması',
      description: null,
      status: 'Completed',
      totalSteps: 1,
      completedSteps: 1,
      progressPercent: 100,
      totalMinutes: 30,
      nextStep: null,
      steps: after,
    );

    await pumpTall(
      tester,
      _app(
        project: _project(before),
        step: before[0],
        service: _FakeProjectService(finished),
      ),
    );

    await tester.tap(find.text('Adımı Tamamla'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Projeni tamamladın'),
      findsOneWidget,
    );
    expect(find.text('Sonraki adıma geç'), findsNothing);
  });
}
