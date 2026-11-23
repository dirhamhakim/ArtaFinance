# Rancangan aplikasi keuangan pribadi

> **Keputusan terbaru 21 November 2026:** baca [perubahan kebutuhan untuk coding dan FigCraft](PERUBAHAN-KEBUTUHAN-2026-11-21.md). Dokumen tersebut menggantikan aturan yang bertentangan di bawah: Debit menjadi kelas bersaldo sendiri, biaya transfer mencakup pengirim/penerima, pilihan berulang berjumlah 12, dan ringkasan memakai Aset/Liabilitas/Total. Untuk UI gunakan [pemetaan Bibit/Stockbit terbaru](design/PEMETAAN-ROMBAK-UI-2026-11-20.md). Status versi implementasi lama pada dokumen ini bersifat historis; versi terpasang 0.6.0+8 dan hasil pengujiannya dicatat di [laporan HP 20 November](TESTING-HP-2026-11-20.md). Perubahan 21 November belum diimplementasikan.

Status: spesifikasi keseluruhan produk dan riwayat keputusan. Implementasi kode terkini **0.4.0+6** mencakup investasi, impor katalog, harga, kurs, bunga, utang/piutang dan CSV; lihat [cakupan, cara pakai dan batas aktual tahap 4](TAHAP-4-0.4.0.md). APK 0.4.0 belum dibuild. Beberapa rincian spesifikasi di bawah tetap merupakan arah pengembangan, termasuk amortisasi dan siklus kartu kredit otomatis.
Terakhir diperbarui: 19 November 2026, Asia/Jakarta.

Frontend: [referensi Stockbit dan tema terang/gelap](design/REFERENSI-STOCKBIT.md), [brief untuk FigCraft](design/BRIEF-FIGCRAFT.md), dan [token visual usulan](design/tokens.json). [Desain native FigCraft dan panduan review](../design/README.md) revisi v3 sudah dibuat: 174 layar/state dan 15 flow, termasuk logo/loading, impor/ekspor katalog IDX dan saldo minus, dengan pasangan gelap/terang untuk alur tambahan. Belum merupakan implementasi aplikasi Flutter.

## Keputusan pengguna

