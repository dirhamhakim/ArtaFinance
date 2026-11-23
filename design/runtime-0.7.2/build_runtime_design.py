"""Generate editable FigCraft command batches from Arta 0.7.2 UI inventory.

The batches are applied by the FigCraft MCP, never by rewriting a native file.
No APK, financial database or phone is accessed by this script.
"""
import json, math, re, zipfile, hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
OUT.mkdir(exist_ok=True)
PAGES = json.loads((OUT/'pages.json').read_text(encoding='utf-8-sig')) if (OUT/'pages.json').exists() else {}
MASTER = json.loads(zipfile.ZipFile(ROOT/'design/Arta-Master-Ikon-Komponen-2026-11-21.figcraft').read('document.json'))
ICONS = {v['name'].split('/',1)[1]:v['id'] for v in MASTER['nodes'].values() if v['type']=='component' and v['name'].startswith('Glyph/')}
BRANDS = {v['name'].split('/',1)[1]:(v['id'],v['width'],v['height']) for v in MASTER['nodes'].values() if v['type']=='component' and v['name'].startswith('Brand/')}
SPECS=[]
def add(page,route,title,items,source,**kw):
    SPECS.append(dict(page=page,route=route,title=title,items=items,source=source,**kw))
def p(t): return ('p',t)
def h(t): return ('h',t)
def f(label,value='',dest=None,helper=None): return ('f',label,value,dest,helper)
def b(t,dest=None,kind='primary'): return ('b',t,dest,kind)
def row(t,sub='',value='',dest=None,icon='document',brand=None): return ('row',t,sub,value,dest,icon,brand)
def chips(labels,selected=0,dests=None):return ('chips',labels,selected,dests)
def switch(t,on=False,dest=None,sub=''):return ('switch',t,on,dest,sub)
def note(t):return ('note',t)
def empty(t,icon='receipt'):return ('empty',t,icon)
def chart(kind='line',title='Perkembangan nilai aset',state='normal'):return ('chart',kind,title,state)
def card(title,items):return ('card',title,items)
def val(label,value,role='Text/Primary'):return ('value',label,value,role)
def confirm(page,route,title,text,action,dest,source):
    add(page,route,title,[p(text),b('Batal','@close','text'),b(action,dest)],source,sheet=True)

# Primary navigation and reporting. Each scope is a real AnalyticsScreen value.
home=[val('Total kekayaan','Rp151.950.000'),p('Nilai aset dikurangi liabilitas'),
 card('Aset / Liabilitas / Total',[('balance',False)]),
 card('Catatan keuanganmu',[note('Semua pencatatan tersedia offline.'),('shortcuts',)]),
 card('Produk investasi',[p('Nilai penutupan tersimpan'),row('Saham Indonesia','Bandingkan dengan IHSG','Rp52.500.000','portfolio-stock','stocks'),row('Crypto','Spot dan staking','Rp68.000.000','portfolio-crypto','crypto'),row('Reksa dana','NAB diisi manual','Rp10.000.000','portfolio-fund','funds')]),
 ('carousel',0),row('Lihat laporan lengkap','Gabungan, investasi, noninvestasi & arus kas','','analysis-combined','portfolio'),row('Saham vs IHSG','Perbandingan kinerja portofolio','','performance','stocks'),row('2 transaksi menunggu','Tinjau jadwal jatuh tempo','','schedules','calendar'),h('Transaksi terbaru'),row('Makan & Minum','21 Nov 2026 · 12:30 · Mandiri','−Rp45.000','transaction-edit','receipt'),row('Gaji','20 Nov 2026 · 08:00 · SeaBank','+Rp10.000.000','transaction-edit','arrow-down')]
add('Ringkasan','home','Ringkasan',home,'home_screen.dart',nav=0)
add('Ringkasan','home-empty','Ringkasan',[val('Total kekayaan','Rp0'),card('Aset / Liabilitas / Total',[('balance',False)]),card('Catatan keuanganmu',[note('Semua pencatatan tersedia offline.'),('shortcuts',)]),b('Tambah aset pertama','asset-bank'),card('Produk investasi',[row('Saham Indonesia','Bandingkan dengan IHSG','Rp0','portfolio-empty','stocks'),row('Crypto','Spot dan staking','Rp0','portfolio-empty','crypto'),row('Reksa dana','NAB diisi manual','Rp0','portfolio-empty','funds')]),empty('Belum ada transaksi. Catatanmu akan tampil di sini.')],'home_screen.dart',nav=0)
add('Ringkasan','home-private','Ringkasan',[val('Total kekayaan','••••••'),card('Aset / Liabilitas / Total',[('balance',True)]),note('Nominal disembunyikan di seluruh aplikasi.'),card('Catatan keuanganmu',[('shortcuts',)]),('carousel',1),row('Lihat laporan lengkap','','','analysis-private','portfolio')],'home_screen.dart',nav=0)
add('Ringkasan','home-slide2','Ringkasan',home[:5]+[('carousel',1)]+home[6:],'home_screen.dart; cashflow_carousel.dart',nav=0)
add('Ringkasan','home-incomplete','Ringkasan',home[:3]+[note('1 aset tanpa kurs · 1 posisi belum dinilai. Total belum lengkap.')]+home[3:],'home_screen.dart',nav=0)
for scope,label,sub in [('combined','Gabungan aset','Saldo aset + investasi · IDR'),('investment','Investasi','Nilai unit investasi · IDR'),('cash','Aset noninvestasi','Saldo aset, termasuk kas RDN/exchange · IDR'),('cashflow','Pemasukan & pengeluaran','Nilai aktual · IDR')]:
    items=[f('Jenis analisis',label,'analysis-scope'),chips(['1B','3B','6B','1T','Semua']),p(sub),chart('cashflow' if scope=='cashflow' else 'line','Arus kas per hari / interval' if scope=='cashflow' else 'Perkembangan nilai aset')]
    if scope!='cashflow':items += [chart('donut','Komposisi saat ini')]
    items += [row('Tentang perhitungan','','','analysis-method','info')]
    add('Ringkasan','analysis-'+scope,'Analisis & grafik',items,'analytics_screen.dart')
add('Ringkasan','analysis-scope','Jenis analisis',[row(x,'','','analysis-'+r,icon='check') for r,x in [('combined','Gabungan aset'),('investment','Investasi'),('cash','Aset noninvestasi'),('cashflow','Pemasukan & pengeluaran')]],'analytics_screen.dart',sheet=True)
add('Ringkasan','analysis-private','Analisis & grafik',[f('Jenis analisis','Gabungan aset','analysis-scope'),chips(['1B','3B','6B','1T','Semua']),card('Perkembangan nilai aset',[p('Nominal dan grafik disembunyikan ••••••')]),card('Komposisi saat ini',[p('Komposisi disembunyikan ••••••')]),b('Tampilkan nominal','analysis-combined','text')],'analytics_screen.dart')
add('Ringkasan','analysis-method','Tentang perhitungan',[p('Investasi mencakup nilai unit saham, crypto, dan reksa dana. Saldo aset mencakup bank, tunai, e-wallet, kantong debit, piutang/utang, serta kas RDN/exchange yang belum dibelanjakan. Kartu yang hanya menaut ke aset tidak dihitung dua kali.'),p('Transfer pokok, beli/jual investasi dan pokok pinjaman bukan arus kas pendapatan/konsumsi. Staking dihitung satu kali. Harga/kurs terakhir pada atau sebelum tanggal digunakan; harga masa depan tidak ditarik mundur.'),p('Saldo awal berlaku sejak pembuatan atau transaksi paling awal. Periode panjang diringkas hingga sekitar 366 titik.')],'analytics_screen.dart')
for state,msg in [('empty','Belum ada data untuk grafik.'),('one','Satu titik tersedia; tambahkan riwayat untuk melihat perubahan.'),('missing','Harga/kurs belum lengkap. Garis diputus pada titik yang belum dinilai.'),('tooltip','21 Nov 2026 · Rp151.950.000')]:
    add('Ringkasan','chart-'+state,'Analisis & grafik',[chart('line','Perkembangan nilai aset',state),note(msg),chart('donut','Komposisi saat ini',state)],'finance_charts.dart; analytics_screen.dart')

# Aset: all seven real AccountKind values. No fabricated edit/archive account UI.
asset_rows=[row('SeaBank','Bank · IDR','Rp12.500.000','asset-detail','bank','seabank'),row('Mandiri','Bank · IDR','Rp2.150.000','asset-detail','bank','mandiri'),row('Jago Syariah','Bank · IDR','Rp1.000.000','asset-detail','bank','jago'),row('Debit Jago','Kartu debit · IDR','Rp500.000','asset-debit-detail','card','jago'),row('DOKU','Dompet digital · IDR','Rp300.000','asset-detail','wallet','doku'),row('Tunai','Tunai · IDR','−Rp50.000','asset-negative','cash'),row('Stockbit RDN','Saldo exchange / sekuritas · IDR','Rp5.000.000','asset-detail','stocks'),row('Utang kartu kredit','Utang / kartu kredit · IDR','−Rp1.200.000','debts','card'),row('Dana belum cair','Piutang / dana belum cair · IDR','Rp750.000','debts','receivable')]
asset_filters=['Semua','Bank','Tunai','Dompet digital','Saldo exchange / sekuritas','Utang / kartu kredit','Piutang / dana belum cair','Kartu debit']
add('Aset','assets','Aset',[card('Aset / Liabilitas / Total',[('balance',False)]),b('Tambah aset','asset-bank'),f('Cari aset',''),chips(asset_filters),*asset_rows],'home_screen.dart',nav=2)
add('Aset','assets-empty','Aset',[card('Aset / Liabilitas / Total',[('balance',False)]),b('Tambah aset','asset-bank'),empty('Belum ada aset yang sesuai.','wallet')],'home_screen.dart',nav=2)
add('Aset','assets-search','Aset',[f('Cari aset','DOKU'),chips(asset_filters),asset_rows[4]],'home_screen.dart',nav=2)
classes=[('bank','Bank'),('cash','Tunai'),('ewallet','Dompet digital'),('exchange','Saldo exchange / sekuritas'),('liability','Utang / kartu kredit'),('receivable','Piutang / dana belum cair'),('debit','Kartu debit')]
for kind,label in classes:
    items=[f('Nama aset',{'bank':'Mandiri','ewallet':'DOKU','debit':'Debit Jago'}.get(kind,label)),f('Kelas aset',label,'asset-classes')]
    if kind in ['bank','ewallet','debit']:items += [row('Pilih bank / e-wallet','Logo penyedia atau ikon Lainnya','','provider-wallet' if kind=='ewallet' else 'provider-bank','bank')]
    items += [f('Mata uang aset','IDR','currencies'),f('Saldo awal (IDR)','−10.000' if kind=='liability' else '0',helper='Saldo minus diperbolehkan. Contoh: -10.000'),p('Saldo awal tidak dihitung sebagai pemasukan. Saldo exchange/sekuritas hanya uang tunai; unit investasi dicatat terpisah pada Portofolio.')]
    if kind=='debit':items += [note('Kartu debit ini mempunyai saldo kantong sendiri. Isi saldo melalui transfer dari bank agar tidak dihitung dua kali.')]
    if kind=='liability':items += [p('Utang awal ditulis minus. Pinjaman masuk: transfer Utang → bank. Bayar pokok: transfer bank → Utang. Bunga dicatat sebagai pengeluaran terpisah.')]
    if kind=='receivable':items += [p('Piutang awal ditulis positif. Memberi pinjaman: bank → Piutang. Diterima kembali: Piutang → bank. Pokok bukan pengeluaran/pemasukan baru.')]
    items += [b('Simpan aset','assets')]
    add('Aset','asset-'+kind,'Tambah aset',items,'account_form.dart')
add('Aset','asset-classes','Kelas aset',[row(label,'','','asset-'+k,'check') for k,label in classes],'account_form.dart; ledger.dart',sheet=True)
for k,title,balance in [('detail','Mandiri','Rp2.150.000'),('debit-detail','Debit Jago','Rp500.000'),('negative','Tunai','−Rp50.000')]:
    add('Aset','asset-'+k,title,[card('Saldo aset',[val('Kartu debit' if k=='debit-detail' else 'Bank' if k=='detail' else 'Tunai',balance),p('Saldo kantong kartu berdiri sendiri. Isi saldo melalui transfer dari bank.' if k=='debit-detail' else 'Saldo awal dan transaksi membentuk saldo aset ini.')]),b('Catat transaksi','expense'),b('Transfer dari aset ini','transfer','secondary'),h('Riwayat transaksi'),row('Makan & Minum','21 Nov 2026 · 12:30','−Rp45.000','transaction-edit','receipt')],'asset_detail_screen.dart')
add('Aset','asset-not-found','Aset',[empty('Aset tidak tersedia.','wallet')],'asset_detail_screen.dart')
for suffix,title,providers in [('bank','Pilih bank',['SeaBank','Mandiri','Jago','BCA','BRI','BNI','Bank lainnya']),('wallet','Pilih e-wallet',['DOKU','DANA','GoPay','OVO','ShopeePay','LinkAja','E-wallet lainnya'])]:
    add('Pemilih','provider-'+suffix,title,[f('Cari bank / e-wallet',''),*[row(x,'','','asset-ewallet' if suffix=='wallet' else 'asset-bank','bank' if suffix=='bank' else 'wallet',x.lower().replace('shopeepay','shopee-pay').replace('seabank','seabank')) for x in providers]],'provider_logo.dart',sheet=True)
add('Pemilih','provider-none','Pilih bank',[f('Cari bank / e-wallet','Tidak ditemukan'),empty('Tidak ada penyedia yang cocok. Pilih Lainnya untuk nama kustom.','search'),row('Bank lainnya','Ikon tetap, nama aset dapat diisi sendiri','','asset-bank','bank')],'provider_logo.dart',sheet=True)
add('Aset','cards','Kartu debit',[note('Kartu terhubung merupakan metode pembayaran. Saldonya mengikuti aset sumber; tidak dihitung dua kali.'),b('Tambah kartu debit','card-new'),row('Jago Syariah · kartu utama','Terhubung ke Jago Syariah · aktif','','card-edit','card','jago')],'cards_screen.dart')
for key,title in [('new','Tambah kartu debit'),('edit','Ubah kartu debit')]:
    add('Aset','card-'+key,title,[f('Nama kartu','Jago Syariah · kartu utama'),f('Rekening / kantong sumber','Jago Syariah','source-assets'),switch('Arsipkan kartu',key=='edit'),b('Simpan kartu','cards')],'cards_screen.dart')
add('Aset','cards-empty','Kartu debit',[b('Tambah kartu debit','card-new'),empty('Belum ada kartu debit terhubung.','card')],'cards_screen.dart')
add('Aset','debts','Utang & piutang',[p('Pokok pinjaman dicatat sebagai transfer, bukan pendapatan/pengeluaran baru.'),b('Tambah aset utang','asset-liability'),b('Tambah aset piutang','asset-receivable','secondary'),card('Utang kartu kredit',[val('Kewajiban','Rp1.200.000'),b('Bayar pokok','debt-pay','secondary'),b('Belanja kartu kredit','debt-spend','secondary')]),card('Dana belum cair',[val('Piutang','Rp750.000'),b('Terima pelunasan','debt-receive','secondary')])],'debts_screen.dart')

