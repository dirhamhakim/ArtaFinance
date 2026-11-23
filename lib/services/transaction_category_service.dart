import '../models/ledger.dart';
import '../models/transaction_category.dart';

/// Preserve legacy names while the catalog is introduced without rewriting money.
abstract final class TransactionCategoryService {
  static const income = [
    'Gaji',
    'Bonus',
    'Freelance',
    'Usaha',
    'Hadiah',
    'Cashback',
    'Bunga',
    'Dividen',
    'Penjualan',
    'Pemasukan Lainnya',
  ];
  static const expense = [
    'Makan & Minum',
    'Belanja Bulanan',
    'Transportasi',
    'Tempat Tinggal',
    'Tagihan',
    'Internet & Pulsa',
    'Kesehatan',
    'Pendidikan',
    'Hiburan',
    'Langganan',
    'Biaya Bank',
    'Pajak & Administrasi',
    'Cicilan',
    'Donasi',
    'Keluarga',
    'Pengeluaran Lainnya',
  ];

  static List<TransactionCategory> all(LedgerSnapshot data) {
    final values = {
      for (final v in data.extras.categories ?? <TransactionCategory>[])
        v.key: v,
    };
    for (final kind in [TransactionKind.income, TransactionKind.expense]) {
      for (final name in [
        ...data.transactions
            .where((t) => t.kind == kind)
            .map((t) => t.category),
        ...data.schedules.where((s) => s.kind == kind).map((s) => s.category),
        if (data.extras.categories == null)
          ...(kind == TransactionKind.income ? income : expense),
      ]) {
        final text = name.trim();
        if (text.isEmpty) continue;
        final key = categoryKey(kind, text);
        values.putIfAbsent(
          key,
          () => TransactionCategory(id: 'legacy:$key', kind: kind, name: text),
        );
      }
    }
    return values.values.toList()..sort((a, b) => a.key.compareTo(b.key));
  }

  static List<String> options(LedgerSnapshot data, TransactionKind kind) =>
      all(data)
          .where((v) => v.kind == kind && !v.archived)
          .map((v) => v.name)
          .toList();

  static bool isArchived(
    LedgerSnapshot data,
    TransactionKind kind,
    String name,
  ) => all(data).any((v) => v.key == categoryKey(kind, name) && v.archived);
}
