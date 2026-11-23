import '../widgets/finance_dialog.dart';
import '../widgets/finance_select.dart';
import '../widgets/arta_icon.dart';

import 'package:feather_icons/feather_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../controllers/finance_controller.dart';
import '../models/decimal.dart';
import '../models/interest.dart';
import '../models/ledger.dart';
import '../models/money.dart';
import '../services/interest_engine.dart';
import '../widgets/finance_fields.dart';
import '../widgets/finance_empty_state.dart';

class InterestScreen extends StatefulWidget {
  const InterestScreen({super.key, required this.controller});
  final FinanceController controller;
  @override
  State<InterestScreen> createState() => _InterestScreenState();
}

class _InterestScreenState extends State<InterestScreen> {
  int limit = 31;
  FinanceController get c => widget.controller;
  Future<void> voidPosting(InterestPosting p) async {
    final yes = await showFinanceDialog<bool>(
      context: context,
      builder: (ctx) => FinanceDialog(
        title: const Text('Batalkan catatan bunga?'),
        content: const Text(
          'Saldo dikoreksi. Periode tetap ditandai batal agar tidak tercatat otomatis lagi. Riwayat bunga lain yang sudah dikonfirmasi tidak diubah.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Batalkan catatan'),
          ),
        ],
      ),
    );
    if (yes == true) {
      final ok = await c.voidInterest(p.id);
      if (mounted && !ok) financeMessage(context, c.error!);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: c,
    builder: (ctx, _) {
      List<InterestPosting> pending = [];
      String? issue;
      try {
        pending = InterestEngine.pending(
          c.snapshot,
          c.clock(),
          maxPerRule: limit + 1,
        );
      } on FormatException catch (e) {
        issue = e.message;
      }
      final extras = c.snapshot.extras;
      final posted = [...extras.interestPostings]
        ..sort((a, b) => b.date.compareTo(a.date));
      String currency(InterestPosting p) => c.snapshot.accounts
          .firstWhere(
            (a) =>
                a.id ==
                extras.interestRules
                    .firstWhere((r) => r.id == p.ruleId)
                    .accountId,
          )
          .currency;
      return Scaffold(
        appBar: AppBar(title: const Text('Bunga & bagi hasil')),
        body: financeBody([
          const Text(
            'Aturan diisi sendiri; tidak ada tarif bank bawaan. Saldo negatif menghasilkan estimasi bunga nol. Estimasi belum menambah saldo sampai dicatat atau mode otomatis diaktifkan.',
          ),
          FilledButton.icon(
            onPressed: c.busy || c.snapshot.accounts.isEmpty
                ? null
                : () => Navigator.push<void>(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => InterestRuleForm(controller: c),
                    ),
                  ),
            icon: const ArtaIcon(FeatherIcons.plus),
            label: const Text('Tambah aturan bunga'),
          ),
          if (extras.interestRules.isEmpty)
            const FinanceEmptyState(
              message: 'Atur bunga harian atau bulanan sesuai rekening Anda.',
              kind: EmptyKind.calendar,
            ),
          for (final rule in extras.interestRules)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rule.name, style: Theme.of(ctx).textTheme.titleMedium),
                    Text(
                      '${c.snapshot.accounts.firstWhere((a) => a.id == rule.accountId).name} · ${rule.start}${rule.end == null ? '' : ' s.d. ${rule.end}'}',
                    ),
                    Text(
                      '${rule.monthly ? 'Kredit bulanan' : 'Kredit harian'} · ${rule.progressive ? 'Tier progresif' : 'Tarif seluruh saldo'} · basis ${rule.daysBasis} hari\nPajak ${rule.taxPercent.text}% · ${rule.previousClosing ? 'Saldo akhir hari sebelumnya' : 'Saldo akhir hari perhitungan'} · ${rule.automatic ? 'Otomatis' : 'Konfirmasi'}',
                    ),
                    for (final tier in rule.tiers)
                      Text(
                        'Mulai ${c.displayCurrency(tier.from, c.snapshot.accounts.firstWhere((a) => a.id == rule.accountId).currency)} → ${tier.percent.text}% / tahun',
                      ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Aturan aktif'),
                      value: rule.active,
                      onChanged: c.busy
                          ? null
                          : (v) async {
                              final ok = await c.saveInterestRule(
                                InterestRule.fromJson({
                                  ...rule.toJson(),
                                  'active': v,
                                }),
                              );
                              if (ctx.mounted && !ok) {
                                financeMessage(ctx, c.error!);
                              }
                            },
                    ),
                    const Text(
                      'Untuk mengubah tarif, hentikan aturan ini dan buat aturan baru dengan tanggal berlaku baru.',
                    ),
                  ],
                ),
              ),
            ),
          Text(
            'Estimasi periode selesai',
            style: Theme.of(ctx).textTheme.titleMedium,
          ),
          const Text(
            'Dihitung sampai kemarin dalam WIB. Kredit bulanan menunggu periode selesai. Tinjau bruto/pajak/tanggal sesuai mutasi bank sebelum mencatat. Estimasi berikutnya mengikuti bunga aktual yang sudah dicatat.',
          ),
          if (issue != null) Text(issue),
          if (pending.isEmpty)
            const Text(
              'Tidak ada periode yang menunggu, atau kurs aset belum diisi.',
            ),
          for (final p in pending.take(limit))
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                extras.interestRules.firstWhere((r) => r.id == p.ruleId).name,
              ),
              subtitle: Text(
                '${p.start} — ${p.end}\nBruto ${c.displayCurrency(p.gross, currency(p))} · pajak ${c.displayCurrency(p.tax, currency(p))}\nNeto ${c.displayCurrency(p.net, currency(p))}',
              ),
              trailing: const ArtaIcon(FeatherIcons.chevronRight),
              onTap: c.busy
                  ? null
                  : () => Navigator.push<void>(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) =>
                            InterestPostForm(controller: c, estimate: p),
                      ),
                    ),
            ),
          if (pending.length > limit)
            TextButton(
              onPressed: () => setState(() => limit += 31),
              child: const Text('Tampilkan 31 periode berikutnya'),
            ),
          Text(
            'Riwayat bunga aktual',
            style: Theme.of(ctx).textTheme.titleMedium,
          ),
          for (final p in posted.take(limit))
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${p.date}${p.voided ? ' · dibatalkan' : ''}'),
              subtitle: Text(
                '${p.start} — ${p.end}\nNeto ${c.displayCurrency(p.net, currency(p))}',
              ),
              trailing: p.voided
                  ? null
                  : IconButton(
                      tooltip: 'Batalkan catatan',
                      onPressed: c.busy ? null : () => voidPosting(p),
                      icon: const ArtaIcon(FeatherIcons.trash2),
                    ),
            ),
          if (posted.length > limit)
            TextButton(
              onPressed: () => setState(() => limit += 31),
              child: const Text('Tampilkan riwayat berikutnya'),
            ),
        ]),
      );
    },
  );
}

