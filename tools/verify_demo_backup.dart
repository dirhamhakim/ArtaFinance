// Offline compatibility and financial checks for the deliverable demo JSON.
import 'dart:convert';
import 'dart:io';

import 'package:arta/database/app_database.dart';
import 'package:arta/models/decimal.dart';
import 'package:arta/models/investment.dart';
import 'package:arta/models/ledger.dart';
import 'package:arta/models/money.dart';
import 'package:arta/models/recurrence_option.dart';
import 'package:arta/models/schedule.dart';
import 'package:arta/repositories/finance_repository.dart';
import 'package:arta/services/analytics_service.dart';
import 'package:arta/services/backup_service.dart';
import 'package:arta/services/interest_engine.dart';
import 'package:arta/services/performance_service.dart';

const path = 'Arta-Demo-Lengkap-0.7.0.json';
var checks = 0;
void check(bool value, String label) {
  if (!value) throw StateError(label);
  checks++;
}

Object? canonical(Object? value) {
  if (value is Map<String, Object?>) {
    return {
      for (final k in value.keys.toList()..sort()) k: canonical(value[k]),
    };
  }
  if (value is List<Object?>) {
    return value.map(canonical).toList()
      ..sort((a, b) => jsonEncode(a).compareTo(jsonEncode(b)));
  }
  return value;
}

