import '../widgets/finance_dialog.dart';
import '../widgets/finance_date_field.dart';
import '../models/recurrence_option.dart';
import '../widgets/transaction_tabs.dart';
import '../widgets/transaction_category_field.dart';
import '../widgets/finance_select.dart';
import '../widgets/arta_icon.dart';

import 'package:feather_icons/feather_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../controllers/finance_controller.dart';
import '../models/ledger.dart';
import '../models/money.dart';
import '../models/schedule.dart';
import '../services/schedule_engine.dart';
import '../widgets/transfer_fee_field.dart';
import '../widgets/transaction_time_field.dart';
import '../widgets/receipt_images_field.dart';
import '../models/receipt_image.dart';
import '../models/decimal.dart';
import '../widgets/finance_fields.dart';

enum EntryMode { once, repeat, installment }

class TransactionForm extends StatefulWidget {
  const TransactionForm({
    super.key,
    required this.controller,
    this.existing,
    this.initialMode = EntryMode.once,
    this.replaces,
    this.initialAccountId,
    this.initialDestinationId,
    this.initialKind,
  });
  final FinanceController controller;
  final LedgerTransaction? existing;
  final EntryMode initialMode;
  final ScheduleRule? replaces;
  final String? initialAccountId, initialDestinationId;
  final TransactionKind? initialKind;
  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final form = GlobalKey<FormState>();
  late final TextEditingController amount,
      fee,
      category,
      note,
      name,
      interval,
      count;
  late EntryMode entryMode;
  RepeatFrequency frequency = RepeatFrequency.monthly;
  ScheduleMode scheduleMode = ScheduleMode.confirm;
  bool endOfMonth = false;
  int? monthDay;
  List<int> weekdays = [];
  bool chooseWeekdays = false;
  String? endDate;
  String zone = 'Asia/Jakarta';
  bool get scheduled => entryMode != EntryMode.once;
  bool get installment => entryMode == EntryMode.installment;
  late TransactionKind kind;
  final categoryDrafts = <TransactionKind, String>{};
  late String accountId, date;
  String? destinationId;
  bool saving = false;
  late bool feeEnabled;
  late bool senderFeeEnabled, receiverFeeEnabled;
  late TextEditingController receiverFee, receiverFx;
  String get receiverCurrency =>
      widget.controller.snapshot.accounts
          .where((a) => a.id == destinationId)
          .firstOrNull
          ?.currency ??
      currency;
  String? time, cardId;
  List<ReceiptImage> images = [];
  late TextEditingController destinationAmount, fx;
  String get currency => widget.controller.snapshot.accounts
      .firstWhere((a) => a.id == accountId)
      .currency;
  bool get crossCurrency =>
      kind == TransactionKind.transfer &&
      destinationId != null &&
      currency !=
          widget.controller.snapshot.accounts
              .firstWhere((a) => a.id == destinationId)
              .currency;
  String get today => localDate(
    widget.controller.clock().toUtc().add(
      Duration(hours: scheduleZones[zone]!),
    ),
  );
  late final int replacesResolvedCount;
  @override
  void initState() {
    super.initState();
    final tx = widget.existing;
    final rule = widget.replaces;
    zone = tx?.zone ?? rule?.zone ?? zone;
    time = tx != null
        ? tx.time
        : rule != null
        ? rule.time
        : localTime(
            widget.controller.clock().toUtc().add(
              Duration(hours: scheduleZones[zone]!),
            ),
          );
    cardId = tx?.cardId;
    images = [...?tx?.images];
    replacesResolvedCount = widget.controller.snapshot.occurrences
        .where((o) => o.scheduleId == rule?.id)
        .length;
    entryMode = rule == null
        ? widget.initialMode
        : (rule.installments ? EntryMode.installment : EntryMode.repeat);
    kind =
        tx?.kind ?? rule?.kind ?? widget.initialKind ?? TransactionKind.expense;
    accountId =
        tx?.accountId ??
        rule?.accountId ??
        widget.initialAccountId ??
        widget.controller.snapshot.accounts.first.id;
    destinationAmount = TextEditingController(
      text: tx?.destinationAmount?.input ?? '',
    );
    fx = TextEditingController(
      text:
          tx?.idrRate?.text ??
          widget.controller.snapshot.extras.rate(currency)?.text ??
          '',
    );
    destinationId =
        tx?.destinationId ?? rule?.destinationId ?? widget.initialDestinationId;
    final remaining = rule == null
        ? <PendingOccurrence>[]
        : ScheduleEngine.pending(
            rule,
            widget.controller.snapshot.occurrences,
            limit: 1200,
          ).toList();
    date =
        tx?.date ??
        remaining.firstOrNull?.date ??
        localDate(
          widget.controller.clock().toUtc().add(const Duration(hours: 7)),
        );
    final rest = rule?.installments == true
        ? remaining.fold(Money.zero, (sum, item) => sum + item.amount)
        : null;
    amount = TextEditingController(
      text: tx?.amount.input ?? rest?.input ?? rule?.amount.input ?? '',
    );
    fee = TextEditingController(text: tx?.fee.input ?? rule?.fee.input ?? '0');
    receiverFee = TextEditingController(
      text: tx?.receivingFee.input ?? rule?.receivingFee.input ?? '0',
    );
    receiverFx = TextEditingController(
      text:
          tx?.receiverFeeRate?.text ??
          widget.controller.snapshot.extras.rate(receiverCurrency)?.text ??
          '',
    );
    receiverFeeEnabled =
        !(tx?.receivingFee ?? rule?.receivingFee ?? Money.zero).isZero;
    senderFeeEnabled =
        !(tx?.fee ?? rule?.fee ?? Money.zero).isZero || !receiverFeeEnabled;
    feeEnabled =
        !(tx?.fee ?? rule?.fee ?? Money.zero).isZero || receiverFeeEnabled;
    category = TextEditingController(
      text: tx?.category ?? rule?.category ?? '',
    );
    note = TextEditingController(text: tx?.note ?? rule?.note ?? '');
    name = TextEditingController(text: rule?.name ?? '');
    interval = TextEditingController(text: rule?.interval.toString() ?? '1');
    count = TextEditingController(
      text: rule?.count != null
          ? remaining.length.toString()
          : (installment ? '12' : ''),
    );
    if (rule != null) {
      frequency = rule.frequency;
      weekdays = [...rule.weekdays];
      chooseWeekdays = weekdays.isNotEmpty;
      scheduleMode = rule.mode;
      endOfMonth = rule.endOfMonth;
      monthDay =
          rule.monthDay ??
          (!rule.endOfMonth &&
                  (rule.frequency == RepeatFrequency.monthly ||
                      rule.frequency == RepeatFrequency.yearly)
              ? DateTime.parse(rule.startDate).day
              : null);
      endDate = rule.endDate;
      zone = rule.zone;
    }
  }

