import 'decimal.dart';
import 'ledger.dart';
import 'money.dart';
import 'staking.dart';

enum InstrumentKind { stock, crypto, fund }

enum InvestmentKind {
  buy,
  sell,
  opening,
  transfer,
  dividend,
  reward,
  split,
  stake,
  unstakeRequest,
  unstake,
  stakingReward,
  stakingLoss,
}

bool isStaking(InvestmentKind kind) => {
  InvestmentKind.stake,
  InvestmentKind.unstakeRequest,
  InvestmentKind.unstake,
  InvestmentKind.stakingReward,
  InvestmentKind.stakingLoss,
}.contains(kind);

String investmentLabel(InvestmentKind k) => switch (k) {
  InvestmentKind.buy => 'Beli',
  InvestmentKind.sell => 'Jual',
  InvestmentKind.opening => 'Saldo unit awal',
  InvestmentKind.transfer => 'Pindah unit',
  InvestmentKind.dividend => 'Dividen / hasil tunai',
  InvestmentKind.reward => 'Reward unit',
  InvestmentKind.split => 'Split / reverse split',
  InvestmentKind.stake => 'Stake unit',
  InvestmentKind.unstakeRequest => 'Ajukan unstake',
  InvestmentKind.unstake => 'Unstake cair / langsung',
  InvestmentKind.stakingReward => 'Reward staking aktual',
  InvestmentKind.stakingLoss => 'Slashing / biaya unit staking',
};

final class Instrument {
  Instrument({
    required this.id,
    required this.code,
    required this.name,
    required this.kind,
    this.currency = 'IDR',
    this.providerId = '',
    this.logo = '',
    this.metadata = const {},
    this.overrides = const {},
    this.archived = false,
  });
  final String id, code, name, currency, providerId, logo;
  final InstrumentKind kind;
  final Map<String, Object?> metadata, overrides;
  final bool archived;
  String get displayName => overrides['name'] as String? ?? name;
  String get priceSymbol => overrides['provider_id'] as String? ?? providerId;
  String get logoUrl =>
      overrides['logo'] as String? ??
      (kind == InstrumentKind.stock
          ? 'https://assets.stockbit.com/logos/companies/$code.png'
          : logo);
  Map<String, Object?> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'kind': kind.name,
    'currency': currency,
    'provider_id': providerId,
    'logo': logo,
    'metadata': metadata,
    'overrides': overrides,
    'archived': archived,
  };
  factory Instrument.fromJson(Map<String, Object?> j) {
    exactKeys(j, {
      'id',
      'code',
      'name',
      'kind',
      'currency',
      'provider_id',
      'logo',
      'metadata',
      'overrides',
      'archived',
    });
    final v = Instrument(
      id: stringField(j, 'id'),
      code: stringField(j, 'code'),
      name: stringField(j, 'name'),
      kind: InstrumentKind.values.firstWhere(
        (v) => v.name == j['kind'],
        orElse: () => throw const FormatException('Jenis instrumen salah.'),
      ),
      currency: stringField(j, 'currency'),
      providerId: stringField(j, 'provider_id', empty: true),
      logo: stringField(j, 'logo', empty: true),
      metadata: objectMap(j['metadata']),
      overrides: objectMap(j['overrides']),
      archived: boolField(j, 'archived'),
    );
    if (!currencies.contains(v.currency) ||
        v.code.length > 40 ||
        v.name.length > 200 ||
        !v.overrides.keys.every({'name', 'provider_id', 'logo'}.contains) ||
        v.overrides.values.any((v) => v is! String || v.length > 1000)) {
      throw const FormatException('Metadata instrumen tidak valid.');
    }
    for (final url in [v.logo, v.overrides['logo'] as String? ?? '']) {
      if (url.isNotEmpty &&
          (Uri.tryParse(url)?.scheme != 'https' ||
              Uri.tryParse(url)?.host.isEmpty == true)) {
        throw const FormatException('URL logo harus HTTPS.');
      }
    }
    if (v.kind == InstrumentKind.stock &&
        (!RegExp(r'^[A-Z]{4}$').hasMatch(v.code) || v.currency != 'IDR')) {
      throw const FormatException(
        'Saham dibatasi kode IDX empat huruf dan IDR.',
      );
    }
    final shares = v.metadata['shares_count'];
    if (shares != null &&
        (shares is! String || !RegExp(r'^\d+$').hasMatch(shares))) {
      throw const FormatException('Jumlah lembar saham harus digit teks.');
    }
    return v;
  }
}

