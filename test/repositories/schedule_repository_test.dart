import 'dart:convert';
import 'dart:io';

import 'package:arta/controllers/finance_controller.dart';
import 'package:arta/database/app_database.dart';
import 'package:arta/models/ledger.dart';
import 'package:arta/models/money.dart';
import 'package:arta/models/schedule.dart';
import 'package:arta/repositories/finance_repository.dart';
import 'package:arta/services/backup_service.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../fixtures.dart';

void main() {
  late AppDatabase db;
  late FinanceRepository repo;
  bool memoryOpen = false;
  setUp(() async {
    db = AppDatabase.memory();
    memoryOpen = true;
    repo = FinanceRepository(db);
    await repo.addAccount(account('bank', '0'));
  });
  tearDown(() async {
    if (memoryOpen) await db.close();
  });
  test(
    'dua aturan Mandiri catch-up bulanan termasuk Februari tanpa duplikasi',
    () async {
      await repo.saveSchedule(
        schedule(
          id: 'day4',
          start: '2024-01-04',
          amount: '5500',
          mode: ScheduleMode.automatic,
        ),
      );
      await repo.saveSchedule(
        schedule(
          id: 'eom',
          start: '2024-01-04',
          endOfMonth: true,
          mode: ScheduleMode.automatic,
        ),
      );
      final now = DateTime.utc(2024, 3, 31, 10);
      await repo.processAutomatic(now);
      await repo.processAutomatic(now);
      final data = await repo.load();
      expect(data.transactions, hasLength(6));
      expect(data.occurrences, hasLength(6));
      expect(data.balance('bank'), Money.input('-34500'));
      expect(data.transactions.map((t) => t.date).toSet(), {
        '2024-01-04',
        '2024-01-31',
        '2024-02-04',
        '2024-02-29',
        '2024-03-04',
        '2024-03-31',
      });
    },
  );
  test('dua permintaan bersamaan hanya menghasilkan satu transaksi', () async {
    await repo.saveSchedule(schedule(start: '2026-11-04'));
    final now = DateTime.utc(2026, 11, 19);
    final results = await Future.wait([
      repo.resolveOccurrence('rule', 0, now),
      repo.resolveOccurrence('rule', 0, now),
    ]);
    expect(results.where((v) => v), hasLength(1));
    final data = await repo.load();
    expect(data.transactions, hasLength(1));
    expect(data.occurrences, hasLength(1));
  });
  test(
    'konfirmasi, perubahan satu kejadian, transfer dan fee boleh saldo minus',
    () async {
      await repo.addAccount(account('wallet', '0'));
      await repo.saveSchedule(
        schedule(
          kind: TransactionKind.transfer,
          destination: 'wallet',
          amount: '100',
          fee: '5',
          start: '2026-11-04',
        ),
      );
      final now = DateTime.utc(2026, 11, 19);
      await repo.processAutomatic(now);
      expect((await repo.load()).transactions, isEmpty);
      await repo.resolveOccurrence(
        'rule',
        0,
        now,
        amount: Money.input('150'),
        fee: Money.input('2'),
        date: '2026-11-18',
        note: 'Aktual',
      );
      expect(await repo.resolveOccurrence('rule', 0, now), false);
      final data = await repo.load();
      expect(data.balance('bank'), Money.input('-152'));
      expect(data.balance('wallet'), Money.input('150'));
      expect(data.total, Money.input('-2'));
      expect(data.occurrences.single.dueDate, '2026-11-04');
      expect(data.transactions.single.date, '2026-11-18');
      expect(data.transactions.single.note, 'Aktual');
      expect(data.schedules.single.amount, Money.input('100'));
    },
  );
  test('hapus transaksi, backup dan restore mempertahankan tombstone anti duplikasi', () async {
    final now = DateTime.utc(2026, 11, 19);
    await repo.saveSchedule(
      schedule(start: '2026-11-04', mode: ScheduleMode.automatic),
      processAt: now,
    );
    var data = await repo.load();
    await repo.deleteTransaction(data.transactions.single.id);
    data = await repo.load();
    expect(data.occurrences.single.state, OccurrenceState.deleted);
    expect(data.occurrences.single.transactionId, isNull);
    final service = BackupService();
    await repo.replace(
      await service.decode(service.encode(data)),
      processAt: now,
    );
    await repo.processAutomatic(now);
    data = await repo.load();
    expect(data.transactions, isEmpty);
    expect(data.balance('bank'), Money.zero);
    expect(data.occurrences.single.state, OccurrenceState.deleted);
  });
  test('lewati, jeda dan lanjut tanpa backlog sebelum hari ini', () async {
    await repo.saveSchedule(
      schedule(start: '2026-01-04', mode: ScheduleMode.automatic),
    );
    await repo.resolveOccurrence(
      'rule',
      0,
      DateTime.utc(2026, 1, 4),
      skip: true,
    );
    await repo.setScheduleState(
      'rule',
      ScheduleState.paused,
      DateTime.utc(2026, 1, 5),
    );
    await repo.processAutomatic(DateTime.utc(2026, 3, 4));
    expect((await repo.load()).transactions, isEmpty);
    await repo.setScheduleState(
      'rule',
      ScheduleState.active,
      DateTime.utc(2026, 3, 4),
      skipMissed: true,
    );
    final data = await repo.load();
    expect(data.transactions.map((t) => t.date), ['2026-03-04']);
    expect(data.occurrences.map((o) => o.state), [
      OccurrenceState.skipped,
      OccurrenceState.skipped,
      OccurrenceState.posted,
    ]);
  });
  test(
    'ubah mendatang mengarsipkan aturan lama tanpa menulis ulang riwayat',
    () async {
      final now = DateTime.utc(2026, 2, 1);
      await repo.saveSchedule(
        schedule(mode: ScheduleMode.automatic),
        processAt: now,
      );
      await repo.saveSchedule(
        schedule(
          id: 'new',
          start: '2026-02-28',
          amount: '7000',
          mode: ScheduleMode.automatic,
        ),
        replacesId: 'rule',
        replacesResolvedCount: 1,
        processAt: now,
      );
      await repo.processAutomatic(DateTime.utc(2026, 3, 31));
      final data = await repo.load();
      expect(data.schedules.first.state, ScheduleState.stopped);
      expect(data.transactions, hasLength(3));
      expect(data.balance('bank'), Money.input('-20000'));
      expect(
        data.occurrences.where((o) => o.scheduleId == 'rule'),
        hasLength(1),
      );
      await expectLater(
        repo.saveSchedule(
          schedule(id: 'stale'),
          replacesId: 'new',
          replacesResolvedCount: 0,
        ),
        throwsFormatException,
      );
      expect((await repo.load()).schedules, hasLength(2));
    },
  );
  test(
    'SQL gagal pada kejadian membatalkan jadwal dan transaksi sekaligus',
    () async {
      await db.customStatement(
        "CREATE TRIGGER fail_occurrence BEFORE INSERT ON schedule_occurrences BEGIN SELECT RAISE(ABORT, 'test failure'); END",
      );
      await expectLater(
        repo.saveSchedule(
          schedule(mode: ScheduleMode.automatic),
          processAt: DateTime.utc(2026, 2, 1),
        ),
        throwsA(isA<Exception>()),
      );
      var data = await repo.load();
      expect(data.schedules, isEmpty);
      expect(data.transactions, isEmpty);
      expect(data.occurrences, isEmpty);
      await repo.saveSchedule(schedule());
      await expectLater(
        repo.resolveOccurrence('rule', 0, DateTime.utc(2026, 2, 1)),
        throwsA(isA<Exception>()),
      );
      data = await repo.load();
      expect(data.transactions, isEmpty);
      expect(data.occurrences, isEmpty);
    },
  );
  test(
    'cicilan hanya membukukan setiap bagian; total persis dan selesai',
    () async {
      await repo.saveSchedule(
        schedule(
          start: '2026-01-31',
          amount: '100',
          count: 3,
          installments: true,
          mode: ScheduleMode.automatic,
        ),
      );
      final controller = FinanceController(
        repo,
        clock: () => DateTime.utc(2026, 6, 1),
      );
      try {
        await controller.initialize();
        await controller.initialize();
        expect(controller.snapshot.transactions, hasLength(3));
        expect(controller.snapshot.balance('bank'), Money.input('-100'));
        expect(controller.due, isEmpty);
      } finally {
        controller.dispose();
      }
    },
  );
  test('restore gagal di riwayat mengembalikan aset, jadwal, ledger dan preferensi lama', () async {
    await repo.saveSchedule(
      schedule(id: 'old', start: '2026-11-04', mode: ScheduleMode.automatic),
      processAt: DateTime.utc(2026, 11, 19),
    );
    await repo.setTheme('light');
    final before = await repo.load();
    await db.customStatement(
      "CREATE TRIGGER fail_history BEFORE INSERT ON schedule_occurrences BEGIN SELECT RAISE(ABORT, 'test failure'); END",
    );
    final service = BackupService();
    await expectLater(
      repo.replace(await service.decode(service.encode(before))),
      throwsA(isA<Exception>()),
    );
    final after = await repo.load();
    expect(after.theme, 'light');
    expect(
      after.transactions.single.toJson(),
      before.transactions.single.toJson(),
    );
    expect(after.schedules.single.toJson(), before.schedules.single.toJson());
    expect(
      after.occurrences.single.toJson(),
      before.occurrences.single.toJson(),
    );
  });
  for (final oldVersion in [1, 2, 3, 4]) {
    test('migrasi file SQLite v$oldVersion ke v5 menjaga data lama', () async {
      await db.close();
      memoryOpen = false;
      final directory = await Directory.systemTemp.createTemp(
        'arta-migration-',
      );
      final file = File(p.join(directory.path, 'test.sqlite'));
      final legacy = _LegacyDatabase(NativeDatabase(file), version: oldVersion);
      await legacy.customStatement(
        'INSERT INTO accounts(id,body) VALUES (?, ?)',
        ['bank', jsonEncode(account('bank', '-1').toJson())],
      );
      await legacy.customStatement(
        'INSERT INTO ledger_transactions(id,account_id,date,body) VALUES (?, ?, ?, ?)',
        ['tx', 'bank', '2026-11-19', jsonEncode(transaction().toJson())],
      );
      await legacy.customStatement(
        "INSERT INTO preferences(key,value) VALUES ('theme','light')",
      );
      await legacy.close();
      final upgraded = AppDatabase.file(file);
      try {
        final repository = FinanceRepository(upgraded);
        final data = await repository.load();
        expect(data.balance('bank'), Money.input('-101'));
        expect(data.theme, 'light');
        expect(data.schedules, isEmpty);
        expect(data.occurrences, isEmpty);
        expect(data.cards, isEmpty);
        expect(data.transactions.single.time, isNull);
        await repository.saveSchedule(schedule());
        expect((await repository.load()).schedules, hasLength(1));
        final version = await upgraded
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(version.read<int>('user_version'), 5);
        expect(
          await upgraded.customSelect('SELECT * FROM market_benchmarks').get(),
          isEmpty,
        );
      } finally {
        await upgraded.close();
        await directory.delete(recursive: true);
      }
    });
  }
}

