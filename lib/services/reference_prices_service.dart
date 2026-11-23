import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';

import '../models/decimal.dart';
import '../models/investment.dart';
import '../models/ledger.dart';

/// Loads referenced instruments separately; immutable reference history never
/// inflates SQLite or financial backups.
final class ReferencePricesService {
  ReferencePricesService({AssetBundle? bundle}) : bundle = bundle ?? rootBundle;
  final AssetBundle bundle;
  Map<String, Object?>? _index;
  final _cache = <String, List<PriceQuote>>{};
  Future<LedgerSnapshot> attach(
    LedgerSnapshot data, {
    Set<String> requested = const {},
  }) async {
    final needed = {
      ...data.extras.events.map((e) => e.instrumentId),
      ...requested,
    };
    if (needed.isEmpty) return data;
    final issues = <String>[];
    final quotes = <PriceQuote>[];
    try {
      _index ??= objectMap(
        jsonDecode(await bundle.loadString('assets/data/history/index.json')),
      );
      final entries = {
        for (final raw in _index!['instruments']! as List<Object?>)
          (objectMap(raw)['id']! as String): objectMap(raw),
      };
      for (final i in data.extras.instruments.where(
        (i) => needed.contains(i.id),
      )) {
        final canonical = i.kind == InstrumentKind.crypto
            ? 'cg:${i.priceSymbol}'
            : i.kind == InstrumentKind.stock
            ? 'idx:${i.code}'
            : i.id;
        final meta = entries[canonical];
        if (meta == null) continue;
        final currency = i.currency;
        if (i.kind == InstrumentKind.stock && currency != 'IDR') continue;
        if (i.kind == InstrumentKind.crypto &&
            !{'IDR', 'USD'}.contains(currency)) {
          continue;
        }
        final key = '${i.id}:$currency:$canonical';
        try {
          if (!_cache.containsKey(key)) {
            final file = stringField(meta, 'file');
            if (!RegExp(r'^[a-zA-Z0-9_\-]+\.json\.Z$').hasMatch(file)) {
              throw const FormatException('Nama aset harga tidak valid.');
            }
            final bytes = await bundle.load('assets/data/history/$file');
            final source = stringField(meta, 'source'),
                prepared = stringField(_index!, 'prepared_at');
            final adjusted = meta['adjusted_through'] as String?;
            final raw = bytes.buffer.asUint8List(
              bytes.offsetInBytes,
              bytes.lengthInBytes,
            );
            _cache[key] = await Isolate.run(
              () => decodeReferencePrices(
                raw,
                i.id,
                currency,
                source,
                prepared,
                adjusted,
              ),
            );
          }
          quotes.addAll(_cache[key]!);
        } catch (_) {
          issues.add(i.code);
        }
      }
      _cache.removeWhere((k, v) => !needed.any((id) => k.startsWith('$id:')));
    } catch (_) {
      issues.add('indeks riwayat bawaan');
    }
    return data.withExtras(
      data.extras.copy(referenceQuotes: quotes, referenceIssues: issues),
    );
  }
}

List<PriceQuote> decodeReferencePrices(
  Uint8List compressed,
  String id,
  String currency,
  String source,
  String prepared,
  String? adjusted,
) {
  final bytes = gzip.decode(compressed);
  if (bytes.length > 4 * 1024 * 1024) {
    throw const FormatException('Aset riwayat terlalu besar.');
  }
  final rows = jsonDecode(utf8.decode(bytes)) as List<Object?>;
  if (rows.length > 50000) {
    throw const FormatException('Riwayat instrumen terlalu panjang.');
  }
  final result = <PriceQuote>[];
  String? previous;
  for (final raw in rows) {
    final row = raw! as List<Object?>;
    final date = row[0]! as String;
    if (previous != null && date.compareTo(previous) <= 0) {
      throw const FormatException('Tanggal referensi tidak berurutan.');
    }
    previous = date;
    final q = PriceQuote(
      instrumentId: id,
      price: Decimal.parse(row[currency == 'USD' ? 2 : 1]! as String),
      currency: currency,
      date: date,
      fetchedAt: prepared,
      source: source,
      adjustedThrough: adjusted,
      isReference: true,
    );
    PriceQuote.fromJson(q.toJson());
    result.add(q);
  }
  return result;
}
