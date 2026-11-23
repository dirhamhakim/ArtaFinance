# Peta penggunaan dan rancangan awal

**Panduan implementasi terbaru:** [Arta 0.4.0 — investasi, Bibit manual, katalog IDX, harga, kurs, bunga dan ekspor](TAHAP-4-0.4.0.md). Kode fitur tersebut tersedia; APK 0.4.0 belum dibuild. Untuk keamanan/foto/kartu lihat [0.3.0](TAHAP-3-0.3.0.md), dan untuk jadwal/cicilan lihat [tahap 2](IMPLEMENTASI-TAHAP-2.md).

Isi di bawah adalah catatan rancangan awal. Label pending investasi belum berupa status order khusus; panduan 0.4.0 menjelaskan realisasinya memakai akun dana dalam proses/pencairan dan transfer. Utang/piutang/kartu kredit memakai akun dan transfer pokok; belum menghitung amortisasi/siklus tagihan otomatis. Lokasi menu aktual dan batas fitur mengikuti panduan versi terbaru, bukan nama menu rancangan lama.

## Saldo akun noninvestasi boleh minus

Bank, kas, e-wallet dan akun pembayaran sejenis boleh mempunyai saldo negatif. Anda tetap dapat menyimpan pengeluaran, transfer, saldo awal negatif dan transaksi terjadwal meskipun saldo tidak cukup. Misalnya saldo Rp100.000 dikurangi pengeluaran Rp150.000 akan ditampilkan sebagai -Rp50.000.

Nilai minus tetap masuk ke ringkasan dan backup. Aplikasi tidak otomatis membuat catatan utang atau biaya tambahan hanya karena saldo minus. Nominal pengeluaran/transfer diisi positif seperti biasa; saldo dihitung dari arah transaksinya. Pencatatan ini tidak mengirim pembayaran ke bank/platform.

## Reksa dana Bibit dengan input manual

1. Tambahkan akun penyimpanan Bibit dan produk reksa dana yang dimiliki.
2. Jika memulai dari kepemilikan lama, masukkan jumlah unit, tanggal saldo awal, dan modal historis jika diketahui. Jangan menjadikan saldo awal sebagai pemasukan baru.
3. Untuk pembelian baru, masukkan akun pembayar, nominal, tanggal pembayaran, dan biaya jika ada. Selama masih diproses, tandai sebagai pembelian pending/dana dalam proses; kas yang telah keluar tetap tercatat dan belum diasumsikan sebagai unit reksa dana.
4. Setelah Bibit mengonfirmasi transaksi, isi unit yang benar-benar diterima, NAB/unit, dan tanggal efektif. Cocokkan dana, unit, pembulatan, serta biaya dengan konfirmasi tersebut.
5. Perbarui NAB/unit lewat form harga manual dengan tanggal NAB yang terlihat di Bibit. Pembaruan ini hanya mengubah valuasi, bukan unit atau modal pembelian.
6. Nilai portofolio dihitung dari unit yang dimiliki dikali NAB/unit terakhir. Jika tanggal NAB berbeda dengan hari ini, tanggal tersebut tetap ditampilkan.
7. Ketika menjual, isi unit yang dilepas dan hasil bersih. Dana penjualan yang belum masuk ditandai pending/piutang pencairan; saat cair, pindahkan ke akun penerima tanpa mencatat pendapatan kedua kali.

Contoh ilustrasi tanpa biaya: pembelian Rp1.000.000 dikonfirmasi memperoleh 800 unit pada NAB/unit Rp1.250. Jika NAB berikutnya Rp1.300, valuasi menjadi Rp1.040.000 dan laba belum terealisasi Rp40.000. Angka ini bukan saldo kas baru. Gunakan angka konfirmasi aktual saat ada pembulatan/biaya.

## Membuat transaksi berulang sendiri

1. Pilih pemasukan, pengeluaran, atau transfer sesuai kejadian.
2. Isi akun, nominal, kategori, dan catatan yang diinginkan; tidak ada potongan bank aktif secara bawaan.
3. Pada bagian tanggal pilih **Berulang / Cicilan**, lalu **Berulang**. Tentukan tanggal mulai dan frekuensi. Untuk bulanan tersedia **Tanggal tertentu** atau **Hari terakhir setiap bulan**.
4. Pilih catat otomatis atau minta konfirmasi. Contoh: biaya tetap bulanan dapat dicatat otomatis; tagihan berubah dapat menunggu konfirmasi.
5. Tinjau kejadian berikutnya sebelum menyimpan. Pilih tanggal berdasarkan mutasi pribadi, bukan tanggal debit bank yang diasumsikan aplikasi.
6. Transaksi otomatis masuk ketika jatuh tempo diproses. Bila aplikasi lama tidak dibuka, kejadian yang terlewat diproses saat aplikasi dibuka kembali dengan tanggal efektif masing-masing.
7. Menghapus aturan menghentikan kejadian mendatang; transaksi lama tetap tersimpan. Melewati satu kejadian tidak membatalkan seluruh aturan.

Pencatatan ini tidak mendebit bank atau melakukan pembayaran. Bunga/pajak/biaya dapat diberi nama sesuai mutasi pengguna. Aturan pengulangan tetap tidak boleh menghasilkan catatan ganda jika nominal yang sama sudah dicatat melalui proses lain; pencocokan memerlukan peninjauan, bukan hanya kesamaan nominal.

Contoh pengaturan Mandiri sesuai keterangan pengguna:

