import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menzilim_app/core/design/design_system.dart';
import 'package:menzilim_app/core/settings/app_settings_controller.dart';
import 'package:menzilim_app/core/theme/app_theme.dart';

Widget _host({required Widget child, Brightness brightness = Brightness.light}) {
  return MaterialApp(
    theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('MenzilimCard', () {
    testWidgets('dokunma geri bildirimi verir ve tema renklerini kullanır',
        (tester) async {
      var tapped = 0;

      await tester.pumpWidget(
        _host(
          child: MenzilimCard(
            onTap: () => tapped++,
            child: const Text('kart'),
          ),
        ),
      );

      await tester.tap(find.text('kart'));
      await tester.pumpAndSettle();

      expect(tapped, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('koyu temada da sorunsuz çizilir', (tester) async {
      await tester.pumpWidget(
        _host(
          brightness: Brightness.dark,
          child: const MenzilimCard(
            tone: MenzilimCardTone.primary,
            child: Text('kart'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('MenzilimChip etiketi gösterir', (tester) async {
    await tester.pumpWidget(
      _host(
        child: const MenzilimChip(
          label: '.NET Blog',
          icon: Icons.public,
          tone: MenzilimChipTone.secondary,
        ),
      ),
    );

    expect(find.text('.NET Blog'), findsOneWidget);
  });

  testWidgets('MenzilimProgressBar değeri animasyonla ilerletir',
      (tester) async {
    await tester.pumpWidget(_host(child: const MenzilimProgressBar(value: 0.6)));

    // Animasyon başlarken 0'dan başlar, sonunda hedefe ulaşır.
    await tester.pump(const Duration(milliseconds: 16));
    final initial = tester
        .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
        .value!;

    await tester.pumpAndSettle();
    final settled = tester
        .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
        .value!;

    expect(initial, lessThan(0.6));
    expect(settled, closeTo(0.6, 0.001));
  });

  testWidgets('MenzilimButton yüklenirken tıklanamaz', (tester) async {
    var tapped = 0;

    await tester.pumpWidget(
      _host(
        child: MenzilimButton(
          label: 'Gönder',
          isLoading: true,
          onPressed: () => tapped++,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Gönder'), findsNothing);

    await tester.tap(find.byType(FilledButton));
    // Yükleniyor göstergesi sürekli döndüğü için pumpAndSettle kullanılmaz.
    await tester.pump();

    expect(tapped, 0);
  });

  testWidgets('MenzilimSectionHeader başlık ve eylemi gösterir',
      (tester) async {
    var pressed = 0;

    await tester.pumpWidget(
      _host(
        child: MenzilimSectionHeader(
          title: 'Bugün Senin Alanında',
          subtitle: 'Alanındaki güncel gelişmeler.',
          actionLabel: 'Tüm Haberler',
          onAction: () => pressed++,
        ),
      ),
    );

    expect(find.text('Bugün Senin Alanında'), findsOneWidget);
    expect(find.text('Alanındaki güncel gelişmeler.'), findsOneWidget);

    await tester.tap(find.text('Tüm Haberler'));
    await tester.pumpAndSettle();

    expect(pressed, 1);
  });

  group('Marka', () {
    testWidgets('logo kilidi sembolü ve MENZİLİM yazısını gösterir',
        (tester) async {
      await tester.pumpWidget(_host(child: const MenzilimLogo(markSize: 32)));
      await tester.pumpAndSettle();

      expect(find.byType(MenzilimLogoMark), findsOneWidget);
      // Marka adı çevrilmez ve Türkçe "İ" korunur.
      expect(find.text('MENZİLİM'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('slogan istendiğinde gösterilir', (tester) async {
      await tester.pumpWidget(
        _host(child: const MenzilimLogo(markSize: 32, showTagline: true)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hedefini belir. Yolunu keşfet.'), findsOneWidget);
    });

    testWidgets('sembol koyu temada da sorunsuz çizilir', (tester) async {
      await tester.pumpWidget(
        _host(
          brightness: Brightness.dark,
          child: const MenzilimLogoMark(size: 48, boxed: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(MenzilimLogoMark), findsOneWidget);
    });
  });

  testWidgets('tema uzantısı durum renklerini parlaklığa göre verir',
      (tester) async {
    await tester.pumpWidget(
      _host(brightness: Brightness.dark, child: const SizedBox()),
    );

    final context = tester.element(find.byType(SizedBox));

    expect(context.statusColors, AppStatusColors.dark);
    expect(AppSettingsController.supportedLocales, hasLength(2));
  });
}
