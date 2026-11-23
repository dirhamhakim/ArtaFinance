import '../models/decimal.dart';
import '../models/ledger.dart';
import '../models/money.dart';
import '../models/interest.dart';

final class InterestEngine {
  /// Daily accrual in minor currency units with twelve extra decimal places.
  static Decimal daily(InterestRule rule, Money balance) {
    if (balance.isNegative || balance.isZero) return Decimal.zero;
    var weighted = BigInt.zero;
    if (rule.progressive) {
      for (var n = 0; n < rule.tiers.length; n++) {
        final t = rule.tiers[n];
        if (balance.compareTo(t.from) <= 0) break;
        final upper = n + 1 == rule.tiers.length
            ? balance
            : rule.tiers[n + 1].from.compareTo(balance) < 0
            ? rule.tiers[n + 1].from
            : balance;
        weighted += (upper - t.from).minor * t.percent.raw;
      }
    } else {
      final t = rule.tiers.lastWhere((t) => balance.compareTo(t.from) >= 0);
      weighted = balance.minor * t.percent.raw;
    }
    return Decimal(roundRatio(weighted, BigInt.from(100 * rule.daysBasis)));
  }

  static List<InterestPosting> pending(
    LedgerSnapshot data,
    DateTime now, {
    bool automaticOnly = false,
    int maxPerRule = 3660,
  }) {
    final today = localDate(now.toUtc().add(const Duration(hours: 7)));
    final last = DateTime.parse('${today}T00:00:00Z')
        .subtract(const Duration(days: 1));
    final posts = <InterestPosting>[];
    for (final r in data.extras.interestRules.where(
      (r) => r.active && (!automaticOnly || r.automatic),
    )) {
      final account = data.accounts.firstWhere((a) => a.id == r.accountId);
      final fx = data.extras.rate(account.currency);
      if (fx == null) continue;
      var day = DateTime.parse('${r.start}T00:00:00Z');
      final resolved =
          data.extras.interestPostings.where((p) => p.ruleId == r.id).toList()
            ..sort((a, b) => a.start.compareTo(b.start));
      for (final p in resolved) {
        if (p.start == localDate(day)) {
          day = DateTime.parse('${p.end}T00:00:00Z')
              .add(const Duration(days: 1));
        } else if (p.start.compareTo(localDate(day)) > 0) {
          break;
        }
      }
      var end = last;
      if (r.end != null && DateTime.parse('${r.end}T00:00:00Z').isBefore(end)) {
        end = DateTime.parse('${r.end}T00:00:00Z');
      }
      var added = 0;
      while (!day.isAfter(end) && added < maxPerRule) {
        final periodStart = day;
        var periodEnd = r.monthly
            ? DateTime.utc(day.year, day.month + 1, 0)
            : day;
        if (r.end != null &&
            periodEnd.isAfter(DateTime.parse('${r.end}T00:00:00Z'))) {
          periodEnd = DateTime.parse('${r.end}T00:00:00Z');
        }
        if (periodEnd.isAfter(end)) break;
        final startText = localDate(periodStart),
            endText = localDate(periodEnd);
        final id = '${r.id}:$startText:$endText';
        if (!data.extras.interestPostings.any((v) => v.id == id)) {
          var accrual = Decimal.zero;
          for (
            var d = day;
            !d.isAfter(periodEnd);
            d = d.add(const Duration(days: 1))
          ) {
            final balanceDate = r.previousClosing
                ? d.subtract(const Duration(days: 1))
                : d;
            accrual =
                accrual +
                daily(
                  r,
                  data.balanceAt(r.accountId, through: localDate(balanceDate)),
                );
          }
          final gross = Money(roundRatio(accrual.raw, Decimal.scale));
          final tax = Money(
            roundRatio(
              gross.minor * r.taxPercent.raw,
              Decimal.scale * BigInt.from(100),
            ),
          );
          posts.add(
            InterestPosting(
              ruleId: r.id,
              start: startText,
              end: endText,
              date: endText,
              gross: gross,
              tax: tax,
              idrRate: fx,
            ),
          );
          added++;
        }
        day = periodEnd.add(const Duration(days: 1));
      }
    }
    posts.sort((a, b) => a.end.compareTo(b.end));
    return posts;
  }
}
