# Pengujian Arta di Samsung A05s — 20 November 2026

Sesi pengujian selesai dengan tiga temuan. APK terpasang: **0.6.0+8**, paket `id.arta.arta`, Samsung SM-A057F, Android 15. Pengujian melalui ADB pada HP fisik; emulator, build, pemasangan ulang APK, login Google, dan perubahan kode aplikasi tidak dilakukan.

[Checklist lama sudah diperbarui](TESTING-APK-0.2.0.md): **18 lulus, 2 gagal, 50 sebagian, 1 terhalang, 37 belum**, dari 108 kasus. Dua kasus gagal, T25 dan T77, menunjuk masalah tata letak yang sama (BUG-003). Bug versi footer dan preferensi restore juga tercatat meskipun alur finansial terkait dapat berjalan. Kasus sebagian tetap tidak dicentang agar tidak dianggap sudah selesai.

Hotspot dan data seluler dipertahankan. Bibit dan Stockbit hanya disalin sebagai paket APK; keduanya tidak dibuka atau diambil screenshotnya.

Data finansial awal kosong dan integritas SQLite `ok`. Data pengujian diberi nama QA. Cadangan awal dan bukti rinci tersimpan di `build/physical-device-0.6.0/`.

## Temuan yang perlu diperbaiki

### BUG-002 — Versi pada Pengaturan tertinggal

- Aktual: footer menampilkan `Arta · 0.4.0`, sementara paket terpasang terverifikasi 0.6.0+8.
- Dampak: pengguna sulit memastikan versi APK dari dalam aplikasi.
- Sumber: teks tetap di `lib/screens/home_screen.dart:816`.
- Bukti: `settings-backup.xml` dan screenshot sesi.
- [Screenshot versi footer](testing/bukti/2026-11-20/settings-backup.png).
- Prioritas: rendah. Belum diperbaiki dalam sesi pengujian.

### BUG-003 — Tombol simpan tertutup navigasi Samsung

- Buka form transaksi dalam posisi portrait, gunakan navigasi Android tiga tombol, sembunyikan keyboard, lalu gulir ke paling bawah.
- Aktual: tombol `Simpan transaksi` berada pada y=2220–2355, sedangkan bilah navigasi Samsung mulai sekitar y=2265. Sebagian tombol tertutup dan sulit ditekan.
- Dampak: alur pencatatan dasar terhambat. Pengujian dapat dilanjutkan dengan keyboard tetap terbuka dan tombol digulir ke atas keyboard.
- Bukti: `expense-save-position.png`, `save-keyboard-hidden.png`, `save-with-keyboard.png`.
- [Screenshot tombol tertutup](testing/bukti/2026-11-20/expense-save-position.png).
- Prioritas: tinggi. Belum diperbaiki; perlu uji ulang inset bawah di HP fisik.

### BUG-004 — Restore mengaktifkan kembali pembaruan harga otomatis

- Matikan `Simpan penutupan harian otomatis`, simpan, lalu pulihkan backup finansial yang valid.
- Aktual: preferensi `market_daily_auto=false` hilang setelah restore dan switch kembali aktif. API key tetap tersimpan terpisah.
- Sumber: daftar preferensi yang dipertahankan pada restore di `lib/repositories/finance_repository.dart:614` masih menyebut `market_auto`, bukan `market_daily_auto`.
- Dampak: pembaruan otomatis dapat berjalan kembali meskipun sebelumnya dimatikan pengguna.
- Bukti: `restore-auto-preference-reset.png/.xml`, perbandingan database sebelum/sesudah.
- [Screenshot preferensi setelah restore](testing/bukti/2026-11-20/restore-auto-preference-reset.png).
- Prioritas: sedang. Switch dimatikan kembali untuk melanjutkan pengujian deterministik; kode belum diperbaiki.

## Paket referensi yang disalin

| Aplikasi | Lokasi | Jumlah APK | Ukuran |
| --- | --- | ---: | ---: |
| Bibit | `design/references-apk/bibit/` | 3 | 49.872.719 byte |
| Stockbit | `design/references-apk/stockbit/` | 3 | 165.912.831 byte |

Manifest salinan `extraction.json` pada masing-masing folder memuat checksum. Tidak ada analisis tampilan aplikasi referensi dalam sesi ini.

## Hasil yang sudah diamati di HP

Tabel berikut menyatakan skenario yang benar-benar dijalankan, bukan menyimpulkan bahwa seluruh 108 kasus sudah lulus. Kasus dengan banyak cabang tetap membutuhkan pemeriksaan lanjutan sebagaimana dicatat di checklist utama.

