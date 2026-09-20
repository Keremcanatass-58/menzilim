import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menzilim_app/core/network/api_client.dart';
import 'package:menzilim_app/core/settings/app_settings_controller.dart';
import 'package:menzilim_app/features/projects/models/user_project.dart';
import 'package:menzilim_app/features/projects/screens/project_screen.dart';
import 'package:menzilim_app/features/projects/services/project_service.dart';
import 'package:menzilim_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeProjectService extends ProjectService {
  final List<UserProject> projects;
  final UserProject? afterComplete;
  final Object? error;

  final List<String> completedStepIds = [];

  _FakeProjectService({
    this.projects = const [],
    this.afterComplete,
    this.error,
  }) : super(ApiClient());

  @override
  Future<List<UserProject>> getMyProjects(String token) async {
    if (error != null) throw error!;
    return projects;
  }

  @override
  Future<UserProject> completeStep(String token, String stepId) async {
    completedStepIds.add(stepId);
    return afterComplete ?? projects.first;
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
      description: '$title açıklaması',
      status: status,
      estimatedMinutes: 30,
      contentId: contentId,
      contentTitle: contentId == null ? null : 'İçerik $order',
      skillName: skillName,
    );

UserProject _project({
  required List<UserProjectStep> steps,
  String status = 'InProgress',
}) {
  final completed = steps.where((s) => s.isCompleted).length;

  return UserProject(
    id: 'p-1',
    name: 'REST API + Veritabanı Uygulaması',
    description: 'Bu yolun sonunda çalışan bir API geliştirmiş olacaksın.',
    status: status,
    totalSteps: steps.length,
    completedSteps: completed,
    progressPercent: ((completed / steps.length) * 100).round(),
    totalMinutes: steps.length * 30,
    nextStep: steps.where((s) => s.isAvailable).firstOrNull,
    steps: steps,
  );
}

Widget _app(ProjectService service, {VoidCallback? onGoToToday}) => MenzilimApp(
      settings: AppSettingsController(),
      home: ProjectScreen(projectService: service, onGoToToday: onGoToToday),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': 'test-token'});
  });

  /// Adım kartları uzun bir listede yer alır; tüm liste tek ekranda
  /// kurulsun diye test yüzeyi yükseltilir.
  Future<void> pumpTall(WidgetTester tester, Widget app) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
  }

  testWidgets('proje adımları durumlarıyla listelenir', (tester) async {
    final service = _FakeProjectService(
      projects: [
        _project(
          steps: [
            _step(1, 'Gereksinimleri belirle', 'Completed'),
            _step(2, 'İlk uç noktayı oluştur', 'Available', contentId: 'c-1'),
            _step(3, 'Veritabanını tasarla', 'Locked'),
          ],
        ),
      ],
    );

    await pumpTall(tester, _app(service));

    expect(find.text('REST API + Veritabanı Uygulaması'), findsOneWidget);
    expect(find.text('1/3 adım'), findsWidgets);
    expect(find.text('Tamamlandı'), findsOneWidget);
    expect(find.text('Sıradaki'), findsOneWidget);
    expect(find.text('Kilitli'), findsOneWidget);

    // Kilitli adım neden kilitli olduğunu söyler.
    expect(
      find.text('Bu adım, önceki adımı tamamlayınca açılır.'),
      findsOneWidget,
    );
  });

  testWidgets('yalnızca açık adım tamamlanabilir', (tester) async {
    final service = _FakeProjectService(
      projects: [
        _project(
          steps: [
            _step(1, 'Gereksinimleri belirle', 'Available'),
            _step(2, 'İlk uç noktayı oluştur', 'Locked'),
          ],
        ),
      ],
    );

    await pumpTall(tester, _app(service));

    // Kilitli adımda tamamlama butonu yoktur.
    expect(find.text('Adımı Tamamla'), findsOneWidget);
  });

  testWidgets('adım tamamlanınca proje güncellenir', (tester) async {
    final service = _FakeProjectService(
      projects: [
        _project(
          steps: [
            _step(1, 'Gereksinimleri belirle', 'Available'),
            _step(2, 'İlk uç noktayı oluştur', 'Locked'),
          ],
        ),
      ],
      afterComplete: _project(
        steps: [
          _step(1, 'Gereksinimleri belirle', 'Completed'),
          _step(2, 'İlk uç noktayı oluştur', 'Available'),
        ],
      ),
    );

    await pumpTall(tester, _app(service));

    await tester.tap(find.text('Adımı Tamamla').first);
    await tester.pumpAndSettle();

    expect(service.completedStepIds, ['step-1']);
    expect(find.text('Tamamlandı'), findsOneWidget);
    expect(find.text('1/2 adım'), findsWidgets);
  });

  testWidgets('proje yoksa boş durum yönlendirici mesaj verir',
      (tester) async {
    var goToToday = 0;

    await tester.pumpWidget(
      _app(_FakeProjectService(), onGoToToday: () => goToToday++),
    );
    await tester.pumpAndSettle();

    expect(find.text('Henüz bir projen yok.'), findsOneWidget);
    expect(
      find.textContaining('Uzmanlığın için proje hazırlanıyor'),
      findsOneWidget,
    );

    await tester.tap(find.text('Bugüne Dön'));
    await tester.pumpAndSettle();

    expect(goToToday, 1);
  });

  testWidgets('hata durumunda tekrar denenebilir', (tester) async {
    final service = _FakeProjectService(
      error: ApiException(statusCode: 500, message: 'Sunucu hatası'),
    );

    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    expect(find.text('Projen yüklenemedi.'), findsOneWidget);
    expect(find.text('Tekrar Dene'), findsOneWidget);
  });
}
