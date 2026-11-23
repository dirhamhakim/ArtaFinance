# Implementasi tahap 1 — Arta 0.1.0

Tanggal: 19 November 2026, Asia/Jakarta.

Catatan historis versi 0.1.0. Versi saat ini 0.2.0 sudah menambahkan jadwal dan cicilan; lihat [implementasi tahap 2](IMPLEMENTASI-TAHAP-2.md).

Dokumen ini menjelaskan fitur yang sudah ditulis di Flutter. `RANCANGAN.md` tetap merupakan spesifikasi keseluruhan produk; fitur di sana tidak otomatis sudah tersedia di aplikasi.

## Cakupan

- Akun bank, tunai, dompet digital, dan saldo tunai exchange/sekuritas, semuanya IDR.
- Saldo awal boleh negatif. Saldo awal tidak menjadi pemasukan.
- Pemasukan, pengeluaran, dan transfer dua akun dengan biaya opsional.
- Tanggal transaksi, kategori bebas untuk pemasukan/pengeluaran, dan catatan opsional.
- Edit dan hapus transaksi dengan perhitungan ulang saldo.
- Ringkasan saldo, grafik pemasukan/pengeluaran bulan kalender perangkat, daftar akun, dan pencarian transaksi berdasarkan kategori, akun, catatan atau tanggal.
- Tema gelap sebagai awal, tema terang, dan mengikuti perangkat; pilihan disimpan di SQLite.
- Logo Arta pada launcher dan splash Android, serta loading vektor Flutter. Animasi berhenti ketika data selesai dimuat; tidak menunggu internet. Reduced motion menampilkan logo statis.
- Ekspor JSON biasa, backup JSON terenkripsi, dan restore dengan pratinjau jumlah data.

Ini merupakan fondasi pencatatan. Belum ada pembelian/penjualan investasi, harga Yahoo/CoinGecko, impor Excel/JSON katalog melalui aplikasi, jadwal berulang/cicilan, bunga otomatis, multi-mata-uang, atau sinkronisasi. Dataset IDX di `assets/data/idx_stocks.json` belum menjadi tabel yang dapat diedit di aplikasi ini. Tahap berikutnya harus menambah migrasi dan format backup untuk tabel baru.

## Menjalankan proyek

1. Android SDK sudah ditemukan di profil Windows pengguna. Sambungkan ponsel dengan USB debugging aktif atau jalankan emulator sendiri.
2. Jalankan `.\scripts\flutter.ps1 -Task Get` untuk dependensi.
3. Jalankan `-Task Check`, lalu `-Task Test` untuk pemeriksaan.
4. Jalankan `-Task Build` untuk APK debug atau `-Task Run` untuk menjalankan pada perangkat.

Helper memakai SDK di `.tooling/flutter`, cache Pub di `.tooling/pub-cache`, dan JDK di `.tooling/jdk21` bila tersedia. Lokasi cache Gradle dapat dibaca dari `.tooling/gradle-cache-path.txt`; tanpa file tersebut, default-nya `.tooling/gradle`. Pada komputer ini cache Gradle dipindahkan ke folder sementara `C:\Users\User\AppData\Local\Temp\Arta-Keuangan-Gradle` karena drive proyek kehabisan ruang. Semua itu alat pengembangan lokal dan tidak dimasukkan ke APK atau menjadi lokasi database pengguna. Helper tidak menambah PATH sistem atau mengganti Java global. Jika memakai Flutter dari lokasi lain, gunakan SDK Flutter 3.50+ dengan Dart 3.14+ dan JDK yang kompatibel dengan Gradle proyek; sesuaikan helper bila diperlukan.

Flutter 3.50 memisahkan komponen Material menjadi paket resmi `material_ui`. Karena itu impor UI memakai paket ini sesuai [panduan migrasi Flutter](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui).

Build Gradle dibatasi dua worker dengan heap maksimum 2 GB dan kompilasi Kotlin dalam proses yang sama, agar lebih sesuai dengan komputer pengembangan yang RAM-nya terbatas. Ini konfigurasi alat build, bukan kebutuhan memori aplikasi Android. Daemon Gradle berhenti setelah menganggur satu menit.

Jika unduhan engine `arm64_v8a_debug` oleh Gradle terputus, tersedia helper opsional `.\scripts\cache-flutter-engine.ps1`. Helper ini memerlukan Python 3 hanya pada komputer pengembangan, mengunduh potongan byte dari server resmi Flutter, memeriksa checksum MD5 dari header Google Storage, dan mencatat SHA-256. Cache lokal baru diaktifkan sesudah file utuh diverifikasi. Aplikasi Android tidak memakai Python atau server tambahan. Tanpa cache ini, Gradle tetap memakai sumber Flutter biasa.

