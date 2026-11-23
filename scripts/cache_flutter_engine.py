"""Fetch the official Android engine in resumable ranges after long-download timeouts."""
import base64
import concurrent.futures
import hashlib
import json
import re
import time
import urllib.request
import zipfile
from pathlib import Path

root = Path(__file__).resolve().parent.parent
engine = (root / '.tooling/flutter/bin/cache/engine.stamp').read_text().strip()
if not re.fullmatch(r'[a-f0-9]{40}', engine):
    raise ValueError('Invalid engine revision')
version = '1.0.0-' + engine
artifact = 'arm64_v8a_debug'
name = artifact + '-' + version
base = 'https://storage.googleapis.com/download.flutter.io/io/flutter/' + artifact + '/' + version + '/' + name
url = base + '.jar'
with urllib.request.urlopen(urllib.request.Request(url, method='HEAD'), timeout=30) as response:
    size = int(response.headers['Content-Length'])
    hashes = ','.join(response.headers.get_all('x-goog-hash', []))
    expected_md5 = re.search(r'md5=([^,]+)', hashes).group(1)

work = root / '.tooling/engine-downloads' / engine
destination = root / '.tooling/flutter-maven/io/flutter' / artifact / version
work.mkdir(parents=True, exist_ok=True)
chunk_size = 4 * 1024 * 1024
count = (size + chunk_size - 1) // chunk_size

def fetch(index):
    start = index * chunk_size
    end = min(start + chunk_size, size) - 1
    part = work / f'{index:04}.part'
    if part.exists() and part.stat().st_size == end - start + 1:
        return index
    for attempt in range(4):
        try:
            request = urllib.request.Request(url, headers={
                'Range': f'bytes={start}-{end}', 'Accept-Encoding': 'identity'})
            with urllib.request.urlopen(request, timeout=45) as response:
                if response.status != 206 or response.headers['Content-Range'] != f'bytes {start}-{end}/{size}':
                    raise ValueError('Server returned an unexpected byte range')
                data = response.read(chunk_size + 1)
            if len(data) != end - start + 1:
                raise ValueError('Incomplete range')
            temporary = part.with_suffix('.tmp')
            temporary.write_bytes(data)
            temporary.replace(part)
            return index
        except Exception:
            if attempt == 3:
                raise
            time.sleep(attempt + 1)

print(f'Fetching official engine: {size:,} bytes in {count} ranges', flush=True)
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
    for completed, future in enumerate(concurrent.futures.as_completed(
            [pool.submit(fetch, i) for i in range(count)]), 1):
        future.result()
        if completed % 8 == 0 or completed == count:
            print(f'Ranges complete: {completed}/{count}', flush=True)

assembled = work / (name + '.jar')
md5 = hashlib.md5()
sha256 = hashlib.sha256()
with assembled.open('wb') as output:
    for index in range(count):
        data = (work / f'{index:04}.part').read_bytes()
        output.write(data)
        md5.update(data)
        sha256.update(data)
if base64.b64encode(md5.digest()).decode() != expected_md5:
    raise ValueError('Checksum differs from the official Google Storage header')
with zipfile.ZipFile(assembled) as archive:
    if not archive.namelist():
        raise ValueError('Empty archive')
with urllib.request.urlopen(base + '.pom', timeout=30) as response:
    pom = response.read()
destination.mkdir(parents=True, exist_ok=True)
assembled.replace(destination / (name + '.jar'))
(destination / (name + '.pom')).write_bytes(pom)
(destination / 'download-receipt.json').write_text(json.dumps({
    'source': url, 'bytes': size, 'md5_base64': expected_md5,
    'sha256': sha256.hexdigest(), 'engine': engine}, indent=2), encoding='utf-8')
(root / '.tooling/flutter-maven/.ready').write_text(engine, encoding='ascii')
print('Official engine checksum verified. Local Maven cache ready.', flush=True)
