import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:arta/database/app_database.dart';
import 'package:arta/repositories/finance_repository.dart';
import 'package:arta/models/ledger.dart';
import 'package:arta/models/money.dart';
import 'package:arta/models/decimal.dart';
import 'package:arta/models/investment.dart';
import 'package:arta/services/backup_service.dart';
import 'package:arta/models/schedule.dart';

import '../fixtures.dart';

Instrument stock() => Instrument(
  id: 'idx:BBCA',
  code: 'BBCA',
  name: 'Bank Central Asia',
  kind: InstrumentKind.stock,
  providerId: 'BBCA.JK',
);
Instrument bitcoin() => Instrument(
  id: 'cg:bitcoin',
  code: 'BTC',
  name: 'Bitcoin',
  kind: InstrumentKind.crypto,
  providerId: 'bitcoin',
);
InvestmentEvent event(
  String id, {
  String instrument = 'idx:BBCA',
  String account = 'broker',
  String? destination,
  InvestmentKind kind = InvestmentKind.buy,
  String qty = '100',
  String gross = '900000',
  String fee = '0',
  String unitFee = '0',
  String rate = '1',
  String date = '2026-11-01',
  bool unknown = false,
}) => InvestmentEvent(
  id: id,
  instrumentId: instrument,
  accountId: account,
  kind: kind,
  quantity: Decimal.parse(qty),
  gross: Money.input(gross),
  fee: Money.input(fee),
  idrRate: Decimal.parse(rate),
  date: date,
  createdAt: '${date}T01:00:00.000Z',
  destinationId: destination,
  unitFee: Decimal.parse(unitFee),
  unknownCost: unknown,
);

