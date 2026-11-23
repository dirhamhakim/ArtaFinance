import json, hashlib, re
from pathlib import Path

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[1]
reg = json.loads((BASE/'screen-manifest.json').read_text(encoding='utf-8'))
summary = json.loads((BASE/'coverage-summary.json').read_text(encoding='utf-8'))
qa = json.loads((BASE/'qa-geometry.json').read_text(encoding='utf-8'))
native = ROOT/'design/Arta-0.7.2-Seluruh-Tampilan.figcraft'
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
rows = {}
for item in reg: rows.setdefault(item['route'], {})[item['theme']] = item
lines = ['# Cakupan layar Arta 0.7.2+11', '', 'Snapshot kode pada 22 November 2026. Satu baris adalah satu keadaan desain; bukan jumlah fitur independen. Semua keadaan memiliki pasangan tema gelap dan terang. Dialog sistem merupakan representasi alur.', '', '| Kelompok | Route / state | Judul | Dark ID | Light ID | Sumber Flutter |', '|---|---|---|---:|---:|---|']
for route, pair in rows.items():
    v=pair['Dark']
    lines.append(f"| {v['page']} | `{route}` | {v['title'].replace('|','/')} | {v['id']} | {pair['Light']['id']} | {v['source'].replace('|','/')} |")