  @override
  void dispose() {
    for (final c in [amount, fee, category, note, name, interval, count]) {
      c.dispose();
    }
    receiverFee.dispose();
    receiverFx.dispose();
    destinationAmount.dispose();
    fx.dispose();
    super.dispose();
  }

  String? moneyValidator(String? text, {bool allowZero = false}) {
    try {
      final value = Money.input(text ?? '');
      return (allowZero ? value.isNegative : !value.isPositive)
          ? (allowZero ? 'Biaya minimal 0.' : 'Nominal harus lebih dari 0.')
          : null;
    } on FormatException catch (e) {
      return e.message;
    }
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    if (scheduled && crossCurrency) {
      financeMessage(
        context,
        'Jadwal transfer memakai dua aset bermata uang sama. Catat transfer lintas mata uang sebagai transaksi sekali dengan nominal tujuan aktual.',
      );
      return;
    }
    if (scheduled && !installment && chooseWeekdays && weekdays.isEmpty) {
      financeMessage(context, 'Pilih minimal satu hari berulang.');
      return;
    }
    setState(() => saving = true);
    bool ok;
    if (scheduled) {
      final rule = ScheduleRule(
        id: widget.controller.newId(),
        name: name.text.trim(),
        kind: kind,
        accountId: accountId,
        destinationId: kind == TransactionKind.transfer ? destinationId : null,
        amount: Money.input(amount.text),
        receiverFee:
            kind == TransactionKind.transfer && feeEnabled && receiverFeeEnabled
            ? Money.input(receiverFee.text)
            : Money.zero,
        fee: kind == TransactionKind.transfer && feeEnabled && senderFeeEnabled
            ? Money.input(fee.text)
            : Money.zero,
        category: kind == TransactionKind.transfer ? '' : category.text.trim(),
        note: note.text.trim(),
        startDate: date,
        frequency: installment ? RepeatFrequency.monthly : frequency,
        weekdays: !installment && chooseWeekdays
            ? List.unmodifiable(weekdays)
            : const [],
        interval: int.parse(interval.text),
        endOfMonth: endOfMonth,
        monthDay:
            (installment ||
                    frequency == RepeatFrequency.monthly ||
                    frequency == RepeatFrequency.yearly) &&
                !endOfMonth
            ? monthDay
            : null,
        endDate: installment ? null : endDate,
        count: count.text.trim().isEmpty ? null : int.parse(count.text),
        installments: installment,
        mode: scheduleMode,
        zone: zone,
        state: widget.replaces?.state ?? ScheduleState.active,
        createdAt: widget.controller.clock().toUtc().toIso8601String(),
        time: time,
      );
      ok = await widget.controller.saveSchedule(
        rule,
        replacesId: widget.replaces?.id,
        replacesResolvedCount: replacesResolvedCount,
      );
    } else {
      ok = await widget.controller.saveTransaction(
        kind: kind,
        accountId: accountId,
        destinationId: kind == TransactionKind.transfer ? destinationId : null,
        amount: Money.input(amount.text),
        receiverFee:
            kind == TransactionKind.transfer && feeEnabled && receiverFeeEnabled
            ? Money.input(receiverFee.text)
            : Money.zero,
        fee: kind == TransactionKind.transfer && feeEnabled && senderFeeEnabled
            ? Money.input(fee.text)
            : Money.zero,
        receiverFeeRate:
            kind == TransactionKind.transfer && feeEnabled && receiverFeeEnabled
            ? (receiverCurrency == 'IDR'
                  ? Decimal.one
                  : (receiverCurrency == currency
                        ? Decimal.input(fx.text)
                        : Decimal.input(receiverFx.text)))
            : null,
        date: date,
        category: kind == TransactionKind.transfer ? '' : category.text,
        note: note.text,
        existing: widget.existing,
        time: time,
        zone: zone,
        cardId: cardId,
        images: images,
        destinationAmount: crossCurrency
            ? Money.input(destinationAmount.text)
            : null,
        idrRate: currency == 'IDR' ? Decimal.one : Decimal.input(fx.text),
      );
    }
    if (!mounted) return;
    setState(() => saving = false);
    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(widget.controller.error!)));
    }
  }

  String? integer(String? text, int min, int max, {bool optional = false}) {
    if (optional && (text ?? '').trim().isEmpty) return null;
    final value = int.tryParse(text ?? '');
    return value == null || value < min || value > max
        ? 'Isi angka $min–$max.'
        : null;
  }

  Future<void> selectDate({bool ending = false}) async {
    final today = DateTime.parse(
      localDate(
        widget.controller.clock().toUtc().add(
          Duration(hours: scheduleZones[zone]!),
        ),
      ),
    );
    final initial = DateTime.parse((ending ? endDate : date) ?? date);
    final selected = await showDatePicker(
      context: context,
      initialDate: !scheduled && initial.isAfter(today) ? today : initial,
      firstDate: ending ? DateTime.parse(date) : DateTime(1900),
      lastDate: scheduled ? DateTime(2199, 12, 31) : today,
    );
    if (selected != null && mounted) {
      setState(() {
        if (ending) {
          endDate = localDate(selected);
        } else {
          date = localDate(selected);
          monthDay = selected.day;
          if (endDate != null && endDate!.compareTo(date) < 0) endDate = null;
        }
      });
    }
  }

  List<Widget> scheduleFields() => [
    const SizedBox(height: 20),
    TextFormField(
      key: const Key('schedule-name'),
      controller: name,
      maxLength: 80,
      decoration: const InputDecoration(
        labelText: 'Nama jadwal',
        hintText: 'Biaya bank akhir bulan',
      ),
      validator: (v) =>
          v == null || v.trim().isEmpty ? 'Isi nama jadwal.' : null,
    ),
    if (!installment) ...[
      const SizedBox(height: 20),
      FinanceSelect<RecurrenceOption>(
        key: const Key('repeat-frequency'),
        initialValue: chooseWeekdays
            ? RecurrenceOption.weekdays
            : RecurrenceOption.match(
                frequency,
                int.tryParse(interval.text) ?? 1,
                endOfMonth,
                weekdays,
              ),
        decoration: const InputDecoration(labelText: 'Frekuensi'),
        items: [
          for (final option in RecurrenceOption.values)
            DropdownMenuItem(value: option, child: Text(option.label)),
        ],
        onChanged: saving
            ? null
            : (v) => setState(() {
                if (frequency != v!.frequency) monthDay = null;
                frequency = v.frequency;
                interval.text = '${v.interval}';
                endOfMonth = v == RecurrenceOption.monthEnd;
                chooseWeekdays = v == RecurrenceOption.weekdays;
                if (!chooseWeekdays) weekdays = [];
              }),
      ),
      if (chooseWeekdays) ...[
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var d = 1; d <= 7; d++)
              FilterChip(
                label: Text(
                  [
                    'Senin',
                    'Selasa',
                    'Rabu',
                    'Kamis',
                    'Jumat',
                    'Sabtu',
                    'Minggu',
                  ][d - 1],
                ),
                selected: weekdays.contains(d),
                onSelected: saving
                    ? null
                    : (selected) => setState(() {
                        if (selected) {
                          weekdays.add(d);
                        } else {
                          weekdays.remove(d);
                        }
                      }),
              ),
          ],
        ),
      ],
    ],
    if (installment ||
        RecurrenceOption.match(
              frequency,
              int.tryParse(interval.text) ?? 1,
              endOfMonth,
              weekdays,
            ) ==
            null) ...[
      const SizedBox(height: 20),
      TextFormField(
        key: const Key('schedule-interval'),
        controller: interval,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Interval periode'),
        validator: (v) => integer(v, 1, 999),
      ),
    ],
    if (installment || frequency == RepeatFrequency.monthly) ...[
      const SizedBox(height: 12),
      SwitchListTile.adaptive(
        key: const Key('schedule-end-of-month'),
        contentPadding: EdgeInsets.zero,
        title: const Text('Hari terakhir setiap bulan'),
        subtitle: Text(
          endOfMonth
              ? 'Mengikuti 28/29, 30, atau 31 sesuai kalender.'
              : 'Tanggal ${monthDay ?? DateTime.parse(date).day} setiap bulan. Bulan pendek memakai hari terakhir.',
        ),
        value: endOfMonth,
        onChanged: saving ? null : (v) => setState(() => endOfMonth = v),
      ),
    ],
    const SizedBox(height: 20),
    TextFormField(
      key: const Key('schedule-count'),
      controller: count,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: installment
            ? 'Jumlah cicilan (bagian)'
            : 'Jumlah kejadian (opsional)',
        helperText: installment
            ? 'Total dibagi dalam sen. Sisa pembulatan masuk bagian terakhir.'
            : 'Kosongkan untuk terus berulang. Tanggal akhir juga dapat membatasi jadwal.',
      ),
      validator: (v) =>
          integer(v, installment ? 2 : 1, 1200, optional: !installment),
    ),
    if (!installment) ...[
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: saving ? null : () => selectDate(ending: true),
        icon: const ArtaIcon(FeatherIcons.calendar),
        label: Text(
          endDate == null ? 'Tanggal akhir (opsional)' : 'Sampai $endDate',
        ),
      ),
      if (endDate != null)
        TextButton(
          onPressed: saving ? null : () => setState(() => endDate = null),
          child: const Text('Tanpa tanggal akhir'),
        ),
    ],
    const SizedBox(height: 20),
    FinanceSelect<String>(
      initialValue: zone,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Zona waktu jadwal'),
      items: const [
        DropdownMenuItem(
          value: 'Asia/Jakarta',
          child: Text('WIB · Asia/Jakarta'),
        ),
        DropdownMenuItem(
          value: 'Asia/Makassar',
          child: Text('WITA · Asia/Makassar'),
        ),
        DropdownMenuItem(
          value: 'Asia/Jayapura',
          child: Text('WIT · Asia/Jayapura'),
        ),
      ],
      onChanged: saving ? null : (v) => setState(() => zone = v!),
    ),
    const SizedBox(height: 20),
    FinanceSelect<ScheduleMode>(
      key: const Key('schedule-mode'),
      initialValue: scheduleMode,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Mode pencatatan'),
      items: const [
        DropdownMenuItem(
          value: ScheduleMode.confirm,
          child: Text('Minta konfirmasi'),
        ),
        DropdownMenuItem(
          value: ScheduleMode.automatic,
          child: Text(
            'Catat otomatis saat jatuh tempo',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
      onChanged: saving ? null : (v) => setState(() => scheduleMode = v!),
    ),
    const SizedBox(height: 12),
    Text(
      scheduleMode == ScheduleMode.automatic
          ? 'Saat disimpan, dibuka, atau kembali ke aplikasi, semua jadwal lewat yang belum diproses akan dicatat. Saldo boleh minus. Jadwal tidak melakukan debit ke bank.'
          : 'Kejadian jatuh tempo menunggu Anda catat atau lewati di menu Transaksi berulang. Saldo berubah setelah dicatat.',
    ),
    if (installment)
      const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Text(
          'Ini pembagian pengeluaran berkala. Total tidak dicatat sekali lagi di awal; belum mencakup utang, bunga kredit, atau pelunasan sebagian.',
        ),
      ),
    if (widget.replaces != null)
      const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Text(
          'Menyimpan akan menghentikan sisa jadwal lama dan membuat jadwal baru. Riwayat lama tetap tersimpan. Tinjau tanggal mulai dan total rencana tersisa sebelum menyimpan.',
        ),
      ),
  ];

  Future<void> remove() async {
    final accepted = await showFinanceDialog<bool>(
      context: context,
      builder: (context) => FinanceDialog(
        title: const Text('Hapus transaksi?'),
        content: Text(
          widget.controller.snapshot.occurrences.any(
                (o) => o.transactionId == widget.existing!.id,
              )
              ? 'Saldo aset akan dihitung ulang. Riwayat jadwal tetap menyimpan kejadian ini sebagai dihapus sehingga tidak dibuat ulang.'
              : 'Saldo aset akan dihitung ulang.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    setState(() => saving = true);
    final ok = await widget.controller.deleteTransaction(widget.existing!.id);
    if (!mounted) return;
    setState(() => saving = false);
    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(widget.controller.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = widget.controller.snapshot.accounts;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.replaces != null
              ? 'Ubah jadwal mendatang'
              : widget.existing != null
              ? 'Edit transaksi'
              : scheduled
              ? (installment ? 'Buat cicilan' : 'Buat transaksi berulang')
              : 'Catat transaksi',
        ),
        actions: [
          if (widget.existing != null)
            IconButton(
              onPressed: saving ? null : remove,
              tooltip: 'Hapus transaksi',
              icon: const ArtaIcon(FeatherIcons.trash2),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: FilledButton(
            key: const Key('save-transaction'),
            onPressed: saving ? null : save,
            child: Text(
              saving
                  ? 'Menyimpan…'
                  : scheduled
                  ? 'Simpan jadwal'
                  : 'Simpan transaksi',
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: form,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TransactionTabs(
                    value: kind,
                    installment: installment,
                    onChanged: saving
                        ? null
                        : (v) => setState(() {
                            categoryDrafts[kind] = category.text;
                            kind = v;
                            category.text = categoryDrafts[v] ?? '';
                          }),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    key: const Key('transaction-amount'),
                    controller: amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: installment
                          ? 'Total pengeluaran yang dibagi ($currency)'
                          : scheduled
                          ? 'Nominal per kejadian ($currency)'
                          : 'Nominal ($currency)',
                      hintText: '10.000',
                    ),
                    validator: moneyValidator,
                  ),
                  const SizedBox(height: 20),
                  if (kind != TransactionKind.transfer) ...[
                    TransactionCategoryField(
                      controller: category,
                      data: widget.controller.snapshot,
                      kind: kind,
                      enabled: !saving,
                      originalCategory: widget.existing?.kind == kind
                          ? widget.existing?.category
                          : widget.replaces?.kind == kind
                          ? widget.replaces?.category
                          : null,
                    ),
                    const SizedBox(height: 20),
                  ],
                  FinanceSelect<String>(
                    key: const Key('source-account'),
                    initialValue: accountId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: kind == TransactionKind.transfer
                          ? 'Dari aset'
                          : 'Aset',
                    ),
                    items: accounts
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(
                              a.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: saving
                        ? null
                        : (v) => setState(() {
                            accountId = v!;
                            fx.text =
                                widget.controller.snapshot.extras
                                    .rate(currency)
                                    ?.text ??
                                '';
                            cardId = null;
                            if (destinationId == accountId) {
                              destinationId = null;
                            }
                          }),
                  ),
                  if (kind == TransactionKind.transfer) ...[
                    const SizedBox(height: 20),
                    FinanceSelect<String>(
                      key: ValueKey('destination-$accountId'),
                      initialValue: destinationId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Ke aset'),
                      items: accounts
                          .where((a) => a.id != accountId)
                          .map(
                            (a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(
                                a.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      validator: (v) => v == null || v == accountId
                          ? 'Pilih aset tujuan berbeda.'
                          : null,
                      onChanged: saving
                          ? null
                          : (v) => setState(() {
                              destinationId = v;
                              receiverFx.text =
                                  widget.controller.snapshot.extras
                                      .rate(receiverCurrency)
                                      ?.text ??
                                  '';
                            }),
                    ),
                  ],
                  if (!scheduled &&
                      widget.controller.snapshot.cards.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    FinanceSelect<String>(
                      key: ValueKey('payment-card-$accountId-$cardId'),
                      initialValue: cardId ?? '',
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Metode pembayaran',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('Langsung dari rekening / aset'),
                        ),
                        ...widget.controller.snapshot.cards
                            .where(
                              (c) => c.accountId == accountId || c.id == cardId,
                            )
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(
                                  '${c.name}${c.accountId != accountId ? ' · sumber historis' : ''}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                      ],
                      onChanged: saving
                          ? null
                          : (v) => setState(() => cardId = v == '' ? null : v),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (crossCurrency) ...[
                    const SizedBox(height: 20),
                    numberField(
                      destinationAmount,
                      'Nominal diterima (${widget.controller.snapshot.accounts.firstWhere((a) => a.id == destinationId).currency})',
                      money: true,
                      key: const Key('destination-amount'),
                    ),
                  ],
                  if (currency != 'IDR' && !scheduled) ...[
                    const SizedBox(height: 20),
                    numberField(
                      fx,
                      'Kurs historis IDR per 1 $currency',
                      key: const Key('transaction-fx'),
                    ),
                  ],
                  if (currency != 'IDR' && scheduled)
                    const Text(
                      'Kejadian jadwal menyimpan kurs valuasi yang tersedia saat dicatat. Isi kurs dahulu di Pengaturan.',
                    ),
                  if (kind == TransactionKind.transfer) ...[
                    const SizedBox(height: 20),
                    TransferFeeField(
                      currency: currency,
                      enabled: feeEnabled,
                      senderEnabled: senderFeeEnabled,
                      receiverEnabled: receiverFeeEnabled,
                      receiverController: receiverFee,
                      receiverCurrency: receiverCurrency,
                      onSenderChanged: saving
                          ? null
                          : (v) => setState(() => senderFeeEnabled = v),
                      onReceiverChanged: saving
                          ? null
                          : (v) => setState(() => receiverFeeEnabled = v),
                      controller: fee,
                      onChanged: saving
                          ? null
                          : (v) => setState(() => feeEnabled = v),
                      validator: (v) => moneyValidator(v, allowZero: true),
                    ),
                    if (feeEnabled &&
                        receiverFeeEnabled &&
                        crossCurrency &&
                        receiverCurrency != 'IDR') ...[
                      const SizedBox(height: 16),
                      numberField(
                        receiverFx,
                        'Kurs historis IDR per 1 $receiverCurrency (biaya penerima)',
                      ),
                    ],
                  ],
                  const SizedBox(height: 20),
                  if (widget.existing == null && widget.replaces == null) ...[
                    FinanceSelect<EntryMode>(
                      key: const Key('entry-mode'),
                      initialValue: entryMode,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Berulang / Cicilan',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: EntryMode.once,
                          child: Text('Sekali saja'),
                        ),
                        DropdownMenuItem(
                          value: EntryMode.repeat,
                          child: Text('Berulang'),
                        ),
                        DropdownMenuItem(
                          value: EntryMode.installment,
                          child: Text('Cicilan pengeluaran'),
                        ),
                      ],
                      onChanged: saving
                          ? null
                          : (v) => setState(() {
                              entryMode = v!;
                              if (installment) {
                                kind = TransactionKind.expense;
                                frequency = RepeatFrequency.monthly;
                                if (count.text.isEmpty) count.text = '12';
                              }
                              if (!scheduled && date.compareTo(today) > 0) {
                                date = today;
                              }
                            }),
                    ),
                    const SizedBox(height: 20),
                  ],
                  FinanceDateField(
                    key: const Key('entry-date'),
                    label: scheduled ? 'Mulai' : 'Tanggal',
                    value: financeDateLabel(date),
                    onTap: saving ? null : selectDate,
                  ),
                  if (scheduled) ...scheduleFields(),
                  const SizedBox(height: 12),
                  TransactionTimeField(
                    value: time,
                    zone: zone,
                    onChanged: saving ? null : (v) => setState(() => time = v),
                  ),
                  if (widget.existing != null &&
                      widget.controller.snapshot.occurrences.any(
                        (o) => o.transactionId == widget.existing!.id,
                      ))
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text(
                        'Transaksi berasal dari jadwal. Edit hanya mengubah transaksi ini; aturan dan kejadian lainnya tetap mengikuti rencana awal.',
                      ),
                    ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: note,
                    maxLength: 1000,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Catatan (opsional)',
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!scheduled) ...[
                    ReceiptImagesField(
                      images: images,
                      onChanged: saving
                          ? null
                          : (v) => setState(() => images = v),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
