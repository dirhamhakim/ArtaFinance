import '../widgets/finance_dialog.dart';
import '../widgets/finance_select.dart';
import '../widgets/arta_icon.dart';

import 'package:feather_icons/feather_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../controllers/finance_controller.dart';
import '../models/decimal.dart';
import '../models/investment.dart';
import '../models/ledger.dart';
import '../models/money.dart';
import '../models/staking.dart';
import '../widgets/finance_empty_state.dart';
import '../widgets/finance_fields.dart';
import '../widgets/transaction_time_field.dart';
import '../widgets/transfer_fee_field.dart';

class StakingScreen extends StatelessWidget {
  const StakingScreen({super.key, required this.controller});
  final FinanceController controller;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (ctx, _) {
      final c = controller, data = c.snapshot;
      final state = replayPortfolio(data.extras.events);
      void open(Widget page) =>
          Navigator.push<void>(ctx, MaterialPageRoute(builder: (_) => page));
      final events = data.extras.events.where((e) => isStaking(e.kind)).toList()
        ..sort((a, b) => compareInvestmentEvents(b, a));
      return Scaffold(
        appBar: AppBar(
          title: const Text('Staking crypto'),
          actions: [
            IconButton(
              onPressed: c.busy
                  ? null
                  : () => c.setAmountsHidden(!c.amountsHidden),
              tooltip: 'Tampilkan / sembunyikan nominal',
              icon: ArtaIcon(
                c.amountsHidden ? FeatherIcons.eyeOff : FeatherIcons.eye,
              ),
            ),
          ],
        ),
        body: financeBody([
          const Text(
            'Catatan manual tanpa koneksi wallet. Unit staking dan menunggu unstake tetap milik Anda, masuk portofolio sekali, dan tidak bisa dijual sebelum dilepas.',
          ),
          FilledButton.icon(
            key: const Key('add-staking-plan'),
            onPressed: c.busy || data.accounts.isEmpty
                ? null
                : () => open(StakingPlanForm(controller: c)),
            icon: const ArtaIcon(FeatherIcons.plus),
            label: const Text('Tambah posisi staking'),
          ),
          if (data.accounts.isEmpty)
            const Text('Tambahkan aset/lokasi crypto terlebih dahulu.'),
          if (data.extras.stakingPlans.isEmpty)
            const FinanceEmptyState(
              message: 'Belum ada posisi staking. Catat unit awal/beli crypto, lalu buat posisi.',
              kind: EmptyKind.accounts,
            ),
          for (final p in data.extras.stakingPlans)
            Builder(
              builder: (_) {
                final b = state.staking[p.id] ?? StakingBalance();
                final i = data.extras.instruments.firstWhere(
                  (i) => i.id == p.instrumentId,
                );
                final h = state.holdings
                    .where(
                      (h) =>
                          h.accountId == p.accountId &&
                          h.instrumentId == p.instrumentId,
                    )
                    .firstOrNull;
                String units(Decimal value) =>
                    c.amountsHidden ? '••••••' : value.text;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${p.name}${p.archived ? ' · diarsipkan' : ''}',
                          style: Theme.of(ctx).textTheme.titleMedium,
                        ),
                        Text(
                          '${i.code} · ${data.accounts.firstWhere((a) => a.id == p.accountId).name}',
                        ),
                        if (p.validator.isNotEmpty || p.network.isNotEmpty)
                          Text('${p.network} · ${p.validator}'),
                        Text(
                          'Aktif: ${units(b.staked)} · Menunggu unstake: ${units(b.pending)}',
                        ),
                        Text(
                          'Unit bebas di aset: ${units(h?.available ?? Decimal.zero)}',
                        ),
                        Text(
                          'Reward aktual: ${units(b.rewards)} · Slashing/biaya unit: ${units(b.losses)}',
                        ),
                        if (p.apr != null)
                          Text(
                            c.amountsHidden
                                ? 'APR / estimasi ••••••'
                                : 'APR referensi ${p.apr!.text}% · estimasi setahun ${(b.staked * p.apr! / Decimal.parse('100')).text} ${i.code}. Bukan reward tercatat; APR dapat berubah.',
                          ),
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton(
                              onPressed: c.busy
                                  ? null
                                  : () => open(
                                      StakingEventForm(controller: c, plan: p),
                                    ),
                              child: const Text('Catat aktivitas'),
                            ),
                            TextButton(
                              onPressed: c.busy
                                  ? null
                                  : () => open(
                                      StakingPlanForm(
                                        controller: c,
                                        existing: p,
                                      ),
                                    ),
                              child: const Text('Edit posisi'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          Text('Riwayat staking', style: Theme.of(ctx).textTheme.titleMedium),
          for (final e in events)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(investmentLabel(e.kind)),
              subtitle: Text(
                '${e.date} ${e.time ?? ''} · ${data.extras.stakingPlans.firstWhere((p) => p.id == e.stakingId).name}\n${c.amountsHidden ? '••••••' : e.quantity.text} unit${e.availableOn == null ? '' : ' · estimasi cair ${e.availableOn}'}${e.note.isEmpty ? '' : '\n${e.note}'}',
              ),
              trailing: const ArtaIcon(FeatherIcons.chevronRight),
              onTap: c.busy
                  ? null
                  : () => open(StakingEventForm(controller: c, existing: e)),
            ),
          const Text(
            'Reward dicatat saat benar-benar diterima; pending reward belum menjadi saldo. Restake menambah unit terkunci. Unstake tidak otomatis cair saat tanggal estimasi lewat. Biaya token dicatat sebagai slashing/biaya unit; biaya tunai terpisah. Tidak ada APY otomatis, transaksi jaringan atau liquid staking token yang dibuat sendiri.',
          ),
        ]),
      );
    },
  );
}

class StakingPlanForm extends StatefulWidget {
  const StakingPlanForm({super.key, required this.controller, this.existing});
  final FinanceController controller;
  final StakingPlan? existing;
  @override
  State<StakingPlanForm> createState() => _StakingPlanFormState();
}

class _StakingPlanFormState extends State<StakingPlanForm> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name, validator, network, apr;
  String? account, instrument;
  bool archived = false;
  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    name = TextEditingController(text: p?.name ?? '');
    validator = TextEditingController(text: p?.validator ?? '');
    network = TextEditingController(text: p?.network ?? '');
    apr = TextEditingController(text: p?.apr?.text ?? '');
    account =
        p?.accountId ?? widget.controller.snapshot.accounts.firstOrNull?.id;
    instrument =
        p?.instrumentId ??
        widget.controller.snapshot.extras.instruments
            .where((i) => i.kind == InstrumentKind.crypto && !i.archived)
            .firstOrNull
            ?.id;
    archived = p?.archived ?? false;
  }

  @override
  void dispose() {
    for (final c in [name, validator, network, apr]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    final c = widget.controller;
    return Scaffold(
      appBar: AppBar(title: const Text('Posisi staking')),
      body: Form(
        key: form,
        child: financeFormBody([
          TextFormField(
            controller: name,
            decoration: const InputDecoration(
              labelText: 'Nama posisi / platform',
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Isi nama posisi.' : null,
          ),
          accountField(
            c.snapshot.accounts,
            account,
            (v) => setState(() => account = v),
          ),
          FinanceSelect<String>(
            initialValue: instrument,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Crypto'),
            items: [
              for (final i in c.snapshot.extras.instruments.where(
                (i) =>
                    i.kind == InstrumentKind.crypto &&
                    (!i.archived || i.id == instrument),
              ))
                DropdownMenuItem(
                  value: i.id,
                  child: Text(
                    '${i.code} · ${i.displayName}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            validator: (v) => v == null ? 'Pilih crypto.' : null,
            onChanged: (v) => setState(() => instrument = v),
          ),
          TextFormField(
            controller: network,
            decoration: const InputDecoration(labelText: 'Jaringan (opsional)'),
          ),
          TextFormField(
            controller: validator,
            decoration: const InputDecoration(
              labelText: 'Validator / produk (opsional)',
            ),
          ),
          TextFormField(
            controller: apr,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'APR referensi % (opsional)',
              helperText: 'Hanya estimasi, bukan reward otomatis.',
            ),
          ),
          if (widget.existing != null)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Arsipkan posisi'),
              value: archived,
              onChanged: (v) => setState(() => archived = v),
            ),
          const Text(
            'Membuat posisi belum mengunci unit. Sesudah tersimpan, Catat aktivitas > Stake unit. Untuk kepemilikan lama, masukkan Saldo unit awal terlebih dahulu tanpa mendebit kas lagi.',
          ),
          FilledButton(
            key: const Key('save-staking-plan'),
            onPressed: () async {
              if (!form.currentState!.validate()) return;
              try {
                final p = StakingPlan(
                  id: widget.existing?.id ?? c.newId(),
                  accountId: account!,
                  instrumentId: instrument!,
                  name: name.text.trim(),
                  network: network.text.trim(),
                  validator: validator.text.trim(),
                  apr: apr.text.trim().isEmpty ? null : Decimal.input(apr.text),
                  archived: archived,
                );
                StakingPlan.fromJson(p.toJson());
                await finishFinanceSave(ctx, c, c.saveStakingPlan(p));
              } on FormatException catch (e) {
                if (ctx.mounted) financeMessage(ctx, e.message);
              }
            },
            child: const Text('Simpan posisi'),
          ),
        ]),
      ),
    );
  }
}

class StakingEventForm extends StatefulWidget {
  const StakingEventForm({
    super.key,
    required this.controller,
    this.plan,
    this.existing,
  });
  final FinanceController controller;
  final StakingPlan? plan;
  final InvestmentEvent? existing;
  @override
  State<StakingEventForm> createState() => _StakingEventFormState();
}

class _StakingEventFormState extends State<StakingEventForm> {
  final form = GlobalKey<FormState>();
  late StakingPlan plan;
  InvestmentKind kind = InvestmentKind.stake;
  late TextEditingController units, fee, fx, note;
  late String date;
  String? time, availableOn;
  bool feeOn = false, pending = false, restake = false;
  FinanceController get c => widget.controller;
  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    plan =
        widget.plan ??
        c.snapshot.extras.stakingPlans.firstWhere((p) => p.id == e!.stakingId);
    kind = e?.kind ?? kind;
    date =
        e?.date ?? localDate(c.clock().toUtc().add(const Duration(hours: 7)));
    time =
        e?.time ?? localTime(c.clock().toUtc().add(const Duration(hours: 7)));
    units = TextEditingController(text: e?.quantity.text ?? '');
    fee = TextEditingController(text: e?.fee.input ?? '0');
    note = TextEditingController(text: e?.note ?? '');
    final currency = c.snapshot.accounts
        .firstWhere((a) => a.id == plan.accountId)
        .currency;
    fx = TextEditingController(
      text: e?.idrRate.text ?? c.snapshot.extras.rate(currency)?.text ?? '',
    );
    feeOn = e?.fee.isPositive ?? false;
    pending = e?.pendingBucket ?? false;
    restake = e?.rewardStaked ?? false;
    availableOn = e?.availableOn;
  }

  @override
  void dispose() {
    for (final t in [units, fee, fx, note]) {
      t.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final a = c.snapshot.accounts.firstWhere((a) => a.id == plan.accountId);
    try {
      final e = InvestmentEvent(
        id: widget.existing?.id ?? c.newId(),
        instrumentId: plan.instrumentId,
        accountId: plan.accountId,
        stakingId: plan.id,
        kind: kind,
        quantity: Decimal.input(units.text),
        gross: Money.zero,
        fee: feeOn ? Money.input(fee.text) : Money.zero,
        date: date,
        time: time,
        createdAt:
            widget.existing?.createdAt ?? c.clock().toUtc().toIso8601String(),
        idrRate: a.currency == 'IDR' ? Decimal.one : Decimal.input(fx.text),
        note: note.text.trim(),
        pendingBucket:
            {
              InvestmentKind.unstake,
              InvestmentKind.stakingLoss,
            }.contains(kind) &&
            pending,
        rewardStaked: kind == InvestmentKind.stakingReward && restake,
        availableOn: kind == InvestmentKind.unstakeRequest ? availableOn : null,
      );
      InvestmentEvent.fromJson(e.toJson());
      if (mounted) await finishFinanceSave(context, c, c.saveInvestment(e));
    } on FormatException catch (e) {
      if (mounted) financeMessage(context, e.message);
    }
  }

  Future<void> remove() async {
    final ok = await showFinanceDialog<bool>(
      context: context,
      builder: (ctx) => FinanceDialog(
        title: const Text('Hapus aktivitas staking?'),
        content: const Text(
          'Seluruh urutan kas, unit dan kunci staking dihitung ulang. Ditolak jika aktivitas berikutnya tidak lagi valid.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await finishFinanceSave(
        context,
        c,
        c.deleteInvestment(widget.existing!.id),
      );
    }
  }

  @override
  Widget build(BuildContext ctx) => AnimatedBuilder(
    animation: c,
    builder: (ctx, _) {
      final a = c.snapshot.accounts.firstWhere((a) => a.id == plan.accountId);
      final i = c.snapshot.extras.instruments.firstWhere(
        (i) => i.id == plan.instrumentId,
      );
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.existing == null
                ? 'Catat staking'
                : 'Edit aktivitas staking',
          ),
          actions: [
            if (widget.existing != null)
              IconButton(
                onPressed: c.busy ? null : remove,
                tooltip: 'Hapus aktivitas',
                icon: const ArtaIcon(FeatherIcons.trash2),
              ),
          ],
        ),
        body: Form(
          key: form,
          child: financeFormBody([
            Text('${plan.name} · ${i.code}\n${a.name}'),
            FinanceSelect<InvestmentKind>(
              initialValue: kind,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Aktivitas'),
              items: [
                for (final k in InvestmentKind.values.where(isStaking))
                  DropdownMenuItem(value: k, child: Text(investmentLabel(k))),
              ],
              onChanged: (v) => setState(() => kind = v!),
            ),
            numberField(
              units,
              'Jumlah unit ${i.code}',
              key: const Key('staking-units'),
            ),
            if ({
              InvestmentKind.unstake,
              InvestmentKind.stakingLoss,
            }.contains(kind))
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ambil dari unit menunggu unstake'),
                subtitle: const Text(
                  'Nonaktif: unit aktif staking. Aktif: unit dalam proses unstake.',
                ),
                value: pending,
                onChanged: (v) => setState(() => pending = v),
              ),
            if (kind == InvestmentKind.stakingReward)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Reward langsung di-stake kembali'),
                subtitle: const Text('Nonaktif: reward menjadi unit bebas.'),
                value: restake,
                onChanged: (v) => setState(() => restake = v),
              ),
            if (kind == InvestmentKind.unstakeRequest) ...[
              OutlinedButton(
                onPressed: () async {
                  final d = await pickFinanceDate(ctx, availableOn ?? date);
                  if (d != null && mounted) setState(() => availableOn = d);
                },
                child: Text('Perkiraan cair: ${availableOn ?? 'belum diisi'}'),
              ),
              if (availableOn != null)
                TextButton(
                  onPressed: () => setState(() => availableOn = null),
                  child: const Text('Hapus perkiraan cair'),
                ),
            ],
            TransferFeeField(
              enabled: feeOn,
              onChanged: (v) => setState(() => feeOn = v),
              controller: fee,
              validator: (v) {
                try {
                  return Money.input(v ?? '').isNegative ? 'Minimal 0.' : null;
                } on FormatException catch (e) {
                  return e.message;
                }
              },
            ),
            Text(
              'Biaya tunai memakai ${a.currency} dari aset ${a.name}. Biaya dalam token dicatat sebagai slashing/biaya unit staking.',
            ),
            if (a.currency != 'IDR')
              numberField(fx, 'Kurs historis IDR per 1 ${a.currency}'),
            OutlinedButton.icon(
              onPressed: () async {
                final d = await pickFinanceDate(
                  ctx,
                  date,
                  now: c.clock().toUtc().add(const Duration(hours: 7)),
                );
                if (d != null && mounted) setState(() => date = d);
              },
              icon: const ArtaIcon(FeatherIcons.calendar),
              label: Text(date),
            ),
            TransactionTimeField(
              value: time,
              onChanged: (v) => setState(() => time = v),
            ),
            TextFormField(
              controller: note,
              decoration: const InputDecoration(labelText: 'Catatan'),
            ),
            FilledButton(
              key: const Key('save-staking-event'),
              onPressed: c.busy ? null : save,
              child: const Text('Simpan aktivitas'),
            ),
          ]),
        ),
      );
    },
  );
}
