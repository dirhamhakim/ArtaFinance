import 'package:material_ui/material_ui.dart';

/// Nilai efektif saat disimpan ditentukan form, bukan teks draft yang tersembunyi.
class TransferFeeField extends StatelessWidget {
  const TransferFeeField({
    super.key,
    required this.enabled,
    required this.controller,
    required this.onChanged,
    required this.validator,
    this.actual = false,
    this.currency = 'IDR',
    this.senderEnabled = true,
    this.receiverEnabled = false,
    this.receiverController,
    this.onSenderChanged,
    this.onReceiverChanged,
    this.receiverCurrency,
  });

  final bool enabled, actual;
  final String currency;
  final TextEditingController controller;
  final ValueChanged<bool>? onChanged;
  final FormFieldValidator<String> validator;
  final bool senderEnabled, receiverEnabled;
  final TextEditingController? receiverController;
  final ValueChanged<bool>? onSenderChanged, onReceiverChanged;
  final String? receiverCurrency;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SwitchListTile.adaptive(
        key: const Key('fee-enabled'),
        contentPadding: EdgeInsets.zero,
        title: const Text('Biaya transaksi'),
        subtitle: Text(
          receiverController == null
              ? 'Tambahkan biaya transfer dari aset asal'
              : 'Aktifkan biaya pengirim atau penerima',
        ),
        value: enabled,
        onChanged: onChanged,
      ),
      if (enabled) ...[
        if (receiverController != null)
          SwitchListTile.adaptive(
            key: const Key('fee-sender-enabled'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Biaya pengirim'),
            value: senderEnabled,
            onChanged: onSenderChanged,
          ),
        const SizedBox(height: 12),
        if (senderEnabled)
          TextFormField(
            key: const Key('fee-amount'),
            controller: controller,
            enabled: onChanged != null,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: actual
                  ? 'Biaya aktual ($currency)'
                  : 'Biaya transaksi ($currency)',
              helperText:
                  'Dipotong dari aset asal dan dihitung sebagai pengeluaran.',
            ),
            validator: validator,
          ),
        if (receiverController != null) ...[
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            key: const Key('fee-receiver-enabled'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Biaya penerima'),
            subtitle: const Text(
              'Dikurangi dari nominal yang masuk ke aset tujuan',
            ),
            value: receiverEnabled,
            onChanged: onReceiverChanged,
          ),
          if (receiverEnabled)
            TextFormField(
              key: const Key('receiver-fee-amount'),
              controller: receiverController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText:
                    'Nominal biaya penerima (${receiverCurrency ?? currency})',
              ),
              validator: validator,
            ),
        ],
      ],
    ],
  );
}