final class InvestmentEvent {
  InvestmentEvent({
    required this.id,
    required this.instrumentId,
    required this.accountId,
    required this.kind,
    required this.quantity,
    required this.gross,
    required this.fee,
    required this.date,
    required this.createdAt,
    required this.idrRate,
    this.destinationId,
    this.time,
    this.note = '',
    this.unknownCost = false,
    this.unitFee,
    this.zone = 'Asia/Jakarta',
    this.stakingId,
    this.pendingBucket = false,
    this.rewardStaked = false,
    this.availableOn,
  });
  final String id, instrumentId, accountId, date, createdAt, note, zone;
  final String? destinationId, time;
  final InvestmentKind kind;
  final Decimal quantity, idrRate;
  final Decimal? unitFee;
  final Money gross, fee;
  final bool unknownCost;
  final String? stakingId, availableOn;
  final bool pendingBucket, rewardStaked;
  Decimal get networkFee => unitFee ?? Decimal.zero;
  Money cashDelta(String account) => account != accountId
      ? Money.zero
      : switch (kind) {
          InvestmentKind.buy => -(gross + fee),
          InvestmentKind.sell || InvestmentKind.dividend => gross - fee,
          InvestmentKind.transfer ||
          InvestmentKind.stake ||
          InvestmentKind.unstakeRequest ||
          InvestmentKind.unstake ||
          InvestmentKind.stakingReward ||
          InvestmentKind.stakingLoss => -fee,
          _ => Money.zero,
        };
  Map<String, Object?> toJson() => {
    'id': id,
    'instrument_id': instrumentId,
    'account_id': accountId,
    'kind': kind.name,
    'quantity': quantity.text,
    'gross_minor': gross.stored,
    'fee_minor': fee.stored,
    'date': date,
    'created_at': createdAt,
    'idr_rate': idrRate.text,
    'destination_id': destinationId,
    'time': time,
    'note': note,
    'unknown_cost': unknownCost,
    'unit_fee': networkFee.text,
    'zone': zone,
    if (isStaking(kind)) ...{
      'staking_id': stakingId,
      'pending_bucket': pendingBucket,
      'reward_staked': rewardStaked,
      'available_on': availableOn,
    },
  };
  factory InvestmentEvent.fromJson(Map<String, Object?> j) {
    exactKeys(j, {
      'id',
      'instrument_id',
      'account_id',
      'kind',
      'quantity',
      'gross_minor',
      'fee_minor',
      'date',
      'created_at',
      'idr_rate',
      'destination_id',
      'time',
      'note',
      'unknown_cost',
      'unit_fee',
      'zone',
      if (j.containsKey('staking_id')) 'staking_id',
      if (j.containsKey('pending_bucket')) 'pending_bucket',
      if (j.containsKey('reward_staked')) 'reward_staked',
      if (j.containsKey('available_on')) 'available_on',
    });
    final e = InvestmentEvent(
      id: stringField(j, 'id'),
      instrumentId: stringField(j, 'instrument_id'),
      accountId: stringField(j, 'account_id'),
      kind: InvestmentKind.values.firstWhere(
        (v) => v.name == j['kind'],
        orElse: () => throw const FormatException('Jenis investasi salah.'),
      ),
      quantity: Decimal.parse(stringField(j, 'quantity')),
      gross: Money.stored(stringField(j, 'gross_minor')),
      fee: Money.stored(stringField(j, 'fee_minor')),
      date: stringField(j, 'date'),
      createdAt: stringField(j, 'created_at'),
      idrRate: Decimal.parse(stringField(j, 'idr_rate')),
      destinationId: j['destination_id'] as String?,
      time: j['time'] as String?,
      note: stringField(j, 'note', empty: true),
      unknownCost: boolField(j, 'unknown_cost'),
      unitFee: Decimal.parse(stringField(j, 'unit_fee')),
      zone: stringField(j, 'zone'),
      stakingId: j['staking_id'] as String?,
      pendingBucket: j.containsKey('pending_bucket')
          ? boolField(j, 'pending_bucket')
          : false,
      rewardStaked: j.containsKey('reward_staked')
          ? boolField(j, 'reward_staked')
          : false,
      availableOn: j['available_on'] as String?,
    );
    validateDate(e.date);
    validateTime(e.time);
    if (isStaking(e.kind)) {
      if (e.stakingId == null ||
          e.stakingId!.trim().isEmpty ||
          !e.gross.isZero ||
          !e.networkFee.isZero ||
          e.unknownCost ||
          e.destinationId != null ||
          (e.rewardStaked && e.kind != InvestmentKind.stakingReward) ||
          (e.pendingBucket &&
              !{
                InvestmentKind.unstake,
                InvestmentKind.stakingLoss,
              }.contains(e.kind))) {
        throw const FormatException('Transaksi staking tidak valid.');
      }
      if (e.availableOn != null) {
        validateDate(e.availableOn!);
        if (e.kind != InvestmentKind.unstakeRequest ||
            e.availableOn!.compareTo(e.date) < 0) {
          throw const FormatException(
            'Perkiraan cair harus setelah pengajuan unstake.',
          );
        }
      }
    } else if (e.stakingId != null ||
        e.pendingBucket ||
        e.rewardStaked ||
        e.availableOn != null) {
      throw const FormatException('Informasi staking pada transaksi biasa.');
    }
    if (!{'Asia/Jakarta', 'Asia/Makassar', 'Asia/Jayapura'}.contains(e.zone) ||
        DateTime.tryParse(e.createdAt)?.isUtc != true ||
        !e.idrRate.positive ||
        e.gross.isNegative ||
        e.fee.isNegative ||
        e.networkFee.negative ||
        e.note.length > 1000) {
      throw const FormatException('Transaksi investasi tidak valid.');
    }
    if (e.kind != InvestmentKind.dividend && !e.quantity.positive) {
      throw const FormatException('Unit harus positif.');
    }
    if (e.kind == InvestmentKind.dividend &&
        (!e.quantity.isZero || !e.gross.isPositive)) {
      throw const FormatException(
        'Dividen memakai nominal tunai dan unit nol.',
      );
    }
    if ({InvestmentKind.buy, InvestmentKind.sell}.contains(e.kind) &&
        !e.gross.isPositive) {
      throw const FormatException('Nilai beli/jual harus positif.');
    }
    if ({InvestmentKind.sell, InvestmentKind.dividend}.contains(e.kind) &&
        e.fee.compareTo(e.gross) > 0) {
      throw const FormatException('Biaya melebihi hasil tunai.');
    }
    if (e.kind == InvestmentKind.transfer
        ? (e.destinationId == null ||
              e.destinationId == e.accountId ||
              !e.gross.isZero)
        : e.destinationId != null) {
      throw const FormatException('Tujuan perpindahan unit tidak valid.');
    }
    if (e.kind != InvestmentKind.transfer && !e.networkFee.isZero) {
      throw const FormatException('Biaya unit hanya untuk perpindahan.');
    }
    if ({InvestmentKind.reward, InvestmentKind.split}.contains(e.kind) &&
        (!e.gross.isZero || !e.fee.isZero)) {
      throw const FormatException('Reward/split tidak mengubah kas.');
    }
    if (e.kind == InvestmentKind.opening && !e.fee.isZero) {
      throw const FormatException('Saldo unit awal tidak mengubah kas.');
    }
    if (e.unknownCost && e.kind != InvestmentKind.opening) {
      throw const FormatException('Modal tak diketahui hanya untuk unit awal.');
    }
    return e;
  }
}

