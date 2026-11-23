import '../widgets/finance_dialog.dart';
import '../widgets/arta_icon.dart';

import 'package:feather_icons/feather_icons.dart';

import 'dart:convert';

import 'package:material_ui/material_ui.dart';

import '../controllers/finance_controller.dart';
import '../models/decimal.dart';
import '../models/investment.dart';
import '../models/ledger.dart';
import '../services/data_files_service.dart';
import '../services/csv_service.dart';
import '../widgets/finance_fields.dart';
import '../widgets/password_field.dart';

class MarketSettingsScreen extends StatefulWidget {
  const MarketSettingsScreen({super.key, required this.controller});
  final FinanceController controller;
  @override
  State<MarketSettingsScreen> createState() => _MarketSettingsScreenState();
}

class _MarketSettingsScreenState extends State<MarketSettingsScreen> {
  final keyInput = TextEditingController(), sheet = TextEditingController();
  bool auto = true, working = false, loaded = false;
  FinanceController get c => widget.controller;
  String rateLabel(String currency) {
    final rate = c.snapshot.extras.rates
        .where((r) => r.currency == currency)
        .firstOrNull;
    return rate == null
        ? 'Kurs belum diisi'
        : '1 $currency = ${rate.rate.text} IDR · ${rate.date}';
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final key = await c.priceKeys.read();
      final url = await c.repository.preference('sheet_csv_url');
      final refresh = await c.repository.preference('market_daily_auto');
      if (mounted) {
        setState(() {
          keyInput.text = key;
          sheet.text = url ?? '';
          auto = refresh != 'false';
          loaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loaded = true);
    }
  }

  @override
  void dispose() {
    keyInput.dispose();
    sheet.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (working || c.busy) return;
    setState(() => working = true);
    try {
      final key = keyInput.text.trim();
      if (key.length > 256 || key.contains(RegExp(r'[\r\n]'))) {
        throw const FormatException('API key tidak valid.');
      }
      await c.priceKeys.write(key);
      await c.repository.setPreference('sheet_csv_url', sheet.text.trim());
      await c.repository.setPreference('market_daily_auto', auto.toString());
      if (mounted) financeMessage(context, 'Pengaturan disimpan di perangkat.');
    } catch (_) {
      if (mounted) {
        financeMessage(
          context,
          'Pengaturan belum tersimpan. Buka kunci aplikasi dan coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> csv() async {
    if (working || c.busy) return;
    setState(() => working = true);
    try {
      final file = await DataFilesService().pick([
        'csv',
      ], maxBytes: 2 * 1024 * 1024);
      if (file == null) return;
      final quotes = CsvService().prices(
        utf8.decode(file.bytes),
        c.snapshot.extras.instruments,
        c.clock(),
      );
      if (!mounted) return;
      final accept = await showFinanceDialog<bool>(
        context: context,
        builder: (ctx) => FinanceDialog(
          scrollable: true,
          title: const Text('Pratinjau harga CSV'),
          content: Text(
            '${quotes.length} harga valid.\n${quotes.take(12).map((q) => '${q.instrumentId} · ${q.date} · ${q.price.text} ${q.currency}').join('\n')}\nTanggal harus tanggal harga/NAB, bukan tanggal unduh.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Terapkan'),
            ),
          ],
        ),
      );
      if (accept == true) {
        final ok = await c.saveQuotes(quotes);
        if (mounted) {
          financeMessage(context, ok ? 'Harga CSV disimpan.' : c.error!);
        }
      }
    } on FormatException catch (e) {
      if (mounted) financeMessage(context, e.message);
    } catch (_) {
      if (mounted) financeMessage(context, 'CSV belum dapat diimpor.');
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: c,
    builder: (ctx, _) => Scaffold(
      appBar: AppBar(title: const Text('Sumber harga & kurs')),
      body: financeBody([
        const Text(
          'Saham: Yahoo Finance KODE.JK, penutupan sesi selesai. Crypto: CoinGecko Demo. Reksa dana: NAB manual. Tidak ada perdagangan atau koneksi aset platform.',
        ),
        PasswordField(
          controller: keyInput,
          label: 'CoinGecko Demo API key (opsional)',
        ),
        const Text(
          'Key disimpan terenkripsi melalui Android Keystore, terpisah dari backup. Key Demo mempunyai kuota. Harga harian membutuhkan satu request per koin yang dimiliki; harga terbaru manual digabung dalam satu request crypto.',
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Simpan penutupan harian otomatis'),
          subtitle: const Text(
            'Saat aplikasi aktif dan tidak terkunci. Default aktif; data lengkap tidak diminta ulang pada hari yang sama. Harga terbaru hanya lewat tombol manual.',
          ),
          value: auto,
          onChanged: working || !loaded
              ? null
              : (v) => setState(() => auto = v),
        ),
        TextFormField(
          controller: sheet,
          decoration: const InputDecoration(
            labelText: 'URL CSV Google Sheets publik (opsional)',
            helperText:
                'docs.google.com/spreadsheets/.../export?format=csv&gid=...',
          ),
        ),
        FilledButton(
          onPressed: working || c.busy || !loaded ? null : save,
          child: const Text('Simpan pengaturan harga'),
        ),
        OutlinedButton(
          onPressed: working || c.busy
              ? null
              : () async {
                  await c.fetchSheet();
                  if (ctx.mounted) {
                    financeMessage(
                      ctx,
                      c.error ?? c.marketMessage ?? 'Selesai.',
                    );
                  }
                },
          child: const Text('Ambil harga spreadsheet tersimpan'),
        ),
        const Text(
          'Cadangan spreadsheet: tabel CSV dengan header code,date,price,currency. Contoh BBCA,2026-11-18,9000,IDR. Gunakan harga penutupan biasa dan tanggal sesi sebenarnya; GOOGLEFINANCE tidak menjamin semua simbol atau akses data historis lewat API. Pratinjau CSV lokal tersedia di bawah.',
        ),
        OutlinedButton.icon(
          onPressed: working || c.busy ? null : csv,
          icon: const ArtaIcon(FeatherIcons.upload),
          label: const Text('Impor harga / NAB CSV'),
        ),
        if (working || c.busy) const LinearProgressIndicator(),
        Text(
          'Mata uang & kurs valuasi',
          style: Theme.of(ctx).textTheme.titleMedium,
        ),
        const Text(
          'Kurs menyatakan IDR untuk satu unit mata uang. Kurs valuasi terbaru tidak mengubah kurs historis transaksi. Saldo kas memakai dua desimal; unit investasi memakai hingga 12 desimal. USDT tidak otomatis dianggap USD.',
        ),
        for (final currency in currencies.where((v) => v != 'IDR'))
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(currency),
            subtitle: Text(rateLabel(currency)),
            trailing: const ArtaIcon(FeatherIcons.edit2),
            onTap: c.busy
                ? null
                : () => Navigator.push<void>(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) =>
                          FxRateForm(controller: c, currency: currency),
                    ),
                  ),
          ),
      ]),
    ),
  );
}

