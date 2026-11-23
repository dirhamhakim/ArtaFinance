import 'ledger.dart';

String categoryKey(TransactionKind kind, String name) =>
    '${kind.name}:${name.trim().toLowerCase()}';

final class TransactionCategory {
  const TransactionCategory({
    required this.id,
    required this.kind,
    required this.name,
    this.archived = false,
  });
  final String id, name;
  final TransactionKind kind;
  final bool archived;
  String get key => categoryKey(kind, name);
  TransactionCategory copy({String? name, bool? archived}) =>
      TransactionCategory(
        id: id,
        kind: kind,
        name: name ?? this.name,
        archived: archived ?? this.archived,
      );
  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'name': name,
    'archived': archived,
  };
  factory TransactionCategory.fromJson(Map<String, Object?> json) {
    exactKeys(json, {'id', 'kind', 'name', 'archived'});
    final kind = TransactionKind.values
        .where((v) => v.name == json['kind'] && v != TransactionKind.transfer)
        .firstOrNull;
    final name = stringField(json, 'name');
    if (kind == null || name != name.trim() || name.length > 80) {
      throw const FormatException(
        'Kategori harus pemasukan/pengeluaran dengan nama 1–80 karakter.',
      );
    }
    return TransactionCategory(
      id: stringField(json, 'id'),
      kind: kind,
      name: name,
      archived: boolField(json, 'archived'),
    );
  }
}
