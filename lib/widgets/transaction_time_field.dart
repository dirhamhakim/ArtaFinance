import 'finance_date_field.dart';

import 'package:material_ui/material_ui.dart';

import '../models/ledger.dart';

class TransactionTimeField extends StatelessWidget {
  const TransactionTimeField({
    super.key,
    required this.value,
    required this.onChanged,
    this.zone = 'Asia/Jakarta',
  });
  final String? value;
  final String zone;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) => FinanceDateField(
    label: 'Waktu',
    glyph: 'clock',
    value: '${value ?? "Belum dicatat"} · ${zone.split("/").last}',
    key: const Key('transaction-time'),
    onTap: onChanged == null
        ? null
        : () async {
            final parts = value?.split(':');
            final picked = await showTimePicker(
              context: context,
              initialTime: parts == null
                  ? TimeOfDay.now()
                  : TimeOfDay(
                      hour: int.parse(parts[0]),
                      minute: int.parse(parts[1]),
                    ),
              initialEntryMode: TimePickerEntryMode.dialOnly,
              helpText: 'Pilih jam dan menit',
              cancelText: 'Batal',
              confirmText: 'Simpan',
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(alwaysUse24HourFormat: true),
                child: child!,
              ),
            );
            if (picked != null) {
              onChanged!(
                localTime(DateTime(2000, 1, 1, picked.hour, picked.minute)),
              );
            }
          },
  );
}
