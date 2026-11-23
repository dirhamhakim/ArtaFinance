import 'decimal.dart';
import 'investment.dart';
import 'interest.dart';
import 'ledger.dart';
import 'money.dart';
import 'staking.dart';
import 'transaction_category.dart';

final class FinanceExtras {
  const FinanceExtras({
    this.instruments = const [],
    this.events = const [],
    this.quotes = const [],
    this.rates = const [],
    this.interestRules = const [],
    this.interestPostings = const [],
    this.catalogInfo = const {},
    this.stakingPlans = const [],
    this.rateHistory = const [],
    this.referenceQuotes = const [],
    this.referenceIssues = const [],
    this.categories,
  });
  final List<Instrument> instruments;
  final List<InvestmentEvent> events;
  final List<PriceQuote> quotes;
  final List<FxRate> rates;
  final List<InterestRule> interestRules;
  final List<InterestPosting> interestPostings;
  final Map<String, Object?> catalogInfo;
  final List<StakingPlan> stakingPlans;
  final List<FxRate> rateHistory;

  /// Null means an older database/backup: derive defaults and legacy names.
  final List<TransactionCategory>? categories;

  /// Bundled reference prices are immutable and excluded from financial backup.
  final List<PriceQuote> referenceQuotes;
  final List<String> referenceIssues;
  Iterable<PriceQuote> get allQuotes => [...referenceQuotes, ...quotes];
  FinanceExtras copy({
    List<Instrument>? instruments,
    List<InvestmentEvent>? events,
    List<PriceQuote>? quotes,
    List<FxRate>? rates,
    List<InterestRule>? interestRules,
    List<InterestPosting>? interestPostings,
    Map<String, Object?>? catalogInfo,
    List<StakingPlan>? stakingPlans,
    List<FxRate>? rateHistory,
    List<PriceQuote>? referenceQuotes,
    List<String>? referenceIssues,
    List<TransactionCategory>? categories,
  }) => FinanceExtras(
    instruments: instruments ?? this.instruments,
    events: events ?? this.events,
    quotes: quotes ?? this.quotes,
    rates: rates ?? this.rates,
    interestRules: interestRules ?? this.interestRules,
    interestPostings: interestPostings ?? this.interestPostings,
    catalogInfo: catalogInfo ?? this.catalogInfo,
    stakingPlans: stakingPlans ?? this.stakingPlans,
    rateHistory: rateHistory ?? this.rateHistory,
    referenceQuotes: referenceQuotes ?? this.referenceQuotes,
    referenceIssues: referenceIssues ?? this.referenceIssues,
    categories: categories ?? this.categories,
  );
  Decimal? rate(String currency) => currency == 'IDR'
      ? Decimal.one
      : rates.where((v) => v.currency == currency).firstOrNull?.rate;
  PriceQuote? latest(String instrument, {bool live = false}) {
    final list =
        allQuotes
            .where((v) => v.instrumentId == instrument && v.isLive == live)
            .toList()
          ..sort(comparePriceQuotes);
    return list.firstOrNull;
  }

  List<Holding> get holdings => buildHoldings(events);
  Money? holdingValue(Holding holding) {
    final q = latest(holding.instrumentId);
    if (q == null) return null;
    final fx = rate(q.currency);
    if (fx == null) return null;
    return (holding.quantity *
            priceAtLedgerUnits(
              q,
              events,
              localDate(DateTime.now().toUtc().add(const Duration(hours: 7))),
            ) *
            fx)
        .money();
  }