| Field | Aturan pertama | Aturan kedua |
| --- | --- | --- |
| Jenis | Pengeluaran | Pengeluaran |
| Akun | Mandiri | Mandiri |
| Nominal | Rp5.500 | Rp6.000 |
| Frekuensi | Setiap bulan | Setiap bulan |
| Tanggal | Tanggal tertentu: 4 | Hari terakhir setiap bulan |
| Nama/kategori | Diisi sendiri | Diisi sendiri |
| Pencatatan | Otomatis bila dipilih pengguna | Otomatis bila dipilih pengguna |

Aturan kedua mengikuti 28/29 Februari, 30 April, 31 Januari, dan seterusnya. Aturan ini tidak diaktifkan otomatis untuk semua akun Mandiri. Kelola aturan melalui **Lainnya > Pengaturan > Transaksi berulang**, mengikuti pola navigasi Money Manager.

## Mencatat bunga akun

- Buka fitur **Bunga akun**, pilih akun, lalu masukkan aturan sendiri bila ingin menggunakan kalkulasi. Semua parameter dapat diatur dan tidak ditetapkan berdasarkan nama bank.
- Cara paling sederhana: catat nilai bunga yang benar-benar diterima dan potongan yang terlihat pada mutasi.
- Jika mutasi menampilkan bruto dan pajak terpisah, masukkan keduanya dalam satu kelompok agar kenaikan kas sama dengan neto.
- Jika hanya nilai neto yang diketahui, jangan mengarang nilai bruto/pajak; simpan neto dan tandai rincian belum tersedia.
- Perhitungan bunga otomatis opsional. Pengguna mengatur tarif, tanggal berlaku, dasar saldo, tingkatan, jadwal kredit, dan pembulatan terlebih dahulu.
- Angka estimasi tidak menambah saldo aktual sampai dikonfirmasi atau mode pencatatan otomatis sengaja diaktifkan.

## Cicilan

- Tentukan apakah rencana hanya membagi pengeluaran bulanan atau mencatat utang yang sesungguhnya.
- Masukkan total/nominal per periode secara jelas, jumlah periode, tanggal awal, serta biaya/bunga jika ada.
- Tinjau jumlah seluruh bagian, urutan cicilan, pembayaran yang sudah dilakukan, dan sisa rencana.
- Untuk utang, pembayaran pokok mengurangi kewajiban; bunga merupakan pengeluaran. Jangan mencatat pokok dua kali sebagai pengeluaran pembelian dan pengeluaran pembayaran.

## Harga aset

- Saham menggunakan penutupan sesi terakhir yang tersedia dan sudah selesai, bukan wajib tanggal hari ini.
- Crypto menggunakan harga cache terakhir, dengan refresh daring ketika halaman portofolio aktif.
- Jika layanan gagal atau kuota habis, aplikasi tetap berfungsi offline dengan label tanggal harga terakhir.
- Harga/NAB manual dapat dipakai sebagai pengganti. Mengisi harga tidak mengubah transaksi beli/jual yang sudah dicatat.
- GOOGLEFINANCE belum dijamin dapat dijadikan jalur otomatis karena batas akses historis dan dukungan simbolnya.

## Memperbarui daftar saham IDX

Alur ini masih direncanakan dan belum tersedia dalam aplikasi.

1. Unduh daftar saham terbaru dari IDX dalam format Excel `.xlsx`. Tidak perlu mengubahnya menjadi JSON di komputer.
2. Buka **Lainnya > Pengaturan > Katalog saham Indonesia > Impor daftar saham**. File JSON katalog hasil ekspor aplikasi juga dapat dipilih.
3. Pilih file di HP. Proses impor berjalan offline dan tidak mengirim file ke server.
4. Periksa ringkasan saham baru, perubahan nama/metadata, saham yang tidak ditemukan pada file tersebut dan masalah baris. Perbaiki file jika ada kode duplikat atau data wajib kosong.
5. Tekan **Terapkan pembaruan** setelah meninjau. Seluruh kolom selain `No` disimpan, termasuk tanggal pencatatan, jumlah lembar saham emiten dan papan pencatatan, meskipun belum ditampilkan dalam aplikasi. Daftar pencarian langsung menggunakan katalog baru; impor tidak mengubah transaksi, jumlah unit atau modal investasi.
6. Saham yang tidak ada dalam unduhan baru tetap disimpan. Ketidakhadiran dalam file tidak otomatis berarti delisting. Koreksi metadata manual tidak ditimpa begitu saja.
7. Gunakan **Ekspor katalog JSON** bila ingin menyimpan daftar tersebut. Untuk pindah HP beserta transaksi, tetap gunakan backup lengkap.

Menu ini memperbarui daftar perusahaan, bukan harga saham. Harga tetap mengikuti cache/Yahoo atau input harga manual.

## Backup dan pindah HP

- Gunakan backup lengkap berversi untuk pemulihan, bukan CSV transaksi saja.
- Simpan salinan di luar direktori internal aplikasi, misalnya folder dokumen atau media cadangan pilihan sendiri.
- Backup terenkripsi memerlukan kata sandi saat restore; jangan menyimpan satu-satunya salinan kata sandi bersama file backup.
- CSV digunakan untuk analisis atau pemindahan tabel tertentu. Format tersebut tidak mencakup seluruh jadwal, relasi, lampiran, dan pengaturan.
- Restore harus menampilkan ringkasan, memvalidasi file, dan membuat backup data lama sebelum menggantikannya.
- Restore di HP kedua tidak membuat kedua HP saling tersinkronisasi. Jangan menganggap dua file backup dari perangkat berbeda otomatis dapat digabungkan.
