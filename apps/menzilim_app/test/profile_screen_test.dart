import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menzilim_app/core/auth/auth_controller.dart';
import 'package:menzilim_app/core/network/api_client.dart';
import 'package:menzilim_app/core/settings/app_settings_controller.dart';
import 'package:menzilim_app/features/dashboard/models/dashboard_response.dart';
import 'package:menzilim_app/features/dashboard/services/dashboard_service.dart';
import 'package:menzilim_app/features/onboarding/models/onboarding_profile.dart';
import 'package:menzilim_app/features/onboarding/models/onboarding_request.dart';
import 'package:menzilim_app/features/onboarding/models/specialization.dart';
import 'package:menzilim_app/features/onboarding/services/onboarding_service.dart';
import 'package:menzilim_app/features/onboarding/services/specialization_service.dart';
import 'package:menzilim_app/features/profile/screens/profile_screen.dart';
import 'package:menzilim_app/features/progress/models/progress_response.dart';
import 'package:menzilim_app/features/progress/screens/progress_screen.dart';
import 'package:menzilim_app/features/progress/services/progress_service.dart';
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
      completedTasks: 1,
      totalMinutes: 60,
      completedMinutes: 25,
      dailyProgressPercent: 42,
      completedContentCount: 1,
      inProgressContentCount: 0,
    );
  }
}

class _FakeOnboardingService extends OnboardingService {
  final List<OnboardingRequest> saved = [];

  _FakeOnboardingService() : super(ApiClient());

  @override
  Future<OnboardingProfile?> getProfile(String token) async {
    return const OnboardingProfile(
      professionId: 'prof-1',
      specializationId: 'spec-backend',
      experienceLevel: 'Beginner',
      careerGoal: 'Backend geliştirici olmak',
      dailyLearningMinutes: 60,
    );
  }

  @override
  Future<void> saveOnboarding(OnboardingRequest request, String token) async {
    saved.add(request);
  }
}

class _FakeSpecializationService extends SpecializationService {
  _FakeSpecializationService() : super(ApiClient());

  @override
  Future<List<Specialization>> getSpecializations(String professionId) async {
    return [
      Specialization(id: 'spec-backend', name: 'Backend'),
      Specialization(id: 'spec-frontend', name: 'Frontend'),
    ];
  }
}

class _FakeProgressService extends ProgressService {
  _FakeProgressService() : super(ApiClient());

  @override
  Future<ProgressResponse> getMyProgress(String token) async {
    return ProgressResponse.fromJson(const {
      'overview': {
        'completedTaskCount': 4,
        'estimatedLearningMinutes': 90,
        'completedPlanCount': 1,
        'activeDayCount': 2,
      },
      'today': {
        'hasPlan': true,
        'totalTasks': 3,
        'completedTasks': 1,
        'totalMinutes': 60,
        'completedMinutes': 25,
        'progressPercent': 42,
      },
      'content': {'completedCount': 2, 'inProgressCount': 1},
      'quiz': {'attemptCount': 3, 'distinctQuizCount': 2},
      'skills': {'totalCount': 7, 'withProgressCount': 2, 'items': []},
    });
  }
}

Widget _app({_FakeOnboardingService? onboarding}) =>
    MenzilimApp(
      settings: AppSettingsController(),
      auth: AuthController(),
      home: ProfileScreen(
        dashboardService: _FakeDashboardService(),
        onboardingService: onboarding ?? _FakeOnboardingService(),
        specializationService: _FakeSpecializationService(),
        progressService: _FakeProgressService(),
      ),
    );

void main() {
  /// Profil uzun bir listedir; tüm bölümler tek karede kurulsun diye test
  /// yüzeyi yükseltilir.
  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'test-token',
      'user_email': 'kullanici@menzilim.test',
    });
  });

  testWidgets('profil bilgileri ve ilerleme özeti gösterilir', (tester) async {
    useTallSurface(tester);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('kullanici@menzilim.test'), findsOneWidget);
    expect(find.text('Yazılım Geliştirici'), findsOneWidget);
    expect(find.text('Backend'), findsOneWidget);
    expect(find.text('Beginner'), findsOneWidget);
    expect(find.text('60 dakika'), findsOneWidget);
    expect(find.text('Backend geliştirici olmak'), findsOneWidget);

    // İlerleme özeti.
    expect(find.text('4'), findsOneWidget);
    expect(find.text('90'), findsOneWidget);
  });

  testWidgets('İlerlememi Gör ProgressScreen açar', (tester) async {
    useTallSurface(tester);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final action = find.text('İlerlememi Gör');
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(find.byType(ProgressScreen), findsOneWidget);
  });

  testWidgets('uzmanlık ve günlük süre düzenlenip kaydedilir', (tester) async {
    useTallSurface(tester);

    final onboarding = _FakeOnboardingService();

    await tester.pumpWidget(_app(onboarding: onboarding));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Düzenle'));
    await tester.pumpAndSettle();

    // Uzmanlık değiştirilir.
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Frontend').last);
    await tester.pumpAndSettle();

    // Günlük süre değiştirilir.
    await tester.tap(find.widgetWithText(ChoiceChip, '30 dk'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(onboarding.saved, hasLength(1));
    expect(onboarding.saved.single.specializationId, 'spec-frontend');
    expect(onboarding.saved.single.dailyLearningMinutes, 30);
    expect(onboarding.saved.single.professionId, 'prof-1');
  });

  testWidgets('çıkış butonu oturumu kapatır', (tester) async {
    useTallSurface(tester);

    final auth = AuthController();
    await auth.restore();

    await tester.pumpWidget(
      MenzilimApp(
        settings: AppSettingsController(),
        auth: auth,
        home: ProfileScreen(
          dashboardService: _FakeDashboardService(),
          onboardingService: _FakeOnboardingService(),
          specializationService: _FakeSpecializationService(),
          progressService: _FakeProgressService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final logout = find.text('Çıkış Yap');
    await tester.ensureVisible(logout);
    await tester.tap(logout);
    await tester.pumpAndSettle();

    expect(auth.status, AuthStatus.unauthenticated);
  });
}
