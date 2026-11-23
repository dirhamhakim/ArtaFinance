# Arta — desain aplikasi keuangan pribadi

> **Tahap 2 selesai — 21 November 2026:** [UI lengkap FigCraft dan panduan](full-ui-2026-11-21/README.md) memuat 176 pasangan layar/state/pemilih (352 artboard), dua QA 360 px, logo/loading Arta, DOKU, 45 pasangan sheet dan alur fitur terbaru. File native: `Arta-UI-Lengkap-2026-11-21.figcraft`. Ini desain/prototype; kode Flutter/APK belum berubah. Informasi status lama di bawah tetap sebagai riwayat.

> **Master terbaru — 21 November 2026:** [Arta-Master-Ikon-Komponen-2026-11-21.figcraft](Arta-Master-Ikon-Komponen-2026-11-21.figcraft), dengan [panduan dan preview](master-components-2026-11-21/README.md). Proyek baru berisi 52 glyph, 12 logo dan 97 master UI dalam dua tema. Gunakan ini untuk rombak berikutnya; proyek 174 state di bawah tetap disimpan sebagai desain lama, belum seluruhnya dipindahkan ke master baru.

Desain dibuat dan direvisi pada 18 November 2026 melalui MCP FigCraft. **Arta** adalah nama kerja yang dapat diganti. File native: [Arta-Keuangan-Pribadi.figcraft](Arta-Keuangan-Pribadi.figcraft). Revisi v3 menambahkan logo, prototype loading, impor/ekspor katalog IDX dan saldo noninvestasi negatif. Ukuran/font/komponen tetap mengikuti revisi v2 berdasarkan [59 screenshot pengguna](../docs/design/ANALISIS-REFERENSI-SCREENSHOT.md).

## Isi proyek

Ada **174 layar/state**, termasuk **17 overlay**, pada sembilan halaman. Revisi v3 menambahkan 79 state: 38 gelap dan 41 terang. Desain utama memakai tema gelap dengan aksen hijau, mengikuti [59 screenshot referensi](../docs/design/ANALISIS-REFERENSI-SCREENSHOT.md). Ini bukan spesifikasi merek resmi Stockbit.

| Halaman FigCraft | Cakupan |
| --- | --- |
| 00 · Foundations & Components | Warna semantik, tipografi Lato, tombol, field, navigasi, badge, baris transaksi, state form dan contoh teks besar |
| 01 · Beranda & Transaksi | Kekayaan bersih, chart, nominal tersembunyi, daftar/kalender, pemasukan, pengeluaran, transfer, detail, pencarian dan lampiran |
| 02 · Investasi | Ringkasan, saham, crypto, reksa dana, detail aset, beli/jual/transfer, riwayat, NAB manual, pembelian dan pencairan reksa dana yang menunggu konfirmasi |
| 03 · Akun, Jadwal & Bunga | Akun dan kelompoknya, mutasi, rekonsiliasi, aturan berulang, pemilih tanggal/akhir bulan, cicilan, pembayaran kewajiban, aturan bunga, saldo bertingkat dan estimasi |
| 04 · Laporan & Pengaturan | Laporan arus kas/kategori/kekayaan, anggaran, backup/restore, ekspor CSV, kategori, harga, kurs, notifikasi, keamanan, tema dan panduan |
| 05 · States & Flows | Pemilih akun/kategori/aset/tanggal, filter, konfirmasi, sukses, kosong, error, status harga, keypad, PIN, preview terang dan beranda 360 px |
| 06 · Referensi & Spesifikasi v2 | Katalog 59 screenshot, detail gambar panjang, pembanding font dan spesifikasi bentuk/ukuran komponen native |
| 07 · Identitas & Loading | Master monogram/wordmark Arta, ikon launcher, aset SVG/PNG/Android, splash, tiga fase loading, versi statis, error/coba lagi dan Tentang; gelap/terang |
| 08 · Katalog Saham IDX | Katalog/pencarian, Excel/JSON, pemilih file, lima kolom sumber, pratinjau/perbandingan, kode yang tetap disimpan, validasi, proses/sukses/gagal, impor ulang, detail/koreksi metadata dan ekspor; 29 state per tema |

Daftar seluruh layar beserta ID node berada di [screen-manifest.json](screen-manifest.json). ID tersebut merujuk pada file native ini.

## Cara meninjau prototype

1. Buka file `.figcraft` di FigCraft. Posisi tersimpan berada di layar Ringkasan pada halaman 01.
2. Gunakan Present/Preview dan pilih flow yang ingin ditinjau.
3. Coba tab bawah, tombol tambah/catat, baris daftar, tombol kembali, serta tutup panel.

Lima belas titik awal prototype tersedia:

