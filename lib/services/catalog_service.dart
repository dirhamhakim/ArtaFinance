import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:path/path.dart' as p;

import '../models/ledger.dart';
import '../models/investment.dart';
import '../models/finance_extras.dart';

final class CatalogPreview {
  CatalogPreview(this.sheet, this.rows, this.warnings);
  final String sheet;
  final List<Map<String, Object?>> rows;
  final List<String> warnings;
  Map<String, int> counts(FinanceExtras data) {
    var added = 0, changed = 0, same = 0;
    final existing = {
      for (final i in data.instruments.where(
        (v) => v.kind == InstrumentKind.stock,
      ))
        i.code: i,
    };
    for (final r in rows) {
      final old = existing[r['code']];
      if (old == null) {
        added++;
        continue;
      }
      final merged = mergeStock(old, r);
      if (jsonEncode(merged.toJson()) == jsonEncode(old.toJson())) {
        same++;
      } else {
        changed++;
      }
    }
    return {
      'baru': added,
      'berubah': changed,
      'tetap': same,
      'tidak ditemukan': existing.keys
          .where((k) => !rows.any((r) => r['code'] == k))
          .length,
    };
  }

  FinanceExtras apply(FinanceExtras data, String file, DateTime now) {
    final instruments = [...data.instruments];
    for (final row in rows) {
      final at = instruments.indexWhere(
        (i) => i.kind == InstrumentKind.stock && i.code == row['code'],
      );
      final next = mergeStock(at < 0 ? null : instruments[at], row);
      if (at < 0) {
        instruments.add(next);
      } else {
        instruments[at] = next;
      }
    }
    return data.copy(
      instruments: instruments,
      catalogInfo: {
        'file': file,
        'sheet': sheet,
        'imported_at': now.toUtc().toIso8601String(),
        'source_as_of': null,
      },
    );
  }
}

String normalizeStock(String value) {
  final text = value.trim().toUpperCase().replaceFirst(RegExp(r'\.JK$'), '');
  if (!RegExp(r'^[A-Z]{4}$').hasMatch(text)) {
    throw const FormatException('Kode IDX harus empat huruf.');
  }
  return text;
}

String parseListingDate(String text, {bool date1904 = false}) {
  String checked(String value) {
    validateDate(value);
    return value;
  }

  final serial = int.tryParse(text.replaceFirst(RegExp(r'\.0$'), ''));
  if (serial != null) {
    return checked(
      localDate(
        (date1904 ? DateTime.utc(1904) : DateTime.utc(1899, 12, 30)).add(
          Duration(days: serial),
        ),
      ),
    );
  }
  final slash = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$').firstMatch(text);
  if (slash != null) {
    return checked(
      '${slash[3]}-${slash[2]!.padLeft(2, '0')}-${slash[1]!.padLeft(2, '0')}',
    );
  }
  final words = RegExp(r'^(\d{1,2})\s+([A-Za-z]+)\.?\s+(\d{4})$')
      .firstMatch(text);
  if (words != null) {
    const months = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'mei': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'agu': 8,
      'agt': 8,
      'sep': 9,
      'oct': 10,
      'okt': 10,
      'nov': 11,
      'dec': 12,
      'des': 12,
    };
    final name = words[2]!.toLowerCase();
    final month = months[name.length > 3 ? name.substring(0, 3) : name];
    if (month != null) {
      return checked(
        '${words[3]}-${month.toString().padLeft(2, '0')}-${words[1]!.padLeft(2, '0')}',
      );
    }
  }
  validateDate(text);
  return text;
}

String parseSharesCount(String text) {
  if (RegExp(r'^\d{1,3}(?:[.]\d{3})+$').hasMatch(text)) {
    return text.replaceAll('.', '');
  }
  if (RegExp(r'^\d{1,3}(?:[,]\d{3})+$').hasMatch(text)) {
    return text.replaceAll(',', '');
  }
  if (RegExp(r'^\d+\.0$').hasMatch(text)) {
    return text.substring(0, text.length - 2);
  }
  if (!RegExp(r'^\d+$').hasMatch(text)) {
    throw const FormatException('Jumlah lembar saham tidak valid.');
  }
  return text;
}

Instrument mergeStock(Instrument? old, Map<String, Object?> row) {
  final code = row['code']! as String;
  final metadata = <String, Object?>{...?old?.metadata};
  for (final key in row.keys.where(
    (k) => !{'code', 'name', 'yahoo_symbol'}.contains(k),
  )) {
    metadata[key] = row[key];
  }
  return Instrument(
    id: old?.id ?? 'idx:$code',
    code: code,
    name: row['name']! as String,
    kind: InstrumentKind.stock,
    providerId:
        old?.providerId ?? (row['yahoo_symbol'] as String? ?? '$code.JK'),
    metadata: metadata,
    overrides: old?.overrides ?? const {},
    archived: old?.archived ?? false,
  );
}