void main() {
  late AppDatabase db;
  late FinanceRepository repo;
  setUp(() async {
    db = AppDatabase.memory();
    repo = FinanceRepository(db);
    await repo.addAccount(account('bank', '2000000'));
    await repo.addAccount(account('broker', '0'));
    await repo.addAccount(account('wallet', '0'));
    await repo.saveInstrument(stock());
    await repo.saveInstrument(bitcoin());
  });
  tearDown(() => db.close());
  test(
    'jadwal asing tanpa kurs menunggu; sesudah kurs diisi tercatat sekali',
    () async {
      await repo.addAccount(
        Account(
          id: 'usd',
          name: 'USD',
          kind: AccountKind.cash,
          opening: Money.zero,
          createdAt: '2026-11-01T00:00:00Z',
          currency: 'USD',
        ),
      );
      await repo.saveSchedule(
        schedule(
          id: 'foreign',
          source: 'usd',
          start: '2026-11-01',
          amount: '10',
          count: 1,
          mode: ScheduleMode.automatic,
        ),
      );
      await repo.processAutomatic(DateTime.utc(2026, 11, 19));
      expect((await repo.load()).transactions, isEmpty);
      await repo.saveRate(
        FxRate(
          currency: 'USD',
          rate: Decimal.parse('16000'),
          date: '2026-11-19',
        ),
      );
      await repo.processAutomatic(DateTime.utc(2026, 11, 19));
      await repo.processAutomatic(DateTime.utc(2026, 11, 19));
      final s = await repo.load();
      expect(s.transactions.length, 1);
      expect(s.balance('usd'), Money.input('-10'));
      expect(s.expenseForMonth('2026-11'), Money.input('160000'));
    },
  );
  test(
    'pinjaman, cicilan pokok dan belanja kredit tidak menggandakan laporan',
    () async {
      await repo.addAccount(
        Account(
          id: 'loan',
          name: 'Pinjaman',
          kind: AccountKind.liability,
          opening: Money.zero,
          createdAt: '2026-11-01T00:00:00Z',
        ),
      );
      await repo.saveTransaction(
        transaction(
          id: 'borrow',
          source: 'loan',
          destination: 'bank',
          kind: TransactionKind.transfer,
          amount: '100000',
        ),
      );
      expect((await repo.load()).total, Money.input('2000000'));
      await repo.saveTransaction(
        transaction(
          id: 'repay',
          source: 'bank',
          destination: 'loan',
          kind: TransactionKind.transfer,
          amount: '40000',
          fee: '1000',
        ),
      );
      await repo.saveTransaction(
        transaction(id: 'purchase', source: 'loan', amount: '50000'),
      );
      final s = await repo.load();
      expect(s.balance('loan'), Money.input('-110000'));
      expect(s.total, Money.input('1949000'));
      expect(s.incomeForMonth('2026-11'), Money.zero);
      expect(s.expenseForMonth('2026-11'), Money.input('51000'));
    },
  );
  test('memberi dan menerima kembali piutang hanya memindahkan aset', () async {
    await repo.addAccount(
      Account(
        id: 'claim',
        name: 'Piutang',
        kind: AccountKind.receivable,
        opening: Money.zero,
        createdAt: '2026-11-01T00:00:00Z',
      ),
    );
    await repo.saveTransaction(
      transaction(
        id: 'lend',
        source: 'bank',
        destination: 'claim',
        kind: TransactionKind.transfer,
        amount: '80000',
      ),
    );
    await repo.saveTransaction(
      transaction(
        id: 'collect',
        source: 'claim',
        destination: 'bank',
        kind: TransactionKind.transfer,
        amount: '30000',
      ),
    );
    final s = await repo.load();
    expect(s.balance('claim'), Money.input('50000'));
    expect(s.total, Money.input('2000000'));
    expect(s.incomeForMonth('2026-11'), Money.zero);
    expect(s.expenseForMonth('2026-11'), Money.zero);
  });
  test(
    'bank → broker → beli → jual: aset tidak ganda dan beli bukan konsumsi',
    () async {
      await repo.saveTransaction(
        transaction(
          id: 'fund',
          source: 'bank',
          destination: 'broker',
          kind: TransactionKind.transfer,
          amount: '1000000',
          date: '2026-11-01',
        ),
      );
      await repo.saveInvestment(event('buy', fee: '2000'));
      await repo.saveQuotes([
        PriceQuote(
          instrumentId: 'idx:BBCA',
          price: Decimal.parse('9000'),
          currency: 'IDR',
          date: '2026-11-01',
          fetchedAt: '2026-11-01T11:00:00Z',
          source: 'Manual',
        ),
      ]);
      var s = await repo.load();
      expect(s.balance('broker'), Money.input('98000'));
      expect(s.netWorth, Money.input('1998000'));
      expect(s.expenseForMonth('2026-11'), Money.input('2000'));
      expect(s.extras.holdings.single.cost, Money.input('902000'));
      await repo.saveInvestment(
        event(
          'sell',
          kind: InvestmentKind.sell,
          qty: '50',
          gross: '500000',
          fee: '1000',
          date: '2026-11-02',
        ),
      );
      s = await repo.load();
      expect(s.balance('broker'), Money.input('597000'));
      expect(s.extras.holdings.single.quantity, Decimal.parse('50'));
      expect(s.extras.holdings.single.cost, Money.input('451000'));
      expect(s.extras.holdings.single.realized, Money.input('48000'));
      expect(s.netWorth, Money.input('2047000'));
      expect(s.incomeForMonth('2026-11'), Money.zero);
    },
  );
  test(
    'pindah crypto membawa modal; biaya jaringan mengurangi unit asal',
    () async {
      await repo.saveInvestment(
        event('buy', instrument: 'cg:bitcoin', qty: '1', gross: '1000000'),
      );
      await repo.saveInvestment(
        event(
          'send',
          instrument: 'cg:bitcoin',
          kind: InvestmentKind.transfer,
          qty: '0.4',
          gross: '0',
          unitFee: '0.01',
          destination: 'wallet',
          date: '2026-11-02',
        ),
      );
      final s = await repo.load();
      final origin = s.extras.holdings.firstWhere(
            (h) => h.accountId == 'broker',
          ),
          dest = s.extras.holdings.firstWhere((h) => h.accountId == 'wallet');
      expect(origin.quantity, Decimal.parse('0.59'));
      expect(origin.cost, Money.input('590000'));
      expect(dest.quantity, Decimal.parse('0.4'));
      expect(dest.cost, Money.input('400000'));
      expect(s.balance('broker'), Money.input('-1000000'));
    },
  );
  test(
    'jual/edit/hapus pembelian yang merusak unit historis rollback atomik',
    () async {
      await repo.saveInvestment(event('buy'));
      await expectLater(
        repo.saveInvestment(
          event(
            'too-much',
            kind: InvestmentKind.sell,
            qty: '101',
            date: '2026-11-02',
          ),
        ),
        throwsFormatException,
      );
      await repo.saveInvestment(
        event(
          'sell',
          kind: InvestmentKind.sell,
          qty: '50',
          gross: '500000',
          date: '2026-11-02',
        ),
      );
      await expectLater(repo.deleteInvestment('buy'), throwsFormatException);
      await expectLater(
        repo.saveInvestment(event('buy', qty: '10')),
        throwsFormatException,
      );
      final s = await repo.load();
      expect(s.extras.events.length, 2);
      expect(s.extras.holdings.single.quantity, Decimal.parse('50'));
    },
  );
  test(
    'dividen tidak mengubah unit, reward dan split tidak mengubah kas',
    () async {
      await repo.saveInvestment(
        event('open', kind: InvestmentKind.opening, gross: '800000'),
      );
      await repo.saveInvestment(
        event(
          'div',
          kind: InvestmentKind.dividend,
          qty: '0',
          gross: '20000',
          fee: '2000',
          date: '2026-11-02',
        ),
      );
      await repo.saveInvestment(
        event(
          'reward',
          kind: InvestmentKind.reward,
          qty: '10',
          gross: '0',
          date: '2026-11-03',
        ),
      );
      await repo.saveInvestment(
        event(
          'split',
          kind: InvestmentKind.split,
          qty: '2',
          gross: '0',
          date: '2026-11-04',
        ),
      );
      final s = await repo.load();
      expect(s.balance('broker'), Money.input('18000'));
      expect(s.extras.holdings.single.quantity, Decimal.parse('220'));
      expect(s.extras.holdings.single.cost, Money.input('800000'));
      expect(s.incomeForMonth('2026-11'), Money.input('20000'));
      expect(s.expenseForMonth('2026-11'), Money.input('2000'));
    },
  );
  test(
    'modal awal tak diketahui tidak dilaporkan sebagai laba penuh',
    () async {
      await repo.saveInvestment(
        event('open', kind: InvestmentKind.opening, gross: '0', unknown: true),
      );
      await repo.saveInvestment(
        event(
          'sell',
          kind: InvestmentKind.sell,
          qty: '50',
          gross: '500000',
          date: '2026-11-02',
        ),
      );
      final s = await repo.load();
      expect(s.extras.holdings.single.cost, isNull);
      expect(s.extras.holdings.single.realized, isNull);
    },
  );
  test(
    'saham menolak pecahan lembar; reksadana menerima unit 12 desimal',
    () async {
      await expectLater(
        repo.saveInvestment(event('bad', qty: '0.1')),
        throwsFormatException,
      );
      await repo.saveInstrument(
        Instrument(
          id: 'bibit:fund',
          code: 'RDPU',
          name: 'RDPU manual',
          kind: InstrumentKind.fund,
        ),
      );
      await repo.saveInvestment(
        event(
          'fund',
          instrument: 'bibit:fund',
          qty: '123.456789012345',
          gross: '150000',
        ),
      );
      expect(
        (await repo.load()).extras.holdings.single.quantity.text,
        '123.456789012345',
      );
    },
  );
  test(
    'kurs historis tetap, kurs valuasi berubah, transfer lintas uang eksplisit',
    () async {
      await repo.addAccount(
        Account(
          id: 'usd',
          name: 'USDT',
          kind: AccountKind.exchange,
          opening: Money.zero,
          createdAt: '2026-11-01T00:00:00Z',
          currency: 'USDT',
        ),
      );
      await repo.saveRate(
        FxRate(
          currency: 'USDT',
          rate: Decimal.parse('16000'),
          date: '2026-11-01',
        ),
      );
      final raw = transaction(
        id: 'fx',
        source: 'bank',
        destination: 'usd',
        kind: TransactionKind.transfer,
        amount: '1600000',
        fee: '1000',
        date: '2026-11-01',
      ).toJson();
      await expectLater(
        repo.saveTransaction(LedgerTransaction.fromJson(raw)),
        throwsFormatException,
      );
      await repo.saveTransaction(
        LedgerTransaction.fromJson({
          ...raw,
          'destination_minor': Money.input('100').stored,
          'idr_rate': '1',
        }),
      );
      await repo.saveInvestment(
        event(
          'buy-usdt',
          instrument: 'cg:bitcoin',
          account: 'usd',
          qty: '0.001',
          gross: '10',
          fee: '1',
          rate: '16000',
        ),
      );
      await repo.saveRate(
        FxRate(
          currency: 'USDT',
          rate: Decimal.parse('17000'),
          date: '2026-11-02',
        ),
      );
      final s = await repo.load();
      expect(s.balance('usd'), Money.input('89'));
      expect(s.extras.holdings.single.cost, Money.input('176000'));
      expect(s.expenseForMonth('2026-11'), Money.input('17000'));
      expect(s.total, Money.input('1912000'));
    },
  );
  test('aset tanpa kurs dan posisi tanpa harga tidak dianggap 1:1/bernilai nol lengkap', () async {
    await repo.addAccount(
      Account(
        id: 'usd',
        name: 'USD',
        kind: AccountKind.cash,
        opening: Money.input('10'),
        createdAt: '2026-11-01T00:00:00Z',
        currency: 'USD',
      ),
    );
    await repo.saveInvestment(
      event('open', kind: InvestmentKind.opening, gross: '100'),
    );
    final s = await repo.load();
    expect(s.missingFxCount, 1);
    expect(s.unpricedHoldings, 1);
    expect(s.total, Money.input('2000000'));
  });
  test('backup terbaru memulihkan seluruh investasi/kurs; JSON tak valid tidak menyentuh data', () async {
    await repo.saveInvestment(event('buy'));
    final bytes = BackupService().encode(await repo.load());
    final parsed = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    expect(parsed['schema_version'], 6);
    final restored = await BackupService().decode(bytes);
    await repo.replace(restored);
    expect((await repo.load()).extras.events.single.id, 'buy');
    parsed['extras']['events'][0]['quantity'] = '-1';
    await expectLater(
      BackupService().decode(
        Uint8List.fromList(utf8.encode(jsonEncode(parsed))),
      ),
      throwsFormatException,
    );
    expect((await repo.load()).extras.events.single.quantity.text, '100');
  });
  test('backup v3 tetap dapat diimpor tanpa data extras', () async {
    final bytes = BackupService().encode(await repo.load());
    final j = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    j['schema_version'] = 3;
    j.remove('extras');
    final old = await BackupService().decode(
      Uint8List.fromList(utf8.encode(jsonEncode(j))),
    );
    expect(old.extras.instruments, isEmpty);
  });
  test('satu cache harian diperbarui tanpa mengubah beli historis', () async {
    await repo.saveInvestment(event('buy'));
    PriceQuote q(String price, String stamp) => PriceQuote(
      instrumentId: 'idx:BBCA',
      price: Decimal.parse(price),
      currency: 'IDR',
      date: '2026-11-01',
      fetchedAt: stamp,
      source: 'Manual',
    );
    await repo.saveQuotes([q('9000', '2026-11-01T11:00:00Z')]);
    await repo.saveQuotes([q('9100', '2026-11-01T12:00:00Z')]);
    final s = await repo.load();
    expect(s.extras.quotes.length, 1);
    expect(s.extras.events.single.gross, Money.input('900000'));
    expect(s.investmentValue, Money.input('910000'));
  });
}
