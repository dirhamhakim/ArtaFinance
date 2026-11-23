import '../widgets/finance_dialog.dart';
import '../widgets/arta_icon.dart';

import 'package:feather_icons/feather_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../controllers/finance_controller.dart';
import '../models/ledger.dart';
import '../models/money.dart';
import '../models/schedule.dart';
import '../services/schedule_engine.dart';
import '../widgets/transfer_fee_field.dart';
import '../widgets/transaction_time_field.dart';

class OccurrenceForm extends StatefulWidget {
  const OccurrenceForm({
    super.key,
    required this.controller,
    required this.item,
  });
  final FinanceController controller;
  final PendingOccurrence item;
  @override
  State<OccurrenceForm> createState() => _OccurrenceFormState();
}

class _OccurrenceFormState extends State<OccurrenceForm> {
  final form = GlobalKey<FormState>();
  late final TextEditingController amount, fee, note;
  late String date;
  bool saving = false;
  late bool feeEnabled;
  late TextEditingController receiverFee;
  late bool senderFeeEnabled, receiverFeeEnabled;
  String? time;
  PendingOccurrence get item => widget.item;
  @override
  void initState() {
    super.initState();
    amount = TextEditingController(text: item.amount.input);
    fee = TextEditingController(text: item.rule.fee.input);
    receiverFee = TextEditingController(text: item.rule.receivingFee.input);
    receiverFeeEnabled = !item.rule.receivingFee.isZero;
    senderFeeEnabled = !item.rule.fee.isZero || !receiverFeeEnabled;
    feeEnabled = !item.rule.fee.isZero || receiverFeeEnabled;
    time = item.rule.time;
    note = TextEditingController(text: item.rule.note);
    final today = item.rule.today(widget.controller.clock());
    date = item.date.compareTo(today) > 0 ? today : item.date;
    if (date == today) {
      time = localTime(
        widget.controller.clock().toUtc().add(
          Duration(hours: scheduleZones[item.rule.zone]!),
        ),
      );
    }
  }

  @override
  void dispose() {
    amount.dispose();
    fee.dispose();
    receiverFee.dispose();
    note.dispose();
    super.dispose();
  }

  String? validateMoney(String? text, {bool zero = false}) {
    try {
      final value = Money.input(text ?? '');
      return (zero ? value.isNegative : !value.isPositive)
          ? 'Isi nominal ${zero ? 'minimal 0' : 'lebih dari 0'}.'
          : null;
    } on FormatException catch (e) {
      return e.message;
    }
  }

  Future<void> resolve({bool skip = false}) async {
    if (saving ||
        widget.controller.busy ||
        (!skip && !form.currentState!.validate())) {
      return;
    }
    if (skip) {
      final accept = await showFinanceDialog<bool>(
        context: context,
        builder: (context) => FinanceDialog(
          title: const Text('Lewati kejadian ini?'),
          content: Text(
            '${item.rule.name} · ${item.date}\nSaldo tidak berubah. Kejadian ini tidak akan dibuat ulang. Pada cicilan, bagian ini dianggap dilewati dan tidak dibagi ulang.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Lewati'),
            ),
          ],
        ),
      );
      if (accept != true || !mounted) return;
    }
    setState(() => saving = true);
    final ok = await widget.controller.resolveOccurrence(
      item,
      skip: skip,
      amount: skip ? null : Money.input(amount.text),
      fee: skip
          ? null
          : item.rule.kind == TransactionKind.transfer &&
                feeEnabled &&
                senderFeeEnabled
          ? Money.input(fee.text)
          : Money.zero,
      receiverFee: skip
          ? null
          : feeEnabled && receiverFeeEnabled
          ? Money.input(receiverFee.text)
          : Money.zero,
      date: date,
      note: note.text.trim(),
      time: time,
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
    appBar: AppBar(title: const Text('Catat satu kejadian')),
    body: SafeArea(
      child: Center(
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
                  Text(
                    item.rule.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${transactionLabel(item.rule.kind)} · jatuh tempo ${item.date}',
                  ),
                  if (item.rule.installments)
                    Text('Cicilan ${item.ordinal + 1}/${item.rule.count}'),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const Key('occurrence-amount'),
                    controller: amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText:
                          'Nominal aktual (${widget.controller.snapshot.accounts.firstWhere((a) => a.id == item.rule.accountId).currency})',
                      helperText: 'Perubahan hanya untuk kejadian ini.',
                    ),
                    validator: validateMoney,
                  ),
                  if (item.rule.kind == TransactionKind.transfer) ...[
                    const SizedBox(height: 20),
                    TransferFeeField(
                      currency: widget.controller.snapshot.accounts
                          .firstWhere((a) => a.id == item.rule.accountId)
                          .currency,
                      enabled: feeEnabled,
                      senderEnabled: senderFeeEnabled,
                      receiverEnabled: receiverFeeEnabled,
                      receiverController: receiverFee,
                      onSenderChanged: saving
                          ? null
                          : (v) => setState(() => senderFeeEnabled = v),
                      onReceiverChanged: saving
                          ? null
                          : (v) => setState(() => receiverFeeEnabled = v),
                      actual: true,
                      controller: fee,
                      onChanged: saving
                          ? null
                          : (v) => setState(() => feeEnabled = v),
                      validator: (v) => validateMoney(v, zero: true),
                    ),
                  ],
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: saving
                        ? null
                        : () async {
                            final selected = await showDatePicker(
                              context: context,
                              initialDate: DateTime.parse(date),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.parse(
                                item.rule.today(widget.controller.clock()),
                              ),
                            );
                            if (selected != null && mounted) {
                              setState(() => date = localDate(selected));
                            }
                          },
                    icon: const ArtaIcon(FeatherIcons.calendar),
                    label: Text('Tanggal aktual: $date'),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: note,
                    maxLength: 1000,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Catatan (opsional)',
                    ),
                  ),
                  const SizedBox(height: 20),
                  TransactionTimeField(
                    value: time,
                    zone: item.rule.zone,
                    onChanged: saving ? null : (v) => setState(() => time = v),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tanggal jatuh tempo tetap tersimpan. Jika nominal cicilan diubah, bagian lainnya tetap sesuai rencana awal.',
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('post-occurrence'),
                    onPressed: saving ? null : resolve,
                    child: Text(saving ? 'Menyimpan…' : 'Catat transaksi ini'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: saving ? null : () => resolve(skip: true),
                    child: const Text('Lewati sekali'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
