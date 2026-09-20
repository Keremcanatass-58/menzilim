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
import 'package:menzilim_app/features/news/models/news_item.dart';
import 'package:menzilim_app/features/news/screens/news_screen.dart';
import 'package:menzilim_app/features/news/services/news_link_opener.dart';
import 'package:menzilim_app/features/news/services/news_service.dart';
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
      dailyLearningMinutes: 30,
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
  ) async =>
      [];
}

class _FakeSkillService extends SkillService {
  _FakeSkillService() : super(ApiClient());

  @override
  Future<List<SkillProgressResponse>> getMySkills(String token) async => [];
}

class _FakeNewsService extends NewsService {
  final List<Future<List<NewsItem>> Function()> responses;
  int calls = 0;

  _FakeNewsService(this.responses) : super(ApiClient());

  @override
  Future<List<NewsItem>> getMyNews(String token) {
    final response = responses[calls.clamp(0, responses.length - 1)];
    calls++;
    return response();
  }
}

NewsItem _news(String id, String title) => NewsItem(
      id: id,
      title: title,
      summary: '$title özeti',
      sourceName: '.NET Blog',
      sourceUrl: 'https://devblogs.microsoft.com/dotnet/$id/',
      publishedAt: DateTime(2025, 11, 11),
    );

Widget _app(NewsService newsService, {NewsLinkOpener? openLink}) {
  return MaterialApp(
    home: DashboardScreen(
      dashboardService: _FakeDashboardService(),
      dailyPlanService: _FakeDailyPlanService(),
      contentService: _FakeContentService(),
      skillService: _FakeSkillService(),
      newsService: newsService,
      openNewsLink: openLink,
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': 'test-token'});
  });

  testWidgets('en fazla 2 haber gösterir ve tümünü görme bağlantısı sunar',
      (tester) async {
    final news = _FakeNewsService([
      () async => [
            _news('a', 'Haber A'),
            _news('b', 'Haber B'),
            _news('c', 'Haber C'),
            _news('d', 'Haber D'),
          ],
    ]);

    await tester.pumpWidget(_app(news));
    await tester.pumpAndSettle();

    expect(find.text('Bugün Senin Alanında'), findsOneWidget);
    expect(find.text('Haber A'), findsOneWidget);
    expect(find.text('Haber B'), findsOneWidget);
    expect(find.text('Haber C'), findsNothing);
    expect(find.text('Haber D'), findsNothing);
    expect(find.text('Tüm Haberler'), findsOneWidget);
  });

  testWidgets('Tüm Haberler NewsScreen\'e götürür', (tester) async {
    final news = _FakeNewsService([
      () async => [for (var i = 0; i < 4; i++) _news('n$i', 'Haber $i')],
    ]);

    await tester.pumpWidget(_app(news));
    await tester.pumpAndSettle();

    final action = find.text('Tüm Haberler');
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(find.byType(NewsScreen), findsOneWidget);
    expect(find.text('Senin Alanında Gündem'), findsOneWidget);
    // Tüm liste (4 haber) NewsScreen'de.
    await tester.scrollUntilVisible(find.text('Haber 3'), 200);
    expect(find.text('Haber 3'), findsOneWidget);
  });

  testWidgets('dashboard kartındaki Haberi İncele kaynağı açar', (tester) async {
    final opened = <Uri>[];
    final news = _FakeNewsService([
      () async => [_news('announcing-dotnet-10', '.NET 10 yayınlandı')],
    ]);

    await tester.pumpWidget(_app(news, openLink: (uri) async {
      opened.add(uri);
      return true;
    }));
    await tester.pumpAndSettle();

    final action = find.text('Haberi İncele');
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(opened, [
      Uri.parse('https://devblogs.microsoft.com/dotnet/announcing-dotnet-10/'),
    ]);
  });

  testWidgets('haber hatası dashboard\'u düşürmez ve tekrar denenebilir',
      (tester) async {
    final news = _FakeNewsService([
      () async => throw ApiException(statusCode: 500, message: 'Hata'),
      () async => [_news('a', 'Haber A')],
    ]);

    await tester.pumpWidget(_app(news));
    await tester.pumpAndSettle();

    // Dashboard'un diğer bölümleri çalışır.
    expect(find.text('Bugünün Yol Haritası'), findsOneWidget);
    expect(find.text('Sana Özel İçerikler'), findsOneWidget);
    expect(find.text('Haberler yüklenemedi.'), findsOneWidget);
    expect(find.text('Tüm Haberler'), findsNothing);

    final retry = find.descendant(
      of: find.ancestor(
        of: find.text('Haberler yüklenemedi.'),
        matching: find.byType(Wrap),
      ),
      matching: find.text('Tekrar Dene'),
    );
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(news.calls, 2);
    expect(find.text('Haberler yüklenemedi.'), findsNothing);
    expect(find.text('Haber A'), findsOneWidget);
  });

  testWidgets('haber yoksa boş durum gösterir', (tester) async {
    await tester.pumpWidget(_app(_FakeNewsService([() async => []])));
    await tester.pumpAndSettle();

    expect(find.text('Şu an alanında gösterilecek haber yok.'), findsOneWidget);
    expect(find.text('Tüm Haberler'), findsNothing);
  });
}