# Transaksi form variants, all conditional fee/FX/card/schedule branches.
transactions=[f('Cari transaksi',''),f('Jenis transaksi','Semua','transaction-types'),b('Filter tanggal','calendar','text'),h('21 November 2026'),row('Makan & Minum','12:30 · Mandiri · 1 lampiran struk','−Rp45.000','transaction-edit','receipt'),row('Mandiri → DOKU','09:10 · biaya Rp2.500','Rp100.000','transaction-edit','transfer'),h('20 November 2026'),row('Gaji','08:00 · SeaBank','+Rp10.000.000','transaction-edit','arrow-down')]
add('Transaksi','transactions','Transaksi',transactions,'home_screen.dart',nav=3,fab='expense')
add('Transaksi','transactions-search','Transaksi',[f('Cari transaksi','Makan'),f('Jenis transaksi','Pengeluaran','transaction-types'),b('Filter tanggal','calendar','text'),h('21 November 2026'),transactions[4]],'home_screen.dart',nav=3,fab='expense')
add('Transaksi','transactions-date','Transaksi',[f('Cari transaksi',''),f('Jenis transaksi','Pengeluaran','transaction-types'),b('Hapus filter','transactions','text'),p('Tanggal: 2026-11-21'),transactions[4]],'home_screen.dart',nav=3,fab='expense')
add('Transaksi','transactions-empty','Transaksi',[f('Cari transaksi',''),f('Jenis transaksi','Semua','transaction-types'),empty('Belum ada transaksi yang sesuai.')],'home_screen.dart',nav=3,fab='expense')
add('Transaksi','transactions-no-match','Transaksi',[f('Cari transaksi','Tidak ditemukan'),empty('Tidak ada transaksi yang cocok.','search')],'home_screen.dart',nav=3)

def tx_items(kind='expense',fees='off',fx=False,mode='once',edit=False,card_on=False):
    items=[chips(['Pengeluaran','Pemasukan','Transfer'],['expense','income','transfer'].index(kind),['expense','income','transfer']),f('Total pengeluaran (IDR)' if mode=='installment' else 'Nominal per kejadian (IDR)' if mode=='repeat' else 'Nominal (USD)' if fx else 'Nominal (IDR)','1.200.000' if mode=='installment' else '100.000')]
    if kind!='transfer':items += [f('Kategori pemasukan' if kind=='income' else 'Kategori pengeluaran','Gaji' if kind=='income' else 'Makan & Minum','category-picker-income' if kind=='income' else 'category-picker-expense', 'Kelola kategori di Pengaturan → Kategori.')]
    items += [f('Dari aset' if kind=='transfer' else 'Aset','Bybit ID · USD' if fx else 'Mandiri · IDR','source-assets')]
    if kind=='transfer':items += [f('Ke aset','DOKU · IDR','destination-assets')]
    if card_on:items += [f('Metode pembayaran','Jago Syariah · kartu utama','payment-method')]
    if fx:
        if kind=='transfer':items += [f('Nominal diterima (IDR)','1.600.000')]
        items += [f('Kurs historis IDR per 1 USD','16.000')]
    if kind=='transfer':
        items += [switch('Biaya transaksi',fees!='off','transfer-sender' if fees=='off' else 'transfer')]
        if fees!='off':
            items += [switch('Biaya pengirim',fees in ['sender','both'],'transfer-both'),switch('Biaya penerima',fees in ['receiver','both'],'transfer-both')]
            if fees in ['sender','both']:items += [f('Biaya pengirim (USD)' if fx else 'Biaya pengirim (IDR)','2.500')]
            if fees in ['receiver','both']:items += [f('Biaya penerima (IDR)','1.000')]
    if not edit:items += [f('Berulang / Cicilan',{'once':'Sekali saja','repeat':'Berulang','installment':'Cicilan pengeluaran'}[mode],'entry-modes')]
    items += [f('Mulai' if mode!='once' else 'Tanggal','21 Nov 2026','calendar')]
    if mode!='once':
        items += [f('Nama jadwal','Biaya bank akhir bulan' if mode=='repeat' else 'Cicilan perangkat')]
        if mode=='repeat':items += [f('Frekuensi','Setiap Akhir Bulan','frequency')]
        else:items += [f('Interval periode','1')]
        items += [switch('Hari terakhir setiap bulan',mode=='repeat'),f('Jumlah cicilan (bagian)' if mode=='installment' else 'Jumlah kejadian (opsional)','12' if mode=='installment' else '',helper='Sisa pembulatan masuk bagian terakhir.' if mode=='installment' else 'Kosongkan untuk terus berulang.')]
        if mode=='repeat':items += [f('Tanggal akhir (opsional)','Belum diisi','calendar')]
        items += [f('Zona waktu jadwal','WIB · Asia/Jakarta','zones'),f('Mode pencatatan','Minta konfirmasi','schedule-modes'),note('Saat aplikasi aktif, kejadian jatuh tempo dapat dicatat atau dikonfirmasi. Tidak melakukan debit bank.')]
    items += [f('Jam','12:30 · WIB','clock'),f('Catatan (opsional)','Contoh catatan',helper='Maksimal 1.000 karakter')]
    if mode=='once':items += [row('Lampiran struk','0/3 · Foto dipilih melalui Photo Picker','','receipt-picker','paperclip'),b('Tambah foto','photo-picker','secondary')]
    return items

for route,kind,fees,fx,mode in [('expense','expense','off',False,'once'),('income','income','off',False,'once'),('transfer','transfer','off',False,'once'),('transfer-sender','transfer','sender',False,'once'),('transfer-receiver','transfer','receiver',False,'once'),('transfer-both','transfer','both',False,'once'),('transfer-fx','transfer','both',True,'once'),('expense-fx','expense','off',True,'once'),('repeat-expense','expense','off',False,'repeat'),('repeat-income','income','off',False,'repeat'),('repeat-transfer','transfer','both',False,'repeat'),('installment','expense','off',False,'installment')]:
    add('Berulang' if mode!='once' else 'Transaksi',route,'Cicilan pengeluaran' if mode=='installment' else 'Transaksi berulang' if mode=='repeat' else 'Catat transaksi',tx_items(kind,fees,fx,mode),'transaction_form.dart; transfer_fee_field.dart',footer=('Simpan jadwal' if mode!='once' else 'Simpan transaksi','schedules' if mode!='once' else 'transactions'))
add('Transaksi','expense-card','Catat transaksi',tx_items(card_on=True),'transaction_form.dart',footer=('Simpan transaksi','transactions'))
add('Transaksi','transaction-edit','Edit transaksi',tx_items(edit=True)+[note('Jika berasal dari jadwal, edit hanya mengubah transaksi ini; aturan dan kejadian lainnya tetap mengikuti rencana awal.')],'transaction_form.dart',footer=('Simpan perubahan','transactions'),delete='transaction-delete')
add('Transaksi','transaction-error','Catat transaksi',[*tx_items()[:4],('error','Isi kategori. Nominal harus positif.'),*tx_items()[4:]],'transaction_form.dart',footer=('Simpan transaksi','transactions'))
add('Transaksi','transaction-saving','Catat transaksi',tx_items()+[note('Menyimpan… Tombol simpan tidak dapat ditekan ulang.')],'transaction_form.dart',footer=('Menyimpan…',None))
confirm('Transaksi','transaction-delete','Hapus transaksi?','Saldo dihitung ulang. Transaksi dari jadwal tetap ditandai dihapus agar tidak dibuat ulang.','Hapus','transactions','transaction_form.dart')
add('Transaksi','receipt-picker','Lampiran struk',[row('struk-21-nov.jpg','JPEG · dipilih pengguna','','receipt-preview','paperclip'),b('Tambah foto','photo-picker','secondary'),b('Hapus lampiran','expense','text'),p('Maksimal tiga lampiran. Foto disimpan bersama transaksi dan backup.')],'receipt_images_field.dart',sheet=True)
add('Transaksi','receipt-preview','Lampiran struk',[('receipt',),b('Tutup','@close','text')],'receipt_images_field.dart',sheet=True)

# Recurring list, detail, occurrence and confirmation states.
for state,label in [('active','Aktif'),('paused','Dijeda'),('stopped','Dihentikan'),('all','Semua')]:
    add('Berulang','schedules' if state=='active' else 'schedules-'+state,'Transaksi berulang',[f('Cari jadwal',''),chips(['Aktif','Dijeda','Dihentikan','Semua'],['active','paused','stopped','all'].index(state),['schedules','schedules-paused','schedules-stopped','schedules-all']),switch('Cicilan',False,'schedules-installment'),h('Jatuh tempo · 2'),row('Biaya administrasi Mandiri','4 Nov 2026 · Pengeluaran','Rp5.500','occurrence','calendar'),row('Biaya akhir bulan','30 Nov 2026 · Pengeluaran','Rp6.000','schedule-detail','calendar'),h('Aturan jadwal · 2'),row('Biaya akhir bulan',label+' · Setiap akhir bulan','','schedule-'+('detail' if state in ['active','all'] else state),'schedule'),b('Tambah jadwal','schedule-create','secondary')],'schedules_screen.dart')
add('Berulang','schedules-installment','Transaksi berulang',[f('Cari jadwal',''),chips(['Aktif','Dijeda','Dihentikan','Semua']),switch('Cicilan',True),row('Cicilan perangkat','3/12 · Rp1.200.000 total','Rp100.000','schedule-installment','calendar'),b('Tambah jadwal','schedule-create')],'schedules_screen.dart')
add('Berulang','schedules-empty','Transaksi berulang',[f('Cari jadwal',''),chips(['Aktif','Dijeda','Dihentikan','Semua']),empty('Belum ada jadwal yang sesuai.','calendar'),b('Tambah jadwal','schedule-create')],'schedules_screen.dart')
add('Berulang','schedule-create','Tambah jadwal',[row('Transaksi berulang','Pemasukan, pengeluaran, atau transfer berkala','','repeat-expense','schedule'),row('Cicilan pengeluaran','Bagi satu total ke beberapa bulan','','installment','calendar')],'schedules_screen.dart',sheet=True)
for state in ['detail','paused','stopped','installment','completed']:
    inst=state=='installment'; active=state in ['detail','installment'];
    items=[val('Aktif' if active else 'Dijeda' if state=='paused' else 'Selesai' if state=='completed' else 'Dihentikan','Cicilan perangkat' if inst else 'Biaya akhir bulan'),val('Total rencana · 12 bagian' if inst else 'Per kejadian','Rp1.200.000' if inst else 'Rp6.000'),f('Jenis & aset','Pengeluaran · Mandiri'),f('Kategori','Cicilan' if inst else 'Biaya Bank'),f('Pengulangan','Setiap bulan · akhir bulan'),f('Mode','Minta konfirmasi'),p('Zona Asia/Jakarta · mulai 2026-01-31')]
    if active:items += [b('Jeda jadwal','schedule-paused','secondary'),b('Ubah jadwal mendatang','schedule-edit','secondary'),b('Hentikan pengulangan','schedule-stop','text')]
    elif state=='paused':items += [b('Lanjutkan jadwal','schedule-resume')]
    if inst:items += [val('Sisa rencana','Rp900.000'),val('Pengeluaran aktual','Rp300.000')]
    items += [h('Kejadian terdekat'),row('30 Nov 2026 · 11','Menunggu konfirmasi','Rp6.000','occurrence','calendar'),h('Riwayat kejadian'),row('31 Okt 2026 · 10','Tercatat · Rp6.000','','transaction-edit','check'),row('30 Sep 2026 · 9','Dilewati · tidak akan dibuat ulang','','','history'),row('31 Agu 2026 · 8','Transaksi dihapus · tidak akan dibuat ulang','','','trash'),b('Tampilkan riwayat lainnya','schedule-detail','text')]
    add('Berulang','schedule-'+state,'Detail pengulangan',items,'schedules_screen.dart')
add('Berulang','schedule-edit','Ubah jadwal mendatang',tx_items(mode='repeat')+[note('Menyimpan akan menghentikan sisa jadwal lama dan membuat jadwal baru. Riwayat lama tetap tersimpan.')],'transaction_form.dart',footer=('Simpan jadwal','schedules'))
add('Berulang','repeat-weekdays','Transaksi berulang',tx_items(mode='repeat')[:6]+[f('Frekuensi','Setiap Hari Tertentu','frequency'),chips(['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'],0)]+tx_items(mode='repeat')[7:],'transaction_form.dart',footer=('Simpan jadwal','schedules'))
add('Berulang','repeat-yearly','Transaksi berulang',tx_items(mode='repeat')[:6]+[f('Frekuensi','Setiap Tahun','frequency'),note('29 Februari memakai hari terakhir Februari pada tahun nonkabisat; jangkar tahunan tetap dipertahankan.')]+tx_items(mode='repeat')[8:],'transaction_form.dart',footer=('Simpan jadwal','schedules'))
for tr in [False,True]:
    add('Berulang','occurrence-transfer' if tr else 'occurrence','Catat satu kejadian',[h('Biaya akhir bulan' if not tr else 'Isi DOKU'),p('Pengeluaran · jatuh tempo 30 Nov 2026' if not tr else 'Transfer · jatuh tempo 30 Nov 2026'),f('Nominal aktual (IDR)','6.000',helper='Perubahan hanya untuk kejadian ini.'),*([switch('Biaya transaksi',True),switch('Biaya pengirim',True),f('Biaya pengirim aktual (IDR)','2.500'),switch('Biaya penerima',False)] if tr else []),f('Tanggal aktual','21 Nov 2026','calendar'),f('Catatan (opsional)',''),f('Jam','12:30 · WIB','clock'),p('Tanggal jatuh tempo tetap tersimpan. Jika nominal cicilan diubah, bagian lainnya tetap sesuai rencana awal.'),b('Catat transaksi ini','schedule-detail'),b('Lewati sekali','occurrence-skip','secondary')],'occurrence_form.dart')
confirm('Berulang','occurrence-skip','Lewati kejadian ini?','Kejadian ditandai dilewati dan tidak mengubah saldo. Jadwal berikutnya tetap berjalan.','Lewati','schedule-detail','occurrence_form.dart')
confirm('Berulang','schedule-stop','Hentikan jadwal?','Kejadian mendatang dihentikan; transaksi dan riwayat yang sudah tercatat tetap tersimpan.','Hentikan','schedule-stopped','schedules_screen.dart')
add('Berulang','schedule-resume','Lanjutkan jadwal',[p('Pilih cara menangani kejadian yang terlewat selama jadwal dijeda.'),b('Batal','@close','text'),b('Proses semua yang lewat','schedule-detail'),b('Lewati sebelum hari ini','schedule-detail','secondary')],'schedules_screen.dart',sheet=True)

