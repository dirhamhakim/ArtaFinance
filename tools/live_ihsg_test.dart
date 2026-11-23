import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:arta/services/market_service.dart';

void main() {
  test('production Yahoo IHSG daily close and IDX search', () async {
    final service = MarketService();
    addTearDown(service.close);
    final closes = await service.ihsgCloses();
    expect(closes, isNotEmpty);
    expect(
      closes.every((q) => q.instrumentId == 'benchmark:ihsg' && !q.isLive),
      isTrue,
    );
    final stocks = await service.searchStocks('BBCA');
    expect(
      stocks.any((i) => i.code == 'BBCA' && i.priceSymbol == 'BBCA.JK'),
      isTrue,
    );
    File('build/ihsg-live-0.6.0.json').writeAsStringSync(
      jsonEncode({
        'verified_at': DateTime.now().toUtc().toIso8601String(),
        'provider': 'Yahoo Finance',
        'symbol': '^JKSE',
        'interval': '1d',
        'completed_sessions': closes.length,
        'first_date': closes.first.date,
        'last_date': closes.last.date,
        'idx_search_verified': 'BBCA.JK',
        'api_key_required': false,
      }),
    );
  });
}
