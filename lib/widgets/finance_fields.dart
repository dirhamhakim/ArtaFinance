import 'finance_select.dart';

import 'package:material_ui/material_ui.dart';

import '../controllers/finance_controller.dart';
import '../models/ledger.dart';
import '../models/money.dart';
import '../models/decimal.dart';

Widget financeBody(List<Widget> children) => SafeArea(
  child: Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 650),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final child in children)
            Padding(padding: const EdgeInsets.only(bottom: 16), child: child),
        ],
      ),
    ),
  ),
);

/// Forms have a bounded field count. Keep their FormField states mounted even
/// when scrolled away, so validation cannot skip an off-screen amount or rate.
Widget financeFormBody(List<Widget> children) => SafeArea(
  child: Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 650),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final child in children)
              Padding(padding: const EdgeInsets.only(bottom: 16), child: child),
          ],
        ),
      ),
    ),
  ),
);

Widget numberField(
  TextEditingController controller,
  String label, {
  bool money = false,
  bool zero = false,
  bool signed = false,
  Key? key,
  String? helper,
}) => TextFormField(
  key: key,
  controller: controller,
  keyboardType: TextInputType.numberWithOptions(decimal: true, signed: signed),
  decoration: InputDecoration(
    labelText: label,
    helperText:
        helper ??
        (money
            ? 'Format Indonesia: 10.000,50'
            : 'Desimal: 0,001 atau 0.001; tanpa pemisah ribuan'),
  ),
  validator: (text) {
    try {
      final value = money
          ? Money.input(text ?? '').minor
          : Decimal.input(text ?? '').raw;
      if (!signed && (zero ? value.isNegative : value <= BigInt.zero)) {
        return zero ? 'Minimal 0.' : 'Harus lebih dari 0.';
      }
      return null;
    } on FormatException catch (e) {
      return e.message;
    }
  },
);
Widget accountField(
  List<Account> accounts,
  String? selected,
  ValueChanged<String> onChanged, {
  String label = 'Aset',
  Key? key,
}) => FinanceSelect<String>(
  key: key ?? ValueKey('account-$label-$selected'),
  initialValue: selected,
  isExpanded: true,
  decoration: InputDecoration(labelText: label),
  items: accounts
      .map(
        (a) => DropdownMenuItem(
          value: a.id,
          child: Text(
            '${a.name} · ${a.currency}',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      )
      .toList(),
  validator: (v) => v == null ? 'Pilih aset.' : null,
  onChanged: (v) {
    if (v != null) onChanged(v);
  },
);
Future<String?> pickFinanceDate(
  BuildContext context,
  String current, {
  DateTime? now,
}) async {
  final value = await showDatePicker(
    context: context,
    initialDate: DateTime.parse(current),
    firstDate: DateTime(1900),
    lastDate: now ?? DateTime(2199, 12, 31),
  );
  return value == null ? null : localDate(value);
}

void financeMessage(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
Future<void> finishFinanceSave(
  BuildContext context,
  FinanceController c,
  Future<bool> action,
) async {
  final ok = await action;
  if (!context.mounted) return;
  if (ok) {
    Navigator.pop(context);
  } else {
    financeMessage(context, c.error ?? 'Belum berhasil.');
  }
}
