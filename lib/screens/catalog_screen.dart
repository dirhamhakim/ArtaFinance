import '../widgets/finance_dialog.dart';
import '../widgets/finance_select.dart';
import '../widgets/arta_icon.dart';

import 'package:feather_icons/feather_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../controllers/finance_controller.dart';
import '../models/investment.dart';
import '../models/decimal.dart';
import '../services/catalog_service.dart';
import '../services/data_files_service.dart';
import '../widgets/finance_fields.dart';
import '../widgets/finance_empty_state.dart';

class InstrumentLogo extends StatelessWidget {
  const InstrumentLogo(this.instrument, {super.key});
  final Instrument instrument;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 40,
    height: 40,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: instrument.logoUrl.isEmpty
          ? const ArtaIcon(FeatherIcons.hexagon)
          : Image.network(
              instrument.logoUrl,
              width: 40,
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  instrument.code.substring(
                    0,
                    instrument.code.length < 3 ? instrument.code.length : 3,
                  ),
                ),
              ),
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : const ArtaIcon(FeatherIcons.hexagon),
            ),
    ),
  );
}

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({
    super.key,
    required this.controller,
    this.select = false,
  });
  final FinanceController controller;
  final bool select;
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String query = '';
  InstrumentKind? kind = InstrumentKind.stock;
  int limit = 50;
  bool filesBusy = false;
  FinanceController get c => widget.controller;
  Future<void> import() async {
    if (filesBusy || c.busy) return;
    setState(() => filesBusy = true);
    try {
      final file = await DataFilesService().pick(['xlsx', 'json']);
      if (file == null) return;
      final previews = await parseCatalogInBackground(file.bytes, file.name);
      if (!mounted) return;
      CatalogPreview? selected = previews.first;
      if (previews.length > 1) {
        selected = await showFinanceDialog<CatalogPreview>(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: const Text('Pilih sheet katalog'),
            children: [
              for (final p in previews)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, p),
                  child: Text('${p.sheet} · ${p.rows.length} baris'),
                ),
            ],
          ),
        );
      }
      if (selected == null || !mounted) return;
      final preview = selected;
      final counts = preview.counts(c.snapshot.extras);
      final accept = await showFinanceDialog<bool>(
        context: context,
        builder: (ctx) => FinanceDialog(
          scrollable: true,
          title: const Text('Pratinjau impor IDX'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${file.name}\nSheet: ${preview.sheet}\n${counts.entries.map((v) => '${v.key}: ${v.value}').join('\n')}',
              ),
              const SizedBox(height: 12),
              const Text(
                'Kode yang tidak ada pada file tetap disimpan. Koreksi manual dan riwayat investasi dipertahankan. Tanggal impor bukan tanggal efektif IDX.',
              ),
              for (final warning in preview.warnings)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(warning),
                ),
              const SizedBox(height: 12),
              for (final r in preview.rows.take(12))
                Text('${r['code']} · ${r['name']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Terapkan pembaruan'),
            ),
          ],
        ),
      );
      if (accept != true) return;
      final ok = await c.run(
        () => c.repository.updateExtras(
          (data) => preview.apply(data, file.name, c.clock()),
        ),
      );
      if (mounted) {
        financeMessage(
          context,
          ok ? 'Katalog diperbarui secara atomik.' : c.error!,
        );
      }
    } on FormatException catch (e) {
      if (mounted) financeMessage(context, e.message);
    } catch (_) {
      if (mounted) financeMessage(context, 'File belum berhasil diproses.');
    } finally {
      if (mounted) setState(() => filesBusy = false);
    }
  }

  Future<void> cryptoSearch({bool stock = false}) async {
    final input = TextEditingController();
    final q = await showFinanceDialog<String>(
      context: context,
      builder: (ctx) => FinanceDialog(
        title: Text(
          stock ? 'Cari saham IDX di Yahoo' : 'Cari crypto di CoinGecko',
        ),
        content: TextField(
          controller: input,
          decoration: InputDecoration(
            labelText: 'Nama / simbol',
            hintText: stock ? 'BBCA atau nama perusahaan' : 'bitcoin',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, input.text),
            child: const Text('Cari'),
          ),
        ],
      ),
    );
    if (q == null || !mounted) return;
    setState(() => filesBusy = true);
    try {
      final results = stock
          ? await c.market.searchStocks(q)
          : await c.market.searchCrypto(q, await c.priceKeys.read());
      if (!mounted) return;
      final selected = await showFinanceDialog<Instrument>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: Text(stock ? 'Pilih saham Indonesia' : 'Pilih ID crypto'),
          children: [
            if (results.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Tidak ditemukan.'),
              ),
            for (final i in results)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, i),
                child: Text('${i.name} (${i.code})\nID: ${i.id}'),
              ),
          ],
        ),
      );
      if (selected != null) {
        if (!c.snapshot.extras.instruments.any((i) => i.id == selected.id)) {
          await c.saveInstrument(selected);
        }
        if (mounted) {
          setState(
            () => kind = stock ? InstrumentKind.stock : InstrumentKind.crypto,
          );
        }
      }
    } catch (_) {
      if (mounted) {
        financeMessage(
          context,
          stock
              ? 'Pencarian Yahoo belum tersedia. Gunakan impor IDX atau tambah manual.'
              : 'Pencarian gagal. Periksa API key/koneksi atau tambahkan ID crypto manual.',
        );
      }
    } finally {
      if (mounted) setState(() => filesBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: c,
    builder: (context, _) {
      final rows =
          c.snapshot.extras.instruments
              .where(
                (i) =>
                    (kind == null || i.kind == kind) &&
                    (!widget.select || !i.archived) &&
                    '${i.code} ${i.displayName} ${i.priceSymbol}'
                        .toLowerCase()
                        .contains(query.toLowerCase()),
              )
              .toList()
            ..sort((a, b) => a.code.compareTo(b.code));
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.select ? 'Pilih instrumen' : 'Katalog instrumen'),
        ),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      FinanceSelect<InstrumentKind?>(
                        initialValue: kind,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Jenis instrumen',
                        ),
                        items: [
                          const DropdownMenuItem<InstrumentKind?>(
                            value: null,
                            child: Text('Semua'),
                          ),
                          for (final k in InstrumentKind.values)
                            DropdownMenuItem(
                              value: k,
                              child: Text(switch (k) {
                                InstrumentKind.stock => 'Saham Indonesia (IDX)',
                                InstrumentKind.crypto => 'Crypto',
                                InstrumentKind.fund => 'Reksa dana',
                              }),
                            ),
                        ],
                        onChanged: (v) => setState(() {
                          kind = v;
                          limit = 50;
                        }),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('catalog-search'),
                        decoration: const InputDecoration(
                          labelText: 'Cari kode / nama',
                          prefixIcon: ArtaIcon(FeatherIcons.search),
                        ),
                        onChanged: (v) => setState(() {
                          query = v;
                          limit = 50;
                        }),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: c.busy || filesBusy ? null : import,
                            icon: const ArtaIcon(FeatherIcons.upload),
                            label: const Text('Impor IDX'),
                          ),
                          OutlinedButton(
                            onPressed: c.busy || filesBusy
                                ? null
                                : cryptoSearch,
                            child: const Text('Cari crypto online'),
                          ),
                          OutlinedButton.icon(
                            onPressed: c.busy || filesBusy
                                ? null
                                : () => cryptoSearch(stock: true),
                            icon: const ArtaIcon(FeatherIcons.search),
                            label: const Text('Cari saham online'),
                          ),
                          OutlinedButton(
                            onPressed: c.busy || filesBusy
                                ? null
                                : () => Navigator.push<void>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          InstrumentForm(controller: c),
                                    ),
                                  ),
                            child: const Text('Tambah manual'),
                          ),
                          OutlinedButton(
                            onPressed: c.busy || filesBusy
                                ? null
                                : () async {
                                    try {
                                      await DataFilesService().save(
                                        CatalogService().export(
                                          c.snapshot.extras,
                                        ),
                                        'arta-katalog-idx',
                                        extension: 'json',
                                      );
                                    } catch (_) {
                                      if (context.mounted) {
                                        financeMessage(
                                          context,
                                          'Ekspor katalog gagal.',
                                        );
                                      }
                                    }
                                  },
                            child: const Text('Ekspor IDX JSON'),
                          ),
                        ],
                      ),
                      Text(
                        '${rows.length} instrumen · ${c.snapshot.extras.catalogInfo['file'] ?? 'katalog lokal'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (filesBusy) const LinearProgressIndicator(),
                    ],
                  ),
                ),
              ),
              rows.isEmpty
                  ? const SliverToBoxAdapter(
                      child: FinanceEmptyState(
                        message: 'Belum ada instrumen yang cocok.',
                        kind: EmptyKind.search,
                      ),
                    )
                  : SliverList.builder(
                      itemCount: rows.length > limit ? limit + 1 : rows.length,
                      itemBuilder: (ctx, n) {
                        if (n == limit) {
                          return TextButton(
                            onPressed: () => setState(() => limit += 50),
                            child: const Text('Tampilkan 50 berikutnya'),
                          );
                        }
                        final i = rows[n];
                        return ListTile(
                          leading: InstrumentLogo(i),
                          title: Text(
                            '${i.code}${i.archived ? ' · arsip' : ''}',
                          ),
                          subtitle: Text(i.displayName),
                          trailing: const ArtaIcon(FeatherIcons.chevronRight),
                          onTap: c.busy || filesBusy
                              ? null
                              : () => widget.select
                                    ? Navigator.pop(context, i)
                                    : Navigator.push<void>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => InstrumentForm(
                                            controller: c,
                                            existing: i,
                                          ),
                                        ),
                                      ),
                        );
                      },
                    ),
            ],
          ),
        ),
      );
    },
  );
}

