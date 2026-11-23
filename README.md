# Arta

Aplikasi keuangan pribadi Android dengan Flutter, SQLite/Drift, serta tema gelap dan terang. Pencatatan berjalan offline tanpa backend atau akun login.

**Terbaru: 0.7.2+11.** Menu **Pengaturan → Pencatatan → Kategori** menambahkan pengelolaan kategori pemasukan/pengeluaran: tambah tanpa transaksi, ubah nama beserta label riwayat/jadwal, arsip/aktifkan kembali, pencarian dan validasi duplikat. Kategori tersimpan lokal dan masuk backup JSON/terenkripsi schema 6; backup versi 1–6 didukung. **201/201 pengujian unit/widget lulus; analyzer bersih.** Pengujian HP 0.7.2 belum dijalankan karena perangkat sedang dipakai pemiliknya.

- [APK 0.7.2](build/app/outputs/flutter-apk/arta-0.7.2-debug.apk) · [identitas dan hasil pengujian](docs/BUILD-0.7.2.json)
- [Panduan kategori 0.7.2](docs/PATCH-0.7.2.md) · [Panduan desain 0.7.0](docs/TAHAP-7-0.7.0.md) · [preview Flutter](design/flutter-0.7.0/README.md)
- [Checklist HP lengkap, termasuk kategori T143–T149](docs/TESTING-APK-0.2.0.md)

## Riwayat implementasi

**0.7.1+10** memperbaiki pilihan kategori pada form transaksi, header/privasi, restore besar, ekspansi CSV Pengaturan dan isolasi kegagalan sumber harga. **188 pengujian unit/widget, 13 skenario native Android dan 29 kasus manual lulus** pada sesi Samsung A05s Android 15; menu pengelolaan kategori di Pengaturan baru ditambahkan pada 0.7.2. Lihat [laporan HP 21 November](docs/TESTING-HP-2026-11-21.md).

**0.7.0+9** menerapkan desain FigCraft: font Bit Sans offline, dua tema, master SVG, lima tab ikon, card bertingkat dan panel bawah; serta DOKU, kantong Debit, 12 pilihan berulang, biaya transfer kedua pihak dan reset PIN melalui sidik jari. Versi ini melewati 182 pengujian unit/widget.

Source **0.6.0+8** meredesain tema, ikon, kartu, menu dan form; mengganti ilustrasi kucing dengan ilustrasi keuangan; menambah IHSG offline dan penutupan otomatis, grafik dua garis estimasi return saham vs IHSG, serta pencarian saham baru khusus IDX lewat Yahoo. SQLite menjadi skema 5; backup finansial tetap schema 5. **APK debug 0.6.0 sudah dibuild; siap diuji pengguna di HP.** Lihat [panduan 0.6.0](docs/TAHAP-6-0.6.0.md) dan [laporan validasi](docs/VALIDASI-0.6.0.json).

Source 0.6.0 telah melewati **168 pengujian unit/widget**, analyzer bersih, migrasi SQLite v1–v4 ke v5, serta uji jaringan langsung Yahoo untuk IHSG dan pencarian saham IDX. Preview tema gelap/terang tersedia di `build/ui-review/*-0.6.0.png`; hasil USB versi 0.6.0 kemudian dicatat pada [laporan 20 November](docs/TESTING-HP-2026-11-20.md).

Versi **0.5.0+7** menambahkan line chart/donut gabungan aset, portofolio dan saldo akun; dua garis arus kas; sepuluh crypto bawaan termasuk BNB dan XRP; staking manual; serta penutupan harian otomatis dengan harga terbaru manual yang dipisahkan. Referensi offline dari file pengguna mencakup 918 saham dan 10 crypto; 26 saham tanpa data dibiarkan tanpa harga. **150 pengujian unit/widget lulus dan analyzer bersih. APK 0.5.0 tidak dibuild terpisah; seluruh fiturnya masuk APK 0.6.0.** Lihat [panduan 0.5.0](docs/TAHAP-5-0.5.0.md) dan [hasil validasi source](docs/VALIDASI-0.5.0.json).

