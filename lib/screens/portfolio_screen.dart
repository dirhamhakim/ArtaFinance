import '../widgets/balance_card.dart';
import '../widgets/finance_charts.dart';
import '../models/ledger.dart';
import '../models/money.dart';
import '../widgets/arta_icon.dart';

import 'package:material_ui/material_ui.dart';

import '../controllers/finance_controller.dart';
import '../models/investment.dart';
import '../widgets/finance_fields.dart';
import '../widgets/finance_empty_state.dart';
import 'performance_screen.dart';
import 'catalog_screen.dart';
import 'investment_form.dart';
import 'market_settings_screen.dart';
import 'staking_screen.dart';
import '../services/analytics_service.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({
    super.key,
    required this.controller,
    this.embedded = false,
    this.initialType,
  });
  final FinanceController controller;
  final bool embedded;
  final InstrumentKind? initialType;
  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  String query = '';
  late InstrumentKind? type = widget.initialType;
  int days = 30;
  Object? cachedSnapshot;
  int? cachedDays;
  String? cachedDate;
  List<AnalyticsPoint> points = [];
  FinanceController get c => widget.controller;
  void open(Widget page) =>
      Navigator.push<void>(context, MaterialPageRoute(builder: (_) => page));

  Future<void> actions() => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Kelola investasi',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final (label, glyph, action)
                in <(String, String, VoidCallback)>[
                  (
                    'Catat investasi',
                    'plus',
                    () => open(InvestmentForm(controller: c)),
                  ),
                  (
                    'Staking crypto',
                    'staking',
                    () => open(StakingScreen(controller: c)),
                  ),
                  (
                    'Saham vs IHSG',
                    'stocks',
                    () => open(PerformanceScreen(controller: c)),
                  ),
                  (
                    'Katalog instrumen',
                    'search',
                    () => open(CatalogScreen(controller: c)),
                  ),
                  (
                    'Sumber harga & kurs',
                    'settings',
                    () => open(MarketSettingsScreen(controller: c)),
                  ),
                  (
                    'Perbarui penutupan',
                    'calendar',
                    () => c.refreshDailyCloses(force: true),
                  ),
                  (
                    'Harga terbaru (manual)',
                    'refresh',
                    () async {
                      await c.refreshPrices();
                      if (mounted) {
                        financeMessage(
                          this.context,
                          c.error ?? c.marketMessage ?? 'Selesai.',
                        );
                      }
                    },
                  ),
                ])
              ListTile(
                leading: DesignGlyph(glyph),
                title: Text(label),
                onTap: c.busy || c.pricesBusy
                    ? null
                    : () {
                        Navigator.pop(context);
                        action();
                      },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: c,
    builder: (context, _) {
      final data = c.snapshot,
          extras = data.extras,
          colors = Theme.of(context).colorScheme;
      final today = localDate(c.clock().toUtc().add(const Duration(hours: 7)));
      if (!identical(cachedSnapshot, data) ||
          cachedDays != days ||
          cachedDate != today) {
        points = AnalyticsService().history(data, c.clock(), days: days);
        cachedSnapshot = data;
        cachedDays = days;
        cachedDate = today;
      }
      final holdings = extras.holdings.where((h) => h.quantity.positive).where((
        h,
      ) {
        final i = extras.instruments.firstWhere((i) => i.id == h.instrumentId);
        return (type == null || i.kind == type) &&
            '${i.code} ${i.displayName} ${data.accounts.firstWhere((a) => a.id == h.accountId).name}'
                .toLowerCase()
                .contains(query.toLowerCase());
      }).toList();
      final events = [...extras.events]
        ..sort(
          (a, b) => '${b.date}${b.time ?? ''}${b.createdAt}'.compareTo(
            '${a.date}${a.time ?? ''}${a.createdAt}',
          ),
        );
      final knownCost = extras.holdings
          .where(
            (h) =>
                h.quantity.positive &&
                h.cost != null &&
                extras.holdingValue(h) != null,
          )
          .fold(Money.zero, (sum, h) => sum + h.cost!);
      final knownValue = extras.holdings
          .where(
            (h) =>
                h.quantity.positive &&
                h.cost != null &&
                extras.holdingValue(h) != null,
          )
          .fold(Money.zero, (sum, h) => sum + extras.holdingValue(h)!);
      final pnl = knownValue - knownCost;
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !widget.embedded,
          title: const Text('Portofolio'),
          actions: [
            IconButton(
              tooltip: 'Kelola investasi',
              onPressed: actions,
              icon: const DesignGlyph('more'),
            ),
          ],
        ),
        body: financeBody([
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
                          'Total investasi',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Tampilkan / sembunyikan nominal',
                        onPressed: c.busy
                            ? null
                            : () => c.setAmountsHidden(!c.amountsHidden),
                        icon: DesignGlyph(c.amountsHidden ? 'eye-off' : 'eye'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  MoneyText(
                    data.investmentValue,
                    hidden: c.amountsHidden,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Laba/rugi posisi dengan modal diketahui',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  MoneyText(
                    pnl,
                    hidden: c.amountsHidden,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: pnl.isNegative ? colors.error : colors.primary,
                    ),
                  ),
                  if (data.unpricedHoldings > 0)
                    Text(
                      '${data.unpricedHoldings} posisi tanpa harga/kurs. Total belum lengkap.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (extras.holdings.any(
                    (h) => h.quantity.positive && h.cost == null,
                  ))
                    Text(
                      'Sebagian modal belum diketahui; laba/rugi belum lengkap.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 16),
                  if (c.amountsHidden)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Grafik disembunyikan ••••••'),
                    )
                  else
                    FinanceLineChart(
                      dates: points.map((p) => p.date).toList(),
                      lines: [
                        ChartLine(
                          'Nilai investasi',
                          points.map((p) => p.investment).toList(),
                          colors.primary,
                        ),
                      ],
                    ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (final (label, value) in [
                          ('1B', 30),
                          ('3B', 90),
                          ('6B', 180),
                          ('1T', 365),
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(label),
                              selected: days == value,
                              onSelected: (_) => setState(() => days = value),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    'Perubahan nilai mencakup setoran dan penarikan. Lihat Saham vs IHSG untuk kinerja saham.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: ExpansionTile(
              key: const PageStorageKey('portfolio-composition-expanded'),
              title: const Text('Komposisi portofolio'),
              leading: const DesignGlyph('portfolio'),
              childrenPadding: const EdgeInsets.all(16),
              children: [
                if (c.amountsHidden)
                  const Text('Komposisi disembunyikan ••••••')
                else
                  FinanceDonutChart(
                    composition: AnalyticsService().composition(
                      data,
                      AssetScope.investment,
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const Key('add-investment'),
                  onPressed: c.busy || data.accounts.isEmpty
                      ? null
                      : () => open(InvestmentForm(controller: c)),
                  icon: const DesignGlyph('plus'),
                  label: const Text('Catat investasi'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Saham vs IHSG',
                onPressed: () => open(PerformanceScreen(controller: c)),
                icon: DesignGlyph('stocks', color: colors.secondary),
              ),
              IconButton(
                tooltip: 'Staking crypto',
                onPressed: () => open(StakingScreen(controller: c)),
                icon: const DesignGlyph('staking'),
              ),
            ],
          ),
          if (data.accounts.isEmpty)
            const Text(
              'Tambahkan aset bank/RDN/exchange terlebih dahulu pada menu Aset.',
            ),
          if (c.busy || c.pricesBusy) const LinearProgressIndicator(),
          if (c.marketMessage != null)
            Text(
              c.marketMessage!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (extras.referenceIssues.isNotEmpty)
            Text(
              'Riwayat bawaan belum terbaca: ${extras.referenceIssues.join(', ')}. Harga manual tetap tersedia.',
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (label, value) in <(String, InstrumentKind?)>[
                  ('Semua', null),
                  ('Saham', InstrumentKind.stock),
                  ('Crypto', InstrumentKind.crypto),
                  ('Reksa dana', InstrumentKind.fund),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: type == value,
                      onSelected: (_) => setState(() => type = value),
                    ),
                  ),
              ],
            ),
          ),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Cari kepemilikan',
              prefixIcon: Padding(
                padding: EdgeInsets.all(16),
                child: DesignGlyph('search', size: 20),
              ),
            ),
            onChanged: (v) => setState(() => query = v),
          ),
          if (holdings.isEmpty)
            const FinanceEmptyState(
              message: 'Belum ada kepemilikan yang sesuai. Catat pembelian atau unit awal.',
              kind: EmptyKind.accounts,
            ),
          for (final h in holdings)
            Builder(
              builder: (context) {
                final i = extras.instruments.firstWhere(
                      (i) => i.id == h.instrumentId,
                    ),
                    q = extras.latest(h.instrumentId);
                final value = extras.holdingValue(h),
                    profit = value == null || h.cost == null
                        ? null
                        : value - h.cost!;
                return Card(
                  child: ExpansionTile(
                    key: PageStorageKey(
                      'holding-${h.accountId}-${h.instrumentId}',
                    ),
                    leading: InstrumentLogo(i),
                    title: Text(i.code),
                    subtitle: Text(
                      '${data.accounts.firstWhere((a) => a.id == h.accountId).name} · ${c.amountsHidden ? '••••••' : h.quantity.text} unit',
                    ),
                    trailing: SizedBox(
                      width: MediaQuery.sizeOf(context).width * .30,
                      child: value == null
                          ? Text(
                              'Belum dinilai',
                              style: Theme.of(context).textTheme.bodySmall,
                            )
                          : MoneyText(
                              value,
                              hidden: c.amountsHidden,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Divider(),
                      const SizedBox(height: 12),
                      Text(i.displayName),
                      if (h.locked.positive)
                        Text(
                          'Unit bebas: ${c.amountsHidden ? '••••••' : h.available.text} · Staking/unstake: ${c.amountsHidden ? '••••••' : h.locked.text}',
                        ),
                      Text(
                        'Modal: ${h.cost == null ? 'Belum diketahui' : c.displayMoney(h.cost!)}',
                      ),
                      Text(
                        'Laba/rugi belum terealisasi: ${profit == null ? 'Belum diketahui' : c.displayMoney(profit)}',
                        style: TextStyle(
                          color: profit?.isNegative == true
                              ? colors.error
                              : colors.primary,
                        ),
                      ),
                      Text(
                        'Laba/rugi terealisasi: ${h.realized == null ? 'Modal historis tidak lengkap' : c.displayMoney(h.realized!)}',
                      ),
                      Text(
                        q == null
                            ? 'Harga belum tersedia'
                            : 'Harga penutupan ${q.date} · ${q.source}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (extras.latest(i.id, live: true) case final latest?)
                        Text(
                          'Harga terbaru manual: ${c.amountsHidden ? '••••••' : '${latest.currency} ${latest.price.text}'} · ${latest.asOf ?? latest.date}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: () => open(
                              InstrumentDetailScreen(
                                controller: c,
                                instrument: i,
                              ),
                            ),
                            child: const Text('Grafik & detail'),
                          ),
                          TextButton(
                            onPressed: () =>
                                open(PriceForm(controller: c, instrument: i)),
                            child: const Text('Harga / NAB manual'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          Text(
            'Riwayat investasi',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final e in events.take(5))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const DesignGlyph('history'),
              title: Text(
                '${investmentLabel(e.kind)} · ${extras.instruments.firstWhere((i) => i.id == e.instrumentId).code}',
              ),
              subtitle: Text('${e.date} ${e.time ?? ''}'),
              trailing: const DesignGlyph('chevron-right'),
              onTap: c.busy
                  ? null
                  : () => open(
                      isStaking(e.kind)
                          ? StakingEventForm(controller: c, existing: e)
                          : InvestmentForm(controller: c, existing: e),
                    ),
            ),
          if (events.isNotEmpty)
            TextButton(
              onPressed: () => open(InvestmentHistoryScreen(controller: c)),
              child: const Text('Lihat semua riwayat investasi'),
            ),
        ]),
      );
    },
  );
}

class InvestmentHistoryScreen extends StatelessWidget {
  const InvestmentHistoryScreen({super.key, required this.controller});
  final FinanceController controller;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (ctx, _) {
      final rows = [...controller.snapshot.extras.events]
        ..sort((a, b) => b.date.compareTo(a.date));
      return Scaffold(
        appBar: AppBar(title: const Text('Seluruh riwayat investasi')),
        body: ListView.builder(
          itemCount: rows.length,
          itemBuilder: (ctx, n) {
            final e = rows[n];
            return ListTile(
              title: Text(
                '${investmentLabel(e.kind)} · ${controller.snapshot.extras.instruments.firstWhere((i) => i.id == e.instrumentId).code}',
              ),
              subtitle: Text(
                '${e.date} · ${controller.amountsHidden ? '••••••' : e.quantity.text} unit',
              ),
              onTap: () => Navigator.push<void>(
                ctx,
                MaterialPageRoute(
                  builder: (_) => isStaking(e.kind)
                      ? StakingEventForm(controller: controller, existing: e)
                      : InvestmentForm(controller: controller, existing: e),
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

class InstrumentDetailScreen extends StatefulWidget {
  const InstrumentDetailScreen({
    super.key,
    required this.controller,
    required this.instrument,
  });
  final FinanceController controller;
  final Instrument instrument;
  @override
  State<InstrumentDetailScreen> createState() => _InstrumentDetailScreenState();
}

class _InstrumentDetailScreenState extends State<InstrumentDetailScreen> {
  FinanceController get controller => widget.controller;
  Instrument get instrument => widget.instrument;
  int _visible = 60;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.loadInstrumentHistory(instrument.id);
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (ctx, _) {
      final quotes =
          controller.snapshot.extras.allQuotes
              .where((q) => q.instrumentId == instrument.id && !q.isLive)
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));
      final daily = <String, PriceQuote>{};
      for (final q in quotes) {
        final old = daily[q.date];
        if (old == null || comparePriceQuotes(q, old) < 0) {
          daily[q.date] = q;
        }
      }
      final series = daily.values.toList();
      return Scaffold(
        appBar: AppBar(title: Text('${instrument.code} · harga')),
        body: financeBody([
          Text(
            instrument.displayName,
            style: Theme.of(ctx).textTheme.titleLarge,
          ),
          const Text(
            'Grafik memakai riwayat harga penutupan/manual tersimpan; harga terbaru manual dipisahkan. Ini bukan grafik keuntungan portofolio.',
          ),
          if (series.any((q) => q.adjustedThrough != null))
            const Text(
              'Riwayat sumber disesuaikan stock split. Grafik harga memakai basis sumber; valuasi portofolio menyesuaikan dengan split yang dicatat di ledger.',
            ),
          if (!controller.amountsHidden && series.length > 1)
            SizedBox(
              height: 180,
              child: CustomPaint(
                painter: _PricePainter(
                  series,
                  Theme.of(ctx).colorScheme.primary,
                ),
              ),
            ),
          if (series.length < 2)
            const FinanceEmptyState(
              message: 'Grafik muncul setelah tersedia harga pada dua tanggal berbeda.',
              kind: EmptyKind.transactions,
            ),
          FilledButton(
            onPressed: controller.busy
                ? null
                : () => Navigator.push<void>(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => PriceForm(
                        controller: controller,
                        instrument: instrument,
                      ),
                    ),
                  ),
            child: const Text('Input harga / NAB'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.push<void>(
              ctx,
              MaterialPageRoute(
                builder: (_) => InstrumentForm(
                  controller: controller,
                  existing: instrument,
                ),
              ),
            ),
            child: const Text('Metadata & mapping harga'),
          ),
          if (controller.busy) const LinearProgressIndicator(),
          for (final q in series.reversed.take(_visible))
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                '${q.date} · ${controller.amountsHidden ? '••••••' : '${q.currency} ${q.price.text}'}',
              ),
              subtitle: Text(
                '${q.source}${q.asOf == null ? '' : '\nWaktu sumber ${q.asOf}'}\nDiambil ${q.fetchedAt}',
              ),
            ),
          if (series.length > _visible)
            OutlinedButton(
              onPressed: () => setState(() => _visible += 60),
              child: Text(
                'Tampilkan 60 berikutnya (${series.length - _visible} tersisa)',
              ),
            ),
        ]),
      );
    },
  );
}

class _PricePainter extends CustomPainter {
  _PricePainter(this.values, this.color);
  final List<PriceQuote> values;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final raw = values.map((q) => q.price.raw).toList();
    var min = raw.first, max = raw.first;
    for (final v in raw) {
      if (v < min) min = v;
      if (v > max) max = v;
    }
    final range = max - min;
    final path = Path();
    final first = DateTime.parse(values.first.date).millisecondsSinceEpoch,
        last = DateTime.parse(values.last.date).millisecondsSinceEpoch;
    for (var n = 0; n < values.length; n++) {
      final x =
          8 +
          (DateTime.parse(values[n].date).millisecondsSinceEpoch - first) /
              (last - first) *
              (size.width - 16);
      final ratio = range == BigInt.zero
          ? 0.5
          : ((raw[n] - min) * BigInt.from(10000) ~/ range).toInt() / 10000;
      final y = size.height - 8 - ratio * (size.height - 16);
      if (n == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _PricePainter old) =>
      old.values != values || old.color != color;
}