class InstrumentForm extends StatefulWidget {
  const InstrumentForm({super.key, required this.controller, this.existing});
  final FinanceController controller;
  final Instrument? existing;
  @override
  State<InstrumentForm> createState() => _InstrumentFormState();
}

class _InstrumentFormState extends State<InstrumentForm> {
  final form = GlobalKey<FormState>();
  late TextEditingController code, name, provider, logo;
  InstrumentKind kind = InstrumentKind.fund;
  String currency = 'IDR';
  bool archived = false, useSource = false;
  @override
  void initState() {
    super.initState();
    final i = widget.existing;
    kind = i?.kind ?? kind;
    currency = i?.currency ?? currency;
    archived = i?.archived ?? false;
    code = TextEditingController(text: i?.code ?? '');
    name = TextEditingController(text: i?.displayName ?? '');
    provider = TextEditingController(text: i?.priceSymbol ?? '');
    logo = TextEditingController(text: i?.logoUrl ?? '');
  }

  @override
  void dispose() {
    for (final c in [code, name, provider, logo]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate() || widget.controller.busy) return;
    try {
      final old = widget.existing;
      final symbol = kind == InstrumentKind.stock
          ? normalizeStock(code.text)
          : code.text.trim().toUpperCase();
      final value = Instrument(
        id:
            old?.id ??
            (kind == InstrumentKind.stock
                ? 'idx:$symbol'
                : widget.controller.newId()),
        code: symbol,
        name: old?.name ?? name.text.trim(),
        kind: kind,
        currency: currency,
        providerId:
            old?.providerId ??
            (kind == InstrumentKind.stock
                ? '$symbol.JK'
                : provider.text.trim()),
        logo: old?.logo ?? logo.text.trim(),
        metadata: old?.metadata ?? const {},
        archived: archived,
        overrides: old == null || useSource
            ? const {}
            : {
                'name': name.text.trim(),
                'provider_id': provider.text.trim(),
                'logo': logo.text.trim(),
              },
      );
      Instrument.fromJson(value.toJson());
      if (!mounted) return;
      await finishFinanceSave(
        context,
        widget.controller,
        widget.controller.saveInstrument(value),
      );
    } on FormatException catch (e) {
      if (mounted) financeMessage(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (ctx, _) => Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? 'Tambah instrumen' : 'Metadata instrumen',
        ),
      ),
      body: Form(
        key: form,
        child: financeFormBody([
          if (widget.existing == null)
            FinanceSelect<InstrumentKind>(
              initialValue: kind,
              decoration: const InputDecoration(labelText: 'Jenis'),
              items: [
                for (final k in InstrumentKind.values)
                  DropdownMenuItem(
                    value: k,
                    child: Text(switch (k) {
                      InstrumentKind.stock => 'Saham IDX',
                      InstrumentKind.crypto => 'Crypto',
                      InstrumentKind.fund => 'Reksa dana',
                    }),
                  ),
              ],
              onChanged: (v) => setState(() {
                kind = v!;
                if (kind == InstrumentKind.stock) currency = 'IDR';
              }),
            ),
          TextFormField(
            controller: code,
            readOnly: widget.existing != null,
            decoration: const InputDecoration(labelText: 'Kode / simbol'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Isi kode.' : null,
          ),
          TextFormField(
            controller: name,
            maxLength: 200,
            decoration: const InputDecoration(labelText: 'Nama'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Isi nama.' : null,
          ),
          FinanceSelect<String>(
            key: ValueKey('instrument-currency-$currency-$kind'),
            initialValue: currency,
            decoration: const InputDecoration(labelText: 'Mata uang harga/NAB'),
            items: [
              for (final v
                  in kind == InstrumentKind.stock ? ['IDR'] : currencies)
                DropdownMenuItem(value: v, child: Text(v)),
            ],
            onChanged: widget.existing == null
                ? (v) => setState(() => currency = v!)
                : null,
          ),
          TextFormField(
            controller: provider,
            decoration: InputDecoration(
              labelText: kind == InstrumentKind.stock
                  ? 'Simbol Yahoo (KODE.JK)'
                  : 'ID CoinGecko (crypto)',
              helperText: 'Reksa dana tidak memerlukan ID harga online.',
            ),
          ),
          TextFormField(
            controller: logo,
            decoration: const InputDecoration(
              labelText: 'URL logo HTTPS (opsional)',
            ),
          ),
          if (widget.existing != null) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Arsipkan dari pilihan transaksi baru'),
              value: archived,
              onChanged: (v) => setState(() => archived = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Kembali memakai metadata sumber'),
              subtitle: const Text(
                'Menghapus koreksi nama, simbol harga dan logo.',
              ),
              value: useSource,
              onChanged: (v) => setState(() => useSource = v),
            ),
            for (final item in widget.existing!.metadata.entries)
              SelectableText('${item.key}: ${item.value ?? '—'}'),
          ],
          FilledButton(
            onPressed: widget.controller.busy ? null : save,
            child: const Text('Simpan instrumen'),
          ),
        ]),
      ),
    ),
  );
}
