import 'package:arta/models/ledger.dart';
import 'package:arta/models/money.dart';
import 'package:arta/models/schedule.dart';
import 'package:arta/services/schedule_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures.dart';

void main() {
  test(
    'tanggal pengulangan tersimpan terpisah dari mulai yang jatuh di Februari',
    () {
      for (final day in [29, 30, 31]) {
        final rule = schedule(start: '2025-02-28', monthDay: day);
        rule.validate();
        expect(rule.dateAt(0), '2025-02-28');
        expect(rule.dateAt(1), '2025-03-$day');
        final restored = ScheduleRule.fromJson(rule.toJson());
        expect(restored.monthDay, day);
        expect(restored.dateAt(1), '2025-03-$day');
      }
      expect(
        () => schedule(start: '2026-03-20', monthDay: 4).validate(),
        throwsFormatException,
      );
      final annual = schedule(
        start: '2025-02-28',
        monthDay: 29,
        frequency: RepeatFrequency.yearly,
      );
      annual.validate();
      expect(annual.dateAt(0), '2025-02-28');
      expect(annual.dateAt(3), '2028-02-29');
    },
  );
  test(
    'pengeluaran aktual cicilan mengikuti jenis transaksi setelah koreksi',
    () {
      final rule = schedule(amount: '300', count: 3, installments: true);
      for (final kind in TransactionKind.values) {
        final tx = transaction(
          kind: kind,
          destination: kind == TransactionKind.transfer ? 'wallet' : null,
          amount: '100',
          fee: kind == TransactionKind.transfer ? '2' : '0',
        );
        final data = LedgerSnapshot(
          accounts: [account('bank', '0'), account('wallet', '0')],
          transactions: [tx],
          schedules: [rule],
          occurrences: [
            const ScheduleOccurrence(
              scheduleId: 'rule',
              ordinal: 0,
              dueDate: '2026-01-31',
              state: OccurrenceState.posted,
              transactionId: 'tx',
              resolvedAt: '2026-02-01T00:00:00Z',
            ),
          ],
        );
        data.validate();
        expect(data.actualExpenseForSchedule('rule'), switch (kind) {
          TransactionKind.expense => Money.input('100'),
          TransactionKind.transfer => Money.input('2'),
          TransactionKind.income => Money.zero,
        });
        expect(data.remainingForSchedule(rule), Money.input('200'));
      }
    },
  );
  test('tanggal asal 29–31 dan tahun kabisat tidak bergeser permanen', () {
    for (final day in [29, 30, 31]) {
      final rule = schedule(start: '2024-01-$day');
      expect(
        [for (var i = 0; i < 3; i++) rule.dateAt(i)],
        ['2024-01-$day', '2024-02-29', '2024-03-$day'],
      );
    }
    final rule = schedule(start: '2025-01-31');
    expect(
      [for (var i = 0; i < 4; i++) rule.dateAt(i)],
      ['2025-01-31', '2025-02-28', '2025-03-31', '2025-04-30'],
    );
  });
  test('akhir bulan mengikuti kalender dan tidak digeser akhir pekan', () {
    final rule = schedule(start: '2024-01-04', endOfMonth: true);
    expect(
      [for (var i = 0; i < 4; i++) rule.dateAt(i)],
      ['2024-01-31', '2024-02-29', '2024-03-31', '2024-04-30'],
    );
    expect(
      schedule(start: '2025-02-04', endOfMonth: true).dateAt(0),
      '2025-02-28',
    );
  });
  test(
    'interval, batas jumlah, tanggal akhir inklusif dan kalender tahunan',
    () {
      final rule = schedule(start: '2026-01-31', interval: 2, count: 3);
      expect(
        [for (var i = 0; i < 4; i++) rule.dateAt(i)],
        ['2026-01-31', '2026-03-31', '2026-05-31', null],
      );
      expect(
        schedule(start: '2026-01-31', end: '2026-02-28').dateAt(1),
        '2026-02-28',
      );
      expect(
        schedule(start: '2026-01-31', end: '2026-02-28').dateAt(2),
        isNull,
      );
      final yearly = schedule(
        start: '2024-02-29',
        frequency: RepeatFrequency.yearly,
      );
      expect(yearly.dateAt(1), '2025-02-28');
      expect(yearly.dateAt(4), '2028-02-29');
      expect(
        schedule(
          start: '2026-12-28',
          frequency: RepeatFrequency.weekly,
          interval: 2,
        ).dateAt(1),
        '2027-01-11',
      );
      expect(
        schedule(
          start: '2026-12-31',
          frequency: RepeatFrequency.daily,
        ).dateAt(1),
        '2027-01-01',
      );
      expect(yearly.dateAt(110000), isNull);
    },
  );
  test(
    'cicilan BigInt menjumlah persis total; pembulatan di bagian terakhir',
    () {
      for (final amount in ['100', '100,01', '999999999999999999999999,99']) {
        final rule = schedule(amount: amount, count: 3, installments: true);
        rule.validate();
        final sum = [
          0,
          1,
          2,
        ].fold(Money.zero, (total, i) => total + rule.amountAt(i));
        expect(sum, Money.input(amount));
      }
      final rule = schedule(amount: '100', count: 3, installments: true);
      expect(
        [for (var i = 0; i < 3; i++) rule.amountAt(i).input],
        ['33,33', '33,33', '33,34'],
      );
      expect(
        () => schedule(amount: '0,02', count: 3, installments: true).validate(),
        throwsFormatException,
      );
      expect(
        () => schedule(count: 1, installments: true).validate(),
        throwsFormatException,
      );
    },
  );
  test('tanggal jatuh tempo memakai zona jadwal, bukan zona perangkat', () {
    final now = DateTime.parse('2026-11-03T16:30:00Z');
    final wib = schedule(start: '2026-11-04');
    final wit = schedule(id: 'wit', start: '2026-11-04', zone: 'Asia/Jayapura');
    expect(wib.today(now), '2026-11-03');
    expect(wit.today(now), '2026-11-04');
    final data = LedgerSnapshot(
      accounts: [account('bank', '0')],
      transactions: [],
      schedules: [wib, wit],
    );
    expect(ScheduleEngine.due(data, now).map((p) => p.rule.id), ['wit']);
  });
  test('riwayat dilewati tidak muncul lagi; rencana tidak mengubah saldo', () {
    final rule = schedule(count: 3);
    final history = [
      ScheduleOccurrence(
        scheduleId: rule.id,
        ordinal: 0,
        dueDate: '2026-01-31',
        state: OccurrenceState.skipped,
        resolvedAt: '2026-02-01T00:00:00Z',
      ),
    ];
    final data = LedgerSnapshot(
      accounts: [account('bank', '-1')],
      transactions: [],
      schedules: [rule],
      occurrences: history,
    );
    data.validate();
    expect(ScheduleEngine.pending(rule, history).map((p) => p.date), [
      '2026-02-28',
      '2026-03-31',
    ]);
    expect(
      ScheduleEngine.due(data, DateTime.utc(2026, 2, 28)).map((p) => p.ordinal),
      [1],
    );
    expect(data.balance('bank'), Money.input('-1'));
  });
  test('backup dengan identitas, urutan, tanggal, atau tautan kejadian salah ditolak', () {
    final rule = schedule();
    for (final occurrence in [
      ScheduleOccurrence(
        scheduleId: 'missing',
        ordinal: 0,
        dueDate: '2026-01-31',
        state: OccurrenceState.skipped,
        resolvedAt: '2026-02-01T00:00:00Z',
      ),
      ScheduleOccurrence(
        scheduleId: rule.id,
        ordinal: 0,
        dueDate: '2026-02-01',
        state: OccurrenceState.skipped,
        resolvedAt: '2026-02-01T00:00:00Z',
      ),
      ScheduleOccurrence(
        scheduleId: rule.id,
        ordinal: 0,
        dueDate: '2026-01-31',
        state: OccurrenceState.posted,
        transactionId: 'missing',
        resolvedAt: '2026-02-01T00:00:00Z',
      ),
    ]) {
      expect(
        () => LedgerSnapshot(
          accounts: [account('bank', '0')],
          transactions: [],
          schedules: [rule],
          occurrences: [occurrence],
        ).validate(),
        throwsFormatException,
      );
    }
  });
}