## Cara pakai

1. Tambahkan akun, misalnya Mandiri atau SeaBank. Masukkan saldo yang benar pada saat mulai mencatat. Contoh saldo minus: `-10.000`.
2. Tekan **Catat transaksi**. Pilih pemasukan atau pengeluaran, akun, nominal positif, kategori, tanggal, dan catatan bila perlu.
3. Untuk memindahkan uang ke akun lain, pilih **Transfer**, isi akun asal dan tujuan yang berbeda, nominal, serta biaya jika ada. Tambahkan dahulu akun tujuan bila belum ada.
4. Ketuk transaksi pada daftar untuk mengeditnya. Ikon tempat sampah meminta konfirmasi sebelum menghapus.
5. Gunakan **Pengaturan** untuk tema dan backup. Simpan cadangan di lokasi pilihan sendiri, terutama sebelum ganti HP atau menghapus aplikasi.

Saldo awal merupakan saldo sebelum transaksi paling awal yang akan dicatat. Jika ingin memasukkan riwayat lama, gunakan saldo sebelum riwayat tersebut; jangan memakai saldo hari ini lalu menambahkan kembali transaksi yang sudah membentuk saldo hari ini.

Nominal form menggunakan format Indonesia: `10000`, `10.000`, atau `10.000,50`. Titik berarti pemisah ribuan; koma berarti desimal. Nominal transfer/pemasukan/pengeluaran harus positif. Saldo akun tetap boleh menjadi minus sesudah transaksi. Saat ini satu transaksi tidak mendukung lampiran, split kategori, atau mata uang lain.

Pemilihan tanggal pada form dibatasi sampai hari ini. Jadwal masa depan akan dikelola melalui fitur berulang pada tahap berikutnya; tidak ada potongan otomatis berdasarkan nama bank. Contoh pribadi Mandiri Rp5.500 tanggal 4 dan Rp6.000 akhir bulan tetap dicatat manual dahulu. Aplikasi tidak menganggap kedua nominal tersebut aturan bank universal.

## Perhitungan

Nominal disimpan sebagai bilangan bulat sen dalam bentuk string desimal kanonis, lalu dihitung menggunakan `BigInt`. `0,10 + 0,20` tetap `0,30`; nominal tidak dikonversi ke `double`. Hanya rasio batang grafik yang dikonversi menjadi angka tampilan.

Saldo akun = saldo awal + pemasukan − pengeluaran − transfer keluar − biaya transfer + transfer masuk.

Contoh: Mandiri Rp1.000.000 mentransfer Rp200.000 ke saldo exchange dengan biaya Rp2.500. Mandiri turun Rp202.500; saldo exchange naik Rp200.000. Total saldo turun Rp2.500. Laporan pengeluaran mencatat Rp2.500, bukan Rp202.500. Pembelian crypto/saham dari saldo exchange belum tersedia.

Transfer tersimpan sebagai satu transaksi dengan dua referensi akun, sehingga kedua sisi mengikuti satu catatan. Edit/hapus juga memengaruhi kedua sisi. Saldo dihitung dari sumber transaksi dan saldo awal, tidak disimpan sebagai cache yang dapat berbeda sendiri.

Tanggal transaksi merupakan tanggal kalender lokal `YYYY-MM-DD`; waktu pembuatan menggunakan UTC. Laporan bulanan memakai tanggal transaksi. Riwayat diurutkan tanggal terbaru dahulu; transaksi pada tanggal sama memakai urutan penyimpanan.

## Penyimpanan dan backup

SQLite berada pada application-support directory privat aplikasi, bernama `arta.sqlite`. Versi skema awal: 1. Tabelnya `accounts`, `ledger_transactions`, dan `preferences`. Body domain disimpan sebagai JSON tervalidasi; ID dan referensi transaksi juga menjadi kolom relasional dengan foreign key SQLite. Drift menangani pembukaan dan transaksi database. Saat menambah fitur, buat migrasi eksplisit; jangan menghapus database pengguna.

