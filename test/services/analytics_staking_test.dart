import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:arta/controllers/finance_controller.dart';
import 'package:arta/database/app_database.dart';
import 'package:arta/models/decimal.dart';
import 'package:arta/models/finance_extras.dart';
import 'package:arta/models/investment.dart';
import 'package:arta/models/ledger.dart';
import 'package:arta/models/money.dart';
import 'package:arta/models/staking.dart';
import 'package:arta/repositories/finance_repository.dart';
import 'package:arta/services/analytics_service.dart';
import 'package:arta/services/backup_service.dart';
import 'package:arta/services/csv_service.dart';
import 'package:arta/services/market_service.dart';

import '../fixtures.dart';
import '../repositories/portfolio_repository_test.dart'
    show event, bitcoin, stock;
import '../screens/investment_ui_test.dart' show FakePriceKeys;

PriceQuote quote(
  String date,
  String price, {
  bool live = false,
  String instrument = 'cg:bitcoin',
}) => PriceQuote(
  instrumentId: instrument,
  price: Decimal.parse(price),
  currency: 'IDR',
  date: date,
  fetchedAt: '2026-11-19T12:00:00Z',
  source: live ? 'latest' : 'close',
  isLive: live,
);
InvestmentEvent stakingEvent(
  String id,
  InvestmentKind kind,
  String qty, {
  String date = '2026-11-02',
  bool pending = false,
  bool restake = false,
  String fee = '0',
}) => InvestmentEvent(
  id: id,
  instrumentId: 'cg:bitcoin',
  accountId: 'broker',
  kind: kind,
  quantity: Decimal.parse(qty),
  gross: Money.zero,
  fee: Money.input(fee),
  date: date,
  createdAt: '${date}T02:00:00Z',
  idrRate: Decimal.one,
  stakingId: 'stake',
  pendingBucket: pending,
  rewardStaked: restake,
);
const plan = StakingPlan(
  id: 'stake',
  accountId: 'broker',
  instrumentId: 'cg:bitcoin',
  name: 'Validator uji',
);
LedgerSnapshot sample({List<PriceQuote>? quotes}) => LedgerSnapshot(
  accounts: [account('broker', '1000')],
  transactions: [],
  extras: FinanceExtras(
    instruments: [bitcoin()],
    events: [event('buy', instrument: 'cg:bitcoin', qty: '2', gross: '200')],
    quotes: quotes ?? [quote('2026-11-01', '100'), quote('2026-11-02', '110')],
  ),
);

