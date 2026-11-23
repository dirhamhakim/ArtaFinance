import 'package:flutter_test/flutter_test.dart';
import 'package:arta/database/app_database.dart';
import 'package:arta/repositories/finance_repository.dart';
import 'package:arta/models/decimal.dart';
import 'package:arta/models/interest.dart';
import 'package:arta/models/money.dart';
import 'package:arta/services/interest_engine.dart';
import 'package:arta/services/backup_service.dart';

import '../fixtures.dart';

InterestRule rule({
  String id = 'interest',
  String start = '2026-11-01',
  String? end,
  bool automatic = false,
  bool monthly = false,
  bool progressive = false,
  List<InterestTier>? tiers,
}) => InterestRule(
  id: id,
  accountId: 'bank',
  name: 'Bunga pengguna',
  start: start,
  end: end,
  tiers: tiers ?? [InterestTier(Money.zero, Decimal.parse('3.65'))],
  taxPercent: Decimal.parse('20'),
  monthly: monthly,
  progressive: progressive,
  automatic: automatic,
);
void main() {
  late AppDatabase db;
  late FinanceRepository repo;
  setUp(() async {
    db = AppDatabase.memory();
    repo = FinanceRepository(db);
    await repo.addAccount(account('bank', '1000000'));
  });
  tearDown(() => db.close());
  test(
    'riwayat bunga panjang diproses bertahap tanpa memblokir startup',
    () async {
      final old = InterestRule.fromJson({
        ...rule(start: '2000-01-01', automatic: true).toJson(),
        'tiers': [InterestTier(Money.zero, Decimal.zero).toJson()],
      });
      await repo.saveInterestRule(old);
      await repo.processInterest(DateTime.utc(2026, 11, 19));
      expect((await repo.load()).extras.interestPostings.length, 100);
      await repo.processInterest(DateTime.utc(2026, 11, 19));
      expect((await repo.load()).extras.interestPostings.length, 200);
      expect((await repo.load()).balance('bank'), Money.input('1000000'));
    },
  );
  test('tarif seluruh saldo dan progresif berbeda sesuai tier', () {
    final tiers = [
      InterestTier(Money.zero, Decimal.parse('3.65')),
      InterestTier(Money.input('1000000'), Decimal.parse('7.3')),
    ];
    final whole = InterestEngine.daily(
      rule(tiers: tiers),
      Money.input('1500000'),
    );
    final progressive = InterestEngine.daily(
      rule(tiers: tiers, progressive: true),
      Money.input('1500000'),
    );
    expect(Money(roundRatio(whole.raw, Decimal.scale)), Money.input('300'));
    expect(
      Money(roundRatio(progressive.raw, Decimal.scale)),
      Money.input('200'),
    );
    expect(InterestEngine.daily(rule(), Money.input('-1000')).isZero, isTrue);
  });
  test(
    'estimasi belum mengubah saldo; bruto/pajak/neto dicatat satu kali',
    () async {
      await repo.saveInterestRule(rule());
      final now = DateTime.utc(2026, 11, 2);
      var s = await repo.load();
      final pending = InterestEngine.pending(s, now);
      expect(pending.length, 1);
      expect(s.balance('bank'), Money.input('1000000'));
      expect(pending.single.gross, Money.input('100'));
      expect(pending.single.tax, Money.input('20'));
      expect(await repo.postInterest(pending.single), isTrue);
      expect(await repo.postInterest(pending.single), isFalse);
      s = await repo.load();
      expect(s.balance('bank'), Money.input('1000080'));
      expect(s.incomeForMonth('2026-11'), Money.input('100'));
      expect(s.expenseForMonth('2026-11'), Money.input('20'));
    },
  );
  test(
    'otomatis harian memakai bunga aktual sebelumnya, proses ulang idempoten',
    () async {
      await repo.saveInterestRule(rule(automatic: true));
      await repo.processInterest(DateTime.utc(2026, 11, 3));
      var s = await repo.load();
      expect(s.extras.interestPostings.length, 2);
      expect(s.extras.interestPostings.last.gross, Money.input('100,01'));
      expect(s.balance('bank'), Money.input('1000160,01'));
      await repo.processInterest(DateTime.utc(2026, 11, 3));
      s = await repo.load();
      expect(s.extras.interestPostings.length, 2);
    },
  );
  test(
    'kredit bulanan menunggu akhir bulan, termasuk Februari kabisat',
    () async {
      await repo.saveInterestRule(rule(start: '2024-02-01', monthly: true));
      expect(
        InterestEngine.pending(await repo.load(), DateTime.utc(2024, 2, 29)),
        isEmpty,
      );
      final p = InterestEngine.pending(
        await repo.load(),
        DateTime.utc(2024, 3, 1),
      ).single;
      expect(p.start, '2024-02-01');
      expect(p.end, '2024-02-29');
      expect(p.gross, Money.input('2900'));
      await repo.postInterest(p);
      expect((await repo.load()).balance('bank'), Money.input('1002320'));
    },
  );
  test('perubahan riwayat mengubah estimasi, tidak menulis ulang bunga terkonfirmasi', () async {
    await repo.saveInterestRule(rule());
    final p = InterestEngine.pending(
      await repo.load(),
      DateTime.utc(2026, 11, 2),
    ).single;
    await repo.postInterest(
      InterestPosting.fromJson({
        ...p.toJson(),
        'gross_minor': Money.input('120').stored,
        'tax_minor': Money.input('24').stored,
      }),
    );
    await repo.saveTransaction(
      transaction(id: 'earlier', amount: '500000', date: '2026-11-01'),
    );
    final s = await repo.load();
    expect(s.extras.interestPostings.single.gross, Money.input('120'));
    final future = InterestEngine.pending(s, DateTime.utc(2026, 11, 3)).single;
    expect(future.gross, Money.input('50,01'));
  });
  test('pembatalan mempertahankan penanda agar tidak tercatat ulang setelah restore', () async {
    await repo.saveInterestRule(rule(automatic: true, end: '2026-11-01'));
    await repo.processInterest(DateTime.utc(2026, 11, 2));
    final id = (await repo.load()).extras.interestPostings.single.id;
    await repo.voidInterest(id);
    final restored = await BackupService().decode(
      BackupService().encode(await repo.load()),
    );
    await repo.replace(restored);
    await repo.processInterest(DateTime.utc(2026, 11, 3));
    final s = await repo.load();
    expect(s.extras.interestPostings.single.voided, isTrue);
    expect(s.balance('bank'), Money.input('1000000'));
  });
  test(
    'aturan aktif yang tumpang tindih dan periode palsu ditolak atomik',
    () async {
      await repo.saveInterestRule(rule());
      await expectLater(
        repo.saveInterestRule(rule(id: 'second')),
        throwsFormatException,
      );
      final p = InterestEngine.pending(
        await repo.load(),
        DateTime.utc(2026, 11, 2),
      ).single;
      await expectLater(
        repo.postInterest(
          InterestPosting.fromJson({...p.toJson(), 'start': '2026-10-31'}),
        ),
        throwsFormatException,
      );
      expect((await repo.load()).extras.interestPostings, isEmpty);
      expect((await repo.load()).extras.interestRules.length, 1);
    },
  );
  test('basis 360/366 dan tarif batas inklusif divalidasi', () {
    final r = InterestRule.fromJson({...rule().toJson(), 'days_basis': 360});
    final amount = Money(
      roundRatio(
        InterestEngine.daily(r, Money.input('1000000')).raw,
        Decimal.scale,
      ),
    );
    expect(amount, Money.input('101,39'));
    expect(
      () => InterestRule.fromJson({...rule().toJson(), 'tax_percent': '101'}),
      throwsFormatException,
    );
    expect(
      () => InterestRule.fromJson({...rule().toJson(), 'days_basis': 0}),
      throwsFormatException,
    );
  });
}