  Map<String, Object?> toJson() => {
    'instruments': instruments.map((v) => v.toJson()).toList(),
    'events': events.map((v) => v.toJson()).toList(),
    'quotes': quotes.map((v) => v.toJson()).toList(),
    'rates': rates.map((v) => v.toJson()).toList(),
    'interest_rules': interestRules.map((v) => v.toJson()).toList(),
    'interest_postings': interestPostings.map((v) => v.toJson()).toList(),
    'catalog_info': catalogInfo,
    'staking_plans': stakingPlans.map((v) => v.toJson()).toList(),
    'rate_history': rateHistory.map((v) => v.toJson()).toList(),
    if (categories != null)
      'categories': categories!.map((v) => v.toJson()).toList(),
  };
  factory FinanceExtras.fromJson(Map<String, Object?> j) {
    exactKeys(j, {
      'instruments',
      'events',
      'quotes',
      'rates',
      'interest_rules',
      'interest_postings',
      'catalog_info',
      if (j.containsKey('staking_plans')) 'staking_plans',
      if (j.containsKey('rate_history')) 'rate_history',
      if (j.containsKey('categories')) 'categories',
    });
    List<T> read<T>(String key, T Function(Map<String, Object?>) parse) {
      final rows = j[key];
      if (rows is! List<Object?> || rows.length > 100000) {
        throw const FormatException(
          'Daftar keuangan tidak valid/terlalu besar.',
        );
      }
      return rows.map((v) => parse(objectMap(v))).toList();
    }

    return FinanceExtras(
      categories: j.containsKey('categories')
          ? List.unmodifiable(read('categories', TransactionCategory.fromJson))
          : null,
      instruments: read('instruments', Instrument.fromJson),
      events: read('events', InvestmentEvent.fromJson),
      quotes: read('quotes', PriceQuote.fromJson),
      rates: read('rates', FxRate.fromJson),
      interestRules: read('interest_rules', InterestRule.fromJson),
      interestPostings: read('interest_postings', InterestPosting.fromJson),
      catalogInfo: objectMap(j['catalog_info']),
      stakingPlans: j.containsKey('staking_plans')
          ? read('staking_plans', StakingPlan.fromJson)
          : const [],
      rateHistory: j.containsKey('rate_history')
          ? read('rate_history', FxRate.fromJson)
          : const [],
    );
  }
  void validate(List<Account> accounts) {
    void unique(Iterable<String> values) {
      final ids = <String>{};
      if (values.any((v) => !ids.add(v))) {
        throw const FormatException('ID keuangan duplikat.');
      }
    }

    unique(instruments.map((v) => v.id));
    unique((categories ?? []).map((v) => v.id));
    unique((categories ?? []).map((v) => v.key));
    for (final category in categories ?? <TransactionCategory>[]) {
      TransactionCategory.fromJson(category.toJson());
    }
    unique(
      instruments
          .where((v) => v.kind == InstrumentKind.stock)
          .map((v) => v.code),
    );
    unique(events.map((v) => v.id));
    unique(quotes.map((v) => v.key));
    unique(rates.map((v) => v.currency));
    unique(interestRules.map((v) => v.id));
    unique(interestPostings.map((v) => v.id));
    unique(stakingPlans.map((v) => v.id));
    unique(rateHistory.map((v) => '${v.currency}:${v.date}'));
    for (final f in rateHistory) {
      FxRate.fromJson(f.toJson());
    }
    for (final p in stakingPlans) {
      StakingPlan.fromJson(p.toJson());
      if (!accounts.any((a) => a.id == p.accountId) ||
          !instruments.any(
            (i) => i.id == p.instrumentId && i.kind == InstrumentKind.crypto,
          )) {
        throw const FormatException(
          'Staking memerlukan aset dan instrumen crypto.',
        );
      }
    }
    for (final i in instruments) {
      Instrument.fromJson(i.toJson());
    }
    for (final f in rates) {
      FxRate.fromJson(f.toJson());
    }
    for (final e in events) {
      InvestmentEvent.fromJson(e.toJson());
      final i = instruments.where((v) => v.id == e.instrumentId).firstOrNull;
      final a = accounts.where((v) => v.id == e.accountId).firstOrNull;
      if (isStaking(e.kind) &&
          !stakingPlans.any(
            (p) =>
                p.id == e.stakingId &&
                p.accountId == e.accountId &&
                p.instrumentId == e.instrumentId,
          )) {
        throw const FormatException('Posisi staking tidak sesuai transaksi.');
      }
      if (i == null ||
          a == null ||
          (a.currency == 'IDR' && e.idrRate != Decimal.one) ||
          (e.destinationId != null &&
              !accounts.any((v) => v.id == e.destinationId))) {
        throw const FormatException('Referensi investasi tidak valid.');
      }
      if (i.kind == InstrumentKind.stock &&
          e.kind != InvestmentKind.split &&
          (e.quantity.raw % Decimal.scale != BigInt.zero ||
              e.networkFee.raw % Decimal.scale != BigInt.zero)) {
        throw const FormatException(
          'Unit saham berupa lembar bulat; 1 lot = 100 lembar.',
        );
      }
    }
    for (final h in buildHoldings(events)) {
      if (instruments.firstWhere((i) => i.id == h.instrumentId).kind ==
              InstrumentKind.stock &&
          h.quantity.raw % Decimal.scale != BigInt.zero) {
        throw const FormatException(
          'Split menghasilkan pecahan lembar saham. Catat penyelesaian pecahan sesuai sekuritas lebih dahulu.',
        );
      }
    }
    for (final q in quotes) {
      PriceQuote.fromJson(q.toJson());
      if (!instruments.any(
        (v) => v.id == q.instrumentId && v.currency == q.currency,
      )) {
        throw const FormatException('Referensi harga tidak valid.');
      }
    }
    for (final r in interestRules) {
      InterestRule.fromJson(r.toJson());
      if (!accounts.any((v) => v.id == r.accountId)) {
        throw const FormatException('Aset bunga tidak ditemukan.');
      }
    }
    final active = interestRules.where((r) => r.active).toList();
    for (var a = 0; a < active.length; a++) {
      for (var b = a + 1; b < active.length; b++) {
        final x = active[a], y = active[b];
        if (x.accountId == y.accountId &&
            x.start.compareTo(y.end ?? '9999-12-31') <= 0 &&
            y.start.compareTo(x.end ?? '9999-12-31') <= 0) {
          throw const FormatException(
            'Dua aturan bunga aktif untuk aset yang sama tidak boleh tumpang tindih.',
          );
        }
      }
    }
    for (final p in interestPostings) {
      InterestPosting.fromJson(p.toJson());
      final r = interestRules.where((v) => v.id == p.ruleId).firstOrNull;
      if (r == null ||
          p.start.compareTo(r.start) < 0 ||
          (r.end != null && p.end.compareTo(r.end!) > 0)) {
        throw const FormatException('Referensi periode bunga tidak valid.');
      }
      if (p.date.compareTo(p.end) < 0) {
        throw const FormatException(
          'Tanggal kredit tidak boleh sebelum akhir periode.',
        );
      }
      final startDate = DateTime.parse(p.start),
          endDate = DateTime.parse(p.end);
      if (!r.monthly && p.start != p.end) {
        throw const FormatException('Kredit harian harus satu tanggal.');
      }
      if (r.monthly) {
        final first = localDate(DateTime(startDate.year, startDate.month));
        final expectedStart = r.start.compareTo(first) > 0 ? r.start : first;
        final last = localDate(
          DateTime(startDate.year, startDate.month + 1, 0),
        );
        final expectedEnd = r.end != null && r.end!.compareTo(last) < 0
            ? r.end!
            : last;
        if (p.start != expectedStart ||
            p.end != expectedEnd ||
            endDate.month != startDate.month) {
          throw const FormatException(
            'Periode kredit bulanan tidak sesuai aturan.',
          );
        }
      }
      if (accounts.firstWhere((a) => a.id == r.accountId).currency == 'IDR' &&
          p.idrRate != Decimal.one) {
        throw const FormatException('Kurs bunga IDR harus satu.');
      }
    }
    final byAccount = <String, List<InterestPosting>>{};
    final ruleAccounts = {for (final r in interestRules) r.id: r.accountId};
    for (final p in interestPostings) {
      byAccount.putIfAbsent(ruleAccounts[p.ruleId]!, () => []).add(p);
    }
    for (final rows in byAccount.values) {
      rows.sort((a, b) => a.start.compareTo(b.start));
      for (var n = 1; n < rows.length; n++) {
        if (rows[n].start.compareTo(rows[n - 1].end) <= 0) {
          throw const FormatException(
            'Periode bunga aset sudah pernah dicatat atau dibatalkan.',
          );
        }
      }
    }
  }
}
