import '../models/ledger.dart';
import '../models/money.dart';
import '../models/schedule.dart';

final class PendingOccurrence {
  const PendingOccurrence(this.rule, this.ordinal, this.date);
  final ScheduleRule rule;
  final int ordinal;
  final String date;
  Money get amount => rule.amountAt(ordinal);
  bool isDue(DateTime now) {
    final day = date.compareTo(rule.today(now));
    if (day != 0) return day < 0;
    return rule.time == null ||
        rule.time!.compareTo(
              localTime(
                now.toUtc().add(Duration(hours: scheduleZones[rule.zone]!)),
              ),
            ) <=
            0;
  }
}

abstract final class ScheduleEngine {
  static Iterable<PendingOccurrence> pending(
    ScheduleRule rule,
    Iterable<ScheduleOccurrence> history, {
    String? through,
    int limit = 100,
  }) sync* {
    final resolved = history
        .where((o) => o.scheduleId == rule.id)
        .map((o) => o.ordinal)
        .toSet();
    var emitted = 0;
    for (var ordinal = 0; ; ordinal++) {
      final date = rule.dateAt(ordinal);
      if (date == null || (through != null && date.compareTo(through) > 0)) {
        return;
      }
      if (resolved.contains(ordinal)) continue;
      yield PendingOccurrence(rule, ordinal, date);
      if (++emitted >= limit) return;
    }
  }

  static List<PendingOccurrence> due(
    LedgerSnapshot data,
    DateTime now, {
    int limit = 100,
  }) {
    final result = <PendingOccurrence>[];
    for (final rule in data.schedules.where(
      (s) => s.state == ScheduleState.active,
    )) {
      result.addAll(
        pending(
          rule,
          data.occurrences,
          through: rule.today(now),
          limit: limit,
        ).where((item) => item.isDue(now)),
      );
    }
    result.sort((a, b) {
      final date = a.date.compareTo(b.date);
      return date != 0 ? date : a.rule.id.compareTo(b.rule.id);
    });
    return result.take(limit).toList();
  }
}
