// Generates synthetic financial data through Arta's production backup codec.
// Run from the project root: dart run tools/create_demo_backup.dart
import 'dart:convert';
import 'dart:io';

import 'package:arta/models/decimal.dart';
import 'package:arta/models/finance_extras.dart';
import 'package:arta/models/interest.dart';
import 'package:arta/models/investment.dart';
import 'package:arta/models/ledger.dart';
import 'package:arta/models/money.dart';
import 'package:arta/models/payment_card.dart';
import 'package:arta/models/receipt_image.dart';
import 'package:arta/models/recurrence_option.dart';
import 'package:arta/models/schedule.dart';
import 'package:arta/models/staking.dart';
import 'package:arta/services/analytics_service.dart';
import 'package:arta/services/backup_service.dart';
import 'package:arta/services/catalog_service.dart';
import 'package:arta/services/interest_engine.dart';

const demoPath = 'Arta-Demo-Lengkap-0.7.0.json';
const stamp = '2026-11-20T16:00:00Z';
final asOf = DateTime.parse('2026-11-21T05:00:00Z');
final transactions = <LedgerTransaction>[];
final events = <InvestmentEvent>[];
final schedules = <ScheduleRule>[];
final occurrences = <ScheduleOccurrence>[];
var serial = 0;

Money money(String value) => Money.input(value);
Decimal decimal(String value) => Decimal.parse(value);

Account asset(
  String id,
  String name,
  AccountKind kind,
  String opening, {
  String currency = 'IDR',
  String? provider,
}) => Account(
  id: id,
  name: 'DEMO · $name',
  kind: kind,
  opening: money(opening),
  currency: currency,
  providerId: provider,
  createdAt: '2026-06-01T00:00:00Z',
);

LedgerTransaction tx(
  TransactionKind kind,
  String account,
  String amount,
  String date,
  String category,
  String note, {
  String? destination,
  String fee = '0',
  String receiverFee = '0',
  String? destinationAmount,
  String? rate,
  String? receiverRate,
  String time = '12:30',
  String zone = 'Asia/Jakarta',
  String? card,
  List<ReceiptImage> images = const [],
  String? id,
}) {
  final value = LedgerTransaction(
    id: id ?? 'demo-tx-${++serial}',
    kind: kind,
    accountId: account,
    destinationId: destination,
    amount: money(amount),
    fee: money(fee),
    receiverFee: money(receiverFee),
    destinationAmount: destinationAmount == null
        ? null
        : money(destinationAmount),
    idrRate: rate == null ? null : decimal(rate),
    receiverFeeRate: receiverRate == null ? null : decimal(receiverRate),
    date: date,
    time: time,
    zone: zone,
    category: category,
    note: 'DATA CONTOH — $note',
    createdAt: '${date}T13:00:00Z',
    cardId: card,
    images: images,
  );
  transactions.add(value);
  return value;
}

void invest(
  String account,
  String instrument,
  InvestmentKind kind,
  String quantity,
  String gross,
  String date, {
  String fee = '0',
  String rate = '1',
  String? destination,
  String? unitFee,
  String? plan,
  bool pending = false,
  bool rewardStaked = false,
  String? availableOn,
  bool unknown = false,
  String note = '',
  String time = '14:00',
}) {
  events.add(
    InvestmentEvent(
      id: 'demo-inv-${++serial}',
      accountId: account,
      instrumentId: instrument,
      kind: kind,
      quantity: decimal(quantity),
      gross: money(gross),
      fee: money(fee),
      idrRate: decimal(rate),
      date: date,
      time: time,
      createdAt: '${date}T13:00:00Z',
      destinationId: destination,
      unitFee: unitFee == null ? null : decimal(unitFee),
      stakingId: plan,
      pendingBucket: pending,
      rewardStaked: rewardStaked,
      availableOn: availableOn,
      unknownCost: unknown,
      note: 'DATA CONTOH — $note',
    ),
  );
}

void resolve(ScheduleRule rule, int ordinal, OccurrenceState state) {
  final due = rule.dateAt(ordinal)!;
  final posted = state == OccurrenceState.posted
      ? tx(
          rule.kind,
          rule.accountId,
          rule.amountAt(ordinal).input,
          due,
          rule.category,
          'Jadwal ${rule.name}; kejadian ${ordinal + 1}.',
          destination: rule.destinationId,
          fee: rule.fee.input,
          receiverFee: rule.receivingFee.input,
          time: rule.time ?? '08:00',
        )
      : null;
  occurrences.add(
    ScheduleOccurrence(
      scheduleId: rule.id,
      ordinal: ordinal,
      dueDate: due,
      state: state,
      transactionId: posted?.id,
      resolvedAt: '${due}T14:00:00Z',
    ),
  );
}