Arta tahap 2 menyediakan akun IDR, saldo awal termasuk minus, pemasukan, pengeluaran, transfer dengan biaya, edit/hapus transaksi, pencarian, grafik arus kas bulanan, tema gelap/terang, serta backup/restore JSON biasa atau terenkripsi. Tahap 2 menambahkan transaksi berulang harian/mingguan/bulanan/tahunan, akhir bulan, mode otomatis/konfirmasi, jeda/lanjutkan, riwayat anti-duplikasi, dan pembagian cicilan pengeluaran. Versi 0.2.1 menambahkan jalur direktori Android cadangan dan diagnostik startup. Pada uji USB Samsung A05s Android 15, aplikasi berhasil masuk Ringkasan dan berhasil dibuka ulang; error startup versi 0.2.0 tidak muncul pada uji tersebut.

Versi **0.4.0+6** menambahkan portofolio saham/crypto/reksa dana, beli/jual dan perpindahan unit dengan modal rata-rata, dividen/reward/split, impor katalog IDX Excel/JSON, harga Yahoo/CoinGecko/manual/CSV, kurs dan akun multi mata uang, aturan bunga pengguna, serta ekspor CSV. Lihat [panduan lengkap 0.4.0](docs/TAHAP-4-0.4.0.md) dan [80 kasus pengujian manual](docs/TESTING-APK-0.2.0.md). **APK debug 0.4.0 sudah dibuild; identitas dan tanda tangannya terverifikasi. Siap diuji pengguna di HP.**

Kode 0.4.0 telah melewati **121 pengujian unit/widget dalam satu suite akhir**, analyzer bersih, pemeriksaan Kotlin/JVM, smoke test parser harga langsung, serta pencocokan Excel IDX asli 944 saham. Lihat [laporan validasi](docs/VALIDASI-0.4.0.json). Versi ini belum dipasang atau diuji di HP.

Utang/piutang dan belanja kartu kredit dicatat melalui akun bertanda serta transfer pokok, tanpa menggandakan arus kas; perhitungan amortisasi dan siklus tagihan tidak ditebak otomatis. Jadwal dan bunga otomatis diproses saat aplikasi aktif/dibuka. Belum ada worker/notifikasi Android atau sinkronisasi akun platform/perangkat. Pencatatan lokal tidak membutuhkan backend atau login.

Versi 0.2.2 menambahkan toggle biaya transfer, tombol mata sandi backup, dan penyamaran nominal. **0.3.0+5** menambahkan kunci opsional sidik jari/PIN Arta, jam transaksi 24 jam, lampiran foto struk, ilustrasi kucing, serta kartu debit Jago tertaut rekening. **APK debug 0.3.0 sudah dibuat setelah persetujuan pengguna; versi dan tanda tangan terverifikasi.** Pengujian versi ini di HP belum dijalankan. Lihat [panduan, batas verifikasi dan checklist tahap 3](docs/TAHAP-3-0.3.0.md).

- [Cara memakai jadwal dan cicilan versi 0.2.0](docs/IMPLEMENTASI-TAHAP-2.md)
- [Patch dan batas verifikasi 0.2.1](docs/PATCH-0.2.1.md)
- [Perubahan UI, checklist, dan pekerjaan berikutnya 0.2.2](docs/PATCH-0.2.2.md)
- [0.3.0: keamanan, jam, foto, ilustrasi dan kartu](docs/TAHAP-3-0.3.0.md)
- [0.4.0: investasi, katalog, harga, kurs, bunga dan CSV](docs/TAHAP-4-0.4.0.md)
- [Checklist pengujian APK dan laporan hasil](docs/TESTING-APK-0.2.0.md)
- [Hasil pengujian Samsung A05s melalui USB](docs/TESTING-HP-2026-11-19.md)
- [Menghubungkan Samsung A05s melalui USB untuk debugging](docs/KONEKSI-HP-USB.md)
- [CoinGecko gratis dan rencana batas pemakaian](docs/COINGECKO-GRATIS.md)
- [Fondasi dan cara menjalankan proyek](docs/IMPLEMENTASI-TAHAP-1.md)
- [Seluruh rancangan produk](docs/RANCANGAN.md)
- [Desain FigCraft dan referensi](design/README.md)
- [Panduan katalog saham IDX](docs/KATALOG-SAHAM-DAN-LOGO.md)

## Menjalankan

