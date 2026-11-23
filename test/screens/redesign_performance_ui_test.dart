import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:arta/controllers/finance_controller.dart';
import 'package:arta/database/app_database.dart';
import 'package:arta/models/investment.dart';
import 'package:arta/repositories/finance_repository.dart';
import 'package:arta/repositories/benchmark_repository.dart';
import 'package:arta/screens/home_screen.dart';
import 'package:arta/screens/performance_screen.dart';
import 'package:arta/theme/app_theme.dart';
import 'package:arta/widgets/finance_charts.dart';
import 'package:arta/widgets/finance_empty_state.dart';

import '../fixtures.dart';
import '../repositories/portfolio_repository_test.dart' show stock, event;
import '../services/performance_test.dart' show close;
import '../services/benchmark_test.dart' show BenchmarkFileBundle;
import 'finance_flow_test.dart' show loadFonts, capture, captureKey;
import 'investment_ui_test.dart' show FakePriceKeys;

void main() {
  test('primary button text contrast meets 4.5 in light and dark themes', () {
    for (final brightness in Brightness.values) {
      final theme = AppTheme.create(brightness);
      final bg = theme.filledButtonTheme.style!.backgroundColor!.resolve({})!;
      final fg = theme.filledButtonTheme.style!.foregroundColor!.resolve({})!;
      final a = bg.computeLuminance(), b = fg.computeLuminance();
      final ratio = ((a > b ? a : b) + .05) / ((a < b ? a : b) + .05);
      expect(ratio, greaterThanOrEqualTo(4.5));
    }
  });
  late AppDatabase db;
  late FinanceController c;
  setUp(() async {
    db = AppDatabase.memory();
    final repo = FinanceRepository(db);
    await repo.addAccount(account('broker', '2500000'));
    await repo.addAccount(account('bank', '1000000'));
    await repo.saveInstrument(stock());
    await repo.saveInvestment(
      event('start', kind: InvestmentKind.opening, qty: '100', gross: '900000'),
    );
    await repo.saveQuotes([
      for (final (day, price) in [
        ('2026-11-01', '9000'),
        ('2026-11-03', '9100'),
        ('2026-11-06', '8900'),
        ('2026-11-10', '9400'),
        ('2026-11-12', '9350'),
        ('2026-11-16', '9600'),
        ('2026-11-18', '9800'),
      ])
        close(day, price),
    ]);
    await repo.setPreference('market_daily_auto', 'false');
    c = FinanceController(
      repo,
      clock: () => DateTime.utc(2026, 11, 19, 12),
      priceKeys: FakePriceKeys(),
      benchmarks: BenchmarkRepository(db, bundle: BenchmarkFileBundle()),
    );
    await c.initialize();
    await c.benchmark!.load();
  });
  tearDown(() async {
    c.dispose();
    await db.close();
  });
  testWidgets(
    'benchmark lines, period rebasing, dividend switch and privacy work',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.create(Brightness.dark),
          home: PerformanceScreen(controller: c),
        ),
      );
      await tester.pumpAndSettle();
      final chart = tester.widget<FinanceLineChart>(
        find.byType(FinanceLineChart),
      );
      expect(chart.lines.length, 2);
      expect(chart.lines.first.values.first?.input, '0');
      await tester.tap(find.text('1B'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Sertakan dividen neto'), 300);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(find.text('Estimasi TWR · termasuk dividen neto'), findsOneWidget);
      await tester.ensureVisible(
        find.byTooltip('Tampilkan / sembunyikan nominal'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Tampilkan / sembunyikan nominal'));
      await tester.pumpAndSettle();
      expect(find.byType(FinanceLineChart), findsNothing);
      expect(c.amountsHidden, isTrue);
    },
  );
  testWidgets(
    'redesign and benchmark adapt to large fonts in portrait and landscape',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final size in [const Size(360, 800), const Size(800, 360)]) {
        tester.view.physicalSize = size;
        for (final brightness in Brightness.values) {
          for (final page in [
            HomeScreen(controller: c),
            PerformanceScreen(controller: c),
            const Scaffold(
              body: FinanceEmptyState(message: 'Belum ada transaksi.'),
            ),
          ]) {
            await tester.pumpWidget(
              MaterialApp(theme: AppTheme.create(brightness), home: page),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
          }
        }
      }
    },
  );
  testWidgets('capture redesigned home and benchmark in both themes', (
    tester,
  ) async {
    await loadFonts(tester);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final brightness in Brightness.values) {
      for (final (name, page) in <(String, Widget)>[
        ('home', HomeScreen(controller: c)),
        ('performance', PerformanceScreen(controller: c)),
        (
          'empty',
          const Scaffold(
            body: Center(
              child: FinanceEmptyState(
                message: 'Transaksi yang dicatat akan tampil di sini.',
              ),
            ),
          ),
        ),
      ]) {
        await tester.pumpWidget(
          RepaintBoundary(
            key: captureKey,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.create(brightness),
              home: page,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await capture(tester, '$name-${brightness.name}-0.6.0');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    }
  });
}
