# Arta 0.2.0 — transaksi berulang dan cicilan

Tanggal: 19 November 2026, Asia/Jakarta.

Versi ini melanjutkan [fondasi tahap 1](IMPLEMENTASI-TAHAP-1.md). Akun, pemasukan/pengeluaran, transfer, saldo minus, tema, dan backup tetap tersedia. Implementasi berjalan sepenuhnya di Flutter dan SQLite tanpa server atau langganan.

## Membuat jadwal

Buka **Pengaturan > Transaksi berulang > +**, lalu pilih **Transaksi berulang** atau **Cicilan pengeluaran**. Pintasan juga tersedia pada Ringkasan. Dari formulir **Catat transaksi**, pilihan **Berulang / Cicilan** berada di dekat tanggal. Membuat jadwal tidak sekaligus menyimpan transaksi sekali saja di luar jadwal.

Isi jenis transaksi, akun, nominal, kategori, nama jadwal, tanggal mulai, dan catatan bila perlu. Transfer memakai dua akun berbeda dan biaya opsional. Saldo boleh menjadi minus; tidak ada penolakan karena saldo tidak cukup.

Frekuensi yang tersedia: harian, mingguan, bulanan, tahunan, dan setiap N periode (1–999). Untuk pengulangan biasa, jumlah kejadian opsional (1–1.200), tanggal akhir opsional dan inklusif, atau keduanya kosong untuk terus berulang. Jika dua batas diisi, batas yang lebih dahulu tercapai menghentikan rencana. Rentang kalender yang didukung 1900–2199.

Bulanan memakai tanggal pada **Mulai** atau sakelar **Hari terakhir setiap bulan**. Tanggal 31 Januari mengikuti 28/29 Februari lalu kembali ke 31 Maret. Sakelar akhir bulan tetap mengikuti hari terakhir kalender; tidak digeser karena Sabtu/Minggu atau hari libur. Mulai 19 November dengan sakelar aktif menghasilkan kejadian pertama 30 November. Tahunan 29 Februari mengikuti 28 Februari pada tahun biasa dan kembali ke 29 pada tahun kabisat, termasuk ketika aturan diedit setelah kejadian pada tahun biasa. Jangkar tanggal kalender disimpan pada `month_day`, terpisah dari tanggal mulai.

Zona jadwal dipilih dari WIB (`Asia/Jakarta`, UTC+7), WITA (`Asia/Makassar`, UTC+8), dan WIT (`Asia/Jayapura`, UTC+9). Default WIB. Tanggal efektif terpisah dari waktu pencatatan UTC. Mengganti zona perangkat tidak mengubah tanggal jadwal yang sudah dipilih. Ringkasan bulanan umum masih memakai bulan kalender perangkat seperti tahap 1.

## Dua mode pencatatan

- **Minta konfirmasi**: kejadian jatuh tempo tampil pada daftar berulang dan belum mengubah saldo. Ketuk untuk meninjau nominal, biaya transfer, tanggal aktual dan catatan, lalu **Catat transaksi ini** atau **Lewati sekali**.
- **Catat otomatis saat jatuh tempo**: aplikasi mencatat semua kejadian yang sudah lewat sampai hari ini pada saat jadwal disimpan, aplikasi dibuka, kembali ke foreground, tombol periksa ditekan, atau hari berganti ketika aplikasi terbuka. Tanggal transaksi otomatis adalah tanggal jatuh temponya, bukan tanggal aplikasi dibuka kembali.

Pemeriksaan pergantian hari dilakukan tiap menit selama aplikasi terbuka. Belum ada worker latar belakang atau notifikasi Android: jika aplikasi ditutup paksa atau HP mati, catch-up dijalankan saat aplikasi dibuka kembali. Jadwal hanya membentuk catatan dan tidak melakukan debit atau pembayaran ke bank.

Tanggal mulai di masa lalu dapat langsung menghasilkan banyak transaksi pada mode otomatis. Pilih mulai pada kejadian pertama yang belum masuk ke saldo awal/riwayat Anda. Aplikasi tidak mencocokkan transaksi manual berdasarkan kesamaan nama, tanggal, atau nominal; bila sudah mencatat manual, jangan mencatat kejadian yang sama lagi melalui jadwal.