| Area | Hasil aktual |
| --- | --- |
| Startup dan penyimpanan | Masuk Ringkasan dan berhasil setelah force-stop/buka ulang. Database awal dan snapshot pengujian memiliki integritas `ok`; peringatan startup versi lama tidak muncul. |
| Akun | Lima akun dasar dibuat lewat UI, termasuk saldo awal −1.000. Nama kosong ditolak. Saldo awal tidak dihitung sebagai pemasukan. |
| Transaksi | Pengeluaran 150.000 membuat saldo Mandiri −50.000; pemasukan 20.000 menjadi −30.000. Transfer 5.000 dengan biaya 1.000 menghasilkan Mandiri −36.000 dan Wallet 5.000. Toggle biaya bekerja. |
| Edit/hapus | Mengubah pengeluaran menjadi 100.000 menghasilkan saldo 14.000. Batal hapus mempertahankan transaksi; hapus terkonfirmasi menghasilkan Mandiri 114.000. |
| Desimal dan pencarian | Pemasukan 0,10 + 0,20 lalu pengeluaran 0,30 mengembalikan saldo tepat −1.000. Pencarian kategori, catatan, akun, hasil kosong, dan pengosongan pencarian sesuai. |
| Arus kas | Pemasukan 20.000,30 dan pengeluaran 1.000,30; pokok transfer tidak masuk arus kas. Grafik dua garis menampilkan nilai dan tanggal yang dipilih. |
| Chart aset | Sebelum perubahan transaksi lanjutan: kas 8.814.500, investasi 61.350.000, gabungan 70.164.500. Ketiga line chart dan donut cocok dengan perhitungan independen. Saldo negatif ditampilkan terpisah sebagai pengurang. |
| Kartu dan kurs | Kartu QA Debit Jago Syariah menampilkan saldo sumber 1.000.000. Tidak menambah total kekayaan. Akun USD 100 dengan kurs 16.000 tampil senilai 1.600.000 dalam chart. Pembuatan kartu dan kurs pada skenario ini melalui fixture backup, bukan form. |
| Jadwal | Fixture otomatis terbatas membuat enam transaksi pada 4/31 Januari, 4/29 Februari, 4/31 Maret 2024. Refresh berulang tidak menggandakan transaksi. |
| Konfirmasi jadwal | Rencana 7.000 diubah menjadi transaksi aktual 7.500 pada 11 April. Jatuh tempo tetap 10 April; aturan tetap 7.000. |
| Cicilan | Varian total 10 dibagi tiga secara manual: 3,33 + 3,33 + 3,34. Jumlah tepat 10, tiga kejadian selesai, tanpa transaksi pokok tambahan. Aturannya berasal dari fixture. |
| Bunga | Saldo 3.650.000, APR uji 10%, basis 365, pajak 20%. Hari pertama bruto 1.000/pajak 200/neto 800. Setelah diposting, estimasi hari kedua bruto 1.000,22/pajak 200,04/neto 800,18. Keduanya dikonfirmasi lewat UI. |
| Staking | ETH total 1,005; aktif 0,305, pending 0,1, bebas 0,6; reward aktual 0,01 dan slashing 0,005. APR 5% hanya estimasi. Pending tidak otomatis cair meskipun perkiraan tanggal lewat. Klaim manual 0,1 membuat pending 0 dan bebas 0,7, tanpa menambah unit total. |
| TWR dan IHSG | Data awal: saham +11,11%, IHSG +2,96%, selisih +8,15 pp, basis 0%. Pembelian tambahan 100 BBCA senilai 900.000 tetap menghasilkan return +11,11%. Jual seluruh 200 lembar senilai 2.000.000 dengan biaya 1.000 mempertahankan hasil +11,06% meskipun unit menjadi nol. |
| IHSG online | Tombol pembaruan berhasil menyimpan sampai 19 November 2026. Grafik membandingkan sampai tanggal bersama tersebut; sesi 20 November yang masih berjalan tidak masuk. |
| Harga crypto | Tombol harga terbaru menyimpan dua quote live BTC/ETH, terpisah dari valuasi utama. Pembaruan penutupan menyimpan 14 titik tanggal 13–19 November; quote 19 November memakai waktu sumber 20 November 00:00 UTC. Harga live tanggal 20 tidak berubah menjadi close. |
| Riwayat referensi | Grafik BTC yang memuat riwayat panjang berhasil digambar pada APK terpasang. Ini juga memeriksa pembacaan aset riwayat terkompresi di Android. |
| Katalog | Excel IDX dikenali 944 saham, tetap 944, baru/berubah/tidak ditemukan 0; pembaruan berhasil. Yahoo BBCA.JK dan BBCA berhasil; AAPL tersaring. Pencarian CoinGecko berhasil dan BCH ditambahkan sebagai data QA. Sepuluh bawaan: BTC, ETH, USDT, USDC, SOL, HYPE, XAUT, PAXG, BNB, XRP. |
| Tema dan privasi | Tema terang/gelap serta donut diperiksa secara visual. Mata saldo memakai titik, dan chart/komposisi disembunyikan saat nominal disembunyikan. Seluruh layar sensitif dan persistensi privasi belum diuji lengkap. |
| Keamanan | Sidik jari asli pemilik HP berhasil membuka Arta melalui dialog biometrik Android. Membatalkan sensor tetap mengunci data. PIN aplikasi pada keypad khusus berhasil sebagai cadangan; percobaan PIN salah tidak membuka aplikasi. Kunci uji kemudian dinonaktifkan. Pengujian penundaan setelah banyak kegagalan belum dilakukan. |
| Izin | Paket terpasang tidak meminta izin baca galeri/penyimpanan umum. Alur memilih, menyimpan, dan memulihkan foto belum dijalankan. |
| Backup biasa | Ekspor native berhasil; JSON valid dan API key tidak ada di file. Batal picker, batal preview, batal cadangan wajib, JSON rusak, dan versi tidak didukung mempertahankan baris finansial. Restore fixture schema 5 berhasil. |
| Backup terenkripsi | Ekspor AES-256-GCM/PBKDF2-HMAC-SHA256 menghasilkan 451.933 byte. File asli hasil HP berhasil didekripsi dan divalidasi di laptop: 11 akun, 10 transaksi, 4 jadwal, 10 kejadian, 1 kartu, 11 aktivitas investasi, 2 posting bunga. Sandi salah tidak mengganti data. |

