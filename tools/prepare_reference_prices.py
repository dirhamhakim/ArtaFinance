"""Validate user-provided daily closes and make per-instrument offline assets.

Original Downloads files are never modified. Financial transactions and backups
do not contain this immutable reference dataset.
"""
from pathlib import Path
from decimal import Decimal, ROUND_HALF_UP
from datetime import date, datetime, timezone
import argparse
import gzip
import hashlib
import json


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('stocks')
    parser.add_argument('crypto')
    args = parser.parse_args()
    stocks_path, crypto_path = Path(args.stocks), Path(args.crypto)
    stocks = json.loads(stocks_path.read_text(encoding='utf-8-sig'), parse_float=Decimal)
    crypto = json.loads(crypto_path.read_text(encoding='utf-8-sig'), parse_float=Decimal)
    catalog = json.loads(Path('assets/data/idx_stocks.json').read_text(encoding='utf-8-sig'))
    defaults = json.loads(Path('assets/data/crypto_defaults.json').read_text(encoding='utf-8'))
    codes = {row['code'] for row in catalog['stocks']}
    no_data = set(stocks['tidak_ada_data'])
    assert not (set(stocks['saham']) & no_data)
    assert set(stocks['saham']) | no_data == codes
    mapping = {row['code']: row for row in defaults}
    assert not (set(crypto['koin']) - set(mapping)), 'Register new crypto first.'
    output = Path('assets/data/history')
    output.mkdir(parents=True, exist_ok=True)
    manifest = {'version': 1, 'prepared_at': datetime.now(timezone.utc).isoformat(),
                'stocks_source': stocks['sumber'], 'crypto_source': crypto['catatan'],
                'stock_no_data': sorted(no_data), 'instruments': []}
    invalid = []
    rounded = 0
    count = 0
    def price(raw, instrument, day):
        nonlocal rounded
        n = Decimal(str(raw))
        if not n.is_finite() or n <= 0:
            invalid.append({'instrument': instrument, 'date': day})
            return None
        if n.as_tuple().exponent < -12:
            n = n.quantize(Decimal('0.000000000001'), rounding=ROUND_HALF_UP)
            rounded += 1
        return format(n, 'f').rstrip('0').rstrip('.') if '.' in format(n,'f') else format(n,'f')
    def emit(identity, rows, source, adjusted_through):
        nonlocal count
        assert rows and len({r[0] for r in rows}) == len(rows)
        rows.sort(key=lambda r: r[0])
        filename = identity.replace(':', '_') + '.json.Z'
        body = json.dumps(rows, ensure_ascii=False, separators=(',', ':')).encode('utf-8')
        packed = gzip.compress(body, compresslevel=9, mtime=0)
        (output/filename).write_bytes(packed)
        manifest['instruments'].append({'id':identity, 'file':filename, 'source':source,
            'adjusted_through':adjusted_through, 'rows':len(rows), 'first':rows[0][0], 'last':rows[-1][0],
            'sha256':hashlib.sha256(packed).hexdigest()})
        count += len(rows)
    for code, data in stocks['saham'].items():
        rows=[]
        assert data['jumlah_hari'] == len(data['harga_penutupan']), code
        for day, raw in data['harga_penutupan'].items():
            date.fromisoformat(day)
            p = price(raw, code, day)
            if p is not None: rows.append([day, p])
        emit('idx:'+code, rows, 'Referensi pengguna · Yahoo Close disesuaikan split', stocks['dibuat_pada'][:10])
    for code, data in crypto['koin'].items():
        usd, idr = data['harga_penutupan_usd'], data['harga_penutupan_idr']
        assert set(usd) == set(idr), code
        assert data['jumlah_hari'] == len(usd), code
        rows=[]
        for day in usd:
            date.fromisoformat(day)
            a, b = price(idr[day],code,day), price(usd[day],code,day)
            if a is not None and b is not None: rows.append([day,a,b])
        emit(mapping[code]['id'], rows, 'Referensi pengguna · Yahoo crypto UTC / IDR konversi kurs harian', None)
    (output/'index.json').write_text(json.dumps(manifest,ensure_ascii=False,separators=(',',':'))+'\n',encoding='utf-8')
    result = {'stock_instruments':len(stocks['saham']), 'crypto_instruments':len(crypto['koin']),
        'stock_no_data':sorted(no_data), 'missing_default_crypto':sorted(set(mapping)-set(crypto['koin'])),
        'crypto_codes':sorted(crypto['koin']), 'observations':count,
        'invalid_points_skipped':len(invalid), 'invalid_sample':invalid[:20], 'precision_roundings':rounded,
        'compressed_bytes':sum((output/x['file']).stat().st_size for x in manifest['instruments']),
        'input_sha256':{str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in [stocks_path,crypto_path]}}
    Path('build/reference-data-0.5.0.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({k:v for k,v in result.items() if k not in {'stock_no_data','invalid_sample','input_sha256'}},ensure_ascii=False))


if __name__ == '__main__':
    main()
