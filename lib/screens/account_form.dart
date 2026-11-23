import '../widgets/finance_select.dart';

import 'package:material_ui/material_ui.dart';

import '../controllers/finance_controller.dart';
import '../models/ledger.dart';
import '../models/money.dart';
import '../models/decimal.dart';
import '../widgets/provider_logo.dart';
import '../widgets/arta_icon.dart';

class AccountForm extends StatefulWidget {
  const AccountForm({
    super.key,
    required this.controller,
    this.initialKind = AccountKind.bank,
  });
  final FinanceController controller;
  final AccountKind initialKind;
  @override
  State<AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<AccountForm> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final opening = TextEditingController(text: '0');
  AccountKind kind = AccountKind.bank;
  String currency = 'IDR';
  String? providerId;
  @override
  void initState() {
    super.initState();
    kind = widget.initialKind;
  }

  bool saving = false;
  @override
  void dispose() {
    name.dispose();
    opening.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() => saving = true);
    final ok = await widget.controller.createAccount(
      name.text,
      kind,
      Money.input(opening.text),
      currency: currency,
      providerId: providerId,
    );
    if (!mounted) return;
    setState(() => saving = false);
    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(widget.controller.error!)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tambah aset')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Form(
          key: form,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('account-name'),
                  controller: name,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nama aset',
                    hintText: 'Misalnya Mandiri',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Isi nama aset.' : null,
                ),
                const SizedBox(height: 16),
                FinanceSelect<AccountKind>(
                  initialValue: kind,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Kelas aset'),
                  items: AccountKind.values
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(
                            accountLabel(v),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: saving
                      ? null
                      : (v) => setState(() {
                          kind = v!;
                          providerId = null;
                        }),
                ),
                if ([
                  AccountKind.bank,
                  AccountKind.ewallet,
                  AccountKind.debit,
                ].contains(kind)) ...[
                  const SizedBox(height: 20),
                  Card(
                    child: ListTile(
                      leading: ProviderLogo(
                        provider: providerId ?? 'other',
                        kind: kind,
                      ),
                      title: Text(
                        assetProviders
                                .where((p) => p.id == providerId)
                                .firstOrNull
                                ?.name ??
                            'Pilih bank / e-wallet',
                      ),
                      subtitle: const Text('Logo penyedia atau ikon Lainnya'),
                      trailing: const DesignGlyph('chevron-right'),
                      onTap: saving
                          ? null
                          : () async {
                              final selected = await pickAssetProvider(
                                context,
                                kind,
                              );
                              if (selected != null && mounted) {
                                setState(() {
                                  providerId = selected;
                                  if (name.text.trim().isEmpty &&
                                      selected != 'other') {
                                    name.text = assetProviders
                                        .firstWhere((p) => p.id == selected)
                                        .name;
                                  }
                                });
                              }
                            },
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FinanceSelect<String>(
                  initialValue: currency,
                  decoration: const InputDecoration(
                    labelText: 'Mata uang aset',
                  ),
                  items: [
                    for (final v in currencies)
                      DropdownMenuItem(value: v, child: Text(v)),
                  ],
                  onChanged: saving
                      ? null
                      : (v) => setState(() => currency = v!),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const Key('opening-balance'),
                  controller: opening,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Saldo awal ($currency)',
                    hintText: '0',
                    helperText: 'Saldo minus diperbolehkan. Contoh: -10.000',
                  ),
                  validator: (v) {
                    try {
                      Money.input(v ?? '');
                      return null;
                    } on FormatException catch (e) {
                      return e.message;
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Saldo awal tidak dihitung sebagai pemasukan. Saldo exchange/sekuritas di sini hanya uang tunai; unit investasi dicatat terpisah pada Portofolio. Isi kurs di Pengaturan untuk menghitung total IDR aset mata uang asing.',
                ),
                if (kind == AccountKind.liability)
                  const Text(
                    'Utang awal ditulis minus. Pinjaman masuk: transfer aset Utang → bank. Bayar pokok: transfer bank → Utang. Bunga dicatat sebagai pengeluaran terpisah. Belanja kartu kredit dicatat pengeluaran dari aset Utang, lalu bayar tagihan dengan transfer.',
                  ),
                if (kind == AccountKind.receivable)
                  const Text(
                    'Piutang awal ditulis positif. Memberi pinjaman: transfer bank → Piutang. Saat diterima kembali: transfer Piutang → bank. Pokok bukan pengeluaran/pemasukan baru.',
                  ),
                if (kind == AccountKind.debit)
                  const Text(
                    'Kartu debit ini mempunyai saldo kantong sendiri. Isi saldo melalui transfer dari bank agar tidak dihitung dua kali.',
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('save-account'),
                  onPressed: saving ? null : save,
                  child: Text(saving ? 'Menyimpan…' : 'Simpan aset'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