final class _LegacyDatabase extends GeneratedDatabase {
  _LegacyDatabase(super.executor, {this.version = 1});
  final int version;
  @override
  int get schemaVersion => version;
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => const [];
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) async {
      await customStatement(
        'CREATE TABLE accounts (id TEXT PRIMARY KEY, body TEXT NOT NULL)',
      );
      await customStatement(
        'CREATE TABLE ledger_transactions (id TEXT PRIMARY KEY,account_id TEXT NOT NULL REFERENCES accounts(id),destination_id TEXT REFERENCES accounts(id),date TEXT NOT NULL,body TEXT NOT NULL)',
      );
      await customStatement(
        'CREATE INDEX tx_date ON ledger_transactions(date)',
      );
      await customStatement(
        'CREATE TABLE preferences (key TEXT PRIMARY KEY,value TEXT NOT NULL)',
      );
      if (version >= 2) {
        await customStatement(
          'CREATE TABLE schedules (id TEXT PRIMARY KEY, body TEXT NOT NULL)',
        );
        await customStatement(
          'CREATE TABLE schedule_occurrences (schedule_id TEXT NOT NULL REFERENCES schedules(id), ordinal INTEGER NOT NULL CHECK (ordinal >= 0), transaction_id TEXT UNIQUE REFERENCES ledger_transactions(id), body TEXT NOT NULL, PRIMARY KEY (schedule_id, ordinal))',
        );
      }
      if (version >= 3) {
        await customStatement(
          'CREATE TABLE payment_cards (id TEXT PRIMARY KEY, body TEXT NOT NULL)',
        );
      }
      if (version >= 4) {
        await customStatement(
          'CREATE TABLE finance_extras(id TEXT PRIMARY KEY,body TEXT NOT NULL)',
        );
      }
    },
  );
}
