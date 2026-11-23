import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// SQL eksplisit melalui Drift; nominal disimpan sebagai TEXT agar tidak overflow.
final class AppDatabase extends GeneratedDatabase {
  AppDatabase(super.executor);
  factory AppDatabase.file(File file) =>
      AppDatabase(NativeDatabase.createInBackground(file));
  factory AppDatabase.memory() => AppDatabase(NativeDatabase.memory());
  @override
  int get schemaVersion => 5;
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
        '''CREATE TABLE ledger_transactions (
        id TEXT PRIMARY KEY, account_id TEXT NOT NULL REFERENCES accounts(id),
        destination_id TEXT REFERENCES accounts(id), date TEXT NOT NULL, body TEXT NOT NULL)''',
      );
      await customStatement(
        'CREATE INDEX tx_date ON ledger_transactions(date)',
      );
      await customStatement(
        'CREATE TABLE preferences (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
      );
      await _createSchedules();
      await _createCards();
      await _createExtras();
      await _createMarketHistory();
    },
    onUpgrade: (_, from, to) async {
      if (from < 2) await _createSchedules();
      if (from < 3) await _createCards();
      if (from < 4) await _createExtras();
      if (from < 5) await _createMarketHistory();
    },
    beforeOpen: (_) async => customStatement('PRAGMA foreign_keys = ON'),
  );

  Future<void> _createExtras() => customStatement(
    'CREATE TABLE finance_extras (id TEXT PRIMARY KEY, body TEXT NOT NULL)',
  );

  Future<void> _createMarketHistory() => customStatement(
    'CREATE TABLE market_benchmarks (symbol TEXT NOT NULL, date TEXT NOT NULL, price TEXT NOT NULL, fetched_at TEXT NOT NULL, PRIMARY KEY(symbol,date)) WITHOUT ROWID',
  );

  Future<void> _createCards() => customStatement(
    'CREATE TABLE payment_cards (id TEXT PRIMARY KEY, body TEXT NOT NULL)',
  );

  Future<void> _createSchedules() async {
    await customStatement('''CREATE TABLE schedules (
      id TEXT PRIMARY KEY, body TEXT NOT NULL)''');
    await customStatement('''CREATE TABLE schedule_occurrences (
      schedule_id TEXT NOT NULL REFERENCES schedules(id),
      ordinal INTEGER NOT NULL CHECK (ordinal >= 0),
      transaction_id TEXT UNIQUE REFERENCES ledger_transactions(id),
      body TEXT NOT NULL, PRIMARY KEY (schedule_id, ordinal))''');
  }
}
