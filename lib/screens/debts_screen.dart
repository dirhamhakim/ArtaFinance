import 'package:material_ui/material_ui.dart';

import '../controllers/finance_controller.dart';
import '../models/ledger.dart';
import '../models/money.dart';
import '../widgets/finance_fields.dart';
import '../widgets/finance_empty_state.dart';
import 'account_form.dart';
import 'transaction_form.dart';

class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key, required this.controller});
  final FinanceController controller;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (ctx, _) {
      final rows = controller.snapshot.accounts
          .where(
            (a) => {
              AccountKind.liability,
              AccountKind.receivable,
            }.contains(a.kind),
          )
          .toList();
      void open(Widget page) =>
          Navigator.push<void>(ctx, MaterialPageRoute(builder: (_) => page));
      return Scaffold(
        appBar: AppBar(title: const Text('Utang & piutang')),
        body: financeBody([
          const Text(
            'Pokok dicatat sebagai transfer antar aset. Utang bersaldo minus, piutang bersaldo positif; keduanya masuk kekayaan bersih dengan tanda aslinya. Bunga dan biaya dicatat terpisah. Tidak ada debit bank otomatis.',
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: controller.busy
                    ? null
                    : () => open(
                        AccountForm(
                          controller: controller,
                          initialKind: AccountKind.liability,
                        ),
                      ),
                child: const Text('Tambah aset utang'),
              ),
              OutlinedButton(
                onPressed: controller.busy
                    ? null
                    : () => open(
                        AccountForm(
                          controller: controller,
                          initialKind: AccountKind.receivable,
                        ),
                      ),
                child: const Text('Tambah aset piutang'),
              ),
            ],
          ),
          if (rows.isEmpty)
            const FinanceEmptyState(
              message: 'Belum ada utang atau piutang.',
              kind: EmptyKind.accounts,
            ),
          for (final account in rows)
            Builder(
              builder: (ctx) {
                final balance = controller.snapshot.balance(account.id),
                    debt = account.kind == AccountKind.liability;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          account.name,
                          style: Theme.of(ctx).textTheme.titleMedium,
                        ),
                        Text(
                          '${accountLabel(account.kind)} · ${account.currency}',
                        ),
                        Text(
                          'Saldo aset: ${controller.displayCurrency(balance, account.currency)}',
                        ),
                        if (debt)
                          Text(
                            'Sisa pokok/tagihan tercatat: ${controller.displayCurrency(balance.isNegative ? -balance : Money.zero, account.currency)}',
                          ),
                        if (debt && !balance.isNegative && !balance.isZero)
                          const Text(
                            'Saldo positif menunjukkan kelebihan bayar atau kredit yang belum dipakai.',
                          ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: controller.busy
                                  ? null
                                  : () => open(
                                      TransactionForm(
                                        controller: controller,
                                        initialAccountId: account.id,
                                        initialKind: TransactionKind.transfer,
                                      ),
                                    ),
                              child: Text(
                                debt ? 'Terima pinjaman' : 'Terima pembayaran',
                              ),
                            ),
                            OutlinedButton(
                              onPressed: controller.busy
                                  ? null
                                  : () => open(
                                      TransactionForm(
                                        controller: controller,
                                        initialAccountId:
                                            controller.snapshot.accounts
                                                .where(
                                                  (a) => a.id != account.id,
                                                )
                                                .firstOrNull
                                                ?.id ??
                                            account.id,
                                        initialDestinationId: account.id,
                                        initialKind: TransactionKind.transfer,
                                      ),
                                    ),
                              child: Text(
                                debt ? 'Bayar pokok' : 'Berikan pinjaman',
                              ),
                            ),
                            if (debt)
                              TextButton(
                                onPressed: controller.busy
                                    ? null
                                    : () => open(
                                        TransactionForm(
                                          controller: controller,
                                          initialAccountId: account.id,
                                          initialKind: TransactionKind.expense,
                                        ),
                                      ),
                                child: const Text('Belanja kartu kredit'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const Text(
            'Cicilan pokok tetap dapat memakai jadwal Transfer ke aset Utang. Jadwalkan bunga/biaya sebagai Pengeluaran dari aset pembayar. Fitur ini tidak menebak amortisasi, limit kartu, tanggal cetak, minimum payment atau jumlah bunga. Gunakan rincian pemberi pinjaman/lembar tagihan aktual.',
          ),
        ]),
      );
    },
  );
}
