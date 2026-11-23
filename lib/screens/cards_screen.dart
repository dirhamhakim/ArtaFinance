import '../widgets/finance_select.dart';
import '../widgets/arta_icon.dart';

import 'package:feather_icons/feather_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../controllers/finance_controller.dart';
import '../models/ledger.dart';
import '../models/payment_card.dart';
import '../widgets/finance_empty_state.dart';

class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key, required this.controller});
  final FinanceController controller;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Kartu debit')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Kartu memakai saldo rekening sumber. Total aset tidak bertambah karena kartu dibuat.',
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const Key('add-card'),
                  onPressed:
                      controller.busy ||
                          !controller.snapshot.accounts.any(
                            (a) => a.kind == AccountKind.bank,
                          )
                      ? null
                      : () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CardForm(controller: controller),
                          ),
                        ),
                  icon: const ArtaIcon(FeatherIcons.plus),
                  label: const Text('Tambah kartu debit'),
                ),
                const SizedBox(height: 16),
                if (!controller.snapshot.accounts.any(
                  (a) => a.kind == AccountKind.bank,
                ))
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Tambahkan aset bank sumber terlebih dahulu di menu Aset.',
                    ),
                  ),
                if (controller.snapshot.cards.isEmpty)
                  const FinanceEmptyState(
                    message: 'Belum ada kartu. Hubungkan kartu Jago ke rekening atau kantong sumbernya.',
                    kind: EmptyKind.cards,
                  ),
                for (final card in controller.snapshot.cards)
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const ArtaIcon(FeatherIcons.creditCard),
                      title: Text(card.name),
                      subtitle: Text(
                        'Debit · ${controller.snapshot.accounts.firstWhere((a) => a.id == card.accountId).name}\nSaldo sumber ${controller.displayCurrency(controller.snapshot.balance(card.accountId), controller.snapshot.accounts.firstWhere((a) => a.id == card.accountId).currency)}',
                      ),
                      trailing: const ArtaIcon(FeatherIcons.chevronRight),
                      onTap: controller.busy
                          ? null
                          : () => Navigator.push<void>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CardForm(
                                  controller: controller,
                                  existing: card,
                                ),
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class CardForm extends StatefulWidget {
  const CardForm({super.key, required this.controller, this.existing});
  final FinanceController controller;
  final PaymentCard? existing;
  @override
  State<CardForm> createState() => _CardFormState();
}

class _CardFormState extends State<CardForm> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(
    text: widget.existing?.name ?? 'Debit Jago Syariah',
  );
  late String source =
      widget.existing?.accountId ??
      widget.controller.snapshot.accounts
          .firstWhere((a) => a.kind == AccountKind.bank)
          .id;
  bool saving = false;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() => saving = true);
    final ok = await widget.controller.saveCard(
      PaymentCard(
        id: widget.existing?.id ?? widget.controller.newId(),
        name: name.text.trim(),
        accountId: source,
        createdAt:
            widget.existing?.createdAt ??
            widget.controller.clock().toUtc().toIso8601String(),
      ),
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
    appBar: AppBar(
      title: Text(
        widget.existing == null ? 'Tambah kartu debit' : 'Ubah kartu debit',
      ),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: form,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  key: const Key('card-name'),
                  controller: name,
                  maxLength: 80,
                  decoration: const InputDecoration(labelText: 'Nama kartu'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Isi nama kartu.' : null,
                ),
                const SizedBox(height: 20),
                FinanceSelect<String>(
                  key: const Key('card-source'),
                  initialValue: source,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Rekening / kantong sumber',
                  ),
                  items: widget.controller.snapshot.accounts
                      .where((a) => a.kind == AccountKind.bank)
                      .map(
                        (a) => DropdownMenuItem(
                          value: a.id,
                          child: Text(a.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: saving ? null : (v) => setState(() => source = v!),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Pilih aset yang mewakili kantong sumber di Jago. Perubahan tautan berlaku untuk pilihan transaksi baru; sumber transaksi lama tetap tersimpan.',
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('save-card'),
                  onPressed: saving ? null : save,
                  child: Text(saving ? 'Menyimpan…' : 'Simpan kartu'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
