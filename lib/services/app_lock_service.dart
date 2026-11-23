import 'package:flutter/services.dart';

class LockStatus {
  const LockStatus({
    this.enabled = false,
    this.biometric = false,
    this.available = false,
    this.retry = 0,
  });
  final bool enabled, biometric, available;
  final int retry;
  factory LockStatus.fromMap(Map<Object?, Object?> value) => LockStatus(
    enabled: value['enabled'] as bool,
    biometric: value['biometric'] as bool,
    available: value['available'] as bool,
    retry: value['retry'] as int,
  );
}

class PinResult {
  const PinResult(this.ok, this.retry);
  final bool ok;
  final int retry;
}

abstract class AppLockService {
  Future<LockStatus> status();
  Future<LockStatus> configure(String pin, bool biometric);
  Future<LockStatus> disable();
  Future<PinResult> verifyPin(String pin);
  Future<bool> authenticateBiometric();
  Future<void> invalidateSession();
}

class AndroidAppLockService implements AppLockService {
  static const channel = MethodChannel('id.arta.arta/security');
  Future<LockStatus> _state(
    String method, [
    Map<String, Object?>? args,
  ]) async => LockStatus.fromMap(
    (await channel.invokeMapMethod<Object?, Object?>(method, args))!,
  );
  @override
  Future<LockStatus> status() => _state('status');
  @override
  Future<LockStatus> configure(String pin, bool biometric) =>
      _state('configure', {'pin': pin, 'biometric': biometric});
  @override
  Future<LockStatus> disable() => _state('disable');
  @override
  Future<PinResult> verifyPin(String pin) async {
    final result = (await channel.invokeMapMethod<Object?, Object?>(
      'verifyPin',
      {'pin': pin},
    ))!;
    return PinResult(result['ok'] as bool, result['retry'] as int);
  }

  @override
  Future<bool> authenticateBiometric() async =>
      await channel.invokeMethod<bool>('biometric') ?? false;
  @override
  Future<void> invalidateSession() => channel.invokeMethod<void>('lock');
}