class InterestRuleForm extends StatefulWidget {
  const InterestRuleForm({super.key, required this.controller});
  final FinanceController controller;
  @override
  State<InterestRuleForm> createState() => _InterestRuleFormState();
}

class _InterestRuleFormState extends State<InterestRuleForm> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final tax = TextEditingController(text: '0');
  final from = [TextEditingController(text: '0')],
      percent = [TextEditingController(text: '0')];
  String? account, end;
  late String start;
  bool progressive = false, monthly = false, previous = true, automatic = false;
  int basis = 365;
  FinanceController get c => widget.controller;
  @override
  void initState() {
    super.initState();
    account = c.snapshot.accounts.firstOrNull?.id;
    start = localDate(c.clock().toUtc().add(const Duration(hours: 7)));
  }

  @override
  void dispose() {
    for (final t in [name, tax, ...from, ...percent]) {
      t.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (c.busy || !form.currentState!.validate()) return;
    try {
      final r = InterestRule(
        id: c.newId(),
        accountId: account!,
        name: name.text.trim(),
        start: start,
        end: end,
        tiers: [
          for (var n = 0; n < from.length; n++)
            InterestTier(
              Money.input(from[n].text),
              Decimal.input(percent[n].text),
            ),
        ],
        taxPercent: Decimal.input(tax.text),
        progressive: progressive,
        monthly: monthly,
        previousClosing: previous,
        daysBasis: basis,
        automatic: automatic,
      );
      InterestRule.fromJson(r.toJson());
      if (!mounted) return;
      await finishFinanceSave(context, c, c.saveInterestRule(r));
    } on FormatException catch (e) {
      if (mounted) financeMessage(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: c,
    builder: (ctx, _) => Scaffold(
      appBar: AppBar(title: const Text('Aturan bunga pengguna')),
      body: Form(
        key: form,
        child: financeFormBody([
          TextFormField(
            controller: name,
            maxLength: 80,
            decoration: const InputDecoration(labelText: 'Nama aturan'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Isi nama.' : null,
          ),
          accountField(
            c.snapshot.accounts,
            account,
            (v) => setState(() => account = v),
          ),
          OutlinedButton(
            onPressed: () async {
              final d = await pickFinanceDate(ctx, start);
              if (d != null && mounted) setState(() => start = d);
            },
            child: Text('Mulai berlaku: $start'),
          ),
          OutlinedButton(
            onPressed: () async {
              final d = await pickFinanceDate(ctx, end ?? start);
              if (d != null && mounted) setState(() => end = d);
            },
            child: Text(
              end == null ? 'Tanggal akhir (opsional)' : 'Sampai: $end',
            ),
          ),
          if (end != null)
            TextButton(
              onPressed: () => setState(() => end = null),
              child: const Text('Tanpa tanggal akhir'),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Kredit setiap akhir bulan'),
            subtitle: const Text(
              'Jika nonaktif: kredit harian. Perhitungan selalu berdasarkan saldo per hari.',
            ),
            value: monthly,
            onChanged: (v) => setState(() => monthly = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Pakai saldo akhir hari sebelumnya'),
            value: previous,
            onChanged: (v) => setState(() => previous = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Tier progresif'),
            subtitle: const Text(
              'Aktif: setiap rentang saldo memakai tarifnya. Nonaktif: tarif tier terpilih untuk seluruh saldo.',
            ),
            value: progressive,
            onChanged: (v) => setState(() => progressive = v),
          ),
          FinanceSelect<int>(
            initialValue: basis,
            decoration: const InputDecoration(
              labelText: 'Basis hari per tahun',
            ),
            items: [
              for (final v in [360, 365, 366])
                DropdownMenuItem(value: v, child: Text('$v hari')),
            ],
            onChanged: (v) => setState(() => basis = v!),
          ),
          const Text(
            'Tier pertama harus mulai saldo 0. Contoh: mulai 0 dengan tarif 0%, lalu batas saldo berikutnya dengan tarif pilihan Anda. Tarif berupa persen per tahun.',
          ),
          for (var n = 0; n < from.length; n++)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    numberField(
                      from[n],
                      'Batas saldo tier ${n + 1} (${c.snapshot.accounts.where((a) => a.id == account).firstOrNull?.currency ?? 'IDR'})',
                      money: true,
                      zero: true,
                    ),
                    const SizedBox(height: 12),
                    numberField(percent[n], 'Tarif tahunan (%)', zero: true),
                  ],
                ),
              ),
            ),
          if (from.length < 20)
            OutlinedButton(
              onPressed: () => setState(() {
                from.add(TextEditingController());
                percent.add(TextEditingController());
              }),
              child: const Text('Tambah tingkatan saldo'),
            ),
          numberField(tax, 'Pajak atas bunga (%)', zero: true),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Catat otomatis saat aplikasi dibuka'),
            subtitle: const Text(
              'Menganggap hasil estimasi sebagai bunga aktual. Default nonaktif; aktifkan hanya jika aturan dan riwayat saldo sudah sesuai.',
            ),
            value: automatic,
            onChanged: (v) => setState(() => automatic = v),
          ),
          const Text(
            'Pembulatan setengah menjauh dari nol, ke dua desimal: bruto per periode, lalu pajak. Basis hari dipilih manual. Belum ada pengambilan tarif atau mutasi bank otomatis.',
          ),
          FilledButton(
            onPressed: c.busy || account == null ? null : save,
            child: const Text('Simpan aturan bunga'),
          ),
        ]),
      ),
    ),
  );
}