# Portfolio and performance: no fabricated performance percentages from deposits.
portfolio=[card('Total investasi',[val('Nilai penutupan tersimpan','Rp130.500.000'),val('Laba/rugi posisi dengan modal diketahui','+Rp5.200.000','Accent'),chart('line','Nilai investasi'),chips(['1B','3B','6B','1T']),p('Perubahan nilai mencakup setoran dan penarikan. Lihat Saham vs IHSG untuk kinerja saham.')]),row('Komposisi portofolio','','','portfolio-composition','portfolio'),b('Catat investasi','investment-buy'),chips(['Semua','Saham','Crypto','Reksa dana'],0,['portfolio','portfolio-stock','portfolio-crypto','portfolio-fund']),f('Cari kepemilikan',''),row('BBCA','Stockbit RDN · 5.000 unit','Rp52.500.000','holding-expanded','stocks'),row('BTC','Tokocrypto · 0,04 unit','Rp68.000.000','holding-crypto','crypto'),row('Reksa dana pasar uang','Bibit · 8.000 unit','Rp10.000.000','holding-fund','funds'),h('Riwayat investasi'),row('Beli · BBCA','21 Nov 2026 · 10:00','','investment-edit','history'),b('Lihat semua riwayat investasi','investment-history','text')]
add('Investasi','portfolio','Portofolio',portfolio,'portfolio_screen.dart',nav=1,menu='portfolio-actions')
for k,idx in [('stock',1),('crypto',2),('fund',3)]:
    add('Investasi','portfolio-'+k,'Portofolio',portfolio[:3]+[chips(['Semua','Saham','Crypto','Reksa dana'],idx,['portfolio','portfolio-stock','portfolio-crypto','portfolio-fund']),f('Cari kepemilikan','')]+[portfolio[5+idx]]+portfolio[-3:],'portfolio_screen.dart',nav=1,menu='portfolio-actions')
add('Investasi','portfolio-composition','Portofolio',portfolio[:1]+[chart('donut','Komposisi portofolio')]+portfolio[2:],'portfolio_screen.dart',nav=1,menu='portfolio-actions')
add('Investasi','portfolio-empty','Portofolio',[val('Total investasi','Rp0'),chart('line','Nilai investasi','empty'),b('Catat investasi','investment-buy'),chips(['Semua','Saham','Crypto','Reksa dana']),f('Cari kepemilikan',''),empty('Belum ada kepemilikan yang sesuai. Catat pembelian atau unit awal.','portfolio')],'portfolio_screen.dart',nav=1)
add('Investasi','portfolio-private','Portofolio',[val('Total investasi','••••••'),val('Laba/rugi posisi dengan modal diketahui','••••••'),p('Grafik disembunyikan ••••••'),row('Komposisi portofolio','Komposisi disembunyikan ••••••','','portfolio-composition','portfolio'),b('Tampilkan nominal','portfolio','text'),b('Catat investasi','investment-buy')],'portfolio_screen.dart',nav=1)
add('Investasi','portfolio-missing','Portofolio',[val('Total investasi','Belum lengkap'),note('1 posisi tanpa harga/kurs. Total belum lengkap. Sebagian modal belum diketahui; laba/rugi belum lengkap.'),chart('line','Nilai investasi','missing'),row('HYPE','MetaMask · unit tersimpan','Belum dinilai','holding-missing','crypto'),b('Harga / NAB manual','price-crypto')],'portfolio_screen.dart',nav=1)
add('Investasi','portfolio-actions','Kelola investasi',[row('Perbarui harga terbaru','Permintaan manual; tidak mengganti valuasi penutupan','','price-refresh','refresh'),row('Ambil penutupan harian','Yahoo, CoinGecko, IHSG','','daily-refresh','calendar'),row('Katalog instrumen','','','catalog','search'),row('Sumber harga & kurs','','','market','settings'),row('Saham vs IHSG','','','performance','stocks'),row('Staking crypto','','','staking','staking')],'portfolio_screen.dart',sheet=True)
for suffix,code,name,extra in [('expanded','BBCA','Bank Central Asia Tbk',''),('crypto','BTC','Bitcoin','Unit bebas: 0,03 · Staking/unstake: 0,01'),('fund','RDPU','Reksa dana pasar uang','NAB diisi manual'),('missing','HYPE','Hyperliquid','Harga belum tersedia')]:
    add('Investasi','holding-'+suffix,'Portofolio',[card(code,[p(name),p('Stockbit RDN · 5.000 unit' if code=='BBCA' else 'Lokasi unit · jumlah tersimpan'),p(extra) if extra else p('Harga penutupan 2026-11-20 · Yahoo Finance'),val('Modal','Rp47.300.000' if suffix!='missing' else 'Belum diketahui'),val('Laba/rugi belum terealisasi','+Rp5.200.000' if suffix!='missing' else 'Belum diketahui','Accent'),val('Laba/rugi terealisasi','Rp500.000'),p('Harga terbaru manual tersimpan terpisah dari harga penutupan.'),b('Grafik & detail','instrument-detail','secondary'),b('Harga / NAB manual','price-fund' if suffix=='fund' else 'price-stock','text')])],'portfolio_screen.dart')
add('Investasi','investment-history','Seluruh riwayat investasi',[row(x,'21 Nov 2026 · lokasi unit tersimpan','','staking-activity-stake' if 'staking' in x else 'investment-edit','history') for x in ['Beli · BBCA','Jual · BBCA','Dividen / hasil tunai · BBCA','Pindah unit · BTC','Reward staking aktual · SOL','Saldo unit awal · RDPU']],'portfolio_screen.dart')
for suffix in ['normal','empty']:
    add('Investasi','instrument-detail' if suffix=='normal' else 'instrument-history-empty','BBCA · harga',[h('Bank Central Asia Tbk'),p('Simbol Yahoo: BBCA.JK'),chart('line','Riwayat penutupan', 'normal' if suffix=='normal' else 'empty'),b('Input harga / NAB','price-stock'),b('Metadata & mapping harga','instrument-stock','secondary'),h('Riwayat harga'),row('20 Nov 2026','Yahoo Finance · penutupan','IDR 10.500','','stocks') if suffix=='normal' else empty('Belum ada riwayat harga.','stocks')],'portfolio_screen.dart')
investment_labels=[('buy','Beli'),('sell','Jual'),('opening','Saldo unit awal'),('transfer','Pindah unit'),('dividend','Dividen / hasil tunai'),('reward','Reward unit'),('split','Split / reverse split')]
for kind,label in investment_labels:
    items=[p('Transfer dana bank → RDN/exchange dicatat di transaksi Transfer. Di sini catat unit yang sudah dikonfirmasi platform.'),b('BBCA · Bank Central Asia Tbk','catalog-select','secondary'),f('Jenis pencatatan',label,'investment-kinds'),f('Lokasi unit awal' if kind=='opening' else 'Aset kas / lokasi aset','Stockbit RDN','source-assets')]
    if kind=='transfer':items += [f('Lokasi tujuan unit','Triv','destination-assets'),note('Unit membawa modal rata-rata asal; biaya jaringan unit dibebankan dari lokasi asal.')]
    if kind!='dividend':
        if kind!='split':items += [switch('Input dalam lot (1 lot = 100 lembar)',True)]
        items += [f('Faktor split (2 untuk 1:2; 0,5 untuk reverse)' if kind=='split' else 'Jumlah lot','2' if kind=='split' else '50')]
    if kind=='opening':items += [switch('Modal awal tidak diketahui',False,'investment-opening-unknown')]
    if kind in ['buy','sell']:items += [switch('Hitung nominal dari unit × harga',False,'investment-unit-price')]
    if kind in ['buy','sell','dividend','opening']:items += [f('Total modal historis (IDR)' if kind=='opening' else 'Nominal bruto (IDR)','47.300.000')]
    if kind in ['buy','sell','dividend','transfer']:items += [switch('Biaya transaksi',True),f('Biaya transaksi (IDR)','10.000')]
    if kind=='transfer':items += [f('Biaya jaringan dalam unit aset','0')]
    items += [f('Tanggal','21 Nov 2026','calendar'),f('Jam','10:00 · WIB','clock'),f('Catatan',''),note('Saldo unit awal tidak menarik kas. Reward unit bermodal nol. Split mengubah unit tanpa mengubah total modal.'),b('Simpan investasi','portfolio')]
    add('Investasi','investment-'+kind,'Catat investasi',items,'investment_form.dart; investment.dart')
add('Investasi','investment-unit-price','Catat investasi',[*SPECS[[s['route'] for s in SPECS].index('investment-buy')]['items'][:5],switch('Hitung nominal dari unit × harga',True),f('Harga per unit / lembar (IDR)','10.500'),b('Hitung nominal bruto',None,'secondary'),f('Nominal bruto (IDR)','52.500.000'),switch('Biaya transaksi',False),f('Tanggal','21 Nov 2026','calendar'),f('Jam','10:00','clock'),b('Simpan investasi','portfolio')],'investment_form.dart')
add('Investasi','investment-opening-unknown','Catat investasi',[b('BTC · Bitcoin','catalog-select','secondary'),f('Jenis pencatatan','Saldo unit awal','investment-kinds'),f('Lokasi unit awal','MetaMask','source-assets'),f('Unit / lembar','0,04'),switch('Modal awal tidak diketahui',True),note('Laba berbasis modal tidak akan diklaim sampai modal tersedia.'),f('Tanggal','21 Nov 2026','calendar'),f('Jam','10:00','clock'),f('Catatan',''),b('Simpan investasi','portfolio')],'investment_form.dart')
add('Investasi','investment-edit','Edit investasi',[f('Instrumen','BBCA · Bank Central Asia Tbk'),f('Jenis pencatatan','Beli','investment-kinds'),f('Aset kas / lokasi aset','Stockbit RDN','source-assets'),f('Jumlah lot','50'),f('Nominal bruto (IDR)','47.300.000'),switch('Biaya transaksi',True),f('Biaya transaksi (IDR)','10.000'),f('Tanggal','21 Nov 2026','calendar'),f('Jam','10:00','clock'),f('Catatan',''),b('Simpan investasi','portfolio')],'investment_form.dart',delete='investment-delete')
confirm('Investasi','investment-delete','Hapus transaksi investasi?','Seluruh aktivitas investasi dihitung ulang. Penghapusan ditolak bila menyebabkan urutan unit, modal atau staking tidak valid.','Hapus','portfolio','investment_form.dart')
for kind,title,price in [('stock','BBCA','10.500'),('crypto','BTC','1.700.000.000'),('fund','RDPU','1.250,00')]:
    add('Investasi','price-'+kind,'Harga / NAB · '+title,[p('Harga penutupan / NAB manual tidak mengubah unit maupun kas.'),f('Harga per unit / lembar','' if kind=='crypto' else price),f('Tanggal harga','20 Nov 2026','calendar'),b('Simpan harga','instrument-detail')],'investment_form.dart')
perf=[card('Kinerja portofolio saham',[val('Return saham','+7,50%','Accent'),val('IHSG','+4,20%','Purple'),p('Perbandingan pada periode yang sama; dinormalisasi dari awal periode.'),chart('benchmark','Saham vs IHSG'),chips(['1B','3B','6B','1T','Semua'])]),switch('Sertakan dividen neto',False,'performance-dividend','Dividen yang benar-benar diterima; bukan perubahan harga saja.'),row('Cara menghitung perbandingan','','','performance-method','info')]
add('Investasi','performance','Saham vs IHSG',perf,'performance_screen.dart')
add('Investasi','performance-dividend','Saham vs IHSG',perf[:1]+[switch('Sertakan dividen neto',True,'performance')]+perf[2:],'performance_screen.dart')
add('Investasi','performance-incomplete','Saham vs IHSG',[chart('benchmark','Saham vs IHSG','missing'),note('Data belum lengkap. Harga saham, kurs historis dan/atau IHSG diperlukan pada periode pembanding.'),row('Cara menghitung perbandingan','','','performance-method','info')],'performance_screen.dart')
add('Investasi','performance-method','Cara menghitung perbandingan',[p('Return portofolio saham menggunakan TWR; arus dana eksternal dipisahkan dari perubahan kinerja. IHSG dinormalisasi ke awal periode yang sama.'),p('Nilai rupiah portofolio tidak dibandingkan langsung dengan level indeks mentah. Grafik nilai aset tidak sama dengan grafik return.'),p('Dividen neto opsional. Periode atau harga/kurs yang belum lengkap ditandai, bukan dibuat menjadi return nol.')],'performance_screen.dart')

# Staking with actual five activity values and optional controls.
staking_base=[p('Pencatatan staking manual. Pokok tetap masuk portofolio satu kali; APR referensi tidak otomatis menambah reward.'),b('Tambah posisi staking','staking-plan'),card('SOL · Tokocrypto',[p('Validator / produk · jaringan Solana'),val('Unit aktif staking','10 SOL'),val('Menunggu unstake','2 SOL'),val('Perkiraan cair','24 Nov 2026'),b('Catat aktivitas','staking-activity-stake'),b('Edit posisi','staking-plan-edit','secondary')]),h('Riwayat aktivitas'),row('Stake unit','21 Nov 2026 · 10:00','10 SOL','staking-activity-edit','staking'),row('Reward staking aktual','20 Nov 2026 · 10:00','0,01 SOL','staking-activity-reward','staking')]
add('Staking','staking','Staking crypto',staking_base,'staking_screen.dart')
add('Staking','staking-empty','Staking crypto',staking_base[:2]+[empty('Belum ada posisi staking. Tambahkan posisi lalu catat aktivitas aktual.','staking')],'staking_screen.dart')
for edit in [False,True]:
    add('Staking','staking-plan-edit' if edit else 'staking-plan','Posisi staking',[f('Nama posisi / platform','SOL · Tokocrypto'),f('Aset penyimpanan','Tokocrypto','source-assets'),f('Crypto','SOL · Solana','catalog-crypto'),f('Jaringan (opsional)','Solana'),f('Validator / produk (opsional)','Validator utama'),f('APR referensi % (opsional)','5,5'),switch('Arsipkan posisi',False),note('APR hanya referensi. Pokok, reward, biaya dan pencairan dicatat manual.'),b('Simpan posisi','staking')],'staking_screen.dart')
activity=[('stake','Stake unit'),('request','Ajukan unstake'),('unstake','Unstake cair / langsung'),('reward','Reward staking aktual'),('loss','Slashing / biaya unit staking')]
for kind,label in activity:
    items=[h('SOL · Tokocrypto'),p('Tokocrypto · jaringan Solana'),f('Aktivitas',label,'staking-kinds'),f('Jumlah unit SOL','0,01' if kind=='reward' else '2')]
    if kind in ['unstake','loss']:items += [switch('Ambil dari unit menunggu unstake',False,'staking-pending','Nonaktif: unit aktif staking. Aktif: unit dalam proses unstake.')]
    if kind=='reward':items += [switch('Reward langsung di-stake kembali',True,'staking-reward-free','Nonaktif: reward menjadi unit bebas.')]
    if kind=='request':items += [f('Perkiraan cair','24 Nov 2026','calendar'),b('Hapus perkiraan cair',None,'text')]
    items += [switch('Biaya transaksi',False,'staking-fee'),p('Biaya tunai memakai mata uang aset. Biaya token dicatat sebagai slashing/biaya unit staking.'),f('Tanggal','21 Nov 2026','calendar'),f('Jam','10:00','clock'),f('Catatan',''),b('Simpan aktivitas','staking')]
    add('Staking','staking-activity-'+kind,'Catat staking',items,'staking_screen.dart')
