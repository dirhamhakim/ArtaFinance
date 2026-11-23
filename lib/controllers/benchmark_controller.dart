import 'package:flutter/foundation.dart';

import '../models/investment.dart';
import '../models/ledger.dart';
import '../repositories/benchmark_repository.dart';
import '../repositories/finance_repository.dart';
import '../services/market_service.dart';

final class BenchmarkController extends ChangeNotifier {
  BenchmarkController(
    this.repository,
    this.preferences,
    this.market, {
    required this.clock,
  });
  final BenchmarkRepository repository;
  final FinanceRepository preferences;
  final MarketService market;
  final DateTime Function() clock;
  List<PriceQuote> quotes = [];
  bool busy = false;
  bool _disposed = false;
  String? message;
  Future<void>? _loading;
  Future<void> load() => _loading ??= _load();
  Future<void> _load() async {
    try {
      quotes = await repository.load();
    } catch (_) {
      message =
          'Riwayat IHSG belum dapat dibaca. Catatan keuangan tetap tersedia.';
      _loading = null;
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> refresh({bool force = false}) async {
    if (busy || _disposed) return;
    busy = true;
    notifyListeners();
    try {
      await load();
      if (_disposed) return;
      final now = clock().toUtc();
      final local = now.add(const Duration(hours: 7));
      var target = DateTime.utc(local.year, local.month, local.day);
      if (local.hour < 18) target = target.subtract(const Duration(days: 1));
      while (target.weekday > 5) {
        target = target.subtract(const Duration(days: 1));
      }
      final key = localDate(target);
      if (!force &&
          await preferences.preference('market_ihsg_checked') == key) {
        return;
      }
      final attempted = DateTime.tryParse(
        await preferences.preference('market_ihsg_attempt') ?? '',
      );
      if (attempted != null &&
          now.difference(attempted) < Duration(minutes: force ? 1 : 60)) {
        return;
      }
      await preferences.setPreference(
        'market_ihsg_attempt',
        now.toIso8601String(),
      );
      final since = quotes.isEmpty
          ? null
          : DateTime.parse(quotes.last.date).subtract(const Duration(days: 7));
      final rows = await market.ihsgCloses(since: since);
      if (_disposed) return;
      await repository.save(rows);
      quotes = await repository.load();
      await preferences.setPreference('market_ihsg_checked', key);
      message = 'IHSG tersimpan sampai ${quotes.last.date}.';
    } catch (_) {
      message = 'IHSG belum diperbarui. Riwayat offline tetap tersedia.';
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
