import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:arta/models/decimal.dart';
import 'package:arta/models/finance_extras.dart';
import 'package:arta/models/investment.dart';
import 'package:arta/models/ledger.dart';
import 'package:arta/models/money.dart';
import 'package:arta/services/catalog_service.dart';
import 'package:arta/services/csv_service.dart';
import 'package:arta/services/market_service.dart';

import '../repositories/portfolio_repository_test.dart'
    show stock, bitcoin, event;
import '../fixtures.dart' show account;

Uint8List catalogJson(List<Map<String, Object?>> rows) => Uint8List.fromList(
  utf8.encode(jsonEncode({'schema_version': 1, 'stocks': rows})),
);
Uint8List workbook({bool formula = false, bool unknown = false}) {
  final archive = Archive();
  void add(String path, String content) {
    final bytes = utf8.encode(content);
    archive.add(ArchiveFile(path, bytes.length, bytes));
  }

  add(
    'xl/workbook.xml',
    '<workbook xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="IDX" r:id="rId1"/></sheets></workbook>',
  );
  add(
    'xl/_rels/workbook.xml.rels',
    '<Relationships><Relationship Id="rId1" Target="worksheets/sheet1.xml"/></Relationships>',
  );
  String c(String ref, String text) =>
      '<c r="$ref" t="inlineStr"><is><t>$text</t></is></c>';
  add(
    'xl/worksheets/sheet1.xml',
    '<worksheet><sheetData><row r="1">${c('A1', 'No')}${c('B1', 'Kode')}${c('C1', 'Nama Perusahaan')}${c('D1', 'Tanggal Pencatatan')}${c('E1', 'Saham')}${c('F1', 'Papan Pencatatan')}${unknown ? c('G1', 'Sektor Baru') : ''}</row><row r="2">${c('A2', '1')}${c('B2', 'TRUE')}${c('C2', 'Triniti Dinamik Tbk.')}<c r="D2"><v>45000</v></c><c r="E2">${formula ? '<f>1+1</f>' : ''}<v>1234567890123456</v></c>${c('F2', 'Utama')}${unknown ? c('G2', 'Teknologi') : ''}</row></sheetData></worksheet>',
  );
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

Map<String, Object?> yahooFixture({Object? lastClose = 9100}) {
  final stamps = [
    DateTime.utc(2026, 11, 18, 2).millisecondsSinceEpoch ~/ 1000,
    DateTime.utc(2026, 11, 19, 2).millisecondsSinceEpoch ~/ 1000,
  ];
  return {
    'chart': {
      'result': [
        {
          'meta': {
            'symbol': 'BBCA.JK',
            'currency': 'IDR',
            'currentTradingPeriod': {
              'regular': {
                'end':
                    DateTime.utc(2026, 11, 19, 9).millisecondsSinceEpoch ~/
                    1000,
              },
            },
          },
          'timestamp': stamps,
          'indicators': {
            'quote': [
              {
                'close': [9000, lastClose],
              },
            ],
          },
        },
      ],
      'error': null,
    },
  };
}

void main() {
  test('CSV investasi memisahkan unit, biaya unit dan arus kas bertanda', () {
    final s = LedgerSnapshot(
      accounts: [account('broker', '1000000')],
      transactions: [],
      extras: FinanceExtras(
        instruments: [stock()],
        events: [event('buy', fee: '1000')],
      ),
    );
    final csv = CsvService();
    final rows = csv.parse(utf8.decode(csv.transactions(s)));
    final h = rows.first, row = rows[1];
    expect(row.length, h.length);
    expect(row[h.indexOf('units')], '100');
    expect(row[h.indexOf('destination_amount')], '');
    expect(row[h.indexOf('net_amount')], '-901000');
    expect(
      csv
          .parse(
            utf8.decode(
              csv.encode([
                ['-1+HYPERLINK("x")'],
              ]),
            ),
          )
          .single
          .single,
      startsWith("'"),
    );
  });
  test('desimal eksak 12 digit, notasi API, dan pembulatan sen', () {
    expect((Decimal.parse('0.1') + Decimal.parse('0.2')).text, '0.3');
    expect(
      (Decimal.parse('0.000000000001') * Decimal.parse('1000000000000'))
          .money(),
      Money.input('1'),
    );
    expect(Decimal.api(1e-8).text, '0.00000001');
    expect(Decimal.parse('1.005').money(), Money.input('1,01'));
    expect(Decimal.parse('-1.005').money(), Money.input('-1,01'));
    expect(() => Decimal.parse('0.0000000000001'), throwsFormatException);
  });
  test('seed IDX 944 kode, saham TRUE, jumlah lembar lengkap', () {
    final result = CatalogService()
        .parse(
          File('assets/data/idx_stocks.json').readAsBytesSync(),
          'idx.json',
        )
        .single;
    expect(result.rows.length, 944);
    expect(result.rows.any((r) => r['code'] == 'TRUE'), isTrue);
    final value = result.apply(
      const FinanceExtras(),
      'seed',
      DateTime.utc(2026, 11, 19),
    );
    expect(
      value.instruments.every((i) => i.metadata.containsKey('shares_count')),
      isTrue,
    );
    value.validate([]);
  });
  test('Excel mempertahankan TRUE, tanggal serial dan digit lembar besar', () {
    final preview = CatalogService()
        .parse(workbook(unknown: true), 'daftar.xlsx')
        .single;
    expect(preview.rows.single['code'], 'TRUE');
    expect(preview.rows.single['shares_count'], '1234567890123456');
    expect(preview.rows.single['listing_date'], '2023-03-15');
    expect(preview.rows.single['extra:Sektor Baru'], 'Teknologi');
    expect(preview.rows.single.containsKey('No'), isFalse);
    expect(preview.warnings.length, 2);
  });
  test('tanggal dan lembar teks unduhan IDX Indonesia', () {
    expect(parseListingDate('08 Agt 2021'), '2021-08-08');
    expect(parseListingDate('01 Des 2000'), '2000-12-01');
    expect(parseSharesCount('2.087.100.500'), '2087100500');
    expect(parseSharesCount('1,234,567'), '1234567');
    expect(() => parseListingDate('31 Feb 2026'), throwsFormatException);
  });
  test('formula/error Excel dan duplikasi normalisasi membatalkan impor', () {
    expect(
      () => CatalogService().parse(workbook(formula: true), 'idx.xlsx'),
      throwsFormatException,
    );
    expect(
      () => CatalogService().parse(
        catalogJson([
          {'code': 'BBCA', 'name': 'A'},
          {'code': 'bbca.jk', 'name': 'B'},
        ]),
        'idx.json',
      ),
      throwsFormatException,
    );
  });
  test('merge katalog menjaga ID, mapping, koreksi dan saham absen', () {
    final old = Instrument(
      id: 'custom-id',
      code: 'BBCA',
      name: 'Lama',
      kind: InstrumentKind.stock,
      providerId: 'BBCA.JK',
      metadata: {'shares_count': '123', 'listing_board': 'Utama'},
      overrides: {'name': 'Nama saya'},
    );
    final other = Instrument(
      id: 'idx:BBRI',
      code: 'BBRI',
      name: 'BRI',
      kind: InstrumentKind.stock,
      providerId: 'BBRI.JK',
    );
    final data = FinanceExtras(instruments: [old, other]);
    final preview = CatalogService()
        .parse(
          catalogJson([
            {'code': 'BBCA', 'name': 'Nama sumber baru'},
          ]),
          'idx.json',
        )
        .single;
    expect(preview.counts(data), {
      'baru': 0,
      'berubah': 1,
      'tetap': 0,
      'tidak ditemukan': 1,
    });
    final next = preview.apply(data, 'update.json', DateTime.utc(2026, 11, 19));
    final bbca = next.instruments.first;
    expect(bbca.id, 'custom-id');
    expect(bbca.displayName, 'Nama saya');
    expect(bbca.metadata['shares_count'], '123');
    expect(next.instruments.length, 2);
    expect(preview.counts(next)['tetap'], 1);
    final round = CatalogService()
        .parse(CatalogService().export(next), 'idx.json')
        .single;
    expect(round.rows.length, 2);
  });
  test('katalog menolak nama/kode kosong dan versi tak didukung', () {
    expect(
      () => CatalogService().parse(
        catalogJson([
          {'code': '', 'name': 'A'},
        ]),
        'idx.json',
      ),
      throwsFormatException,
    );
    expect(
      () => CatalogService().parse(
        Uint8List.fromList(utf8.encode('{"schema_version":99,"stocks":[]}')),
        'idx.json',
      ),
      throwsFormatException,
    );
  });
  test('Yahoo menolak sesi berjalan dan memakai close sebelumnya', () {
    final before = MarketService.parseYahoo(
      yahooFixture(),
      stock(),
      DateTime.utc(2026, 11, 19, 8),
    );
    expect(before.date, '2026-11-18');
    expect(before.price.text, '9000');
    final after = MarketService.parseYahoo(
      yahooFixture(),
      stock(),
      DateTime.utc(2026, 11, 19, 9, 16),
    );
    expect(after.date, '2026-11-19');
    final missing = MarketService.parseYahoo(
      yahooFixture(lastClose: null),
      stock(),
      DateTime.utc(2026, 11, 19, 10),
    );
    expect(missing.date, '2026-11-18');
  });
  test('Yahoo akhir pekan memakai sesi tersedia; mata uang salah ditolak', () {
    final q = MarketService.parseYahoo(
      yahooFixture(),
      stock(),
      DateTime.utc(2026, 11, 22, 10),
    );
    expect(q.date, '2026-11-19');
    final j = yahooFixture();
    ((j['chart'] as Map)['result'] as List).first['meta']['currency'] = 'USD';
    expect(
      () => MarketService.parseYahoo(j, stock(), DateTime.utc(2026, 11, 22)),
      throwsFormatException,
    );
  });
  test(
    'CoinGecko menggabung ID, key memakai header, timestamp sumber disimpan',
    () async {
      var calls = 0;
      final now = DateTime.utc(2026, 11, 19, 10);
      final service = MarketService(
        clock: () => now,
        client: MockClient((request) async {
          calls++;
          expect(
            request.url.queryParameters.containsKey('x_cg_demo_api_key'),
            isFalse,
          );
          expect(request.headers['x-cg-demo-api-key'], 'demo-test-key');
          expect(request.url.queryParameters['ids'], 'bitcoin,ethereum');
          return http.Response(
            jsonEncode({
              'bitcoin': {
                'idr': 1500000000,
                'last_updated_at': now.millisecondsSinceEpoch ~/ 1000,
              },
              'ethereum': {
                'idr': 50000000,
                'last_updated_at': now.millisecondsSinceEpoch ~/ 1000,
              },
            }),
            200,
          );
        }),
      );
      addTearDown(service.close);
      final results = await service.crypto([
        bitcoin(),
        Instrument(
          id: 'cg:ethereum',
          code: 'ETH',
          name: 'Ethereum',
          kind: InstrumentKind.crypto,
          providerId: 'ethereum',
        ),
      ], 'demo-test-key');
      expect(calls, 1);
      expect(results.length, 2);
      expect(results.first.asOf, now.toIso8601String());
      expect(results.first.source, 'CoinGecko');
    },
  );
  test('429 menahan request berikutnya; null/nol bukan harga baru', () async {
    var calls = 0;
    final now = DateTime.utc(2026, 11, 19);
    final service = MarketService(
      clock: () => now,
      client: MockClient((_) async {
        calls++;
        return http.Response('{}', 429, headers: {'retry-after': '300'});
      }),
    );
    addTearDown(service.close);
    await expectLater(
      service.crypto([bitcoin()], 'fake'),
      throwsFormatException,
    );
    await expectLater(
      service.crypto([bitcoin()], 'fake'),
      throwsFormatException,
    );
    expect(calls, 1);
    final invalid = MarketService(
      clock: () => now,
      client: MockClient(
        (_) async =>
            http.Response('{"bitcoin":{"idr":0,"last_updated_at":1}}', 200),
      ),
    );
    addTearDown(invalid.close);
    await expectLater(
      invalid.crypto([bitcoin()], 'fake'),
      throwsFormatException,
    );
  });
  test(
    'CSV kutip, baris baru, formula dan nilai negatif aman untuk spreadsheet',
    () {
      final service = CsvService();
      final bytes = service.encode([
        ['name', 'amount'],
        ['=IMPORTXML("x")', '-123'],
        ['a,b\nc', '10'],
      ]);
      final rows = service.parse(utf8.decode(bytes));
      expect(rows[1][0], startsWith("'="));
      expect(rows[1][1], '-123');
      expect(rows[2][0], 'a,b\nc');
    },
  );
  test('CSV harga all-or-nothing, tanggal/duplikat/mata uang diverifikasi', () {
    final csv = CsvService(), now = DateTime.utc(2026, 11, 19);
    final q = csv.prices(
      'code,date,price,currency\nBBCA.JK,2026-11-18,9000,IDR',
      [stock()],
      now,
    );
    expect(q.single.instrumentId, 'idx:BBCA');
    expect(
      () => csv.prices('code,date,price,currency\nBBCA,2026-11-18,9000,USD', [
        stock(),
      ], now),
      throwsFormatException,
    );
    expect(
      () => csv.prices(
        'code,date,price,currency\nBBCA,2026-11-18,9000,IDR\nXXXX,2026-11-18,1,IDR',
        [stock()],
        now,
      ),
      throwsFormatException,
    );
  });
  test('URL spreadsheet terbatas HTTPS Google Sheets', () async {
    final service = MarketService(
      client: MockClient(
        (_) async => http.Response('code,date,price,currency', 200),
      ),
    );
    addTearDown(service.close);
    await expectLater(
      service.sheetCsv('http://localhost/private'),
      throwsFormatException,
    );
    expect(
      await service.sheetCsv(
        'https://docs.google.com/spreadsheets/d/example/export?format=csv',
      ),
      'code,date,price,currency',
    );
  });
}