final class PriceQuote {
  PriceQuote({
    required this.instrumentId,
    required this.price,
    required this.currency,
    required this.date,
    required this.fetchedAt,
    required this.source,
    this.asOf,
    this.isLive = false,
    this.adjustedThrough,
    this.isReference = false,
  });
  final String instrumentId, currency, date, fetchedAt, source;
  final String? asOf;
  final bool isLive;
  final bool isReference;
  final String? adjustedThrough;
  final Decimal price;
  String get key => '$instrumentId:$date:$source:${isLive ? 'live' : 'close'}';
  Map<String, Object?> toJson() => {
    'instrument_id': instrumentId,
    'price': price.text,
    'currency': currency,
    'date': date,
    'fetched_at': fetchedAt,
    'source': source,
    if (asOf != null) 'as_of': asOf,
    'is_live': isLive,
    if (adjustedThrough != null) 'adjusted_through': adjustedThrough,
  };
  factory PriceQuote.fromJson(Map<String, Object?> j) {
    exactKeys(j, {
      'instrument_id',
      'price',
      'currency',
      'date',
      'fetched_at',
      'source',
      if (j.containsKey('as_of')) 'as_of',
      if (j.containsKey('is_live')) 'is_live',
      if (j.containsKey('adjusted_through')) 'adjusted_through',
    });
    final q = PriceQuote(
      instrumentId: stringField(j, 'instrument_id'),
      price: Decimal.parse(stringField(j, 'price')),
      currency: stringField(j, 'currency'),
      date: stringField(j, 'date'),
      fetchedAt: stringField(j, 'fetched_at'),
      source: stringField(j, 'source'),
      asOf: j['as_of'] as String?,
      isLive: j.containsKey('is_live')
          ? boolField(j, 'is_live')
          : j['source'] == 'CoinGecko',
      adjustedThrough: j['adjusted_through'] as String?,
    );
    validateDate(q.date);
    if (q.adjustedThrough != null) {
      validateDate(q.adjustedThrough!);
      if (q.adjustedThrough!.compareTo(q.date) < 0) {
        throw const FormatException('Tanggal basis split mendahului harga.');
      }
    }
    if (!q.price.positive ||
        !currencies.contains(q.currency) ||
        DateTime.tryParse(q.fetchedAt)?.isUtc != true ||
        (q.asOf != null && DateTime.tryParse(q.asOf!)?.isUtc != true)) {
      throw const FormatException('Harga/kurs tidak valid.');
    }
    return q;
  }
}