- Android dengan Flutter; data utama berada di SQLite melalui Drift.
- Tidak memakai Express, Supabase, PostgreSQL, login, atau hosting pada tahap ini.
- Pencatatan, laporan, jadwal, dan perhitungan investasi berjalan offline.
- Saldo akun noninvestasi (bank, kas, e-wallet dan akun pembayaran sejenis) boleh negatif. Saldo tidak cukup bukan alasan menolak pencatatan.
- Logo aplikasi vektor dan prototype loading yang mengikuti logo sudah dibuat dalam varian terang/gelap. Aset SVG/PNG/Android tersedia; logo dan animasi loading Flutter sudah ditambahkan pada tahap 1. Lihat [identitas dan loading](design/IDENTITAS-DAN-LOADING.md).
- Internet hanya diperlukan untuk mengambil harga/logo. Logo disimpan dalam cache.
- Yahoo Finance diuji lebih dahulu untuk harga penutupan saham harian terakhir.
- Google Sheets/GOOGLEFINANCE merupakan kandidat cadangan, bukan integrasi otomatis yang telah dipastikan berhasil.
- Reksa dana Bibit menggunakan input manual atas unit dan NAB/unit yang benar-benar dikonfirmasi.
- Aturan akun, biaya bank, pajak, dan transaksi berulang diisi pengguna. Tidak membuat potongan otomatis berdasarkan nama bank/kartu.
- Pengguna memakai SeaBank, Mandiri (Livin', kartu Debit GPN Gold), dan Jago Syariah.
- Platform lain: Bibit, Stockbit, Floq, Triv, Tokocrypto, MetaMask, RedotPay, Bybit ID, Pyypl, dan Getplu.
- Platform dicatat sebagai tempat menyimpan akun/aset; belum berarti tersedia sinkronisasi dengan platform tersebut.
- Kebutuhan terdekat jadwal: biaya/potongan bank bulanan. Saat ini tidak ada cicilan aktif; fitur cicilan tetap masuk rancangan.
- Pengguna mengonfirmasi potongan Mandiri Rp5.500 setiap tanggal 4 dan Rp6.000 setiap akhir bulan. Keduanya contoh aturan pribadi yang dibuat pengguna, bukan preset wajib. Label pajak/biaya mengikuti pilihan pengguna.
- Alur Berulang/Cicilan mengikuti pola Money Manager Android agar familiar. Bunga disediakan sebagai fitur umum yang parameternya diisi pengguna.

## Struktur kode yang diusulkan

```text
lib/
  core/                 # Tanggal, desimal, kesalahan, pengaturan
  database/             # Tabel Drift, migrasi, transaksi SQLite
  models/               # Model domain
  repositories/         # Akses data lokal dan adapter harga
  services/             # Ledger, jadwal, investasi, bunga, backup
  controllers/          # State layar dan interaksi pengguna
  screens/              # Halaman
  widgets/              # Komponen tampilan bersama
docs/
  RANCANGAN.md
  PANDUAN.md
```

Tidak membutuhkan routes HTTP. Navigasi halaman dipisahkan dari logika transaksi.

## Buku transaksi dan ketepatan angka

- Pisahkan akun penyimpanan (bank, kas, RDN, exchange, wallet), instrumen (IDR, USD, USDT, BTC, saham, reksa dana), dan kepemilikan.
- Transfer antar akun sendiri memindahkan aset; tidak menambah pendapatan atau pengeluaran konsumsi. Biaya transfer menjadi komponen terpisah.
- Pembelian investasi menukar kas dengan unit aset; penjualan menukar unit dengan kas. Nilai penjualan dipisahkan dari laba/rugi.
- Pembelian, penjualan, biaya, dan perpindahan yang terkait disimpan dalam satu transaksi database.
- Saldo dihitung dari catatan transaksi. Cache saldo dapat dibuat untuk kecepatan dan harus dapat dibangun ulang.
- Saldo akun noninvestasi adalah nilai bertanda dan boleh minus sejak saldo awal, transaksi baru, transaksi terjadwal maupun edit/hapus transaksi historis. Izinkan pengeluaran dan transfer yang melewati saldo tersedia; jangan memasang validasi `saldo >= 0`, menjepit hasil ke nol atau menonaktifkan tombol simpan karena saldo negatif. Nominal komponen pengeluaran/transfer tetap positif; arah transaksi menentukan penambahan/pengurangan saldo. Field saldo awal/penyesuaian dapat merepresentasikan nilai bertanda.
- Saldo negatif dipertahankan pada database, cache, perhitungan ulang, laporan, ekspor dan restore. Kekayaan bersih memakai kontribusi saldo bertanda; jangan mengubahnya menjadi nilai absolut atau membuat kewajiban/pengeluaran tambahan otomatis yang menghitung jumlah yang sama dua kali. Pencatatan minus tidak menginstruksikan pembayaran bank atau membuktikan fasilitas overdraft.
- Izin minus ini berlaku untuk saldo akun noninvestasi. Tidak memperluas aturan unit saham/crypto/reksa dana menjadi short selling. Pembaruan saldo negatif juga tidak otomatis mengenakan bunga/penalti; aturan bunga/biaya tetap mengikuti input pengguna.
- Nilai uang dan kuantitas tidak memakai floating point untuk perhitungan keuangan. Gunakan representasi desimal eksak; serialisasikan sebagai string kanonis saat backup. Perhatikan batas integer SQLite untuk token dengan presisi besar.
- Modal rata-rata tertimbang diusulkan sebagai metode awal. Simpan detail pembelian untuk audit dan perubahan metode di masa depan.
- Transfer aset mempertahankan modal historis. Kepemilikan dengan modal yang belum diketahui tidak menghasilkan klaim laba berbasis modal nol.
- Perubahan tanggal/nominal transaksi historis harus menghitung ulang bagian kepemilikan/laporan yang terpengaruh.
- Saldo awal bukan pemasukan periode berjalan. Impor data investasi lama harus menghindari pencatatan nilai akun investasi dan isi portofolionya dua kali.
- Kurs historis transaksi dan kurs valuasi terakhir disimpan terpisah. Kekurangan kurs ditampilkan, bukan diam-diam dianggap 1:1.

## Transaksi berulang

### Perilaku referensi Realbyte Android yang telah diverifikasi

- Pengaturan Repeat berada di bagian tanggal form transaksi; pengguna memilih frekuensi lalu menyimpan.
- Secara default, transaksi muncul pada tanggal yang dijadwalkan. Ada pilihan menampilkannya sejak awal bulan.
- Jadwal masa depan dapat dilihat dalam daftar jadwal.
- Menghapus aturan berulang tidak menghapus transaksi yang sudah terbentuk.
- Dokumentasi ini menerangkan perilaku publik, bukan seluruh algoritma internal atau semua variasi versi aplikasi.

### Perilaku aplikasi yang diusulkan

Form: jenis transaksi, akun asal/tujuan jika transfer, nominal, kategori/subkategori, catatan, tanggal mulai, frekuensi, interval, serta tanggal akhir atau jumlah kejadian opsional.

- Pada form transaksi, sediakan pilihan **Berulang / Cicilan** di bagian tanggal, mengikuti penempatan pada Money Manager. Pengelolaan seluruh aturan ada di **Lainnya > Pengaturan > Transaksi berulang**; nama akhir disesuaikan bahasa antarmuka.
- Pada pengulangan bulanan, sediakan menu **Tanggal tertentu** dan **Hari terakhir setiap bulan**. Akhir bulan adalah tanggal kalender terakhir, tidak otomatis digeser karena akhir pekan atau hari libur.
- Contoh pribadi pengguna: pengeluaran dari Mandiri Rp5.500 pada tanggal 4 setiap bulan dan pengeluaran Rp6.000 pada hari terakhir setiap bulan; nama/kategori diisi pengguna. Pencatatan otomatis dipilih saat pengguna membuat aturan, sehingga tidak meminta pengisian ulang tiap bulan.
- Akhir Februari mengikuti 28/29 sesuai tahun; April 30; Januari 31. Aturan tidak diubah menjadi tanggal 30 atau 31 permanen.
- Dukung harian, mingguan, bulanan, tahunan, dan setiap N periode.
- Aturan bulan mempertahankan tanggal asal: 31 Januari -> akhir Februari -> 31 Maret. Sediakan pilihan eksplisit akhir bulan.
- Gunakan zona waktu akun/jadwal, default Asia/Jakarta; simpan tanggal efektif terpisah dari waktu pencatatan.
- Mode **catat otomatis saat jatuh tempo** cocok untuk biaya tetap yang diatur sendiri oleh pengguna.
- Mode **minta konfirmasi** cocok untuk nominal berubah atau transaksi yang belum pasti terjadi.
- Mode tampil awal bulan hanya menunjukkan rencana/proyeksi; label dan saldo aktual harus jelas terpisah.
- Aplikasi hanya mencatat. Pengaturan jadwal tidak mengirim uang atau memerintahkan bank melakukan debit.
- Saat aplikasi dibuka/resume, proses seluruh kejadian yang sudah jatuh tempo sampai hari ini. Jadwal yang diproses beberapa kali tidak boleh membentuk transaksi ganda.
- Setiap kejadian memiliki identitas unik berdasarkan aturan dan urutan kejadian. Transaksi, status kejadian, dan progres jadwal disimpan atomik.
- Kejadian yang sengaja dilewati/dihapus disimpan statusnya agar tidak muncul lagi saat catch-up.
- Sediakan jeda, lanjutkan, lewati sekali, ubah satu kejadian, serta ubah kejadian mendatang.
- Perubahan aturan berlaku mulai kejadian yang dipilih; riwayat yang sudah tercatat tidak ditulis ulang otomatis.
- Notifikasi lokal merupakan pengingat. Keberhasilan pencatatan tidak bergantung pada notifikasi atau proses background berjalan tepat waktu.
- Jika HP mati/force-stop, notifikasi dapat terlambat/tidak muncul. Catch-up saat membuka aplikasi menjamin kelengkapan pencatatan jadwal, bukan ketepatan waktu notifikasi.

## Cicilan

Referensi Realbyte Android: memilih Installment dari bagian tanggal, memasukkan jumlah bulan, melihat urutan cicilan serta sisa dan totalnya. Contoh di dokumentasi membagi total pembelian menjadi bagian bulanan; tagihan kartu memiliki siklus dan tanggal pembayaran tersendiri.

Usulan aplikasi membedakan:

1. **Pembagian pengeluaran berkala**: satu total dibagi ke N transaksi terjadwal, dengan label 1/N sampai N/N. Tidak mencatat total sekali lagi sebagai pengeluaran tambahan.
2. **Utang sebenarnya**: pembelian/pencairan membentuk kewajiban. Pembayaran pokok mengurangi kewajiban, bunga/biaya menjadi pengeluaran. Jangan mencatat pembelian penuh dan semua pembayaran pokok sebagai pengeluaran yang sama dua kali.

Form harus menyebut nominal yang dimasukkan sebagai total atau nominal per periode. Pembulatan dialokasikan agar jumlah seluruh bagian persis sama dengan total. Dukung uang muka, pembayaran parsial, pelunasan awal dan perubahan jadwal secara eksplisit tanpa mengubah riwayat pembayaran lama. Fitur perhitungan kredit kompleks tidak diasumsikan tersedia pada versi awal.

## Bunga dan potongan akun

- Tidak ada preset aktif yang membentuk transaksi otomatis hanya karena pengguna memilih SeaBank/Mandiri/Jago Syariah.
- Seluruh pengguna dapat mencatat pemasukan bunga dan potongannya secara manual atau memakai aturan opsional yang mereka aktifkan.
- Sediakan menu **Bunga akun** untuk memilih akun dan mengisi parameter sendiri. Tidak mengambil tarif bank sebagai nilai aktif tanpa input pengguna. Tampilkan preview bruto/potongan/neto dan tanggal sebelum mengaktifkan aturan.
- Bedakan biaya administrasi rekening, biaya kartu, penalti saldo, pajak bunga, serta pendapatan bunga/bagi hasil. Nama kategori dapat diubah pengguna.
- Biaya tetap boleh memakai transaksi berulang umum; pajak bergantung bunga lebih tepat mengikuti transaksi bunga jika pengguna memilih perhitungan otomatis.
- Aturan opsional menyimpan tanggal mulai berlaku, batas saldo, tarif tahunan, cara menerapkan tingkatan (seluruh saldo atau progresif), dasar saldo, basis hari, frekuensi kredit, serta pembulatan dan pajak yang dapat diatur.
- Pisahkan perkiraan bunga dari bunga yang benar-benar masuk. Hanya nilai terkonfirmasi/catatan otomatis yang diaktifkan pengguna memengaruhi saldo aktual.
- Satu catatan bunga dapat memuat bruto, pajak, dan neto; saldo bertambah sebesar neto, bukan bruto ditambah neto.
- Perubahan transaksi historis menghitung ulang estimasi terkait, bukan mengubah bunga aktual yang sudah dikonfirmasi tanpa tindakan pengguna.
- Perkiraan bunga membutuhkan riwayat saldo lengkap; jangan menjanjikan angka sama persis dengan bank bila mutasi, tarif, atau aturan pembulatan belum lengkap.

Temuan bank sebagai referensi, bukan tarif yang dipaksakan:

- Mandiri memisahkan biaya kartu dan biaya rekening. Kartu Gold GPN tercantum Rp5.500/bulan. Halaman tarif mencantumkan Tabungan NOW Rp6.000/bulan dan Tabungan Rupiah Rp13.000/bulan. Jenis kartu/Livin' belum menentukan produk rekening pengguna atau tanggal debitnya.
- Halaman bunga Mandiri menampilkan tarif nol pada kelompok saldo rendah untuk Tabungan Rupiah/NOW. Tetap perlu memastikan produk, periode, dan mutasi aktual sebelum menyesuaikan aturan pribadi.
- FAQ SeaBank menjelaskan bunga harian berdasarkan saldo akhir hari sebelumnya. Kebijakan tingkatan dapat berubah; tidak menetapkan satu persentase permanen.
- Kantong Jago Syariah dengan akad Wadiah dicantumkan tanpa imbalan; produk Mudharabah memiliki mekanisme berbeda. Jangan menerapkan bunga Jago konvensional ke Jago Syariah.

## Harga dan logo

- Katalog saham Indonesia menggunakan seed JSON dari Excel IDX pengguna: 944 kode unik, unduhan 18 November 2026. Parser Flutter telah dicocokkan dengan file asli untuk kelima kolom; beberapa nama tetap terpotong sesuai sumber. Pencarian lokal dibatasi katalog IDX yang disimpan di SQLite; Yahoo dipakai untuk harga. Mapping seluruh simbol dan kelengkapan pasar belum diverifikasi. Lihat [implementasi tahap 4](TAHAP-4-0.4.0.md).
- Pengguna dapat memperbarui katalog melalui **Pengaturan > Katalog saham & instrumen > Impor IDX**: Excel `.xlsx` atau JSON katalog. Impor lokal menyediakan preview, validasi dan penggabungan atomik. ID instrumen, riwayat, kepemilikan dan koreksi manual dipertahankan; kode absen tidak dihapus/delisting. Ekspor katalog JSON terpisah dari backup lengkap sudah tersedia pada kode 0.4.0.
- Simpan semua kolom Excel IDX selain `No`: kode, nama perusahaan, tanggal pencatatan, jumlah lembar saham (`shares_count`) dan papan pencatatan. Jumlah lembar tetap masuk database/ekspor/backup walau belum dipakai fitur. Gunakan INTEGER 64-bit nonnegatif di SQLite dan string digit dalam JSON; data tidak tersedia tetap `null`/nilai lama, bukan nol. Jumlah saham emiten terpisah dari unit kepemilikan pengguna dan pembaruannya tidak menghasilkan transaksi atau penyesuaian unit otomatis.
- Yahoo: uji pengambilan harga penutupan sesi yang sudah selesai untuk saham pengguna. Gunakan close biasa untuk valuasi, bukan adjusted close. Uji simbol seperti BBCA.JK, akhir pekan, hari libur, respons kosong, dan pembatasan request.
- Simpan tanggal sesi harga, waktu pengambilan, mata uang, dan sumber secara terpisah. Hari ini tidak selalu merupakan tanggal harga terakhir.
- Jangan menyebut data intraday sebagai harga penutupan final. Ambil sesi sebelumnya bila sesi terbaru belum selesai/dipastikan final.
- GOOGLEFINANCE: dokumentasi Google membatasi akses data historis melalui Sheets API/Apps Script dan tidak menjamin dukungan semua simbol. Atribut closeyest adalah penutupan sebelumnya, bukan otomatis penutupan terbaru setelah pasar hari ini tutup. Cadangan ini perlu uji nyata; jangan menjanjikan otomatisasi yang belum terbukti.
- Input manual/impor tabel harga milik pengguna tetap tersedia apabila sumber daring gagal.
- CoinGecko Demo memiliki kuota, bukan unlimited. Gabungkan ID koin dalam request. Default refresh 5 menit hanya ketika halaman portofolio aktif, dengan cache, jeda refresh manual, dan backoff pada 429.
- Simpan harga terakhir saat offline/gagal; jangan menggantinya dengan nol. Jangan mengubah harga beli historis.
- NAB/unit reksa dana diisi manual dengan tanggal NAB. Unit baru mengikuti konfirmasi Bibit, bukan estimasi pembagian nominal order yang masih pending.
- Logo saham menggunakan pola URL yang diberikan pengguna: `https://assets.stockbit.com/logos/companies/{KODE_SAHAM}.png`, misalnya `BBCA.png`; sufiks `.JK` hanya pada simbol harga Yahoo. Unduh seperlunya ke cache HP, bukan seluruh logo/server storage. Jika belum tersedia/gagal, tampilkan kode/inisial. Pola URL terpusat dapat diganti; belum ada jaminan antarmuka publik yang stabil.
- API key harga pribadi dapat diatur di perangkat; jangan membundel satu key rahasia bersama untuk distribusi publik. Pengaturan publik/berkas .env dalam APK tidak menjamin kerahasiaan key.

## Backup, ekspor, dan restore

- Backup lengkap: JSON berversi yang dapat dipaketkan dalam arsip terenkripsi, mencakup akun, kategori, aset, transaksi dan komponennya, jadwal dan status setiap kejadian, cicilan, aturan bunga, harga/kurs, pengaturan, serta lampiran bila ada.
- Simpan UUID, relasi, urutan kejadian, zona waktu, presisi desimal, versi skema, dan waktu ekspor. Jadwal yang telah diproses tidak boleh dijalankan ulang setelah restore.
- Ekspor CSV untuk transaksi/kepemilikan/harga sebagai tabel analisis. CSV transaksi saja bukan backup lengkap dan tidak memulihkan seluruh pengaturan.
- Gunakan snapshot konsisten/transaksi baca ketika membuat backup; jangan menyalin file SQLite yang sedang ditulis tanpa penanganan WAL/snapshot.
- Restore memvalidasi format, versi, relasi, duplikasi ID, serta angka sebelum mengganti data secara atomik. Kegagalan restore tidak boleh mengubah data lama.
- Buat backup data yang sedang dipakai sebelum restore. Versi awal restore menggantikan satu kumpulan data; tidak otomatis menggabungkan dua perangkat.
- Tawarkan backup ke lokasi yang dipilih pengguna melalui pemilih dokumen Android. Salinan di penyimpanan internal aplikasi saja tidak cukup menghadapi uninstall/HP rusak.
- Tidak ada sinkronisasi otomatis antar perangkat pada rancangan lokal ini. Menyimpan backup ke folder cloud adalah penyalinan file, bukan sinkronisasi konflik transaksi.

## Pemeriksaan sebelum menyatakan aplikasi selesai

- Transfer/pembelian/penjualan dan fee tidak menggandakan kekayaan atau pengeluaran.
- Saldo noninvestasi minus: saldo awal -Rp100.000 dapat disimpan; saldo Rp100.000 dengan pengeluaran Rp150.000 menjadi -Rp50.000. Transfer Rp150.000 dari saldo Rp100.000 dengan fee Rp5.000 menghasilkan -Rp55.000 pada sumber dan +Rp150.000 pada tujuan; perubahan total kedua akun hanya -Rp5.000. Jadwal otomatis tetap tercatat saat menghasilkan minus. Edit transaksi mundur, perhitungan ulang, laporan dan backup/restore mempertahankan tanda dan nilai yang sama.
- Catch-up setelah beberapa bulan, buka aplikasi berulang, hapus satu kejadian, jeda, dan perubahan jadwal tidak menimbulkan duplikasi.
- Tanggal 29-31, tahun kabisat, akhir bulan, dan perubahan zona waktu diuji.
- Kasus penerimaan pengguna: jadwal Mandiri menghasilkan tepat satu Rp5.500 pada tanggal 4 dan satu Rp6.000 pada tanggal kalender terakhir tiap bulan; Februari biasa/kabisat diuji. Buka ulang dan restore backup tidak menggandakan kedua kejadian.
- Penjumlahan cicilan sama persis dengan total; pembayaran pokok dan bunga terpisah.
- Bunga bertingkat, perubahan tarif efektif, pembulatan, pajak dan mutasi mundur diuji dengan angka contoh eksak.
- Backup/restore mempertahankan data, presisi dan progres jadwal; backup rusak ditolak tanpa kehilangan data.
- Harga stale, API gagal, hari libur, serta NAB manual tidak merusak saldo transaksi.
- Uji di Android nyata untuk notifikasi, resume setelah force-stop, backup, dan akses harga.
- Flutter/Dart belum terdeteksi pada PATH dan lokasi umum yang diperiksa di komputer ini; SDK diperlukan sebelum build/analyze APK. Belum ada pengujian aplikasi Android atau integrasi harga nyata.

## Referensi resmi

- [Realbyte Android: Repeat dan Installment](https://help.realbyteapps.com/hc/en-us/articles/360046668993-How-to-set-up-a-repeat-schedule-installment)
- [Realbyte: Edit dan hapus aturan Repeat](https://help.realbyteapps.com/hc/en-us/articles/7139801632793-How-to-edit-and-delete-Repeat-Setting)
- [Mandiri: Biaya dan limit debit](https://www.bankmandiri.co.id/debit-biaya-limit)
- [Mandiri: Tarif layanan](https://www.bankmandiri.co.id/tarif-layanan)
- [Mandiri: Suku bunga dana](https://www.bankmandiri.co.id/suku-bunga-dana)
- [SeaBank: Perhitungan bunga](https://www.seabank.co.id/help-center/article/10012)
- [Jago Syariah: Biaya dan imbalan](https://www.jago.com/id/syariah/rates)
- [Google: GOOGLEFINANCE](https://support.google.com/docs/answer/3093281?hl=en)
- [Android: Work requests](https://developer.android.com/develop/background-work/background-tasks/persistent/getting-started/define-work)
- [CoinGecko: Paket API](https://www.coingecko.com/en/api/pricing)
- [Drift](https://drift.simonbinder.eu/)
