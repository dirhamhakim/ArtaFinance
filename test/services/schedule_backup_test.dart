import 'dart:convert';
import 'dart:typed_data';

import 'package:arta/models/ledger.dart';
import 'package:arta/models/schedule.dart';
import 'package:arta/services/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures.dart';

Uint8List bytes(Map<String, Object?> data) =>
    Uint8List.fromList(utf8.encode(jsonEncode(data)));
void main() {
  final service = BackupService();
  test('backup v1 diterima dengan jadwal kosong dan saldo lama utuh', () async {
    final restored = await service.decode(
      bytes({
        'format': 'arta-backup',
        'schema_version': 1,
        'created_at': '2026-11-19T00:00:00Z',
        'accounts': [account('bank', '-100').toJson()],
        'transactions': [transaction().toJson()],
        'preferences': {'theme': 'light'},
      }),
    );
    expect(restored.schedules, isEmpty);
    expect(restored.occurrences, isEmpty);
    expect(restored.balance('bank').input, '-200');
    expect(restored.theme, 'light');
  });
  test('backup terbaru menjaga seluruh kolom jadwal dan riwayat termasuk yang dilewati', () async {
    final data = LedgerSnapshot(
      accounts: [account('bank', '0')],
      transactions: [],
      schedules: [
        schedule(count: 3, installments: true, zone: 'Asia/Makassar'),
      ],
      occurrences: [
        const ScheduleOccurrence(
          scheduleId: 'rule',
          ordinal: 0,
          dueDate: '2026-01-31',
          state: OccurrenceState.skipped,
          resolvedAt: '2026-02-01T00:00:00Z',
        ),
      ],
    );
    final encoded = service.encode(data);
    expect(
      (jsonDecode(utf8.decode(encoded))
          as Map<String, Object?>)['schema_version'],
      6,
    );
    final restored = await importBackupInBackground(encoded);
    expect(restored.schedules.single.toJson(), data.schedules.single.toJson());
    expect(
      restored.occurrences.single.toJson(),
      data.occurrences.single.toJson(),
    );
  });
  test(
    'riwayat hilang, duplikat, atau tanggal salah ditolak sebelum restore',
    () async {
      final occurrence = const ScheduleOccurrence(
        scheduleId: 'rule',
        ordinal: 0,
        dueDate: '2026-01-31',
        state: OccurrenceState.skipped,
        resolvedAt: '2026-02-01T00:00:00Z',
      ).toJson();
      final data = LedgerSnapshot(
        accounts: [account('bank', '0')],
        transactions: [],
        schedules: [schedule()],
      );
      for (final mutate in <void Function(Map<String, Object?>)>[
        (j) => j.remove('occurrences'),
        (j) => j['occurrences'] = [occurrence, occurrence],
        (j) => j['occurrences'] = [
          {...occurrence, 'due_date': '2026-01-30'},
        ],
        (j) => j['schedules'] = [
          {...schedule().toJson(), 'interval': 0},
        ],
        (j) => j['schedules'] = [],
      ]) {
        final json = jsonDecode(
          utf8.decode(service.encode(data)),
        ) as Map<String, Object?>;
        // Default a valid history; mutations must break it in a meaningful way.
        json['occurrences'] = [occurrence];
        mutate(json);
        await expectLater(service.decode(bytes(json)), throwsFormatException);
      }
    },
  );
}