add('Staking','staking-pending','Catat staking',[f('Aktivitas','Unstake cair / langsung','staking-kinds'),f('Jumlah unit SOL','2'),switch('Ambil dari unit menunggu unstake',True,'staking-activity-unstake'),switch('Biaya transaksi',False),f('Tanggal','21 Nov 2026','calendar'),f('Jam','10:00','clock'),b('Simpan aktivitas','staking')],'staking_screen.dart')
add('Staking','staking-reward-free','Catat staking',[f('Aktivitas','Reward staking aktual','staking-kinds'),f('Jumlah unit SOL','0,01'),switch('Reward langsung di-stake kembali',False,'staking-activity-reward'),note('Reward menjadi unit bebas, tidak menambah unit terkunci.'),f('Tanggal','21 Nov 2026','calendar'),f('Jam','10:00','clock'),b('Simpan aktivitas','staking')],'staking_screen.dart')
add('Staking','staking-fee','Catat staking',[f('Aktivitas','Stake unit','staking-kinds'),f('Jumlah unit SOL','2'),switch('Biaya transaksi',True),f('Biaya transaksi (USD)','0,2'),f('Kurs historis IDR per 1 USD','16.000'),f('Tanggal','21 Nov 2026','calendar'),f('Jam','10:00','clock'),b('Simpan aktivitas','staking')],'staking_screen.dart')
add('Staking','staking-activity-edit','Edit aktivitas staking',[f('Aktivitas','Stake unit','staking-kinds'),f('Jumlah unit SOL','10'),switch('Biaya transaksi',False),f('Tanggal','21 Nov 2026','calendar'),f('Jam','10:00','clock'),f('Catatan',''),b('Simpan aktivitas','staking')],'staking_screen.dart',delete='staking-delete')
confirm('Staking','staking-delete','Hapus aktivitas staking?','Posisi staking dan seluruh aktivitas dihitung ulang. Urutan unit harus tetap valid.','Hapus','staking','staking_screen.dart')

# Interest rules: daily/monthly, progressive tiers and actual confirmation.
interest=[p('Aturan diisi sendiri; tidak ada tarif bank bawaan. Saldo negatif menghasilkan estimasi bunga nol.'),b('Tambah aturan bunga','interest-rule'),card('Bunga SeaBank',[p('SeaBank · sejak 1 Nov 2026'),p('Kredit harian · Tarif seluruh saldo · basis 365 hari'),p('Pajak 20% · Saldo akhir hari sebelumnya · Konfirmasi'),switch('Aturan aktif',True),p('Untuk mengubah tarif, hentikan aturan ini dan buat aturan baru dengan tanggal berlaku baru.')]),h('Estimasi periode selesai'),row('20 Nov 2026','Estimasi · bruto Rp1.000 · pajak Rp200','Rp800','interest-post','interest'),b('Tampilkan 31 periode berikutnya','interest-more','text'),h('Riwayat aktual'),row('19 Nov 2026','Bruto Rp1.000 · pajak Rp200','Rp800','interest-void','interest'),b('Tampilkan riwayat berikutnya','interest-more','text')]
add('Bunga','interest','Bunga & bagi hasil',interest,'interest_screen.dart')
add('Bunga','interest-empty','Bunga & bagi hasil',interest[:2]+[empty('Atur bunga harian atau bulanan sesuai rekening Anda.','calendar')],'interest_screen.dart')
add('Bunga','interest-more','Bunga & bagi hasil',interest+[row('18 Nov 2026 · dibatalkan','Catatan batal tetap tersimpan','','interest-voided','history')],'interest_screen.dart')
for mode in ['daily','monthly','progressive','automatic']:
    items=[f('Nama aturan','Bunga SeaBank'),f('Aset','SeaBank','source-assets'),f('Mulai berlaku','1 Nov 2026','calendar'),f('Tanggal akhir (opsional)','Belum diisi','calendar'),switch('Kredit setiap akhir bulan',mode=='monthly','interest-rule-monthly','Jika nonaktif: kredit harian. Perhitungan berdasarkan saldo per hari.'),switch('Pakai saldo akhir hari sebelumnya',True),switch('Tier progresif',mode=='progressive','interest-rule-progressive','Aktif: setiap rentang saldo memakai tarifnya. Nonaktif: tarif tier terpilih untuk seluruh saldo.'),f('Basis hari per tahun','365 hari','interest-basis'),note('Tier pertama harus mulai saldo 0. Tarif berupa persen per tahun.'),card('Tier 1',[f('Batas saldo tier 1 (IDR)','0'),f('Tarif tahunan (%)','3,5')])]
    if mode=='progressive':items += [card('Tier 2',[f('Batas saldo tier 2 (IDR)','10.000.000'),f('Tarif tahunan (%)','4')])]
    items += [b('Tambah tingkatan saldo','interest-rule-progressive','secondary'),f('Pajak atas bunga (%)','20'),switch('Catat otomatis saat aplikasi dibuka',mode=='automatic','interest-rule-automatic','Default nonaktif; menganggap estimasi sebagai bunga aktual.'),p('Bruto per periode lalu pajak dibulatkan ke dua desimal. Tidak ada pengambilan tarif atau mutasi bank otomatis.'),b('Simpan aturan bunga','interest')]
    add('Bunga','interest-rule' if mode=='daily' else 'interest-rule-'+mode,'Aturan bunga pengguna',items,'interest_screen.dart')
add('Bunga','interest-post','Konfirmasi bunga aktual',[p('Periode 20 Nov 2026 — 20 Nov 2026. Sesuaikan dengan nilai yang benar-benar dikreditkan bank. Saldo bertambah bruto dikurangi pajak satu kali.'),f('Bunga bruto aktual','1.000'),f('Pajak aktual','200'),f('Tanggal masuk','21 Nov 2026','calendar'),b('Catat bunga aktual','interest')],'interest_screen.dart')
confirm('Bunga','interest-void','Batalkan catatan bunga?','Saldo dikoreksi. Periode tetap ditandai batal agar tidak tercatat otomatis lagi. Riwayat bunga lain tidak diubah.','Batalkan catatan','interest-voided','interest_screen.dart')
add('Bunga','interest-voided','Bunga & bagi hasil',[note('Catatan bunga dibatalkan. Periode tetap ditandai agar tidak dibuat ulang.'),row('20 Nov 2026 · dibatalkan','Tidak menambah saldo','Rp0',None,'history')],'interest_screen.dart')

# Catalog, import/export/search, metadata and market settings.
catalog=[f('Jenis instrumen','Semua','catalog-types'),f('Cari kode / nama',''),b('Impor IDX','idx-file','secondary'),b('Cari crypto online','search-crypto','secondary'),b('Cari saham online','search-stock','secondary'),b('Tambah manual','instrument-stock','secondary'),b('Ekspor IDX JSON','catalog-export','text'),p('944 saham · 10 crypto · katalog tersimpan lokal'),row('BBCA','Bank Central Asia Tbk','','instrument-stock','stocks'),row('BTC','Bitcoin','','instrument-crypto','crypto'),row('SOL','Solana','','instrument-crypto','crypto'),b('Tampilkan 50 berikutnya','catalog-more','text')]
add('Katalog','catalog','Katalog instrumen',catalog,'catalog_screen.dart')
for kind in ['stock','crypto','fund']:
    add('Katalog','catalog-'+kind,'Katalog instrumen',[f('Jenis instrumen',{'stock':'Saham','crypto':'Crypto','fund':'Reksa dana'}[kind],'catalog-types'),f('Cari kode / nama',''),b('Tambah manual','instrument-'+kind,'secondary'),*[row(code,name,'','instrument-'+kind,'stocks' if kind=='stock' else 'crypto' if kind=='crypto' else 'funds') for code,name in ([('BBCA','Bank Central Asia Tbk'),('BBRI','Bank Rakyat Indonesia Tbk')] if kind=='stock' else [('BTC','Bitcoin'),('ETH','Ethereum'),('SOL','Solana'),('HYPE','Hyperliquid'),('USDT','Tether'),('USDC','USD Coin'),('XAUT','Tether Gold'),('PAXG','PAX Gold'),('BNB','BNB'),('XRP','XRP')] if kind=='crypto' else [('RDPU','Reksa dana pasar uang')])]],'catalog_screen.dart')
add('Katalog','catalog-select','Pilih instrumen',[f('Jenis instrumen','Semua','catalog-types'),f('Cari kode / nama',''),row('BBCA','Bank Central Asia Tbk','','investment-buy','stocks'),row('BTC','Bitcoin','','investment-buy','crypto'),row('RDPU','Reksa dana pasar uang','','investment-buy','funds')],'catalog_screen.dart')
add('Katalog','catalog-more','Katalog instrumen',catalog+[row('TLKM','Telkom Indonesia Tbk','','instrument-stock','stocks'),row('UNVR','Unilever Indonesia Tbk','','instrument-stock','stocks')],'catalog_screen.dart')
add('Katalog','catalog-empty','Katalog instrumen',[f('Jenis instrumen','Semua','catalog-types'),f('Cari kode / nama','Tidak ditemukan'),empty('Tidak ada instrumen yang cocok.','search'),b('Tambah manual','instrument-stock','secondary')],'catalog_screen.dart')
for kind,code,name,provider in [('stock','BBCA','Bank Central Asia Tbk','BBCA.JK'),('crypto','BTC','Bitcoin','bitcoin'),('fund','RDPU','Reksa dana pasar uang','')]:
    add('Katalog','instrument-'+kind,'Instrumen',[f('Jenis',{'stock':'Saham','crypto':'Crypto','fund':'Reksa dana'}[kind],'instrument-types'),f('Kode / simbol',code),f('Nama',name),f('Mata uang harga/NAB','IDR','currencies'),f('Simbol Yahoo (contoh BBCA.JK)' if kind=='stock' else 'ID CoinGecko / mapping (opsional)',provider),f('URL logo HTTPS (opsional)',''),switch('Arsipkan dari pilihan transaksi baru',False,'instrument-archived'),switch('Kembali memakai metadata sumber',False,'instrument-source','Koreksi manual tidak ditimpa oleh pembaruan katalog.'),b('Simpan instrumen','catalog')],'catalog_screen.dart')
add('Katalog','instrument-archived','Instrumen',[f('Kode / simbol','BBCA'),f('Nama','Bank Central Asia Tbk'),switch('Arsipkan dari pilihan transaksi baru',True),p('Riwayat dan harga tetap disimpan.'),b('Simpan instrumen','catalog')],'catalog_screen.dart')
add('Katalog','instrument-source','Instrumen',[f('Kode / simbol','BBCA'),f('Nama','Bank Central Asia Tbk'),switch('Kembali memakai metadata sumber',True),note('Koreksi manual dilepas saat disimpan. Metadata sumber katalog digunakan kembali.'),b('Simpan instrumen','catalog')],'catalog_screen.dart')
for typ in ['stock','crypto']:
    add('Katalog','search-'+typ,'Cari saham Indonesia' if typ=='stock' else 'Cari crypto online',[f('Nama / simbol','BBCA' if typ=='stock' else 'Bitcoin'),b('Batal','@close','text'),b('Cari','search-'+typ+'-results')],'catalog_screen.dart',sheet=True)
    add('Katalog','search-'+typ+'-results','Pilih saham Indonesia' if typ=='stock' else 'Pilih ID crypto',[row('Bank Central Asia Tbk (BBCA)\nID: yahoo:BBCA.JK' if typ=='stock' else 'Bitcoin (BTC)\nID: bitcoin','Sumber Yahoo Finance · IDX saja' if typ=='stock' else 'ID unik CoinGecko','','catalog','stocks' if typ=='stock' else 'crypto')],'catalog_screen.dart',sheet=True)
add('Katalog','search-no-results','Hasil pencarian',[empty('Tidak ditemukan.','search'),b('Tutup','@close','text')],'catalog_screen.dart',sheet=True)
add('Katalog','idx-file','Buka file',[('native','Android DocumentsUI / Storage Access Framework'),row('Daftar Saham.xlsx','Downloads · dipilih pengguna','','idx-preview','document'),row('katalog-idx.json','Downloads · JSON','','idx-preview','document'),b('Pilih file','idx-preview')],'data_files_service.dart; catalog_screen.dart',native=True)
add('Katalog','idx-sheets','Pilih sheet katalog',[row('Daftar Saham · 944 baris','','','idx-preview','document'),row('Sheet2 · 5 baris','','','idx-preview','document')],'catalog_screen.dart',sheet=True)
add('Katalog','idx-preview','Pratinjau impor IDX',[p('Daftar Saham.xlsx\nSheet: Daftar Saham'),val('Baris valid','944'),val('Saham baru','2'),val('Metadata diperbarui','3'),p('Kode yang tidak ada pada file tetap disimpan. Koreksi manual dan riwayat investasi dipertahankan. Tanggal impor bukan tanggal efektif IDX.'),note('Semua kolom sumber disimpan: kode, nama, tanggal pencatatan, jumlah saham, papan dan kolom lainnya; No opsional.'),row('BBCA','Bank Central Asia Tbk'),row('BBRI','Bank Rakyat Indonesia Tbk'),b('Batal','@close','text'),b('Terapkan pembaruan','catalog')],'catalog_screen.dart',sheet=True)
add('Katalog','idx-error','Impor IDX gagal',[('error','Struktur file/baris tidak valid atau kode duplikat. Data lama tetap disimpan.'),b('Pilih file lain','idx-file','secondary'),b('Tutup','@close','text')],'catalog_screen.dart; idx_catalog_service.dart',sheet=True)
add('Katalog','catalog-export','Simpan ke…',[('native','Android DocumentsUI — membuat dokumen'),f('Nama file','arta-katalog-idx.json'),b('Simpan','catalog')],'catalog_screen.dart; data_files_service.dart',native=True)
market=[p('Saham: Yahoo Finance KODE.JK, penutupan sesi selesai. Crypto: CoinGecko Demo. Reksa dana: NAB manual. Tidak ada perdagangan atau koneksi aset platform.'),f('CoinGecko Demo API key (opsional)','••••••••••••','market-key-visible', 'Disimpan terenkripsi melalui Android Keystore; terpisah dari backup.'),switch('Simpan penutupan harian otomatis',True,'market-auto-off','Saat aplikasi aktif dan tidak terkunci. Data lengkap tidak diminta ulang pada hari yang sama.'),f('URL CSV Google Sheets publik (opsional)','https://docs.google.com/spreadsheets/…/export?format=csv'),b('Simpan pengaturan harga','market-saved'),b('Ambil harga spreadsheet tersimpan','sheet-fetch','secondary'),p('CSV: code,date,price,currency. Gunakan penutupan biasa dengan tanggal sesi sebenarnya.'),b('Impor harga / NAB CSV','price-csv-file','secondary'),h('Mata uang & kurs valuasi'),p('IDR per satu unit mata uang. Kurs valuasi tidak mengubah kurs historis. USDT tidak otomatis dianggap USD.'),row('USD','IDR 16.000 · 20 Nov 2026','','fx-usd','document'),row('USDT','IDR 16.000 · 20 Nov 2026','','fx-usdt','document'),row('USDC','Belum ada kurs','','fx-usdc','document')]
add('Harga','market','Sumber harga & kurs',market,'market_settings_screen.dart')
add('Harga','market-key-visible','Sumber harga & kurs',[p('Contoh key fiktif; tidak menggunakan rahasia pengguna.'),f('CoinGecko Demo API key (opsional)','CG-demo-contoh-bukan-key-asli','market'),*market[2:]],'market_settings_screen.dart')
add('Harga','market-auto-off','Sumber harga & kurs',market[:2]+[switch('Simpan penutupan harian otomatis',False,'market')]+market[3:],'market_settings_screen.dart')
add('Harga','market-saved','Sumber harga & kurs',[note('Pengaturan harga disimpan. API key tetap berada di Keystore perangkat.')]+market,'market_settings_screen.dart')
for route,title,msg in [('price-refresh','Perbarui harga terbaru','Harga terbaru diminta manual. Valuasi penutupan tidak diubah.'),('daily-refresh','Penutupan harian','Sesi saham/IHSG terakhir yang selesai dan hari crypto UTC yang sudah selesai disimpan.'),('prices-offline','Harga tersimpan','Koneksi tidak tersedia. Cache dan tanggal sumber tetap ditampilkan.'),('prices-quota','Sumber harga dibatasi','Kuota/rate limit sumber tercapai. Permintaan ditunda; cache dan sumber lain tetap tersedia.'),('sheet-fetch','Harga spreadsheet','Membaca URL CSV Google Sheets publik yang tersimpan.'),('prices-symbol-missing','Simbol belum tersedia','Saham tanpa riwayat tidak diberi harga nol. Sumber/simbol lain tetap diproses.')]:
    add('Harga',route,title,[note(msg),row('BBCA','Yahoo Finance · 20 Nov 2026','IDR 10.500',None,'stocks'),row('BTC','CoinGecko · hari UTC 20 Nov 2026','IDR 1,7 miliar',None,'crypto'),row('IHSG','Yahoo ^JKSE · 20 Nov 2026','8.250,00',None,'stocks'),b('Sumber harga & kurs','market','secondary')],'finance_controller.dart; market_service.dart; benchmark_controller.dart')