## Dua contoh Mandiri milik pengguna

Tambahkan akun Mandiri terlebih dahulu, kemudian buat dua jadwal pengeluaran sendiri:

| Isian | Biaya tanggal 4 | Biaya akhir bulan |
| --- | --- | --- |
| Nama/kategori | Diisi sesuai mutasi | Diisi sesuai mutasi |
| Nominal per kejadian | 5.500 | 6.000 |
| Frekuensi / N | Bulanan / 1 | Bulanan / 1 |
| Mulai | Tanggal 4 pertama yang belum dicatat | Bulan pertama yang belum dicatat |
| Hari terakhir setiap bulan | Mati | Aktif |
| Mode | Otomatis jika diinginkan | Otomatis jika diinginkan |

Tidak ada aturan wajib berdasarkan nama bank, kartu GPN Gold, atau jenis rekening. Pajak, biaya, dan bunga tetap diberi kategori sesuai catatan pengguna. Bunga dengan nominal tetap bisa menjadi pemasukan berulang; kalkulasi bunga berdasarkan saldo/tarif belum tersedia.

## Jeda, ubah, hentikan dan riwayat

Ketuk aturan pada daftar untuk membuka detail. Bagian **Kejadian berikutnya** menampilkan 12 kejadian yang belum diproses; rencana tidak masuk saldo. Kejadian mendatang dapat dicatat lebih awal dengan tanggal aktual maksimal hari ini, atau dilewati. Form perubahan nominal satu kejadian berlaku ketika kejadian itu dicatat; belum ada penyimpanan override untuk dieksekusi otomatis pada masa depan.

**Jeda jadwal** menahan pemrosesan. Saat dilanjutkan, pilih **Proses semua yang lewat** atau **Lewati sebelum hari ini**. Pilihan kedua menyimpan kejadian lewat sebagai dilewati dan mempertahankan kejadian hari ini. Mode otomatis langsung menjalankan kejadian tersisa yang jatuh tempo.

**Ubah jadwal mendatang** mengisi formulir dari sisa rencana, menghentikan aturan lama, lalu membuat aturan baru ketika disimpan. Status jeda dipertahankan. Tanggal pengulangan bulanan disimpan terpisah dari tanggal mulai: mengedit aturan tanggal 31 pada kejadian 28 Februari tetap menghasilkan 31 Maret jika tanggal tidak diubah. Memilih tanggal mulai lain secara eksplisit mengganti tanggal pengulangannya. Seluruh kejadian lama yang belum diproses dibatalkan, termasuk sebelum tanggal mulai baru. Periksa tanggal mulai, jumlah dan nominal baru. Riwayat lama tidak diubah dan dapat ditemukan pada filter **Semua**. Jika ada kejadian diproses ketika formulir terbuka, penyimpanan ditolak agar sisa rencana ditinjau ulang. **Hentikan pengulangan** mengarsipkan aturan secara permanen; buat aturan baru untuk mulai lagi.

**Lewati sekali** tidak membentuk transaksi. Menghapus transaksi yang berasal dari jadwal menghitung ulang saldo, tetapi menyimpan status kejadian sebagai **dihapus**. Membuka ulang aplikasi, menyegarkan, atau memulihkan backup tidak membuatnya kembali. Riwayat menautkan transaksi yang masih ada sehingga dapat diedit melalui detail jadwal. Mengedit transaksi tidak mengubah aturan atau bagian lain.

Kejadian dibedakan dengan pasangan ID aturan dan urutan, bukan nominal atau tanggal saja. SQLite menyimpan transaksi dan status kejadian secara atomik, dengan kunci unik untuk menahan pencatatan ganda. Jadwal yang selesai mempertahankan status aturan aktif dengan label **Selesai** karena tidak memiliki kejadian tersisa.

## Cicilan pengeluaran

Pilih **Cicilan pengeluaran**, isi **Total pengeluaran yang dibagi**, jumlah bagian (2–1.200), tanggal awal, dan interval bulan. Contoh total `100` dibagi 3 menghasilkan `33,33`, `33,33`, dan `33,34`. Nominal dihitung dalam sen dengan `BigInt`; bagian terakhir menampung sisa pembulatan. Total tidak dibukukan lagi di awal, sehingga ketiga pengeluaran berjumlah persis `100`.

