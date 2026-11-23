import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter/services.dart';

import '../database/app_database.dart';
import '../models/investment.dart';
import '../models/decimal.dart';
import '../models/ledger.dart';

/// Public market reference cache, separate from personal financial backups.
final class BenchmarkRepository {
  BenchmarkRepository(this.database, {AssetBundle? bundle})
    : bundle = bundle ?? rootBundle;
  final AppDatabase database;
  final AssetBundle bundle;
  List<PriceQuote>? _base;
  Future<List<PriceQuote>> load() async {
    if (_base == null) {
      final bytes = await bundle.load('assets/data/ihsg.json.Z');
      final raw = bytes.buffer.asUint8List(
        bytes.offsetInBytes,
        bytes.lengthInBytes,
      );
      final meta = objectMap(
        jsonDecode(await bundle.loadString('assets/data/ihsg_meta.json')),
      );
      final fetched = stringField(meta, 'retrieved_at');
      _base = await Isolate.run(() => decodeIhsg(raw, fetched));
    }
    final dates = {for (final q in _base!) q.date: q};
    for (final row
        in await database
            .customSelect(
              'SELECT date,price,fetched_at FROM market_benchmarks WHERE symbol = ?',
              variables: [const Variable<String>('^JKSE')],
            )
            .get()) {
      final q = PriceQuote(
        instrumentId: 'benchmark:ihsg',
        price: Decimal.parse(row.read<String>('price')),
        currency: 'IDR',
        date: row.read<String>('date'),
        fetchedAt: row.read<String>('fetched_at'),
        source: 'Yahoo · IHSG close',
      );
      dates[q.date] = q;
    }
    return dates.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> save(List<PriceQuote> quotes) async {
    for (final q in quotes) {
      PriceQuote.fromJson(q.toJson());
      if (q.instrumentId != 'benchmark:ihsg' ||
          q.isLive ||
          q.currency != 'IDR') {
        throw const FormatException('Referensi IHSG tidak valid.');
      }
    }
    await database.transaction(() async {
      for (final q in quotes) {
        await database.customStatement(
          'INSERT OR REPLACE INTO market_benchmarks(symbol,date,price,fetched_at) VALUES(?,?,?,?)',
          ['^JKSE', q.date, q.price.text, q.fetchedAt],
        );
      }
    });
  }
}

List<PriceQuote> decodeIhsg(Uint8List bytes, String fetched) {
  final raw = gzip.decode(bytes);
  if (raw.length > 2 * 1024 * 1024) {
    throw const FormatException('Referensi IHSG terlalu besar.');
  }
  final rows = jsonDecode(utf8.decode(raw)) as List<Object?>;
  if (rows.length > 50000) {
    throw const FormatException('Referensi IHSG terlalu panjang.');
  }
  String? previous;
  return rows.map((raw) {
    final row = raw! as List<Object?>;
    final q = PriceQuote(
      instrumentId: 'benchmark:ihsg',
      price: Decimal.parse(row[1]! as String),
      currency: 'IDR',
      date: row[0]! as String,
      fetchedAt: fetched,
      source: 'Yahoo · referensi IHSG',
      isReference: true,
    );
    PriceQuote.fromJson(q.toJson());
    if (previous != null && q.date.compareTo(previous!) <= 0) {
      throw const FormatException('Tanggal IHSG tidak berurutan.');
    }
    previous = q.date;
    return q;
  }).toList();
}