| Flow | Layar awal | Yang ditinjau |
| --- | --- | --- |
| 01 · Mulai dari Beranda | Ringkasan | Lima tab utama, laporan, transaksi dan sembunyikan saldo |
| 02 · Catat transaksi | Pengeluaran | Jenis transaksi, akun/kategori, tanggal, jadwal, keypad dan simpan |
| 03 · Kelola investasi | Investasi | Kelas aset, detail, pencatatan beli/jual/transfer dan reksa dana |
| 04 · Berulang & akhir bulan | Berulang | Aturan bulanan, tanggal tertentu, hari terakhir, detail dan tindakan jadwal |
| 05 · Bunga buatan pengguna | Bunga akun | Input tarif, dasar saldo, tingkatan, estimasi dan pencatatan aktual |
| 06 · Backup & pemulihan | Backup & ekspor | Backup lengkap, CSV, preview pemulihan, konfirmasi dan error |
| 07 · Logo & pembukaan Arta | Splash gelap | Logo → tiga fase loading → Beranda |
| 08 · Pembukaan gagal & coba lagi | Pembukaan gagal | Error pembukaan dan coba lagi |
| 09 · Impor katalog IDX | Katalog gelap | Pilih Excel/JSON, preview, pembaruan, pencarian dan ekspor |
| 10 · File katalog bermasalah | Validasi gagal | Duplikasi kode, nama kosong dan jumlah lembar tidak valid |
| 11 · Pembaruan gagal & pemulihan | Impor gagal | Keadaan lama tetap tersimpan dan coba lagi |
| 12 · Saldo noninvestasi boleh minus | Pengeluaran | Rp100.000 − Rp150.000 → saldo −Rp50.000, simpan tetap aktif |
| 13 · Logo Arta · terang | Splash terang | Pasangan terang untuk alur pembukaan |
| 14 · Impor katalog · terang | Katalog terang | Pasangan terang untuk alur katalog |
| 15 · Saldo minus · terang | Pengeluaran terang | Pasangan terang untuk saldo negatif |

Prototype mempunyai 960 interaksi navigasi/overlay/timer. Pilihan dalam panel menutup panel sebagai simulasi; pilihan tersebut belum mengubah data form. Detail akun/aset tertentu menggunakan layar perwakilan untuk meninjau pola yang sama; katalog menyediakan detail/edit tersendiri untuk BBCA, BMRI, BBRI dan ARTO. Tombol simpan menuju state contoh dan tidak menulis transaksi nyata. Pencarian memakai query contoh `bank`, pemilih file adalah mock Android dan impor/ekspor belum memproses file sebenarnya.

Alur katalog dapat dibuka melalui **Lainnya > Pengaturan > Katalog saham Indonesia**. Ketuk simbol Arta di Beranda/Lainnya, atau **Pengaturan > Tentang Arta**, untuk melihat identitas dan preview loading. Rangkaian timer hanya demonstrasi gerak; implementasi nanti menunggu pekerjaan lokal yang sebenarnya dan tidak menambahkan durasi tunggu wajib.

## Keputusan penting yang terlihat dalam desain

- Lima tab: Beranda, Transaksi, Investasi, Akun, Lainnya. Pencatatan utama tetap tersedia saat offline.
- Transfer kas dan transfer aset dipisahkan dari pendapatan/pengeluaran serta pembelian/penjualan. Form investasi adalah pencatatan, bukan pengiriman order.
- Modal, valuasi, laba/rugi dan saldo kas dibedakan. Harga mempunyai sumber/tanggal dan state cache/tidak tersedia.
- Contoh Mandiri: Rp5.500 setiap tanggal 4, Rp6.000 pada hari terakhir bulan. Ini aturan pribadi yang diisi pengguna, bukan preset aktif bagi semua akun.
- Form berulang memuat frekuensi, tanggal mulai/akhir, mode otomatis/konfirmasi, dan pilihan tanggal tertentu/hari terakhir. Tersedia tindakan edit, jeda, lewati dan hentikan.
- Cicilan mempunyai jumlah periode, rincian bagian, sisa dan pembayaran. Saat ini seluruh datanya contoh.
- Tarif, potongan, dasar saldo, frekuensi dan tingkatan bunga diisi pengguna. Angka contoh 3% per tahun pada layar estimasi bukan tarif bank yang diverifikasi. Estimasi dibedakan dari penerimaan aktual.
- Reksa dana memakai unit dan NAB manual. Pembayaran dan pencairan yang belum terkonfirmasi diberi status tersendiri. Penjelasan domain lebih lanjut ada pada [panduan](../docs/PANDUAN.md).
- Backup lengkap dan CSV mempunyai tujuan berbeda. Pemulihan memiliki preview, konfirmasi penggantian data dan state file tidak valid.
- Katalog menyimpan semua kolom IDX selain No: kode, nama perusahaan, tanggal pencatatan, jumlah lembar dan papan. Detail saham membedakan jumlah lembar emiten dari kepemilikan pengguna.
- Skenario impor contoh: katalog awal 944; file 944 baris = 2 baru + 4 berubah + 938 tetap. Dua kode lama yang tidak muncul tetap disimpan sehingga katalog menjadi 946. Ini data ilustrasi prototype, bukan hasil perbandingan file IDX pengguna.
- Saldo bank/kas/e-wallet boleh negatif. Preview pengeluaran dan detail akun memperlihatkan tanda minus tanpa menghalangi penyimpanan.
- Logo Arta adalah vektor editable, dengan master/monokrom dan [aset handoff](branding/README.md). Loading memakai penekanan bergantian pada tiga bagian simbol, dengan pasangan statis untuk gerakan dikurangi.

