# Hasil pengujian Arta — 21 November 2026

**Selesai untuk cakupan di bawah.** APK **0.7.1+10** terpasang pada Samsung A05s SM-A057F, Android 15. Semua pengujian Android memakai HP USB; tidak memakai emulator atau login Google. PIN/sidik jari tidak diuji ulang sesuai instruksi pengguna, yang menyatakan keduanya normal.

[APK final](../build/app/outputs/flutter-apk/arta-0.7.1-debug.apk) · [Identitas build dan SHA-256](BUILD-0.7.1.json) · [Hasil terstruktur](TESTING-HP-2026-11-21.json) · [Checklist utama](TESTING-APK-0.2.0.md)

## Hasil akhir

| Lapisan | Hasil | Bukti |
| --- | --- | --- |
| Unit dan widget, run final | **188 lulus, 0 gagal** | [Log final](../build/physical-device-0.7.1/host-tests-final.log) |
| Skenario native Android/SQLite pada paket QA terpisah | **13 lulus** | [Run awal](../build/physical-device-0.7.1/device-tests.log), [ulang P10](../build/physical-device-0.7.1/device-demo-retest.log) |
| Verifikasi backup demo dan hitungan finansial | **66 pemeriksaan lulus** | [Log](../build/physical-device-0.7.1/demo-verification.log) |
| Regresi sumber harga 404/429 dan parser | **35 lulus**; termasuk suite final | [Log](../build/physical-device-0.7.1/provider-isolation-tests.log) |
| Static analysis | **Bersih** | [Log](../build/physical-device-0.7.1/analyze-final.log) |
| Kasus manual pada APK normal | **29 catatan lulus** | Tabel kasus di bawah |

Angka tiap lapisan tidak dijumlahkan karena sebagian memeriksa alur yang sama.

## Perbaikan yang masuk APK

- Pilihan kategori pemasukan/pengeluaran tersedia kembali: daftar terpisah, pencarian, kategori khusus, penggunaan kembali kategori lama, serta draft masing-masing jenis transaksi. Transfer tidak meminta kategori.
- Mata dan loading di header atas dihapus. Kontrol privasi nominal berada pada card nilai dan tetap berlaku lintas halaman.
- Restore snapshot besar memakai satu transaksi SQLite dan validasi menyeluruh sebelum penulisan, tanpa memuat ulang seluruh riwayat untuk setiap transaksi. Skenario native backup demo 1,3 MB selesai sekitar **4,3 detik**.
- Error panel CSV ketika kembali ke Pengaturan setelah menggulir diperbaiki. Status buka/tutup panel memiliki PageStorageKey sendiri, terpisah dari posisi gulir. Panel komposisi/kepemilikan juga memiliki identitas terpisah.
- Sinkronisasi penutupan membedakan simbol hilang dan gangguan sumber. Respons 404 pada satu saham tidak menghentikan saham lain; gangguan Yahoo tidak menghentikan CoinGecko. Batas 12 request per putaran tetap berlaku.
- Keterangan analisis menjelaskan kantong debit sebagai aset tersendiri dan kartu terhubung tidak dihitung dua kali. Versi diagnosis startup sesuai versi aplikasi.

## Cakupan dan metode

- [x] SQLite privat, bootstrap, pembukaan ulang file dan integritas; CRUD, saldo minus, debit, liabilitas/piutang, kurs dan transfer dua biaya — unit serta Android P01–P03.
- [x] Kategori default/khusus, pencarian, edit, pemisahan pemasukan/pengeluaran, jadwal dan round-trip backup — unit/widget, Android P09 dan manual M04.
- [x] Dua belas frekuensi berulang, tanggal pendek/kabisat, zona waktu, konfirmasi/otomatis, jeda/lanjut/henti, cicilan, pembulatan dan riwayat transaksi yang dihapus — engine lengkap serta Android P04–P08.
- [x] Investasi seluruh jenis event, unit/lot, modal/laba, transfer unit/biaya unit, kurs historis dan harga/NAB — unit, demo lengkap, Android P10/P11.
- [x] Staking manual: penguncian pokok, permintaan/cair unstake, reward bebas/restake, biaya/slashing, dependensi dan arsip — unit, data demo dan Android P12.
- [x] Bunga flat/bertingkat/progresif, harian/bulanan, pajak, aktual, otomatis, duplikasi periode dan pembatalan — unit, demo dan Android P13.
- [x] Line/donut investasi, gabungan, noninvestasi, arus kas dan perbandingan TWR saham vs IHSG — widget seluruh scope serta tampilan native APK normal M12/M13.
- [x] JSON biasa/enkripsi melalui DocumentsUI, sandi salah, file rusak/versi baru, pembatalan cadangan wajib, CSV transaksi/kepemilikan/harga dan impor IDX Excel/JSON — manual Android dan pemeriksaan isi file/SQLite.
- [x] Harga/NAB CSV, pencarian Yahoo khusus IDX, pencarian ID crypto, harga live manual, penutupan UTC crypto dan penutupan saham/IHSG — request nyata pada HP. Seluruh 10 crypto default terverifikasi setelah API key dipasang.
- [x] Keyboard Samsung dan nominal desimal, kalender, dial 24 jam 23:45, struk JPEG melalui PhotoPicker Android, posisi Simpan di atas keyboard/bilah navigasi — manual M04. APK tidak meminta izin READ_MEDIA/READ_EXTERNAL_STORAGE.
- [x] Tema terang/gelap/sistem, portrait/landscape dan pembesaran teks — widget dan Android P08; kalender/jam/picker serta privasi nominal juga diperiksa pada APK normal.
- [x] Data awal dipulihkan, key tetap tersimpan, nominal kembali terlihat, otomatis harga aktif, mode pesawat mati, stay-awake USB dikembalikan, paket QA terpisah dibuang.
- [x] PIN dan sidik jari: **USER_REPORTED_PASS**, tidak diuji ulang oleh agen.