Future<List<CatalogPreview>> parseCatalogInBackground(
  Uint8List bytes,
  String file,
) => Isolate.run(() => CatalogService().parse(bytes, file));

final class CatalogService {
  static const maxBytes = 10 * 1024 * 1024;
  List<CatalogPreview> parse(Uint8List bytes, String file) {
    if (bytes.length > maxBytes) {
      throw const FormatException('Katalog maksimal 10 MB.');
    }
    try {
      if (p.extension(file).toLowerCase() == '.json') return [_json(bytes)];
      if (p.extension(file).toLowerCase() != '.xlsx') {
        throw const FormatException('Pilih Excel .xlsx atau JSON katalog.');
      }
      return _xlsx(bytes);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('File katalog rusak atau tidak didukung.');
    }
  }

  CatalogPreview _json(Uint8List bytes) {
    final j = objectMap(jsonDecode(utf8.decode(bytes)));
    if (j['schema_version'] != 1 ||
        j['stocks'] is! List<Object?> ||
        j.containsKey('format')) {
      throw const FormatException(
        'Gunakan JSON katalog schema_version 1, bukan backup keuangan.',
      );
    }
    final rows = (j['stocks']! as List<Object?>)
        .map((v) => Map<String, Object?>.from(objectMap(v)))
        .toList();
    return _validate('JSON', rows);
  }

  CatalogPreview _validate(
    String sheet,
    List<Map<String, Object?>> rows, {
    List<String> warnings = const [],
  }) {
    if (rows.isEmpty || rows.length > 10000) {
      throw const FormatException('Jumlah baris katalog harus 1–10.000.');
    }
    final codes = <String>{};
    final issues = <String>[];
    final clean = <Map<String, Object?>>[];
    for (var n = 0; n < rows.length; n++) {
      try {
        final row = Map<String, Object?>.from(rows[n]);
        row['code'] = normalizeStock(stringField(row, 'code'));
        row['name'] = stringField(row, 'name').trim();
        if (!codes.add(row['code']! as String)) {
          throw const FormatException('Kode duplikat setelah normalisasi.');
        }
        final date = row['listing_date'];
        if (date != null) validateDate(date as String);
        mergeStock(null, row);
        Instrument.fromJson(mergeStock(null, row).toJson());
        clean.add(row);
      } on Object catch (e) {
        issues.add(
          'Baris ${rows[n]['source_row'] ?? n + 1}: ${e is FormatException ? e.message : 'nilai kolom tidak valid'}',
        );
      }
    }
    if (issues.isNotEmpty) {
      throw FormatException('Impor dibatalkan. ${issues.take(20).join('\n')}');
    }
    return CatalogPreview(sheet, clean, warnings);
  }