Data SQLite lokal belum dienkripsi. Backup terenkripsi menggunakan AES-256-GCM dan PBKDF2-HMAC-SHA256 dengan 600.000 iterasi, salt acak dan nonce acak. Kata sandi tidak disimpan oleh aplikasi dan tidak dapat dipulihkan. Pengolahan JSON dan enkripsi berjalan di isolate agar tidak menghentikan animasi antarmuka. Backup biasa adalah JSON terbaca. Ukuran file backup dibatasi 25 MB, termasuk pembungkus enkripsi.

Backup versi 1 menyimpan seluruh data yang sudah diimplementasikan: akun, saldo awal, transaksi, ID, tanggal, catatan, biaya, dan preferensi tema. Belum ada tabel investasi/katalog/jadwal yang harus dicadangkan. Format dengan versi atau kolom yang tidak dikenal ditolak, sehingga fitur baru tidak dibuang diam-diam oleh versi aplikasi ini.

Restore:

1. Pilih file JSON melalui pemilih dokumen Android. File terenkripsi meminta kata sandi.
2. Aplikasi memvalidasi format, versi, nominal, tanggal, ID duplikat, dan relasi akun. Kata sandi salah atau file berubah tidak melanjutkan restore.
3. Periksa jumlah akun/transaksi pada konfirmasi.
4. Simpan cadangan data saat ini pada lokasi yang dipilih. Bila langkah ini dibatalkan, restore ikut batal. Cadangan sebelum restore mengikuti enkripsi file yang dipulihkan dan menggunakan kata sandi yang sama bila terenkripsi.
5. Penggantian seluruh data dilakukan dalam satu transaksi SQLite. Kegagalan penulisan membatalkan seluruh penggantian.

Android automatic cloud backup dinonaktifkan; pencadangan dilakukan melalui menu aplikasi. Backup/restore adalah pemindahan snapshot, bukan sinkronisasi atau penggabungan data antarperangkat. CSV laporan dan impor transaksi aplikasi lain belum tersedia.

## Pengujian

Suite menguji presisi desimal/angka besar, saldo minus, klasifikasi transfer/biaya, validasi tanggal dan referensi, edit/hapus transaksi, rollback restore saat SQL gagal, persistensi setelah database dibuka ulang, round trip JSON/enkripsi, kata sandi salah, file yang dimodifikasi, serta alur akun/transaksi/tema pada widget ponsel.

- `flutter test`: **15 pengujian lulus**, termasuk layar 360×800 dan 800×360 dengan skala teks 2×.
- Tampilan kosong, ringkasan gelap dan ringkasan terang dirender dengan Lato asli dan ikon Material, lalu diperiksa secara visual. Hasil ada di `build/ui-review/`.
- Analyzer: **tanpa temuan**.
- APK debug: **berhasil dibangun**, package `id.arta.arta`, versi `0.1.0+1`, Android minimal API 24 (Android 7), target API 36, ABI `arm64-v8a`, `armeabi-v7a`, dan `x86_64`.
- Identitas APK diperiksa: label **Arta**, ikon `arta_launcher`, dan tanda tangan **Android Debug** valid. File: `build/app/outputs/flutter-apk/app-debug.apk`, 173.705.424 byte. SHA-256: `ad4e0a976c6e66825efec2f6d4a9365ff1a224daef248ab927e5486bc5e539d6`.
- Salin APK ke HP Android dan buka file untuk memasang versi pengujian. Ukuran APK debug mencakup alat debugging dan beberapa ABI; ini belum ukuran rilis akhir yang dioptimalkan.
- Belum diuji pada perangkat Android fisik. Pemilih dokumen, pemasangan APK, splash sistem Android, dan siklus aplikasi pada perangkat perlu smoke test di HP. Widget test memverifikasi alur pencatatan dan tema, bukan dialog dokumen native Android.

## Urutan lanjutan

1. Transaksi berulang: tanggal bulanan dan hari terakhir bulan, kebijakan tanggal yang tidak ada, pembuatan kejadian tanpa duplikasi, serta konfirmasi terlambat saat aplikasi dibuka kembali. Tambahkan cicilan pada mesin jadwal yang sama.
2. Katalog IDX ke tabel lokal, seed awal 944 kode, lalu impor Excel/JSON dengan pratinjau, validasi dan aturan pembaruan. Simpan seluruh kolom sumber selain `No`; jumlah lembar tetap presisi.
3. Ledger investasi: saldo tunai platform, beli/jual, fee, lot/unit, transfer antarwallet, harga manual dan cache harga daring.
4. Bunga berdasarkan aturan yang diisi pengguna, serta laporan yang lebih lengkap.

Setiap tahap harus memperbarui backup dan pengujian sebelum dipakai untuk data nyata.