add('Harga','price-csv-file','Buka CSV',[('native','Android DocumentsUI / SAF'),row('harga-nab.csv','Downloads · CSV','','price-csv-preview','document')],'market_settings_screen.dart; data_files_service.dart',native=True)
add('Harga','price-csv-preview','Pratinjau harga CSV',[p('2 harga valid. Hanya diterapkan setelah konfirmasi.'),row('BBCA','2026-11-20 · IDR','10.500'),row('RDPU','2026-11-20 · IDR','1.250,00'),b('Batal','@close','text'),b('Terapkan','market')],'market_settings_screen.dart',sheet=True)
add('Harga','price-csv-error','CSV tidak dapat diterapkan',[('error','Tanggal, simbol, mata uang, duplikasi atau nominal tidak valid. Impor dibatalkan seluruhnya; harga lama tetap tersimpan.'),b('Pilih file lain','price-csv-file','secondary')],'csv_service.dart; market_settings_screen.dart',sheet=True)
for currency in ['USD','USDT','SGD','EUR','MYR']:
    add('Harga','fx-'+currency.lower(),'Kurs '+currency+' → IDR',[f('IDR per 1 '+currency,'16.000'),f('Tanggal kurs','20 Nov 2026','calendar'),note('Kurs historis transaksi tidak ditulis ulang oleh kurs valuasi.'),b('Simpan kurs','market')],'market_settings_screen.dart')

# Category manager implemented in 0.7.2, distinct from transaction category picker.
cat_names=['Belanja Bulanan','Biaya Bank','Cicilan','Donasi','Hiburan','Internet & Pulsa','Keluarga','Kesehatan','Makan & Minum','Pajak & Administrasi','Pendidikan','Pengeluaran Lainnya','Tempat Tinggal','Transportasi','Langganan']
for typ in ['expense','income']:
    names=cat_names if typ=='expense' else ['Bonus','Bunga','Cashback','Dividen','Freelance','Gaji','Hadiah','Pemasukan Lainnya','Penjualan','Usaha']
    add('Kategori','categories' if typ=='expense' else 'categories-income','Kategori',[chips(['Pengeluaran','Pemasukan'],0 if typ=='expense' else 1,['categories','categories-income']),f('Cari kategori',''),chips(['Arsip','Tambah kategori'],1,['categories-archive','category-add-income' if typ=='income' else 'category-add']),*[row(x,'0 transaksi · 0 jadwal','','category-edit','arrow-up' if typ=='expense' else 'arrow-down') for x in names]],'categories_screen.dart')
    add('Pemilih','category-picker-'+typ,'Kategori pemasukan' if typ=='income' else 'Kategori pengeluaran',[f('Cari atau buat kategori',''),*[row(x,'','','income' if typ=='income' else 'expense','check') for x in names]],'transaction_category_field.dart',sheet=True)
add('Kategori','categories-search','Kategori',[chips(['Pengeluaran','Pemasukan']),f('Cari kategori','Servis'),chips(['Arsip','Tambah kategori'],1,['categories-archive','category-add']),row('Servis kendaraan','Belum dipakai','','category-edit','arrow-up')],'categories_screen.dart')
add('Kategori','categories-no-match','Kategori',[chips(['Pengeluaran','Pemasukan']),f('Cari kategori','Tidak ditemukan'),empty('Tidak ada kategori yang cocok.','search')],'categories_screen.dart')
add('Kategori','categories-archive','Kategori',[chips(['Pengeluaran','Pemasukan']),f('Cari kategori',''),chips(['Arsip','Tambah kategori'],0,['categories','category-add']),row('Servis kendaraan','2 transaksi · 1 jadwal · Diarsipkan','','category-edit','history'),b('Aktifkan kategori','category-reactivate','secondary')],'categories_screen.dart')
add('Kategori','categories-archive-empty','Kategori',[chips(['Pengeluaran','Pemasukan']),chips(['Arsip','Tambah kategori'],0),empty('Belum ada kategori diarsipkan.','document')],'categories_screen.dart')
for route,title,kind in [('category-add','Tambah kategori','Pengeluaran'),('category-add-income','Tambah kategori','Pemasukan'),('category-edit','Ubah kategori','Pengeluaran')]:
    items=[p(kind),f('Nama kategori','Servis kendaraan')]
    if route=='category-edit':items += [p('Nama pada seluruh transaksi dan jadwal kategori ini ikut diperbarui. Nominal dan tanggal tetap sama.'),b('Arsipkan kategori','category-archive','text')]
    items += [b('Batal','@close','text'),b('Simpan','categories-income' if kind=='Pemasukan' else 'categories')]
    add('Kategori',route,title,items,'categories_screen.dart',sheet=True)
add('Kategori','category-duplicate','Tambah kategori',[p('Pengeluaran'),f('Nama kategori','makan & minum'),('error','Nama sudah ada, termasuk di arsip.'),b('Batal','@close','text'),b('Simpan','categories')],'categories_screen.dart',sheet=True)
confirm('Kategori','category-archive','Arsipkan kategori?','“Servis kendaraan” disembunyikan dari pilihan baru. Transaksi lama dan jadwal berulang tetap disimpan dan berjalan; jeda jadwal dari menu transaksi berulang bila diperlukan.','Arsipkan','categories-archive','categories_screen.dart')
confirm('Kategori','category-reactivate','Aktifkan kategori?','“Servis kendaraan” akan tersedia kembali untuk transaksi baru.','Aktifkan','categories','categories_screen.dart')
add('Pemilih','category-custom','Kategori pengeluaran',[f('Cari atau buat kategori','Servis kendaraan'),row('Gunakan "Servis kendaraan"','Kategori muncul kembali setelah transaksi disimpan.','','expense','plus')],'transaction_category_field.dart',sheet=True)

# Settings/backup: real actions, no invented destructive reset menu.
settings=[card('Arta',[p('Keuangan pribadimu, di perangkatmu')]),h('Pencatatan'),card('Kelola keuangan',[row('Kategori','Pemasukan, pengeluaran dan arsip','','categories','document'),row('Transaksi berulang & cicilan','Jadwal dan akhir bulan','','schedules','calendar'),row('Bunga & bagi hasil','Aturan dan pencatatan aktual','','interest','interest'),row('Staking crypto','Stake, unstake dan reward manual','','staking','staking'),row('Utang & piutang','Pinjaman dan dana belum cair','','debts','document'),row('Katalog saham & instrumen','Impor daftar IDX dan pencarian crypto','','catalog','search'),row('Sumber harga & mata uang','Penutupan harian, permintaan manual dan kurs','','market','refresh'),row('Kartu terhubung','Metode pembayaran pada rekening','','cards','card')]),h('Preferensi'),card('Tampilan & keamanan',[f('Tema','Gelap / Terang / Ikuti perangkat','theme-picker'),row('Kunci aplikasi','Sidik jari HP dan PIN Arta · opsional','','security','fingerprint')]),h('Data & cadangan'),card('Backup & restore',[p('JSON untuk memulihkan seluruh data; CSV untuk analisis.'),row('Backup terenkripsi','','','backup-encrypt','lock'),row('Ekspor JSON biasa','','','backup-json-file','export'),row('Pulihkan dari file','','','restore-file','import'),row('Ekspor CSV','','','csv-expanded','export')]),h('Tentang Arta'),p('Versi 0.7.2 · Penyimpanan lokal'),p('Pencatatan keuangan dan investasi offline. Internet digunakan untuk harga dan logo. Cadangkan data sebelum mengganti perangkat.'),b('Sumber & lisensi','licenses','text')]
add('Pengaturan','settings','Pengaturan',settings,'home_screen.dart',nav=4)
add('Pengaturan','theme-picker','Tema',[row('Gelap','','','settings','check'),row('Terang','','','settings','check'),row('Ikuti perangkat','','','settings','check')],'home_screen.dart; finance_select.dart',sheet=True)
add('Pengaturan','csv-expanded','Pengaturan',[h('Data & cadangan'),card('Backup & restore',[row('Ekspor CSV transaksi','','','csv-transactions-file','export'),row('Ekspor CSV kepemilikan','','','csv-holdings-file','export'),row('Ekspor CSV harga','','','csv-prices-file','export')]),p('CSV untuk analisis, bukan pengganti backup lengkap.')],'home_screen.dart',nav=4)
add('Pengaturan','backup-encrypt','Enkripsi backup',[f('Kata sandi','••••••••••••','backup-password-visible'),f('Ulangi kata sandi','••••••••••••','backup-password-visible'),p('Simpan kata sandi sendiri. Tanpa kata sandi backup terenkripsi tidak dapat dipulihkan.'),b('Batal','@close','text'),b('Lanjut','backup-encrypted-file')],'home_screen.dart; password_field.dart',sheet=True)
add('Pengaturan','backup-password-visible','Enkripsi backup',[p('Contoh sandi demonstrasi, bukan sandi pengguna.'),f('Kata sandi','contoh-sandi-demo','backup-encrypt'),f('Ulangi kata sandi','contoh-sandi-demo','backup-encrypt'),b('Batal','@close','text'),b('Lanjut','backup-encrypted-file')],'password_field.dart',sheet=True)
add('Pengaturan','backup-password-error','Enkripsi backup',[f('Kata sandi','••••••'),f('Ulangi kata sandi','••••'),('error','Kata sandi belum memenuhi ketentuan atau konfirmasi tidak sama.'),b('Batal','@close','text'),b('Lanjut','backup-encrypt')],'home_screen.dart',sheet=True)
for route,name,return_route in [('backup-json-file','arta-backup.json','backup-success'),('backup-encrypted-file','arta-backup-encrypted.json','backup-success'),('csv-transactions-file','arta-transaksi.csv','csv-success'),('csv-holdings-file','arta-kepemilikan.csv','csv-success'),('csv-prices-file','arta-harga.csv','csv-success'),('restore-mandatory-file','arta-sebelum-restore.json','restore-progress')]:
    add('Pengaturan',route,'Simpan ke…',[('native','Android DocumentsUI — membuat dokumen'),f('Nama file',name),row('Downloads','Folder contoh'),b('Simpan',return_route),b('Batal','restore-cancelled' if route=='restore-mandatory-file' else 'settings','text')],'backup_files_service.dart; home_screen.dart',native=True)
for route,msg in [('backup-success','Backup berhasil disimpan. Kategori, arsip, lampiran dan seluruh data keuangan tercakup.'),('csv-success','CSV berhasil disimpan untuk analisis.')]:
    add('Pengaturan',route,'Pengaturan',[note(msg),b('Kembali ke Pengaturan','settings')],'home_screen.dart',sheet=True)
add('Pengaturan','restore-file','Buka file',[('native','Android DocumentsUI / SAF'),row('arta-backup.json','Backup JSON','','restore-preview','document'),row('arta-backup-encrypted.json','Backup terenkripsi','','restore-password','lock'),b('Batal','settings','text')],'backup_files_service.dart; home_screen.dart',native=True)
add('Pengaturan','restore-password','Buka backup',[f('Kata sandi','••••••••••••'),b('Batal','@close','text'),b('Lanjut','restore-preview')],'home_screen.dart',sheet=True)
add('Pengaturan','restore-preview','Pulihkan backup?',[p('Isi file akan menggantikan data keuangan saat ini. Kategori yang belum dipakai dan kategori arsip ikut dipulihkan.'),val('Aset','9'),val('Transaksi','203'),val('Jadwal','12'),val('Investasi','46'),p('Simpan cadangan data saat ini sebelum memulihkan. API key dan kunci perangkat tidak diambil dari backup.'),b('Batal','settings','text'),b('Simpan cadangan & pulihkan','restore-mandatory-file')],'home_screen.dart',sheet=True)
for route,title,msg in [('restore-wrong-password','Buka backup','Kata sandi salah atau file backup rusak.'),('restore-invalid','File backup tidak didukung','File JSON rusak, versi belum didukung atau referensi data tidak valid. Data sekarang tetap tersimpan.'),('restore-cancelled','Pemulihan dibatalkan','Penyimpanan cadangan data lama dibatalkan; restore tidak dilanjutkan.')]:
    add('Pengaturan',route,title,[('error',msg),b('Kembali','settings')],'home_screen.dart; backup_service.dart',sheet=True)
add('Pengaturan','restore-progress','Memulihkan data',[('loading',),p('Memvalidasi dan mengganti data secara atomik. Jangan menekan ulang.'),b('Selesai','home')],'home_screen.dart')
add('Pengaturan','licenses','Sumber & lisensi',[h('Arta 0.7.2'),p('Flutter / Dart · SQLite / Drift · paket open source'),p('Font Bit Sans dan Lato disertakan sebagai asset. Ikon SVG proyek serta logo penyedia mengikuti sumber dan lisensinya.'),p('Yahoo Finance, CoinGecko dan metadata IDX merupakan sumber data. Nama/logo bukan klaim kerja sama.'),row('Lisensi paket','Daftar lisensi yang disediakan Flutter','','license-detail','document')],'home_screen.dart; showLicensePage')
add('Pengaturan','license-detail','Lisensi paket',[h('Daftar lisensi'),p('Paket Flutter/Dart yang terpasang, pemberitahuan hak cipta dan teks lisensi. Konten disediakan oleh LicenseRegistry Flutter.')],'showLicensePage',native=False)

# Security and startup. These are visual simulations; no owner authentication.
for enabled in [False,True]:
    add('Keamanan','security-enabled' if enabled else 'security','Kunci aplikasi',[('large-icon','fingerprint'),h('Kunci aplikasi aktif' if enabled else 'Kunci aplikasi opsional'),p('Gunakan sidik jari HP sebagai pilihan utama dan PIN Arta 6 angka sebagai cadangan. PIN Arta terpisah dari PIN layar kunci HP.'),b('Ubah PIN / pilihan sidik jari' if enabled else 'Aktifkan kunci aplikasi','pin-setup'),*([b('Nonaktifkan kunci aplikasi','security-disable','secondary'),b('Kunci sekarang','pin','secondary')] if enabled else []),p('Kunci aktif kembali ketika aplikasi masuk latar belakang, termasuk pemilih foto/file. Data form tetap ada setelah dibuka kembali.'),p('Simpan backup terenkripsi sebelum mengaktifkan kunci. Tidak ada pemulihan online tanpa sidik jari/backup milik Anda.')],'security_screen.dart')
