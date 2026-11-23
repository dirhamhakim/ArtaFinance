import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arta/models/decimal.dart';
import 'package:arta/models/finance_extras.dart';
import 'package:arta/models/investment.dart';
import 'package:arta/models/ledger.dart';
import 'package:arta/services/analytics_service.dart';
import 'package:arta/services/backup_service.dart';
import 'package:arta/services/csv_service.dart';
import 'package:arta/services/reference_prices_service.dart';

import '../fixtures.dart';
import '../repositories/portfolio_repository_test.dart'
    show event, stock, bitcoin;

class FileBundle extends CachingAssetBundle {
  final loaded = <String>[];
  @override
  Future<ByteData> load(String key) async {
    loaded.add(key);
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(bytes);
  }
}

PriceQuote adjusted({
  String date = '2026-11-01',
  String? through = '2026-11-19',
  String price = '50',
  bool reference = true,
}) => PriceQuote(
  instrumentId: 'idx:BBCA',
  price: Decimal.parse(price),
  currency: 'IDR',
  date: date,
  fetchedAt: '2026-11-19T12:00:00Z',
  source: 'test',
  adjustedThrough: through,
  isReference: reference,
);

void main() {
  test('reference index partitions all 944 IDX codes and includes ten default coins', () {
    final index = objectMap(
      jsonDecode(File('assets/data/history/index.json').readAsStringSync()),
    );
    final entries = (index['instruments']! as List<Object?>)
        .map(objectMap)
        .toList();
    final stockCodes = entries
        .where((m) => (m['id']! as String).startsWith('idx:'))
        .map((m) => (m['id']! as String).substring(4))
        .toSet();
    final absent = (index['stock_no_data']! as List<Object?>)
        .cast<String>()
        .toSet();
    final catalog =
        (objectMap(
                  jsonDecode(
                    File('assets/data/idx_stocks.json').readAsStringSync(),
                  ),
                )['stocks']!
                as List<Object?>)
            .map((v) => objectMap(v)['code'])
            .toSet();
    expect(stockCodes.length, 918);
    expect(absent.length, 26);
    expect(stockCodes.intersection(absent), isEmpty);
    expect({...stockCodes, ...absent}, catalog);
    final defaults =
        (jsonDecode(File('assets/data/crypto_defaults.json').readAsStringSync())
                as List<Object?>)
            .map((v) => Instrument.fromJson(objectMap(v)).id)
            .toSet();
    expect(
      entries
          .where((m) => (m['id']! as String).startsWith('cg:'))
          .map((m) => m['id'])
          .toSet(),
      defaults,
    );
  });

  test('Dart reads long stock and crypto histories without altering dates or USD/IDR prices', () {
    final index = objectMap(
      jsonDecode(File('assets/data/history/index.json').readAsStringSync()),
    );
    final entries = (index['instruments']! as List<Object?>).map(objectMap);
    for (final id in ['idx:BBCA', 'idx:TRUE', 'cg:bitcoin', 'cg:ripple']) {
      final meta = entries.firstWhere((v) => v['id'] == id);
      final bytes = File('assets/data/history/${meta['file']}')
          .readAsBytesSync();
      final raw = jsonDecode(utf8.decode(gzip.decode(bytes))) as List<Object?>;
      for (final currency in id.startsWith('cg:') ? ['IDR', 'USD'] : ['IDR']) {
        final quotes = decodeReferencePrices(
          bytes,
          id,
          currency,
          meta['source']! as String,
          index['prepared_at']! as String,
          meta['adjusted_through'] as String?,
        );
        expect(quotes.length, meta['rows']);
        expect(quotes.first.date, meta['first']);
        expect(quotes.last.date, meta['last']);
        expect(quotes.every((q) => q.isReference && !q.isLive), isTrue);
        final column = currency == 'USD' ? 2 : 1;
        expect(
          quotes.first.price,
          Decimal.parse((raw.first! as List<Object?>)[column]! as String),
        );
        expect(
          quotes.last.price,
          Decimal.parse((raw.last! as List<Object?>)[column]! as String),
        );
      }
    }
  });

  test('only needed history loads, aliases work and no-data stocks remain unpriced', () async {
    final bundle = FileBundle(),
        service = ReferencePricesService(bundle: FileBundle());
    final loader = ReferencePricesService(bundle: bundle);
    final alias = Instrument(
      id: 'custom-btc',
      code: 'BTC',
      name: 'Bitcoin',
      kind: InstrumentKind.crypto,
      providerId: 'bitcoin',
    );
    final missing = Instrument(
      id: 'idx:WSKT',
      code: 'WSKT',
      name: 'Waskita',
      kind: InstrumentKind.stock,
      providerId: 'WSKT.JK',
    );
    final data = LedgerSnapshot(
      accounts: [account('broker', '1000')],
      transactions: [],
      extras: FinanceExtras(
        instruments: [stock(), bitcoin(), alias, missing],
        events: [event('b', gross: '100')],
      ),
    );
    final empty = await service.attach(LedgerSnapshot.empty());
    expect(empty.extras.referenceQuotes, isEmpty);
    final attached = await loader.attach(
      data,
      requested: {alias.id, missing.id},
    );
    expect(attached.extras.referenceIssues, isEmpty);
    expect(attached.extras.referenceQuotes.map((q) => q.instrumentId).toSet(), {
      stock().id,
      alias.id,
    });
    expect(attached.extras.latest(missing.id), isNull);
    expect(bundle.loaded.where((p) => p.endsWith('.Z')).length, 2);
    await loader.attach(data, requested: {alias.id});
    expect(bundle.loaded.where((p) => p.endsWith('.Z')).length, 2);
    final manual = adjusted(
      date: attached.extras.latest(stock().id)!.date,
      price: '123',
      reference: false,
    );
    final overlaid = attached.withExtras(
      attached.extras.copy(quotes: [manual]),
    );
    expect(overlaid.extras.latest(stock().id), same(manual));
    final backup = BackupService().encode(overlaid);
    expect(backup.length, lessThan(10000));
    final restored = await BackupService().decode(backup);
    expect(restored.extras.referenceQuotes, isEmpty);
    expect(restored.extras.quotes.single.price, Decimal.parse('123'));
    final again = await loader.attach(restored, requested: {alias.id});
    expect(
      again.extras.referenceQuotes.length,
      attached.extras.referenceQuotes.length,
    );
  });

  test('split-adjusted sources and actual units preserve portfolio value across split', () {
    final events = [
      event('opening', kind: InvestmentKind.opening, qty: '10', gross: '0'),
      event(
        'split',
        kind: InvestmentKind.split,
        qty: '2',
        gross: '0',
        date: '2026-11-02',
      ),
    ];
    final q = adjusted();
    expect(priceAtLedgerUnits(q, events, '2026-11-01'), Decimal.parse('100'));
    expect(priceAtLedgerUnits(q, events, '2026-11-02'), Decimal.parse('50'));
    final data = LedgerSnapshot(
      accounts: [account('broker', '0')],
      transactions: [],
      extras: FinanceExtras(
        instruments: [stock()],
        events: events,
        referenceQuotes: [q],
      ),
    );
    final points = AnalyticsService().history(
      data,
      DateTime.utc(2026, 11, 3),
      days: 2,
    );
    expect(points.map((p) => p.investment?.input).toSet(), {'1000'});
  });

  test(
    'carried unadjusted prices normalize future splits once across locations',
    () {
      final events = [
        event(
          's1',
          kind: InvestmentKind.split,
          qty: '2',
          gross: '0',
          date: '2026-11-02',
        ),
        event(
          's2',
          account: 'wallet',
          kind: InvestmentKind.split,
          qty: '2',
          gross: '0',
          date: '2026-11-02',
        ),
      ];
      expect(
        priceAtLedgerUnits(
          adjusted(through: null, price: '100'),
          events,
          '2026-11-03',
        ),
        Decimal.parse('50'),
      );
      expect(
        priceAtLedgerUnits(adjusted(), events, '2026-11-01'),
        Decimal.parse('100'),
      );
    },
  );

  test('CSV and backup preserve split basis without turning references into user data', () async {
    final q = adjusted(reference: false);
    final data = LedgerSnapshot(
      accounts: [],
      transactions: [],
      extras: FinanceExtras(instruments: [stock()], quotes: [q]),
    );
    final csv = CsvService();
    final prices = csv.prices(utf8.decode(csv.quotes(data)), [
      stock(),
    ], DateTime.utc(2026, 11, 20));
    expect(prices.single.adjustedThrough, '2026-11-19');
    expect(
      (await BackupService().decode(BackupService().encode(data)))
          .extras
          .quotes
          .single
          .adjustedThrough,
      '2026-11-19',
    );
  });
}
