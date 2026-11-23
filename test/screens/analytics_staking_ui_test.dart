import 'package:arta/widgets/finance_select.dart';
import 'package:arta/controllers/finance_controller.dart';
import 'package:arta/database/app_database.dart';
import 'package:arta/models/decimal.dart';
import 'package:arta/models/investment.dart';
import 'package:arta/models/money.dart';
import 'package:arta/models/staking.dart';
import 'package:arta/repositories/finance_repository.dart';
import 'package:arta/screens/analytics_screen.dart';
import 'package:arta/screens/staking_screen.dart';
import 'package:arta/services/analytics_service.dart';
import 'package:arta/theme/app_theme.dart';
import 'package:arta/widgets/finance_charts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../fixtures.dart';
import '../repositories/portfolio_repository_test.dart' show bitcoin, event;
import 'finance_flow_test.dart' show capture, captureKey, loadFonts;
import 'investment_ui_test.dart' show openForm, field, FakePriceKeys;

void main() {
  late AppDatabase db;
  late FinanceController c;
  setUp(() async {
    db = AppDatabase.memory();
    final repo = FinanceRepository(db);
    await repo.addAccount(account('broker', '2000'));
    await repo.addAccount(account('minus', '-100'));
    await repo.saveInstrument(bitcoin());
    await repo.saveInvestment(
      event(
        'opening',
        instrument: bitcoin().id,
        kind: InvestmentKind.opening,
        qty: '10',
        gross: '1000',
      ),
    );
    await repo.saveQuotes([
      for (final (date, price) in [
        ('2026-11-01', '100'),
        ('2026-11-02', '110'),
        ('2026-11-15', '120'),
      ])
        PriceQuote(
          instrumentId: bitcoin().id,
          price: Decimal.parse(price),
          currency: 'IDR',
          date: date,
          fetchedAt: '${date}T12:00:00Z',
          source: 'close',
        ),
    ]);
    c = FinanceController(
      repo,
      clock: () => DateTime.utc(2026, 11, 19),
      priceKeys: FakePriceKeys(),
    );
    await c.initialize();
  });
  tearDown(() async {
    c.dispose();
    await db.close();
  });
  testWidgets(
    'all asset scopes render charts, period switches and touch selection work',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.create(Brightness.dark),
          home: AnalyticsScreen(controller: c),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FinanceLineChart), findsOneWidget);
      await tester.tap(find.text('1T'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FinanceLineChart>(find.byType(FinanceLineChart))
            .dates
            .length,
        366,
      );
      await tester.tap(find.byKey(const Key('finance-line-chart')));
      await tester.pump();
      await tester.tap(find.byType(FinanceSelect<AssetScope>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pemasukan & pengeluaran').last);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FinanceLineChart>(find.byType(FinanceLineChart))
            .lines
            .length,
        2,
      );
      expect(find.byType(FinanceDonutChart), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('privacy removes numeric charts and donut from tree', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.create(Brightness.dark),
        home: AnalyticsScreen(controller: c),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tampilkan / sembunyikan nominal'));
    await tester.pumpAndSettle();
    expect(find.byType(FinanceLineChart), findsNothing);
    expect(find.byType(FinanceDonutChart), findsNothing);
    expect(find.textContaining('disembunyikan'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'staking plan and activity forms persist locked units without changing cash',
    (tester) async {
      await openForm(tester, StakingPlanForm(controller: c));
      await tester.enterText(field('Nama posisi / platform'), 'QA Staking');
      await tester.enterText(field('APR referensi % (opsional)'), '5');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('save-staking-plan')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save-staking-plan')));
      await tester.pumpAndSettle();
      expect(c.snapshot.extras.stakingPlans.single.name, 'QA Staking');
      final p = c.snapshot.extras.stakingPlans.single;
      await openForm(tester, StakingEventForm(controller: c, plan: p));
      await tester.enterText(find.byKey(const Key('staking-units')), '6');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('save-staking-event')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save-staking-event')));
      await tester.pumpAndSettle();
      expect(c.snapshot.extras.holdings.single.locked.text, '6');
      expect(c.snapshot.extras.holdings.single.available.text, '4');
      expect(c.snapshot.balance('broker'), Money.input('2000'));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'new screens support small landscape and large fonts in both themes',
    (tester) async {
      const p = StakingPlan(
        id: 'stake',
        accountId: 'broker',
        instrumentId: 'cg:bitcoin',
        name: 'Validator dengan nama panjang',
        apr: null,
      );
      await c.saveStakingPlan(p);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final brightness in Brightness.values) {
        for (final size in [const Size(360, 800), const Size(800, 360)]) {
          tester.view.physicalSize = size;
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          for (final page in [
            AnalyticsScreen(controller: c),
            StakingScreen(controller: c),
            StakingPlanForm(controller: c, existing: p),
            StakingEventForm(controller: c, plan: p),
          ]) {
            await tester.pumpWidget(
              MaterialApp(theme: AppTheme.create(brightness), home: page),
            );
            await tester.pumpAndSettle();
            await tester.drag(
              find.byType(Scrollable).first,
              const Offset(0, -400),
            );
            await tester.pumpAndSettle();
            if (page is AnalyticsScreen) {
              await tester.scrollUntilVisible(
                find.byKey(const Key('finance-donut-chart')),
                250,
                scrollable: find.byType(Scrollable).first,
              );
              await tester.pumpAndSettle();
            }
            expect(
              tester.takeException(),
              isNull,
              reason: '$page $brightness $size',
            );
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
          }
        }
      }
    },
  );
  testWidgets('capture line and donut chart previews in both themes', (
    tester,
  ) async {
    await loadFonts(tester);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(
        RepaintBoundary(
          key: captureKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.create(brightness),
            home: AnalyticsScreen(controller: c),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await capture(tester, 'analytics-${brightness.name}-0.5.0');
      await tester.scrollUntilVisible(
        find.byKey(const Key('finance-donut-chart')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await capture(tester, 'donut-${brightness.name}-0.5.0');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });
}