confirm('Keamanan','security-disable','Nonaktifkan kunci aplikasi?','Arta akan langsung terbuka tanpa sidik jari atau PIN.','Nonaktifkan','security','security_screen.dart')
for route,state in [('pin','empty'),('pin-filled','filled'),('pin-visible','visible'),('pin-error','error'),('pin-lockout','lockout'),('pin-biometric-loading','loading'),('pin-no-biometric','unavailable'),('pin-setup','setup'),('pin-confirm','confirm'),('pin-mismatch','mismatch'),('pin-reset','reset')]:
    add('Keamanan',route,'PIN Arta',[('pin',state)],'pin_keypad.dart; app_lock_gate.dart; security_screen.dart',pin=True)
add('Keamanan','biometric-dialog','Verifikasi sidik jari',[('native','Android BiometricPrompt — tampilan mengikuti HP'),('large-icon','fingerprint'),h('Verifikasi untuk membuka Arta'),p('Gunakan sensor sidik jari yang terdaftar pada HP.'),b('Simulasi berhasil','home'),b('Batal','pin','text')],'app_lock_controller.dart',sheet=True,native=True)
add('Keamanan','forgot-pin-unavailable','Lupa PIN',[p('Reset PIN memerlukan sidik jari yang diaktifkan sebelumnya. Data dan PIN tidak dihapus saat verifikasi tidak tersedia.'),b('Tutup','@close','text')],'app_lock_gate.dart',sheet=True)
add('Keamanan','forgot-pin-verify','Reset PIN dengan sidik jari',[p('Verifikasi sidik jari pemilik HP sebelum membuka form PIN baru.'),('large-icon','fingerprint'),b('Simulasi verifikasi berhasil','pin-reset'),b('Batal','pin','text')],'app_lock_gate.dart',sheet=True,native=True)
add('Keamanan','startup-loading','Arta',[('loading',),h('Arta'),p('Membuka penyimpanan lokal…')],'app.dart; arta_logo.dart',startup=True)
add('Keamanan','startup-error','Arta',[('large-icon','warning'),h('Penyimpanan lokal belum dapat dibuka'),p('Periksa rincian lalu coba lagi. Database internal tidak memerlukan izin galeri atau penyimpanan luas.'),b('Coba lagi','startup-loading'),row('Rincian masalah','Versi 0.7.2 · diagnostik lokal','','startup-diagnostic','info')],'app.dart; services/bootstrap_service.dart',startup=True)
add('Keamanan','startup-diagnostic','Rincian masalah',[p('Arta 0.7.2 · Android'),p('Pembukaan direktori/database gagal. Contoh diagnostik tanpa data keuangan atau rahasia pengguna.'),b('Coba lagi','startup-loading')],'app.dart',startup=True)

# Shared pickers are separate states, with every finite option represented.
pickers=[('transaction-types','Jenis transaksi',['Semua','Pengeluaran','Pemasukan','Transfer'],'transactions'),('entry-modes','Berulang / Cicilan',['Sekali saja','Berulang','Cicilan pengeluaran'],['expense','repeat-expense','installment']),('currencies','Mata uang',['IDR','USD','USDT','SGD','EUR','MYR'],'asset-bank'),('zones','Zona waktu jadwal',['WIB · Asia/Jakarta','WITA · Asia/Makassar','WIT · Asia/Jayapura'],'repeat-expense'),('schedule-modes','Mode pencatatan',['Minta konfirmasi','Catat otomatis saat jatuh tempo'],'repeat-expense'),('investment-kinds','Jenis pencatatan',[x[1] for x in investment_labels],['investment-'+x[0] for x in investment_labels]),('staking-kinds','Aktivitas',[x[1] for x in activity],['staking-activity-'+x[0] for x in activity]),('catalog-types','Jenis instrumen',['Semua','Saham','Crypto','Reksa dana'],['catalog','catalog-stock','catalog-crypto','catalog-fund']),('instrument-types','Jenis',['Saham','Crypto','Reksa dana'],['instrument-stock','instrument-crypto','instrument-fund']),('interest-basis','Basis hari per tahun',['360 hari','365 hari','366 hari'],'interest-rule'),('payment-method','Metode pembayaran',['Langsung dari rekening / aset','Jago Syariah · kartu utama'],'expense-card')]
for route,title,options,dest in pickers:
    add('Pemilih',route,title,[row(x,'','',dest[i] if isinstance(dest,list) else dest,'check') for i,x in enumerate(options)],'finance_select.dart; respective screen constructors',sheet=True)
frequency=['Setiap Hari','Setiap Hari Tertentu','Setiap Minggu','Setiap 2 Minggu','Setiap 4 Minggu','Setiap Bulan','Setiap Akhir Bulan','Setiap 2 Bulan','Setiap 3 Bulan','Setiap 4 Bulan','Setiap 6 Bulan','Setiap Tahun']
add('Pemilih','frequency','Frekuensi',[row(x,'','','repeat-weekdays' if i==1 else 'repeat-yearly' if i==11 else 'repeat-expense','check') for i,x in enumerate(frequency)],'recurrence_option.dart; finance_select.dart',sheet=True)
for route,title,dest in [('source-assets','Pilih aset','expense'),('destination-assets','Ke aset','transfer')]:
    add('Pemilih',route,title,[row(x,'Saldo tersedia, minus diperbolehkan','',dest,'wallet') for x in ['Mandiri · IDR','SeaBank · IDR','Jago Syariah · IDR','Debit Jago · IDR','DOKU · IDR','Bybit ID · USD','Tokocrypto · IDR','Stockbit RDN · IDR','Bibit · IDR','MetaMask · USDT','Utang kartu kredit · IDR']],'finance_fields.dart; finance_select.dart',sheet=True)
add('Pemilih','calendar','Pilih tanggal',[('calendar',),b('Batal','@close','text'),b('OK','@close')],'finance_date_field.dart; showDatePicker',sheet=True)
add('Pemilih','calendar-input','Masukkan tanggal',[f('Tanggal','21/11/2026'),b('Mode kalender','calendar','text'),b('Batal','@close','text'),b('OK','@close')],'finance_date_field.dart; showDatePicker',sheet=True)
add('Pemilih','clock','Pilih waktu',[('clock',),b('Input angka','clock-input','text'),b('Batal','@close','text'),b('OK','@close')],'transaction_time_field.dart; showTimePicker',sheet=True)
add('Pemilih','clock-input','Pilih waktu',[f('Jam (00–23)','23'),f('Menit (00–59)','45'),b('Mode jam dinding','clock','text'),b('Batal','@close','text'),b('OK','@close')],'transaction_time_field.dart; showTimePicker',sheet=True)
add('Pemilih','photo-picker','Pilih foto',[('native','Android Photo Picker — hanya foto yang dipilih'),chips(['Foto','Album']),row('Foto struk pilihan pengguna','Tidak meminta akses seluruh galeri','','receipt-picker','paperclip'),('receipt',),b('Tambahkan','receipt-picker'),b('Batal','@close','text')],'receipt_images_field.dart; native Photo Picker',native=True,sheet=True)
add('Pemilih','loading-state','Menyimpan data',[('loading',),p('Operasi sedang berjalan. Tombol submit dinonaktifkan untuk mencegah duplikasi.')],'finance_controller.dart; arta_logo.dart',sheet=True)
add('Pemilih','validation-state','Periksa data',[('error','Isi kolom wajib. Nominal harus valid. Perubahan belum disimpan.'),b('Perbaiki isian','@close')],'finance_fields.dart; form validators',sheet=True)

# Additional branches found while auditing the source and every prototype target.
for route,kind,source,destination in [('debt-pay','transfer','Mandiri · IDR','Utang kartu kredit · IDR'),('debt-receive','transfer','Dana belum cair · IDR','Mandiri · IDR'),('debt-borrow','transfer','Utang kartu kredit · IDR','Mandiri · IDR'),('debt-lend','transfer','Mandiri · IDR','Dana belum cair · IDR'),('debt-spend','expense','Utang kartu kredit · IDR',None)]:
    items=tx_items(kind)
    items=[f(v[1],source,v[3],v[4]) if v[0]=='f' and v[1] in ['Aset','Dari aset'] else f('Ke aset',destination,'destination-assets') if v[0]=='f' and v[1]=='Ke aset' else v for v in items]
    add('Aset',route,'Catat transaksi',items,'debts_screen.dart; transaction_form.dart',footer=('Simpan transaksi','debts'))
for idx,(kind,label) in enumerate(classes,1):
    matching=[v for v in asset_rows if (label in v[2]) or (kind=='debit' and 'Debit' in v[1])]
    add('Aset','assets-filter-'+kind,'Aset',[card('Aset / Liabilitas / Total',[('balance',False)]),b('Tambah aset','asset-'+kind),f('Cari aset',''),chips(asset_filters,idx,['assets']+['assets-filter-'+k for k,_ in classes]),*matching],'home_screen.dart',nav=2)
add('Aset','asset-detail-empty','Mandiri',[card('Saldo aset',[val('Bank · IDR','Rp0'),p('Saldo awal dan transaksi membentuk saldo aset ini.')]),b('Catat transaksi','expense'),b('Transfer dari aset ini','transfer','secondary'),h('Riwayat transaksi'),empty('Belum ada transaksi untuk aset ini.')],'asset_detail_screen.dart')
for kind,label,item in [('expense','Pengeluaran',transactions[4]),('income','Pemasukan',transactions[-1]),('transfer','Transfer',transactions[5])]:
    add('Transaksi','transactions-'+kind,'Transaksi',[f('Cari transaksi',''),f('Jenis transaksi',label,'transaction-types'),b('Filter tanggal','calendar','text'),item],'home_screen.dart',nav=3,fab='expense')
add('Berulang','repeat-with-end','Transaksi berulang',tx_items(mode='repeat')+[f('Tanggal akhir (opsional)','31 Des 2026','calendar'),b('Tanpa tanggal akhir','repeat-expense','text')],'transaction_form.dart',footer=('Simpan jadwal','schedules'))
add('Berulang','schedule-not-found','Detail jadwal',[empty('Jadwal tidak ditemukan.','calendar')],'schedules_screen.dart')
add('Berulang','occurrence-installment','Catat satu kejadian',[h('Cicilan perangkat'),p('Cicilan 3/12 · jatuh tempo 21 Nov 2026'),f('Nominal aktual (IDR)','100.000',helper='Perubahan hanya untuk kejadian ini.'),f('Tanggal aktual','21 Nov 2026','calendar'),f('Catatan (opsional)',''),f('Jam','12:30 · WIB','clock'),p('Jika nominal cicilan diubah, bagian lainnya tetap sesuai rencana awal.'),b('Catat transaksi ini','schedule-installment'),b('Lewati sekali','occurrence-skip','secondary')],'occurrence_form.dart')
add('Investasi','investment-history-empty','Seluruh riwayat investasi',[],'portfolio_screen.dart')
for kind,code,label,cash,currency in [('crypto','ETH','Ethereum','Tokocrypto','IDR'),('fund','RDPU','Reksa dana pasar uang','Bibit','IDR')]:
    add('Investasi','investment-buy-'+kind,'Catat investasi',[p('Catat unit yang sudah dikonfirmasi. Tidak ada order pending atau koneksi transaksi platform otomatis.'),b(code+' · '+label,'catalog-select','secondary'),f('Jenis pencatatan','Beli','investment-kinds'),f('Aset kas / lokasi aset',cash,'source-assets'),f('Unit / lembar','0,01' if kind=='crypto' else '800'),switch('Hitung nominal dari unit × harga',False,'investment-unit-price'),f('Nominal bruto (IDR)','500.000' if kind=='crypto' else '1.000.000'),switch('Biaya transaksi',False),f('Tanggal','21 Nov 2026','calendar'),f('Jam','10:00','clock'),f('Catatan',''),b('Simpan investasi','portfolio')],'investment_form.dart')
add('Investasi','performance-private','Saham vs IHSG',[val('Kinerja portofolio saham','••••••'),p('Estimasi TWR · tanpa dividen tunai'),chips(['1B','3B','6B','1T','Semua']),card('Portofolio & pasar',[p('Return dan grafik disembunyikan ••••••')]),switch('Sertakan dividen neto',False),b('Tampilkan nominal','performance','text')],'performance_screen.dart')
add('Pemilih','clock-minutes','Pilih waktu',[('clock-minutes',),b('Input angka','clock-input','text'),b('Batal','@close','text'),b('OK','@close')],'transaction_time_field.dart; showTimePicker',sheet=True)
add('Keamanan','biometric-cancelled','Verifikasi PIN',[('error','Verifikasi sidik jari dibatalkan atau belum berhasil. Data dan PIN tetap disimpan.'),b('Coba sidik jari lagi','biometric-dialog'),b('Gunakan PIN','pin','secondary')],'app_lock_controller.dart',sheet=True)
add('Transaksi','transfer-fx-receiver','Catat transaksi',[chips(['Pengeluaran','Pemasukan','Transfer'],2,['expense','income','transfer']),f('Nominal (USD)','100'),f('Dari aset','Bybit ID · USD','source-assets'),f('Ke aset','MetaMask · USDT','destination-assets'),f('Nominal diterima (USDT)','100'),f('Kurs historis IDR per 1 USD','16.000'),switch('Biaya transaksi',True),switch('Biaya pengirim',True),f('Biaya pengirim (USD)','0,1'),switch('Biaya penerima',True),f('Biaya penerima (USDT)','0,05'),f('Kurs historis IDR per 1 USDT (biaya penerima)','16.000'),f('Berulang / Cicilan','Sekali saja','entry-modes'),f('Tanggal','21 Nov 2026','calendar'),f('Jam','12:30','clock'),f('Catatan (opsional)',''),b('Tambah foto','photo-picker','secondary')],'transaction_form.dart; transfer_fee_field.dart',footer=('Simpan transaksi','transactions'))

