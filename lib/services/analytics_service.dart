import '../models/decimal.dart';
import '../models/investment.dart';
import '../models/ledger.dart';
import '../models/money.dart';

enum AssetScope { combined, investment, cash, cashflow }

String scopeLabel(AssetScope scope) => switch (scope) {
  AssetScope.combined => 'Gabungan aset',
  AssetScope.investment => 'Portofolio investasi',
  AssetScope.cash => 'Aset noninvestasi',
  AssetScope.cashflow => 'Pemasukan & pengeluaran',
};

final class AnalyticsPoint {
  AnalyticsPoint({
    required this.date,
    required this.cash,
    required this.investment,
    required this.income,
    required this.expense,
    this.missingCash = 0,
    this.missingInvestments = 0,
  });
  final String date;
  final Money? cash, investment;
  final Money income, expense;
  final int missingCash, missingInvestments;
  Money? get combined =>
      cash == null || investment == null ? null : cash! + investment!;
  Money? value(AssetScope scope) => switch (scope) {
    AssetScope.cash => cash,
    AssetScope.investment => investment,
    AssetScope.combined => combined,
    AssetScope.cashflow => income,
  };
}

final class AssetSlice {
  const AssetSlice(this.label, this.value);
  final String label;
  final Money value;
}

final class AssetComposition {
  AssetComposition({
    required this.positive,
    required this.negative,
    required this.missing,
  });
  final List<AssetSlice> positive, negative;
  final int missing;
  Money get positiveTotal => positive.fold(Money.zero, (s, p) => s + p.value);
  Money get negativeTotal => negative.fold(Money.zero, (s, p) => s + p.value);
  Money get net => positiveTotal + negativeTotal;
}

final class _Change {
  _Change(this.date, this.apply);
  final String date;
  final void Function() apply;
}

/// Valuation at each historical close: never uses a future quote or FX rate.
/// Values are null when a nonzero position cannot be valued completely.
final class AnalyticsService {
  AssetComposition composition(
    LedgerSnapshot data,
    AssetScope scope, {
    String? through,
  }) {
    final groups = <String, Money>{};
    var missing = 0;
    void add(String label, Money value) => groups.update(
      '${value.isNegative ? '-' : '+'}:$label',
      (v) => v + value,
      ifAbsent: () => value,
    );
    if (scope != AssetScope.investment) {
      for (final a in data.accounts) {
        final balance = data.balanceAt(a.id, through: through);
        if (balance.isZero) continue;
        final fx = _latestRate(data, a.currency, through);
        if (fx == null) {
          missing++;
          continue;
        }
        add(
          scope == AssetScope.combined ? accountLabel(a.kind) : a.name,
          fx.timesMoney(balance),
        );
      }
    }
    if (scope != AssetScope.cash) {
      final holdings = buildHoldings(
        data.extras.events
            .where((e) => through == null || e.date.compareTo(through) <= 0)
            .toList(),
      );
      for (final h in holdings.where((h) => h.quantity.positive)) {
        final i = data.extras.instruments.firstWhere(
          (i) => i.id == h.instrumentId,
        );
        final q = _quote(
          data.extras.allQuotes.where(
            (q) =>
                !q.isLive &&
                q.instrumentId == i.id &&
                (through == null || q.date.compareTo(through) <= 0),
          ),
        );
        final fx = q == null ? null : _latestRate(data, q.currency, through);
        if (q == null || fx == null) {
          missing++;
          continue;
        }
        final label = scope == AssetScope.combined
            ? switch (i.kind) {
                InstrumentKind.stock => 'Saham',
                InstrumentKind.crypto => 'Crypto',
                InstrumentKind.fund => 'Reksa dana',
              }
            : '${i.code} · ${i.displayName}';
        final day =
            through ??
            localDate(DateTime.now().toUtc().add(const Duration(hours: 7)));
        add(
          label,
          (h.quantity * priceAtLedgerUnits(q, data.extras.events, day) * fx)
              .money(),
        );
      }
    }
    final rows =
        groups.entries
            .map((e) => AssetSlice(e.key.substring(2), e.value))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return AssetComposition(
      positive: rows.where((r) => r.value.isPositive).toList(),
      negative: rows.where((r) => r.value.isNegative).toList(),
      missing: missing,
    );
  }

