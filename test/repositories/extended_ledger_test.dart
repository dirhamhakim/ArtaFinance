import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:arta/database/app_database.dart';
import 'package:arta/models/ledger.dart';
import 'package:arta/models/money.dart';
import 'package:arta/models/payment_card.dart';
import 'package:arta/models/receipt_image.dart';
import 'package:arta/models/schedule.dart';
import 'package:arta/repositories/finance_repository.dart';
import 'package:arta/services/backup_service.dart';
import 'package:arta/services/schedule_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures.dart';

ReceiptImage receipt() => ReceiptImage.fromJson({
  'id': 'photo',
  'mime': 'image/jpeg',
  'data': base64Encode(File('test/fixtures/receipt.jpg').readAsBytesSync()),
});
PaymentCard card(String source) => PaymentCard(
  id: 'debit',
  name: 'Debit Jago Syariah',
  accountId: source,
  createdAt: '2026-11-19T00:00:00Z',
);

void main() {
  late AppDatabase db;
  late FinanceRepository repo;
  setUp(() async {
    db = AppDatabase.memory();
    repo = FinanceRepository(db);
    await repo.addAccount(account('bank', '1000'));
    await repo.addAccount(account('pocket', '100'));
  });
  tearDown(() => db.close());

  test('kartu tidak menambah saldo dan relink tidak mengubah sumber transaksi lama', () async {
    await repo.saveCard(card('bank'));
    expect((await repo.load()).total, Money.input('1100'));
    final tx = LedgerTransaction.fromJson({
      ...transaction(amount: '50').toJson(),
      'card_id': 'debit',
      'time': '23:59',
      'zone': 'Asia/Jakarta',
    });
    await repo.saveTransaction(tx);
    await repo.saveCard(card('pocket'));
    await repo.saveTransaction(
      LedgerTransaction.fromJson({...tx.toJson(), 'note': 'Koreksi catatan'}),
      edit: true,
    );
    final data = await repo.load();
    expect(data.balance('bank'), Money.input('950'));
    expect(data.balance('pocket'), Money.input('100'));
    expect(data.transactions.single.accountId, 'bank');
    expect(data.total, Money.input('1050'));
    await expectLater(
      repo.saveTransaction(
        LedgerTransaction.fromJson({...tx.toJson(), 'id': 'wrong-new'}),
      ),
      throwsFormatException,
    );
    await repo.saveTransaction(
      LedgerTransaction.fromJson({
        ...tx.toJson(),
        'id': 'new',
        'account_id': 'pocket',
      }),
    );
    expect((await repo.load()).balance('pocket'), Money.input('50'));
  });

  test(
    'backup v3 menjaga foto, jam, kartu dan sumber historis setelah restore',
    () async {
      await repo.saveCard(card('bank'));
      final tx = LedgerTransaction.fromJson({
        ...transaction(amount: '30').toJson(),
        'time': '00:05',
        'zone': 'Asia/Makassar',
        'card_id': 'debit',
        'images': [receipt().toJson()],
      });
      await repo.saveTransaction(tx);
      await repo.saveCard(card('pocket'));
      final bytes = BackupService().encode(await repo.load());
      final snapshot = await BackupService().decode(bytes);
      await repo.replace(snapshot);
      final restored = await repo.load();
      expect(restored.cards.single.accountId, 'pocket');
      expect(restored.transactions.single.toJson(), tx.toJson());
      expect(restored.transactions.single.images.single.bytes, receipt().bytes);
      expect(restored.total, Money.input('1070'));
    },
  );

  test(
    'backup v2 dan transaksi lama tetap tanpa jam; waktu 24 jam divalidasi',
    () async {
      final data = {
        'format': 'arta-backup',
        'schema_version': 2,
        'created_at': '2026-11-19T00:00:00Z',
        'accounts': [account('bank', '1000').toJson()],
        'transactions': [transaction().toJson()],
        'preferences': {'theme': 'dark'},
        'schedules': <Object?>[],
        'occurrences': <Object?>[],
      };
      final old = await BackupService().decode(
        Uint8List.fromList(utf8.encode(jsonEncode(data))),
      );
      expect(old.transactions.single.time, isNull);
      expect(old.cards, isEmpty);
      for (final time in ['24:00', '12:60', '9:05', '11:30 PM']) {
        expect(
          () => LedgerTransaction.fromJson({
            ...transaction().toJson(),
            'time': time,
          }),
          throwsFormatException,
        );
      }
      for (final time in ['00:00', '12:00', '23:59']) {
        expect(
          LedgerTransaction.fromJson({...transaction().toJson(), 'time': time})
              .time,
          time,
        );
      }
    },
  );

  test(
    'jam jadwal mengikuti zona dan diproses tepat sekali setelah waktunya',
    () async {
      final rule = ScheduleRule.fromJson({
        ...schedule(
          start: '2026-11-19',
          zone: 'Asia/Makassar',
          mode: ScheduleMode.automatic,
        ).toJson(),
        'time': '09:30',
      });
      await repo.saveSchedule(rule);
      final before = DateTime.utc(2026, 11, 19, 1, 29);
      expect(ScheduleEngine.due(await repo.load(), before), isEmpty);
      await repo.processAutomatic(before);
      expect((await repo.load()).transactions, isEmpty);
      final after = before.add(const Duration(minutes: 1));
      await repo.processAutomatic(after);
      await repo.processAutomatic(after);
      final tx = (await repo.load()).transactions.single;
      expect(tx.time, '09:30');
      expect(tx.zone, 'Asia/Makassar');
      expect(tx.date, '2026-11-19');
    },
  );

  test('lampiran rusak, berlebihan dan referensi kartu hilang ditolak', () {
    expect(
      () => ReceiptImage.fromJson({
        'id': 'bad',
        'mime': 'image/jpeg',
        'data': base64Encode([255, 216, 255, 217]),
      }),
      throwsFormatException,
    );
    expect(
      () => LedgerTransaction.fromJson({
        ...transaction().toJson(),
        'images': List.generate(4, (_) => receipt().toJson()),
      }),
      throwsFormatException,
    );
    expect(
      () => LedgerSnapshot(
        accounts: [account('bank', '100')],
        transactions: [
          LedgerTransaction.fromJson({
            ...transaction().toJson(),
            'card_id': 'missing',
          }),
        ],
      ).validate(),
      throwsFormatException,
    );
  });

  test(
    'urutan transaksi bertanggal sama mengikuti jam, jam lama tidak dikarang',
    () async {
      for (final time in ['18:00', '08:00', null]) {
        await repo.saveTransaction(
          LedgerTransaction.fromJson({
            ...transaction(id: 'tx-${time ?? 'old'}').toJson(),
            'time': ?time,
          }),
        );
      }
      expect((await repo.load()).transactions.map((t) => t.time), [
        '18:00',
        '08:00',
        null,
      ]);
    },
  );
}
