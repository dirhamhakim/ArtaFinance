import '../widgets/arta_icon.dart';

import 'package:material_ui/material_ui.dart';
import 'package:feather_icons/feather_icons.dart';

import '../controllers/finance_controller.dart';
import '../models/money.dart';
import '../services/performance_service.dart';
import '../widgets/finance_charts.dart';
import '../widgets/finance_fields.dart';
import '../widgets/finance_empty_state.dart';
import '../widgets/finance_surfaces.dart';

String performancePercent(Money value) {
  final a = value.minor.abs();
  return '${value.isNegative
      ? '-'
      : value.isPositive
      ? '+'
      : ''}${a ~/ BigInt.from(100)},${(a % BigInt.from(100)).toString().padLeft(2, '0')}%';
}

String performanceAxis(BigInt minor) {
  final tenths = (minor.abs() + BigInt.from(5)) ~/ BigInt.from(10);
  final fraction = tenths % BigInt.from(10);
  return '${minor.isNegative ? '-' : ''}${tenths ~/ BigInt.from(10)}${fraction == BigInt.zero ? '' : ',$fraction'}%';
}

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key, required this.controller});
  final FinanceController controller;
  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  int? days = 365;
  bool dividends = false;
  final service = PerformanceService();
  Object? cachedSnapshot, cachedBenchmark;
  int? cachedDays;
  bool? cachedDividends;
  String? cachedDay;
  PerformanceResult result = const PerformanceResult([], {}, false);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await widget.controller.benchmark?.load();
      if (mounted) widget.controller.refreshBenchmark();
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (ctx, _) {
      final c = widget.controller, b = c.benchmark;
      final now = c.clock();
      final currentDay = now
          .toUtc()
          .add(const Duration(hours: 7))
          .toIso8601String()
          .substring(0, 10);
      if (!identical(cachedSnapshot, c.snapshot) ||
          !identical(cachedBenchmark, b?.quotes) ||
          cachedDays != days ||
          cachedDividends != dividends ||
          cachedDay != currentDay) {
        result = service.compare(
          c.snapshot,
          b?.quotes ?? [],
          now,
          days: days,
          dividends: dividends,
        );
        cachedSnapshot = c.snapshot;
        cachedBenchmark = b?.quotes;
        cachedDays = days;
        cachedDividends = dividends;
        cachedDay = currentDay;
      }
      final points = result.points, last = points.lastOrNull;
      final difference = last?.portfolio == null
          ? null
          : last!.portfolio! - last.ihsg;
      final colors = Theme.of(ctx).colorScheme;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Saham vs IHSG'),
          actions: [
            IconButton(
              tooltip: 'Perbarui IHSG',
              onPressed: b?.busy == true
                  ? null
                  : () => c.refreshBenchmark(force: true),
              icon: const ArtaIcon(FeatherIcons.refreshCw),
            ),
          ],
        ),
        body: financeBody([
          FinanceHero(
            label: 'Kinerja portofolio saham',
            trailing: IconButton(
              tooltip: 'Tampilkan / sembunyikan nominal',
              onPressed: c.busy
                  ? null
                  : () => c.setAmountsHidden(!c.amountsHidden),
              icon: ArtaIcon(
                c.amountsHidden ? FeatherIcons.eyeOff : FeatherIcons.eye,
              ),
            ),
            value: c.amountsHidden
                ? '••••••'
                : last?.portfolio == null
                ? 'Belum tersedia'
                : performancePercent(last!.portfolio!),
            details: [
              Text(
                'Estimasi TWR · ${dividends ? 'termasuk dividen neto' : 'tanpa dividen tunai'}',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              if (!c.amountsHidden && difference != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${performancePercent(difference).replaceFirst('%', ' poin persentase')} terhadap IHSG',
                    style: TextStyle(
                      color: difference.isNegative
                          ? colors.error
                          : colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
            footer: Text(
              points.isEmpty
                  ? 'Mulai setelah harga dan kepemilikan tersedia.'
                  : '${points.first.date} — ${points.last.date} · basis awal 0%',
            ),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
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
          if (b?.busy == true) const LinearProgressIndicator(),
          if (b?.message != null)
            Text(b!.message!, style: Theme.of(ctx).textTheme.bodySmall),
          if (points.isEmpty)
            const FinanceEmptyState(
              message: 'Belum ada periode saham dan IHSG yang dapat dibandingkan. Catat kepemilikan saham dan lengkapi harga penutupannya.',
              kind: EmptyKind.accounts,
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Portofolio & pasar',
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    if (c.amountsHidden)
                      const Text('Return dan grafik disembunyikan ••••••')
                    else
                      FinanceLineChart(
                        dates: points.map((p) => p.date).toList(),
                        lines: [
                          ChartLine(
                            'Portofolio saham',
                            points.map((p) => p.portfolio).toList(),
                            colors.primary,
                          ),
                          ChartLine(
                            'IHSG',
                            points.map((p) => p.ihsg).toList(),
                            colors.secondary,
                          ),
                        ],
                        formatValue: performancePercent,
                        formatAxis: performanceAxis,
                      ),
                  ],
                ),
              ),
            ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Sertakan dividen neto'),
            subtitle: const Text(
              'IHSG tetap indeks harga. Aktifkan untuk melihat hasil saham termasuk dividen aktual.',
            ),
            value: dividends,
            onChanged: (v) => setState(() => dividends = v),
          ),
          if (result.issues.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(result.issues.join('\n')),
              ),
            ),
          const ExpansionTile(
            key: PageStorageKey('performance-method-expanded'),
            title: Text('Cara menghitung perbandingan'),
            childrenPadding: EdgeInsets.all(16),
            children: [
              Text(
                'Semua saham di seluruh lokasi dihitung bersama. Crypto, reksa dana, saldo bank dan kas RDN tidak termasuk. Kedua garis mulai dari 0% pada penutupan pertama yang sama dalam periode pilihan.',
              ),
              SizedBox(height: 12),
              Text(
                'Beli dan saldo unit awal adalah penambahan modal; jual adalah penarikan. Transfer unit internal dan split tidak menjadi keuntungan atau setoran baru. Fee transaksi tetap mengurangi kinerja.',
              ),
              SizedBox(height: 12),
              Text(
                'TWR dihubungkan pada setiap transaksi. Saham yang diperdagangkan dinilai pada harga eksekusi; saham lain memakai close terakhir, sehingga hasil merupakan estimasi dengan data harian, bukan TWR intraday penuh. Return hari pertama sebelum titik awal tidak dihitung.',
              ),
              SizedBox(height: 12),
              Text(
                'Harga masa depan tidak dipakai mundur. Jika valuasi hilang setelah titik awal, return portofolio tidak disambung secara fiktif. Lengkapi harga atau pilih periode dengan data lengkap. IHSG memakai sesi penutupan yang tersedia; aplikasi tidak membuat tanggal libur.',
              ),
            ],
          ),
        ]),
      );
    },
  );
}
