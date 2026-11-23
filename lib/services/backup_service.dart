import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../models/ledger.dart';
import '../models/schedule.dart';
import '../models/payment_card.dart';
import '../models/finance_extras.dart';

/// JSON besar dan derivasi kunci berjalan di isolate agar animasi UI tetap hidup.
Future<Uint8List> exportBackupInBackground(
  LedgerSnapshot snapshot, {
  String? password,
}) => Isolate.run(() async {
  final service = BackupService();
  final bytes = service.encode(snapshot);
  return password == null ? bytes : service.encrypt(bytes, password);
});
Future<LedgerSnapshot> importBackupInBackground(
  Uint8List bytes, {
  String? password,
}) => Isolate.run(() => BackupService().decode(bytes, password: password));
Future<bool> backupIsEncryptedInBackground(Uint8List bytes) =>
    Isolate.run(() => BackupService().isEncrypted(bytes));

final class BackupService {
  static const maxBytes = 25 * 1024 * 1024;
  static const iterations = 600000;
  static const _format = 'arta-backup';
  final _cipher = AesGcm.with256bits();
  final _kdf = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: iterations,
    bits: 256,
  );

  Uint8List encode(LedgerSnapshot snapshot) {
    snapshot.validate();
    return _checked(
      Uint8List.fromList(
        utf8.encode(
          jsonEncode({
            'format': _format,
            'schema_version': 6,
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'accounts': snapshot.accounts.map((a) => a.toJson()).toList(),
            'transactions': snapshot.transactions
                .map((t) => t.toJson())
                .toList(),
            'preferences': {'theme': snapshot.theme},
            'schedules': snapshot.schedules.map((s) => s.toJson()).toList(),
            'occurrences': snapshot.occurrences.map((o) => o.toJson()).toList(),
            'cards': snapshot.cards.map((v) => v.toJson()).toList(),
            'extras': snapshot.extras.toJson(),
          }),
        ),
      ),
    );
  }

  bool isEncrypted(Uint8List bytes) =>
      _read(bytes)['format'] == 'arta-encrypted';

  Future<Uint8List> encrypt(Uint8List plaintext, String password) async {
    if (password.length < 8) {
      throw const FormatException('Kata sandi minimal 8 karakter.');
    }
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final key = await _kdf.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
    final box = await _cipher.encrypt(plaintext, secretKey: key);
    return _checked(
      Uint8List.fromList(
        utf8.encode(
          jsonEncode({
            'format': 'arta-encrypted',
            'schema_version': 1,
            'algorithm': 'AES-256-GCM/PBKDF2-HMAC-SHA256',
            'iterations': iterations,
            'salt': base64Encode(salt),
            'nonce': base64Encode(box.nonce),
            'mac': base64Encode(box.mac.bytes),
            'ciphertext': base64Encode(box.cipherText),
          }),
        ),
      ),
    );
  }

  Future<LedgerSnapshot> decode(Uint8List bytes, {String? password}) async {
    var json = _read(bytes);
    if (json['format'] == 'arta-encrypted') {
      exactKeys(json, {
        'format',
        'schema_version',
        'algorithm',
        'iterations',
        'salt',
        'nonce',
        'mac',
        'ciphertext',
      });
      if (json['schema_version'] != 1 ||
          json['iterations'] != iterations ||
          json['algorithm'] != 'AES-256-GCM/PBKDF2-HMAC-SHA256') {
        throw const FormatException('Versi enkripsi belum didukung.');
      }
      if (password == null) {
        throw const FormatException('Kata sandi diperlukan.');
      }
      final salt = base64Decode(stringField(json, 'salt'));
      final nonce = base64Decode(stringField(json, 'nonce'));
      final mac = base64Decode(stringField(json, 'mac'));
      if (salt.length != 16 || nonce.length != 12 || mac.length != 16) {
        throw const FormatException('Backup terenkripsi rusak.');
      }
      final key = await _kdf.deriveKeyFromPassword(
        password: password,
        nonce: salt,
      );
      try {
        final plain = await _cipher.decrypt(
          SecretBox(
            base64Decode(stringField(json, 'ciphertext')),
            nonce: nonce,
            mac: Mac(mac),
          ),
          secretKey: key,
        );
        json = _read(Uint8List.fromList(plain));
      } on SecretBoxAuthenticationError {
        throw const FormatException('Kata sandi salah atau file backup rusak.');
      }
    }
    final version = json['schema_version'];
    if (json['format'] != _format || !{1, 2, 3, 4, 5, 6}.contains(version)) {
      throw const FormatException('Format atau versi backup belum didukung.');
    }
    exactKeys(json, {
      'format',
      'schema_version',
      'created_at',
      'accounts',
      'transactions',
      'preferences',
      if (version != 1) ...{'schedules', 'occurrences'},
      if (version == 3 || version == 4 || version == 5 || version == 6) 'cards',
      if (version == 4 || version == 5 || version == 6) 'extras',
    });
    if (DateTime.tryParse(stringField(json, 'created_at')) == null) {
      throw const FormatException('Waktu backup tidak valid.');
    }
    final accounts = json['accounts'];
    final transactions = json['transactions'];
    final schedules = version == 1 ? <Object?>[] : json['schedules'];
    final occurrences = version == 1 ? <Object?>[] : json['occurrences'];
    final cards = version == 3 || version == 4 || version == 5 || version == 6
        ? json['cards']
        : <Object?>[];
    if (cards is! List<Object?>) {
      throw const FormatException('Daftar kartu tidak valid.');
    }
    if (accounts is! List<Object?> || transactions is! List<Object?>) {
      throw const FormatException('Daftar aset atau transaksi tidak valid.');
    }
    if (schedules is! List<Object?> || occurrences is! List<Object?>) {
      throw const FormatException('Daftar jadwal atau riwayat tidak valid.');
    }
    final preferences = objectMap(json['preferences']);
    exactKeys(preferences, {'theme'});
    final snapshot = LedgerSnapshot(
      extras: version == 4 || version == 5 || version == 6
          ? FinanceExtras.fromJson(objectMap(json['extras']))
          : const FinanceExtras(),
      cards: cards.map((v) => PaymentCard.fromJson(objectMap(v))).toList(),
      accounts: accounts.map((v) => Account.fromJson(objectMap(v))).toList(),
      transactions: transactions
          .map((v) => LedgerTransaction.fromJson(objectMap(v)))
          .toList(),
      theme: stringField(preferences, 'theme'),
      schedules: schedules
          .map((v) => ScheduleRule.fromJson(objectMap(v)))
          .toList(),
      occurrences: occurrences
          .map((v) => ScheduleOccurrence.fromJson(objectMap(v)))
          .toList(),
    );
    snapshot.validate();
    return snapshot;
  }

  Map<String, Object?> _read(Uint8List bytes) {
    if (bytes.length > maxBytes) {
      throw const FormatException('Ukuran backup maksimal 25 MB.');
    }
    try {
      return objectMap(jsonDecode(utf8.decode(bytes)));
    } on FormatException {
      throw const FormatException('File JSON backup tidak valid.');
    }
  }

  Uint8List _checked(Uint8List bytes) {
    if (bytes.length > maxBytes) {
      throw const FormatException('Ukuran backup maksimal 25 MB.');
    }
    return bytes;
  }
}
