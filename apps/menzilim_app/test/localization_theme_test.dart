import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menzilim_app/core/network/api_client.dart';
import 'package:menzilim_app/core/settings/app_settings_controller.dart';
import 'package:menzilim_app/core/theme/app_theme.dart';
import 'package:menzilim_app/features/ai_coach/screens/ai_coach_screen.dart';
import 'package:menzilim_app/features/auth/screens/login_screen.dart';
import 'package:menzilim_app/features/news/models/news_item.dart';
import 'package:menzilim_app/features/news/screens/news_screen.dart';
import 'package:menzilim_app/features/news/services/news_service.dart';
import 'package:menzilim_app/features/progress/models/progress_response.dart';
import 'package:menzilim_app/features/progress/screens/progress_screen.dart';
import 'package:menzilim_app/features/progress/services/progress_service.dart';
import 'package:menzilim_app/features/skills/models/skill_progress_response.dart';
import 'package:menzilim_app/features/skills/screens/skills_screen.dart';
import 'package:menzilim_app/features/skills/services/skill_service.dart';
import 'package:menzilim_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeNewsService extends NewsService {
  _FakeNewsService() : super(ApiClient());

  @override
  Future<List<NewsItem>> getMyNews(String token) async => [
        NewsItem(
          id: 'n1',
          title: '.NET 10 yayınlandı',
          summary: 'Özet',
          sourceName: '.NET Blog',
          sourceUrl: 'https://devblogs.microsoft.com/dotnet/announcing-dotnet-10/',
          publishedAt: DateTime(2025, 11, 11),
        ),
      ];
}

class _FakeSkillService extends SkillService {
  _FakeSkillService() : super(ApiClient());

  @override
  Future<List<SkillProgressResponse>> getMySkills(String token) async => [
        SkillProgressResponse(
          skillId: 's1',
          skillName: 'C#',
          category: 'Programlama',
          progressPercent: 40,
          totalContentCount: 2,
          completedContentCount: 1,
          inProgressContentCount: 1,
          totalQuizCount: 1,
          attemptedQuizCount: 1,
          quizAttemptCount: 2,
          bestQuizScore: 80,
          latestQuizScore: 60,
        ),
      ];
}

class _FakeProgressService extends ProgressService {
  _FakeProgressService() : super(ApiClient());

  @override
  Future<ProgressResponse> getMyProgress(String token) async => const ProgressResponse(
        overview: ProgressOverview(
          completedTaskCount: 3,
          estimatedLearningMinutes: 45,
          completedPlanCount: 1,
          activeDayCount: 2,
        ),
        today: ProgressToday(
          hasPlan: true,
          totalTasks: 3,
          completedTasks: 1,
          totalMinutes: 60,
          completedMinutes: 25,
          progressPercent: 42,
        ),
        content: ProgressContent(completedCount: 1, inProgressCount: 1),
        quiz: ProgressQuiz(
          attemptCount: 2,
          distinctQuizCount: 1,
          bestScore: 80,
          averageScore: 70,
          latestScore: 60,
        ),
        skills: ProgressSkills(
          totalCount: 7,
          startedCount: 1,
          strongest: [],
          focus: [],
        ),
      );
}

