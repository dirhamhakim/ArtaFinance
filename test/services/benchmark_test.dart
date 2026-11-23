import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:arta/database/app_database.dart';
import 'package:arta/controllers/benchmark_controller.dart';
import 'package:arta/repositories/benchmark_repository.dart';
import 'package:arta/repositories/finance_repository.dart';
import 'package:arta/models/investment.dart';
import 'package:arta/models/ledger.dart';
import 'package:arta/services/market_service.dart';

import 'performance_test.dart' show close;

class BenchmarkFileBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(await File(key).readAsBytes());
}

void main() {
  test(
    'bundled IHSG is daily, ordered, exact and available entirely offline',
    () {
      final meta = objectMap(
        jsonDecode(File('assets/data/ihsg_meta.json').readAsStringSync()),
      );
      final quotes = decodeIhsg(
        File('assets/data/ihsg.json.Z').readAsBytesSync(),
        meta['retrieved_at']! as String,
      );
      expect(quotes.length, meta['rows']);
      expect(quotes.length, greaterThan(8500));
      expect(quotes.first.date, meta['first']);
      expect(quotes.last.date, meta['last']);
      expect(
        quotes.every((q) => !q.isLive && q.instrumentId == 'benchmark:ihsg'),
        isTrue,
      );
    },
  );
  test('IHSG overlay persists outside financial extras and does not duplicate dates', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final repo = BenchmarkRepository(db, bundle: BenchmarkFileBundle());
    final initial = await repo.load();
    final q = close(initial.last.date, '1234', id: 'benchmark:ihsg');
    await repo.save([q]);
    await repo.save([q]);
    final loaded = await repo.load();
    expect(loaded.length, initial.length);
    expect(loaded.last.price, q.price);
    expect((await FinanceRepository(db).load()).extras.quotes, isEmpty);
    await expectLater(
      repo.save([close('2026-11-19', '1')]),
      throwsFormatException,
    );
  });
  test('daily index refresh uses JKSE, skips intraday, persists target and retry backoff', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    var calls = 0;
    Uri? requested;
    final market = MarketService(
      clock: () => DateTime.utc(2026, 11, 19, 12),
      client: MockClient((request) async {
        calls++;
        requested = request.url;
        return http.Response(
          jsonEncode({
            'chart': {
              'result': [
                {
                  'meta': {
                    'symbol': '^JKSE',
                    'currency': 'IDR',
                    'currentTradingPeriod': {
                      'regular': {
                        'end':
                            DateTime.utc(
                              2026,
                              11,
                              19,
                              9,
                            ).millisecondsSinceEpoch ~/
                            1000,
                      },
                    },
                  },
                  'timestamp': [
                    DateTime.utc(2026, 11, 19, 2).millisecondsSinceEpoch ~/
                        1000,
                  ],
                  'indicators': {
                    'quote': [
                      {
                        'close': [1234],
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
    addTearDown(market.close);
    final c = BenchmarkController(
      BenchmarkRepository(db, bundle: BenchmarkFileBundle()),
      FinanceRepository(db),
      market,
      clock: () => DateTime.utc(2026, 11, 19, 12),
    );
    addTearDown(c.dispose);
    await c.refresh();
    await c.refresh();
    await c.refresh(force: true);
    expect(calls, 1);
    expect(Uri.decodeComponent(requested!.path), endsWith('/^JKSE'));
    expect(requested!.queryParameters['interval'], '1d');
    expect(requested!.queryParameters.containsKey('period1'), isTrue);
    expect(c.quotes.last.date, '2026-11-19');
  });
  test('Yahoo search accepts only IDX equities and preserves mapping for IPO additions', () async {
    final market = MarketService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'quotes': [
              {
                'symbol': 'BBCA.JK',
                'quoteType': 'EQUITY',
                'longname': 'Bank Central Asia',
              },
              {
                'symbol': 'IPOX.JK',
                'quoteType': 'EQUITY',
                'shortname': 'IPO Example',
              },
              {'symbol': 'AAPL', 'quoteType': 'EQUITY'},
              {'symbol': '^JKSE', 'quoteType': 'INDEX'},
              {'symbol': 'FUND.JK', 'quoteType': 'MUTUALFUND'},
            ],
          }),
          200,
        ),
      ),
    );
    addTearDown(market.close);
    final results = await market.searchStocks('bank');
    expect(results.map((i) => i.code), ['BBCA', 'IPOX']);
    expect(results.last.priceSymbol, 'IPOX.JK');
    expect(
      results.every(
        (i) => i.kind == InstrumentKind.stock && i.currency == 'IDR',
      ),
      isTrue,
    );
  });
}