class InterestPostForm extends StatefulWidget {
  const InterestPostForm({
    super.key,
    required this.controller,
    required this.estimate,
  });
  final FinanceController controller;
  final InterestPosting estimate;
  @override
  State<InterestPostForm> createState() => _InterestPostFormState();
}

class _InterestPostFormState extends State<InterestPostForm> {
  final form = GlobalKey<FormState>();
  late TextEditingController gross, tax;
  late String date;
  @override
  void initState() {
    super.initState();
    gross = TextEditingController(text: widget.estimate.gross.input);
    tax = TextEditingController(text: widget.estimate.tax.input);
    date = widget.estimate.date;
  }

  @override
  void dispose() {
    gross.dispose();
    tax.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (ctx, _) => Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi bunga aktual')),
      body: Form(
        key: form,
        child: financeFormBody([
          Text(
            'Periode ${widget.estimate.start} — ${widget.estimate.end}. Sesuaikan dengan nilai yang benar-benar dikreditkan bank. Saldo bertambah bruto dikurangi pajak, satu kali.',
          ),
          numberField(gross, 'Bunga bruto aktual', money: true, zero: true),
          numberField(tax, 'Pajak aktual', money: true, zero: true),
          OutlinedButton(
            onPressed: () async {
              final d = await pickFinanceDate(
                ctx,
                date,
                now: widget.controller.clock().toUtc().add(
                  const Duration(hours: 7),
                ),
              );
              if (d != null && mounted) setState(() => date = d);
            },
            child: Text('Tanggal masuk: $date'),
          ),
          FilledButton(
            onPressed: widget.controller.busy
                ? null
                : () async {
                    if (!form.currentState!.validate()) return;
                    try {
                      final p = InterestPosting.fromJson({
                        ...widget.estimate.toJson(),
                        'gross_minor': Money.input(gross.text).stored,
                        'tax_minor': Money.input(tax.text).stored,
                        'date': date,
                      });
                      await finishFinanceSave(
                        ctx,
                        widget.controller,
                        widget.controller.postInterest(p),
                      );
                    } on FormatException catch (e) {
                      if (ctx.mounted) financeMessage(ctx, e.message);
                    }
                  },
            child: const Text('Catat bunga aktual'),
          ),
        ]),
      ),
    ),
  );
}