(BASE/'CAKUPAN-LAYAR.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
source_inventory=[]
for p in sorted((ROOT/'lib/screens').glob('*.dart')):
    names=re.findall(r'^class ([A-Z]\w*) extends (?:StatefulWidget|StatelessWidget)',p.read_text(encoding='utf-8'),re.M)
    matched=[v['route'] for v in reg if v['theme']=='Dark' and p.name in v['source']]
    source_inventory.append({'file':str(p.relative_to(ROOT)).replace('\\','/'),'public_widgets':names,'mapped_states':matched})
(BASE/'source-inventory.json').write_text(json.dumps(source_inventory,ensure_ascii=False,indent=2),encoding='utf-8')
sources={str(p.relative_to(ROOT)).replace('\\','/'):sha(p) for p in sorted((ROOT/'lib').rglob('*.dart'))}
sources['pubspec.yaml']=sha(ROOT/'pubspec.yaml')
(BASE/'source-fingerprints.json').write_text(json.dumps(sources,indent=2),encoding='utf-8')
readme='''# Arta — seluruh tampilan versi 0.7.2+11

File utama: [Arta-0.7.2-Seluruh-Tampilan.figcraft](../Arta-0.7.2-Seluruh-Tampilan.figcraft).

Dibuat melalui MCP FigCraft sebagai satu dokumen native yang dapat diedit. Berisi 286 keadaan UI dalam dua tema (572 artboard), 13 halaman APP, satu halaman indeks, dan sembilan halaman LIB berisi master ikon/komponen. Jumlah keadaan mencakup variasi form, pemilih, popup, konfirmasi, kosong, error, dan hasil; bukan 286 fitur terpisah.

## Membuka dan menelusuri

1. Buka file `.figcraft`, mulai dari halaman `00 · Panduan & Cakupan 0.7.2`.
2. Buka halaman berawalan `APP` untuk tampilan versi terbaru. Pasangan Dark di kiri dan Light di kanan.
3. Form dan daftar panjang memakai viewport gulir. Bagian yang tidak tampak pada tangkapan pertama tetap ada dalam konten gulir.
4. Jalankan prototype dari salah satu dari 30 titik awal. Indeks memiliki tombol tema dan tautan kelompok layar.
5. Gunakan [CAKUPAN-LAYAR.md](CAKUPAN-LAYAR.md) untuk mencari route, judul, sumber Flutter dan ID artboard.

Halaman LIB adalah pustaka dan contoh lama untuk referensi komponen, bukan tampilan tambahan yang diklaim tersedia di APK. Tampilan APP didokumentasikan berdasarkan kode 0.7.2+11. Ukuran artboard mobile 400 × 900 logical pixels.

## Cakupan

Ringkasan dan analisis; aset/tunai/bank/e-wallet/debit/utang/piutang; transaksi pemasukan, pengeluaran, transfer, biaya kedua sisi dan lampiran; kategori pemasukan/pengeluaran beserta pencarian, pengarsipan dan aktivasi kembali; transaksi berulang, cicilan dan kejadian jadwal; portofolio saham/crypto/reksadana, transaksi investasi dan harga; grafik komposisi/nilai serta perbandingan saham–IHSG; staking manual; bunga/bagi hasil; katalog dan impor IDX; harga penutupan, refresh manual, kurs; pengaturan tema, backup/restore; PIN, biometrik dan pemulihan; kalender, jam 24 jam dan pemilih Android.

Teks, komponen, ikon dan chart APP berupa layer native yang dapat diedit. Warna diikat ke mode tema semantik. Angka, tanggal, harga, nama dan riwayat pada desain adalah contoh statis.

## Batas prototype

Koneksi mencontohkan navigasi dan perubahan keadaan. FigCraft tidak menjalankan SQLite, perhitungan keuangan, penyimpanan input, API harga, pembacaan file, kamera atau sensor sidik jari. Dialog file/foto/biometrik Android adalah representasi, bukan salinan pasti skin Samsung. Pengujian fungsi tersebut tetap dilakukan pada APK. Dokumen ini tidak mengubah kode atau membangun APK baru.

## Font

Menggunakan Bit Sans Regular/Bold seperti aset Flutter. Keduanya dimuat dan tersedia pada sesi MCP saat pembuatan; **font tidak tertanam dalam file native**. Jika editor menyatakan font hilang, gunakan berkas `assets/fonts/bit_sans_regular.otf` dan `assets/fonts/bit_sans_bold.otf` dari proyek. Folder `previews` menyediakan PNG untuk melihat render tanpa ketergantungan font editor.

## Verifikasi

Seluruh 572 artboard diperiksa secara struktural untuk batas layer dan tujuan prototype; laporan `qa-geometry.json` mencatat nol temuan containment dari aturan pemeriksaan dan nol tujuan tidak valid. Ini tidak menggantikan pemeriksaan visual setiap kemungkinan teks/data runtime. Sampel render yang ditinjau mencakup indeks, Ringkasan, analisis, portofolio/IHSG, staking, kategori, transfer beserta biaya, pengaturan, PIN terang dan pemilih waktu gelap. Semua layar belum diuji satu per satu secara interaktif di FigCraft.

Manifest, inventaris sumber, fingerprint sumber dan hasil simpan tersedia di folder ini. File native disimpan melalui MCP; skrip pendukung hanya menyusun command dan membaca hasil untuk audit.
'''
(BASE/'README.md').write_text(readme,encoding='utf-8')
verification={'version':'0.7.2+11','date':'2026-11-22','native_path':str(native),'bytes':native.stat().st_size,'sha256':sha(native),'app_states':len(rows),'app_artboards':len(reg),'app_pages':13,'library_pages':9,'guide_pages':1,'flow_starts':30,'app_interactions':3939,'geometry_findings':qa['geometry_findings'],'invalid_prototype_destinations':qa['invalid_prototype_destinations'],'font_embedded':False,'source_files_fingerprinted':len(sources),'apk_or_production_code_changed':False}
(BASE/'verification.json').write_text(json.dumps(verification,indent=2),encoding='utf-8')
(BASE/'previews').mkdir(exist_ok=True)
preview_routes=['home','assets','portfolio','performance','schedules','staking','interest','catalog','categories','settings']
exports=[{'route':r,'id':rows[r]['Dark']['id'],'path':str(BASE/'previews'/f'{r}-dark.png')} for r in preview_routes]
exports += [{'route':'pin-setup-light','id':30143,'path':str(BASE/'previews'/'pin-setup-light.png')},{'route':'guide','id':35859,'path':str(BASE/'previews'/'guide.png')}]
(BASE/'preview-plan.json').write_text(json.dumps(exports),encoding='utf-8')
print(json.dumps(verification))
print('Unmapped screen files:',[x['file'] for x in source_inventory if x['public_widgets'] and not x['mapped_states']])
