import 'dart:convert';
import 'dart:typed_data';

import '../models/ledger.dart';
import '../models/investment.dart';
import '../models/decimal.dart';

final class CsvService {
  String _cell(Object? value) {
    var text = value?.toString() ?? '';
    // Prefix spreadsheet formulas, including leading whitespace before =/+/@.
    if (RegExp(r'^\s*[=+@]').hasMatch(text) ||
        (RegExp(r'^\s*-').hasMatch(text) &&
            !RegExp(r'^-\d+(?:[.,]\d+)?$').hasMatch(text.trim())) ||
        text.startsWith('\t') ||
        text.startsWith('\r')) {
      text = "'$text";
    }
    return '"${text.replaceAll('"', '""')}"';
  }

  Uint8List encode(List<List<Object?>> rows) => Uint8List.fromList(
    utf8.encode(
      '\uFEFF${rows.map((r) => r.map(_cell).join(',')).join('\r\n')}\r\n',
    ),
  );
  List<List<String>> parse(String value) {
    final rows = <List<String>>[];
    var row = <String>[];
    var field = StringBuffer();
    var quoted = false;
    final text = value.replaceFirst('\uFEFF', '');
    for (var i = 0; i < text.length; i++) {
      final c = text[i];
      if (c == '"') {
        if (quoted && i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = !quoted;
        }
      } else if (!quoted && (c == ',' || c == '\n' || c == '\r')) {
        row.add(field.toString());
        field = StringBuffer();
        if (c != ',') {
          if (row.any((v) => v.isNotEmpty)) rows.add(row);
          row = [];
          if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
        }
      } else {
        field.write(c);
      }
    }
    if (quoted) throw const FormatException('Kutip CSV tidak lengkap.');
    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }
    return rows;
  }

  List<PriceQuote> prices(
    String csv,
    List<Instrument> instruments,
    DateTime now,
  ) {
    final rows = parse(csv);
    if (rows.length < 2 || rows.length > 10001) {
      throw const FormatException(
        'CSV harga harus berisi header dan 1–10.000 baris.',
      );
    }
    final h = rows.first.map((v) => v.trim().toLowerCase()).toList();
    for (final key in ['code', 'date', 'price', 'currency']) {
      if (!h.contains(key)) throw FormatException('CSV memerlukan kolom $key.');
    }
    final result = <PriceQuote>[];
    final ids = <String>{};
    for (var n = 1; n < rows.length; n++) {
      String at(String key) =>
          h.indexOf(key) < rows[n].length ? rows[n][h.indexOf(key)].trim() : '';
      final code = at('code').toUpperCase().replaceFirst(RegExp(r'\.JK$'), '');
      final matches = instruments
          .where((i) => i.code == code || i.id == at('code'))
          .toList();
      if (matches.length != 1) {
        throw FormatException(
          'Baris ${n + 1}: kode tidak ditemukan/ambigu. Gunakan ID instrumen jika simbol sama.',
        );
      }
      final i = matches.single;
      String? optional(String key) => h.contains(key) ? at(key) : null;
      final mode = optional('kind') ?? 'close';
      if (!{'close', 'live'}.contains(mode)) {
        throw FormatException('Baris ${n + 1}: jenis harga tidak dikenal.');
      }
      final source = optional('source');
      if (source != null && source.length > 200) {
        throw const FormatException('Sumber harga terlalu panjang.');
      }
      final q = PriceQuote(
        instrumentId: i.id,
        price: Decimal.input(at('price')),
        currency: at('currency').toUpperCase(),
        date: at('date'),
        fetchedAt: now.toUtc().toIso8601String(),
        source: source == null || source.isEmpty
            ? (mode == 'live' ? 'CSV · terbaru manual' : 'CSV / spreadsheet')
            : source,
        isLive: mode == 'live',
        adjustedThrough: optional('adjusted_through')?.isEmpty == false
            ? optional('adjusted_through')
            : null,
      );
      PriceQuote.fromJson(q.toJson());
      if (q.currency != i.currency ||
          q.date.compareTo(
                localDate(now.toUtc().add(const Duration(hours: 7))),
              ) >
              0 ||
          !ids.add(q.key)) {
        throw FormatException(
          'Baris ${n + 1}: mata uang/tanggal/duplikasi tidak valid.',
        );
      }
      result.add(q);
    }
    return result;
  }

  Uint8List transactions(LedgerSnapshot data) {
    final accounts = {for (final a in data.accounts) a.id: a};
    return encode([
      [
        'id',
        'date',
        'time',
        'zone',
        'type',
        'account',
        'destination',
        'currency',
        'amount',
        'destination_amount',
        'fee',
        'receiver_fee',
        'receiver_fee_idr_rate',
        'idr_rate',
        'category',
        'note',
        'instrument_id',
        'units',
        'unit_fee',
        'net_amount',
        'tax',
        'period_start',
        'period_end',
        'destination_currency',
        'staking_id',
        'staking_pending_bucket',
        'staking_reward_restaked',
        'staking_expected_available',
      ],
      for (final t in data.transactions)
        [
          t.id,
          t.date,
          t.time,
          t.zone,
          t.kind.name,
          accounts[t.accountId]?.name,
          accounts[t.destinationId]?.name,
          accounts[t.accountId]?.currency,
          t.amount.input,
          t.destinationAmount?.input ??
              (t.kind == TransactionKind.transfer ? t.amount.input : null),
          t.fee.input,
          t.receivingFee.input,
          t.receiverFeeRate?.text,
          t.idrRate?.text ?? '1',
          t.category,
          t.note,
          null,
          null,
          null,
          t.deltaFor(t.accountId).input,
          null,
          null,
          null,
          accounts[t.destinationId]?.currency,
          null,
          null,
          null,
          null,
        ],
      for (final e in data.extras.events)
        [
          e.id,
          e.date,
          e.time,
          e.zone,
          'investment:${e.kind.name}',
          accounts[e.accountId]?.name,
          accounts[e.destinationId]?.name,
          accounts[e.accountId]?.currency,
          e.gross.input,
          null,
          e.fee.input,
          null,
          null,
          e.idrRate.text,
          e.instrumentId,
          e.note,
          e.instrumentId,
          e.quantity.text,
          e.networkFee.text,
          e.cashDelta(e.accountId).input,
          null,
          null,
          null,
          accounts[e.destinationId]?.currency,
          e.stakingId,
          isStaking(e.kind) ? e.pendingBucket : null,
          isStaking(e.kind) ? e.rewardStaked : null,
          e.availableOn,
        ],
      for (final p in data.extras.interestPostings)
        [
          p.id,
          p.date,
          null,
          'Asia/Jakarta',
          p.voided ? 'interest:voided' : 'interest',
          accounts[data.extras.interestRules
                  .firstWhere((r) => r.id == p.ruleId)
                  .accountId]
              ?.name,
          null,
          accounts[data.extras.interestRules
                  .firstWhere((r) => r.id == p.ruleId)
                  .accountId]
              ?.currency,
          p.gross.input,
          null,
          '0',
          null,
          null,
          p.idrRate.text,
          'Bunga',
          '${p.start} — ${p.end}',
          null,
          null,
          null,
          p.net.input,
          p.tax.input,
          p.start,
          p.end,
          null,
          null,
          null,
          null,
          null,
        ],
    ]);
  }

  Uint8List holdings(LedgerSnapshot data) => encode([
    [
      'account',
      'instrument',
      'code',
      'units',
      'cost_idr',
      'market_value_idr',
      'realized_idr',
      'available_units',
      'locked_staking_units',
    ],
    for (final h in data.extras.holdings)
      [
        data.accounts.firstWhere((a) => a.id == h.accountId).name,
        h.instrumentId,
        data.extras.instruments.firstWhere((i) => i.id == h.instrumentId).code,
        h.quantity.text,
        h.cost?.input,
        data.extras.holdingValue(h)?.input,
        h.realized?.input,
        h.available.text,
        h.locked.text,
      ],
  ]);
  Uint8List quotes(LedgerSnapshot data) => encode([
    [
      'code',
      'date',
      'price',
      'currency',
      'source',
      'fetched_at',
      'as_of',
      'kind',
      'adjusted_through',
    ],
    for (final q in data.extras.quotes)
      [
        data.extras.instruments.firstWhere((i) => i.id == q.instrumentId).id,
        q.date,
        q.price.text,
        q.currency,
        q.source,
        q.fetchedAt,
        q.asOf,
        q.isLive ? 'live' : 'close',
        q.adjustedThrough,
      ],
  ]);
}