/// Convert a split-adjusted quote to the actual share units in the ledger on
/// [day]. Repeated corporate actions at different locations count once.
Decimal priceAtLedgerUnits(
  PriceQuote quote,
  Iterable<InvestmentEvent> events,
  String day,
) {
  final anchor = quote.adjustedThrough ?? quote.date;
  final start = anchor.compareTo(day) < 0 ? anchor : day;
  final end = anchor.compareTo(day) < 0 ? day : anchor;
  var factor = Decimal.one;
  final seen = <String>{};
  for (final e in events) {
    if (e.kind == InvestmentKind.split &&
        e.instrumentId == quote.instrumentId &&
        e.date.compareTo(start) > 0 &&
        e.date.compareTo(end) <= 0 &&
        seen.add('${e.date}:${e.quantity.text}')) {
      factor = factor * e.quantity;
    }
  }
  return anchor.compareTo(day) > 0
      ? quote.price * factor
      : quote.price / factor;
}

int comparePriceQuotes(PriceQuote a, PriceQuote b) {
  final day = b.date.compareTo(a.date);
  if (day != 0) return day;
  if (a.isReference != b.isReference) return a.isReference ? 1 : -1;
  return DateTime.parse(b.fetchedAt).compareTo(DateTime.parse(a.fetchedAt));
}

final class FxRate {
  FxRate({required this.currency, required this.rate, required this.date});
  final String currency, date;
  final Decimal rate;
  Map<String, Object?> toJson() => {
    'currency': currency,
    'rate': rate.text,
    'date': date,
  };
  factory FxRate.fromJson(Map<String, Object?> j) {
    exactKeys(j, {'currency', 'rate', 'date'});
    final f = FxRate(
      currency: stringField(j, 'currency'),
      rate: Decimal.parse(stringField(j, 'rate')),
      date: stringField(j, 'date'),
    );
    validateDate(f.date);
    if (!currencies.contains(f.currency) ||
        !f.rate.positive ||
        (f.currency == 'IDR' && f.rate != Decimal.one)) {
      throw const FormatException('Kurs IDR per satu mata uang tidak valid.');
    }
    return f;
  }
}

final class Holding {
  Holding(this.accountId, this.instrumentId);
  final String accountId, instrumentId;
  Decimal quantity = Decimal.zero;
  Money? cost = Money.zero;
  Money? realized = Money.zero;
  Decimal locked = Decimal.zero;
  Decimal get available => quantity - locked;
}

final class PortfolioState {
  PortfolioState(this.holdings, this.staking);
  final List<Holding> holdings;
  final Map<String, StakingBalance> staking;
}

/// Replays weighted average basis chronologically. Edits/deletes are revalidated.
List<Holding> buildHoldings(List<InvestmentEvent> events) =>
    replayPortfolio(events).holdings;

PortfolioState replayPortfolio(List<InvestmentEvent> events) {
  final replay = PortfolioReplay();
  for (final e in [...events]..sort(compareInvestmentEvents)) {
    replay.apply(e);
  }
  return replay.state;
}

int compareInvestmentEvents(InvestmentEvent a, InvestmentEvent b) {
  final date = a.date.compareTo(b.date);
  if (date != 0) return date;
  final time = (a.time ?? '00:00').compareTo(b.time ?? '00:00');
  if (time != 0) return time;
  final created = DateTime.parse(a.createdAt)
      .compareTo(DateTime.parse(b.createdAt));
  return created != 0 ? created : a.id.compareTo(b.id);
}

