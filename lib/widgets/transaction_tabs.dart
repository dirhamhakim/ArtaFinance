import 'package:material_ui/material_ui.dart';

import '../models/ledger.dart';

class TransactionTabs extends StatelessWidget {
  const TransactionTabs({
    super.key,
    required this.value,
    required this.onChanged,
    this.installment = false,
  });
  final TransactionKind value;
  final ValueChanged<TransactionKind>? onChanged;
  final bool installment;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final type in [
        TransactionKind.expense,
        TransactionKind.income,
        TransactionKind.transfer,
      ])
        Expanded(
          child: InkWell(
            onTap:
                onChanged == null ||
                    (installment && type != TransactionKind.expense)
                ? null
                : () => onChanged!(type),
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: type == value
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                transactionLabel(type),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: type == value ? FontWeight.w700 : FontWeight.w400,
                  color: type == value
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
