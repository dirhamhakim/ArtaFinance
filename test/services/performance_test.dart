import 'package:flutter_test/flutter_test.dart';
import 'package:arta/models/decimal.dart';
import 'package:arta/models/finance_extras.dart';
import 'package:arta/models/investment.dart';
import 'package:arta/models/ledger.dart';
import 'package:arta/models/money.dart';
import 'package:arta/services/performance_service.dart';

import '../fixtures.dart';
import '../repositories/portfolio_repository_test.dart'
    show event, stock, bitcoin;

PriceQuote close(
  String date,
  String price, {
  String id = 'idx:BBCA',
  String? adjusted,
}) => PriceQuote(
  instrumentId: id,
  price: Decimal.parse(price),
  currency: 'IDR',
  date: date,
  fetchedAt: '2026-11-19T12:00:00Z',
  source: 'close',
  adjustedThrough: adjusted,
);
List<PriceQuote> indices() => [
  for (final (date, price) in [
    ('2026-11-01', '1000'),
    ('2026-11-02', '1050'),
    ('2026-11-03', '1100'),
  ])
    close(date, price, id: 'benchmark:ihsg'),
];
LedgerSnapshot basket({
  List<InvestmentEvent>? events,
  List<PriceQuote>? quotes,
}) => LedgerSnapshot(
  accounts: [account('broker', '100000'), account('wallet', '0')],
  transactions: [],
  extras: FinanceExtras(
    instruments: [stock(), bitcoin()],
    events:
        events ??
        [event('start', kind: InvestmentKind.opening, qty: '1', gross: '100')],
    quotes:
        quotes ??
        [
          close('2026-11-01', '100'),
          close('2026-11-02', '110'),
          close('2026-11-03', '120'),
        ],
  ),
);
void main() {
  final service = PerformanceService(), now = DateTime.utc(2026, 11, 3, 12);
  test(
    'portfolio and index normalize to same inception; cash and crypto excluded',
    () {
      final data = basket();
      final result = service.compare(data, indices(), now);
      expect(result.issues, isEmpty);
      expect(result.points.first.portfolio, Money.zero);
      expect(result.points.last.portfolio, Money.input('20'));
      expect(result.points.last.ihsg, Money.input('10'));
    },
  );
  test(
    'large unit contribution at unchanged price is not investment performance',
    () {
      final result = service.compare(
        basket(
          events: [
            event(
              'start',
              kind: InvestmentKind.opening,
              qty: '1',
              gross: '100',
            ),
            event(
              'deposit',
              kind: InvestmentKind.opening,
              qty: '50',
              gross: '5000',
              date: '2026-11-02',
            ),
          ],
          quotes: [close('2026-11-01', '100')],
        ),
        indices(),
        now,
      );
      expect(result.points.map((p) => p.portfolio).toSet(), {Money.zero});
    },
  );
  test('buy at actual execution price links gain and removes added purchase capital', () {
    final result = service.compare(
      basket(
        events: [
          event('start', kind: InvestmentKind.opening, qty: '2', gross: '200'),
          event('buy', qty: '2', gross: '300', date: '2026-11-02'),
        ],
        quotes: [close('2026-11-01', '100'), close('2026-11-02', '150')],
      ),
      indices(),
      now,
    );
    expect(result.points.last.portfolio, Money.input('50'));
  });
  test(
    'full sale retains realized return net of fee while capital is withdrawn',
    () {
      final result = service.compare(
        basket(
          events: [
            event(
              'start',
              kind: InvestmentKind.opening,
              qty: '1',
              gross: '100',
            ),
            event(
              'sell',
              kind: InvestmentKind.sell,
              qty: '1',
              gross: '120',
              fee: '1',
              date: '2026-11-02',
            ),
          ],
        ),
        indices(),
        now,
      );
      expect(result.points.last.portfolio, Money.input('19'));
    },
  );
  test('new buy after full withdrawal resumes chain and accounts for fee', () {
    final result = service.compare(
      basket(
        events: [
          event('start', kind: InvestmentKind.opening, qty: '1', gross: '100'),
          event(
            'sell',
            kind: InvestmentKind.sell,
            qty: '1',
            gross: '110',
            date: '2026-11-02',
          ),
          event('buy', qty: '1', gross: '120', fee: '1', date: '2026-11-03'),
        ],
      ),
      indices(),
      now,
    );
    expect(result.issues, isEmpty);
    expect(result.points.last.portfolio, Money.input('9,09'));
  });
  test(
    'split and internal transfer do not fabricate gain on adjusted history',
    () {
      final result = service.compare(
        basket(
          events: [
            event(
              'start',
              kind: InvestmentKind.opening,
              qty: '1',
              gross: '100',
            ),
            event(
              'split',
              kind: InvestmentKind.split,
              qty: '2',
              gross: '0',
              date: '2026-11-02',
            ),
            event(
              'transfer',
              kind: InvestmentKind.transfer,
              qty: '1',
              gross: '0',
              destination: 'wallet',
              date: '2026-11-03',
            ),
          ],
          quotes: [close('2026-11-01', '50', adjusted: '2026-11-19')],
        ),
        indices(),
        now,
      );
      expect(result.points.map((p) => p.portfolio).toSet(), {Money.zero});
    },
  );
  test('dividend option distinguishes price from distributed total return', () {
    final data = basket(
      events: [
        event('start', kind: InvestmentKind.opening, qty: '1', gross: '100'),
        event(
          'div',
          kind: InvestmentKind.dividend,
          qty: '0',
          gross: '10',
          date: '2026-11-02',
        ),
      ],
      quotes: [close('2026-11-01', '100'), close('2026-11-02', '90')],
    );
    expect(
      service.compare(data, indices(), now).points.last.portfolio,
      Money.input('-10'),
    );
    expect(
      service
          .compare(data, indices(), now, dividends: true)
          .points
          .last
          .portfolio,
      Money.zero,
    );
  });
  test(
    'missing new position valuation breaks chain without using a future close',
    () {
      final extra = Instrument(
        id: 'idx:TLKM',
        code: 'TLKM',
        name: 'Telkom',
        kind: InstrumentKind.stock,
        providerId: 'TLKM.JK',
      );
      final data = basket(
        events: [
          event('start', kind: InvestmentKind.opening, qty: '1', gross: '100'),
          event(
            'new',
            instrument: extra.id,
            kind: InvestmentKind.opening,
            qty: '1',
            gross: '0',
            date: '2026-11-02',
          ),
        ],
      );
      final withExtra = data.withExtras(
        data.extras.copy(
          instruments: [stock(), extra],
          quotes: [
            ...data.extras.quotes,
            close('2026-11-03', '50', id: extra.id),
          ],
        ),
      );
      final result = service.compare(withExtra, indices(), now);
      expect(result.points.first.portfolio, Money.zero);
      expect(result.points[1].portfolio, isNull);
      expect(result.points.last.portfolio, isNull);
      expect(result.issues, isNotEmpty);
    },
  );
  test('benchmark limits effective end and periods rebase at common complete close', () {
    final result = service.compare(
      basket(),
      indices().take(2).toList(),
      now,
      days: 1,
    );
    expect(result.points.single.date, '2026-11-02');
    expect(result.points.single.portfolio, Money.zero);
  });
}