Widget _app(AppSettingsController settings, {Widget home = const LoginScreen()}) {
  return MenzilimApp(settings: settings, home: home);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': 'test-token'});
  });

  group('Dil', () {
    testWidgets('varsayılan dil Türkçe', (tester) async {
      await tester.pumpWidget(_app(AppSettingsController()));
      await tester.pumpAndSettle();

      expect(find.text('Tekrar hoş geldin.'), findsOneWidget);
      expect(find.text('Giriş Yap'), findsOneWidget);
      expect(find.text('Kayıt Ol'), findsOneWidget);
    });

    testWidgets('İngilizce seçiliyse ekran İngilizce', (tester) async {
      await tester.pumpWidget(
        _app(AppSettingsController(locale: const Locale('en'))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome back.'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Tekrar hoş geldin.'), findsNothing);
    });

    testWidgets('dil değişikliği yeniden başlatmadan uygulanır', (tester) async {
      final settings = AppSettingsController();

      await tester.pumpWidget(_app(settings));
      await tester.pumpAndSettle();
      expect(find.text('Giriş Yap'), findsOneWidget);

      await settings.setLocale(const Locale('en'));
      await tester.pumpAndSettle();

      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Giriş Yap'), findsNothing);
    });

    testWidgets('kayıtlı dil yeniden açılışta kullanılır', (tester) async {
      await AppSettingsController().setLocale(const Locale('en'));

      final reloaded = await AppSettingsController.load();
      await tester.pumpWidget(_app(reloaded));
      await tester.pumpAndSettle();

      expect(find.text('Welcome back.'), findsOneWidget);
    });
  });

  group('Tema', () {
    Brightness brightnessOf(WidgetTester tester) =>
        Theme.of(tester.element(find.byType(LoginScreen))).brightness;

    testWidgets('Light seçiliyse açık tema', (tester) async {
      await tester.pumpWidget(
        _app(AppSettingsController(themeMode: ThemeMode.light)),
      );
      await tester.pumpAndSettle();

      expect(brightnessOf(tester), Brightness.light);
    });

    testWidgets('Dark seçiliyse koyu tema ve koyu durum renkleri', (tester) async {
      await tester.pumpWidget(
        _app(AppSettingsController(themeMode: ThemeMode.dark)),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(LoginScreen));
      expect(brightnessOf(tester), Brightness.dark);
      expect(context.statusColors, AppStatusColors.dark);
    });

    testWidgets('System seçiliyse cihaz görünümünü izler', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await tester.pumpWidget(_app(AppSettingsController()));
      await tester.pumpAndSettle();

      expect(brightnessOf(tester), Brightness.dark);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();

      expect(brightnessOf(tester), Brightness.light);
    });

    testWidgets('kayıtlı tema yeniden açılışta kullanılır', (tester) async {
      await AppSettingsController().setThemeMode(ThemeMode.dark);

      final reloaded = await AppSettingsController.load();
      await tester.pumpWidget(_app(reloaded));
      await tester.pumpAndSettle();

      expect(brightnessOf(tester), Brightness.dark);
    });
  });

  group('Kritik ekranlar koyu tema + İngilizce', () {
    AppSettingsController darkEnglish() => AppSettingsController(
          locale: const Locale('en'),
          themeMode: ThemeMode.dark,
        );

    testWidgets('News', (tester) async {
      await tester.pumpWidget(
        _app(darkEnglish(), home: NewsScreen(newsService: _FakeNewsService())),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('News in Your Field'), findsOneWidget);
      expect(find.text('Read Article'), findsOneWidget);
      expect(find.text('November 11, 2025'), findsOneWidget);
      // Backend'den gelen haber başlığı çevrilmez.
      expect(find.text('.NET 10 yayınlandı'), findsOneWidget);
    });

    testWidgets('Skills', (tester) async {
      await tester.pumpWidget(
        _app(darkEnglish(), home: SkillsScreen(skillService: _FakeSkillService())),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('My Skills'), findsOneWidget);
      expect(find.text('Best score: 80%'), findsOneWidget);
      expect(find.text('You\'ve made progress in 1 of 1 skill.'), findsOneWidget);
    });

    testWidgets('Progress', (tester) async {
      await tester.pumpWidget(
        _app(darkEnglish(), home: ProgressScreen(progressService: _FakeProgressService())),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Overall Progress'), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('2 attempts'), findsOneWidget);
      expect(find.text('Progress in 1 of 7 skills'), findsOneWidget);
    });

    testWidgets('AI Coach', (tester) async {
      await tester.pumpWidget(_app(darkEnglish(), home: const AiCoachScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('AI Coach'), findsOneWidget);
      expect(find.text('Send'), findsOneWidget);
    });
  });
}
