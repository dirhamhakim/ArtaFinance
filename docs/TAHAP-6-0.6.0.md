# Arta 0.6.0+8 — desain baru dan pembanding IHSG

Penyimpanan tetap lokal. Tidak menambah login, backend, atau Supabase. **168 pengujian unit/widget lulus, analyzer bersih, dan uji langsung Yahoo untuk IHSG/pencarian IDX berhasil.** APK [0.6.0+8](../build/app/outputs/flutter-apk/arta-0.6.0-debug.apk) sudah dibuild atas permintaan pengguna; versi, tanda tangan dan aset riwayat harga terverifikasi. Lihat [identitas build](BUILD-0.6.0.json). Pengujian di komputer tidak menggantikan pengujian APK pada HP.

## Desain

Referensi berasal dari struktur elemen web Stockbit/Bibit yang diberikan pengguna, tanpa menyalin data akun ke proyek. Ikon Stockbit mencampurkan SVG dan Ant Design; beberapa bentuk Bibit cocok dengan Feather. Arta memakai satu keluarga **Feather Icons**, font Lato regular/bold, warna hijau dengan permukaan netral, hierarki angka yang jelas, kartu membulat, form terisi lembut dan tombol konsisten. BitSans tidak disalin.

Ringkasan mengutamakan kekayaan terhitung dan memisahkan saldo akun/investasi. Tombol akun pertama ditempatkan langsung di bawah ringkasan agar terlihat sebelum menu analisis. Kontras teks tombol utama diuji minimal 4,5:1 pada kedua tema. Ikon akun/transaksi mendapat latar lembut. Semua ilustrasi kucing diganti ilustrasi keuangan netral: dokumen, dompet, kartu, kalender, pencarian, dan lampiran. Ilustrasi digambar lokal dengan Canvas; tidak meminta jaringan atau izin tambahan. Logo dan loading Arta tetap dipakai. Tema gelap dan terang, penyamaran nominal, serta ukuran font sistem tetap didukung.

Feather Icons dari paket `feather_icons` berlisensi MIT; font ikonnya sekitar 82 KB. Lato Bold berasal dari Google Fonts dan mengikuti lisensi OFL yang sudah ada di aset. Lisensi paket pihak ketiga ikut mekanisme Flutter.

## Saham vs IHSG

Buka **Ringkasan > Saham vs IHSG** atau **Portofolio > Saham vs IHSG**. Pilih 1B, 3B, 6B, 1T atau Semua. Grafik memperlihatkan garis portofolio hijau dan IHSG biru dalam persen; keduanya mulai dari **0% pada penutupan pertama yang sama** di dalam periode pilihan. Selisih dilaporkan dalam poin persentase. Ketuk/geser grafik untuk tanggal dan return. Tombol mata juga menyembunyikan return dan garis.

Cakupannya seluruh **unit saham IDX di semua lokasi**, termasuk posisi yang sudah dijual ketika menghitung riwayat. Saldo bank, kas RDN, crypto, reksa dana dan transaksi kas biasa tidak dimasukkan. Jadi ini pembanding kinerja saham, bukan garis nilai kekayaan atau return seluruh rekening sekuritas beserta kas menganggur.

### Metode dan batas akurasi

Metode adalah **estimasi TWR yang dihubungkan pada setiap aktivitas investasi**, dengan angka tetap presisi (BigInt/desimal):

- Sebelum beli/jual, instrumen terkait dinilai pada harga eksekusi (`gross / quantity`, dikonversi IDR sesuai transaksi). Instrumen lain memakai close terakhir yang sudah diketahui. Perubahan nilai sebelum arus modal dihubungkan ke return sebelumnya.
- Pembelian dan saldo unit awal menambah modal, bukan keuntungan. Penjualan menarik modal; keuntungan dan fee tetap masuk kinerja. Setelah penjualan penuh, return yang sudah terbentuk tetap tersimpan; pembelian berikutnya dapat melanjutkan rantai.
- Perpindahan unit antarlokasi internal tidak menambah modal. Biaya unit/kas aktual mengurangi kinerja. Split mengubah unit dan harga per unit secara berlawanan, sehingga tidak menggandakan nilai.
- Setiap akhir hari, seluruh posisi dinilai pada harga penutupan terakhir yang tersedia. Harga terbaru manual/live tidak masuk pembanding. Harga masa depan tidak ditarik mundur.
- Default **tanpa dividen tunai**, agar pembandingan terhadap indeks harga jelas. Toggle **Sertakan dividen neto** memasukkan dividen aktual setelah fee yang tercatat. Dividen diperlakukan sebagai distribusi selama hari penerimaan dan dikeluarkan dari basket pada akhir hari. IHSG tetap indeks harga; jangan menyebut perbandingan mode ini sebagai perbandingan dua indeks total return.
- Hari pertama adalah baseline setelah penutupan; keuntungan/fee sebelum baseline tersebut tidak dihitung pada periode ini. Tanggal efektif ditampilkan, sehingga periode tidak berpura-pura memiliki data sebelum kepemilikan/harga tersedia.
- Jika harga yang diperlukan hilang setelah baseline, rantai return diberi celah dan tidak dipulihkan dengan menebak. Lengkapi data atau pilih periode baru dengan data lengkap. Harga terakhir dapat dibawa ke depan sesuai aturan cache, sehingga data basi belum tentu mencerminkan nilai pasar hari itu.