Future<void> main() async {
  final idx = objectMap(
    jsonDecode(await File('assets/data/idx_stocks.json').readAsString()),
  );
  final instruments = [
    for (final row in idx['stocks']! as List<Object?>)
      mergeStock(null, objectMap(row)),
    for (final row in jsonDecode(
      await File('assets/data/crypto_defaults.json').readAsString(),
    ) as List<Object?>)
      Instrument.fromJson(objectMap(row)),
    Instrument(
      id: 'fund:demo-pasar-uang',
      code: 'RDPU-DEMO',
      name: 'DEMO Reksa Dana Pasar Uang',
      kind: InstrumentKind.fund,
      metadata: {
        'input_method': 'manual',
        'description': 'NAB dan unit fiktif; bukan produk Bibit.',
      },
    ),
    Instrument(
      id: 'fund:demo-obligasi',
      code: 'RDPT-DEMO',
      name: 'DEMO Reksa Dana Pendapatan Tetap',
      kind: InstrumentKind.fund,
    ),
    Instrument(
      id: 'fund:demo-saham',
      code: 'RDS-DEMO',
      name: 'DEMO Reksa Dana Saham',
      kind: InstrumentKind.fund,
    ),
    Instrument(
      id: 'fund:demo-split',
      code: 'SPLIT-DEMO',
      name: 'DEMO Arsip Simulasi Split Unit',
      kind: InstrumentKind.fund,
      archived: true,
      overrides: {'name': 'DEMO Split 1:2 · selesai & diarsipkan'},
    ),
  ];
  final accounts = [
    asset(
      'mandiri',
      'Mandiri Livin GPN Gold',
      AccountKind.bank,
      '60000000',
      provider: 'mandiri',
    ),
    asset(
      'seabank',
      'SeaBank Dana Darurat',
      AccountKind.bank,
      '12000000',
      provider: 'seabank',
    ),
    asset(
      'jago',
      'Jago Syariah Kantong Utama',
      AccountKind.bank,
      '5000000',
      provider: 'jago',
    ),
    asset('cash', 'Uang Tunai', AccountKind.cash, '750000'),
    asset('doku', 'DOKU', AccountKind.ewallet, '350000', provider: 'doku'),
    asset('gopay', 'GoPay', AccountKind.ewallet, '200000', provider: 'gopay'),
    asset('dana', 'DANA', AccountKind.ewallet, '100000', provider: 'dana'),
    asset(
      'debit',
      'Debit Jago Syariah · Kantong Kartu',
      AccountKind.debit,
      '0',
      provider: 'jago',
    ),
    asset('stockbit', 'Stockbit RDN', AccountKind.exchange, '0'),
    asset('bibit', 'Bibit Saldo Tunai', AccountKind.exchange, '0'),
    asset('floq', 'FLOQ', AccountKind.exchange, '0'),
    asset('triv', 'TRIV', AccountKind.exchange, '0'),
    asset('tokocrypto', 'Tokocrypto', AccountKind.exchange, '0'),
    asset('metamask', 'MetaMask Wallet', AccountKind.exchange, '0'),
    asset('bybit', 'Bybit ID', AccountKind.exchange, '0', currency: 'USD'),
    asset(
      'redotpay',
      'RedotPay USD',
      AccountKind.ewallet,
      '40',
      currency: 'USD',
    ),
    asset('pyypl', 'Pyypl USD', AccountKind.ewallet, '30', currency: 'USD'),
    asset('getplu', 'Getplu', AccountKind.ewallet, '100000'),
    asset('liability', 'Utang Pribadi', AccountKind.liability, '-3000000'),
    asset('receivable', 'Piutang Teman', AccountKind.receivable, '1500000'),
    asset(
      'pending',
      'Dana Penjualan Belum Cair',
      AccountKind.receivable,
      '800000',
    ),
    asset('negative', 'Koreksi Saldo Minus', AccountKind.cash, '-125000'),
  ];
  final cards = [
    PaymentCard(
      id: 'card-legacy',
      name: 'DEMO Kartu lama · terhubung Jago',
      accountId: 'jago',
      createdAt: '2026-06-01T00:00:00Z',
    ),
  ];

  // Cash funding and investments are separate: a deposit is never an expense.
  for (final allocation in [
    ('stockbit', '20000000'),
    ('bibit', '10000000'),
    ('tokocrypto', '10000000'),
    ('floq', '2000000'),
    ('triv', '2000000'),
  ]) {
    tx(
      TransactionKind.transfer,
      'mandiri',
      allocation.$2,
      '2026-06-02',
      '',
      'Setor dana untuk investasi; belum membeli unit.',
      destination: allocation.$1,
      fee: '2500',
      time: '08:15',
    );
  }
  tx(
    TransactionKind.transfer,
    'mandiri',
    '1600000',
    '2026-06-02',
    '',
    'Transfer lintas mata uang: Rp1.600.000 menjadi USD100; biaya penerima USD1.',
    destination: 'bybit',
    destinationAmount: '100',
    fee: '5000',
    receiverFee: '1',
    receiverRate: '16000',
    time: '09:10',
  );
  tx(
    TransactionKind.transfer,
    'jago',
    '1500000',
    '2026-06-03',
    '',
    'Isi kantong debit terpisah; saldo Jago utama berkurang sekali.',
    destination: 'debit',
  );

  // A varied six-month history fills monthly, category and asset charts.
  for (var month = 6; month <= 11; month++) {
    String day(int d) =>
        '2026-${month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
    tx(
      TransactionKind.income,
      'mandiri',
      '${9500000 + (month - 6) * 150000}',
      day(1),
      'Gaji',
      'Gaji bulanan contoh.',
      time: '08:00',
    );
    tx(
      TransactionKind.income,
      'jago',
      '${600000 + month * 20000}',
      day(12),
      'Freelance',
      'Pembayaran pekerjaan sampingan.',
      time: '16:45',
    );
    tx(
      TransactionKind.transfer,
      'mandiri',
      '1000000',
      day(2),
      '',
      'Tabungan bulanan dana darurat.',
      destination: 'seabank',
    );
    tx(
      TransactionKind.transfer,
      'mandiri',
      '850000',
      day(3),
      '',
      'Dana belanja kartu debit; kantong mandiri.',
      destination: 'debit',
    );
    tx(
      TransactionKind.transfer,
      'mandiri',
      '400000',
      day(5),
      '',
      'Tarik tunai.',
      destination: 'cash',
      fee: month.isEven ? '0' : '2500',
    );
    tx(
      TransactionKind.transfer,
      'mandiri',
      '350000',
      day(7),
      '',
      'Top up DOKU, biaya pengirim Rp1.000 dan penerima Rp500.',
      destination: 'doku',
      fee: '1000',
      receiverFee: '500',
    );
    tx(
      TransactionKind.transfer,
      'jago',
      '250000',
      day(8),
      '',
      'Top up GoPay tanpa biaya.',
      destination: 'gopay',
    );
    for (var d = 1; d <= (month == 11 ? 20 : 28); d += 2) {
      tx(
        TransactionKind.expense,
        d % 4 == 1 ? 'cash' : 'gopay',
        '${18000 + ((d + month) % 5) * 6500}',
        day(d),
        'Makan & Minum',
        'Makan harian, porsi ${d % 3 + 1}.',
        time: d.isEven ? '19:20' : '12:15',
      );
    }
    tx(
      TransactionKind.expense,
      'debit',
      '${320000 + month * 5000}',
      day(6),
      'Belanja Bulanan',
      'Belanja kebutuhan rumah.',
      time: '18:35',
    );
    tx(
      TransactionKind.expense,
      'mandiri',
      '1500000',
      day(10),
      'Tempat Tinggal',
      'Sewa tempat tinggal.',
      time: '09:00',
    );
    tx(
      TransactionKind.expense,
      'doku',
      '125000',
      day(11),
      'Internet & Pulsa',
      'Paket data internet.',
      time: '21:40',
    );
    tx(
      TransactionKind.expense,
      'debit',
      '${175000 + month * 4500}',
      day(14),
      'Transportasi',
      'Bahan bakar dan parkir.',
      time: '07:25',
    );
    tx(
      TransactionKind.expense,
      'jago',
      '99000',
      day(16),
      'Langganan',
      'Langganan hiburan.',
      card: 'card-legacy',
      time: '20:05',
    );
    tx(
      TransactionKind.expense,
      'mandiri',
      '250000',
      day(18),
      'Kesehatan',
      'Vitamin dan kebutuhan kesehatan.',
      time: '10:10',
    );
    tx(
      TransactionKind.expense,
      'debit',
      '150000',
      day(20),
      'Hiburan',
      'Jalan-jalan akhir pekan.',
      time: '19:45',
    );
    tx(
      TransactionKind.transfer,
      'mandiri',
      '250000',
      day(19),
      '',
      'Bayar sebagian utang; mengurangi liabilitas.',
      destination: 'liability',
    );
  }
  tx(
    TransactionKind.transfer,
    'receivable',
    '500000',
    '2026-09-09',
    '',
    'Teman mengembalikan piutang; bukan pemasukan baru.',
    destination: 'mandiri',
  );
  tx(
    TransactionKind.transfer,
    'pending',
    '800000',
    '2026-10-06',
    '',
    'Dana tertunda sudah cair.',
    destination: 'mandiri',
  );
  tx(
    TransactionKind.expense,
    'negative',
    '50000',
    '2026-11-19',
    'Koreksi & Lainnya',
    'Contoh saldo noninvestasi boleh minus.',
  );
  tx(
    TransactionKind.income,
    'redotpay',
    '12,50',
    '2026-11-05',
    'Cashback',
    'Cashback USD dengan kurs historis tersimpan.',
    rate: '16200',
    time: '23:10',
  );
  tx(
    TransactionKind.expense,
    'redotpay',
    '8,75',
    '2026-11-08',
    'Belanja Online',
    'Belanja USD8,75; tidak memakai kurs hari ini.',
    rate: '16150',
  );
  tx(
    TransactionKind.transfer,
    'redotpay',
    '10',
    '2026-11-09',
    '',
    'Transfer sesama USD dengan biaya dua sisi.',
    destination: 'pyypl',
    fee: '0,25',
    receiverFee: '0,10',
    rate: '16100',
    receiverRate: '16100',
  );
  tx(
    TransactionKind.transfer,
    'pyypl',
    '10',
    '2026-11-10',
    '',
    'USD10 ditukar menjadi Rp161.000; penerima dikenai Rp1.000.',
    destination: 'mandiri',
    destinationAmount: '161000',
    fee: '0,20',
    receiverFee: '1000',
    rate: '16100',
    receiverRate: '1',
  );
  tx(
    TransactionKind.expense,
    'getplu',
    '29000',
    '2026-11-17',
    'Belanja Online',
    'Pembayaran dari Getplu.',
    time: '22:10',
    zone: 'Asia/Makassar',
  );
  tx(
    TransactionKind.income,
    'dana',
    '15000',
    '2026-11-18',
    'Cashback',
    'Contoh transaksi zona WIT.',
    time: '10:05',
    zone: 'Asia/Jayapura',
  );

  // Real reference prices; financial trades and quantities below are fictional.
  final historyIndex = objectMap(
    jsonDecode(await File('assets/data/history/index.json').readAsString()),
  );
  final heldIds = {
    'idx:BBCA',
    'idx:BBRI',
    'idx:TLKM',
    'idx:BBNI',
    'idx:ASII',
    ...instruments
        .where((i) => i.kind == InstrumentKind.crypto)
        .map((i) => i.id),
  };
  final quotes = <PriceQuote>[];
  for (final raw in historyIndex['instruments']! as List<Object?>) {
    final meta = objectMap(raw);
    final id = meta['id']! as String;
    if (!heldIds.contains(id)) continue;
    final rows = jsonDecode(
      utf8.decode(
        gzip.decode(
          await File('assets/data/history/${meta['file']}').readAsBytes(),
        ),
      ),
    ) as List<Object?>;
    for (final rawRow in rows) {
      final row = rawRow! as List<Object?>;
      final date = row[0]! as String;
      if (date.compareTo('2026-05-31') < 0 ||
          date.compareTo('2026-11-20') > 0) {
        continue;
      }
      quotes.add(
        PriceQuote(
          instrumentId: id,
          price: decimal(row[1]! as String),
          currency: 'IDR',
          date: date,
          fetchedAt: historyIndex['prepared_at']! as String,
          source: meta['source']! as String,
          adjustedThrough: meta['adjusted_through'] as String?,
        ),
      );
    }
  }
  // Derive execution consideration from historical close, avoiding absurd demo returns.
  Money consideration(String id, String quantity, String date) {
    final prior =
        quotes
            .where((q) => q.instrumentId == id && q.date.compareTo(date) <= 0)
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    if (prior.isEmpty) throw StateError('No close for $id on $date');
    return (prior.last.price * decimal(quantity)).money();
  }

  for (final stock in [
    ('BBCA', '300'),
    ('BBRI', '500'),
    ('TLKM', '1000'),
    ('BBNI', '400'),
    ('ASII', '300'),
  ]) {
    final id = 'idx:${stock.$1}';
    invest(
      'stockbit',
      id,
      InvestmentKind.buy,
      stock.$2,
      consideration(id, stock.$2, '2026-06-03').input,
      '2026-06-03',
      fee: '7500',
      note:
          'Beli ${stock.$2} lembar; harga contoh mengacu penutupan tersimpan.',
    );
  }
  for (final month in [7, 8, 9, 10, 11]) {
    final date = '2026-${month.toString().padLeft(2, '0')}-05';
    invest(
      'stockbit',
      'idx:BBCA',
      InvestmentKind.buy,
      '100',
      consideration('idx:BBCA', '100', date).input,
      date,
      fee: '2000',
      note: 'DCA bulanan 1 lot.',
    );
  }
  invest(
    'stockbit',
    'idx:BBRI',
    InvestmentKind.sell,
    '100',
    consideration('idx:BBRI', '100', '2026-09-15').input,
    '2026-09-15',
    fee: '1500',
    note: 'Jual sebagian; contoh laba/rugi terealisasi.',
  );
  invest(
    'stockbit',
    'idx:TLKM',
    InvestmentKind.dividend,
    '0',
    '135000',
    '2026-08-20',
    fee: '13500',
    note: 'Dividen tunai contoh; fee mewakili potongan yang dicatat.',
  );

  final cryptoAllocations = [
    ('cg:bitcoin', 'tokocrypto', '0.003'),
    ('cg:ethereum', 'tokocrypto', '0.20'),
    ('cg:solana', 'tokocrypto', '3'),
    ('cg:hyperliquid', 'floq', '3'),
    ('cg:binancecoin', 'triv', '0.10'),
    ('cg:tether', 'tokocrypto', '100'),
    ('cg:usd-coin', 'tokocrypto', '75'),
    ('cg:tether-gold', 'triv', '0.005'),
    ('cg:pax-gold', 'triv', '0.005'),
  ];
  for (final coin in cryptoAllocations) {
    invest(
      coin.$2,
      coin.$1,
      InvestmentKind.buy,
      coin.$3,
      consideration(coin.$1, coin.$3, '2026-06-04').input,
      '2026-06-04',
      fee: '5000',
      note: 'Pembelian crypto contoh.',
    );
  }
  invest(
    'floq',
    'cg:ripple',
    InvestmentKind.opening,
    '50',
    '0',
    '2026-06-04',
    unknown: true,
    note: 'Unit awal dengan modal belum diketahui; nilai pasar tetap bisa dihitung.',
  );
  invest(
    'tokocrypto',
    'cg:ethereum',
    InvestmentKind.transfer,
    '0.08',
    '0',
    '2026-07-01',
    destination: 'metamask',
    unitFee: '0.0001',
    fee: '2000',
    note: 'Kirim ETH ke MetaMask, fee unit dan fee tunai terpisah.',
  );
  invest(
    'tokocrypto',
    'cg:bitcoin',
    InvestmentKind.sell,
    '0.0005',
    consideration('cg:bitcoin', '0.0005', '2026-10-10').input,
    '2026-10-10',
    fee: '3000',
    note: 'Jual sebagian BTC.',
  );
  invest(
    'floq',
    'cg:hyperliquid',
    InvestmentKind.reward,
    '0.05',
    '0',
    '2026-09-10',
    note: 'Reward unit biasa, tanpa arus kas.',
  );
  invest(
    'bybit',
    'cg:tether',
    InvestmentKind.buy,
    '20',
    '20',
    '2026-07-03',
    fee: '0,05',
    rate: '16100',
    note: 'Beli USDT memakai saldo USD.',
  );

  final plans = [
    StakingPlan(
      id: 'stake-eth',
      accountId: 'metamask',
      instrumentId: 'cg:ethereum',
      name: 'DEMO ETH · aktif + menunggu cair',
      network: 'Ethereum',
      validator: 'Validator Contoh',
      apr: decimal('3.5'),
    ),
    StakingPlan(
      id: 'stake-sol',
      accountId: 'tokocrypto',
      instrumentId: 'cg:solana',
      name: 'DEMO SOL · reward cair & slashing',
      network: 'Solana',
      validator: 'Validator Contoh SOL',
      apr: decimal('6'),
    ),
    StakingPlan(
      id: 'stake-hype',
      accountId: 'floq',
      instrumentId: 'cg:hyperliquid',
      name: 'DEMO HYPE · selesai',
      network: 'Hyperliquid',
      apr: decimal('2'),
      archived: true,
    ),
  ];
  invest(
    'metamask',
    'cg:ethereum',
    InvestmentKind.stake,
    '0.05',
    '0',
    '2026-07-02',
    plan: 'stake-eth',
    fee: '1500',
    note: 'Pokok tetap dihitung sekali. APR hanya referensi.',
  );
  invest(
    'metamask',
    'cg:ethereum',
    InvestmentKind.stakingReward,
    '0.001',
    '0',
    '2026-08-02',
    plan: 'stake-eth',
    rewardStaked: true,
    note: 'Reward aktual ditambahkan ke stake.',
  );
  invest(
    'metamask',
    'cg:ethereum',
    InvestmentKind.unstakeRequest,
    '0.01',
    '0',
    '2026-09-02',
    plan: 'stake-eth',
    availableOn: '2026-09-09',
    note: 'Ajukan unstake; masih terkunci.',
  );
  invest(
    'metamask',
    'cg:ethereum',
    InvestmentKind.unstake,
    '0.006',
    '0',
    '2026-09-10',
    plan: 'stake-eth',
    pending: true,
    note: 'Sebagian pending sudah cair; sisa masih pending.',
  );
  invest(
    'metamask',
    'cg:ethereum',
    InvestmentKind.stakingLoss,
    '0.0001',
    '0',
    '2026-09-11',
    plan: 'stake-eth',
    pending: true,
    note: 'Biaya unit dari bucket pending, contoh saja.',
  );
  invest(
    'tokocrypto',
    'cg:solana',
    InvestmentKind.stake,
    '2',
    '0',
    '2026-07-02',
    plan: 'stake-sol',
  );
  invest(
    'tokocrypto',
    'cg:solana',
    InvestmentKind.stakingReward,
    '0.02',
    '0',
    '2026-08-02',
    plan: 'stake-sol',
    note: 'Reward aktual ke unit bebas; tidak di-restake.',
  );
  invest(
    'tokocrypto',
    'cg:solana',
    InvestmentKind.stakingLoss,
    '0.005',
    '0',
    '2026-09-02',
    plan: 'stake-sol',
    note: 'Contoh slashing pokok aktif.',
  );
  invest(
    'tokocrypto',
    'cg:solana',
    InvestmentKind.unstake,
    '0.5',
    '0',
    '2026-10-02',
    plan: 'stake-sol',
    note: 'Unstake langsung dari bucket aktif.',
  );
  invest(
    'floq',
    'cg:hyperliquid',
    InvestmentKind.stake,
    '1',
    '0',
    '2026-07-02',
    plan: 'stake-hype',
  );
  invest(
    'floq',
    'cg:hyperliquid',
    InvestmentKind.unstakeRequest,
    '1',
    '0',
    '2026-08-02',
    plan: 'stake-hype',
    availableOn: '2026-08-09',
  );
  invest(
    'floq',
    'cg:hyperliquid',
    InvestmentKind.unstake,
    '1',
    '0',
    '2026-08-09',
    plan: 'stake-hype',
    pending: true,
    note: 'Siklus selesai; posisi staking diarsipkan.',
  );

  for (final fund in [
    ('fund:demo-pasar-uang', '2000', '3000000'),
    ('fund:demo-obligasi', '1000', '2000000'),
    ('fund:demo-saham', '500', '1500000'),
  ]) {
    invest(
      'bibit',
      fund.$1,
      InvestmentKind.buy,
      fund.$2,
      fund.$3,
      '2026-06-05',
      note: 'NAB dan unit diinput manual; produk fiktif.',
    );
  }
  invest(
    'bibit',
    'fund:demo-pasar-uang',
    InvestmentKind.sell,
    '100',
    '155000',
    '2026-10-07',
    fee: '1000',
    note: 'Pencairan sebagian reksa dana.',
  );
  invest(
    'bibit',
    'fund:demo-obligasi',
    InvestmentKind.dividend,
    '0',
    '25000',
    '2026-11-10',
    note: 'Distribusi hasil tunai contoh.',
  );
  invest(
    'bibit',
    'fund:demo-split',
    InvestmentKind.opening,
    '100',
    '100000',
    '2026-06-05',
    note: 'Instrumen fiktif untuk simulasi split.',
  );
  invest(
    'bibit',
    'fund:demo-split',
    InvestmentKind.split,
    '2',
    '0',
    '2026-07-05',
    note: 'Rasio 2 berarti unit 100 menjadi 200; total modal sama.',
  );
  invest(
    'bibit',
    'fund:demo-split',
    InvestmentKind.sell,
    '200',
    '110000',
    '2026-08-05',
    note: 'Posisi selesai, instrumen diarsipkan.',
  );
  for (
    var d = DateTime.utc(2026, 6, 5);
    !d.isAfter(DateTime.utc(2026, 11, 20));
    d = d.add(const Duration(days: 1))
  ) {
    final elapsed = d.difference(DateTime.utc(2026, 6, 5)).inDays;
    for (final item in [
      ('fund:demo-pasar-uang', 150000 + elapsed * 35),
      ('fund:demo-obligasi', 200000 + elapsed * 60),
      ('fund:demo-saham', 300000 + elapsed * 90 + (elapsed % 13 - 6) * 600),
    ]) {
      quotes.add(
        PriceQuote(
          instrumentId: item.$1,
          price: decimal((item.$2 / 100).toStringAsFixed(2)),
          currency: 'IDR',
          date: localDate(d),
          fetchedAt: stamp,
          source: 'DEMO · NAB manual fiktif',
        ),
      );
    }
    quotes.add(
      PriceQuote(
        instrumentId: 'fund:demo-split',
        price: decimal(d.month == 6 ? '1000' : '550'),
        currency: 'IDR',
        date: localDate(d),
        fetchedAt: stamp,
        source: 'DEMO · simulasi split',
        adjustedThrough: localDate(d),
      ),
    );
  }
  // Both cached close and cached live quote are represented, without an API call.
  for (final id in ['cg:bitcoin', 'idx:BBCA']) {
    final rows = quotes.where((q) => q.instrumentId == id).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final last = rows.last;
    quotes.add(
      PriceQuote(
        instrumentId: id,
        price: last.price,
        currency: 'IDR',
        date: last.date,
        fetchedAt: stamp,
        asOf: '${last.date}T16:00:00Z',
        source: 'DEMO · contoh cache live memakai harga historis',
        isLive: true,
      ),
    );
  }

  // Twelve recurrence options, plus installments, income and transfer schedules.
  for (final option in RecurrenceOption.values) {
    final isMonthly = option == RecurrenceOption.monthly;
    final isEom = option == RecurrenceOption.monthEnd;
    final rule = ScheduleRule(
      id: 'repeat-${option.name}',
      name: isMonthly
          ? 'DEMO Mandiri · Rp5.500 tanggal 4'
          : isEom
          ? 'DEMO Mandiri · Rp6.000 akhir bulan'
          : 'DEMO ${option.label}',
      kind: TransactionKind.expense,
      accountId: isMonthly || isEom ? 'mandiri' : 'cash',
      amount: money(
        isMonthly
            ? '5500'
            : isEom
            ? '6000'
            : '25000',
      ),
      fee: Money.zero,
      category: isMonthly || isEom ? 'Biaya Bank' : 'Kebutuhan Rutin',
      note: 'DATA CONTOH — aturan diinput sendiri. Jadwal konfirmasi tidak otomatis mengubah saldo.',
      startDate: isMonthly
          ? '2026-06-04'
          : isEom
          ? '2026-06-30'
          : '2026-11-23',
      frequency: option.frequency,
      interval: option.interval,
      endOfMonth: isEom,
      weekdays: option == RecurrenceOption.weekdays ? [1, 3, 5] : const [],
      count: 12,
      mode: ScheduleMode.confirm,
      time: '08:00',
      createdAt: stamp,
    );
    schedules.add(rule);
    if (isMonthly || isEom) {
      for (var n = 0; n < (isMonthly ? 6 : 5); n++) {
        resolve(rule, n, OccurrenceState.posted);
      }
    }
  }
  final installment = ScheduleRule(
    id: 'installment',
    name: 'DEMO Cicilan Laptop · 6 kali',
    kind: TransactionKind.expense,
    accountId: 'mandiri',
    amount: money('3000000,01'),
    fee: Money.zero,
    category: 'Cicilan',
    note: 'DATA CONTOH — total Rp3.000.000,01 dibagi 6, selisih sen pada cicilan terakhir.',
    startDate: '2026-09-15',
    count: 6,
    installments: true,
    mode: ScheduleMode.confirm,
    time: '09:00',
    createdAt: stamp,
  );
  schedules.add(installment);
  for (var n = 0; n < 3; n++) {
    resolve(installment, n, OccurrenceState.posted);
  }
  final automatic = ScheduleRule(
    id: 'automatic-history',
    name: 'DEMO Otomatis · selesai',
    kind: TransactionKind.expense,
    accountId: 'doku',
    amount: money('10000'),
    fee: Money.zero,
    category: 'Langganan',
    note: 'DATA CONTOH — mode otomatis dengan batas 3 kejadian, seluruhnya sudah diselesaikan.',
    startDate: '2026-08-01',
    count: 3,
    mode: ScheduleMode.automatic,
    time: '00:05',
    createdAt: stamp,
  );
  schedules.add(automatic);
  resolve(automatic, 0, OccurrenceState.posted);
  resolve(automatic, 1, OccurrenceState.skipped);
  resolve(automatic, 2, OccurrenceState.deleted);
  schedules.add(
    ScheduleRule(
      id: 'salary-schedule',
      name: 'DEMO Gaji · konfirmasi',
      kind: TransactionKind.income,
      accountId: 'mandiri',
      amount: money('10250000'),
      fee: Money.zero,
      category: 'Gaji',
      note: 'DATA CONTOH — pemasukan terjadwal.',
      startDate: '2026-12-01',
      mode: ScheduleMode.confirm,
      time: '08:00',
      createdAt: stamp,
    ),
  );
  schedules.add(
    ScheduleRule(
      id: 'transfer-schedule',
      name: 'DEMO Top up DOKU · dijeda',
      kind: TransactionKind.transfer,
      accountId: 'mandiri',
      destinationId: 'doku',
      amount: money('200000'),
      fee: money('1000'),
      receiverFee: money('500'),
      category: '',
      note: 'DATA CONTOH — transfer berulang dengan dua biaya.',
      startDate: '2026-11-23',
      frequency: RepeatFrequency.weekly,
      mode: ScheduleMode.automatic,
      state: ScheduleState.paused,
      time: '07:30',
      createdAt: stamp,
    ),
  );
  schedules.add(
    ScheduleRule(
      id: 'stopped-schedule',
      name: 'DEMO Langganan · dihentikan',
      kind: TransactionKind.expense,
      accountId: 'doku',
      amount: money('19000'),
      fee: Money.zero,
      category: 'Langganan',
      note: 'DATA CONTOH — contoh status dihentikan dan tanggal berakhir.',
      startDate: '2026-07-31',
      endDate: '2026-12-31',
      monthDay: 31,
      mode: ScheduleMode.confirm,
      state: ScheduleState.stopped,
      createdAt: stamp,
    ),
  );
  schedules.add(
    ScheduleRule(
      id: 'leap-year',
      name: 'DEMO Tahunan · tanggal 29 Februari',
      kind: TransactionKind.expense,
      accountId: 'mandiri',
      amount: money('100000'),
      fee: Money.zero,
      category: 'Pajak & Administrasi',
      note: 'DATA CONTOH — tahun biasa menjadi 28 Februari; tahun kabisat kembali 29.',
      startDate: '2028-02-29',
      frequency: RepeatFrequency.yearly,
      count: 4,
      mode: ScheduleMode.confirm,
      createdAt: stamp,
    ),
  );

  // Real JPEG receipts generated locally for fictional transactions only.
  final receiptImages = <ReceiptImage>[];
  for (var n = 1; n <= 3; n++) {
    receiptImages.add(
      ReceiptImage(
        id: 'demo-receipt-$n',
        data: base64Encode(
          await File('build/demo-fixture-assets/receipt-$n.jpg').readAsBytes(),
        ),
      ),
    );
  }
  tx(
    TransactionKind.expense,
    'debit',
    '275000',
    '2026-11-20',
    'Belanja Bulanan',
    'Contoh transaksi dengan tiga lampiran struk fiktif. Tidak ada data pribadi.',
    time: '17:42',
    images: receiptImages,
  );

  final interestRules = [
    InterestRule(
      id: 'interest-seabank',
      accountId: 'seabank',
      name: 'DEMO Bunga harian · tarif contoh 3%',
      start: '2026-11-01',
      tiers: [InterestTier(Money.zero, decimal('3'))],
      taxPercent: decimal('20'),
    ),
    InterestRule(
      id: 'interest-tiered',
      accountId: 'mandiri',
      name: 'DEMO Bunga bertingkat · bukan tarif resmi bank',
      start: '2026-07-01',
      tiers: [
        InterestTier(Money.zero, decimal('0.5')),
        InterestTier(money('10000000'), decimal('1')),
        InterestTier(money('50000000'), decimal('1.5')),
      ],
      taxPercent: decimal('20'),
      monthly: true,
      progressive: true,
      previousClosing: false,
      daysBasis: 360,
    ),
    InterestRule(
      id: 'interest-old',
      accountId: 'mandiri',
      name: 'DEMO Aturan lama · tidak aktif',
      start: '2026-06-01',
      end: '2026-06-30',
      tiers: [
        InterestTier(Money.zero, decimal('0')),
        InterestTier(money('10000000'), decimal('0.5')),
      ],
      taxPercent: decimal('20'),
      monthly: true,
      daysBasis: 366,
      active: false,
    ),
    InterestRule(
      id: 'interest-auto-history',
      accountId: 'seabank',
      name: 'DEMO Otomatis · periode selesai',
      start: '2026-10-31',
      end: '2026-10-31',
      tiers: [InterestTier(Money.zero, decimal('3'))],
      taxPercent: decimal('20'),
      automatic: true,
    ),
  ];
  final rates = [
    FxRate(currency: 'USD', rate: decimal('16200'), date: '2026-11-20'),
  ];
  final rateHistory = <FxRate>[];
  for (
    var d = DateTime.utc(2026, 6, 1);
    !d.isAfter(DateTime.utc(2026, 11, 19));
    d = d.add(const Duration(days: 1))
  ) {
    rateHistory.add(
      FxRate(
        currency: 'USD',
        rate: decimal(
          '${16000 + d.difference(DateTime.utc(2026, 6, 1)).inDays % 200}',
        ),
        date: localDate(d),
      ),
    );
  }
  final extras = FinanceExtras(
    instruments: instruments,
    events: events,
    quotes: quotes,
    rates: rates,
    rateHistory: rateHistory,
    stakingPlans: plans,
    interestRules: interestRules,
    catalogInfo: {
      'file': 'Daftar Saham  - 20261118.xlsx',
      'sheet': 'Sheet1',
      'imported_at': stamp,
      'source_as_of': '2026-11-18',
    },
  );
  LedgerSnapshot snapshot(List<InterestPosting> postings) => LedgerSnapshot(
    accounts: accounts,
    transactions: transactions,
    schedules: schedules,
    occurrences: occurrences,
    cards: cards,
    theme: 'dark',
    extras: extras.copy(interestPostings: postings),
  );
  // Use the production engine, one day at a time, so daily compounding is genuine.
  final postings = <InterestPosting>[
    InterestPosting(
      ruleId: 'interest-old',
      start: '2026-06-01',
      end: '2026-06-30',
      date: '2026-06-30',
      gross: money('7500'),
      tax: money('1500'),
      idrRate: Decimal.one,
    ),
  ];
  for (
    var d = DateTime.utc(2026, 7, 1);
    !d.isAfter(DateTime.utc(2026, 11, 21));
    d = d.add(const Duration(days: 1))
  ) {
    for (final posting in InterestEngine.pending(
      snapshot(postings),
      d,
      maxPerRule: 366,
    )) {
      postings.add(
        InterestPosting(
          ruleId: posting.ruleId,
          start: posting.start,
          end: posting.end,
          date: posting.date,
          gross: posting.gross,
          tax: posting.tax,
          idrRate: posting.idrRate,
          voided:
              posting.ruleId == 'interest-seabank' &&
              posting.start == '2026-11-05',
        ),
      );
    }
  }
  final result = snapshot(postings);
  final backup = BackupService();
  final bytes = backup.encode(result);
  final decoded = await backup.decode(bytes);
  final chart = AnalyticsService().history(decoded, asOf, days: 174);
  if (chart.last.combined == null) {
    throw StateError('Demo chart has missing valuation.');
  }
  await File(demoPath).writeAsBytes(bytes, flush: true);
  stdout.writeln(
    jsonEncode({
      'file': demoPath,
      'bytes': bytes.length,
      'accounts': accounts.length,
      'transactions': transactions.length,
      'investment_events': events.length,
      'instruments': instruments.length,
      'quotes': quotes.length,
      'schedules': schedules.length,
      'occurrences': occurrences.length,
      'staking_plans': plans.length,
      'interest_rules': interestRules.length,
      'interest_postings': postings.length,
      'attachments': receiptImages.length,
      'investment_kinds': events.map((e) => e.kind.name).toSet().toList(),
      'chart_points': chart.length,
      'net_worth': decoded.netWorth.formatted,
    }),
  );
}