Detail menampilkan bagian yang sudah diproses, pengeluaran aktual yang masih tercatat, dan sisa rencana yang belum diproses. Melewati atau menghapus suatu bagian tetap menganggapnya diproses; nominalnya tidak dibagi ulang. Mengubah nominal aktual satu bagian juga tidak mengubah bagian lainnya. Jika jenis transaksi dikoreksi, pengeluaran aktual mengikuti ledger: pengeluaran dihitung sebesar nominal, transfer hanya biayanya, pemasukan tidak dihitung sebagai pengeluaran. Karena itu total aktual bisa berbeda dari rencana bila ada koreksi, kejadian dilewati, atau transaksi dihapus. Saat mengubah jadwal mendatang, total awal formulir adalah jumlah bagian rencana yang belum diproses, bukan sisa utang bank.

Fitur ini untuk pembagian pengeluaran berkala. Belum ada pembukuan kewajiban/utang, pokok-bunga, uang muka terhubung, pembayaran sebagian, atau perhitungan pelunasan kredit. Jangan memasukkan total pembelian sebagai pengeluaran sekali lagi jika memakai rencana pembagian ini untuk pembelian yang sama.

## Database dan backup

Skema SQLite naik dari 1 ke 2 dengan penambahan `schedules` dan `schedule_occurrences`. Migrasi mempertahankan tabel akun, transaksi dan preferensi tahap 1. Tabel kejadian memiliki kunci `(schedule_id, ordinal)`, referensi aturan, dan referensi transaksi unik yang dapat menjadi null setelah transaksi dihapus. Aturan historis disimpan agar identitas kejadian tetap dapat divalidasi.

Format JSON data naik ke `schema_version: 2`, mencakup `accounts`, `transactions`, `schedules`, `occurrences`, dan `preferences`. Backup v1 tetap dapat diimpor dengan jadwal dan riwayat kosong. Aplikasi tahap 1 tidak dapat membaca backup v2. Versi envelope enkripsi tetap 1 karena algoritmanya tidak berubah. Enkripsi tetap AES-256-GCM dan PBKDF2-HMAC-SHA256 600.000 iterasi; batas file tetap 25 MB.

Restore meminta penyimpanan cadangan data saat ini melalui pemilih file terlebih dahulu. Pembatalan penyimpanan membatalkan restore. Penggantian seluruh tabel dan catch-up jadwal otomatis berjalan dalam transaksi SQLite yang sama: kegagalan mengembalikan seluruh data sebelumnya. Kejadian yang sudah diproses di backup tidak dijalankan ulang; kejadian otomatis yang belum diproses sampai hari ini akan ditambahkan. Pastikan zona jadwal dan tanggal mulai benar sebelum memulihkan file lama.

## Status dan pemeriksaan

Seluruh **41 pengujian lulus** dan analyzer bersih. Pemeriksaan mencakup kalender/tahun kabisat, batas periode, zona waktu Indonesia, pembulatan cicilan, mode konfirmasi/otomatis, catch-up, saldo minus, transfer/biaya, permintaan pencatatan bersamaan, jeda/lanjutkan, perubahan mendatang (termasuk jangkar tanggal 31 dan status jeda), koreksi jenis transaksi, tombstone hapus, rollback kegagalan SQL, migrasi v1, backup v1/v2, dan interaksi layar pada 360×800/800×360 dengan skala teks hingga 2×. Gambar pemeriksaan Flutter berada di `build/ui-review/schedule*.png`. Hasil final dicatat di catatan build.

Perintah: `scripts/flutter.ps1 -Task Check`, `-Task Test`, dan `-Task Build`. Hasil build serta jumlah pengujian final dicatat pada `BUILD-TAHAP-2.json`. APK ini masih debug untuk pengujian dan belum diuji pada HP Android fisik.

Investasi/harga, impor katalog saham melalui UI, kalkulasi bunga, laporan lanjutan, CSV transaksi, multi-mata-uang dan sinkronisasi tetap tahap berikutnya. [RANCANGAN.md](RANCANGAN.md) merupakan arah keseluruhan produk, bukan daftar fitur yang seluruhnya sudah selesai.
