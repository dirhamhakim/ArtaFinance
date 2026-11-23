import 'dart:async';

import 'package:arta/services/app_lock_service.dart';

class FakeLockService implements AppLockService {
  FakeLockService({
    this.enabled = false,
    this.available = true,
    this.preferBiometric = true,
  });
  bool enabled, available, preferBiometric;
  bool biometricResult = false, broken = false;
  int retry = 0, pinCalls = 0, invalidations = 0;
  String expectedPin = '123456';
  Completer<PinResult>? pendingPin;
  Completer<bool>? pendingBiometric;
  Completer<LockStatus>? pendingConfiguration;
  @override
  Future<LockStatus> status() async {
    if (broken) throw StateError('unavailable');
    return LockStatus(
      enabled: enabled,
      available: available,
      biometric: preferBiometric,
      retry: retry,
    );
  }

  @override
  Future<LockStatus> configure(String pin, bool biometric) async {
    if (pendingConfiguration != null) return pendingConfiguration!.future;
    expectedPin = pin;
    enabled = true;
    preferBiometric = biometric;
    return status();
  }

  @override
  Future<LockStatus> disable() async {
    enabled = false;
    return status();
  }

  @override
  Future<PinResult> verifyPin(String pin) async {
    pinCalls++;
    if (pendingPin != null) return pendingPin!.future;
    return PinResult(pin == expectedPin, retry);
  }

  @override
  Future<bool> authenticateBiometric() async =>
      pendingBiometric?.future ?? biometricResult;
  @override
  Future<void> invalidateSession() async {
    invalidations++;
  }
}
