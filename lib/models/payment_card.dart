import 'ledger.dart';

/// Kartu debit adalah metode pembayaran, bukan aset bersaldo kedua.
final class PaymentCard {
  const PaymentCard({
    required this.id,
    required this.name,
    required this.accountId,
    required this.createdAt,
  });
  final String id, name, accountId, createdAt;
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'account_id': accountId,
    'created_at': createdAt,
  };
  factory PaymentCard.fromJson(Map<String, Object?> json) {
    exactKeys(json, {'id', 'name', 'account_id', 'created_at'});
    final name = stringField(json, 'name');
    final created = stringField(json, 'created_at');
    if (name.length > 80 || DateTime.tryParse(created)?.isUtc != true) {
      throw const FormatException('Nama atau waktu kartu tidak valid.');
    }
    return PaymentCard(
      id: stringField(json, 'id'),
      name: name,
      accountId: stringField(json, 'account_id'),
      createdAt: created,
    );
  }
}
