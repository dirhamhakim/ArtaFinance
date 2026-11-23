import 'dart:convert';
import 'dart:typed_data';

import 'package:arta/models/ledger.dart';
import 'package:arta/services/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures.dart';

void main() {
  final service = BackupService();
  final data = LedgerSnapshot(
    accounts: [account('bank', '-1000'), account('wallet', '0')],
    transactions: [
      transaction(
        kind: TransactionKind.transfer,
        destination: 'wallet',
        amount: '123,45',
        fee: '0,50',
      ),
    ],
    theme: 'light',
  );
  test('JSON round trip menjaga seluruh kolom dan saldo negatif', () async {
    final bytes = service.encode(data);
    expect(service.isEncrypted(bytes), false);
    final restored = await service.decode(bytes);
    expect(
      restored.accounts.map((v) => v.toJson()),
      data.accounts.map((v) => v.toJson()),
    );
    expect(
      restored.transactions.map((v) => v.toJson()),
      data.transactions.map((v) => v.toJson()),
    );
    expect(restored.theme, 'light');
    expect(restored.balance('bank'), data.balance('bank'));
  });
  test('pemrosesan background mengembalikan snapshot lengkap', () async {
    final bytes = await exportBackupInBackground(data);
    expect(await backupIsEncryptedInBackground(bytes), false);
    final restored = await importBackupInBackground(bytes);
    expect(restored.total, data.total);
    expect(restored.theme, data.theme);
  });
  test(
    'file rusak, versi baru, ID duplikat, dan relasi hilang ditolak',
    () async {
      await expectLater(
        service.decode(Uint8List.fromList(utf8.encode('{oops'))),
        throwsFormatException,
      );
      for (final mutate in <void Function(Map<String, Object?>)>[
        (j) => j['schema_version'] = 999,
        (j) => j['unknown_future_feature'] = [],
        (j) => j['accounts'] = [
          data.accounts.first.toJson(),
          data.accounts.first.toJson(),
        ],
        (j) => j['accounts'] = [],
        (j) => j['preferences'] = {'theme': 'broken'},
      ]) {
        final json = jsonDecode(
          utf8.decode(service.encode(data)),
        ) as Map<String, Object?>;
        mutate(json);
        await expectLater(
          service.decode(Uint8List.fromList(utf8.encode(jsonEncode(json)))),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'AES-GCM round trip; kata sandi salah dan ciphertext berubah ditolak',
    () async {
      final encrypted = await service.encrypt(
        service.encode(data),
        'test-password-123',
      );
      expect(service.isEncrypted(encrypted), true);
      final restored = await service.decode(
        encrypted,
        password: 'test-password-123',
      );
      expect(restored.balance('bank'), data.balance('bank'));
      await expectLater(
        service.decode(encrypted, password: 'wrong-password'),
        throwsFormatException,
      );
      final json = jsonDecode(utf8.decode(encrypted)) as Map<String, Object?>;
      final ciphertext = base64Decode(json['ciphertext']! as String);
      ciphertext[0] ^= 1;
      json['ciphertext'] = base64Encode(ciphertext);
      await expectLater(
        service.decode(
          Uint8List.fromList(utf8.encode(jsonEncode(json))),
          password: 'test-password-123',
        ),
        throwsFormatException,
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
