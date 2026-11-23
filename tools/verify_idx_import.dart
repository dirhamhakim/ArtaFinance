import 'dart:convert';
import 'dart:io';
import 'package:arta/services/catalog_service.dart';
void main(List<String> args) {
  if(args.length!=1)throw ArgumentError('Isi lokasi Excel IDX yang hendak diverifikasi.');
  final excel=CatalogService().parse(File(args.single).readAsBytesSync(),args.single);
  final seed=CatalogService().parse(File('assets/data/idx_stocks.json').readAsBytesSync(),'seed.json').single;
  final expected={for(final row in seed.rows)row['code']:row};
  final sheet=excel.single;
  final differences=<String>[];
  for(final row in sheet.rows) {
    final old=expected[row['code']];
    if(old==null) {differences.add('${row['code']}: tidak ada di seed');continue;}
    for(final key in ['name','listing_date','shares_count','listing_board']) {
      if(row[key]!=old[key])differences.add('${row['code']}.$key');
    }
  }
  final result={'rows':sheet.rows.length,'expected_rows':seed.rows.length,'column_differences':differences,
    'true_preserved':sheet.rows.any((r)=>r['code']=='TRUE'),'warnings':sheet.warnings,
    'passed':differences.isEmpty && sheet.rows.length==seed.rows.length};
  File('build/idx-import-0.4.0.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert(result));
  stdout.writeln(jsonEncode(result));
  if(result['passed']!=true)exitCode=1;
}
