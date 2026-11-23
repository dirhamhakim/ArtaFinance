import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/ledger.dart';
import '../models/transaction_category.dart';
import '../models/money.dart';
import '../models/schedule.dart';
import '../models/payment_card.dart';
import '../models/receipt_image.dart';
import '../repositories/finance_repository.dart';
import '../services/schedule_engine.dart';
import 'app_lock_controller.dart';
import '../models/decimal.dart';
import '../models/investment.dart';
import '../models/interest.dart';
import '../models/staking.dart';
import '../services/market_service.dart';
import '../services/csv_service.dart';
import '../services/reference_prices_service.dart';
import '../repositories/benchmark_repository.dart';
import 'benchmark_controller.dart';

final class FinanceController extends ChangeNotifier {
  FinanceController(
    this.repository, {
    DateTime Function()? clock,
    this.security,
    MarketService? market,
    PriceKeyStore? priceKeys,
    this.references,
    BenchmarkRepository? benchmarks,
  }) : clock = clock ?? DateTime.now,
       market = market ?? MarketService(clock: clock),
       priceKeys = priceKeys ?? AndroidPriceKeyStore() {
    benchmark = benchmarks == null
        ? null
        : BenchmarkController(
            benchmarks,
            repository,
            this.market,
            clock: this.clock,
          );
    benchmark?.addListener(_benchmarkChanged);
  }
  late final BenchmarkController? benchmark;
  void _benchmarkChanged() {
    if (!_disposed) notifyListeners();
  }

  Future<void> refreshBenchmark({bool force = false}) async {
    if (_disposed || !marketForeground || security?.locked == true || !ready) {
      return;
    }
    if (!force && await repository.preference('market_daily_auto') == 'false') {
      return;
    }
    await benchmark?.refresh(force: force);
  }

  final MarketService market;
  final PriceKeyStore priceKeys;
  final ReferencePricesService? references;
  String? _referenceInstrument;
  Future<bool> loadInstrumentHistory(String id) {
    _referenceInstrument = id;
    return run(() async {});
  }

  Future<LedgerSnapshot> _readSnapshot() async {
    final data = await repository.load();
    return references == null
        ? data
        : await references!.attach(data, requested: {?_referenceInstrument});
  }

  final FinanceRepository repository;
  final AppLockController? security;
  final DateTime Function() clock;
  String newId() => _uuid.v4();
  List<PendingOccurrence> get due => ScheduleEngine.due(snapshot, clock());
  final _uuid = const Uuid();
  LedgerSnapshot snapshot = LedgerSnapshot.empty();
  bool busy = false;
  bool ready = false;
  bool amountsHidden = false;
  bool marketForeground = true;
  bool pricesBusy = false;
  bool _disposed = false;
  int _dataGeneration = 0;
  String displayMoney(Money value) =>
      amountsHidden ? '••••••' : value.formatted;
  String displayCurrency(Money value, String currency) =>
      amountsHidden ? '••••••' : currencyMoney(value, currency);
  String? marketMessage;
  DateTime? lastMarketAttempt;
  String? error;