  Decimal? _latestRate(LedgerSnapshot data, String currency, String? through) {
    if (currency == 'IDR') return Decimal.one;
    if (through == null) return data.extras.rate(currency);
    final candidates = <FxRate>[
      for (final t in data.transactions.where(
        (t) =>
            t.idrRate != null &&
            data.accounts.firstWhere((a) => a.id == t.accountId).currency ==
                currency,
      ))
        FxRate(currency: currency, rate: t.idrRate!, date: t.date),
      for (final e in data.extras.events.where(
        (e) =>
            data.accounts.firstWhere((a) => a.id == e.accountId).currency ==
            currency,
      ))
        FxRate(currency: currency, rate: e.idrRate, date: e.date),
      ...data.extras.rateHistory,
      ...data.extras.rates,
    ];
    FxRate? latest;
    for (final f in candidates.where(
      (f) => f.currency == currency && f.date.compareTo(through) <= 0,
    )) {
      if (latest == null || f.date.compareTo(latest.date) >= 0) latest = f;
    }
    return latest?.rate;
  }

  PriceQuote? _quote(Iterable<PriceQuote> rows) {
    PriceQuote? latest;
    for (final q in rows) {
      if (latest == null || comparePriceQuotes(q, latest) < 0) {
        latest = q;
      }
    }
    return latest;
  }

