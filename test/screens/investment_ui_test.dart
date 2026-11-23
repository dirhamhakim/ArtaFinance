import 'package:arta/controllers/finance_controller.dart';
import 'package:arta/database/app_database.dart';
import 'package:arta/models/decimal.dart';
import 'package:arta/models/investment.dart';
import 'package:arta/models/ledger.dart';
import 'package:arta/models/money.dart';
import 'package:arta/repositories/finance_repository.dart';
import 'package:arta/screens/catalog_screen.dart';
import 'package:arta/screens/interest_screen.dart';
import 'package:arta/screens/investment_form.dart';
import 'package:arta/screens/market_settings_screen.dart';
import 'package:arta/screens/portfolio_screen.dart';
import 'package:arta/screens/transaction_form.dart';
import 'package:arta/screens/debts_screen.dart';
import 'package:arta/services/backup_service.dart';
import 'package:arta/services/interest_engine.dart';
import 'package:arta/services/market_service.dart';
import 'package:arta/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../fixtures.dart';
import '../repositories/portfolio_repository_test.dart' show event, stock;
import '../services/interest_engine_test.dart' show rule;
import 'finance_flow_test.dart' show capture, captureKey, loadFonts;

class FakePriceKeys implements PriceKeyStore {
  String value = '';
  @override
  Future<String> read() async => value;
  @override
  Future<void> write(String key) async {
    value = key;
  }
}