# Final source audit: exclude controls and money denominations absent in 0.7.2.
for spec in SPECS:
    if spec['route'] in ['card-new','card-edit']:
        spec['items']=[v for v in spec['items'] if v[0]!='switch']
        spec['items'].insert(-1,p('Pilih aset bank yang mewakili sumber kartu. Perubahan tautan berlaku untuk pilihan transaksi baru; sumber transaksi lama tetap tersimpan.'))
    if spec['route'].startswith('price-') and spec['route'] in ['price-stock','price-crypto','price-fund']:
        spec['items'][1]=f('Harga per unit (IDR)',spec['items'][1][2])
    if spec['page']=='Harga':
        spec['items']=[row('SGD','Belum ada kurs','','fx-sgd','document') if v[0]=='row' and v[1]=='USDC' else v for v in spec['items']]
    if spec['route'] in ['market','market-key-visible','market-auto-off','market-saved']:
        spec['items'] += [row('EUR','Belum ada kurs','','fx-eur','document'),row('MYR','Belum ada kurs','','fx-myr','document')]
    if spec['route']=='destination-assets':spec['items']=[row(v[1],v[2],v[3],'transfer-fx-receiver' if v[1]=='MetaMask · USDT' else v[4],v[5],v[6]) for v in spec['items']]
    if spec['route']=='startup-loading':spec['items']=[v for v in spec['items'] if not(v[0]=='h' and v[1]=='Arta')]
    if spec['route']=='analysis-investment':spec['items'][0]=f('Jenis analisis','Portofolio investasi','analysis-scope')
    if spec['route']=='assets':spec['items']=[chips(asset_filters,0,['assets']+['assets-filter-'+k for k,_ in classes]) if v[0]=='chips' else v for v in spec['items']]
    if spec['route']=='transaction-types':spec['items']=[row(x,'','',r,'check') for x,r in [('Semua','transactions'),('Pengeluaran','transactions-expense'),('Pemasukan','transactions-income'),('Transfer','transactions-transfer')]]
    if spec['route']=='debts':spec['items'] += [b('Terima pinjaman','debt-borrow','secondary'),b('Berikan pinjaman','debt-lend','secondary')]
    if spec['route']=='portfolio-crypto':spec['items'] += [b('Beli crypto','investment-buy-crypto','secondary')]
    if spec['route']=='portfolio-fund':spec['items'] += [b('Beli reksa dana','investment-buy-fund','secondary')]
    if spec['route']=='portfolio-actions':spec['items']=[row('Catat investasi','','','investment-buy','plus'),row('Staking crypto','','','staking','staking'),row('Saham vs IHSG','','','performance','stocks'),row('Katalog instrumen','','','catalog','search'),row('Sumber harga & kurs','','','market','settings'),row('Perbarui penutupan','','','daily-refresh','calendar'),row('Harga terbaru (manual)','','','price-refresh','refresh')]
    if spec['route']=='category-edit':spec['items']=[v for v in spec['items'] if not(v[0]=='b' and v[1]=='Arsipkan kategori')]
    if spec['route'].startswith('categories'):
        spec['items']=[('category-controls','archive' in spec['route']) if v[0]=='chips' and v[1]==['Arsip','Tambah kategori'] else ('category-row',*v[1:]) if v[0]=='row' else v for v in spec['items']]
    spec['source']=spec['source'].replace('idx_catalog_service.dart','catalog_service.dart').replace('services/bootstrap_service.dart','local_storage_service.dart')

