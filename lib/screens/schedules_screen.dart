import '../widgets/finance_dialog.dart';
import '../widgets/arta_icon.dart';

import 'package:feather_icons/feather_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../controllers/finance_controller.dart';
import '../models/ledger.dart';
import '../models/schedule.dart';
import '../routes/app_routes.dart';
import '../services/schedule_engine.dart';
import 'transaction_form.dart';
import '../widgets/finance_empty_state.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key, required this.controller});
  final FinanceController controller;
  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  String filter = 'active', query = '';
  bool onlyInstallments = false;
  FinanceController get controller => widget.controller;
  Widget heading(String label) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(label, style: Theme.of(context).textTheme.titleMedium),
  );
  Future<void> create() async {
    if (controller.snapshot.accounts.isEmpty) {
      await AppRoutes.account(context, controller);
      if (!mounted || controller.snapshot.accounts.isEmpty) return;
    }
    if (!mounted) return;
    final mode = await showModalBottomSheet<EntryMode>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const ArtaIcon(FeatherIcons.repeat),
              title: const Text('Transaksi berulang'),
              subtitle: const Text(
                'Pemasukan, pengeluaran, atau transfer berkala',
              ),
              onTap: () => Navigator.pop(context, EntryMode.repeat),
            ),
            ListTile(
              leading: const ArtaIcon(FeatherIcons.list),
              title: const Text('Cicilan pengeluaran'),
              subtitle: const Text('Bagi satu total ke beberapa bulan'),
              onTap: () => Navigator.pop(context, EntryMode.installment),
            ),
          ],
        ),
      ),
    );
    if (mode != null && mounted) {
      await AppRoutes.schedule(context, controller, mode: mode);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final data = controller.snapshot;
      final rules = data.schedules
          .where(
            (s) =>
                (filter == 'all' || s.state.name == filter) &&
                (!onlyInstallments || s.installments) &&
                '${s.name} ${s.category} ${data.accounts.firstWhere((a) => a.id == s.accountId).name}'
                    .toLowerCase()
                    .contains(query.toLowerCase()),
          )
          .toList();
      final due = controller.due
          .where((p) => !onlyInstallments || p.rule.installments)
          .toList();
      final rows = <Widget>[
        const Text(
          'Jadwal hanya membentuk catatan. Tidak melakukan debit atau pembayaran ke bank.',
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('schedule-search'),
          decoration: const InputDecoration(
            labelText: 'Cari jadwal',
            prefixIcon: ArtaIcon(FeatherIcons.search),
          ),
          onChanged: (v) => setState(() => query = v),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final item in const [
              ('active', 'Aktif'),
              ('paused', 'Dijeda'),
              ('all', 'Semua'),
            ])
              Expanded(
                child: Semantics(
                  selected: filter == item.$1,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: filter == item.$1
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        foregroundColor: filter == item.$1
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () => setState(() => filter = item.$1),
                      child: Text(
                        item.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: FilterChip(
            label: const Text('Cicilan'),
            selected: onlyInstallments,
            onSelected: (v) => setState(() => onlyInstallments = v),
          ),
        ),
        if (due.isNotEmpty && query.isEmpty && filter != 'paused') ...[
          heading('Jatuh tempo · ${due.length}${due.length == 100 ? '+' : ''}'),
          const Text(
            'Belum memengaruhi saldo. Ketuk untuk meninjau nominal, mencatat, atau melewati.',
          ),
          for (final item in due)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              leading: const ArtaIcon(FeatherIcons.clock),
              title: Text(item.rule.name),
              subtitle: Text(
                '${item.date} · ${controller.displayCurrency(item.amount, data.accounts.firstWhere((a) => a.id == item.rule.accountId).currency)}${item.rule.installments ? ' · ${item.ordinal + 1}/${item.rule.count}' : ''}',
              ),
              trailing: const ArtaIcon(FeatherIcons.chevronRight),
              onTap: controller.busy
                  ? null
                  : () => AppRoutes.occurrence(context, controller, item),
            ),
        ],
        heading('Aturan jadwal · ${rules.length}'),
        if (rules.isEmpty)
          FinanceEmptyState(
            message: 'Belum ada jadwal pada pilihan ini. Gunakan + untuk membuat jadwal.',
            kind: query.isEmpty ? EmptyKind.calendar : EmptyKind.search,
          ),
        for (final rule in rules) ...[
          Builder(
            builder: (context) {
              final next = ScheduleEngine.pending(
                rule,
                data.occurrences,
                limit: 1,
              ).firstOrNull;
              final account = data.accounts
                  .firstWhere((a) => a.id == rule.accountId)
                  .name;
              final status = rule.state == ScheduleState.active && next == null
                  ? 'Selesai'
                  : scheduleStateLabel(rule.state);
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                leading: ArtaIcon(
                  rule.installments ? FeatherIcons.list : FeatherIcons.repeat,
                ),
                title: Text(
                  rule.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$account · ${rule.summary}'),
                    Text(
                      '$status · ${next == null ? 'Tidak ada kejadian tersisa' : 'berikutnya ${next.date}'}',
                    ),
                    Text(
                      rule.installments
                          ? 'Total rencana ${controller.displayCurrency(rule.amount, data.accounts.firstWhere((a) => a.id == rule.accountId).currency)} · ${rule.count} bagian'
                          : '${controller.displayCurrency(rule.amount, data.accounts.firstWhere((a) => a.id == rule.accountId).currency)} per kejadian',
                    ),
                  ],
                ),
                trailing: const ArtaIcon(FeatherIcons.chevronRight),
                onTap: controller.busy
                    ? null
                    : () => AppRoutes.scheduleDetail(
                        context,
                        controller,
                        rule.id,
                      ),
              );
            },
          ),
          const Divider(height: 1),
        ],
      ];
      return Scaffold(
        appBar: AppBar(
          title: const Text('Transaksi berulang'),
          actions: [
            IconButton(
              tooltip: 'Periksa jatuh tempo',
              icon: const ArtaIcon(FeatherIcons.refreshCw),
              onPressed: controller.busy
                  ? null
                  : () async {
                      final ok = await controller.refreshSchedules();
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(controller.error!)),
                        );
                      }
                    },
            ),
            IconButton(
              key: const Key('add-schedule'),
              tooltip: 'Tambah jadwal',
              onPressed: controller.busy ? null : create,
              icon: const ArtaIcon(FeatherIcons.plus),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: rows.length,
                itemBuilder: (_, i) => rows[i],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class ScheduleDetailScreen extends StatefulWidget {
  const ScheduleDetailScreen({
    super.key,
    required this.controller,
    required this.id,
  });
  final FinanceController controller;
  final String id;
  @override
  State<ScheduleDetailScreen> createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends State<ScheduleDetailScreen> {
  int historyLimit = 30;
  FinanceController get controller => widget.controller;
  Future<void> changeState(ScheduleRule rule) async {
    final stopping = rule.state != ScheduleState.paused;
    if (stopping) {
      final ok = await controller.setScheduleState(
        rule.id,
        ScheduleState.paused,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(controller.error!)));
      }
    } else {
      final skip = await showFinanceDialog<bool>(
        context: context,
        builder: (context) => FinanceDialog(
          scrollable: true,
          title: const Text('Lanjutkan jadwal'),
          content: const Text(
            'Pilih perlakuan untuk kejadian sebelum hari ini. Mode otomatis akan langsung mencatat kejadian yang tetap tertunda, termasuk hari ini.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Proses semua yang lewat'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Lewati sebelum hari ini'),
            ),
          ],
        ),
      );
      if (skip == null || !mounted) return;
      final ok = await controller.setScheduleState(
        rule.id,
        ScheduleState.active,
        skipMissed: skip,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(controller.error!)));
      }
    }
  }

  Future<void> stop(ScheduleRule rule) async {
    final ok = await showFinanceDialog<bool>(
      context: context,
      builder: (context) => FinanceDialog(
        title: const Text('Hentikan jadwal?'),
        content: const Text(
          'Seluruh kejadian yang belum diproses dibatalkan. Transaksi dan riwayat lama tetap tersimpan. Jadwal yang dihentikan tidak dapat dilanjutkan; Anda dapat membuat aturan baru.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hentikan'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final saved = await controller.setScheduleState(
      rule.id,
      ScheduleState.stopped,
    );
    if (!saved && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(controller.error!)));
    }
  }

  Widget section(String text) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
  Widget field(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(value),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final data = controller.snapshot;
      final rule = data.schedules.where((s) => s.id == widget.id).firstOrNull;
      if (rule == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Detail jadwal')),
          body: const Center(child: Text('Jadwal tidak ditemukan.')),
        );
      }
      final history =
          data.occurrences.where((o) => o.scheduleId == rule.id).toList()
            ..sort((a, b) => b.ordinal.compareTo(a.ordinal));
      final pending = ScheduleEngine.pending(rule, history, limit: 12).toList();
      final next = pending.firstOrNull;
      final active = rule.state == ScheduleState.active;
      final alive = rule.state != ScheduleState.stopped;
      final names = {for (final a in data.accounts) a.id: a.name};
      final actual = data.actualExpenseForSchedule(rule.id);
      final rows = <Widget>[
        Text(
          active && next == null ? 'Selesai' : scheduleStateLabel(rule.state),
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(height: 16),
        Text(rule.name, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          controller.displayCurrency(
            rule.amount,
            data.accounts.firstWhere((a) => a.id == rule.accountId).currency,
          ),
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        Text(
          rule.installments
              ? 'Total rencana · ${rule.count} bagian'
              : 'Per kejadian',
        ),
        const SizedBox(height: 16),
        field(
          'Jenis & aset',
          '${transactionLabel(rule.kind)} · ${names[rule.accountId]}${rule.destinationId == null ? '' : ' → ${names[rule.destinationId]}'}',
        ),
        if (rule.category.isNotEmpty) field('Kategori', rule.category),
        if (!rule.fee.isZero)
          field(
            'Biaya per kejadian',
            controller.displayCurrency(
              rule.fee,
              data.accounts.firstWhere((a) => a.id == rule.accountId).currency,
            ),
          ),
        field('Frekuensi', rule.summary),
        field(
          'Rentang',
          'Mulai ${rule.startDate}${rule.endDate == null ? '' : ' · sampai ${rule.endDate}'}${rule.count == null ? '' : ' · maksimal ${rule.count} kejadian'}',
        ),
        field('Zona waktu', rule.zone),
        field(
          'Mode pencatatan',
          rule.mode == ScheduleMode.automatic
              ? 'Otomatis saat jatuh tempo'
              : 'Minta konfirmasi',
        ),
        if (rule.note.isNotEmpty) field('Catatan', rule.note),
        if (rule.installments) ...[
          section('Progres cicilan'),
          LinearProgressIndicator(value: history.length / rule.count!),
          const SizedBox(height: 8),
          Text(
            '${history.length}/${rule.count} bagian diproses · ${history.where((o) => o.state == OccurrenceState.posted).length} tercatat',
          ),
          field(
            'Pengeluaran aktual yang masih tercatat',
            controller.displayCurrency(
              actual,
              data.accounts.firstWhere((a) => a.id == rule.accountId).currency,
            ),
          ),
          field(
            'Sisa rencana belum diproses',
            controller.displayCurrency(
              data.remainingForSchedule(rule),
              data.accounts.firstWhere((a) => a.id == rule.accountId).currency,
            ),
          ),
          const Text(
            'Bagian dilewati atau dihapus tetap dianggap diproses. Nilai aktual dapat berbeda jika satu kejadian diedit.',
          ),
        ],
        if (alive) ...[
          section('Kelola jadwal'),
          OutlinedButton(
            onPressed: controller.busy ? null : () => changeState(rule),
            child: Text(
              rule.state == ScheduleState.paused
                  ? 'Lanjutkan jadwal'
                  : 'Jeda jadwal',
            ),
          ),
          if (next != null) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: controller.busy
                  ? null
                  : () async {
                      await AppRoutes.schedule(
                        context,
                        controller,
                        replaces: rule,
                      );
                    },
              child: const Text('Ubah jadwal mendatang'),
            ),
          ],
          const SizedBox(height: 12),
          TextButton(
            onPressed: controller.busy ? null : () => stop(rule),
            child: const Text('Hentikan pengulangan'),
          ),
        ],
        if (alive && pending.isNotEmpty) ...[
          section('Kejadian berikutnya'),
          const Text(
            'Rencana belum memengaruhi saldo. Ketuk untuk mencatat lebih awal, mengubah nominal satu kejadian, atau melewati.',
          ),
          if (!active)
            const Text(
              'Lanjutkan jadwal terlebih dahulu untuk memproses kejadian.',
            ),
          for (final item in pending)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              leading: const ArtaIcon(FeatherIcons.calendar),
              title: Text(
                '${item.date}${rule.installments ? ' · ${item.ordinal + 1}/${rule.count}' : ''}',
              ),
              subtitle: Text(
                '${controller.displayCurrency(item.amount, data.accounts.firstWhere((a) => a.id == item.rule.accountId).currency)}${item.isDue(controller.clock()) ? ' · jatuh tempo' : ' · rencana'}',
              ),
              trailing: const ArtaIcon(FeatherIcons.chevronRight),
              onTap: !active || controller.busy
                  ? null
                  : () => AppRoutes.occurrence(context, controller, item),
            ),
          if (pending.length == 12)
            const Text(
              'Menampilkan 12 kejadian terdekat. Daftar maju setelah kejadian diproses.',
            ),
        ],
        section('Riwayat kejadian · ${history.length}'),
        if (history.isEmpty) const Text('Belum ada kejadian yang diproses.'),
        for (final item in history.take(historyLimit))
          ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            leading: ArtaIcon(
              item.state == OccurrenceState.posted
                  ? FeatherIcons.checkCircle
                  : FeatherIcons.slash,
            ),
            title: Text(
              '${item.dueDate} · ${item.ordinal + 1}${rule.count == null ? '' : '/${rule.count}'}',
            ),
            subtitle: Text(switch (item.state) {
              OccurrenceState.posted =>
                'Tercatat · ${controller.displayCurrency(data.transactions.firstWhere((t) => t.id == item.transactionId).amount, data.accounts.firstWhere((a) => a.id == rule.accountId).currency)}',
              OccurrenceState.skipped => 'Dilewati · tidak akan dibuat ulang',
              OccurrenceState.deleted =>
                'Transaksi dihapus · tidak akan dibuat ulang',
            }),
            trailing: item.state == OccurrenceState.posted
                ? const ArtaIcon(FeatherIcons.chevronRight)
                : null,
            onTap: item.state != OccurrenceState.posted || controller.busy
                ? null
                : () => AppRoutes.transaction(
                    context,
                    controller,
                    existing: data.transactions.firstWhere(
                      (t) => t.id == item.transactionId,
                    ),
                  ),
          ),
        if (history.length > historyLimit)
          TextButton(
            onPressed: () => setState(() => historyLimit += 30),
            child: const Text('Tampilkan riwayat lainnya'),
          ),
        const SizedBox(height: 24),
      ];
      return Scaffold(
        appBar: AppBar(title: const Text('Detail pengulangan')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: rows.length,
                itemBuilder: (_, i) => rows[i],
              ),
            ),
          ),
        ),
      );
    },
  );
}