  List<AnalyticsPoint> history(
    LedgerSnapshot data,
    DateTime now, {
    int? days = 30,
    int maxPoints = 366,
  }) {
    if (maxPoints < 2 || (days != null && days < 1)) {
      throw ArgumentError('Invalid chart range.');
    }
    final today = localDate(now.toUtc().add(const Duration(hours: 7)));
    final end = DateTime.parse(today);
    final starts = <String, String>{
      for (final a in data.accounts)
        a.id: localDate(
          DateTime.parse(a.createdAt).toUtc().add(const Duration(hours: 7)),
        ),
    };
    void accountStart(String id, String date) {
      if (date.compareTo(starts[id]!) < 0) starts[id] = date;
    }

    for (final t in data.transactions) {
      accountStart(t.accountId, t.date);
      if (t.destinationId != null) accountStart(t.destinationId!, t.date);
    }
    for (final e in data.extras.events) {
      accountStart(e.accountId, e.date);
      if (e.destinationId != null) accountStart(e.destinationId!, e.date);
    }
    final ruleAccounts = {
      for (final r in data.extras.interestRules) r.id: r.accountId,
    };
    for (final p in data.extras.interestPostings) {
      accountStart(ruleAccounts[p.ruleId]!, p.date);
    }
    var earliest = today;
    for (final d in starts.values) {
      if (d.compareTo(earliest) < 0) earliest = d;
    }
    final start = days == null
        ? DateTime.parse(earliest)
        : end.subtract(Duration(days: days));
    final span = end.difference(start).inDays;
    final stride = ((span + 1) / maxPoints).ceil().clamp(1, 100000);
    final sampleDates = <String>[];
    for (var d = 0; d <= span; d += stride) {
      sampleDates.add(localDate(start.add(Duration(days: d))));
    }
    if (sampleDates.isEmpty || sampleDates.last != today) {
      sampleDates.add(today);
    }
    final balances = <String, Money>{};
    final quotes = <String, PriceQuote>{};
    final fx = <String, Decimal>{'IDR': Decimal.one};
    final replay = PortfolioReplay();
    final changes = <_Change>[];
    void delta(String id, Money value) =>
        balances.update(id, (v) => v + value, ifAbsent: () => value);
    var income = Money.zero, expense = Money.zero;
    void flow(String date, Money inc, Money exp) {
      if (date.compareTo(localDate(start)) >= 0) {
        income = income + inc;
        expense = expense + exp;
      }
    }

    for (final a in data.accounts) {
      changes.add(_Change(starts[a.id]!, () => delta(a.id, a.opening)));
    }
    for (final t in data.transactions) {
      final a = data.accounts.firstWhere((a) => a.id == t.accountId);
      changes.add(
        _Change(t.date, () {
          delta(t.accountId, t.deltaFor(t.accountId));
          if (t.destinationId != null) {
            delta(t.destinationId!, t.deltaFor(t.destinationId!));
          }
          if (t.idrRate != null) fx[a.currency] = t.idrRate!;
          final rate = t.idrRate ?? Decimal.one;
          if (t.receiverFeeRate != null && t.destinationId != null) {
            fx[data.accounts
                    .firstWhere((a) => a.id == t.destinationId)
                    .currency] =
                t.receiverFeeRate!;
          }
          flow(
            t.date,
            t.kind == TransactionKind.income
                ? rate.timesMoney(t.amount)
                : Money.zero,
            t.expenseIdr,
          );
        }),
      );
    }
    for (final e in [...data.extras.events]..sort(compareInvestmentEvents)) {
      final a = data.accounts.firstWhere((a) => a.id == e.accountId);
      changes.add(
        _Change(e.date, () {
          replay.apply(e);
          delta(e.accountId, e.cashDelta(e.accountId));
          fx[a.currency] = e.idrRate;
          flow(
            e.date,
            e.kind == InvestmentKind.dividend
                ? e.idrRate.timesMoney(e.gross)
                : Money.zero,
            e.idrRate.timesMoney(e.fee),
          );
        }),
      );
    }
    for (final p in data.extras.interestPostings.where((p) => !p.voided)) {
      final a = data.accounts.firstWhere((a) => a.id == ruleAccounts[p.ruleId]);
      changes.add(
        _Change(p.date, () {
          delta(a.id, p.net);
          fx[a.currency] = p.idrRate;
          flow(
            p.date,
            p.idrRate.timesMoney(p.gross),
            p.idrRate.timesMoney(p.tax),
          );
        }),
      );
    }
    for (final q in data.extras.allQuotes.where((q) => !q.isLive)) {
      changes.add(
        _Change(q.date, () {
          final old = quotes[q.instrumentId];
          if (old == null || comparePriceQuotes(q, old) < 0) {
            quotes[q.instrumentId] = q;
          }
        }),
      );
    }
    for (final r in [...data.extras.rateHistory, ...data.extras.rates]) {
      changes.add(_Change(r.date, () => fx[r.currency] = r.rate));
    }
    // Stable index tie-break preserves investment time/createdAt order and gives
    // explicit daily FX entries priority over same-day transaction anchors.
    final indexed = changes.indexed.toList()
      ..sort((a, b) {
        final c = a.$2.date.compareTo(b.$2.date);
        return c == 0 ? a.$1.compareTo(b.$1) : c;
      });
    final points = <AnalyticsPoint>[];
    var cursor = 0;
    for (final day in sampleDates) {
      while (cursor < indexed.length &&
          indexed[cursor].$2.date.compareTo(day) <= 0) {
        indexed[cursor++].$2.apply();
      }
      var cash = Money.zero,
          invested = Money.zero,
          missingCash = 0,
          missingInvestments = 0;
      for (final a in data.accounts) {
        final balance = balances[a.id] ?? Money.zero;
        if (balance.isZero) continue;
        final rate = fx[a.currency];
        if (rate == null) {
          missingCash++;
        } else {
          cash = cash + rate.timesMoney(balance);
        }
      }
      for (final h in replay.pools.values.where((h) => h.quantity.positive)) {
        final q = quotes[h.instrumentId];
        final rate = q == null ? null : fx[q.currency];
        if (q == null || rate == null) {
          missingInvestments++;
        } else {
          invested =
              invested +
              (h.quantity *
                      priceAtLedgerUnits(q, data.extras.events, day) *
                      rate)
                  .money();
        }
      }
      points.add(
        AnalyticsPoint(
          date: day,
          cash: missingCash == 0 ? cash : null,
          investment: missingInvestments == 0 ? invested : null,
          income: income,
          expense: expense,
          missingCash: missingCash,
          missingInvestments: missingInvestments,
        ),
      );
      income = Money.zero;
      expense = Money.zero;
    }
    return points;
  }
}