SDK lokal yang disiapkan: Flutter 3.50.0 / Dart 3.14.0 dan Eclipse Temurin JDK 21. Android minimal API 24. Dependensi dikunci melalui `pubspec.lock`.

```powershell
# Dari D:\Aplikasi Keuangan
.\scripts\flutter.ps1 -Task Get
.\scripts\flutter.ps1 -Task Check
.\scripts\flutter.ps1 -Task Test
.\scripts\flutter.ps1 -Task Build
.\scripts\flutter.ps1 -Task Run
# Untuk pengujian otomatis di HP fisik, isi serial dari adb devices -l:
.\scripts\flutter.ps1 -Task DeviceTest -DeviceId SERIAL_HP
```

`Run` memerlukan HP Android yang sudah tersambung untuk debugging. Pengujian Android memakai HP fisik melalui USB tanpa emulator. `Test` memakai satu worker untuk mengurangi penggunaan memori laptop. `DeviceTest` memakai APK QA terpisah dan `--no-uninstall`; gunakan helper tersebut untuk menjalankan integration test perangkat.

APK terbaru dan hasil verifikasi ada pada [laporan build 0.7.2](docs/BUILD-0.7.2.json). Pasang sebagai pembaruan tanpa uninstall untuk mempertahankan data. Backup baru schema 6; format v1–v6 dapat dipulihkan. Key CoinGecko diisi melalui pengaturan perangkat, tidak ditanam di APK. APK 0.6.0 tetap tersedia sebagai arsip pada [identitas build lamanya](docs/BUILD-0.6.0.json).

Riwayat APK 0.3.0: [arta-0.3.0-debug.apk](build/app/outputs/flutter-apk/arta-0.3.0-debug.apk), dengan [catatan build](docs/BUILD-0.3.0.json) dan 75 kasus Dart/Flutter unik terverifikasi melalui suite 74 kasus serta rerun tujuh kasus UI final. APK lama tetap disimpan.

Riwayat APK 0.2.2: [arta-0.2.2-debug.apk](build/app/outputs/flutter-apk/arta-0.2.2-debug.apk), dengan [catatan build](docs/BUILD-0.2.2.json) dan 55 kasus unit/widget terverifikasi melalui suite dan rerun terarah. Versi tersebut belum diuji di HP.

Riwayat APK 0.2.1: [arta-0.2.1-debug.apk](build/app/outputs/flutter-apk/arta-0.2.1-debug.apk). **48 test unit/widget dan 8 kelompok integration test di Samsung A05s Android 15 lulus; analyzer bersih.** Alur pemilih file Android, backup terenkripsi, pembatalan, penolakan JSON dan restore v1/v2 juga diuji. Cakupan dan batasnya ada pada [laporan HP](docs/TESTING-HP-2026-11-19.md); seluruh 26 urutan manual belum diulang persis. Identitas APK dicatat pada [catatan build 0.2.1](docs/BUILD-0.2.1.json), dan hasil historis 0.2.0 pada [catatan build tahap 2](docs/BUILD-TAHAP-2.json). Gunakan backup sebelum memperbarui aplikasi; skema SQLite dimigrasikan otomatis dan backup v1 masih dapat dipulihkan.

## Struktur

```text
lib/
  controllers/    # ChangeNotifier, status operasi dan koordinasi UI
  database/       # SQLite melalui Drift, skema dan transaksi atomik
  models/         # Akun, jadwal, investasi, bunga, kurs dan desimal presisi
  repositories/   # Baca/tulis data lokal
  routes/         # Navigasi formulir
  screens/        # Ringkasan, akun, transaksi, pengaturan dan formulir
  services/       # Jadwal, bunga, katalog XLSX/JSON, harga HTTP, CSV dan backup
  theme/         # Warna dan ukuran komponen dari referensi
  widgets/       # Logo vektor serta animasi loading
test/            # Ledger, SQLite, backup dan interaksi widget
integration_test/ # Pengujian plugin Android, SQLite file, dan UI pada HP fisik
```

Font Lato disertakan beserta [lisensi SIL OFL](assets/Lato-OFL.txt). Logo Arta digambar sebagai vektor; loading mengikuti proses data yang sebenarnya dan menghormati pengaturan pengurangan animasi perangkat.
