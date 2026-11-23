# Pengujian fisik Arta — 19 November 2026

Perangkat: Samsung Galaxy A05s SM-A057F, Android 15, terhubung melalui USB. Versi aplikasi: 0.2.1+3. Emulator tidak digunakan pada pengujian ini.

## Hasil awal pada APK normal

- [x] Pembaruan 0.2.0+2 ke 0.2.1+3 melalui `adb install -r`, tanpa uninstall/hapus data.
- [x] Startup masuk Ringkasan; berhasil kembali setelah force-stop dan dibuka ulang. Error penyimpanan versi lama tidak muncul pada dua pembukaan ini.
- [x] Nama akun kosong ditolak dengan `Isi nama akun.`.
- [x] Membuat akun QA Mandiri 100.000, QA Wallet 0 (Dompet digital), dan QA Minus -1.000. Saldo awal bukan transaksi baru. Nilai tersimpan diperiksa melalui salinan SQLite.

Database sebelum sesi tidak berisi akun/transaksi pengguna. Tiga akun QA di atas dibuat melalui UI untuk pengujian. Skenario otomatis memakai database baru di subfolder privat `device-qa`. Pada putaran akhir, APK uji memakai identitas `id.arta.arta.deviceqa` terpisah dari APK normal.

## Pengujian otomatis pada HP

Perintah:

```powershell
.\scripts\flutter.ps1 -Task DeviceTest -DeviceId SERIAL_HP
```

Ganti `SERIAL_HP` dengan hasil `adb devices -l`. Helper menolak ID emulator, memilih identitas APK QA, dan memakai `--no-uninstall`. Gunakan helper ini untuk tes perangkat, karena perintah Flutter integration test langsung secara default menghapus paket uji sesudah selesai. Skenario ada di [physical_device_test.dart](../integration_test/physical_device_test.dart).

**Status: 8/8 kelompok lulus pada satu putaran akhir.** Bukti hasil: `build/physical-device/device-qa/1795082036559/results.json` dan `build/physical-device/native-all-pass.log`. Pengujian menggunakan plugin direktori Android asli, SQLite berbasis file, dan isolate Android; tidak mengganti penyimpanan dengan database memori.

| ID | Cakupan | Hasil |
| --- | --- | --- |
| P01 | Direktori Android, bootstrap, buka ulang file SQLite | LULUS |
| P02 | UI akun minus dan validasi/simpan pengeluaran | LULUS |
| P03 | Ledger, transfer/biaya, edit/hapus, desimal, UI pencarian | LULUS |
| P04 | Dua jadwal Mandiri, konfirmasi bersamaan, lewati/hapus | LULUS |
| P05 | Jeda/edit/lanjutkan, tanggal 31, kalender, zona dan berhenti | LULUS |
| P06 | Cicilan dan pembulatan, aktual, lewati/hapus riwayat | LULUS |
| P07 | Backup file, enkripsi, kata sandi salah, JSON rusak, v1/v2 | LULUS |
| P08 | UI jadwal, tema, orientasi dan formulir panjang | LULUS |

## Batas cakupan

Pengujian melalui repository/model memverifikasi logika pada SQLite Android asli, tetapi tidak berarti semua langkah UI pada [26 kasus checklist](TESTING-APK-0.2.0.md) sudah dilakukan. Pemilih dokumen Android, akses file melalui URI, pembatalan dialog native, serta pengisian angka/kata sandi dengan keyboard diperiksa terpisah pada D01?D08. Semua kelompok D01?D08 lulus. Restart HP dan pergantian hari nyata belum diuji. Modul investasi/harga/impor IDX/bunga belum diimplementasikan pada APK ini.

## Koneksi HP

Sebelum pengujian offline: mode pesawat mati, Wi-Fi aktif. Untuk pengujian otomatis, mode pesawat diaktifkan dan Wi-Fi dimatikan sementara. Setelah sesi, keadaan semula sudah dikembalikan dan diverifikasi: mode pesawat 0 (mati), Wi-Fi 1 (aktif). Pengaturan jam/tanggal HP tidak diubah; tanggal historis pada pengujian hanya digunakan dalam data uji.

Panduan koneksi ada di [KONEKSI-HP-USB.md](KONEKSI-HP-USB.md). Perbandingan API gratis ada di [COINGECKO-GRATIS.md](COINGECKO-GRATIS.md).

## Alur file Android pada APK normal