# Batched command drawing DSL. Geometry follows current Flutter theme tokens.
class Builder:
    def __init__(self,spec,theme,index):
        self.s=spec;self.theme=theme;self.index=index;self.c=[];self.i=0;self.links=[];self.root='root';self.y=0
    def command(self,cmd,params,alias=None):
        d={'command':cmd,'params':params}
        if alias:d['as']=alias
        self.c.append(d)
        return {'$ref':alias} if alias else None
    def n(self,typ,name,parent,x=0,y=0,w=100,ht=100,**props):
        self.i+=1;a='n'+str(self.i)
        geometry={key:props.pop(key) for key in ['points','path','closed'] if key in props}
        dims={} if typ=='vector' else dict(width=w,height=ht)
        return self.command('node.create',dict(type=typ,name=name,parent=parent,x=x,y=y,props=props,select=False,**dims,**geometry),a)
    def txt(self,parent,text,x,y,w=336,size=14,bold=False,role='Text/Primary',align='left',height=None):
        lines=sum(max(1,math.ceil(len(line)*size*.49/max(w,1))) for line in text.split('\n'))
        ht=height or math.ceil(lines*size*1.5)
        n=self.n('text',text[:70],parent,x,y,w,ht,fontFamily='Bit Sans',fontStyle='Bold' if bold else 'Regular',fontSize=size,lineHeight=size*1.5,textAutoResize='height',textAlign=align,fill={'$var':role},characters=text)
        return n,ht
    def rect(self,parent,name,x,y,w,ht,fill='Surface/Raised',radius=8,stroke=None):
        props={'fill':{'$var':fill} if fill and not fill.startswith('#') else fill,'cornerRadius':radius}
        if stroke:props.update(stroke={'$var':stroke},strokeWeight=1)
        return self.n('frame',name,parent,x,y,w,ht,**props)
    def link(self,node,dest):
        if dest:self.links.append({'node':node['$ref'],'dest':dest})
    def icon(self,parent,name,x,y,color='Text/Secondary',size=24):
        comp=ICONS.get(name,ICONS['document']); self.i+=1;a='n'+str(self.i)
        n=self.command('instance.create',{'component':comp,'parent':parent,'x':x,'y':y},a)
        tone='White' if color=='OnAccent' else 'Purple' if color=='Purple' else 'Green' if color=='Accent' else 'Red' if color=='Negative' else 'Neutral'
        self.command('variable.setMode',{'ids':[n],'collection':'IconTone','mode':tone})
        if size!=24:self.command('transform.scale',{'ids':[n],'factor':size/24})
        return n
    def logo(self,parent,x,y,size=56):
        self.i+=1;a='n'+str(self.i);n=self.command('instance.create',{'component':6773,'parent':parent,'x':x,'y':y},a);self.command('transform.scale',{'ids':[n],'factor':size/88});return n
    def button(self,parent,label,y,dest=None,kind='primary',w=368):
        ht=max(48,math.ceil(len(label)*7.1/max(1,w-32))*21+24)
        r=self.rect(parent,label,0,y,w,ht,'Disabled' if kind=='disabled' else 'Accent/Button' if kind=='primary' else 'Background',8,'Border/Input' if kind=='secondary' else None)
        self.command('node.set',{'ids':[r],'props':{'layout':'horizontal','padding':[12,16,12,16],'mainAlign':'center','crossAlign':'center','gap':8}})
        self.txt(r,label,0,0,w-32,14,True,'OnDisabled' if kind=='disabled' else 'OnAccent' if kind=='primary' else 'Accent',align='center')
        self.link(r,dest if kind!='disabled' else None);return ht
    def item(self,parent,item,y,w=368):
        typ,*args=item
        if typ in ['p','h','note','error']:
            t=args[0]; role='Negative' if typ=='error' else 'Text/Secondary' if typ=='p' else 'Text/Primary'
            if typ in ['note','error']:
                _,ht0=self.txt(parent,'',0,0,w-32);ht0=math.ceil(sum(max(1,math.ceil(len(l)*14*.49/max(w-32,1))) for l in t.split('\n'))*21)
                r=self.rect(parent,'Peringatan' if typ=='error' else 'Informasi',0,y,w,ht0+32,'Surface/Inner',8)
                self.txt(r,t,16,16,w-32,14,False,role);return ht0+32
            _,ht=self.txt(parent,t,0,y,w,16 if typ=='h' else 14,typ=='h',role);return ht
        if typ=='f':
            label,value,dest,helper=args;label=label.replace('$currency','IDR')
            lh=max(16,math.ceil(len(label)*12*.49/(w-32))*18)
            ht=max(64,lh+38)
            r=self.rect(parent,label,0,y,w,ht,'Surface/Inner',8,'Border/Input')
            self.txt(r,label,16,7,w-48,12,False,'Text/Secondary')
            self.txt(r,value if value else ' ',16,lh+12,w-52,14)
            if dest:self.icon(r,'chevron-down',w-38,ht/2-12)
            self.link(r,dest)
            if helper:_,sh=self.txt(parent,helper,12,y+ht+4,w-24,12,False,'Text/Secondary');ht+=sh+8
            return ht
        if typ=='b':return self.button(parent,args[0],y,args[1],args[2],w)
        if typ=='row':
            title,sub,value,dest,icon,brand=args
            ht=max(72,math.ceil(len(title)*14*.49/(w-76-(112 if value else 24)))*21+(36 if sub else 16))
            r=self.rect(parent,title,0,y,w,ht,'Surface/Raised',8)
            if brand in BRANDS:
                ci,cw,ch=BRANDS[brand];self.i+=1;a='n'+str(self.i);ic=self.command('instance.create',{'component':ci,'parent':r,'x':16,'y':ht/2-min(40,40*ch/cw)/2},a);self.command('transform.scale',{'ids':[ic],'factor':min(40/cw,40/ch)})
            else:
                self.n('ellipse','Icon tint',r,16,ht/2-20,40,40,fill={'$var':'Accent/Tint'})
                self.icon(r,icon or 'document',24,ht/2-12,'Purple' if icon in ['stocks','portfolio'] else 'Accent')
            tw=w-88-(100 if value else 20)
            _,th=self.txt(r,title,68,12,tw,14,True)
            if sub:self.txt(r,sub,68,16+th,tw,12,False,'Text/Secondary')
            if value:self.txt(r,value,w-116,ht/2-12,100,14,True,'Negative' if value.startswith('−') else 'Text/Primary',align='right')
            elif dest:self.icon(r,'chevron-right',w-36,ht/2-12)
            self.link(r,dest);return ht
        if typ=='category-controls':
            archived=args[0];r=self.rect(parent,'Arsip',0,y,76,40,'Accent/Tint' if archived else 'Surface/Raised',6,'Border');self.txt(r,'Arsip',8,10,60,12,align='center');self.link(r,'categories' if archived else 'categories-archive')
            rr=self.n('frame','Tambah kategori',parent,88,y,214,48,fill=None);self.button(rr,'Tambah kategori',0,'category-add',w=214);return 48
        if typ=='category-row':
            title,sub,value,dest,icon,brand=args;r=self.rect(parent,title,0,y,w,84,'Surface/Raised',8);self.n('ellipse','Tint',r,16,22,40,40,fill={'$var':'Accent/Tint'});self.icon(r,icon,24,30,'Accent');self.txt(r,title,68,12,w-128,14,True);self.txt(r,sub,68,40,w-128,12,role='Text/Secondary');self.link(r,dest)
            hit=self.n('frame','Aktifkan kategori' if 'Diarsipkan' in sub else 'Arsipkan kategori',r,w-56,18,48,48,fill=None)
            if 'Diarsipkan' in sub:self.icon(hit,'history',12,12)
            else:
                self.n('rectangle','Box archive',hit,14,21,20,15,fill=None,stroke={'$var':'Text/Secondary'},strokeWeight=1.5)
                self.n('rectangle','Lid archive',hit,12,14,24,7,fill=None,stroke={'$var':'Text/Secondary'},strokeWeight=1.5)
                self.n('line','Handle archive',hit,21,26,6,0,stroke={'$var':'Text/Secondary'},strokeWeight=1.5)
            self.link(hit,'category-reactivate' if 'Diarsipkan' in sub else 'category-archive');return 84
        if typ=='chips':
            labels,selected,dests=args;x=0;yy=0
            for i,t in enumerate(labels):
                cw=min(w,max(56,len(t)*6.7+24))
                if x+cw>w:x=0;yy+=46
                r=self.rect(parent,t,x,y+yy,cw,38,'Accent/Tint' if i==selected else 'Surface/Raised',6,'Border')
                self.txt(r,t,8,9,cw-16,12,False,'Text/Primary',align='center')
                if dests:self.link(r,dests[i])
                x+=cw+8
            return yy+38
        if typ=='switch':
            title,on,dest,sub=args;_,th=self.txt(parent,title,0,y,w-70,14,True)
            ht=max(48,th+12)
            if sub:_,sh=self.txt(parent,sub,0,y+th+4,w-70,12,False,'Text/Secondary');ht=max(ht,th+sh+8)
            r=self.rect(parent,title+' switch',w-52,y+10,48,28,'Accent/Button' if on else 'Border',14)
            self.n('ellipse','Thumb',r,24 if on else 4,4,20,20,fill='#FFFFFF')
            self.link(r,dest);return ht
        if typ=='value':
            label,value,role=args;self.txt(parent,label,0,y,w,12,False,'Text/Secondary');self.txt(parent,value,0,y+24,w,26,True,role)
            return 66
        if typ=='card':
            title,children=args;r=self.rect(parent,title,0,y,w,100)
            top=16 if title=='Aset / Liabilitas / Total' else 50
            if top==50:self.txt(r,title,16,16,w-32,16,True)
            inner=self.n('frame','Isi card · padding 16',r,16,top,w-32,100,fill=None,clip=False);cy=0
            for v in children:cy+=self.item(inner,v,cy,w-32)+12
            self.command('node.set',{'ids':[inner],'props':{'height':cy}})
            self.command('node.set',{'ids':[r],'props':{'height':top+cy+4}});return top+cy+4
        if typ=='empty':
            msg,icon=args;r=self.rect(parent,'Empty state · FinanceScene',0,y,w,238,'Background',8)
            scene=self.n('frame','Ilustrasi keuangan editable 148 × 116',r,w/2-74,24,148,116,fill=None)
            self.n('ellipse','Aura',scene,4,7,140,102,fill={'$var':'Accent'},opacity=.055)
            self.n('rectangle','Rear paper',scene,32,20,85,76,fill={'$var':'Accent'},opacity=.1,cornerRadius=15)
            self.n('rectangle','Front paper',scene,22,13,91,82,fill={'$var':'Surface/Raised'},stroke={'$var':'Border'},strokeWeight=1.2,cornerRadius=15)
            self.icon(scene,icon,44,30,'Accent',46)
            self.n('ellipse','Check badge',scene,106,78,26,26,fill={'$var':'Surface/Raised'},stroke={'$var':'Accent'},strokeWeight=1.8)
            self.n('vector','Check mark',scene,0,0,points=[[113,92],[117,96],[125,86]],stroke={'$var':'Accent'},strokeWeight=1.8,fill=None)
            self.n('ellipse','Dot',scene,15,93,6,6,fill={'$var':'Accent'},opacity=.3)
            self.n('ellipse','Dot',scene,126,19,8,8,fill={'$var':'Accent'},opacity=.2)
            self.txt(r,msg,34,156,w-68,14,False,'Text/Secondary',align='center');return 238
        if typ=='native':
            _,ht=self.txt(parent,args[0],0,y,w,12,False,'Text/Secondary');return ht+8
        if typ=='large-icon':self.icon(parent,args[0],w/2-36,y,'Accent',72);return 92
        if typ=='loading':
            self.logo(parent,w/2-28,y+12,56);self.txt(parent,'Arta',0,y+82,w,22,True,align='center');return 132
        if typ=='receipt':
            r=self.rect(parent,'Contoh struk fiktif',16,y,w-32,280,'Surface/Inner',8,'Border/Input');self.txt(r,'TOKO CONTOH\n21 NOV 2026 · 12:30\n\nMakanan                 35.000\nMinuman                 10.000\n────────────────────\nTOTAL                  Rp45.000\n\nContoh lampiran pengguna',20,20,w-72,14);return 280
        if typ=='balance':
            hidden=args[0];self.txt(parent,'Aset',0,y,w/2-12,12,False,'Text/Secondary');self.txt(parent,'Liabilitas',w/2+8,y,w/2-8,12,False,'Text/Secondary');self.txt(parent,'••••••' if hidden else 'Rp153.150.000',0,y+24,w/2-8,16,True);self.txt(parent,'••••••' if hidden else 'Rp1.200.000',w/2+8,y+24,w/2-8,16,True);self.txt(parent,'Total',0,y+64,w-40,12,False,'Text/Secondary');self.txt(parent,'••••••' if hidden else 'Rp151.950.000',0,y+88,w-48,24,True);ic=self.icon(parent,'eye-off' if hidden else 'eye',w-28,y+80);self.link(ic,'home' if hidden else 'home-private');return 128
        if typ=='shortcuts':
            for i,(ico,label,dest) in enumerate([('plus','Catat','expense'),('schedule','Berulang','schedules'),('interest','Bunga','interest'),('staking','Staking','staking')]):
                cx=(w/4)*i+w/8;r=self.n('ellipse',label,parent,cx-20,y,40,40,fill={'$var':'Accent/Tint'});self.icon(parent,ico,cx-12,y+8,'Accent');self.txt(parent,label,cx-w/8,y+50,w/4,12,False,'Text/Secondary',align='center');self.link(r,dest)
            return 78
        if typ=='carousel':
            r=self.rect(parent,'Arus kas bulanan · carousel',0,y,w,230);self.txt(r,'Arus kas bulanan' if args[0]==0 else 'Perbandingan bulanan',16,16,w-32,16,True);self.txt(r,'Pemasukan Rp10.000.000\nPengeluaran Rp2.350.000',16,52,w-32,14);self.chart_shapes(r,'cashflow',16,104,w-32,86,'normal')
            for i in range(2):self.n('ellipse','Indikator halaman '+str(i+1),r,w/2-12+i*16,210,6,6,fill={'$var':'Accent' if i==args[0] else 'Border/Input'})
            self.link(r,'home-slide2' if args[0]==0 else 'home');return 230
        if typ=='chart':
            kind,title,state=args;r=self.rect(parent,title,0,y,w,300 if kind!='donut' else 340,'Surface/Raised',8);self.txt(r,title,16,16,w-48,16,True)
            if kind=='donut':
                colors=['Accent','Purple','Chart/Blue'];vals=[.51,.4,.09];start=-math.pi/2
                for i,frac in enumerate(vals):
                    pts=[]
                    for n in range(32):
                        a=start+2*math.pi*frac*n/31;pts.append([w/2+math.cos(a)*74,150+math.sin(a)*74])
                    for n in range(31,-1,-1):
                        a=start+2*math.pi*frac*n/31;pts.append([w/2+math.cos(a)*48,150+math.sin(a)*48])
                    self.n('vector','Editable donut segment '+str(i+1),r,0,0,w,260,fill={'$var':colors[i]},points=pts,closed=True)
                    start+=2*math.pi*frac
                for i,(label,value) in enumerate([('Crypto','51%'),('Saham','40%'),('Reksa dana','9%')]):self.txt(r,label+' · '+value,24,244+i*25,w-48,12,role=colors[i])
            else:self.chart_shapes(r,kind,16,60,w-32,190,state)
            eye=self.icon(r,'eye',w-40,16);self.link(eye,'analysis-private')
            return 340 if kind=='donut' else 300
        if typ=='calendar':
            self.txt(parent,'Sab, 21 Nov',0,y,w,26,True);self.txt(parent,'November 2026',0,y+56,w,16,True);self.txt(parent,'S     S     R     K     J     S     M',0,y+94,w,14,False,'Text/Secondary',align='center')
            for n in range(30):
                col=(n+6)%7;rr=(n+6)//7;cx=col*w/7;yy=y+130+rr*42
                if n==20:self.n('ellipse','Tanggal terpilih',parent,cx+5,yy-4,34,34,fill={'$var':'Accent/Button'})
                nn,_=self.txt(parent,str(n+1),cx,yy,w/7,14,False,'OnAccent' if n==20 else 'Text/Primary',align='center');self.link(nn,'@close')
            return 388
        if typ in ['clock','clock-minutes']:
            self.txt(parent,'23 : 45',0,y,w,36,True,align='center');r=self.rect(parent,'Jam 24 jam',w/2-116,y+70,232,232,'Surface/Inner',116)
            for n in range(12 if typ=='clock-minutes' else 24):
                a=n*math.pi/6-math.pi/2;rad=94 if n<12 else 62;label=f'{n*5:02d}' if typ=='clock-minutes' else str(12 if n==0 else n if n<12 else 0 if n==12 else n);nn,_=self.txt(r,label,116+rad*math.cos(a)-12,116+rad*math.sin(a)-12,24,14,False,align='center');self.link(nn,'@close' if typ=='clock-minutes' else 'clock-minutes')
            self.n('vector','Jarum jam',r,0,0,232,232,points=[[116,116],[69,35]],stroke={'$var':'Accent'},strokeWeight=2,fill=None);return 318
        if typ=='pin':return self.pin(parent,args[0],y,w)
        raise ValueError(typ)
    def chart_shapes(self,parent,kind,x,y,w,ht,state):
        for i in range(4):self.n('line','Chart grid',parent,x,y+i*ht/3,w,0,stroke={'$var':'Border'},strokeWeight=.6)
        if state in ['empty','missing']:
            self.txt(parent,'Belum ada data lengkap.' if state=='empty' else 'Harga/kurs belum lengkap.',x+12,y+ht/2-14,w-24,12,role='Text/Secondary');return
        for series,role in enumerate(['Accent','Negative'] if kind=='cashflow' else ['Accent','Purple'] if kind=='benchmark' else ['Accent']):
            points=[[x+i*w/11,y+ht*(.8-i*.05+math.sin(i*1.6+series)*.08+series*.12)] for i in range(12)]
            if state=='one':self.n('ellipse','Satu titik data',parent,x+w/2,y+ht/2,6,6,fill={'$var':role})
            else:self.n('vector','Editable series '+str(series+1),parent,0,0,w+x,ht+y,points=points,stroke={'$var':role},strokeWeight=1.7,fill=None,closed=False)
        self.txt(parent,'1 Nov',x,y+ht+12,60,11,role='Text/Secondary');self.txt(parent,'20 Nov',x+w-64,y+ht+12,64,11,role='Text/Secondary',align='right')
        if kind=='benchmark':self.txt(parent,'Saham   +7,50%      IHSG   +4,20%',x,y+ht+34,w,12)
        if state=='tooltip':
            t=self.rect(parent,'Tooltip',x+60,y+16,min(190,w-64),60,'Surface/Inner',6,'Border');self.txt(t,'21 Nov 2026\nRp151.950.000',12,8,170,12)
    def pin(self,parent,state,y,w):
        setup=state in ['setup','confirm','mismatch','reset']
        if setup:
            self.txt(parent,'Ulangi PIN Anda' if state=='confirm' else 'Buat PIN 6 angka',0,y+28,w,18,True,align='center');self.txt(parent,'Gunakan PIN khusus aplikasi ini.',0,y+72,w,14,align='center')
            if state=='mismatch':self.txt(parent,'PIN berbeda. Buat ulang PIN Anda.',0,y+108,w,12,role='Negative',align='center')
            self.txt(parent,'••••••' if state=='confirm' else ' ',24,y+150,w-48,22,align='center');self.icon(parent,'eye',w-36,y+150)
            for r in range(4):
                for c in range(3):
                    key=str(r*3+c+1) if r<3 else 'fingerprint' if c==0 else '0' if c==1 else 'backspace';xx=c*w/3;yy=y+210+r*64
                    self.n('line','Key divider',parent,xx,yy,w/3,0,stroke={'$var':'Border'},strokeWeight=.5)
                    if key.isdigit():nn,_=self.txt(parent,key,xx,yy+12,w/3,26,align='center');self.link(nn,'security-enabled' if state=='confirm' else 'pin-confirm')
                    else:self.icon(parent,key,xx+w/6-12,yy+20,'Text/Secondary')
            self.item(parent,switch('Utamakan sidik jari',True,None,'Gunakan sidik jari HP; PIN Arta tetap tersedia'),y+500,w);return 590
        self.txt(parent,'Verifikasi PIN',0,y+12,w,16,True,align='center')
        self.icon(parent,'lock',w/2-28,y+100,'Accent',56);self.txt(parent,'Gunakan PIN khusus aplikasi ini.' if setup else 'Masukkan PIN Kamu',0,y+188,w,18,True,align='center')
        shown='123456' if state=='visible' else '••••••' if state in ['filled','loading','error'] else ' '
        self.txt(parent,shown,28,y+248,w-56,22,align='center');ic=self.icon(parent,'eye',w-36,y+248);self.link(ic,'pin-visible' if state!='visible' else 'pin-filled')
        if state in ['error','lockout','mismatch']:self.txt(parent,'PIN berbeda. Buat ulang PIN Anda.' if state=='mismatch' else 'Tunggu 30 detik sebelum mencoba lagi.' if state=='lockout' else 'PIN salah. Coba lagi.',0,y+292,w,12,False,'Negative',align='center')
        self.button(parent,'Lanjut',y+340,'home','disabled' if state in ['empty','unavailable','lockout'] else 'primary',w)
        if not setup:
            n,_=self.txt(parent,'Lupa PIN? Verifikasi dengan sidik jari',0,y+410,w,12,role='Accent',align='center');self.link(n,'forgot-pin-unavailable' if state=='unavailable' else 'forgot-pin-verify')
        for r in range(4):
            for c in range(3):
                key=str(r*3+c+1) if r<3 else 'fingerprint' if c==0 else '0' if c==1 else 'backspace';xx=c*w/3;yy=y+464+r*64
                self.n('line','Key divider',parent,xx,yy,w/3,0,stroke={'$var':'Border'},strokeWeight=.5)
                if key.isdigit():n,_=self.txt(parent,key,xx,yy+12,w/3,26,align='center');self.link(n,'pin-filled' if not setup else 'pin-confirm')
                else:ic=self.icon(parent,key,xx+w/6-12,yy+20,'Accent' if key=='fingerprint' and state!='unavailable' else 'Text/Secondary');self.link(ic,'biometric-dialog' if key=='fingerprint' else 'pin')
        if setup:self.txt(parent,'Utamakan sidik jari · aktif jika tersedia',0,y+736,w,12,role='Text/Secondary',align='center')
        if state=='loading':
            r=self.rect(parent,'Scrim biometrik tanpa menggeser keypad',-16,-80,w+32,900,'#00000099',0);self.logo(r,w/2-12,390,56);self.link(r,'biometric-dialog')
        return 776
    def build(self):
        page=PAGES[self.s['page']];x=(self.index%3)*920+(440 if self.theme=='Light' else 0);yy=(self.index//3)*1100
        root=self.command('node.create',dict(type='frame',name=f"{self.s['route']} · {self.theme}",parent=page,x=x,y=yy,width=400,height=900,props={'fill':{'$var':'Background'},'clip':True,'pluginData':{'artaVersion':'0.7.2','route':self.s['route'],'source':self.s['source'],'theme':self.theme}},select=False),'root')
        self.command('variable.setMode',{'ids':[root],'collection':'Theme','mode':self.theme})
        # Status/navigation bars are representative Android chrome.
        self.txt(root,'17:31',16,8,100,12,True);self.txt(root,'LTE   ▰',310,8,74,12,align='right')
        full_pin=self.s.get('pin') and self.s['route'] not in ['pin-setup','pin-confirm','pin-mismatch','pin-reset']
        if not self.s.get('sheet') and not full_pin and not self.s.get('startup'):
            if self.s.get('nav') is None:
                ic=self.icon(root,'chevron-left',16,44);self.link(ic,'@back')
            self.txt(root,self.s['title'],16 if self.s.get('nav') is not None or self.s.get('pin') else 56,42,292,18,True)
            if self.s.get('menu'):ic=self.icon(root,'more',360,44);self.link(ic,self.s['menu'])
            if self.s.get('delete'):ic=self.icon(root,'trash',360,44);self.link(ic,self.s['delete'])
        nav=self.s.get('nav');footer=self.s.get('footer');view_h=772-(64 if nav is not None else 0)-(72 if footer else 0)
        if self.s.get('sheet'):
            self.rect(root,'Underlying app preview',16,110,368,200,'Surface/Raised');self.txt(root,'Arta',32,130,260,18,True);self.rect(root,'Scrim',0,0,400,900,'#00000099',0)
            sheet=self.rect(root,self.s['title']+' · bottom sheet',0,140,400,712,'Surface/Raised',[20,20,0,0]);self.rect(sheet,'Drag handle',184,10,32,4,'Border/Input',2);self.txt(sheet,self.s['title'],20,30,340,18,True)
            view=self.n('frame','Scroll viewport',sheet,0,72,400,620,clip=True,overflow='vertical',fill=None)
        else:view=self.n('frame','Scroll viewport',root,0,24 if full_pin or self.s.get('startup') else 80,400,828 if full_pin or self.s.get('startup') else view_h,clip=True,overflow='vertical',fill=None)
        body=self.n('frame','Konten scroll · seluruh field aplikasi',view,16,16,368,100,fill=None,clip=False)
        y=0
        for item in self.s['items']:y+=self.item(body,item,y)+16
        self.command('node.set',{'ids':[body],'props':{'height':y+20}})
        if self.s.get('sheet'):
            sh=min(752,max(220,y+104))
            self.command('node.set',{'ids':[sheet],'props':{'y':852-sh,'height':sh}})
            self.command('node.set',{'ids':[view],'props':{'height':sh-88}})
        elif self.s.get('startup'):
            self.command('node.set',{'ids':[body],'props':{'y':max(16,(828-y)/2)}})
        if nav is not None:
            nr=self.rect(root,'Navigasi utama · tanpa teks',0,788,400,64,'Background',0)
            for i,(ico,dest) in enumerate([('home','home'),('portfolio','portfolio'),('wallet','assets'),('receipt','transactions'),('settings','settings')]):
                hit=self.n('frame','nav-'+str(i),nr,i*80,8,80,48,fill=None);self.icon(hit,ico,28,12,'Accent' if i==nav else 'Text/Secondary');self.link(hit,dest)
        if footer:
            foot=self.rect(root,'Tombol simpan tetap di atas navigasi Android',0,780,400,72,'Background',0);self.button(foot,footer[0],12,footer[1],w=368);self.command('node.set',{'ids':[foot],'props':{'x':16,'width':368}})
        if self.s.get('fab'):
            r=self.rect(root,'Tambah transaksi',328,716,56,56,'Accent/Button',12);self.icon(r,'plus',16,16,'OnAccent');self.link(r,self.s['fab'])
        self.rect(root,'Android navigation inset',0,852,400,48,'Background',0);self.txt(root,'◁                 ○                 ▢',56,866,288,14,False,'Text/Secondary',align='center')
        return self.c,self.links,y

def generate():
    if not PAGES:print('Spec count',len(SPECS));return
    units=OUT/'units';units.mkdir(exist_ok=True)
    manifest=[];counts={}
    for spec in SPECS:
        i=counts.get(spec['page'],0);counts[spec['page']]=i+1
        for theme in ['Dark','Light']:
            builder=Builder(spec,theme,i);commands,links,content_h=builder.build()
            filename=f"{len(manifest):03d}-{spec['route']}-{theme.lower()}.json"
            payload={'commands':commands,'label':f"0.7.2 · {spec['route']} · {theme}",'document':3}
            (units/filename).write_text(json.dumps(payload,ensure_ascii=False),encoding='utf-8')
            manifest.append(dict(route=spec['route'],title=spec['title'],page=spec['page'],theme=theme,file=filename,commands=len(commands),links=links,contentHeight=content_h,source=spec['source'],native=spec.get('native',False),sheet=spec.get('sheet',False)))
    (OUT/'specs.json').write_text(json.dumps(SPECS,ensure_ascii=False,indent=2),encoding='utf-8')
    (OUT/'manifest-plan.json').write_text(json.dumps(manifest,ensure_ascii=False),encoding='utf-8')
    print(json.dumps({'states':len(SPECS),'artboards':len(manifest),'commands':sum(m['commands'] for m in manifest),'pages':counts},ensure_ascii=False))

if __name__=='__main__':generate()