Future<void> main() async {
  final codec = BackupService();
  final bytes = await File(path).readAsBytes();
  check(!codec.isEncrypted(bytes), 'File must import without a password');
  final original = await codec.decode(bytes);
  original.validate();
  final db = AppDatabase.memory();
  final repo = FinanceRepository(db);
  final now = DateTime.parse('2026-11-21T05:00:00Z');
  try {
    await repo.replace(original, processAt: now);
    var restored = await repo.load();
    final first = objectMap(jsonDecode(utf8.decode(bytes)))
      ..remove('created_at');
    final second = objectMap(jsonDecode(utf8.decode(codec.encode(restored))))
      ..remove('created_at');
    check(
      jsonEncode(canonical(first)) == jsonEncode(canonical(second)),
      'SQLite restore/export must preserve every backed-up value, including image bytes',
    );
    for (final account in original.accounts) {
      check(
        original.balance(account.id) == restored.balance(account.id),
        'Balance ${account.id} changed',
      );
    }
    check(
      restored.accounts.map((a) => a.kind).toSet().length ==
          AccountKind.values.length,
      'All asset classes covered',
    );
    check(
      restored.transactions.map((t) => t.kind).toSet().length ==
          TransactionKind.values.length,
      'All transaction types covered',
    );
    check(
      restored.extras.events.map((e) => e.kind).toSet().length ==
          InvestmentKind.values.length,
      'All investment event types covered',
    );
    check(
      restored.extras.instruments.map((i) => i.kind).toSet().length ==
          InstrumentKind.values.length,
      'All instrument types covered',
    );
    check(
      restored.schedules.map((s) => s.state).toSet().length ==
          ScheduleState.values.length,
      'All schedule states covered',
    );
    check(
      restored.schedules.map((s) => s.mode).toSet().length ==
          ScheduleMode.values.length,
      'All schedule modes covered',
    );
    check(
      restored.occurrences.map((o) => o.state).toSet().length ==
          OccurrenceState.values.length,
      'All occurrence states covered',
    );
    final repeats = restored.schedules
        .map(
          (s) => RecurrenceOption.match(
            s.frequency,
            s.interval,
            s.endOfMonth,
            s.weekdays,
          ),
        )
        .toSet();
    check(
      repeats.containsAll(RecurrenceOption.values),
      'All 12 recurrence options covered',
    );
    check(
      restored.extras.instruments
              .where((i) => i.kind == InstrumentKind.stock)
              .length ==
          944,
      'Full IDX catalog retained',
    );
    check(
      restored.extras.instruments
              .where((i) => i.kind == InstrumentKind.crypto)
              .length ==
          10,
      'All 10 default coins retained',
    );
    check(
      restored.transactions.any(
        (t) => t.destinationAmount != null && t.receiverFeeRate != null,
      ),
      'Cross-currency receiver fee represented',
    );
    check(
      restored.cards.isNotEmpty &&
          restored.transactions.any((t) => t.cardId != null),
      'Historical payment-card reference preserved',
    );
    check(
      restored.transactions.any((t) => t.images.length == 3),
      'Three embedded receipts present',
    );
    check(
      restored.transactions.map((t) => t.zone).toSet().length == 3,
      'All Indonesian time zones represented',
    );
    check(
      restored.extras.quotes.any((q) => q.isLive) &&
          restored.extras.quotes.any((q) => !q.isLive),
      'Close/live caches represented',
    );
    check(
      restored.extras.interestPostings.any((p) => p.voided),
      'Voided interest record preserved',
    );
    check(
      restored.extras.interestRules.any((r) => r.progressive) &&
          restored.extras.interestRules.any((r) => !r.progressive),
      'Both interest tier methods represented',
    );
    check(
      restored.extras.interestRules.any((r) => r.monthly) &&
          restored.extras.interestRules.any((r) => !r.monthly),
      'Daily and monthly interest represented',
    );
    check(
      restored.balance('negative') == Money.input('-175000'),
      'Negative cash balance',
    );
    check(
      restored.balance('liability') == Money.input('-1500000'),
      'Liability repayment must not create income',
    );
    check(
      restored.balance('receivable') == Money.input('1000000'),
      'Receivable collection',
    );
    check(restored.balance('pending') == Money.zero, 'Pending settlement');
    check(
      restored.balance('debit') == Money.input('1970500'),
      'Independent debit pocket without double counting',
    );
    final positions = replayPortfolio(restored.extras.events);
    Holding holding(String account, String instrument) =>
        positions.holdings.singleWhere(
          (h) => h.accountId == account && h.instrumentId == instrument,
        );
    check(
      holding('stockbit', 'idx:BBCA').quantity == Decimal.parse('800'),
      'BBCA purchases expressed in shares',
    );
    check(
      holding('stockbit', 'idx:BBRI').quantity == Decimal.parse('400'),
      'Partial stock sale',
    );
    check(
      holding('metamask', 'cg:ethereum').quantity == Decimal.parse('0.0809'),
      'ETH transfer, reward and slashing',
    );
    check(
      positions.staking['stake-eth']!.pending == Decimal.parse('0.0039'),
      'ETH pending unstake',
    );
    check(
      holding('metamask', 'cg:ethereum').locked == Decimal.parse('0.0449'),
      'Staked principal counted once',
    );
    check(
      holding('tokocrypto', 'cg:solana').quantity == Decimal.parse('3.015'),
      'SOL reward and slashing',
    );
    check(
      positions.staking['stake-hype']!.locked.isZero,
      'Archived staking fully released',
    );
    check(
      holding('bibit', 'fund:demo-split').quantity.isZero,
      'Split followed by full sale',
    );
    check(
      holding('floq', 'cg:ripple').cost == null,
      'Unknown opening basis remains unknown',
    );
    final installment = restored.schedules.singleWhere(
      (s) => s.id == 'installment',
    );
    check(
      restored.remainingForSchedule(installment) == Money.input('1500000,01'),
      'Installment remainder in exact cents',
    );
    final analytics = AnalyticsService();
    final chart = analytics.history(restored, now, days: 173);
    check(
      chart.length > 150 && chart.every((p) => p.combined != null),
      'Six-month charts without missing valuations',
    );
    for (final scope in [
      AssetScope.cash,
      AssetScope.investment,
      AssetScope.combined,
    ]) {
      final composition = analytics.composition(restored, scope);
      check(
        composition.missing == 0 && composition.positive.isNotEmpty,
        'Donut data for ${scope.name}',
      );
    }
    final ihsgRows = jsonDecode(
      utf8.decode(
        gzip.decode(await File('assets/data/ihsg.json.Z').readAsBytes()),
      ),
    ) as List<Object?>;
    final ihsg = [
      for (final raw in ihsgRows)
        if ((raw! as List<Object?>)[0].toString().compareTo('2026-05-31') >= 0)
          PriceQuote(
            instrumentId: 'benchmark:ihsg',
            price: Decimal.parse((raw as List<Object?>)[1]! as String),
            currency: 'IDR',
            date: raw[0]! as String,
            fetchedAt: '2026-11-19T18:11:41Z',
            source: 'Yahoo Finance daily close',
          ),
    ];
    final comparison = PerformanceService().compare(
      restored,
      ihsg,
      now,
      days: 173,
      dividends: true,
    );
    check(
      comparison.points.length > 100 &&
          comparison.points.where((p) => p.portfolio != null).length > 100,
      'IHSG comparison has populated portfolio line',
    );
    check(comparison.issues.isEmpty, 'No benchmark comparison issues');
    check(
      InterestEngine.pending(restored, now, automaticOnly: true).isEmpty,
      'No automatic interest catch-up on import',
    );
    await repo.processAutomatic(DateTime.parse('2027-12-31T05:00:00Z'));
    check(
      (await repo.load()).transactions.length == restored.transactions.length,
      'Automatic demo schedules cannot create unplanned catch-up',
    );
    await repo.replace(original, processAt: now);
    restored = await repo.load();
    check(
      restored.transactions.length == original.transactions.length &&
          restored.extras.events.length == original.extras.events.length,
      'Second import replaces without duplicates',
    );
    await codec.decode(codec.encode(restored));
    final report = {
      'file': path,
      'status': 'PASS',
      'checks': checks,
      'bytes': bytes.length,
      'sqlite_restore_and_reexport': 'all financial fields preserved',
      'chart_points': chart.length,
      'ihsg_comparison_points': comparison.points.length,
      'net_worth': restored.netWorth.formatted,
      'balances': {
        for (final a in restored.accounts) a.name: restored.balance(a.id).input,
      },
      'not_in_financial_backup': [
        'PIN/biometric settings',
        'API keys',
        'device preferences except theme',
        'bundled reference history / IHSG',
      ],
    };
    await File('build/demo-fixture-assets/verification.json')
        .writeAsString(const JsonEncoder.withIndent('  ').convert(report));
    stdout.writeln(jsonEncode(report));
  } finally {
    await db.close();
  }
}
