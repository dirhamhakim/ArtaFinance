import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/app_lock_service.dart';

class AppLockController extends ChangeNotifier {
  AppLockController(this.service, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;
  final AppLockService service;
  final DateTime Function() clock;
  LockStatus status = const LockStatus();
  bool ready = false, locked = true, busy = false, _disposed = false;
  String? error;
  int _epoch = 0;
  bool _background = false;
  bool get backgrounded => _background;
  DateTime? _retryUntil;
  Completer<bool>? _change;
  int get retrySeconds => _retryUntil == null
      ? 0
      : ((_retryUntil!.difference(clock()).inMilliseconds + 999) ~/ 1000).clamp(
          0,
          300,
        );
  bool get useBiometric =>
      status.enabled && status.biometric && status.available;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    if (busy) return;
    busy = true;
    ready = false;
    locked = true;
    try {
      status = await service.status();
      if (_disposed) return;
      _retryUntil = clock().add(Duration(seconds: status.retry));
      ready = true;
      locked = status.enabled;
      error = null;
    } catch (_) {
      locked = true;
      error = 'Keamanan lokal belum dapat dibuka. Coba lagi.';
    }
    busy = false;
    _notify();
  }

  void background() {
    _background = true;
    _epoch++;
    lock();
  }

  void resumed() {
    if (!_background) return;
    _background = false;
    lock();
  }

  void lock() {
    if (!ready || !status.enabled || _disposed) return;
    _epoch++;
    locked = true;
    error = null;
    unawaited(
      service.invalidateSession().catchError((Object _) {
        error = 'Sesi keamanan belum dapat diproses.';
        _notify();
      }),
    );
    _notify();
  }

  Future<bool> _authenticate(Future<PinResult> Function() action) async {
    if (!ready || !status.enabled || busy || _background) return false;
    final epoch = _epoch;
    busy = true;
    error = null;
    _notify();
    try {
      final result = await action();
      if (_disposed || epoch != _epoch) return false;
      _retryUntil = clock().add(Duration(seconds: result.retry));
      if (result.ok) {
        locked = false;
        _change?.complete(true);
        _change = null;
      } else {
        error = result.retry > 0
            ? 'Terlalu banyak percobaan. Tunggu sebelum mencoba lagi.'
            : 'Belum berhasil. Coba lagi atau gunakan PIN Arta.';
      }
      return result.ok;
    } catch (_) {
      if (!_disposed && epoch == _epoch) {
        error = 'Autentikasi belum dapat diproses. Coba lagi.';
      }
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<bool> pin(String pin) async {
    if (!RegExp(r'^\d{6}$').hasMatch(pin) || retrySeconds > 0) return false;
    return _authenticate(() => service.verifyPin(pin));
  }

  Future<bool> biometric() => useBiometric
      ? _authenticate(() async {
          final ok = await service.authenticateBiometric();
          return PinResult(ok, ok ? 0 : retrySeconds);
        })
      : Future.value(false);
  Future<bool> authorizeChange() {
    if (!status.enabled) return Future.value(true);
    if (_change != null) return _change!.future;
    final pending = Completer<bool>();
    _change = pending;
    lock();
    return pending.future;
  }

  Future<bool> configure(String pin, bool biometric) async {
    if (busy || locked || !ready) return false;
    busy = true;
    _notify();
    final epoch = _epoch;
    try {
      status = await service.configure(pin, biometric);
      if (_disposed) return false;
      if (_background || epoch != _epoch) lock();
      error = null;
      return true;
    } catch (_) {
      error = 'Kunci belum berhasil disimpan. Pengaturan lama tetap berlaku.';
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<bool> disable() async {
    if (busy || locked) return false;
    busy = true;
    _notify();
    try {
      status = await service.disable();
      if (_disposed) return false;
      locked = status.enabled;
      error = null;
      return !status.enabled;
    } catch (_) {
      error = 'Kunci belum berhasil dinonaktifkan.';
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    _change?.complete(false);
    _change = null;
    super.dispose();
  }
}
