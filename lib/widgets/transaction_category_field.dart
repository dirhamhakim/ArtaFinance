import 'package:material_ui/material_ui.dart';

import '../models/ledger.dart';
import '../services/transaction_category_service.dart';
import 'arta_icon.dart';

class TransactionCategoryField extends StatelessWidget {
  const TransactionCategoryField({
    super.key,
    required this.controller,
    required this.data,
    required this.kind,
    this.enabled = true,
    this.originalCategory,
  });
  final TextEditingController controller;
  final LedgerSnapshot data;
  final TransactionKind kind;
  final bool enabled;
  final String? originalCategory;

  Future<void> choose(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final choice = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CategorySheet(
        title: kind == TransactionKind.income
            ? 'Kategori pemasukan'
            : 'Kategori pengeluaran',
        values: TransactionCategoryService.options(data, kind),
        selected: controller.text,
      ),
    );
    if (choice != null) controller.text = choice;
  }

  @override
  Widget build(BuildContext context) => TextFormField(
    key: const Key('transaction-category'),
    controller: controller,
    enabled: enabled,
    maxLength: 80,
    textCapitalization: TextCapitalization.sentences,
    decoration: InputDecoration(
      labelText: kind == TransactionKind.income
          ? 'Kategori pemasukan'
          : 'Kategori pengeluaran',
      hintText: 'Pilih atau ketik kategori',
      helperText: 'Kelola kategori di Pengaturan → Kategori. Kategori baru tersimpan setelah transaksi disimpan.',
      helperMaxLines: 2,
      suffixIcon: IconButton(
        key: const Key('choose-transaction-category'),
        tooltip: 'Pilih kategori',
        onPressed: enabled ? () => choose(context) : null,
        icon: const DesignGlyph('chevron-down'),
      ),
    ),
    validator: (v) {
      if (v == null || v.trim().isEmpty) return 'Isi kategori.';
      if (TransactionCategoryService.isArchived(data, kind, v) &&
          v.trim().toLowerCase() != originalCategory?.trim().toLowerCase()) {
        return 'Kategori diarsipkan. Aktifkan kembali di Pengaturan.';
      }
      return null;
    },
  );
}

class _CategorySheet extends StatefulWidget {
  const _CategorySheet({
    required this.title,
    required this.values,
    required this.selected,
  });
  final String title, selected;
  final List<String> values;
  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  String search = '';
  @override
  Widget build(BuildContext context) {
    final query = search.trim();
    final filtered = widget.values
        .where((v) => v.toLowerCase().contains(query.toLowerCase()))
        .toList();
    final custom =
        query.isNotEmpty &&
        !widget.values.any((v) => v.toLowerCase() == query.toLowerCase());
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .65,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.pop(context),
                    icon: const DesignGlyph('close'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                key: const Key('category-search'),
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Cari atau buat kategori',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => search = v),
              ),
            ),
            if (custom)
              ListTile(
                title: Text('Gunakan "$query"'),
                leading: const DesignGlyph('plus'),
                onTap: () => Navigator.pop(context, query),
              ),
            for (final value in filtered)
              ListTile(
                title: Text(value),
                selected:
                    value.toLowerCase() == widget.selected.trim().toLowerCase(),
                trailing:
                    value.toLowerCase() == widget.selected.trim().toLowerCase()
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(context, value),
              ),
          ],
        ),
      ),
    );
  }
}
