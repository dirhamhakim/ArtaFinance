import '../widgets/finance_select.dart';
import '../widgets/arta_icon.dart';

import 'package:feather_icons/feather_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../controllers/finance_controller.dart';
import '../services/analytics_service.dart';
import '../widgets/finance_charts.dart';
import '../widgets/finance_fields.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({
    super.key,
    required this.controller,
    this.initialScope = AssetScope.combined,
  });
  final FinanceController controller;
  final AssetScope initialScope;
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late AssetScope scope = widget.initialScope;
  int? days = 30;
  final service = AnalyticsService();
  Object? cachedSnapshot;
  String? cachedDay;
  int? cachedDays;
  List<AnalyticsPoint> points = [];
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (ctx, _) {
      final c = widget.controller;
      final now = c.clock().toUtc().add(const Duration(hours: 7));
      final today = '${now.year}-${now.month}-${now.day}';
      if (!identical(cachedSnapshot, c.snapshot) ||
          cachedDay != today ||
          cachedDays != days) {
        points = service.history(c.snapshot, c.clock(), days: days);
        cachedSnapshot = c.snapshot;
        cachedDay = today;
        cachedDays = days;
      }
      final missing = points
          .where(
            (p) =>
                scope == AssetScope.cashflow ? false : p.value(scope) == null,
          )
          .length;
      final lines = scope == AssetScope.cashflow
          ? [
              ChartLine(
                'Pemasukan',
                points.map((p) => p.income).toList(),
                Theme.of(ctx).colorScheme.primary,
              ),
              ChartLine(
                'Pengeluaran',
                points.map((p) => p.expense).toList(),
                Theme.of(ctx).colorScheme.error,
              ),
            ]
          : [
              ChartLine(
                scopeLabel(scope),
                points.map((p) => p.value(scope)).toList(),
                Theme.of(ctx).colorScheme.primary,
              ),
            ];
      return Scaffold(
        appBar: AppBar(title: const Text('Analisis & grafik')),
        body: financeBody([
          FinanceSelect<AssetScope>(
            key: ValueKey(scope),
            initialValue: scope,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Jenis analisis'),
            items: [
              for (final s in AssetScope.values)
                DropdownMenuItem(value: s, child: Text(scopeLabel(s))),
            ],
            onChanged: (v) => setState(() => scope = v!),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (label, value) in [
                ('1B', 30),
                ('3B', 90),
                ('6B', 180),
                ('1T', 365),
                ('Semua', null),
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: days == value,
                  onSelected: (_) => setState(() => days = value),
                ),
            ],
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          scope == AssetScope.cashflow
                              ? 'Arus kas per hari / interval'
                              : 'Perkembangan nilai aset',
                          style: Theme.of(ctx).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Tampilkan / sembunyikan nominal',
                        onPressed: c.busy
                            ? null
                            : () => c.setAmountsHidden(!c.amountsHidden),
                        icon: ArtaIcon(
                          c.amountsHidden
                              ? FeatherIcons.eyeOff
                              : FeatherIcons.eye,
                        ),
                      ),
                    ],
                  ),
                  Text(switch (scope) {
                    AssetScope.combined => 'Saldo aset + investasi · IDR',
                    AssetScope.investment => 'Nilai unit investasi · IDR',
                    AssetScope.cash =>
                      'Saldo aset, termasuk kas RDN/exchange · IDR',
                    AssetScope.cashflow => 'Nilai aktual · IDR',
                  }),
                  const SizedBox(height: 12),
                  if (c.amountsHidden)
                    const Text('Nominal dan grafik disembunyikan ••••••')
                  else
                    FinanceLineChart(
                      dates: points.map((p) => p.date).toList(),
                      lines: lines,
                    ),
                  if (!c.amountsHidden && missing > 0)
                    Text(
                      '$missing titik belum lengkap karena harga/kurs belum tersedia. Garis diputus pada data yang belum lengkap.',
                    ),
                ],
              ),
            ),
          ),
          if (scope != AssetScope.cashflow)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Komposisi saat ini',
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (c.amountsHidden)
                      const Text('Komposisi disembunyikan ••••••')
                    else
                      FinanceDonutChart(
                        composition: service.composition(c.snapshot, scope),
                      ),
                  ],
                ),
              ),
            ),
          ExpansionTile(
            key: const PageStorageKey('analytics-method-expanded'),
            title: const Text('Tentang perhitungan'),
            childrenPadding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Investasi mencakup nilai unit saham, crypto, dan reksa dana. Saldo aset mencakup bank, tunai, e-wallet, kantong debit, piutang/utang, serta kas RDN/exchange yang belum dibelanjakan. Kartu yang hanya menaut ke aset tidak dihitung dua kali.',
              ),
              Text(
                scope == AssetScope.cashflow
                    ? 'Transfer pokok, beli/jual investasi, dan pokok pinjaman bukan arus kas pendapatan/konsumsi. Biaya tunai, dividen, bunga aktual dan pajaknya mengikuti laporan transaksi. Reward unit belum dianggap pendapatan kas.'
                    : 'Grafik menunjukkan nilai aset, bukan persentase return. Setoran, penarikan dan perubahan harga ikut mengubah garis. Staking tetap termasuk unit investasi satu kali.',
              ),
              const Text(
                'Harga/kurs terakhir yang diketahui pada atau sebelum tanggal dipakai sampai observasi berikutnya; harga masa depan tidak ditarik mundur. Riwayat saham yang diimpor nanti akan memperbarui grafik ini. Kurs historis yang belum dicatat dapat menghasilkan celah.',
              ),
              const Text(
                'Saldo awal aset berlaku sejak tanggal pembuatan atau transaksi paling awal aset, mana yang lebih dulu. Koreksi saldo awal akan menghitung ulang grafik. Periode panjang diringkas hingga sekitar 366 titik; arus kas dijumlahkan per interval.',
              ),
            ],
          ),
        ]),
      );
    },
  );
}