## Kasus manual pada APK normal

| ID | Status | Hasil aktual |
| --- | --- | --- |
| M01 | PASS | Normal APK 0.7.1+10 installed as update; original finances empty, header privacy/loading removed and card privacy retained. |
| M02 | PASS | Android document picker restore: mandatory prior backup saved, all 22 assets / 202 transactions / schedules / cards / investment extras including JPEGs match JSON exactly; auto price preference stays off. |
| M03 | PASS | Native JSON export saved through Android DocumentsUI; decode and comparison preserve every financial field including all three receipt images. |
| M04 | PASS | Transaksi pengeluaran Rp12.345,67, kategori Makan & Minum, 20 Nov 2026 23:45 Jakarta dan 1 JPEG tersimpan di SQLite offline. Total turun tepat Rp12.345,67. Keyboard Samsung, kalender, dial 24 jam dan PhotoPicker Android berfungsi tanpa izin galeri menyeluruh. |
| M05a | PASS | Backup terenkripsi disimpan lewat DocumentsUI, isi transaksi tidak bocor sebagai teks biasa. |
| M05 | PASS | Backup terenkripsi diekspor dan dipulihkan lewat DocumentsUI Android; seluruh isi tabel termasuk foto sama persis tanpa memperhitungkan urutan baris. Sandi salah tidak mengubah data. |
| M06-QA-Malformed.json | PASS | Restore QA-Malformed.json ditolak sebelum pratinjau, semua tabel tetap sama. |
| M06b | PASS | Backup schema999 ditolak; semua tabel tetap sama. |
| M07 | PASS | Pembatalan penyimpanan cadangan wajib membatalkan restore; 203 transaksi tetap tersimpan. |
| M08-transaksi | PASS | CSV transaksi: 275 baris = 203 transaksi + 46 event investasi + 26 bunga; foto tidak ikut CSV (tersedia di JSON). |
| M08-kepemilikan | PASS | CSV kepemilikan: 21 baris berhasil diekspor melalui Android. |
| M08-harga | PASS | CSV harga: 2998 baris berhasil diekspor melalui Android. |
| M09 | PASS | Pengaturan digulir, pindah Ringkasan lalu kembali: menu CSV dan ketiga ekspor berjalan. Bug PageStorage tidak muncul lagi pada APK perbaikan. |
| M10a | PASS | Impor Excel IDX asli melalui Android: 944 tetap, 0 baru/berubah, metadata tersimpan, transaksi dan unit investasi tidak berubah. |
| M10b | PASS | Katalog JSON menambah tepat 1 saham simulasi QATZ, termasuk tanggal IPO, jumlah lembar dan papan; pencarian lokal menemukannya offline. |
| M11 | PASS | Impor CSV menambah observasi NAB 1.560,25 pada 20 Nov; riwayat sumber lama tetap ada, nilai investasi naik Rp2.755 ke Rp40.167.378,63. Transaksi dan unit tetap. |
| M12 | PASS | Grafik portofolio/donut serta laporan gabungan, noninvestasi dan pemasukan-pengeluaran tampil offline. Gabungan Rp123.000.267,52 sesuai saldo + investasi; saldo negatif dijelaskan terpisah dari donut. |
| M13 | PASS | Perbandingan saham vs IHSG tampil offline: periode sama 3 Jun-18 Nov, TWR saham -5,40%, IHSG -11,67%, selisih +6,27 poin; basis awal 0%. |
| M14a | PASS | Pencarian Yahoo Finance BBCA di HP online mengembalikan PT Bank Central Asia Tbk sebagai idx:BBCA; tidak ada simbol luar IDX. |
| M14b | PASS | CoinGecko online mengembalikan ID crypto yang berbeda jelas; Chainlink dipilih dan ditambah satu kali. Katalog menjadi 960 tanpa mengubah holdings. |
| M15 | PASS | Harga terbaru manual: 15 observasi baru dari CoinGecko, Yahoo · terbaru (dapat tertunda). Transaksi/unit tetap, valuasi penutupan tidak berubah oleh harga live. |
| M16a | PASS | 155 observasi penutupan baru tersimpan dari Yahoo/CoinGecko. Harga crypto selesai UTC sampai 20 Nov, harga saham sesi selesai; transaksi/unit tidak berubah. |
| M17 | PASS | API key yang sebelumnya diberikan disimpan melalui form ke Android Keystore, terpisah dari backup. Pembaruan harian otomatis kembali aktif seperti kondisi awal. |
| M16b | PASS | Setelah Demo API key disimpan, semua 10 crypto default mempunyai penutupan UTC 20 Nov. Membuka ulang aplikasi dengan otomatis aktif melengkapi 3 instrumen yang tersisa; data dan key bertahan setelah restart. |
| M18 | PASS | Data finansial awal dipulihkan melalui restore Android dengan cadangan hasil uji tersimpan. Katalog kembali 944 saham + 10 crypto; akun/transaksi/jadwal/kartu uji hilang. API key dan pengaturan keamanan tidak dihapus. |
| M16c | PASS | Cache IHSG dari Yahoo Finance tersimpan sampai sesi 20 Nov; basis historis bawaan tetap tersedia offline. |
| M19 | PASS | Lima tab dapat dibuka pada APK final, empty state Aset/Transaksi tampil. Mata pada card menyimpan status hide di SQLite saat pindah tab, lalu dikembalikan visible; header tetap tanpa mata/loading. |
| M20 | PASS | Sesudah restore, API key masih terpasang dan pembaruan penutupan otomatis aktif. Key tetap berada di penyimpanan perangkat, tidak di file JSON. |
| M21 | PASS | Seluruh tabel finansial dan metadata cocok dengan backup sebelum demo. Backup akhir tidak memuat API key. Foto uji dan paket QA terpisah dibersihkan, mode pesawat mati, stay-awake USB kembali 0; aplikasi utama tetap terpasang. |