void main() {
  final now = DateTime.utc(2026, 11, 3, 12);
  for (final status in [404, 429]) {
    test(
      'daily close HTTP $status isolates missing symbols and provider failures',
      () async {
        final db = AppDatabase.memory();
        addTearDown(db.close);
        final repo = FinanceRepository(db);
        final other = Instrument(
          id: 'idx:BBRI',
          code: 'BBRI',
          name: 'Bank Rakyat Indonesia',
          kind: InstrumentKind.stock,
          providerId: 'BBRI.JK',
        );
        await repo.replace(
          LedgerSnapshot(
            accounts: [account('broker', '1000')],
            transactions: [],
            extras: FinanceExtras(
              instruments: [stock(), other, bitcoin()],
              events: [
                event('one', gross: '100'),
                event('two', instrument: other.id, gross: '100'),
                event('btc', instrument: 'cg:bitcoin', qty: '2', gross: '200'),
              ],
            ),
          ),
        );
        final calls = <String>[];
        final market = MarketService(
          clock: () => now,
          client: MockClient((request) async {
            calls.add(request.url.path);
            if (request.url.path.endsWith('BBCA.JK')) {
              return http.Response('{}', status);
            }
            if (request.url.host == 'api.coingecko.com') {
              return http.Response(
                jsonEncode({
                  'prices': [
                    [DateTime.utc(2026, 11, 3).millisecondsSinceEpoch, 110],
                  ],
                }),
                200,
              );
            }
            return http.Response(
              jsonEncode({
                'chart': {
                  'result': [
                    {
                      'meta': {'symbol': 'BBRI.JK', 'currency': 'IDR'},
                      'timestamp': [
                        DateTime.utc(2026, 11, 2).millisecondsSinceEpoch ~/
                            1000,
                      ],
                      'indicators': {
                        'quote': [
                          {
                            'close': [1000],
                          },
                        ],
                      },
                    },
                  ],
                },
              }),
              200,
            );
          }),
        );
        final c = FinanceController(
          repo,
          clock: () => now,
          market: market,
          priceKeys: FakePriceKeys(),
        );
        addTearDown(c.dispose);
        await c.initialize();
        expect(await c.refreshDailyCloses(), isFalse);
        expect(c.snapshot.extras.latest('cg:bitcoin')!.price.text, '110');
        expect(c.snapshot.extras.latest('idx:BBCA'), isNull);
        expect(calls.any((path) => path.endsWith('BBRI.JK')), status == 404);
        expect(
          c.snapshot.extras.latest(other.id)?.price.text,
          status == 404 ? '1000' : null,
        );
        expect(calls.length, status == 404 ? 3 : 2);
      },
    );
  }
  test('automatic network sync does not block recording and cannot lose concurrent account changes', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final repo = FinanceRepository(db);
    await repo.replace(sample(quotes: []));
    final requested = Completer<void>();
    final response = Completer<http.Response>();
    final market = MarketService(
      clock: () => now,
      client: MockClient((_) {
        requested.complete();
        return response.future;
      }),
    );
    final c = FinanceController(
      repo,
      clock: () => now,
      market: market,
      priceKeys: FakePriceKeys(),
    );
    addTearDown(c.dispose);
    await c.initialize();
    final updating = c.refreshDailyCloses();
    await requested.future;
    expect(c.pricesBusy, isTrue);
    expect(c.busy, isFalse);
    expect(
      await c.createAccount(
        'While fetching',
        AccountKind.bank,
        Money.input('25'),
      ),
      isTrue,
    );
    response.complete(
      http.Response(
        jsonEncode({
          'prices': [
            [DateTime.utc(2026, 11, 3).millisecondsSinceEpoch, 110],
          ],
        }),
        200,
      ),
    );
    await updating;
    expect(c.snapshot.accounts.length, 2);
    expect(c.snapshot.extras.latest('cg:bitcoin')!.price.text, '110');
    expect(c.snapshot.accounts.any((a) => a.name == 'While fetching'), isTrue);
  });
  test('stock daily check persists yesterday then checks again after the closing window', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final repo = FinanceRepository(db);
    await repo.replace(
      LedgerSnapshot(
        accounts: [account('broker', '1000')],
        transactions: [],
        extras: FinanceExtras(
          instruments: [stock()],
          events: [event('b', qty: '100', gross: '200')],
        ),
      ),
    );
    var at = DateTime.utc(2026, 11, 3, 8);
    var calls = 0;
    final market = MarketService(
      clock: () => at,
      client: MockClient((_) async {
        calls++;
        return http.Response(
          jsonEncode({
            'chart': {
              'result': [
                {
                  'meta': {
                    'symbol': 'BBCA.JK',
                    'currency': 'IDR',
                    'currentTradingPeriod': {
                      'regular': {
                        'end':
                            DateTime.utc(
                              2026,
                              11,
                              3,
                              9,
                            ).millisecondsSinceEpoch ~/
                            1000,
                      },
                    },
                  },
                  'timestamp': [
                    DateTime.utc(2026, 11, 2, 2).millisecondsSinceEpoch ~/ 1000,
                    DateTime.utc(2026, 11, 3, 2).millisecondsSinceEpoch ~/ 1000,
                  ],
                  'indicators': {
                    'quote': [
                      {
                        'close': [100, 110],
                      },
                    ],
                  },
                },
              ],
            },
          }),
          200,
        );
      }),
    );
    final c = FinanceController(
      repo,
      clock: () => at,
      market: market,
      priceKeys: FakePriceKeys(),
    );
    addTearDown(c.dispose);
    await c.initialize();
    await c.refreshDailyCloses();
    await c.refreshDailyCloses();
    expect(calls, 1);
    expect(c.snapshot.extras.latest(stock().id)!.date, '2026-11-02');
    at = DateTime.utc(2026, 11, 3, 11);
    await c.refreshDailyCloses();
    await c.refreshDailyCloses();
    expect(calls, 2);
    expect(c.snapshot.extras.latest(stock().id)!.date, '2026-11-03');
    expect(
      c.snapshot.extras.quotes
          .where((q) => !q.isLive)
          .map((q) => q.date)
          .toSet(),
      {'2026-11-02', '2026-11-03'},
    );
  });
  test('historical value includes cash once, uses dated holdings and no future quote', () {
    final data = sample(
      quotes: [
        quote('2026-11-02', '110'),
        quote('2026-11-03', '9999', live: true),
      ],
    );
    final series = AnalyticsService().history(data, now, days: 2);
    expect(series[0].cash, Money.input('800'));
    expect(series[0].investment, isNull);
    expect(series[0].combined, isNull);
    expect(series[1].investment, Money.input('220'));
    expect(series[1].combined, Money.input('1020'));
    expect(series[2].investment, Money.input('220'));
    expect(data.investmentValue, Money.input('220'));
    expect(data.extras.latest('cg:bitcoin', live: true)!.price.text, '9999');
  });
  test('backfilled historical price fills only appropriate gaps', () {
    final data = sample(quotes: [quote('2026-11-03', '120')]);
    final before = AnalyticsService().history(data, now, days: 2);
    final after = AnalyticsService().history(
      data.withExtras(
        data.extras.copy(
          quotes: [...data.extras.quotes, quote('2026-11-01', '100')],
        ),
      ),
      now,
      days: 2,
    );
    expect(before.first.investment, isNull);
    expect(after.first.investment, Money.input('200'));
    expect(after.last.investment, Money.input('240'));
  });
  test(
    'donut excludes negative balances without removing their net impact',
    () {
      final base = sample();
      final data = LedgerSnapshot(
        accounts: [...base.accounts, account('minus', '-100')],
        transactions: [],
        extras: base.extras,
      );
      final all = AnalyticsService().composition(data, AssetScope.combined);
      expect(all.positiveTotal, Money.input('1020'));
      expect(all.negativeTotal, Money.input('-100'));
      expect(all.net, Money.input('920'));
      final cash = AnalyticsService().composition(data, AssetScope.cash);
      expect(cash.positiveTotal, Money.input('800'));
      expect(cash.net, Money.input('700'));
    },
  );
  test(
    'cashflow series excludes transfers and purchase principal, includes fees',
    () {
      final data = LedgerSnapshot(
        accounts: [account('broker', '1000'), account('bank', '0')],
        transactions: [
          transaction(
            id: 'income',
            kind: TransactionKind.income,
            source: 'broker',
            amount: '100',
            date: '2026-11-01',
          ),
          transaction(
            id: 'transfer',
            kind: TransactionKind.transfer,
            source: 'broker',
            destination: 'bank',
            amount: '200',
            fee: '5',
            date: '2026-11-02',
          ),
          transaction(
            id: 'expense',
            source: 'bank',
            amount: '20',
            date: '2026-11-02',
          ),
        ],
        extras: sample().extras,
      );
      final points = AnalyticsService().history(data, now, days: 2);
      expect(points.first.income, Money.input('100'));
      expect(points.first.expense, Money.zero);
      expect(points[1].income, Money.zero);
      expect(points[1].expense, Money.input('25'));
      expect(points.last.combined, Money.input('1095'));
    },
  );
  test('all-history sampling caps work and aggregates interval flows', () {
    final data = LedgerSnapshot(
      accounts: [
        Account(
          id: 'old',
          name: 'Old',
          kind: AccountKind.bank,
          opening: Money.zero,
          createdAt: '2000-01-01T00:00:00Z',
        ),
      ],
      transactions: [
        transaction(
          id: 'x',
          kind: TransactionKind.income,
          source: 'old',
          amount: '100',
          date: '2020-01-01',
        ),
      ],
    );
    final points = AnalyticsService().history(data, now, days: null);
    expect(points.length, lessThanOrEqualTo(367));
    expect(points.fold(Money.zero, (s, p) => s + p.income), Money.input('100'));
  });
  test('unknown historical FX is a gap; explicit historical rate is not overwritten by a future rate', () {
    final data = LedgerSnapshot(
      accounts: [
        Account(
          id: 'usd',
          name: 'USD',
          kind: AccountKind.bank,
          opening: Money.input('10'),
          currency: 'USD',
          createdAt: '2026-11-01T00:00:00Z',
        ),
      ],
      transactions: [],
      extras: FinanceExtras(
        rates: [
          FxRate(
            currency: 'USD',
            rate: Decimal.parse('16000'),
            date: '2026-11-03',
          ),
        ],
        rateHistory: [
          FxRate(
            currency: 'USD',
            rate: Decimal.parse('15000'),
            date: '2026-11-02',
          ),
        ],
      ),
    );
    final series = AnalyticsService().history(data, now, days: 2);
    expect(series.first.cash, isNull);
    expect(series[1].cash, Money.input('150000'));
    expect(series.last.cash, Money.input('160000'));
  });
  test('ten defaults use verified IDs and do not erase custom overrides or duplicate aliases', () async {
    final raw = jsonDecode(
      File('assets/data/crypto_defaults.json').readAsStringSync(),
    ) as List<Object?>;
    final defaults = raw.map((v) => Instrument.fromJson(objectMap(v))).toList();
    expect(defaults.map((i) => i.code).toSet(), {
      'BTC',
      'ETH',
      'SOL',
      'HYPE',
      'USDT',
      'USDC',
      'XAUT',
      'PAXG',
      'BNB',
      'XRP',
    });
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final repo = FinanceRepository(db);
    final custom = Instrument.fromJson({
      ...bitcoin().toJson(),
      'id': 'my-bitcoin',
      'overrides': {'name': 'My BTC'},
      'archived': true,
    });
    await repo.saveInstrument(custom);
    await repo.ensureDefaultInstruments(defaults);
    await repo.ensureDefaultInstruments(defaults);
    final data = await repo.load();
    expect(data.extras.instruments.length, 10);
    expect(
      data.extras.instruments
          .where((i) => i.priceSymbol == 'bitcoin')
          .single
          .displayName,
      'My BTC',
    );
    expect(
      data.extras.instruments.any((i) => i.priceSymbol == 'binancecoin'),
      isTrue,
    );
  });
  group('staking atomic replay', () {
    late AppDatabase db;
    late FinanceRepository repo;
    setUp(() async {
      db = AppDatabase.memory();
      repo = FinanceRepository(db);
      await repo.addAccount(account('broker', '0'));
      await repo.saveInstrument(bitcoin());
      await repo.saveStakingPlan(plan);
      await repo.saveInvestment(
        event(
          'opening',
          instrument: bitcoin().id,
          kind: InvestmentKind.opening,
          qty: '10',
          gross: '1000',
        ),
      );
    });
    tearDown(() async => db.close());
    test('stake and pending keep principal once; withdraw frees only the selected bucket', () async {
      await repo.saveInvestment(
        stakingEvent('stake1', InvestmentKind.stake, '6'),
      );
      await repo.saveInvestment(
        stakingEvent(
          'pending',
          InvestmentKind.unstakeRequest,
          '2',
          date: '2026-11-03',
        ),
      );
      var data = await repo.load();
      var state = replayPortfolio(data.extras.events);
      expect(state.holdings.single.quantity.text, '10');
      expect(state.holdings.single.available.text, '4');
      expect(state.staking['stake']!.staked.text, '4');
      expect(state.staking['stake']!.pending.text, '2');
      expect(data.balance('broker'), Money.zero);
      expect(state.holdings.single.cost, Money.input('1000'));
      await repo.saveInvestment(
        stakingEvent(
          'withdraw',
          InvestmentKind.unstake,
          '2',
          date: '2026-11-04',
          pending: true,
        ),
      );
      data = await repo.load();
      expect(data.extras.holdings.single.available.text, '6');
      expect(
        replayPortfolio(data.extras.events).staking['stake']!.pending.isZero,
        isTrue,
      );
    });
    test('locked units cannot be sold, transferred or staked again; history rollback is atomic', () async {
      await repo.saveInvestment(
        stakingEvent('stake1', InvestmentKind.stake, '6'),
      );
      await expectLater(
        repo.saveInvestment(
          event(
            'sell',
            instrument: bitcoin().id,
            kind: InvestmentKind.sell,
            qty: '5',
            gross: '500',
            date: '2026-11-03',
          ),
        ),
        throwsFormatException,
      );
      await expectLater(
        repo.saveInvestment(stakingEvent('again', InvestmentKind.stake, '5')),
        throwsFormatException,
      );
      await expectLater(
        repo.deleteInvestment('opening'),
        throwsFormatException,
      );
      final data = await repo.load();
      expect(data.extras.events.length, 2);
      expect(data.extras.holdings.single.quantity.text, '10');
      expect(data.balance('broker'), Money.zero);
    });
    test('reward restake and slashing remove proportional basis, fees only touch cash', () async {
      await repo.saveInvestment(
        stakingEvent('stake1', InvestmentKind.stake, '6', fee: '5'),
      );
      await repo.saveInvestment(
        stakingEvent(
          'reward',
          InvestmentKind.stakingReward,
          '1',
          date: '2026-11-03',
          restake: true,
        ),
      );
      await repo.saveInvestment(
        stakingEvent(
          'loss',
          InvestmentKind.stakingLoss,
          '1',
          date: '2026-11-04',
        ),
      );
      final data = await repo.load();
      final h = data.extras.holdings.single;
      expect(h.quantity.text, '10');
      expect(h.locked.text, '6');
      expect(h.available.text, '4');
      expect(h.cost, Money.input('909,09'));
      expect(h.realized, Money.zero);
      expect(data.balance('broker'), Money.input('-5'));
      expect(data.incomeForMonth('2026-11'), Money.zero);
      expect(data.expenseForMonth('2026-11'), Money.input('5'));
      final b = replayPortfolio(data.extras.events).staking['stake']!;
      expect(b.rewards.text, '1');
      expect(b.losses.text, '1');
    });
    test('delete/reorder unstake dependencies and wrong position references are rejected', () async {
      await repo.saveInvestment(stakingEvent('s', InvestmentKind.stake, '4'));
      await repo.saveInvestment(
        stakingEvent(
          'p',
          InvestmentKind.unstakeRequest,
          '2',
          date: '2026-11-03',
        ),
      );
      await repo.saveInvestment(
        stakingEvent(
          'u',
          InvestmentKind.unstake,
          '2',
          date: '2026-11-04',
          pending: true,
        ),
      );
      await expectLater(repo.deleteInvestment('p'), throwsFormatException);
      final wrong = InvestmentEvent.fromJson({
        ...stakingEvent('wrong', InvestmentKind.stake, '1').toJson(),
        'staking_id': 'missing',
      });
      await expectLater(repo.saveInvestment(wrong), throwsFormatException);
      await expectLater(
        repo.saveStakingPlan(
          StakingPlan(
            id: 'stake',
            accountId: 'broker',
            instrumentId: stock().id,
            name: 'bad',
          ),
        ),
        throwsFormatException,
      );
    });
    test('v5 backup persists all staking states and v4 without extension fields still restores', () async {
      await repo.saveInvestment(stakingEvent('s', InvestmentKind.stake, '4'));
      final data = await repo.load();
      final encoded = BackupService().encode(data);
      final restored = await BackupService().decode(encoded);
      expect(restored.extras.stakingPlans.single.name, plan.name);
      expect(restored.extras.holdings.single.locked.text, '4');
      final old = objectMap(
        jsonDecode(utf8.decode(BackupService().encode(sample()))),
      );
      old['schema_version'] = 4;
      final extras = objectMap(old['extras']);
      extras.remove('staking_plans');
      extras.remove('rate_history');
      final legacy = await BackupService().decode(
        Uint8List.fromList(utf8.encode(jsonEncode(old))),
      );
      expect(legacy.extras.stakingPlans, isEmpty);
      expect(legacy.extras.holdings.single.quantity.text, '2');
    });
    test('CSV exports staking identity and preserves live/close distinction on price reimport', () async {
      await repo.saveInvestment(stakingEvent('s', InvestmentKind.stake, '4'));
      await repo.saveQuotes([
        quote('2026-11-02', '100'),
        PriceQuote.fromJson({
          ...quote('2026-11-02', '110', live: true).toJson(),
          'source': 'close',
        }),
      ]);
      final data = await repo.load();
      final csv = CsvService();
      final tx = csv.parse(utf8.decode(csv.transactions(data)));
      expect(tx.every((r) => r.length == tx.first.length), isTrue);
      expect(tx.last[tx.first.indexOf('staking_id')], 'stake');
      final prices = csv.prices(
        utf8.decode(csv.quotes(data)),
        data.extras.instruments,
        now,
      );
      expect(prices.where((q) => q.isLive).length, 1);
      expect(prices.where((q) => !q.isLive).length, 1);
      final holdings = csv.parse(utf8.decode(csv.holdings(data)));
      expect(holdings[1][holdings[0].indexOf('locked_staking_units')], '4');
    });
    test('saving an earlier FX rate retains the current rate and both historical observations', () async {
      await repo.saveRate(
        FxRate(
          currency: 'USD',
          rate: Decimal.parse('16000'),
          date: '2026-11-03',
        ),
      );
      await repo.saveRate(
        FxRate(
          currency: 'USD',
          rate: Decimal.parse('15000'),
          date: '2026-11-02',
        ),
      );
      final data = await repo.load();
      expect(data.extras.rate('USD')!.text, '16000');
      expect(data.extras.rateHistory.length, 2);
    });
  });
  test('daily crypto parser rejects live tail and waits 35 minutes before a completed day', () {
    int stamp(String date) => DateTime.parse(date).millisecondsSinceEpoch;
    final raw = <String, Object?>{
      'prices': [
        [stamp('2026-11-02T00:00:00Z'), 100],
        [stamp('2026-11-03T00:00:00Z'), 110],
        [stamp('2026-11-03T10:01:00Z'), 9999],
      ],
    };
    final early = MarketService.parseCryptoCloses(
      raw,
      bitcoin(),
      DateTime.utc(2026, 11, 3, 0, 20),
    );
    expect(early.map((q) => q.date), ['2026-11-01']);
    final ready = MarketService.parseCryptoCloses(
      raw,
      bitcoin(),
      DateTime.utc(2026, 11, 3, 1),
    );
    expect(ready.map((q) => q.date), ['2026-11-01', '2026-11-02']);
    expect(ready.last.price.text, '110');
    expect(ready.every((q) => !q.isLive), isTrue);
  });
  test('foreground close sync requests once per target day, ignores live and persists retry backoff', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final repo = FinanceRepository(db);
    await repo.replace(sample(quotes: []));
    var calls = 0;
    var fail = false;
    final market = MarketService(
      clock: () => now,
      client: MockClient((r) async {
        calls++;
        expect(r.url.path, endsWith('/market_chart'));
        expect(r.url.queryParameters['interval'], 'daily');
        if (fail) return http.Response('{}', 503);
        return http.Response(
          jsonEncode({
            'prices': [
              [DateTime.utc(2026, 11, 3).millisecondsSinceEpoch, 110],
              [DateTime.utc(2026, 11, 3, 10).millisecondsSinceEpoch, 9999],
            ],
          }),
          200,
        );
      }),
    );
    final c = FinanceController(
      repo,
      clock: () => now,
      market: market,
      priceKeys: FakePriceKeys(),
    );
    addTearDown(c.dispose);
    await c.initialize();
    await c.refreshDailyCloses();
    await c.refreshDailyCloses();
    expect(calls, 1);
    expect(c.snapshot.extras.latest('cg:bitcoin')!.price.text, '110');
    c.marketForeground = false;
    await c.refreshDailyCloses(force: true);
    expect(calls, 1);
    c.marketForeground = true;
    await repo.setPreference('market_close_checked_cg:bitcoin', 'old');
    await repo.setPreference(
      'market_close_attempt_cg:bitcoin',
      '2026-11-01T00:00:00Z',
    );
    fail = true;
    await c.refreshDailyCloses();
    await c.refreshDailyCloses();
    expect(calls, 2);
    expect(c.snapshot.extras.latest('cg:bitcoin')!.price.text, '110');
  });
}