- [x] D01: Memilih JSON lokal dan menyimpan cadangan wajib sebelum restore; 5 akun dipulihkan, database SQLite utuh.
- [x] D02: Ekspor JSON lewat dialog Simpan Android; file QA-NativeFull.json berhasil dipakai kembali.
- [x] D03: Pembaruan APK final mempertahankan seluruh 5 akun, 1 transaksi, dan preferensi, dibandingkan sebelum/sesudah melalui SQLite.
- [x] D04: Setelah pemasukan penanda 1 ke QA Wallet, restore QA-NativeFull.json menghapus penanda dan mengembalikan 5 akun tanpa transaksi; cadangan penanda tersimpan pada QA-AfterMarker.json.
- [x] D05: Validasi password pendek/tidak sama, penolakan password salah, serta restore password benar lulus. Snapshot setelah pemulihan terenkripsi cocok baseline.
- [x] D06: Pembatalan ekspor/impor dan cadangan wajib mempertahankan data. Transaksi penanda 1 tetap ada. JSON rusak ditolak dengan `File JSON backup tidak valid.`; versi asing ditolak dengan `Format atau versi backup belum didukung.`.
- [x] D07: Restore v1 lewat picker Android menghasilkan QA Legacy -Rp1.100 dengan tema terang. Kembali ke v2 menghasilkan snapshot yang sama dengan baseline lima akun, tanpa transaksi.
- [x] D08: Keadaan awal kosong dipulihkan melalui QA-BeforeUI.json, kemudian aplikasi dihentikan dan dibuka ulang. Ringkasan berhasil tampil dengan 0 akun/transaksi/jadwal dan integritas SQLite OK.

File berada di folder lokal `Download/Arta-QA-20261119`. File contoh yang disalin dengan ADB awalnya belum terindeks oleh Android; sesudah pemindaian MediaScanner, file tampil dan bisa dipilih. Ini dicatat sebagai langkah persiapan fixture, bukan bug aplikasi.

## Catatan proses pengujian

Pada percobaan integration test pertama, runner Flutter memakai nama paket Arta normal dan menghapusnya pada akhir tes sesuai default SDK. Tiga akun QA yang baru dibuat ikut terhapus. Database sebelum sesi kosong; tidak ada catatan pribadi yang hilang. APK normal dipasang kembali. Helper akhir memakai identitas QA terpisah dan `--no-uninstall`; putaran akhir terverifikasi lulus. Hindari menjalankan integration test langsung dengan konfigurasi default terhadap aplikasi yang berisi data.

Dua kegagalan harness awal diperbaiki dengan menunggu operasi SQLite asli selesai dan menutup keyboard sebelum menggulir. Putaran akhir 8/8 lulus tanpa mengubah fitur aplikasi. Pengujian lokal akhir: **48/48 lulus**, analyzer **No issues found**. Identitas dan tanda tangan APK normal final sudah diverifikasi; APK bernama Arta dengan package id `id.arta.arta`, bukan paket QA.

## Hasil akhir dan bukti

Selesai: `2026-11-19T17:29:57.808289+07:00`. **8/8 kelompok integration test HP dan 8/8 pemeriksaan alur file/aplikasi normal lulus**, selain 48/48 unit/widget test. Tidak ditemukan kegagalan aplikasi baru pada cakupan yang dijalankan. BUG-001 tidak muncul pada versi 0.2.1 di perangkat ini; akar masalah tepat versi 0.2.0 tetap belum dikonfirmasi dari log lamanya.

- APK normal 0.2.1+3 tetap terpasang dan dibuka pada Ringkasan. Paket sementara `id.arta.arta.deviceqa` sudah dihapus setelah buktinya disalin.
- Data utama kembali kosong seperti sebelum sesi. Cadangan QA tetap tersedia di `Download/Arta-QA-20261119`; 13 file JSON juga disalin ke `build/physical-device/phone-backups`.
- Log proses utama selama alur backup tidak berisi baris `E/flutter`; bukti ada di `build/physical-device/arta-final-runtime.log`.
- Hasil cleanup: `build/physical-device/cleanup-result.json`. Bukti layar akhir: [Ringkasan kosong setelah buka ulang](../build/physical-device/final-cold-reopen.png). Bukti kompatibilitas: [QA Legacy -Rp1.100](../build/physical-device/native-legacy-minus-1100.png).
- Password backup **data QA** adalah `ArtaUji2026!`. Ini password contoh untuk file pengujian, bukan password akun pengguna.
- Login Google tidak diuji. Tidak ada fitur aplikasi baru yang ditambahkan selama sesi pengujian; perubahan pendukung berada pada harness/konfigurasi pengujian. Pengembangan fitur berikutnya dihentikan sesuai arahan pengguna.

Restart HP, pergantian hari nyata, seluruh kombinasi input UI, dan urutan persis 26 kasus manual belum diselesaikan. Sebagian tanggal/jam pada integration test memakai clock terkontrol di kode tes; jam HP tidak diubah. Font 2? disimulasikan pada Flutter di HP, sedangkan orientasi landscape diminta melalui Android.

Automasi picker disesuaikan agar tombol Kembali benar-benar menutup dialog dan baris file digulir ke area yang terlihat sebelum diketuk. Kegagalan harness tersebut tidak dihitung sebagai bug aplikasi.
