import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:arta/database/app_database.dart';
import 'package:arta/models/ledger.dart';
import 'package:arta/models/transaction_category.dart';
import 'package:arta/repositories/finance_repository.dart';
import 'package:arta/services/backup_service.dart';
import 'package:arta/services/transaction_category_service.dart';
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
    await repo.addAccount(account('bank', '100000'));
  });
  tearDown(() async {
    if (memoryOpen) await db.close();
  });
  const custom = TransactionCategory(
    id: 'custom',
    kind: TransactionKind.expense,
    name: 'Servis kendaraan',
  );

  test(
    'unused categories persist through database reopen and encrypted backup',
    () async {
      await db.close();
      memoryOpen = false;
      final dir = Directory.systemTemp.createTempSync('arta-category-');
      final file = File(p.join(dir.path, 'test.sqlite'));
      final disk = AppDatabase.file(file);
      final diskRepo = FinanceRepository(disk);
      await diskRepo.saveCategory(custom);
      await disk.close();
      final reopened = AppDatabase.file(file);
      late LedgerSnapshot source, restored;
      try {
        source = await FinanceRepository(reopened).load();
        expect(source.transactions, isEmpty);
        expect(
          TransactionCategoryService.options(source, TransactionKind.expense),
          contains(custom.name),
        );
        final codec = BackupService();
        final encrypted = await codec.encrypt(
          codec.encode(source),
          'category-test-password',
        );
        restored = await codec.decode(
          encrypted,
          password: 'category-test-password',
        );
      } finally {
        await reopened.close();
        file.deleteSync();
        dir.deleteSync();
      }
      db = AppDatabase.memory();
      memoryOpen = true;
      repo = FinanceRepository(db);
      await repo.replace(restored);
      expect(
        (await repo.load()).extras.categories!.map((v) => v.toJson()),
        source.extras.categories!.map((v) => v.toJson()),
      );
    },
  );

  test('rename updates only matching kind in transactions and all schedules; financial fields stay exact', () async {
    await repo.saveTransaction(
      transaction(id: 'expense', category: '  Biaya BANK  '),
    );
    await repo.saveTransaction(
      transaction(
        id: 'income',
        category: 'Biaya bank',
        kind: TransactionKind.income,
      ),
    );
    await repo.saveSchedule(schedule());
    await repo.resolveOccurrence('rule', 0, DateTime.utc(2026, 2, 1));
    final before = await repo.load();
    final category = TransactionCategoryService.all(before)
        .firstWhere((v) => v.key == 'expense:biaya bank');
    await repo.saveCategory(
      category.copy(name: 'Administrasi rekening'),
      edit: true,
    );
    final after = await repo.load();
    expect(after.balance('bank'), before.balance('bank'));
    expect(after.schedules.single.toJson(), {
      ...before.schedules.single.toJson(),
      'category': 'Administrasi rekening',
    });
    expect(
      after.occurrences.map((v) => v.toJson()),
      before.occurrences.map((v) => v.toJson()),
    );
    for (final tx in after.transactions) {
      final old = before.transactions.firstWhere((v) => v.id == tx.id);
      expect(tx.toJson(), {
        ...old.toJson(),
        'category': tx.kind == TransactionKind.expense
            ? 'Administrasi rekening'
            : old.category,
      });
    }
    expect(
      TransactionCategoryService.options(after, TransactionKind.expense),
      isNot(contains('Biaya Bank')),
    );
    await repo.resolveOccurrence('rule', 1, DateTime.utc(2026, 3, 1));
    expect(
      (await repo.load()).transactions
          .firstWhere((t) => t.id == 'schedule:rule:1')
          .category,
      'Administrasi rekening',
    );
  });

  test('archive hides defaults and custom names, keeps schedules usable and restores after backup', () async {
    await repo.saveSchedule(schedule());
    final initial = await repo.load();
    final category = TransactionCategoryService.all(initial)
        .firstWhere((v) => v.key == 'expense:biaya bank');
    await repo.saveCategory(category.copy(archived: true), edit: true);
    await repo.resolveOccurrence('rule', 0, DateTime.utc(2026, 2, 1));
    var data = await repo.load();
    expect(data.transactions.single.category.toLowerCase(), 'biaya bank');
    expect(
      TransactionCategoryService.options(
        data,
        TransactionKind.expense,
      ).map((v) => v.toLowerCase()),
      isNot(contains('biaya bank')),
    );
    final codec = BackupService();
    await repo.replace(await codec.decode(codec.encode(data)));
    data = await repo.load();
    expect(
      TransactionCategoryService.isArchived(
        data,
        TransactionKind.expense,
        'BIAYA BANK',
      ),
      isTrue,
    );
    await repo.saveCategory(category, edit: true);
    expect(
      TransactionCategoryService.options(
        await repo.load(),
        TransactionKind.expense,
      ),
      contains(category.name),
    );
  });

  test('duplicates including archives rejected atomically; same name in different kinds allowed', () async {
    await repo.saveCategory(custom.copy(archived: true));
    final before = (await repo.load()).extras.toJson();
    await expectLater(
      repo.saveCategory(
        const TransactionCategory(
          id: 'duplicate',
          kind: TransactionKind.expense,
          name: 'servis kendaraan',
        ),
      ),
      throwsFormatException,
    );
    expect((await repo.load()).extras.toJson(), before);
    await repo.saveCategory(
      const TransactionCategory(
        id: 'other-kind',
        kind: TransactionKind.income,
        name: 'Servis kendaraan',
      ),
    );
    await expectLater(
      repo.saveCategory(
        const TransactionCategory(
          id: 'transfer',
          kind: TransactionKind.transfer,
          name: 'Transfer',
        ),
      ),
      throwsFormatException,
    );
    await expectLater(
      repo.saveCategory(custom.copy(name: '   '), edit: true),
      throwsFormatException,
    );
    await expectLater(
      repo.saveCategory(
        const TransactionCategory(
          id: 'missing',
          kind: TransactionKind.expense,
          name: 'Missing',
        ),
        edit: true,
      ),
      throwsFormatException,
    );
  });

  test('typed category survives deleting its last transaction', () async {
    await repo.saveTransaction(transaction(category: custom.name));
    await repo.deleteTransaction('tx');
    final data = await repo.load();
    expect(data.transactions, isEmpty);
    expect(
      TransactionCategoryService.options(data, TransactionKind.expense),
      contains(custom.name),
    );
  });

  test('old v5 backup without catalog derives defaults and legacy categories; reset clears custom catalog', () async {
    final legacy = LedgerSnapshot(
      accounts: [account('bank', '100000')],
      transactions: [transaction(category: 'Legacy khusus')],
    );
    final codec = BackupService();
    final json = objectMap(jsonDecode(utf8.decode(codec.encode(legacy))));
    json['schema_version'] = 5;
    objectMap(json['extras']).remove('categories');
    await repo.replace(
      await codec.decode(Uint8List.fromList(utf8.encode(jsonEncode(json)))),
    );
    final data = await repo.load();
    expect(
      TransactionCategoryService.options(data, TransactionKind.expense),
      containsAll(['Makan & Minum', 'Legacy khusus']),
    );
    await repo.deleteTransaction('tx');
    expect(
      TransactionCategoryService.options(
        await repo.load(),
        TransactionKind.expense,
      ),
      contains('Legacy khusus'),
    );
    await repo.replace(LedgerSnapshot.empty());
    expect(
      TransactionCategoryService.options(
        await repo.load(),
        TransactionKind.expense,
      ),
      isNot(contains('Legacy khusus')),
    );
  });

  test(
    'malformed or duplicate catalog backup is rejected before replacing data',
    () async {
      await repo.saveCategory(custom);
      final codec = BackupService();
      final json = objectMap(
        jsonDecode(utf8.decode(codec.encode(await repo.load()))),
      );
      final extras = objectMap(json['extras']);
      extras['categories'] = [custom.toJson(), custom.toJson()];
      await expectLater(
        codec.decode(Uint8List.fromList(utf8.encode(jsonEncode(json)))),
        throwsFormatException,
      );
      expect((await repo.load()).accounts, hasLength(1));
    },
  );

  test(
    'SQL error rolls back category rename in both ledger and schedules',
    () async {
      await repo.saveTransaction(transaction(category: custom.name));
      await repo.saveSchedule(schedule(category: custom.name));
      final before = await repo.load();
      final category = TransactionCategoryService.all(before)
          .firstWhere((v) => v.name == custom.name);
      await db.customStatement(
        '''CREATE TEMP TRIGGER reject_category_update
      BEFORE UPDATE ON schedules BEGIN SELECT RAISE(ABORT, 'test failure'); END''',
      );
      await expectLater(
        repo.saveCategory(category.copy(name: 'Nama baru'), edit: true),
        throwsA(anything),
      );
      final after = await repo.load();
      expect(
        after.transactions.map((v) => v.toJson()),
        before.transactions.map((v) => v.toJson()),
      );
      expect(
        after.schedules.map((v) => v.toJson()),
        before.schedules.map((v) => v.toJson()),
      );
      expect(after.extras.toJson(), before.extras.toJson());
    },
  );
}
