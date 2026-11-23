import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:arta/models/investment.dart';
import 'package:arta/services/market_service.dart';

// Explicit opt-in smoke test, outside test/ so routine tests remain offline.
// The environment contains only a private file path, never the credential itself.
void main() {
  test('public market responses pass the production parsers',()async{
    final keyFile=Platform.environment['ARTA_CG_KEY_FILE'];
    if(keyFile==null)fail('Set ARTA_CG_KEY_FILE to the private Demo credential file.');
    final key=File(keyFile!).readAsStringSync().trim();
    final service=MarketService();addTearDown(service.close);
    final stock=Instrument(id:'idx:BBCA',code:'BBCA',name:'Bank Central Asia',kind:InstrumentKind.stock,providerId:'BBCA.JK');
    final btc=Instrument(id:'cg:bitcoin',code:'BTC',name:'Bitcoin',kind:InstrumentKind.crypto,providerId:'bitcoin');
    final eth=Instrument(id:'cg:ethereum',code:'ETH',name:'Ethereum',kind:InstrumentKind.crypto,providerId:'ethereum');
    final close=await service.yahoo(stock),crypto=await service.crypto([btc,eth],key);
    expect(close.price.positive,isTrue);expect(crypto.length,2);expect(crypto.every((q)=>q.price.positive && q.asOf!=null),isTrue);
    final report={'checked_at':DateTime.now().toUtc().toIso8601String(),'passed':true,
      'credential_embedded_or_logged':false,'yahoo':close.toJson(),'coingecko':crypto.map((q)=>q.toJson()).toList()};
    File('build/market-parsers-live-0.4.0.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
  });
}
