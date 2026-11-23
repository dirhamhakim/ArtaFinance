import 'package:arta/models/ledger.dart';
import 'package:arta/models/money.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures.dart';

void main() {
  test('nominal Indonesia, desimal dan nominal besar tetap presisi', () {
    expect((Money.input('0,10') + Money.input('0,20')).input, '0,30');
    expect(Money.input('-10.000,5').formatted, '-Rp 10.000,50');
    final value = Money.input('999999999999999999999999,99');
    expect(Money.stored(value.stored), value);
    expect((value + Money.input('0,01')).input, '1000000000000000000000000');
    for (final invalid in [
      '1.00',
      '1,234',
      '1e10',
      'NaN',
      '',
      '--1',
      '1,000.00',
    ]) {
      expect(() => Money.input(invalid), throwsFormatException);
    }
  });
  test('saldo awal dan transfer bukan pemasukan; biaya adalah pengeluaran', () {
    final snapshot = LedgerSnapshot(
      accounts: [account('bank', '1000'), account('wallet', '-50')],
      transactions: [
        transaction(
          kind: TransactionKind.transfer,
          destination: 'wallet',
          amount: '200',
          fee: '5,50',
        ),
      ],
    );
    snapshot.validate();
    expect(snapshot.balance('bank'), Money.input('794,50'));
    expect(snapshot.balance('wallet'), Money.input('150'));
    expect(snapshot.total, Money.input('944,50'));
    expect(snapshot.incomeForMonth('2026-11'), Money.zero);
    expect(snapshot.expenseForMonth('2026-11'), Money.input('5,50'));
    expect(snapshot.expenseForMonth('2026-10'), Money.zero);
  });
  test('pengeluaran melebihi saldo tetap boleh', () {
    final snapshot = LedgerSnapshot(
      accounts: [account('bank', '0')],
      transactions: [transaction(amount: '5500')],
    );
    snapshot.validate();
    expect(snapshot.balance('bank'), Money.input('-5500'));
  });
  test('tanggal rusak, aset sama, biaya minus dan kategori kosong ditolak', () {
    expect(() => validateDate('2026-02-30'), throwsFormatException);
    expect(
      () => transaction(
        kind: TransactionKind.transfer,
        destination: 'bank',
      ).validate(),
      throwsFormatException,
    );
    expect(
      () => transaction(
        kind: TransactionKind.transfer,
        destination: 'other',
        fee: '-1',
      ).validate(),
      throwsFormatException,
    );
    expect(
      () => LedgerTransaction.fromJson({
        ...transaction().toJson(),
        'category': '',
      }),
      throwsFormatException,
    );
  });
}
