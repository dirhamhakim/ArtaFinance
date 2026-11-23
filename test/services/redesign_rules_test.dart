import 'package:arta/models/decimal.dart';
import 'package:arta/models/ledger.dart';
import 'package:arta/models/money.dart';
import 'package:arta/models/recurrence_option.dart';
import 'package:arta/models/schedule.dart';
import 'package:arta/services/analytics_service.dart';
import 'package:arta/services/backup_service.dart';
import 'package:arta/database/app_database.dart';
import 'package:arta/repositories/finance_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures.dart';

void main() {
  test('automatic scheduled transfer posts both fees once and restore retains daily price preference', () async {
    final db = AppDatabase.memory();
    final repo = FinanceRepository(db);
    addTearDown(db.close);
    await repo.addAccount(account('bank', '1000'));
    await repo.addAccount(account('wallet', '0'));
    final rule = ScheduleRule.fromJson({
      ...schedule(
        kind: TransactionKind.transfer,
        destination: 'wallet',
        amount: '100',
        fee: '5',
        start: '2026-11-19',
        mode: ScheduleMode.automatic,
      ).toJson(),
      'receiver_fee_minor': '200',
    });
    await repo.saveSchedule(rule, processAt: DateTime.utc(2026, 11, 19, 12));
    await repo.processAutomatic(DateTime.utc(2026, 11, 19, 12));
    var data = await repo.load();
    expect(data.transactions, hasLength(1));
    expect(data.balance('bank'), Money.input('895'));
    expect(data.balance('wallet'), Money.input('98'));
    await repo.setPreference('market_daily_auto', 'false');
    final restored = await BackupService().decode(BackupService().encode(data));
    await repo.replace(restored);
    data = await repo.load();
    expect(data.schedules.single.receivingFee, Money.input('2'));
    expect(data.total, Money.input('993'));
    expect(await repo.preference('market_daily_auto'), 'false');
  });
  test('sender and receiver fees affect balances and expenses exactly once; backup round trips', () async {
    final tx = LedgerTransaction.fromJson({
      ...transaction(
        kind: TransactionKind.transfer,
        destination: 'wallet',
        amount: '100',
        fee: '5',
      ).toJson(),
      'receiver_fee_minor': '200',
    });
    final data = LedgerSnapshot(
      accounts: [account('bank', '1000'), account('wallet', '0')],
      transactions: [tx],
    );
    expect(data.balance('bank'), Money.input('895'));
    expect(data.balance('wallet'), Money.input('98'));
    expect(data.expenseForMonth('2026-11'), Money.input('7'));
    expect(data.incomeForMonth('2026-11'), Money.zero);
    expect(data.total, Money.input('993'));
    final restored = await BackupService().decode(BackupService().encode(data));
    expect(restored.transactions.single.receivingFee, Money.input('2'));
    expect(restored.total, data.total);
    final history = AnalyticsService().history(
      data,
      DateTime.utc(2026, 11, 20),
      days: 2,
    );
    expect(history.fold(Money.zero, (s, p) => s + p.expense), Money.input('7'));
  });
  test(
    'receiver fee uses its own currency rate for a cross currency transfer',
    () {
      final tx = LedgerTransaction(
        id: 'fx',
        kind: TransactionKind.transfer,
        accountId: 'idr',
        destinationId: 'usd',
        amount: Money.input('160000'),
        destinationAmount: Money.input('10'),
        fee: Money.input('1000'),
        receiverFee: Money.input('0,50'),
        receiverFeeRate: Decimal.parse('16000'),
        idrRate: Decimal.one,
        date: '2026-11-19',
        category: '',
        note: '',
        createdAt: '2026-11-19T00:00:00Z',
      );
      tx.validate();
      expect(tx.deltaFor('usd'), Money.input('9,50'));
      expect(tx.expenseIdr, Money.input('9000'));
    },
  );
  test('receiver fee cannot consume the transfer or be used on an expense', () {
    expect(
      () => LedgerTransaction.fromJson({
        ...transaction(
          kind: TransactionKind.transfer,
          destination: 'wallet',
          amount: '100',
        ).toJson(),
        'receiver_fee_minor': '10000',
      }),
      throwsFormatException,
    );
    expect(
      () => LedgerTransaction.fromJson({
        ...transaction().toJson(),
        'receiver_fee_minor': '100',
      }),
      throwsFormatException,
    );
  });
  test('weekday recurrence handles a partial first week and remains stable by ordinal', () {
    final rule = ScheduleRule.fromJson({
      ...schedule(
        start: '2026-11-18',
        frequency: RepeatFrequency.daily,
      ).toJson(),
      'weekdays': [1, 3, 5],
    });
    expect(
      [for (var i = 0; i < 7; i++) rule.dateAt(i)],
      [
        '2026-11-18',
        '2026-11-20',
        '2026-11-23',
        '2026-11-25',
        '2026-11-27',
        '2026-11-30',
        '2026-12-02',
      ],
    );
    expect(
      ScheduleRule.fromJson(rule.toJson()).dateAt(1000),
      rule.dateAt(1000),
    );
    expect(
      () => ScheduleRule.fromJson({
        ...rule.toJson(),
        'weekdays': [1, 1],
      }),
      throwsFormatException,
    );
  });
  test(
    '12 choices retain four-week, monthly anchor and leap year semantics',
    () {
      expect(RecurrenceOption.values, hasLength(12));
      final four = schedule(
        start: '2026-01-31',
        frequency: RepeatFrequency.weekly,
        interval: 4,
      );
      expect(four.dateAt(1), '2026-02-28');
      expect(four.dateAt(2), '2026-03-28');
      final month = schedule(start: '2026-01-31');
      expect(month.dateAt(1), '2026-02-28');
      expect(month.dateAt(2), '2026-03-31');
      final year = schedule(
        start: '2024-02-29',
        frequency: RepeatFrequency.yearly,
      );
      expect(year.dateAt(1), '2025-02-28');
      expect(year.dateAt(4), '2028-02-29');
    },
  );
}