  List<CatalogPreview> _xlsx(Uint8List bytes) {
    final zip = ZipDecoder().decodeBytes(bytes, throwOnError: true);
    if (zip.files.length > 3000 ||
        zip.files.fold<int>(0, (s, f) => s + f.size) > 40 * 1024 * 1024) {
      throw const FormatException('Isi Excel terlalu besar.');
    }
    XmlDocument xml(String path) {
      final f = zip.findFile(path);
      if (f == null || f.size > 20 * 1024 * 1024) {
        throw const FormatException(
          'Struktur Excel tidak lengkap/terlalu besar.',
        );
      }
      final text = utf8.decode(f.content);
      if (text.contains('<!DOCTYPE') || text.contains('<!ENTITY')) {
        throw const FormatException('Deklarasi XML tidak didukung.');
      }
      return XmlDocument.parse(text);
    }

    final strings = <String>[];
    if (zip.findFile('xl/sharedStrings.xml') != null) {
      for (final s in xml('xl/sharedStrings.xml').findAllElements('si')) {
        strings.add(s.findAllElements('t').map((t) => t.innerText).join());
      }
    }
    final relations = {
      for (final r in xml(
        'xl/_rels/workbook.xml.rels',
      ).findAllElements('Relationship'))
        r.getAttribute('Id'): r.getAttribute('Target'),
    };
    final workbook = xml('xl/workbook.xml');
    final date1904 =
        workbook
            .findAllElements('workbookPr')
            .firstOrNull
            ?.getAttribute('date1904') ==
        '1';
    final previews = <CatalogPreview>[];
    for (final sheet in workbook.findAllElements('sheet')) {
      final target =
          relations[sheet.getAttribute(
            'id',
            namespaceUri: 'http://schemas.openxmlformats.org/officeDocument/2006/relationships',
          )];
      if (target == null || target.contains('..')) continue;
      final path = target.startsWith('/') ? target.substring(1) : 'xl/$target';
      final sheetRows = xml(path).findAllElements('row');
      Map<String, int>? headers;
      final rows = <Map<String, Object?>>[];
      final unknown = <String>[];
      for (final r in sheetRows) {
        final cells = <int, (String, bool)>{};
        for (final c in r.findElements('c')) {
          final ref = c.getAttribute('r') ?? '';
          var col = 0;
          for (final rune
              in RegExp(r'^[A-Z]+').stringMatch(ref)?.runes ?? <int>[]) {
            col = col * 26 + rune - 64;
          }
          if (col == 0 || col > 256) continue;
          final raw = c.findElements('v').firstOrNull?.innerText ?? '';
          final type = c.getAttribute('t');
          final text = type == 's'
              ? strings[int.parse(raw)]
              : type == 'inlineStr'
              ? c.findAllElements('t').map((t) => t.innerText).join()
              : raw;
          cells[col] = (text, c.findElements('f').isNotEmpty || type == 'e');
        }
        if (headers == null) {
          final found = <String, int>{};
          for (final entry in cells.entries) {
            final raw = entry.value.$1.trim();
            final normalized = raw.toLowerCase().replaceAll(
              RegExp(r'[^a-z0-9]'),
              '',
            );
            final key = switch (normalized) {
              'kode' || 'kodesaham' || 'code' => 'code',
              'namaperusahaan' || 'nama' || 'name' => 'name',
              'tanggalpencatatan' || 'listingdate' => 'listing_date',
              'saham' || 'jumlahsaham' || 'sharescount' => 'shares_count',
              'papanpencatatan' || 'listingboard' => 'listing_board',
              'no' || 'nomor' => null,
              _ => 'extra:$raw',
            };
            if (key != null && raw.isNotEmpty) {
              if (found.containsKey(key)) {
                throw const FormatException('Judul kolom duplikat.');
              }
              found[key] = entry.key;
            }
          }
          if (found.containsKey('code') && found.containsKey('name')) {
            headers = found;
            unknown.addAll(
              found.keys
                  .where((k) => k.startsWith('extra:'))
                  .map((k) => k.substring(6)),
            );
          }
          continue;
        }
        if (cells.values.every((v) => v.$1.trim().isEmpty)) continue;
        final row = <String, Object?>{
          'source_row': int.tryParse(r.getAttribute('r') ?? ''),
        };
        for (final entry in headers.entries) {
          final cell = cells[entry.value];
          if (cell?.$2 == true) {
            throw FormatException(
              'Baris ${row['source_row']}: formula/error tidak didukung pada ${entry.key}.',
            );
          }
          var text = cell?.$1.trim() ?? '';
          Object? value = text.isEmpty ? null : text;
          if (entry.key == 'listing_date' && text.isNotEmpty) {
            value = parseListingDate(text, date1904: date1904);
          }
          if (entry.key == 'shares_count' && text.isNotEmpty) {
            value = parseSharesCount(text);
          }
          row[entry.key] = value;
        }
        rows.add(row);
      }
      if (headers != null) {
        previews.add(
          _validate(
            sheet.getAttribute('name') ?? 'Sheet',
            rows,
            warnings: [
              if (unknown.isNotEmpty)
                'Kolom tambahan disimpan sebagai metadata: ${unknown.join(', ')}. Tinjau sebelum menerapkan.',
              'Nama dan metadata mengikuti file sumber; periksa nama yang tampak terpotong.',
            ],
          ),
        );
      }
    }
    if (previews.isEmpty) {
      throw const FormatException(
        'Tidak ada sheet dengan kolom Kode dan Nama Perusahaan.',
      );
    }
    return previews;
  }

  Uint8List export(FinanceExtras data) => Uint8List.fromList(
    utf8.encode(
      jsonEncode({
        'schema_version': 1,
        'source': data.catalogInfo,
        'stocks': data.instruments
            .where((i) => i.kind == InstrumentKind.stock)
            .map(
              (i) => {
                'code': i.code,
                'name': i.name,
                'yahoo_symbol': i.providerId,
                ...i.metadata,
              },
            )
            .toList(),
      }),
    ),
  );
}
