import 'package:material_ui/material_ui.dart';

import '../controllers/finance_controller.dart';
import '../models/ledger.dart';
import '../routes/app_routes.dart';
import '../widgets/balance_card.dart';
import '../widgets/finance_fields.dart';
import '../widgets/provider_logo.dart';
import '../widgets/finance_empty_state.dart';
import 'transaction_form.dart';

class AssetDetailScreen extends StatelessWidget {
  const AssetDetailScreen({
    super.key,
    required this.controller,
    required this.id,
  });
  final FinanceController controller;
  final String id;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final data = controller.snapshot,
          account = data.accounts.where((a) => a.id == id).firstOrNull;
      if (account == null) {
        return const Scaffold(
          body: Center(child: Text('Aset tidak tersedia.')),
        );
      }
      final txs = data.transactions
          .where((t) => t.accountId == id || t.destinationId == id)
          .toList();
      return Scaffold(
        appBar: AppBar(title: Text(account.name)),
        body: financeBody([
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: ProviderLogo(
                      provider: account.providerId,
                      name: account.name,
                      kind: account.kind,
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(accountLabel(account.kind), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  MoneyText(
                    data.balance(id),
                    currency: account.currency,
                    hidden: controller.amountsHidden,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    account.kind == AccountKind.debit
                        ? 'Saldo kantong kartu berdiri sendiri. Isi saldo melalui transfer dari bank.'
                        : 'Saldo awal dan transaksi membentuk saldo aset ini.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          FilledButton(
            onPressed: controller.busy
                ? null
                : () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransactionForm(
                        controller: controller,
                        initialAccountId: id,
                      ),
                    ),
                  ),
            child: const Text('Catat transaksi'),
          ),
          OutlinedButton(
            onPressed: controller.busy
                ? null
                : () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransactionForm(
                        controller: controller,
                        initialAccountId: id,
                        initialKind: TransactionKind.transfer,
                      ),
                    ),
                  ),
            child: const Text('Transfer dari aset ini'),
          ),
          Text(
            'Riwayat transaksi',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (txs.isEmpty)
            const FinanceEmptyState(
              message: 'Belum ada transaksi untuk aset ini.',
            ),
          for (final tx in txs)
            ListTile(
              title: Text(
                tx.kind == TransactionKind.transfer ? 'Transfer' : tx.category,
              ),
              subtitle: Text('${tx.date} ${tx.time ?? ''}'),
              trailing: SizedBox(
                width: 140,
                child: MoneyText(
                  tx.deltaFor(id),
                  currency: account.currency,
                  hidden: controller.amountsHidden,
                ),
              ),
              onTap: () =>
                  AppRoutes.transaction(context, controller, existing: tx),
            ),
        ]),
      );
    },
  );
}
