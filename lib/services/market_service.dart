import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/decimal.dart';
import '../models/investment.dart';
import '../models/ledger.dart';

abstract interface class PriceKeyStore {
  Future<String> read();
  Future<void> write(String value);
}

final class MarketHttpException extends FormatException {
  MarketHttpException(this.statusCode, String message) : super(message);
  final int statusCode;
  bool get providerUnavailable => !{400, 404, 422}.contains(statusCode);
}

final class AndroidPriceKeyStore implements PriceKeyStore {
  static const channel = MethodChannel('id.arta.arta/security');
  @override
  Future<String> read() async =>
      await channel.invokeMethod<String>('getPriceKey') ?? '';
  @override
  Future<void> write(String value) async {
    await channel.invokeMethod<bool>('setPriceKey', {'value': value});
  }
}

final class MarketService {
  MarketService({http.Client? client, DateTime Function()? clock})
    : client = client ?? http.Client(),
      clock = clock ?? DateTime.now;
  final http.Client client;
  final DateTime Function() clock;
  final Map<String, DateTime> _next = {};
  Future<Object?> _get(Uri uri, {Map<String, String>? headers}) async {
    final host = uri.host;
    final now = clock().toUtc();
    if (_next[host]?.isAfter(now) == true) {
      throw const FormatException(
        'Sumber harga sedang jeda. Coba beberapa saat lagi; cache tetap tersedia.',
      );
    }
    final response = await client
        .get(
          uri,
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'ArtaPersonal/0.6',
            ...?headers,
          },
        )
        .timeout(const Duration(seconds: 18));
    if (response.statusCode == 429) {
      final seconds =
          int.tryParse(response.headers['retry-after'] ?? '') ?? 300;
      _next[host] = now.add(Duration(seconds: seconds.clamp(60, 3600)));
      throw MarketHttpException(
        429,
        'Batas sumber harga tercapai (429). Coba lagi nanti.',
      );
    }
    if (response.statusCode != 200) {
      throw MarketHttpException(
        response.statusCode,
        'Sumber harga gagal (${response.statusCode}). Gunakan harga manual/CSV.',
      );
    }
    if (response.bodyBytes.length > 2 * 1024 * 1024) {
      throw const FormatException('Respons harga terlalu besar.');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<PriceQuote> yahoo(Instrument instrument, {bool live = false}) async {
    final symbol = instrument.priceSymbol;
    if (!RegExp(r'^[A-Z]{4}\.JK$').hasMatch(symbol)) {
      throw const FormatException('Simbol harga saham harus KODE.JK.');
    }
    final json = await _get(
      Uri.https('query1.finance.yahoo.com', '/v8/finance/chart/$symbol', {
        'range': '1mo',
        'interval': '1d',
      }),
    );
    if (live) return parseYahooLatest(objectMap(json), instrument, clock());
    return parseYahoo(objectMap(json), instrument, clock());
  }

  Future<List<PriceQuote>> yahooCloses(Instrument instrument) async {
    if (!RegExp(r'^[A-Z]{4}\.JK$').hasMatch(instrument.priceSymbol)) {
      throw const FormatException('Simbol harga saham harus KODE.JK.');
    }
    final data = await _get(
      Uri.https(
        'query1.finance.yahoo.com',
        '/v8/finance/chart/${instrument.priceSymbol}',
        {'range': '1mo', 'interval': '1d'},
      ),
    );
    return parseYahooCloses(objectMap(data), instrument, clock());
  }

  static final ihsgInstrument = Instrument(
    id: 'benchmark:ihsg',
    code: 'IHSG',
    name: 'IDX Composite',
    kind: InstrumentKind.stock,
    providerId: '^JKSE',
  );
  Future<List<PriceQuote>> ihsgCloses({DateTime? since}) async {
    final params = <String, String>{'interval': '1d'};
    if (since == null) {
      params['range'] = '1mo';
    } else {
      params['period1'] = (since.toUtc().millisecondsSinceEpoch ~/ 1000)
          .toString();
      params['period2'] = (clock().toUtc().millisecondsSinceEpoch ~/ 1000)
          .toString();
    }
    final data = await _get(
      Uri.https('query1.finance.yahoo.com', '/v8/finance/chart/^JKSE', params),
    );
    return parseYahooCloses(objectMap(data), ihsgInstrument, clock());
  }

  static PriceQuote parseYahooLatest(
    Map<String, Object?> json,
    Instrument i,
    DateTime now,
  ) {
    final result = objectMap(json['chart'])['result'] as List<Object?>;
    final meta = objectMap(objectMap(result.first)['meta']);
    final stamp = meta['regularMarketTime'];
    final price = Decimal.api(meta['regularMarketPrice']);
    if (meta['symbol'] != i.priceSymbol ||
        meta['currency'] != i.currency ||
        stamp is! num ||
        !price.positive) {
      throw const FormatException('Harga terbaru Yahoo tidak valid.');
    }
    final at = DateTime.fromMillisecondsSinceEpoch(
      stamp.toInt() * 1000,
      isUtc: true,
    );
    if (at.isAfter(now.toUtc().add(const Duration(minutes: 5)))) {
      throw const FormatException('Timestamp harga tidak valid.');
    }
    return PriceQuote(
      instrumentId: i.id,
      price: price,
      currency: i.currency,
      date: localDate(at.add(const Duration(hours: 7))),
      fetchedAt: now.toUtc().toIso8601String(),
      source: 'Yahoo · terbaru (dapat tertunda)',
      asOf: at.toIso8601String(),
      isLive: true,
    );
  }

  Future<List<PriceQuote>> cryptoCloses(
    Instrument i,
    String key, {
    int days = 7,
  }) async {
    if (!RegExp(r'^[a-z0-9-]+$').hasMatch(i.priceSymbol)) {
      throw const FormatException('ID CoinGecko tidak valid.');
    }
    final data = await _get(
      Uri.https(
        'api.coingecko.com',
        '/api/v3/coins/${i.priceSymbol}/market_chart',
        {
          'vs_currency': i.currency.toLowerCase(),
          'days': days.clamp(2, 365).toString(),
          'interval': 'daily',
        },
      ),
      headers: key.isEmpty ? null : {'x-cg-demo-api-key': key},
    );
    return parseCryptoCloses(objectMap(data), i, clock());
  }

  static List<PriceQuote> parseCryptoCloses(
    Map<String, Object?> data,
    Instrument i,
    DateTime now,
  ) {
    final rows = data['prices'];
    if (rows is! List<Object?> || rows.length > 1000) {
      throw const FormatException('Data harian crypto tidak valid.');
    }
    final quotes = <String, PriceQuote>{};
    for (final raw in rows) {
      if (raw is! List<Object?> ||
          raw.length < 2 ||
          raw[0] is! num ||
          raw[1] == null) {
        continue;
      }
      final at = DateTime.fromMillisecondsSinceEpoch(
        (raw[0] as num).toInt(),
        isUtc: true,
      );
      // Only midnight reference observations; discard the trailing live point.
      if (at.hour != 0 ||
          at.minute != 0 ||
          at.second != 0 ||
          at.millisecond != 0 ||
          now.toUtc().isBefore(at.add(const Duration(minutes: 35)))) {
        continue;
      }
      final price = Decimal.api(raw[1]);
      if (!price.positive) continue;
      final date = localDate(at.subtract(const Duration(days: 1)));
      quotes[date] = PriceQuote(
        instrumentId: i.id,
        price: price,
        currency: i.currency,
        date: date,
        fetchedAt: now.toUtc().toIso8601String(),
        source: 'CoinGecko · referensi penutupan UTC',
        asOf: at.toIso8601String(),
      );
    }
    if (quotes.isEmpty) {
      throw const FormatException('Referensi penutupan crypto belum tersedia.');
    }
    return quotes.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  static PriceQuote parseYahoo(
    Map<String, Object?> json,
    Instrument instrument,
    DateTime now,
  ) => parseYahooCloses(json, instrument, now).last;

  static List<PriceQuote> parseYahooCloses(
    Map<String, Object?> json,
    Instrument instrument,
    DateTime now,
  ) {
    final chart = objectMap(json['chart']);
    final result = chart['result'];
    if (result is! List<Object?> || result.isEmpty) {
      throw const FormatException('Yahoo belum menyediakan harga simbol ini.');
    }
    final data = objectMap(result.first),
        meta = objectMap(objectMap(result.first)['meta']);
    if (meta['currency'] != instrument.currency ||
        meta['symbol'] != instrument.priceSymbol) {
      throw const FormatException('Simbol/mata uang harga Yahoo tidak cocok.');
    }
    final stamps = data['timestamp'] as List<Object?>;
    final quote = objectMap(
      (objectMap(data['indicators'])['quote'] as List<Object?>).first,
    );
    final closes = quote['close'] as List<Object?>;
    final today = localDate(now.toUtc().add(const Duration(hours: 7)));
    final period = meta['currentTradingPeriod'];
    int? regularEnd;
    if (period is Map<String, Object?> &&
        period['regular'] is Map<String, Object?>) {
      regularEnd = (objectMap(period['regular'])['end'] as num?)?.toInt();
    }
    final results = <PriceQuote>[];
    for (var n = 0; n < stamps.length; n++) {
      if (n >= closes.length || closes[n] == null || stamps[n] is! num) {
        continue;
      }
      final date = localDate(
        DateTime.fromMillisecondsSinceEpoch(
          (stamps[n] as num).toInt() * 1000,
          isUtc: true,
        ).add(const Duration(hours: 7)),
      );
      if (date.compareTo(today) > 0) continue;
      if (date == today) {
        if (regularEnd == null) continue;
        final end = DateTime.fromMillisecondsSinceEpoch(
          regularEnd * 1000,
          isUtc: true,
        );
        if (localDate(end.add(const Duration(hours: 7))) != date ||
            now.toUtc().isBefore(end.add(const Duration(minutes: 15)))) {
          continue;
        }
      }
      final price = Decimal.api(closes[n]);
      if (!price.positive) continue;
      results.add(
        PriceQuote(
          instrumentId: instrument.id,
          price: price,
          currency: instrument.currency,
          date: date,
          fetchedAt: now.toUtc().toIso8601String(),
          source: 'Yahoo · penutupan',
          adjustedThrough: today,
        ),
      );
    }
    if (results.isEmpty) {
      throw const FormatException('Belum ada harga penutupan sesi selesai.');
    }
    return results..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<List<PriceQuote>> crypto(
    List<Instrument> instruments,
    String key,
  ) async {
    if (instruments.isEmpty) return [];
    if (instruments.length > 200) {
      throw const FormatException('Maksimal 200 koin per pembaruan.');
    }
    final ids = instruments.map((i) => i.priceSymbol).toSet();
    if (ids.any((id) => !RegExp(r'^[a-z0-9-]+$').hasMatch(id))) {
      throw const FormatException('Isi ID CoinGecko, misalnya bitcoin.');
    }
    final json = objectMap(
      await _get(
        Uri.https('api.coingecko.com', '/api/v3/simple/price', {
          'ids': ids.join(','),
          'vs_currencies': instruments
              .map((i) => i.currency.toLowerCase())
              .toSet()
              .join(','),
          'include_last_updated_at': 'true',
        }),
        headers: key.isEmpty ? null : {'x-cg-demo-api-key': key},
      ),
    );
    final quotes = <PriceQuote>[];
    for (final i in instruments) {
      final coin = json[i.priceSymbol];
      if (coin is! Map<String, Object?>) continue;
      final raw = coin[i.currency.toLowerCase()],
          updated = coin['last_updated_at'];
      if (raw == null || updated is! num || updated <= 0) continue;
      final price = Decimal.api(raw);
      if (!price.positive) continue;
      final stamp = DateTime.fromMillisecondsSinceEpoch(
        updated.toInt() * 1000,
        isUtc: true,
      );
      if (stamp.isAfter(clock().toUtc().add(const Duration(minutes: 5)))) {
        continue;
      }
      quotes.add(
        PriceQuote(
          instrumentId: i.id,
          price: price,
          currency: i.currency,
          date: localDate(stamp.add(const Duration(hours: 7))),
          fetchedAt: clock().toUtc().toIso8601String(),
          source: 'CoinGecko',
          asOf: stamp.toIso8601String(),
          isLive: true,
        ),
      );
    }
    if (quotes.isEmpty) {
      throw const FormatException(
        'Harga crypto tidak tersedia; cache dipertahankan.',
      );
    }
    return quotes;
  }

  Future<List<Instrument>> searchCrypto(String query, String key) async {
    if (query.trim().length < 2) {
      throw const FormatException('Isi minimal dua karakter.');
    }
    final data = objectMap(
      await _get(
        Uri.https('api.coingecko.com', '/api/v3/search', {'query': query}),
        headers: key.isEmpty ? null : {'x-cg-demo-api-key': key},
      ),
    );
    return (data['coins'] as List<Object?>).take(30).map((raw) {
      final c = objectMap(raw);
      return Instrument(
        id: 'cg:${c['id']}',
        code: (c['symbol']! as String).toUpperCase(),
        name: c['name']! as String,
        kind: InstrumentKind.crypto,
        providerId: c['id']! as String,
        logo: c['large'] as String? ?? c['thumb'] as String? ?? '',
      );
    }).toList();
  }

  Future<List<Instrument>> searchStocks(String query) async {
    final text = query.trim();
    if (text.length < 2 || text.length > 100) {
      throw const FormatException('Isi 2–100 karakter pencarian.');
    }
    final json = objectMap(
      await _get(
        Uri.https('query1.finance.yahoo.com', '/v1/finance/search', {
          'q': text,
          'quotesCount': '30',
          'newsCount': '0',
        }),
      ),
    );
    final rows = json['quotes'];
    if (rows is! List<Object?>) {
      throw const FormatException('Respons pencarian saham tidak valid.');
    }
    final result = <String, Instrument>{};
    for (final raw in rows) {
      final row = objectMap(raw), symbol = row['symbol'];
      if (row['quoteType'] != 'EQUITY' ||
          symbol is! String ||
          !RegExp(r'^[A-Z]{4}\.JK$').hasMatch(symbol)) {
        continue;
      }
      final code = symbol.substring(0, 4);
      final name = (row['longname'] ?? row['shortname'] ?? code).toString();
      final i = Instrument(
        id: 'idx:$code',
        code: code,
        name: name,
        kind: InstrumentKind.stock,
        providerId: symbol,
        metadata: const {'source': 'Yahoo search'},
      );
      Instrument.fromJson(i.toJson());
      result[i.id] = i;
    }
    return result.values.toList();
  }

  Future<String> sheetCsv(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'docs.google.com' ||
        !uri.path.startsWith('/spreadsheets/')) {
      throw const FormatException(
        'Gunakan URL CSV Google Sheets publik (HTTPS docs.google.com/spreadsheets/...).',
      );
    }
    final response = await client.get(uri).timeout(const Duration(seconds: 18));
    if (response.statusCode != 200 ||
        response.bodyBytes.length > 2 * 1024 * 1024) {
      throw const FormatException(
        'CSV spreadsheet belum bisa dibaca. Periksa URL/akses publik.',
      );
    }
    return utf8.decode(response.bodyBytes);
  }

  void close() => client.close();
}