## Tema, komponen dan ukuran

Tema gelap menjadi hasil utama sesuai permintaan terbaru. Koleksi semantik `Theme` mempunyai 18 variabel dalam mode **Dark** dan **Light**, termasuk peran terpisah untuk sheet dan tombol aksi. Seluruh 38 state fitur baru mempunyai pasangan terang, ditambah konteks Akun/Lainnya/Pengaturan terang. Bersama preview Beranda terang sebelumnya ada 42 state terang. Sisa layar versi lama belum semuanya mempunyai pasangan terang terpisah.

Ada 32 komponen native, 397 instance dan 11 text style. Lato Regular/Bold digunakan sebagai padanan visual; nama font asli Stockbit tidak dapat dibuktikan dari raster. Contoh Inter/Roboto hanya berada pada board pembanding. Field mempunyai contoh normal, focused, error dan disabled. Grafik garis/area, batang, donut, sumbu, legenda dan sparkline contoh dibuat sebagai layer/vector/text yang dapat diedit. Logo aplikasi menggunakan monogram vektor sendiri; logo bank/emiten pada desain masih memakai glyph/inisial. Pengambilan logo aset dari penyedia dan cache dilakukan saat implementasi.

Geometri v2: header 18 terpusat, tombol/input 48 dengan radius 4, list menu 64, row aset 68, pilihan kanan 20, chip outline visual 30 dengan target 48, tab underline 2, serta sheet abu dengan radius atas 16. Ringkasan memakai outline tipis dan latar halaman. Pagination bernomor tidak terlihat pada sumber; scroll dan pemilih periode menjadi acuan.

Ukuran utama 412 × 915; beranda tambahan 360 × 800. Contoh field dengan teks besar ada di halaman Foundations. Ini pemeriksaan rancangan, belum pengujian aksesibilitas Flutter pada perangkat fisik. Form implementasi harus dapat menggulir dan bertambah tinggi mengikuti ukuran teks.

Ekspor token dari FigCraft tersedia dalam [JSON](theme-variables.json) dan [Dart](theme-tokens.dart). File Dart tersebut hanya konstanta warna, bukan aplikasi Flutter.

## Preview

- [Beranda](previews/01-beranda.png)
- [Daftar transaksi](previews/02-transaksi.png)
- [Catat transaksi](previews/03-catat-transaksi.png)
- [Investasi](previews/04-investasi.png)
- [Jadwal akhir bulan](previews/05-akhir-bulan.png)
- [Estimasi bunga](previews/06-bunga.png)
- [Laporan](previews/07-laporan.png)
- [Backup](previews/08-backup.png)
- [Beranda terang](previews/09-preview-terang.png)
- [Android 360 px](previews/10-android-360.png)
- [Radio pilihan akun / bottom sheet](previews/11-pilih-akun.png)
- [Spesifikasi komponen v2](previews/12-spesifikasi-komponen.png)
- [Identitas Arta](previews/13-identitas-arta.png)
- [Tiga fase loading](previews/14-loading-arta.png)
- [Katalog saham](previews/15-katalog-saham.png)
- [Pratinjau impor gelap](previews/16-impor-preview.png)
- [Pratinjau impor terang](previews/17-impor-terang.png)
- [Pengeluaran dengan saldo minus](previews/18-saldo-minus.png)
- [Pengaturan terbaru](previews/19-pengaturan.png)

## Verifikasi dan batas hasil

Layer tree revisi diperiksa melalui MCP: 7.436 node, 3.175 node teks, tanpa respons terpotong. Pemeriksaan 79 state tambahan tidak menemukan elemen melewati parent atau font selain Lato. Semua tujuan navigasi pada dokumen ditemukan dan pemeriksaan missing fonts kosong. Seluruh state tambahan diekspor dan ditinjau melalui tujuh contact sheet; layar utama juga diperiksa pada ukuran lebih besar. Pemeriksaan kontras token pada 114 pasangan teks/chart/kontrol lulus; ini bukan audit aksesibilitas aplikasi yang sudah berjalan. [Laporan verifikasi](review-v3/verification.json) mencatat batas pemeriksaan.

File native, preview ringkas dan 79 ekspor tambahan di [review-v3](review-v3/index.json) disimpan di workspace. Ekspor 95 layar v2 tetap menjadi arsip pada `review-v2/`. Native sebelum perubahan tersedia pada [arsip v2](archive/Arta-v2-sebelum-logo-dan-impor.figcraft). Semua saldo, grafik, harga, tanggal dan isi form adalah contoh untuk review desain. Perhitungan, input teks, kalkulator, kamera/pemilih file, PIN, database, backup, impor/ekspor katalog, animasi Flutter dan harga daring belum diimplementasikan atau diuji sebagai aplikasi. Implementasi mengikuti [rancangan produk](../docs/RANCANGAN.md).
