import 'dart:async';

import 'package:arta/controllers/app_lock_controller.dart';
import 'package:arta/services/app_lock_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_lock_service.dart';

void main() {
  test(
    'instalasi baru tidak terkunci; aktivasi opsional dan PIN dapat membuka',
    () async {
      final service = FakeLockService();
      final lock = AppLockController(service);
      addTearDown(lock.dispose);
      await lock.initialize();
      expect(lock.locked, isFalse);
      expect(await lock.configure('654321', true), isTrue);
      expect(lock.useBiometric, isTrue);
      lock.lock();
      expect(await lock.pin('111111'), isFalse);
      expect(lock.locked, isTrue);
      expect(await lock.pin('654321'), isTrue);
      expect(lock.locked, isFalse);
    },
  );
  test(
    'biometrik batal tidak membuka; biometrik berhasil dapat membuka',
    () async {
      final service = FakeLockService(enabled: true);
      final lock = AppLockController(service);
      addTearDown(lock.dispose);
      await lock.initialize();
      expect(await lock.biometric(), isFalse);
      expect(lock.locked, isTrue);
      service.biometricResult = true;
      expect(await lock.biometric(), isTrue);
      expect(lock.locked, isFalse);
    },
  );
  test('jeda PIN bertahan saat inisialisasi dan tidak hilang karena biometrik batal', () async {
    var now = DateTime.utc(2026, 11, 19);
    final service = FakeLockService(enabled: true)..retry = 30;
    final lock = AppLockController(service, clock: () => now);
    addTearDown(lock.dispose);
    await lock.initialize();
    expect(await lock.pin('123456'), isFalse);
    expect(service.pinCalls, 0);
    await lock.biometric();
    expect(lock.retrySeconds, 30);
    now = now.add(const Duration(seconds: 30));
    service.retry = 0;
    expect(lock.retrySeconds, 0);
    expect(await lock.pin('123456'), isTrue);
  });
  test('hasil PIN terlambat setelah background tidak membuka sesi', () async {
    final service = FakeLockService(enabled: true)
      ..pendingPin = Completer<PinResult>();
    final lock = AppLockController(service);
    addTearDown(lock.dispose);
    await lock.initialize();
    final attempt = lock.pin('123456');
    lock.background();
    service.pendingPin!.complete(const PinResult(true, 0));
    expect(await attempt, isFalse);
    expect(lock.locked, isTrue);
    lock.resumed();
    expect(lock.locked, isTrue);
    expect(service.invalidations, greaterThan(0));
  });
  test(
    'aktivasi yang selesai di latar belakang tetap meminta buka kunci',
    () async {
      final service = FakeLockService()
        ..pendingConfiguration = Completer<LockStatus>();
      final lock = AppLockController(service);
      addTearDown(lock.dispose);
      await lock.initialize();
      final save = lock.configure('123456', true);
      lock.background();
      service.pendingConfiguration!.complete(
        const LockStatus(enabled: true, biometric: true, available: true),
      );
      expect(await save, isTrue);
      expect(lock.locked, isTrue);
    },
  );
  test('mengubah keamanan memerlukan autentikasi ulang; error penyimpanan gagal tertutup', () async {
    final service = FakeLockService(enabled: true);
    final lock = AppLockController(service);
    addTearDown(lock.dispose);
    await lock.initialize();
    await lock.pin('123456');
    final authorize = lock.authorizeChange();
    expect(lock.locked, isTrue);
    expect(await lock.configure('222222', true), isFalse);
    await lock.pin('123456');
    expect(await authorize, isTrue);
    expect(await lock.disable(), isTrue);
    service.broken = true;
    await lock.initialize();
    expect(lock.locked, isTrue);
    expect(lock.error, isNotNull);
  });
}