Backup terenkripsi kemudian berhasil dipulihkan di HP setelah cadangan wajib disimpan. Seluruh koleksi finansial di atas dibandingkan dengan isi backup dan cocok. Hapus data Arta menghasilkan keadaan baru dengan saldo nol, tanpa akun/transaksi/jadwal/kartu/PIN QA dan field API key kosong. Backup lengkap biasa lalu dipulihkan ke kondisi tersebut; setelah force-stop/buka ulang, akun, transaksi, jadwal, kejadian, kartu, investasi, staking, bunga, katalog dan kurs tetap cocok persis. Data QA dibersihkan lagi sesudah hasil ini disimpan.

## Keadaan akhir

- Arta ditinggalkan terbuka pada Ringkasan, saldo nol, tanpa akun, transaksi, jadwal, kejadian, kartu atau kunci QA. Sepuluh crypto bawaan kembali; BCH tambahan QA sudah terhapus.
- API key pengguna dimasukkan kembali secara privat sesudah uji reset dan disimpan dalam keadaan tersembunyi. Pembaruan penutupan kembali pada default aktif. API key dan PIN tidak dicantumkan dalam laporan maupun backup finansial.
- Cadangan QA tetap tersedia di folder Download/Arta-QA-20261120 pada HP dan `build/physical-device-0.6.0/` di laptop. Backup plain lengkap berukuran **338.783 byte**, terenkripsi **451.933 byte**. File berisi data QA, bukan data pribadi awal pengguna.
- Pemeriksaan akhir: mode pesawat 0, data seluler 1, `TetheredState` teramati. Tidak ada perintah mengubah hotspot, data seluler, atau mode pesawat.
- Seluruh **137 checksum sumber aplikasi** tetap sama. Tidak ada perbaikan fitur, build, atau pemasangan APK baru.
- Pemindaian 153 artefak teks sesi tidak menemukan API key asli. Screenshot yang menyimpan pengaturan key selalu dalam keadaan tersamarkan.
- Hasil mesin: [JSON sesi pengujian](TESTING-HP-2026-11-20.json). [Bukti Ringkasan akhir](testing/bukti/2026-11-20/final-ready-summary.png).

Satu tangkapan awal tepat sesudah hapus data diambil saat splash belum selesai. XML aksesibilitas lama dan pembacaan database sebelum file siap dibuang dari penilaian hasil. Helper diperketat untuk hanya memakai dump aksesibilitas baru dan header SQLite yang valid; verifikasi keadaan kosong menggunakan `reset-fresh-confirmed.sqlite`, bukan tangkapan awal tersebut. Ini kendala pengambilan bukti, bukan temuan data lama bertahan setelah reset.

Oracle angka menggunakan Python Decimal, pemeriksaan baris SQLite, dan data sumber IHSG. Generator fixture dan pemeriksa backup berada di folder build pengujian. Nama akun dan harga sintetis diberi penanda QA agar tidak menyerupai data nyata pengguna. Dua ekspektasi awal pada harness dikoreksi: nilai investasi setelah pembelian naik 1.000.000, sedangkan kekayaan bersih naik 100.000; bunga hari kedua mengikuti saldo setelah posting hari pertama. Keduanya bukan bug aplikasi.

Pencarian Yahoo pertama dengan BBCA sempat memberi hasil kosong. Pengulangan dengan BBCA.JK dan BBCA berhasil. Tidak ada bukti cukup untuk menyimpulkan bug tetap; kondisi ini dicatat untuk pemantauan.

## Batas pengujian

Mode pesawat, mematikan internet/hotspot, dan restart HP tidak dilakukan untuk menjaga sambungan laptop. Sesi ini tidak membuktikan semua cabang dari 108 kasus. Matriks lengkap jadwal/frekuensi/zona waktu, transaksi foto, utang/piutang, transfer mata uang, split/dividen, tier bunga, CSV/Sheets, batas file, migrasi semua versi lama, font besar, landscape, dan percobaan PIN berulang masih memerlukan pengujian. Detail subpemeriksaan yang sudah dilakukan dicatat terpisah dari hasil penuh di checklist utama.