Instrument fund() => Instrument(
  id: 'bibit:rdpu',
  code: 'RDPU',
  name: 'Reksa Dana Pasar Uang',
  kind: InstrumentKind.fund,
);
Finder field(String label) => find.widgetWithText(TextFormField, label);
Future<void> openForm(WidgetTester tester, Widget page) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.create(Brightness.dark),
      home: Builder(
        builder: (ctx) => Scaffold(
          body: FilledButton(
            onPressed: () => Navigator.push<void>(
              ctx,
              MaterialPageRoute(builder: (_) => page),
            ),
            child: const Text('Buka form'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Buka form'));
  await tester.pumpAndSettle();
}

void main() {
  late AppDatabase db;
  late FinanceRepository repo;
  late FinanceController c;
  late FakePriceKeys keys;
  setUp(() async {
    db = AppDatabase.memory();
    repo = FinanceRepository(db);
    keys = FakePriceKeys();
    c = FinanceController(
      repo,
      clock: () => DateTime.utc(2026, 11, 19, 10),
      priceKeys: keys,
    );
    await repo.addAccount(account('broker', '1000000'));
    await repo.saveInstrument(fund());
    await c.initialize();
  });
  tearDown(() async {
    c.dispose();
    await db.close();
  });
  testWidgets('form beli menyimpan kas dan unit secara bersamaan', (
    tester,
  ) async {
    await openForm(tester, InvestmentForm(controller: c, instrument: fund()));
    await tester.enterText(
      find.byKey(const Key('investment-units')),
      '123,456',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('investment-gross')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byKey(const Key('investment-gross')), '150000');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('save-investment')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byKey(const Key('save-investment')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-investment')));
    await tester.pumpAndSettle();
    expect(c.snapshot.balance('broker'), Money.input('850000'));
    expect(c.snapshot.extras.holdings.single.quantity.text, '123.456');
    expect(find.text('Buka form'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('NAB manual mengubah valuasi tanpa mengubah unit atau kas', (
    tester,
  ) async {
    await c.saveInvestment(
      event('buy', instrument: fund().id, qty: '100', gross: '150000'),
    );
    await openForm(tester, PriceForm(controller: c, instrument: fund()));
    await tester.enterText(find.byKey(const Key('manual-price')), '1600,5');
    await tester.tap(find.text('Simpan harga'));
    await tester.pumpAndSettle();
    expect(c.snapshot.investmentValue, Money.input('160050'));
    expect(c.snapshot.balance('broker'), Money.input('850000'));
    expect(c.snapshot.extras.holdings.single.quantity.text, '100');
  });
  testWidgets(
    'pengaturan API key terpisah dari backup, mata dan refresh opsional',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.create(Brightness.dark),
          home: MarketSettingsScreen(controller: c),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        field('CoinGecko Demo API key (opsional)'),
        'demo-test-key-private',
      );
      await tester.scrollUntilVisible(
        find.text('Simpan pengaturan harga'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Simpan pengaturan harga'));
      await tester.pumpAndSettle();
      expect(keys.value, 'demo-test-key-private');
      expect(await repo.preference('market_daily_auto'), 'true');
      expect(
        String.fromCharCodes(BackupService().encode(c.snapshot)),
        isNot(contains('demo-test-key-private')),
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'konfirmasi bunga aktual memakai input pengguna dan neto satu kali',
    (tester) async {
      // Rule fixture targets bank, so supply a separate account with the same balance.
      await repo.addAccount(account('bank', '1000000'));
      await c.saveInterestRule(rule());
      final estimate = InterestEngine.pending(
        c.snapshot,
        DateTime.utc(2026, 11, 2),
      ).single;
      await openForm(
        tester,
        InterestPostForm(controller: c, estimate: estimate),
      );
      await tester.enterText(field('Bunga bruto aktual'), '120');
      await tester.enterText(field('Pajak aktual'), '24');
      await tester.tap(find.text('Catat bunga aktual'));
      await tester.pumpAndSettle();
      expect(c.snapshot.balance('bank'), Money.input('1000096'));
      expect(
        c.snapshot.extras.interestPostings.single.gross,
        Money.input('120'),
      );
    },
  );
  testWidgets(
    'edit transfer lintas uang memiliki nominal diterima yang eksplisit',
    (tester) async {
      await repo.addAccount(
        Account(
          id: 'usd',
          name: 'USD',
          kind: AccountKind.cash,
          opening: Money.zero,
          createdAt: '2026-11-19T00:00:00Z',
          currency: 'USD',
        ),
      );
      final tx = LedgerTransaction.fromJson({
        ...transaction(
          kind: TransactionKind.transfer,
          source: 'broker',
          destination: 'usd',
          amount: '160000',
        ).toJson(),
        'destination_minor': Money.input('10').stored,
        'idr_rate': '1',
      });
      await repo.saveTransaction(tx);
      await c.initialize();
      await openForm(tester, TransactionForm(controller: c, existing: tx));
      await tester.ensureVisible(find.byKey(const Key('destination-amount')));
      await tester.enterText(find.byKey(const Key('destination-amount')), '11');
      FocusManager.instance.primaryFocus?.unfocus();
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      final save = find.byKey(const Key('save-transaction'));
      await tester.scrollUntilVisible(
        save,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(c.snapshot.balance('usd'), Money.input('11'));
      expect(c.snapshot.balance('broker'), Money.input('840000'));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'portofolio, grafik, katalog dan bunga aman pada layar kecil/font besar',
    (tester) async {
      await repo.saveInstrument(stock());
      await c.saveInvestment(
        event('buy', instrument: fund().id, qty: '100', gross: '150000'),
      );
      await c.saveQuotes([
        for (final date in ['2026-11-17', '2026-11-18'])
          PriceQuote(
            instrumentId: fund().id,
            price: Decimal.parse(date.endsWith('18') ? '1600' : '1500'),
            currency: 'IDR',
            date: date,
            fetchedAt: '${date}T10:00:00Z',
            source: 'NAB manual',
          ),
      ]);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final size in [const Size(360, 800), const Size(800, 360)]) {
        tester.view.physicalSize = size;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        for (final page in <Widget>[
          PortfolioScreen(controller: c),
          CatalogScreen(controller: c),
          InterestScreen(controller: c),
          DebtsScreen(controller: c),
          InstrumentDetailScreen(controller: c, instrument: fund()),
        ]) {
          await tester.pumpWidget(
            MaterialApp(theme: AppTheme.create(Brightness.dark), home: page),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        }
      }
    },
  );
  testWidgets('preview portofolio dan grafik mengikuti tema gelap terang', (
    tester,
  ) async {
    await loadFonts(tester);
    await c.saveInvestment(
      event('buy', instrument: fund().id, qty: '100', gross: '150000'),
    );
    await c.saveQuotes([
      for (final date in ['2026-11-17', '2026-11-18'])
        PriceQuote(
          instrumentId: fund().id,
          price: Decimal.parse(date.endsWith('18') ? '1600' : '1500'),
          currency: 'IDR',
          date: date,
          fetchedAt: '${date}T10:00:00Z',
          source: 'NAB manual',
        ),
    ]);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final brightness in [Brightness.dark, Brightness.light]) {
      await tester.pumpWidget(
        RepaintBoundary(
          key: captureKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.create(brightness),
            home: PortfolioScreen(controller: c),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await capture(tester, 'portfolio-${brightness.name}-0.4.0');
      await tester.pumpWidget(
        RepaintBoundary(
          key: captureKey,
          child: MaterialApp(
            theme: AppTheme.create(brightness),
            home: InstrumentDetailScreen(controller: c, instrument: fund()),
            debugShowCheckedModeBanner: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await capture(tester, 'price-chart-${brightness.name}-0.4.0');
    }
    expect(tester.takeException(), isNull);
  });
}
