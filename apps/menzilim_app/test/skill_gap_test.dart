import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:menzilim_app/core/network/api_client.dart';
import 'package:menzilim_app/core/settings/app_settings_controller.dart';
import 'package:menzilim_app/features/skills/models/skill_gap_response.dart';
import 'package:menzilim_app/features/skills/services/skill_service.dart';
import 'package:menzilim_app/features/skills/widgets/skill_gap_list.dart';
import 'package:menzilim_app/features/skills/widgets/skill_gap_summary.dart';
import 'package:menzilim_app/main.dart';

class _FakeClient extends http.BaseClient {
  final Map<String, dynamic> payload;
  String? lastUrl;

  _FakeClient(this.payload);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastUrl = request.url.toString();

    final body = utf8.encode(jsonEncode(payload));

    return http.StreamedResponse(Stream.value(body), 200, headers: {
      'content-type': 'application/json; charset=utf-8',
    });
  }
}

Map<String, dynamic> _item(
  String name,
  String current,
  String target,
  int percent,
  int targetPercent,
  String status,
) =>
    {
      'skillId': 's-$name',
      'skillName': name,
      'category': 'Web',
      'currentLevel': current,
      'targetLevel': target,
      'progressPercent': percent,
      'targetProgressPercent': targetPercent,
      'status': status,
    };

final _payload = <String, dynamic>{
  'specializationName': 'Backend',
  'totalCount': 4,
  'reachedCount': 1,
  'developingCount': 2,
  'notStartedCount': 1,
  'remainingCount': 3,
  'items': [
    _item('REST API', 'Beginner', 'Intermediate', 30, 40, 'Developing'),
    _item('SQL', 'Beginner', 'Intermediate', 10, 40, 'NeedsWork'),
    _item('Authentication', 'None', 'Beginner', 0, 1, 'NotStarted'),
    _item('C#', 'Advanced', 'Intermediate', 90, 40, 'Reached'),
  ],
};

SkillGapResponse get _gap => SkillGapResponse.fromJson(_payload);

Widget _host(Widget child) => MenzilimApp(
      settings: AppSettingsController(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  group('SkillGapResponse', () {
    test('API yanıtını okur ve öncelikli becerileri sıralar', () {
      final gap = _gap;

      expect(gap.specializationName, 'Backend');
      expect(gap.totalCount, 4);
      expect(gap.remainingCount, 3);
      expect(gap.items, hasLength(4));

      // Hedefe ulaşmış beceri öncelikli listede yer almaz.
      expect(
        gap.priority(3).map((item) => item.skillName),
        ['REST API', 'SQL', 'Authentication'],
      );
    });

    test('hedefe yaklaşma oranı hedefin eşiğine göre hesaplanır', () {
      final gap = _gap;

      final restApi = gap.items.firstWhere((i) => i.skillName == 'REST API');
      final reached = gap.items.firstWhere((i) => i.skillName == 'C#');
      final notStarted =
          gap.items.firstWhere((i) => i.skillName == 'Authentication');

      expect(restApi.targetProgress, closeTo(0.75, 0.001));
      expect(reached.targetProgress, 1);
      expect(notStarted.targetProgress, 0);
      expect(notStarted.isNotStarted, isTrue);
      expect(reached.isReached, isTrue);
    });
  });

  test('SkillService.getMySkillGap doğru ucu çağırır', () async {
    final client = _FakeClient(_payload);
    final service = SkillService(ApiClient(client: client));

    final gap = await service.getMySkillGap('token');

    expect(client.lastUrl, endsWith('/api/skills/gap/me'));
    expect(gap.items, hasLength(4));
  });

  testWidgets('dashboard özeti kaç becerinin geliştiğini ve CTA gösterir',
      (tester) async {
    var viewed = 0;

    await tester.pumpWidget(
      _host(SkillGapSummary(gap: _gap, onViewPath: () => viewed++)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hedefine göre'), findsOneWidget);
    expect(find.text('3 beceri geliştiriliyor'), findsOneWidget);
    expect(find.text('REST API'), findsOneWidget);
    expect(find.text('SQL'), findsOneWidget);
    expect(find.text('Authentication'), findsOneWidget);
    expect(find.text('C#'), findsNothing);

    await tester.tap(find.text('Yolumu Gör'));
    await tester.pumpAndSettle();

    expect(viewed, 1);
  });

  testWidgets('Yolum listesi mevcut/hedef seviyeyi Türkçe gösterir',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(SkillGapList(gap: _gap)));
    await tester.pumpAndSettle();

    // Ham backend değerleri gösterilmez.
    expect(find.textContaining('Intermediate'), findsNothing);
    expect(find.textContaining('Developing'), findsNothing);

    expect(find.text('Şu an: Başlangıç'), findsWidgets);
    expect(find.text('Hedef: Orta'), findsWidgets);
    expect(find.text('Gelişiyor'), findsOneWidget);
    expect(find.text('Geliştirilmeli'), findsOneWidget);
    expect(find.text('Henüz başlanmadı'), findsWidgets);
    expect(find.text('Hedefe ulaştın'), findsOneWidget);

    // Yüzde tek başına değil, ne olduğu yazılı.
    expect(
      find.text('İçerik ve quizlerde %30 ilerleme'),
      findsOneWidget,
    );
  });
}
