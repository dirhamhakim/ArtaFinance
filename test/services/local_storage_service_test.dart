import 'dart:io';

import 'package:arta/database/app_database.dart';
import 'package:arta/models/money.dart';
import 'package:arta/repositories/finance_repository.dart';
import 'package:arta/services/local_storage_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('id.arta.arta/storage');
  late Directory temporary;
  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('arta-startup-');
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await temporary.delete(recursive: true);
  });
  test(
    'provider berhasil memakai direktori persisten tanpa meminta fallback',
    () async {
      var nativeCalls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            nativeCalls++;
            return temporary.path;
          });
      final directory = Directory(p.join(temporary.path, 'files'));
      final file = await LocalStorageService(
        android: true,
        directoryProvider: () async => directory,
      ).databaseFile();
      expect(file.path, p.join(directory.path, 'arta.sqlite'));
      expect(await directory.exists(), true);
      expect(nativeCalls, 0);
    },
  );
  test(
    'provider gagal, filesDir membuka database lama pada lokasi sama',
    () async {
      final original = File(p.join(temporary.path, 'arta.sqlite'));
      var db = AppDatabase.file(original);
      await FinanceRepository(db).addAccount(account('bank', '-1000'));
      await FinanceRepository(db).saveTransaction(transaction(amount: '100'));
      await db.close();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'getApplicationSupportDirectory');
            return temporary.path;
          });
      final file = await LocalStorageService(
        android: true,
        directoryProvider: () async => throw StateError('JNI unavailable'),
      ).databaseFile();
      expect(file.path, original.path);
      db = AppDatabase.file(file);
      try {
        final data = await FinanceRepository(db).load();
        expect(data.accounts.single.id, 'bank');
        expect(data.transactions.single.id, 'tx');
        expect(data.balance('bank'), Money.input('-1100'));
      } finally {
        await db.close();
      }
    },
  );
  test(
    'dua kegagalan tersimpan pada rincian dan tidak memilih lokasi sementara',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (call) async =>
                throw PlatformException(code: 'STORAGE_DIRECTORY_UNAVAILABLE'),
          );
      await expectLater(
        LocalStorageService(
          android: true,
          directoryProvider: () async => throw StateError('original failure'),
        ).databaseFile(),
        throwsA(
          isA<LocalStorageException>().having(
            (e) => e.toString(),
            'details',
            allOf(
              contains('original failure'),
              contains('STORAGE_DIRECTORY_UNAVAILABLE'),
            ),
          ),
        ),
      );
      expect(await temporary.list().toList(), isEmpty);
    },
  );
  test(
    'hasil native kosong atau relatif ditolak tanpa membuat database',
    () async {
      for (final path in <String?>[null, '', 'relative-files']) {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async => path);
        await expectLater(
          LocalStorageService(
            android: true,
            directoryProvider: () async => throw MissingPluginException(),
          ).databaseFile(),
          throwsA(isA<LocalStorageException>()),
        );
      }
    },
  );
  test('platform selain Android mempertahankan error provider asli', () async {
    await expectLater(
      LocalStorageService(
        android: false,
        directoryProvider: () async => throw StateError('not android'),
      ).databaseFile(),
      throwsA(isA<StateError>()),
    );
  });
}
