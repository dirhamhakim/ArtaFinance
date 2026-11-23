import '../models/decimal.dart';
import '../models/investment.dart';
import '../models/ledger.dart';
import '../models/money.dart';

final class PerformancePoint {
  const PerformancePoint(this.date, this.portfolio, this.ihsg);
  final String date;

  /// Percentage return, represented at two decimal places without doubles.
  final Money? portfolio;
  final Money ihsg;
}

final class PerformanceResult {
  const PerformanceResult(this.points, this.issues, this.includesDividends);
  final List<PerformancePoint> points;
  final Set<String> issues;
  final bool includesDividends;
}

/// Flow-linked stock-basket TWR estimate. At a trade, that stock is marked at
/// execution price; other stocks use their previous known close. All stocks
/// are marked at completed daily closes at EOD. No intraday marks are invented.
/// RDN cash is outside the basket, so buys/opening units are contributions and
/// sales are withdrawals. Internal unit transfers and splits are not deposits.
final class PerformanceService {
  PerformanceResult compare(
    LedgerSnapshot data,
    List<PriceQuote> benchmark,
    DateTime now, {
    int? days = 365,
    bool dividends = false,
    int maxPoints = 366,
  }) {
    if (days != null && days < 1 || maxPoints < 2) {
      throw ArgumentError('Periode tidak valid.');
    }
    final stocks = {
      for (final i in data.extras.instruments.where(
        (i) => i.kind == InstrumentKind.stock,
      ))
        i.id: i,
    };
    final events =
        data.extras.events
            .where((e) => stocks.containsKey(e.instrumentId))
            .toList()
          ..sort(compareInvestmentEvents);
    final today = localDate(now.toUtc().add(const Duration(hours: 7)));
    final indices = {
      for (final q in benchmark.where(
        (q) => !q.isLive && q.date.compareTo(today) <= 0,
      ))
        q.date: q,
    };
    if (events.isEmpty || indices.isEmpty) {
      return PerformanceResult([], {}, dividends);
    }
    final end = indices.keys.reduce((a, b) => a.compareTo(b) > 0 ? a : b);
    final start = days == null
        ? events.first.date
        : localDate(DateTime.parse(today).subtract(Duration(days: days)));
    if (events.first.date.compareTo(end) > 0) {
      return PerformanceResult([], {}, dividends);
    }
    final used = events.map((e) => e.instrumentId).toSet();
    final splits = events.where((e) => e.kind == InvestmentKind.split).toList();
    final quotes =
        data.extras.allQuotes
            .where(
              (q) =>
                  !q.isLive &&
                  used.contains(q.instrumentId) &&
                  q.date.compareTo(end) <= 0,
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    final closes = <String, PriceQuote>{}, marks = <String, Decimal>{};
    final replay = PortfolioReplay();
    final points = <PerformancePoint>[];
    final issues = <String>{};
    var eventCursor = 0, quoteCursor = 0;
    var factor = Decimal.one;
    Decimal? indexBase;
    Money? pivot;
    var dayDividends = Money.zero;
    var broken = false;
    Money? value() {
      var result = dayDividends;
      for (final h in replay.pools.values.where((h) => h.quantity.positive)) {
        final price = marks[h.instrumentId];
        if (price == null) {
          if (indexBase != null) {
            issues.add('Harga ${stocks[h.instrumentId]!.code} belum lengkap.');
          }
          return null;
        }
        result = result + (h.quantity * price).money();
      }
      return result;
    }

    void link(Money? endValue, Money? base) {
      if (indexBase == null || broken) return;
      if (endValue == null ||
          base == null ||
          endValue.isNegative ||
          base.isNegative) {
        broken = true;
        issues.add(
          'Return tidak dapat disambung karena valuasi belum lengkap.',
        );
        return;
      }
      if (base.isZero) {
        if (!endValue.isZero) {
          broken = true;
          issues.add('Perubahan nilai tanpa modal pembanding.');
        }
        return;
      }
      factor =
          factor *
          Decimal(roundRatio(endValue.minor * Decimal.scale, base.minor));
    }

    for (
      var date = DateTime.parse(events.first.date);
      localDate(date).compareTo(end) <= 0;
      date = date.add(const Duration(days: 1))
    ) {
      final day = localDate(date);
      while (eventCursor < events.length &&
          events[eventCursor].date.compareTo(day) <= 0) {
        final e = events[eventCursor++];
        final gross = e.idrRate.timesMoney(e.gross),
            fee = e.idrRate.timesMoney(e.fee);
        if ((e.kind == InvestmentKind.buy || e.kind == InvestmentKind.sell) &&
            e.quantity.positive) {
          marks[e.instrumentId] =
              Decimal(
                roundRatio(gross.minor * Decimal.scale, BigInt.from(100)),
              ) /
              e.quantity;
        }
        final before = value();
        link(before, pivot);
        replay.apply(e);
        if (e.kind == InvestmentKind.split && marks[e.instrumentId] != null) {
          marks[e.instrumentId] = marks[e.instrumentId]! / e.quantity;
        }
        var after = value();
        switch (e.kind) {
          case InvestmentKind.buy:
            link(after, before == null ? null : before + gross + fee);
          case InvestmentKind.sell:
            link(before == null ? null : before - fee, before);
          case InvestmentKind.opening:
            // Existing capital is linked before the new units are contributed.
            if (indexBase != null && after == null) {
              broken = true;
              issues.add('Harga saldo unit awal belum tersedia.');
            }
          case InvestmentKind.dividend:
            if (dividends) {
              dayDividends = dayDividends + gross - fee;
              after = value();
              link(after, before);
            }
          case InvestmentKind.reward:
            link(after, before);
          case InvestmentKind.transfer:
            link(after == null ? null : after - fee, before);
          case InvestmentKind.split:
            link(after, before);
          default:
            throw const FormatException(
              'Aktivitas non-saham pada pembanding saham.',
            );
        }
        pivot = after;
      }
      while (quoteCursor < quotes.length &&
          quotes[quoteCursor].date.compareTo(day) <= 0) {
        final q = quotes[quoteCursor++];
        final old = closes[q.instrumentId];
        if (old == null || comparePriceQuotes(q, old) < 0) {
          closes[q.instrumentId] = q;
        }
      }
      marks.clear();
      for (final close in closes.values) {
        marks[close.instrumentId] = priceAtLedgerUnits(close, splits, day);
      }
      final closing = value();
      link(closing, pivot);
      pivot = closing == null ? null : closing - dayDividends;
      dayDividends = Money.zero;
      final index = indices[day];
      if (index == null || day.compareTo(start) < 0) continue;
      if (indexBase == null) {
        if (pivot == null || !pivot.isPositive) continue;
        indexBase = index.price;
        factor = Decimal.one;
        broken = false;
      }
      points.add(
        PerformancePoint(
          day,
          broken
              ? null
              : ((factor - Decimal.one) * Decimal.parse('100')).money(),
          ((index.price / indexBase - Decimal.one) * Decimal.parse('100'))
              .money(),
        ),
      );
    }
    if (points.length <= maxPoints) {
      return PerformanceResult(points, issues, dividends);
    }
    final stride = ((points.length - 1) / (maxPoints - 1)).ceil();
    return PerformanceResult(
      [
        for (var i = 0; i < points.length; i += stride) points[i],
        if ((points.length - 1) % stride != 0) points.last,
      ],
      issues,
      dividends,
    );
  }
}