## Kondisi akhir HP

Data finansial sebelum pengujian memang kosong. Setelah pemulihan: tidak ada aset, transaksi, jadwal, kejadian, kartu atau event investasi uji; katalog kembali **944 saham + 10 crypto**. Integritas SQLite `ok`. Cache pasar dapat tetap tersimpan. API key yang diberikan pengguna kini terpasang melalui form dan disimpan terenkripsi oleh Android, terpisah dari JSON; pengaturan PIN/sidik jari dipertahankan.

Cadangan hasil pengujian ada di **Download/Arta-QA-20261121/QA-End-Test-Snapshot.json**. Data contoh asli juga tersedia di folder itu sebagai **QA-Demo-Full.json**, bila ingin melihat tampilan berisi data lagi.

## Batas pengujian

- [ ] Google Sheets CSV publik secara live: URL belum dikonfigurasi. Impor CSV lokal, parser dan pembatasan URL telah lulus.
- [ ] Reset destruktif pada paket utama HP: tidak dijalankan agar pengaturan keamanan pengguna tetap terjaga. Logika reset diuji otomatis; bootstrap penyimpanan baru diuji native pada paket QA.
- [ ] Perangkat/versi Android selain Samsung A05s Android 15. Teks besar pada skenario native menggunakan skala MediaQuery; bukan perubahan seluruh pengaturan font Samsung.

Gangguan 404/429 diuji memakai respons simulasi. Pengujian online tidak sengaja menghabiskan kuota. Pada pengujian awal, kolom key di HP masih kosong: harga publik sebagian berhasil, sebagian tetap memakai cache. Setelah key disimpan, seluruh crypto default berhasil dilengkapi saat aplikasi dibuka kembali.

Catatan bukti: tes CSV terlebih dahulu mereproduksi error pada kode lama sebelum lulus setelah perbaikan. P10 sempat memakai lokasi fixture yang salah pada paket QA dan lulus setelah fixture dipindahkan. Satu run yang bertumpang tindih dengan perubahan source serta percobaan tes paralel menghasilkan kegagalan sementara/SQLite DLL terkunci; **run final terpisah lulus 188/188**. Log percobaan disimpan di folder bukti.

[Bukti screenshot dan log](../build/physical-device-0.7.1/) · [Build log](../build/physical-device-0.7.1/build-final.log) · [Signature APK](../build/physical-device-0.7.1/signature.log)
