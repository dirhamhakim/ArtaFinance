import 'package:feather_icons/feather_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../controllers/finance_controller.dart';
import '../models/ledger.dart';
import '../models/transaction_category.dart';
import '../services/transaction_category_service.dart';
import '../widgets/arta_icon.dart';
import '../widgets/finance_dialog.dart';
import '../widgets/finance_fields.dart';
import '../widgets/finance_surfaces.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key, required this.controller});
  final FinanceController controller;
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  TransactionKind kind = TransactionKind.expense;
  bool archived = false;
  String search = '';
  FinanceController get c => widget.controller;

  Future<void> edit([TransactionCategory? existing]) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final input = TextEditingController(text: existing?.name ?? '');
    final form = GlobalKey<FormState>();
    final entryKind = existing?.kind ?? kind;
    final id = existing?.id ?? c.newId();
    bool saving = false;
    String? issue;
    try {
      await showFinanceDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, update) => FinanceDialog(
            title: Text(existing == null ? 'Tambah kategori' : 'Ubah kategori'),
            content: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transactionLabel(entryKind)),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('category-name'),
                    controller: input,
                    enabled: !saving,
                    maxLength: 80,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Nama kategori',
                    ),
                    validator: (v) {
                      final name = v?.trim() ?? '';
                      if (name.isEmpty) return 'Isi nama kategori.';
                      if (name.length > 80) return 'Maksimal 80 karakter.';
                      if (TransactionCategoryService.all(c.snapshot).any(
                        (v) =>
                            v.id != id && v.key == categoryKey(entryKind, name),
                      )) {
                        return 'Nama sudah ada, termasuk di arsip.';
                      }
                      return null;
                    },
                  ),
                  if (existing != null)
                    const Text(
                      'Nama pada seluruh transaksi dan jadwal kategori ini ikut diperbarui. Nominal dan tanggal tetap sama.',
                    ),
                  if (issue != null)
                    Text(
                      issue!,
                      style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              FilledButton(
                key: const Key('save-category'),
                onPressed: saving
                    ? null
                    : () async {
                        if (!form.currentState!.validate()) return;
                        update(() {
                          saving = true;
                          issue = null;
                        });
                        final ok = await c.saveCategory(
                          TransactionCategory(
                            id: id,
                            kind: entryKind,
                            name: input.text.trim(),
                            archived: existing?.archived ?? false,
                          ),
                          edit: existing != null,
                        );
                        if (!ctx.mounted) return;
                        if (ok) {
                          Navigator.pop(ctx);
                        } else {
                          update(() {
                            saving = false;
                            issue = c.error;
                          });
                        }
                      },
                child: Text(saving ? 'Menyimpan…' : 'Simpan'),
              ),
            ],
          ),
        ),
      );
    } finally {
      input.dispose();
    }
  }

  Future<void> toggleArchive(TransactionCategory category) async {
    final yes = await showFinanceDialog<bool>(
      context: context,
      builder: (ctx) => FinanceDialog(
        title: Text(
          category.archived ? 'Aktifkan kategori?' : 'Arsipkan kategori?',
        ),
        content: Text(
          category.archived
              ? '“${category.name}” akan tersedia kembali untuk transaksi baru.'
              : '“${category.name}” disembunyikan dari pilihan baru. Transaksi lama dan jadwal berulang tetap disimpan dan berjalan; jeda jadwal dari menu transaksi berulang bila diperlukan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(category.archived ? 'Aktifkan' : 'Arsipkan'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    final ok = await c.saveCategory(
      category.copy(archived: !category.archived),
      edit: true,
    );
    if (mounted && !ok) financeMessage(context, c.error!);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: c,
    builder: (context, _) {
      final categories = TransactionCategoryService.all(c.snapshot)
          .where(
            (v) =>
                v.kind == kind &&
                v.archived == archived &&
                v.name.toLowerCase().contains(search.trim().toLowerCase()),
          )
          .toList();
      return Scaffold(
        appBar: AppBar(title: const Text('Kategori')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final value in [
                                TransactionKind.expense,
                                TransactionKind.income,
                              ])
                                ChoiceChip(
                                  key: Key('category-kind-${value.name}'),
                                  label: Text(transactionLabel(value)),
                                  selected: value == kind,
                                  onSelected: c.busy
                                      ? null
                                      : (_) => setState(() => kind = value),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            key: const Key('categories-search'),
                            decoration: const InputDecoration(
                              labelText: 'Cari kategori',
                              prefixIcon: SizedBox(
                                width: 48,
                                child: Center(
                                  child: ArtaIcon(
                                    FeatherIcons.search,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            onChanged: (v) => setState(() => search = v),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              FilterChip(
                                key: const Key('categories-archive-filter'),
                                label: const Text('Arsip'),
                                selected: archived,
                                onSelected: (v) => setState(() => archived = v),
                              ),
                              FilledButton.icon(
                                key: const Key('add-category'),
                                onPressed: c.busy ? null : () => edit(),
                                icon: const DesignGlyph('plus'),
                                label: const Text('Tambah kategori'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (categories.isEmpty)
                    SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            search.trim().isNotEmpty
                                ? 'Tidak ada kategori yang cocok.'
                                : archived
                                ? 'Belum ada kategori diarsipkan.'
                                : 'Belum ada kategori. Tambahkan kategori baru.',
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList.builder(
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final used = c.snapshot.transactions
                              .where(
                                (t) =>
                                    categoryKey(t.kind, t.category) ==
                                    category.key,
                              )
                              .length;
                          final schedules = c.snapshot.schedules
                              .where(
                                (s) =>
                                    categoryKey(s.kind, s.category) ==
                                    category.key,
                              )
                              .length;
                          return Card(
                            child: ListTile(
                              key: ValueKey('category-${category.id}'),
                              leading: FinanceIconBadge(
                                kind == TransactionKind.income
                                    ? FeatherIcons.arrowDownLeft
                                    : FeatherIcons.arrowUpRight,
                              ),
                              title: Text(category.name),
                              subtitle: Text(
                                '$used transaksi · $schedules jadwal${category.archived ? ' · Diarsipkan' : ''}',
                              ),
                              onTap: c.busy ? null : () => edit(category),
                              trailing: IconButton(
                                key: ValueKey(
                                  'archive-category-${category.id}',
                                ),
                                tooltip: category.archived
                                    ? 'Aktifkan kategori'
                                    : 'Arsipkan kategori',
                                icon: ArtaIcon(
                                  category.archived
                                      ? FeatherIcons.rotateCcw
                                      : FeatherIcons.archive,
                                ),
                                onPressed: c.busy
                                    ? null
                                    : () => toggleArchive(category),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