/// Incremental replay also powers historical charts without replaying every
/// transaction again for every chart point.
final class PortfolioReplay {
  final pools = <String, Holding>{};
  final stakes = <String, StakingBalance>{};
  Holding pool(String a, String i) =>
      pools.putIfAbsent('$a:$i', () => Holding(a, i));
  PortfolioState get state => PortfolioState(pools.values.toList(), stakes);
  void apply(InvestmentEvent e) {
    final p = pool(e.accountId, e.instrumentId);
    switch (e.kind) {
      case InvestmentKind.buy:
      case InvestmentKind.opening:
      case InvestmentKind.reward:
        p.quantity = p.quantity + e.quantity;
        if (e.unknownCost) {
          p.cost = null;
        } else if (p.cost != null) {
          p.cost = p.cost! + e.idrRate.timesMoney(e.gross + e.fee);
        }
      case InvestmentKind.dividend:
        break;
      case InvestmentKind.split:
        if (p.locked.positive) {
          throw const FormatException('Selesaikan staking sebelum split unit.');
        }
        if (!p.quantity.positive) {
          throw const FormatException('Split memerlukan kepemilikan.');
        }
        p.quantity = p.quantity * e.quantity;
        if (!p.quantity.positive) {
          throw const FormatException('Hasil split di bawah presisi unit.');
        }
      case InvestmentKind.sell:
      case InvestmentKind.transfer:
        final outgoing = e.quantity + e.networkFee;
        if (outgoing.compareTo(p.available) > 0) {
          throw FormatException(
            'Unit tersedia ${e.instrumentId} tidak cukup pada ${e.date}; unit staking/unstake masih terkunci.',
          );
        }
        final removed = p.cost == null
            ? null
            : Money(roundRatio(p.cost!.minor * outgoing.raw, p.quantity.raw));
        if (e.kind == InvestmentKind.sell) {
          p.realized = p.realized == null || removed == null
              ? null
              : p.realized! + e.idrRate.timesMoney(e.gross - e.fee) - removed;
        } else {
          final dest = pool(e.destinationId!, e.instrumentId);
          final moved = p.cost == null
              ? null
              : Money(
                  roundRatio(p.cost!.minor * e.quantity.raw, p.quantity.raw),
                );
          dest.quantity = dest.quantity + e.quantity;
          dest.cost = dest.cost == null || moved == null
              ? null
              : dest.cost! + moved;
        }
        p.quantity = p.quantity - outgoing;
        p.cost = p.quantity.isZero
            ? Money.zero
            : p.cost == null || removed == null
            ? null
            : p.cost! - removed;
      case InvestmentKind.stake:
      case InvestmentKind.unstakeRequest:
      case InvestmentKind.unstake:
      case InvestmentKind.stakingReward:
      case InvestmentKind.stakingLoss:
        final s = stakes.putIfAbsent(e.stakingId!, StakingBalance.new);
        switch (e.kind) {
          case InvestmentKind.stake:
            if (e.quantity.compareTo(p.available) > 0) {
              throw const FormatException(
                'Unit bebas tidak cukup untuk stake.',
              );
            }
            s.staked = s.staked + e.quantity;
            p.locked = p.locked + e.quantity;
          case InvestmentKind.unstakeRequest:
            if (e.quantity.compareTo(s.staked) > 0) {
              throw const FormatException('Unit aktif staking tidak cukup.');
            }
            s.staked = s.staked - e.quantity;
            s.pending = s.pending + e.quantity;
          case InvestmentKind.unstake:
          case InvestmentKind.stakingLoss:
            final bucket = e.pendingBucket ? s.pending : s.staked;
            if (e.quantity.compareTo(bucket) > 0) {
              throw const FormatException(
                'Unit pada status staking yang dipilih tidak cukup.',
              );
            }
            if (e.pendingBucket) {
              s.pending = s.pending - e.quantity;
            } else {
              s.staked = s.staked - e.quantity;
            }
            p.locked = p.locked - e.quantity;
            if (e.kind == InvestmentKind.stakingLoss) {
              final removed = p.cost == null
                  ? null
                  : Money(
                      roundRatio(
                        p.cost!.minor * e.quantity.raw,
                        p.quantity.raw,
                      ),
                    );
              p.quantity = p.quantity - e.quantity;
              p.cost = p.quantity.isZero
                  ? Money.zero
                  : removed == null
                  ? null
                  : p.cost! - removed;
              s.losses = s.losses + e.quantity;
            }
          case InvestmentKind.stakingReward:
            p.quantity = p.quantity + e.quantity;
            s.rewards = s.rewards + e.quantity;
            if (e.rewardStaked) {
              s.staked = s.staked + e.quantity;
              p.locked = p.locked + e.quantity;
            }
          default:
            break;
        }
    }
  }
}
