import 'package:material_ui/material_ui.dart';

import '../controllers/finance_controller.dart';
import '../models/ledger.dart';
import 'arta_icon.dart';
import 'balance_card.dart';
import 'finance_charts.dart';

class CashflowCarousel extends StatefulWidget {
  const CashflowCarousel({super.key, required this.controller});
  final FinanceController controller;
  @override
  State<CashflowCarousel> createState() => _CashflowCarouselState();
}

class _CashflowCarouselState extends State<CashflowCarousel> {
  int page = 0;
  @override
  Widget build(BuildContext context) {
    final c = widget.controller, colors = Theme.of(context).colorScheme;
    final date = c.clock().toUtc().add(const Duration(hours: 7));
    final month = localDate(date).substring(0, 7);
    final dates = [
      for (var i = 5; i >= 0; i--)
        localDate(DateTime(date.year, date.month - i)),
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Arus kas', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(
              '${months[date.month - 1]} ${date.year} · geser untuk mengganti',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: MediaQuery.textScalerOf(context).scale(14) > 20
                  ? 340
                  : 245,
              child: PageView(
                onPageChanged: (v) => setState(() => page = v),
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (label, value, glyph, color) in [
                        (
                          'Pemasukan',
                          c.snapshot.incomeForMonth(month),
                          'arrow-down',
                          colors.primary,
                        ),
                        (
                          'Pengeluaran',
                          -c.snapshot.expenseForMonth(month),
                          'arrow-up',
                          colors.error,
                        ),
                      ])
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color.withValues(alpha: .18),
                                ),
                                child: Center(
                                  child: DesignGlyph(glyph, color: color),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge,
                                    ),
                                    MoneyText(
                                      value,
                                      hidden: c.amountsHidden,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(color: color),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      Text(
                        'Transfer pokok tidak masuk arus kas.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  c.amountsHidden
                      ? const Center(child: Text('Grafik disembunyikan ••••••'))
                      : FinanceLineChart(
                          dates: dates,
                          compact: true,
                          lines: [
                            ChartLine('Pemasukan', [
                              for (final d in dates)
                                c.snapshot.incomeForMonth(d.substring(0, 7)),
                            ], colors.primary),
                            ChartLine('Pengeluaran', [
                              for (final d in dates)
                                c.snapshot.expenseForMonth(d.substring(0, 7)),
                            ], colors.error),
                          ],
                        ),
                ].map((child) => SingleChildScrollView(child: child)).toList(),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 2; i++)
                  Container(
                    margin: const EdgeInsets.all(3),
                    width: page == i ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: page == i ? colors.primary : colors.outline,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
