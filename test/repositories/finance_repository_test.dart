import 'dart:io';

import 'package:arta/database/app_database.dart';
import 'package:arta/models/ledger.dart';
import 'package:arta/models/money.dart';
import 'package:arta/repositories/finance_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../fixtures.dart';

void main() {
  late AppDatabase db;
  late FinanceRepository repo;
  bool memoryOpen = false;
  setUp(() {
    db = AppDatabase.memory();
    memoryOpen = true;
    repo = FinanceRepository(db);
  });
  tearDown(() async {
    if (memoryOpen) await db.close();
  });
  test(
    'buat aset, transfer, edit, hapus; saldo dihitung ulang tanpa duplikasi',
    () async {
      await repo.addAccount(account('bank', '1000'));
      await repo.addAccount(account('wallet', '0'));
      await repo.saveTransaction(
        transaction(
          kind: TransactionKind.transfer,
          destination: 'wallet',
          amount: '1200',
          fee: '5',
        ),
      );
      var data = await repo.load();
      expect(data.balance('bank'), Money.input('-205'));
      expect(data.balance('wallet'), Money.input('1200'));
      await repo.saveTransaction(
        transaction(
          kind: TransactionKind.transfer,
          destination: 'wallet',
          amount: '300',
          fee: '2',
        ),
        edit: true,
      );
      data = await repo.load();
      expect(data.transactions, hasLength(1));
      expect(data.balance('bank'), Money.input('698'));
      expect(data.balance('wallet'), Money.input('300'));
      await repo.deleteTransaction('tx');
      data = await repo.load();
      expect(data.balance('bank'), Money.input('1000'));
      expect(data.balance('wallet'), Money.zero);
    },
  );
  test('referensi aset salah tidak menyimpan separuh transfer', () async {
    await repo.addAccount(account('bank', '1000'));
    await expectLater(
      repo.saveTransaction(
        transaction(kind: TransactionKind.transfer, destination: 'missing'),
      ),
      throwsFormatException,
    );
    final data = await repo.load();
    expect(data.transactions, isEmpty);
    expect(data.balance('bank'), Money.input('1000'));
  });
  test('restore gagal di tengah SQL mengembalikan seluruh data lama', () async {
    await repo.addAccount(account('bank', '-100'));
    await repo.setTheme('light');
    await db.customStatement(
      "CREATE TRIGGER fail_restore BEFORE INSERT ON ledger_transactions BEGIN SELECT RAISE(ABORT, 'test failure'); END",
    );
    final imported = LedgerSnapshot(
      accounts: [account('new-bank', '900')],
      transactions: [transaction(source: 'new-bank')],
    );
    await expectLater(repo.replace(imported), throwsA(isA<Exception>()));
    final data = await repo.load();
    expect(data.accounts.single.id, 'bank');
    expect(data.balance('bank'), Money.input('-100'));
    expect(data.theme, 'light');
  });
  test('restore valid menjaga ID, nilai, urutan dan tema', () async {
    final imported = LedgerSnapshot(
      accounts: [account('bank', '-10'), account('wallet', '0')],
      transactions: [
        transaction(id: 'second', amount: '3'),
        transaction(id: 'first', amount: '2'),
      ],
      theme: 'system',
    );
    await repo.replace(imported);
    final data = await repo.load();
    expect(data.transactions.map((t) => t.id), ['second', 'first']);
    expect(data.balance('bank'), Money.input('-15'));
    expect(data.theme, 'system');
  });
  test('data tetap ada setelah file SQLite ditutup dan dibuka ulang', () async {
    await db.close();
    memoryOpen = false;
    final directory = await Directory.systemTemp.createTemp(
      'arta-persistence-',
    );
    final file = File(p.join(directory.path, 'test.sqlite'));
    var disk = AppDatabase.file(file);
    try {
      await FinanceRepository(disk)
          .addAccount(account('bank', '99999999999999999999,99'));
      await FinanceRepository(disk).setAmountsHidden(true);
      await disk.close();
      disk = AppDatabase.file(file);
      final data = await FinanceRepository(disk).load();
      expect(await FinanceRepository(disk).amountsHidden(), isTrue);
      expect(
        data.accounts.single.opening,
        Money.input('99999999999999999999,99'),
      );
    } finally {
      await disk.close();
      await directory.delete(recursive: true);
    }
  });
}