class FxRateForm extends StatefulWidget {
  const FxRateForm({
    super.key,
    required this.controller,
    required this.currency,
  });
  final FinanceController controller;
  final String currency;
  @override
  State<FxRateForm> createState() => _FxRateFormState();
}

class _FxRateFormState extends State<FxRateForm> {
  final form = GlobalKey<FormState>();
  late TextEditingController rate;
  late String date;
  @override
  void initState() {
    super.initState();
    final f = widget.controller.snapshot.extras.rates
        .where((f) => f.currency == widget.currency)
        .firstOrNull;
    rate = TextEditingController(text: f?.rate.text ?? '');
    date =
        f?.date ??
        localDate(
          widget.controller.clock().toUtc().add(const Duration(hours: 7)),
        );
  }

  @override
  void dispose() {
    rate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (ctx, _) => Scaffold(
      appBar: AppBar(title: Text('Kurs ${widget.currency} → IDR')),
      body: Form(
        key: form,
        child: financeFormBody([
          numberField(
            rate,
            'IDR per 1 ${widget.currency}',
            key: const Key('fx-rate'),
          ),
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
            child: Text('Tanggal kurs: $date'),
          ),
          FilledButton(
            onPressed: widget.controller.busy
                ? null
                : () async {
                    if (!form.currentState!.validate()) return;
                    await finishFinanceSave(
                      ctx,
                      widget.controller,
                      widget.controller.saveRate(
                        FxRate(
                          currency: widget.currency,
                          rate: Decimal.input(rate.text),
                          date: date,
                        ),
                      ),
                    );
                  },
            child: const Text('Simpan kurs'),
          ),
        ]),
      ),
    ),
  );
}
