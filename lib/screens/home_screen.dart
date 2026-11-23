import '../widgets/finance_dialog.dart';
import '../widgets/balance_card.dart';
import '../config/app_info.dart';
import '../widgets/provider_logo.dart';
import '../widgets/cashflow_carousel.dart';
import '../models/investment.dart';
import 'asset_detail_screen.dart';
import 'schedules_screen.dart';
import '../widgets/finance_select.dart';
import '../widgets/arta_icon.dart';

import 'package:feather_icons/feather_icons.dart';

import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../controllers/finance_controller.dart';
import '../models/ledger.dart';
import '../models/money.dart';
import '../routes/app_routes.dart';
import '../services/backup_files_service.dart';
import '../services/backup_service.dart';
import '../widgets/arta_logo.dart';
import '../widgets/password_field.dart';
import '../widgets/finance_empty_state.dart';
import 'cards_screen.dart';
import 'security_screen.dart';
import 'portfolio_screen.dart';
import 'catalog_screen.dart';
import 'market_settings_screen.dart';
import 'interest_screen.dart';
import 'debts_screen.dart';
import 'analytics_screen.dart';
import 'staking_screen.dart';
import '../services/analytics_service.dart';
import '../services/data_files_service.dart';
import '../services/csv_service.dart';
import '../widgets/finance_surfaces.dart';
import 'performance_screen.dart';
import 'categories_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});
  final FinanceController controller;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int tab = 0;
  String query = '', assetQuery = '';
  AccountKind? assetClass;
  TransactionKind? transactionType;
  String? transactionDate;
  bool fileBusy = false;
  bool foreground = true;
  final files = BackupFilesService();
  FinanceController get controller => widget.controller;
  bool get locked => controller.busy || fileBusy;
  Timer? calendarTimer;
  String lastCalendarDay = '';
  String get calendarDay {
    final now = controller.clock().toUtc();
    return [7, 8, 9]
        .map(
          (h) =>
              '${localDate(now.add(Duration(hours: h)))} ${localTime(now.add(Duration(hours: h)))}',
        )
        .join('/');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    lastCalendarDay = calendarDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.refreshDailyCloses();
    });
    calendarTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!foreground) return;
      if (calendarDay != lastCalendarDay) refreshSchedules();
      controller.refreshDailyCloses();
    });
  }

  @override
  void dispose() {
    calendarTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    controller.marketForeground = foreground;
    if (foreground) {
      refreshSchedules();
      controller.refreshDailyCloses();
    }
  }

  Future<void> refreshSchedules() async {
    if (locked || !mounted) return;
    final ok = await controller.refreshSchedules();
    if (ok) {
      lastCalendarDay = calendarDay;
    } else {
      message(controller.error!);
    }
  }

  void message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  void openPage(Widget page) =>
      Navigator.push<void>(context, MaterialPageRoute(builder: (_) => page));
  Future<void> exportCsv(String table) async {
    if (locked) return;
    setState(() => fileBusy = true);
    try {
      final snapshot = await controller.repository.load();
      final csv = CsvService();
      final bytes = switch (table) {
        'kepemilikan' => csv.holdings(snapshot),
        'harga' => csv.quotes(snapshot),
        _ => csv.transactions(snapshot),
      };
      if (await DataFilesService().save(bytes, 'arta-$table')) {
        message('CSV berhasil disimpan. CSV bukan backup lengkap.');
      }
    } catch (_) {
      message('Ekspor CSV belum berhasil.');
    } finally {
      if (mounted) setState(() => fileBusy = false);
    }
  }

  Widget featureMenu(
    String title,
    String subtitle,
    IconData icon,
    Widget page, {
    Key? key,
  }) => FinanceFeatureTile(
    key: key,
    icon: icon,
    title: title,
    subtitle: subtitle,
    onTap: locked ? null : () => openPage(page),
  );

  Future<String?> password({required bool creating}) async {
    final input = TextEditingController();
    final repeat = TextEditingController();
    final form = GlobalKey<FormState>();
    final result = await showFinanceDialog<String>(
      context: context,
      builder: (context) => FinanceDialog(
        scrollable: true,
        title: Text(creating ? 'Enkripsi backup' : 'Buka backup'),
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                creating
                    ? 'Simpan kata sandi ini. Backup terenkripsi memerlukannya untuk dipulihkan.'
                    : 'Masukkan kata sandi file backup.',
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: input,
                label: 'Kata sandi',
                validator: (v) =>
                    v == null || (creating ? v.length < 8 : v.isEmpty)
                    ? (creating ? 'Minimal 8 karakter.' : 'Isi kata sandi.')
                    : null,
              ),
              if (creating) ...[
                const SizedBox(height: 16),
                PasswordField(
                  controller: repeat,
                  label: 'Ulangi kata sandi',
                  validator: (v) =>
                      v != input.text ? 'Kata sandi berbeda.' : null,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(context, input.text);
              }
            },
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );
    input.dispose();
    repeat.dispose();
    return result;
  }

  Future<void> exportBackup({required bool encrypted}) async {
    if (locked) return;
    setState(() => fileBusy = true);
    try {
      final secret = encrypted ? await password(creating: true) : null;
      if (encrypted && secret == null) return;
      // Baca snapshot database yang konsisten sebelum ekspor.
      final snapshot = await controller.repository.load();
      final bytes = await exportBackupInBackground(snapshot, password: secret);
      final saved = await files.save(
        bytes,
        prefix: encrypted ? 'arta-encrypted' : 'arta-backup',
      );
      if (saved) message('Backup berhasil disimpan.');
    } on FormatException catch (e) {
      message(e.message);
    } catch (_) {
      message('Backup belum berhasil disimpan. Coba lagi.');
    } finally {
      if (mounted) setState(() => fileBusy = false);
    }
  }

  Future<void> restoreBackup() async {
    if (locked) return;
    setState(() => fileBusy = true);
    try {
      final bytes = await files.pick();
      if (bytes == null || !mounted) return;
      final encrypted = await backupIsEncryptedInBackground(bytes);
      if (!mounted) return;
      final secret = encrypted ? await password(creating: false) : null;
      if (encrypted && secret == null) return;
      final imported = await importBackupInBackground(bytes, password: secret);
      if (!mounted) return;
      final accepted = await showFinanceDialog<bool>(
        context: context,
        builder: (context) => FinanceDialog(
          title: const Text('Pulihkan backup?'),
          content: Text(
            '${imported.accounts.length} aset, ${imported.transactions.length} transaksi, '
            '${imported.schedules.length} jadwal, dan ${imported.occurrences.length} riwayat kejadian. '
            'Data saat ini akan diganti. Jadwal otomatis yang tertinggal akan diproses sampai hari ini. Simpan cadangan data saat ini pada langkah berikutnya sebelum melanjutkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Simpan cadangan & pulihkan'),
            ),
          ],
        ),
      );
      if (accepted != true) return;
      final before = await controller.repository.load();
      final recovery = await exportBackupInBackground(before, password: secret);
      final saved = await files.save(recovery, prefix: 'arta-before-restore');
      if (!saved) {
        message('Restore dibatalkan karena cadangan belum disimpan.');
        return;
      }
      final ok = await controller.restore(imported);
      if (ok) {
        setState(() => query = '');
        message('Backup berhasil dipulihkan.');
      } else {
        message(controller.error!);
      }
    } on FormatException catch (e) {
      message(e.message);
    } catch (_) {
      message(
        'Backup belum berhasil dipulihkan. Data saat ini tetap tersimpan.',
      );
    } finally {
      if (mounted) setState(() => fileBusy = false);
    }
  }

  Widget sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 12),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
  Widget empty(String text, {EmptyKind kind = EmptyKind.transactions}) =>
      FinanceEmptyState(message: text, kind: kind);

  Widget panel(String title, List<Widget> children, {Widget? action}) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );

  Future<void> toggleAmounts() async {
    if (!await controller.setAmountsHidden(!controller.amountsHidden)) {
      message(controller.error!);
    }
  }

  Widget balanceSummary({bool investments = true}) {
    final composition = AnalyticsService().composition(
      controller.snapshot,
      investments ? AssetScope.combined : AssetScope.cash,
    );
    return BalanceCard(
      assets: composition.positiveTotal,
      liabilities: composition.negative.fold(
        Money.zero,
        (sum, row) => sum - row.value,
      ),
      hidden: controller.amountsHidden,
      onToggle: locked ? null : toggleAmounts,
    );
  }

  Widget accountTile(Account account) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 8),
    leading: ProviderLogo(
      provider: account.providerId,
      name: account.name,
      kind: account.kind,
    ),
    title: Text(account.name),
    subtitle: Text('${accountLabel(account.kind)} · ${account.currency}'),
    trailing: SizedBox(
      width: MediaQuery.sizeOf(context).width * .34,
      child: MoneyText(
        controller.snapshot.balance(account.id),
        hidden: controller.amountsHidden,
        currency: account.currency,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: controller.snapshot.balance(account.id).isNegative
              ? Theme.of(context).colorScheme.error
              : null,
        ),
      ),
    ),
    onTap: () =>
        openPage(AssetDetailScreen(controller: controller, id: account.id)),
  );

  Widget transactionTile(LedgerTransaction tx) {
    final data = controller.snapshot;
    final account = data.accounts.firstWhere((a) => a.id == tx.accountId);
    final destination = data.accounts
        .where((a) => a.id == tx.destinationId)
        .firstOrNull;
    final color = tx.kind == TransactionKind.expense
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: locked
            ? null
            : () => AppRoutes.transaction(context, controller, existing: tx),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FinanceIconBadge(switch (tx.kind) {
                TransactionKind.income => FeatherIcons.arrowDownLeft,
                TransactionKind.expense => FeatherIcons.fileText,
                TransactionKind.transfer => FeatherIcons.repeat,
              }, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                      builder: (context, box) {
                        final label = tx.kind == TransactionKind.transfer
                            ? '${account.name} → ${destination?.name ?? ''}'
                            : tx.category;
                        final amount = MoneyText(
                          tx.kind == TransactionKind.expense
                              ? -tx.amount
                              : tx.amount,
                          currency: account.currency,
                          hidden: controller.amountsHidden,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: color),
                        );
                        return MediaQuery.textScalerOf(context).scale(14) > 20
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge,
                                  ),
                                  amount,
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: box.maxWidth * .46,
                                    child: amount,
                                  ),
                                ],
                              );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tx.date}${tx.time == null ? '' : ' · ${tx.time}'} · ${account.name}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (tx.note.isNotEmpty)
                      Text(
                        tx.note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (tx.images.isNotEmpty)
                      Text(
                        '${tx.images.length} lampiran struk',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: 16),
                    const Divider(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget shortcut(
    String glyph,
    String label,
    VoidCallback action, {
    Key? key,
  }) => Expanded(
    child: InkWell(
      key: key,
      onTap: locked ? null : action,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary
                    .withValues(alpha: .18),
              ),
              child: Center(
                child: DesignGlyph(
                  glyph,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );

  Widget overview() {
    final data = controller.snapshot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Total kekayaan', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        MoneyText(
          data.netWorth,
          hidden: controller.amountsHidden,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Text(
          'Nilai aset dikurangi liabilitas',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        balanceSummary(),
        if (data.missingFxCount > 0 || data.unpricedHoldings > 0)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              '${data.missingFxCount} aset tanpa kurs · ${data.unpricedHoldings} posisi belum dinilai. Total belum lengkap.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: 16),
        panel('Catatan keuanganmu', [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary
                  .withValues(alpha: .10),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                DesignGlyph(
                  'info',
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Semua pencatatan tersedia offline.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              shortcut(
                'plus',
                'Catat',
                () => data.accounts.isEmpty
                    ? AppRoutes.account(context, controller)
                    : AppRoutes.transaction(context, controller),
              ),
              shortcut(
                'schedule',
                'Berulang',
                () => AppRoutes.schedules(context, controller),
                key: const Key('schedules-menu'),
              ),
              shortcut(
                'interest',
                'Bunga',
                () => openPage(InterestScreen(controller: controller)),
              ),
              shortcut(
                'staking',
                'Staking',
                () => openPage(StakingScreen(controller: controller)),
              ),
            ],
          ),
        ]),
        if (data.accounts.isEmpty) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('first-asset'),
            onPressed: locked
                ? null
                : () => AppRoutes.account(context, controller),
            icon: const DesignGlyph('plus'),
            label: const Text('Tambah aset pertama'),
          ),
        ],
        const SizedBox(height: 16),
        panel('Produk investasi', [
          Text(
            'Nilai penutupan tersimpan',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          for (final (type, title, subtitle, glyph, purple) in [
            (
              InstrumentKind.stock,
              'Saham Indonesia',
              'Bandingkan dengan IHSG',
              'stocks',
              true,
            ),
            (
              InstrumentKind.crypto,
              'Crypto',
              'Spot dan staking',
              'crypto',
              false,
            ),
            (
              InstrumentKind.fund,
              'Reksa dana',
              'NAB diisi manual',
              'funds',
              false,
            ),
          ])
            Builder(
              builder: (context) {
                final value = data.extras.holdings
                    .where(
                      (h) => data.extras.instruments.any(
                        (i) => i.id == h.instrumentId && i.kind == type,
                      ),
                    )
                    .fold(
                      Money.zero,
                      (sum, h) =>
                          sum + (data.extras.holdingValue(h) ?? Money.zero),
                    );
                final color = purple
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.primary;
                return InkWell(
                  onTap: () => openPage(
                    PortfolioScreen(controller: controller, initialType: type),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: .18),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: DesignGlyph(glyph, color: color),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                title,
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: MediaQuery.sizeOf(context).width * .26,
                          child: MoneyText(
                            value,
                            hidden: controller.amountsHidden,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ]),
        const SizedBox(height: 16),
        CashflowCarousel(controller: controller),
        const SizedBox(height: 12),
        ListTile(
          key: const Key('analytics-menu'),
          contentPadding: EdgeInsets.zero,
          leading: const FinanceIconBadge(FeatherIcons.pieChart),
          title: const Text('Lihat laporan lengkap'),
          subtitle: const Text('Gabungan, investasi, noninvestasi & arus kas'),
          trailing: const DesignGlyph('chevron-right'),
          onTap: () => openPage(AnalyticsScreen(controller: controller)),
        ),
        ListTile(
          key: const Key('performance-menu'),
          contentPadding: EdgeInsets.zero,
          leading: const FinanceIconBadge(FeatherIcons.activity),
          title: const Text('Saham vs IHSG'),
          subtitle: const Text('Perbandingan kinerja portofolio'),
          trailing: const DesignGlyph('chevron-right'),
          onTap: () => openPage(PerformanceScreen(controller: controller)),
        ),
        if (controller.due.isNotEmpty)
          ListTile(
            leading: const FinanceIconBadge(FeatherIcons.calendar),
            title: Text('${controller.due.length} transaksi menunggu'),
            subtitle: const Text('Tinjau jadwal jatuh tempo'),
            trailing: const DesignGlyph('chevron-right'),
            onTap: () => AppRoutes.schedules(context, controller),
          ),
        sectionTitle('Transaksi terbaru'),
        if (data.transactions.isEmpty)
          empty('Belum ada transaksi. Catatanmu akan tampil di sini.')
        else
          ...data.transactions.take(5).map(transactionTile),
      ],
    );
  }

  Widget accounts() {
    final data = controller.snapshot;
    final rows = data.accounts.where(
      (a) =>
          (assetClass == null || a.kind == assetClass) &&
          a.name.toLowerCase().contains(assetQuery.toLowerCase()),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        balanceSummary(investments: false),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: locked
                    ? null
                    : () => AppRoutes.account(context, controller),
                icon: const DesignGlyph('plus'),
                label: const Text('Tambah aset'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Grafik aset noninvestasi',
              onPressed: () => openPage(
                AnalyticsScreen(
                  controller: controller,
                  initialScope: AssetScope.cash,
                ),
              ),
              icon: const DesignGlyph('portfolio'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            hintText: 'Cari aset',
            prefixIcon: Padding(
              padding: EdgeInsets.all(16),
              child: DesignGlyph('search', size: 20),
            ),
          ),
          onChanged: (v) => setState(() => assetQuery = v),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('Semua'),
                  selected: assetClass == null,
                  onSelected: (_) => setState(() => assetClass = null),
                ),
              ),
              for (final type in AccountKind.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(accountLabel(type)),
                    selected: assetClass == type,
                    onSelected: (_) => setState(() => assetClass = type),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (rows.isEmpty)
          empty(
            'Belum ada aset yang sesuai.',
            kind: assetQuery.isEmpty ? EmptyKind.accounts : EmptyKind.search,
          ),
        for (final type in AccountKind.values.where(
          (type) => rows.any((a) => a.kind == type),
        )) ...[
          panel(accountLabel(type), [
            for (final a in rows.where((a) => a.kind == type)) accountTile(a),
          ]),
          const SizedBox(height: 16),
        ],
        featureMenu(
          'Utang & piutang',
          'Pokok, pembayaran dan dana belum cair',
          FeatherIcons.fileText,
          DebtsScreen(controller: controller),
        ),
      ],
    );
  }

  Widget transactions() {
    final data = controller.snapshot, q = query.toLowerCase();
    final names = {for (final a in data.accounts) a.id: a.name};
    final matches = data.transactions
        .where(
          (t) =>
              (transactionType == null || t.kind == transactionType) &&
              (transactionDate == null || t.date == transactionDate) &&
              '${t.category} ${t.note} ${t.date} ${t.time ?? ''} ${names[t.accountId]} ${names[t.destinationId] ?? ''}'
                  .toLowerCase()
                  .contains(q),
        )
        .toList();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
      itemCount: matches.isEmpty ? 2 : matches.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('transaction-search'),
                decoration: const InputDecoration(
                  hintText: 'Cari transaksi',
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(16),
                    child: DesignGlyph('search', size: 20),
                  ),
                ),
                onChanged: (v) => setState(() => query = v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FinanceSelect<TransactionKind>(
                      key: ValueKey(transactionType),
                      initialValue: transactionType,
                      decoration: const InputDecoration(
                        labelText: 'Jenis transaksi',
                      ),
                      items: [
                        for (final type in TransactionKind.values)
                          DropdownMenuItem(
                            value: type,
                            child: Text(transactionLabel(type)),
                          ),
                      ],
                      onChanged: (v) => setState(() => transactionType = v),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Filter tanggal',
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: controller.clock(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2199, 12, 31),
                      );
                      if (date != null && mounted) {
                        setState(() => transactionDate = localDate(date));
                      }
                    },
                    icon: const DesignGlyph('calendar'),
                  ),
                  if (transactionType != null || transactionDate != null)
                    IconButton(
                      tooltip: 'Hapus filter',
                      onPressed: () => setState(() {
                        transactionType = null;
                        transactionDate = null;
                      }),
                      icon: const DesignGlyph('close'),
                    ),
                ],
              ),
              if (transactionDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text('Tanggal: $transactionDate'),
                ),
              const SizedBox(height: 12),
            ],
          );
        }
        if (matches.isEmpty) {
          return empty(
            query.isEmpty
                ? 'Belum ada transaksi yang sesuai.'
                : 'Tidak ada transaksi yang cocok.',
            kind: query.isEmpty ? EmptyKind.transactions : EmptyKind.search,
          );
        }
        final tx = matches[index - 1];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (index == 1 || tx.date != matches[index - 2].date)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  tx.date,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            transactionTile(tx),
          ],
        );
      },
    );
  }

  Widget settings() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Card(
        child: ListTile(
          leading: const ArtaLogo(size: 40),
          title: const Text('Arta'),
          subtitle: const Text('Keuangan pribadimu, di perangkatmu'),
        ),
      ),
      sectionTitle('Pencatatan'),
      panel('Kelola keuangan', [
        featureMenu(
          'Kategori',
          'Pemasukan, pengeluaran dan arsip',
          FeatherIcons.tag,
          CategoriesScreen(controller: controller),
          key: const Key('categories-menu'),
        ),
        featureMenu(
          'Transaksi berulang & cicilan',
          'Jadwal dan akhir bulan',
          FeatherIcons.calendar,
          SchedulesScreen(controller: controller),
          key: const Key('schedules-menu'),
        ),
        featureMenu(
          'Bunga & bagi hasil',
          'Aturan dan pencatatan aktual',
          FeatherIcons.percent,
          InterestScreen(controller: controller),
        ),
        featureMenu(
          'Staking crypto',
          'Stake, unstake dan reward manual',
          FeatherIcons.lock,
          StakingScreen(controller: controller),
        ),
        featureMenu(
          'Utang & piutang',
          'Pinjaman dan dana belum cair',
          FeatherIcons.fileText,
          DebtsScreen(controller: controller),
        ),
        featureMenu(
          'Katalog saham & instrumen',
          'Impor daftar IDX dan pencarian crypto',
          FeatherIcons.search,
          CatalogScreen(controller: controller),
        ),
        featureMenu(
          'Sumber harga & mata uang',
          'Penutupan harian, permintaan manual dan kurs',
          FeatherIcons.refreshCw,
          MarketSettingsScreen(controller: controller),
        ),
        if (controller.snapshot.cards.isNotEmpty)
          featureMenu(
            'Kartu terhubung',
            'Metode pembayaran pada rekening',
            FeatherIcons.creditCard,
            CardsScreen(controller: controller),
          ),
      ]),
      sectionTitle('Preferensi'),
      panel('Tampilan & keamanan', [
        FinanceSelect<String>(
          key: ValueKey(controller.snapshot.theme),
          initialValue: controller.snapshot.theme,
          decoration: const InputDecoration(labelText: 'Tema'),
          items: const [
            DropdownMenuItem(value: 'dark', child: Text('Gelap')),
            DropdownMenuItem(value: 'light', child: Text('Terang')),
            DropdownMenuItem(value: 'system', child: Text('Ikuti perangkat')),
          ],
          onChanged: locked
              ? null
              : (v) async {
                  if (!await controller.setTheme(v!)) {
                    message(controller.error!);
                  }
                },
        ),
        if (controller.security != null)
          ListTile(
            key: const Key('security-menu'),
            contentPadding: EdgeInsets.zero,
            leading: const FinanceIconBadge(Icons.fingerprint),
            title: const Text('Kunci aplikasi'),
            subtitle: const Text('Sidik jari HP dan PIN Arta · opsional'),
            trailing: const DesignGlyph('chevron-right'),
            onTap: () =>
                openPage(SecurityScreen(controller: controller.security!)),
          ),
      ]),
      sectionTitle('Data & cadangan'),
      panel('Backup & restore', [
        Text(
          'Simpan cadangan secara berkala. JSON untuk memulihkan seluruh data; CSV untuk analisis.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const FinanceIconBadge(FeatherIcons.lock),
          title: const Text('Backup terenkripsi'),
          trailing: const DesignGlyph('chevron-right'),
          onTap: locked ? null : () => exportBackup(encrypted: true),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const FinanceIconBadge(FeatherIcons.download),
          title: const Text('Ekspor JSON biasa'),
          trailing: const DesignGlyph('chevron-right'),
          onTap: locked ? null : () => exportBackup(encrypted: false),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const FinanceIconBadge(FeatherIcons.upload),
          title: const Text('Pulihkan dari file'),
          trailing: const DesignGlyph('chevron-right'),
          onTap: locked ? null : restoreBackup,
        ),
        ExpansionTile(
          key: const PageStorageKey('settings-csv-expanded'),
          tilePadding: EdgeInsets.zero,
          title: const Text('Ekspor CSV'),
          children: [
            for (final table in ['transaksi', 'kepemilikan', 'harga'])
              ListTile(
                title: Text('Ekspor CSV $table'),
                leading: const DesignGlyph('export'),
                onTap: locked ? null : () => exportCsv(table),
              ),
          ],
        ),
        if (fileBusy) const Center(child: ArtaLogo(loading: true, size: 40)),
      ]),
      sectionTitle('Tentang Arta'),
      Text(
        'Versi $appVersion · Penyimpanan lokal',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 8),
      const Text(
        'Pencatatan keuangan dan investasi offline. Internet digunakan untuk harga dan logo. Cadangkan data sebelum mengganti perangkat.',
      ),
      TextButton(
        onPressed: () => showLicensePage(
          context: context,
          applicationName: 'Arta',
          applicationVersion: appVersion,
        ),
        child: const Text('Sumber & lisensi'),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final page = tab == 1
        ? PortfolioScreen(controller: controller, embedded: true)
        : SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: tab == 3
                    ? transactions()
                    : ListView(
                        key: PageStorageKey('main-tab-$tab'),
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                        children: [
                          switch (tab) {
                            0 => overview(),
                            2 => accounts(),
                            _ => settings(),
                          },
                        ],
                      ),
              ),
            ),
          );
    return Scaffold(
      appBar: tab == 1
          ? null
          : AppBar(
              title: Text(
                [
                  'Ringkasan',
                  'Investasi',
                  'Aset',
                  'Transaksi',
                  'Pengaturan',
                ][tab],
              ),
            ),
      body: page,
      floatingActionButton: tab == 4 || tab == 1
          ? null
          : FloatingActionButton(
              tooltip: tab == 2 || controller.snapshot.accounts.isEmpty
                  ? 'Tambah aset'
                  : 'Catat transaksi',
              onPressed: locked
                  ? null
                  : () => tab == 2 || controller.snapshot.accounts.isEmpty
                        ? AppRoutes.account(context, controller)
                        : AppRoutes.transaction(context, controller),
              child: const DesignGlyph('plus', color: Colors.white),
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (final (index, name, glyph) in [
                (0, 'Ringkasan', 'home'),
                (1, 'Investasi', 'portfolio'),
                (2, 'Aset', 'wallet'),
                (3, 'Transaksi', 'receipt'),
                (4, 'Pengaturan', 'settings'),
              ])
                Expanded(
                  child: Semantics(
                    selected: tab == index,
                    child: IconButton(
                      key: Key('nav-$index'),
                      tooltip: name,
                      onPressed: locked
                          ? null
                          : () => setState(() => tab = index),
                      icon: DesignGlyph(
                        glyph,
                        color: tab == index
                            ? colors.primary
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
