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
import '../widgets/finance_fields.dart';
import '../widgets/transaction_time_field.dart';
import '../widgets/transfer_fee_field.dart';
import 'catalog_screen.dart';

class InvestmentForm extends StatefulWidget {
  const InvestmentForm({
    super.key,
    required this.controller,
    this.instrument,
    this.existing,
  });
  final FinanceController controller;
  final Instrument? instrument;
  final InvestmentEvent? existing;
  @override
  State<InvestmentForm> createState() => _InvestmentFormState();
}

class _InvestmentFormState extends State<InvestmentForm> {
  final form = GlobalKey<FormState>();
  late TextEditingController units, gross, fee, fx, note, unitFee, unitPrice;
  Instrument? instrument;
  InvestmentKind kind = InvestmentKind.buy;
  String? account, destination, time;
  late String date;
  bool feeOn = false, unknown = false, lots = false, unitPriceMode = false;
  FinanceController get c => widget.controller;
  Account? get source =>
      c.snapshot.accounts.where((a) => a.id == account).firstOrNull;
  bool get hasCash => {
    InvestmentKind.buy,
    InvestmentKind.sell,
    InvestmentKind.dividend,
    InvestmentKind.opening,
  }.contains(kind);
  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    instrument =
        widget.instrument ??
        c.snapshot.extras.instruments
            .where((i) => i.id == e?.instrumentId)
            .firstOrNull;
    kind = e?.kind ?? kind;
    account =
        e?.accountId ??
        c.snapshot.accounts
            .where((a) => a.kind == AccountKind.exchange)
            .firstOrNull
            ?.id ??
        c.snapshot.accounts.firstOrNull?.id;
    destination = e?.destinationId;
    date =
        e?.date ?? localDate(c.clock().toUtc().add(const Duration(hours: 7)));
    time =
        e?.time ?? localTime(c.clock().toUtc().add(const Duration(hours: 7)));
    units = TextEditingController(text: e?.quantity.text ?? '');
    gross = TextEditingController(text: e?.gross.input ?? '');
    fee = TextEditingController(text: e?.fee.input ?? '0');
    feeOn = e?.fee.isPositive ?? false;
    fx = TextEditingController(
      text:
          e?.idrRate.text ??
          (source == null
              ? ''
              : c.snapshot.extras.rate(source!.currency)?.text ?? ''),
    );
    note = TextEditingController(text: e?.note ?? '');
    unitFee = TextEditingController(text: e?.networkFee.text ?? '0');
    unitPrice = TextEditingController();
    unknown = e?.unknownCost ?? false;
  }

  @override
  void dispose() {
    for (final t in [units, gross, fee, fx, note, unitFee, unitPrice]) {
      t.dispose();
    }
    super.dispose();
  }

  Future<void> choose() async {
    final i = await Navigator.push<Instrument>(
      context,
      MaterialPageRoute(
        builder: (_) => CatalogScreen(controller: c, select: true),
      ),
    );
    if (i != null && mounted) {
      setState(() {
        instrument = i;
        lots = false;
      });
    }
  }

  void priceTotal() {
    try {
      var qty = Decimal.input(units.text);
      if (lots) qty = qty * Decimal.parse('100');
      gross.text = (qty * Decimal.input(unitPrice.text)).money().input;
    } on FormatException {
      gross.clear();
    }
  }

  Future<void> save() async {
    if (c.busy || !form.currentState!.validate()) return;
    if (instrument == null) {
      financeMessage(context, 'Pilih instrumen.');
      return;
    }
    try {
      var qty = kind == InvestmentKind.dividend
          ? Decimal.zero
          : Decimal.input(units.text);
      if (lots &&
          instrument!.kind == InstrumentKind.stock &&
          kind != InvestmentKind.split) {
        qty = qty * Decimal.parse('100');
      }
      final value = InvestmentEvent(
        id: widget.existing?.id ?? c.newId(),
        instrumentId: instrument!.id,
        accountId: account!,
        kind: kind,
        quantity: qty,
        gross: hasCash && !unknown ? Money.input(gross.text) : Money.zero,
        fee:
            feeOn &&
                {
                  InvestmentKind.buy,
                  InvestmentKind.sell,
                  InvestmentKind.dividend,
                  InvestmentKind.transfer,
                }.contains(kind)
            ? Money.input(fee.text)
            : Money.zero,
        date: date,
        time: time,
        createdAt:
            widget.existing?.createdAt ?? c.clock().toUtc().toIso8601String(),
        idrRate: source!.currency == 'IDR'
            ? Decimal.one
            : Decimal.input(fx.text),
        destinationId: kind == InvestmentKind.transfer ? destination : null,
        unitFee: kind == InvestmentKind.transfer
            ? Decimal.input(unitFee.text)
            : Decimal.zero,
        unknownCost: kind == InvestmentKind.opening && unknown,
        note: note.text.trim(),
      );
      InvestmentEvent.fromJson(value.toJson());
      if (!mounted) return;
      await finishFinanceSave(context, c, c.saveInvestment(value));
    } on FormatException catch (e) {
      if (mounted) financeMessage(context, e.message);
    }
  }

  Future<void> remove() async {
    final accepted = await showFinanceDialog<bool>(
      context: context,
      builder: (ctx) => FinanceDialog(
        title: const Text('Hapus transaksi investasi?'),
        content: const Text(
          'Saldo kas dan seluruh kepemilikan sesudahnya dihitung ulang. Penghapusan ditolak jika membuat unit historis negatif.',
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
    if (accepted == true && mounted) {
      await finishFinanceSave(
        context,
        c,
        c.deleteInvestment(widget.existing!.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: c,
    builder: (ctx, _) => Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? 'Catat investasi' : 'Edit investasi',
        ),
        actions: [
          if (widget.existing != null)
            IconButton(
              onPressed: c.busy ? null : remove,
              tooltip: 'Hapus investasi',
              icon: const ArtaIcon(FeatherIcons.trash2),
            ),
        ],
      ),
      body: Form(
        key: form,
        child: financeFormBody([
          const Text(
            'Transfer dana bank → RDN/exchange dicatat di transaksi Transfer. Di sini catat unit yang sudah dikonfirmasi platform. Tidak menghubungkan aset exchange/sekuritas.',
          ),
          OutlinedButton.icon(
            onPressed: c.busy || widget.existing != null ? null : choose,
            icon: const ArtaIcon(FeatherIcons.search),
            label: Text(
              instrument == null
                  ? 'Pilih instrumen'
                  : '${instrument!.code} · ${instrument!.displayName}',
            ),
          ),
          FinanceSelect<InvestmentKind>(
            initialValue: kind,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Jenis pencatatan'),
            items: [
              for (final k in InvestmentKind.values.where((k) => !isStaking(k)))
                DropdownMenuItem(value: k, child: Text(investmentLabel(k))),
            ],
            onChanged: c.busy
                ? null
                : (v) => setState(() {
                    kind = v!;
                    unknown = false;
                    unitPriceMode = false;
                  }),
          ),
          accountField(
            c.snapshot.accounts,
            account,
            (v) => setState(() {
              account = v;
              fx.text = c.snapshot.extras.rate(source!.currency)?.text ?? '';
              unitPriceMode = false;
            }),
            label: kind == InvestmentKind.opening
                ? 'Lokasi unit awal'
                : 'Aset kas / lokasi aset',
          ),
          if (kind == InvestmentKind.transfer) ...[
            accountField(
              c.snapshot.accounts.where((a) => a.id != account).toList(),
              destination == account ? null : destination,
              (v) => setState(() => destination = v),
              label: 'Lokasi tujuan unit',
            ),
            const Text(
              'Unit yang dikirim membawa modal rata-rata asal. Biaya jaringan unit dibebankan dari lokasi asal; biaya tunai memakai mata uang aset asal.',
            ),
          ],
          if (kind != InvestmentKind.dividend) ...[
            if (instrument?.kind == InstrumentKind.stock &&
                kind != InvestmentKind.split)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Input dalam lot (1 lot = 100 lembar)'),
                value: lots,
                onChanged: (v) => setState(() {
                  lots = v;
                  if (unitPriceMode) priceTotal();
                }),
              ),
            numberField(
              units,
              kind == InvestmentKind.split
                  ? 'Faktor split (2 untuk 1:2; 0,5 untuk reverse)'
                  : lots
                  ? 'Jumlah lot'
                  : 'Unit / lembar',
              key: const Key('investment-units'),
            ),
          ],
          if (kind == InvestmentKind.opening)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Modal awal tidak diketahui'),
              subtitle: const Text(
                'Laba berbasis modal tidak akan diklaim sampai modal tersedia.',
              ),
              value: unknown,
              onChanged: (v) => setState(() => unknown = v),
            ),
          if (hasCash && !unknown) ...[
            if ({InvestmentKind.buy, InvestmentKind.sell}.contains(kind))
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Hitung nominal dari unit × harga'),
                value: unitPriceMode,
                onChanged: (v) => setState(() => unitPriceMode = v),
              ),
            if (unitPriceMode) ...[
              numberField(
                unitPrice,
                'Harga per unit / lembar (${source?.currency ?? 'IDR'})',
              ),
              OutlinedButton(
                onPressed: priceTotal,
                child: const Text('Hitung nominal bruto'),
              ),
            ],
            numberField(
              gross,
              kind == InvestmentKind.opening
                  ? 'Total modal historis (${source?.currency ?? 'IDR'})'
                  : 'Nominal bruto (${source?.currency ?? 'IDR'})',
              money: true,
              zero: kind == InvestmentKind.opening,
              key: const Key('investment-gross'),
            ),
          ],
          if ({
            InvestmentKind.buy,
            InvestmentKind.sell,
            InvestmentKind.dividend,
            InvestmentKind.transfer,
          }.contains(kind))
            TransferFeeField(
              enabled: feeOn,
              onChanged: (v) => setState(() => feeOn = v),
              controller: fee,
              validator: (v) {
                try {
                  if (Money.input(v ?? '').isNegative) return 'Minimal 0.';
                  return null;
                } on FormatException catch (e) {
                  return e.message;
                }
              },
            ),
          if (kind == InvestmentKind.transfer)
            numberField(unitFee, 'Biaya jaringan dalam unit aset', zero: true),
          if (source?.currency != 'IDR')
            numberField(
              fx,
              'Kurs historis IDR per 1 ${source?.currency ?? 'mata uang'}',
            ),
          OutlinedButton.icon(
            onPressed: () async {
              final d = await pickFinanceDate(
                context,
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
            maxLength: 1000,
            decoration: const InputDecoration(labelText: 'Catatan'),
          ),
          const Text(
            'Saldo unit awal tidak menarik kas. Reward unit memiliki modal nol. Beli menambah modal termasuk biaya; jual memakai metode rata-rata tertimbang. Split mengubah unit tanpa mengubah total modal.',
          ),
          FilledButton(
            key: const Key('save-investment'),
            onPressed: c.busy || account == null ? null : save,
            child: const Text('Simpan investasi'),
          ),
        ]),
      ),
    ),
  );
}

class PriceForm extends StatefulWidget {
  const PriceForm({
    super.key,
    required this.controller,
    required this.instrument,
  });
  final FinanceController controller;
  final Instrument instrument;
  @override
  State<PriceForm> createState() => _PriceFormState();
}

class _PriceFormState extends State<PriceForm> {
  final form = GlobalKey<FormState>();
  late TextEditingController price;
  late String date;
  @override
  void initState() {
    super.initState();
    final q = widget.controller.snapshot.extras.latest(widget.instrument.id);
    price = TextEditingController(text: q?.price.text ?? '');
    date =
        q?.date ??
        localDate(
          widget.controller.clock().toUtc().add(const Duration(hours: 7)),
        );
  }

  @override
  void dispose() {
    price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (ctx, _) => Scaffold(
      appBar: AppBar(title: Text('Harga / NAB · ${widget.instrument.code}')),
      body: Form(
        key: form,
        child: financeFormBody([
          Text(
            widget.instrument.kind == InstrumentKind.fund
                ? 'Isi NAB per unit dan tanggal NAB dari Bibit. Ini memperbarui valuasi, bukan jumlah unit.'
                : 'Isi harga terakhir yang diketahui dan tanggal harganya. Harga beli historis tetap tersimpan.',
          ),
          numberField(
            price,
            'Harga per unit (${widget.instrument.currency})',
            key: const Key('manual-price'),
          ),
          OutlinedButton(
            onPressed: () async {
              final d = await pickFinanceDate(
                context,
                date,
                now: widget.controller.clock().toUtc().add(
                  const Duration(hours: 7),
                ),
              );
              if (d != null && mounted) setState(() => date = d);
            },
            child: Text('Tanggal harga: $date'),
          ),
          FilledButton(
            onPressed: widget.controller.busy
                ? null
                : () async {
                    if (!form.currentState!.validate()) return;
                    await finishFinanceSave(
                      context,
                      widget.controller,
                      widget.controller.saveQuotes([
                        PriceQuote(
                          instrumentId: widget.instrument.id,
                          price: Decimal.input(price.text),
                          currency: widget.instrument.currency,
                          date: date,
                          fetchedAt: widget.controller
                              .clock()
                              .toUtc()
                              .toIso8601String(),
                          source: widget.instrument.kind == InstrumentKind.fund
                              ? 'NAB manual'
                              : 'Manual',
                        ),
                      ]),
                    );
                  },
            child: const Text('Simpan harga'),
          ),
        ]),
      ),
    ),
  );
}