  Future<bool> run(Future<void> Function() operation) async {
    if (busy) return false;
    _dataGeneration++;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await operation();
      try {
        snapshot = await _readSnapshot();
        amountsHidden = await repository.amountsHidden();
        ready = true;
      } catch (_) {
        // Mutasi sudah selesai. Jangan meminta submit ulang dan membuat duplikat.
        ready = false;
        error = 'Operasi selesai, tetapi tampilan belum dapat dimuat. Tekan Coba lagi.';
      }
      return true;
    } on FormatException catch (e) {
      error = e.message;
      return false;
    } catch (_) {
      error = 'Data belum berhasil disimpan atau dibaca. Coba lagi.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> initialize() => run(() async {
    await repository.processAutomatic(clock());
    await repository.processInterest(clock());
  });
  Future<bool> refreshSchedules() => initialize();
  Future<bool> createAccount(
    String name,
    AccountKind kind,
    Money opening, {
    String currency = 'IDR',
    String? providerId,
  }) => run(() async {
    await repository.addAccount(
      Account(
        id: _uuid.v4(),
        name: name.trim(),
        kind: kind,
        opening: opening,
        createdAt: DateTime.now().toUtc().toIso8601String(),
        currency: currency,
        providerId: providerId,
      ),
    );
  });
  Future<bool> saveTransaction({
    required TransactionKind kind,
    required String accountId,
    required String? destinationId,
    required Money amount,
    required Money fee,
    Money? receiverFee,
    Decimal? receiverFeeRate,
    required String date,
    required String category,
    required String note,
    LedgerTransaction? existing,
    String? time,
    String zone = 'Asia/Jakarta',
    String? cardId,
    List<ReceiptImage> images = const [],
    Money? destinationAmount,
    Decimal? idrRate,
  }) => run(() async {
    await repository.saveTransaction(
      LedgerTransaction(
        id: existing?.id ?? _uuid.v4(),
        kind: kind,
        accountId: accountId,
        destinationId: destinationId,
        amount: amount,
        fee: fee,
        receiverFee: receiverFee,
        receiverFeeRate: receiverFeeRate,
        date: date,
        category: category.trim(),
        note: note.trim(),
        createdAt:
            existing?.createdAt ?? DateTime.now().toUtc().toIso8601String(),
        time: time,
        zone: zone,
        cardId: cardId,
        images: List.unmodifiable(images),
        destinationAmount: destinationAmount,
        idrRate:
            idrRate ??
            existing?.idrRate ??
            snapshot.extras.rate(
              snapshot.accounts.firstWhere((a) => a.id == accountId).currency,
            ) ??
            (throw const FormatException(
              'Isi kurs IDR di menu Mata uang & kurs.',
            )),
      ),
      edit: existing != null,
    );
  });
  Future<bool> deleteTransaction(String id) =>
      run(() => repository.deleteTransaction(id));
  Future<bool> saveCategory(TransactionCategory value, {bool edit = false}) =>
      run(() => repository.saveCategory(value, edit: edit));
  Future<bool> saveInstrument(Instrument i) =>
      run(() => repository.saveInstrument(i));
  Future<bool> saveStakingPlan(StakingPlan p) =>
      run(() => repository.saveStakingPlan(p));
  Future<bool> saveInvestment(InvestmentEvent e) =>
      run(() => repository.saveInvestment(e));
  Future<bool> deleteInvestment(String id) =>
      run(() => repository.deleteInvestment(id));
  Future<bool> saveQuotes(List<PriceQuote> values) =>
      run(() => repository.saveQuotes(values));
  Future<bool> saveRate(FxRate rate) => run(() => repository.saveRate(rate));
  Future<bool> saveInterestRule(InterestRule rule) =>
      run(() => repository.saveInterestRule(rule));
  Future<bool> postInterest(InterestPosting posting) => run(() async {
    await repository.postInterest(posting);
  });
  Future<bool> voidInterest(String id) =>
      run(() => repository.voidInterest(id));
  Future<bool> refreshPrices() async {
    if (busy || pricesBusy || !marketForeground || security?.locked == true) {
      return false;
    }
    final now = clock().toUtc();
    final saved = await repository.preference('market_last_attempt');
    final previous = DateTime.tryParse(saved ?? '');
    if (previous != null &&
        now.difference(previous) < const Duration(minutes: 1)) {
      marketMessage = 'Tunggu satu menit sejak pembaruan terakhir.';
      notifyListeners();
      return false;
    }
    return run(() async {
      lastMarketAttempt = now;
      await repository.setPreference(
        'market_last_attempt',
        now.toIso8601String(),
      );
      final active = snapshot.extras.holdings
          .where((h) => h.quantity.positive)
          .map((h) => h.instrumentId)
          .toSet();
      final instruments = snapshot.extras.instruments
          .where((i) => active.contains(i.id))
          .toList();
      final updated = <PriceQuote>[];
      final failures = <String>[];
      for (final i in instruments.where(
        (i) => i.kind == InstrumentKind.stock,
      )) {
        try {
          updated.add(await market.yahoo(i, live: true));
        } catch (_) {
          failures.add(i.code);
        }
      }
      final crypto = instruments
          .where((i) => i.kind == InstrumentKind.crypto)
          .toList();
      if (crypto.isNotEmpty) {
        try {
          updated.addAll(await market.crypto(crypto, await priceKeys.read()));
        } catch (_) {
          failures.add('crypto (cek API key/koneksi/kuota)');
        }
      }
      if (updated.isNotEmpty) await repository.saveQuotes(updated);
      marketMessage =
          '${updated.length} harga diperbarui.${failures.isEmpty ? '' : ' Gagal: ${failures.join(', ')}. Cache tetap disimpan.'}${instruments.any((i) => i.kind == InstrumentKind.fund) ? ' NAB reksa dana diisi manual.' : ''}';
    });
  }

  /// Foreground daily close sync. Attempts are persisted per instrument and
  /// target day; partial provider failures don't discard successful prices.
  Future<bool> refreshDailyCloses({bool force = false}) async {
    if (_disposed ||
        busy ||
        pricesBusy ||
        !marketForeground ||
        security?.locked == true ||
        !ready) {
      return false;
    }
    if (!force && await repository.preference('market_daily_auto') == 'false') {
      return false;
    }
    final now = clock().toUtc();
    final local = now.add(const Duration(hours: 7));
    final active = snapshot.extras.holdings
        .where((h) => h.quantity.positive)
        .map((h) => h.instrumentId)
        .toSet();
    final owned = snapshot.extras.instruments
        .where((i) => active.contains(i.id) && i.kind != InstrumentKind.fund)
        .toList();
    if (owned.any((i) => i.kind == InstrumentKind.stock)) {
      refreshBenchmark(force: force);
    }
    if (owned.isEmpty) return true;
    final due = <(Instrument, String)>[];
    for (final i in owned) {
      String target;
      if (i.kind == InstrumentKind.crypto) {
        final midnight = DateTime.utc(now.year, now.month, now.day);
        final end = now.isBefore(midnight.add(const Duration(minutes: 35)))
            ? midnight.subtract(const Duration(days: 1))
            : midnight;
        target = localDate(end.subtract(const Duration(days: 1)));
      } else {
        // Yahoo determines the actual completed session. Check once before and
        // once after the conservative 18:00 WIB closing-data window.
        var day = DateTime.utc(local.year, local.month, local.day);
        if (local.hour < 18) day = day.subtract(const Duration(days: 1));
        while (day.weekday > 5) {
          day = day.subtract(const Duration(days: 1));
        }
        target = localDate(day);
      }
      final checked = await repository.preference(
        'market_close_checked_${i.id}',
      );
      if (!force && checked == target) continue;
      final last = DateTime.tryParse(
        await repository.preference('market_close_attempt_${i.id}') ?? '',
      );
      if (last != null &&
          now.difference(last) < Duration(minutes: force ? 1 : 60)) {
        continue;
      }
      due.add((i, target));
    }
    if (due.isEmpty) return true;
    if (_disposed ||
        busy ||
        pricesBusy ||
        !marketForeground ||
        security?.locked == true) {
      return false;
    }
    pricesBusy = true;
    notifyListeners();
    try {
      var count = 0;
      final failed = <String>[];
      final unavailable = <InstrumentKind>{};
      var requests = 0;
      String? key;
      for (final (i, target) in due) {
        if (_disposed || !marketForeground || security?.locked == true) break;
        if (unavailable.contains(i.kind)) {
          failed.add(i.code);
          continue;
        }
        if (requests >= 12) break;
        requests++;
        await repository.setPreference(
          'market_close_attempt_${i.id}',
          now.toIso8601String(),
        );
        try {
          final List<PriceQuote> quotes;
          if (i.kind == InstrumentKind.stock) {
            quotes = await market.yahooCloses(i);
          } else {
            key ??= await priceKeys.read();
            final previous = snapshot.extras.latest(i.id);
            final days = previous == null
                ? 7
                : now.difference(DateTime.parse(previous.date)).inDays + 2;
            quotes = await market.cryptoCloses(
              i,
              key,
              days: days.clamp(7, 365),
            );
          }
          await repository.saveQuotes(quotes);
          count += quotes.length;
          if (i.kind == InstrumentKind.stock ||
              quotes.any((q) => q.date.compareTo(target) >= 0)) {
            await repository.setPreference(
              'market_close_checked_${i.id}',
              target,
            );
          }
        } catch (error) {
          failed.add(i.code);
          // A missing symbol must not stop other symbols. A provider/network
          // outage stops that provider only, so Yahoo cannot block CoinGecko.
          if (error is! FormatException ||
              (error is MarketHttpException && error.providerUnavailable)) {
            unavailable.add(i.kind);
          }
        }
      }
      marketMessage =
          '$count harga penutupan tersimpan.${failed.isEmpty ? '' : ' Belum tersedia: ${failed.join(', ')}; cache tetap ada.'}';
      if (!_disposed && !busy) {
        final generation = _dataGeneration;
        final refreshed = await _readSnapshot();
        if (!_disposed && !busy && generation == _dataGeneration) {
          snapshot = refreshed;
        }
      }
      return failed.isEmpty;
    } catch (_) {
      marketMessage =
          'Pembaruan penutupan belum berhasil; data lokal tetap tersedia.';
      return false;
    } finally {
      pricesBusy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> fetchSheet() => run(() async {
    final url = await repository.preference('sheet_csv_url') ?? '';
    final csv = await market.sheetCsv(url);
    await repository.saveQuotes(
      CsvService().prices(csv, snapshot.extras.instruments, clock()),
    );
    marketMessage = 'Harga spreadsheet diperbarui.';
  });
  Future<bool> saveCard(PaymentCard card) =>
      run(() => repository.saveCard(card));
  Future<bool> setTheme(String theme) => run(() => repository.setTheme(theme));
  Future<bool> setAmountsHidden(bool hidden) =>
      run(() => repository.setAmountsHidden(hidden));
  Future<bool> restore(LedgerSnapshot backup) =>
      run(() => repository.replace(backup, processAt: clock()));
  Future<bool> saveSchedule(
    ScheduleRule rule, {
    String? replacesId,
    int? replacesResolvedCount,
  }) => run(
    () => repository.saveSchedule(
      rule,
      replacesId: replacesId,
      replacesResolvedCount: replacesResolvedCount,
      processAt: clock(),
    ),
  );
  Future<bool> setScheduleState(
    String id,
    ScheduleState state, {
    bool skipMissed = false,
  }) => run(
    () =>
        repository.setScheduleState(id, state, clock(), skipMissed: skipMissed),
  );
  Future<bool> resolveOccurrence(
    PendingOccurrence item, {
    bool skip = false,
    Money? amount,
    Money? fee,
    Money? receiverFee,
    String? date,
    String? note,
    String? time,
  }) => run(() async {
    await repository.resolveOccurrence(
      item.rule.id,
      item.ordinal,
      clock(),
      skip: skip,
      amount: amount,
      fee: fee,
      receiverFee: receiverFee,
      date: date,
      note: note,
      time: time,
    );
  });

  @override
  void dispose() {
    _disposed = true;
    benchmark?.removeListener(_benchmarkChanged);
    benchmark?.dispose();
    market.close();
    security?.dispose();
    super.dispose();
  }
}
