import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:arta/models/investment.dart';
import 'package:arta/services/market_service.dart';

void main() {
  test('production daily close request parses midnight observations and drops live tail', () async {
    final path = Platform.environment['ARTA_CG_KEY_FILE'];
    if (path == null)
      throw StateError(
        'Provide private credential file path through ARTA_CG_KEY_FILE.',
      );
    final key = File(path).readAsStringSync().trim();
    final now = DateTime.now().toUtc();
    final service = MarketService(clock: () => now);
    addTearDown(service.close);
    final rows = await service.cryptoCloses(
      Instrument(
        id: 'cg:bitcoin',
        code: 'BTC',
        name: 'Bitcoin',
        kind: InstrumentKind.crypto,
        providerId: 'bitcoin',
      ),
      key,
    );
    expect(rows, isNotEmpty);
    expect(rows.every((q) => !q.isLive && q.asOf != null), isTrue);
    for (final q in rows) {
      final at = DateTime.parse(q.asOf!);
      expect(at.hour, 0);
      expect(at.minute, 0);
      expect(at.second, 0);
    }
    File('build/daily-close-live-0.5.0.json').writeAsStringSync(
      jsonEncode({
        'verified_at': now.toIso8601String(),
        'provider': 'CoinGecko Demo',
        'instrument': 'bitcoin',
        'observations': rows.length,
        'first_date': rows.first.date,
        'last_date': rows.last.date,
        'last_as_of': rows.last.asOf,
        'live_tail_excluded': true,
        'credential_recorded': false,
      }),
    );
  });
}