Ini **bukan TWR intraday penuh**: kita tidak mempunyai harga serentak seluruh saham pada setiap arus modal. Aktivitas pada tanggal yang sama mengikuti urutan jam/tanggal ledger. Akurasi bergantung pada harga, gross, fee, tanggal, transfer dan aksi korporasi yang benar-benar dicatat. Dividen terlambat pada saat basket bernilai nol dapat membuat return distribusi tidak dapat dihitung. Jangan memakai grafik ini sebagai jaminan investasi atau bukti kinerja yang diaudit.

Contoh uji: 1 lembar bernilai 100, lalu harga eksekusi jual menjadi 120 dengan fee 1; return bersih 19%, meski semua unit sudah dijual. Penambahan 50 lembar pada harga tetap tidak menciptakan return. Split 1:2 dari 1×100 menjadi 2×50 tetap 0%.

## Data IHSG dan pembaruan

Simbol Yahoo **`^JKSE`**, bukan `IHSG.JK`. Referensi bawaan diambil langsung dari endpoint harian dengan `period1/period2` dan `interval=1d`; `range=max` tidak dipakai karena responsnya dapat berubah menjadi bulanan. Metadata pada `assets/data/ihsg_meta.json` mencatat sumber, interval, tanggal unduh dan hash berkas gzip. Dataset awal berisi 8.915 sesi, 6 April 1990–18 November 2026, sekitar 72 KB terkompresi. Tanggal terakhir adalah respons sumber yang tersedia, bukan janji data hari berjalan sudah ada.

Ketika memiliki saham, pembaruan IHSG mengikuti pengaturan penutupan harian otomatis, hanya saat aplikasi aktif/tidak terkunci. Target harian memakai jendela konservatif setelah 18:00 WIB; parser juga memeriksa sesi sudah selesai + 15 menit. Tidak membuat baris untuk hari libur. Jika cache sudah tersedia, permintaan dimulai dari tanggal terakhir dikurangi tujuh hari untuk mengisi jeda panjang sekaligus menerima revisi dekat tanggal akhir. Tanpa cache tambahan, referensi bawaan tersedia dan permintaan awal memakai satu bulan. Pemeriksaan sukses disimpan per target; kegagalan otomatis diberi jeda satu jam, tombol manual minimal satu menit, serta backoff Yahoo ketika 429. Tombol refresh pada layar pembanding dapat meminta pembaruan secara manual. Offline/error mempertahankan riwayat.

SQLite naik menjadi **skema 5**, dengan tabel referensi `market_benchmarks` terpisah dari transaksi. Data IHSG tambahan disimpan per tanggal tanpa duplikat. Migrasi mempertahankan data finansial lama. Backup finansial tetap **schema 5**, menerima versi 1–5; referensi IHSG tidak ikut backup karena dapat dimuat lagi dari aset/pembaruan. Memulihkan backup finansial tidak menghapus cache publik IHSG yang masih valid.

## Saham baru / IPO

Katalog > **Cari saham online** meminta Yahoo hanya saat tombol Cari ditekan. Hasil dibatasi `EQUITY` dengan kode empat huruf berakhiran `.JK`; indeks, saham luar negeri, dan reksa dana tidak dimasukkan. Pilih hasil untuk menyimpan ke katalog lokal. Instrumen yang sudah ada tidak ditimpa. Nama/provider berasal dari hasil Yahoo, sehingga belum tentu memiliki semua kolom katalog resmi IDX.

Jika Yahoo belum mengenali IPO atau pencarian gagal, gunakan **Impor IDX** Excel/JSON atau **Tambah manual**. Harga kemudian memakai `KODE.JK`; riwayat sebelum IPO tidak dibuat-buat. Pencarian crypto tetap CoinGecko.

## Verifikasi

Aset referensi menggunakan kompresi gzip dengan ekstensi `.json.Z`. Pemeriksaan APK pertama menemukan bahwa Android Gradle membuka dan mengganti nama file `.gz`, sehingga path yang diminta aplikasi tidak tersedia. Ekstensi `.Z` mempertahankan isi terkompresi dan nama aset saat pengemasan. Pemeriksaan APK akhir mencocokkan nama dan checksum seluruh 928 aset harga serta referensi IHSG dengan sumbernya.

Laporan akhir: [VALIDASI-0.6.0.json](VALIDASI-0.6.0.json). Checklist manual tetap memakai [file testing yang lama](TESTING-APK-0.2.0.md). Seluruh 108 kasus menunggu pengujian pengguna di HP menggunakan APK 0.6.0. Simpan backup, lalu pasang sebagai pembaruan tanpa uninstall. Tidak menjalankan emulator atau memasang aplikasi pada perangkat.
