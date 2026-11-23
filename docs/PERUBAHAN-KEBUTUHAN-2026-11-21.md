# Perubahan kebutuhan Arta — 21 November 2026

> **Pembaruan implementasi 0.7.0:** master UI/ikon diterapkan, kelas Debit dan penyedia termasuk DOKU tersedia, 12 pilihan berulang/hari pilihan serta biaya pengirim/penerima sudah dijalankan, dan reset PIN melalui sidik jari sudah diuji dengan service simulasi. Lihat [panduan dan batas verifikasi](TAHAP-7-0.7.0.md). Status awal di bawah adalah catatan historis; pengujian HP 0.7.0 masih menunggu pengguna.

Status: **dicatat untuk coding dan desain FigCraft berikutnya; belum diimplementasikan, belum mengubah desain native, dan belum build**. Dokumen ini mengungguli aturan lama yang bertentangan, khususnya kartu debit yang dahulu hanya menjadi metode pembayaran rekening bank.

Pembaruan tahap desain: [master ikon/komponen FigCraft](../design/master-components-2026-11-21/README.md) kini sudah dibuat dengan contoh tambahan kebutuhan ini. Status awal di atas dan checklist coding tetap historis/belum selesai: rombak seluruh layar serta implementasi Flutter belum dilakukan, dan tidak ada APK baru.

Tambahan pemilih identitas Aset: [logo Bank/E-wallet Indonesia dan opsi Lainnya](design/LOGO-BANK-DAN-EWALLET-INDONESIA.md). Sumber SVG sudah diperiksa; katalog lokal, ikon generik tetap dan alur pemilih masih spesifikasi.

## 1. Ikon dan otorisasi pengerjaan vektor

Pengguna mengizinkan editing/pembuatan ulang vektor untuk mengikuti bentuk referensi, menggunakan VectorCraft, FigCraft, atau alat vektor yang sesuai. Jika MCP yang diperlukan belum tersedia, koneksinya boleh disiapkan tanpa meminta izin ulang. Tahap saat ini hanya mencatat; tidak memasang MCP atau mengubah aset aplikasi.

### Kelompok 2: bentuk referensi sudah tersedia

- Cocokkan vektor dengan referensi Bibit terlebih dahulu, kemudian Stockbit bila tidak ada padanan Bibit.
- Jika sumber SVG asli ada, gunakan geometri sumber sebagai dasar editing. Jika hanya gambar yang tersedia, gambar ulang/tracing berdasarkan bagian gambar yang sama.
- Periksa kanvas, proporsi, tebal garis, sudut, cap/join, padding optis dan tint pada ukuran tampil yang sama. Catat sumber screenshot/DOM pada setiap master ikon.
- Bentuk yang belum selesai dicocokkan tetap berstatus belum final; penemuan paket dengan nama ikon serupa tidak cukup membuktikan kesamaan.
- Ikon menu mengikuti pola garis berwarna + lingkaran tint senada. Ikon navigasi tetap tipis, tanpa teks dan tanpa lapisan indikator tambahan; aktif hijau, lainnya abu-abu.
- Master dibuat editable, varian terang/gelap diperiksa. SVG ekspor disiapkan saat tahap produksi aset; salinan riset tidak otomatis menjadi aset Flutter.

### Kelompok 1: keputusan bentuk yang sekarang sudah mempunyai arahan

| Fungsi | Keputusan untuk pengerjaan berikutnya | Sumber bentuk |
| --- | --- | --- |
| Staking | Buat ulang ikon gembok yang selaras dengan referensi; maknanya unit dikunci. Varian proses unstake/claim tetap memakai keluarga glyph ini bila dibutuhkan, disertai label status. | Gembok PIN/keamanan Bibit; bukan ikon tunas reksa dana. Pengguna mengizinkan adaptasi untuk staking. |
| Bunga aset | Pilihan utama: tunas reksa dana Bibit, mengikuti bentuk dan gaya tintnya. Promo & Voucher Bibit adalah alternatif yang diizinkan jika hasil penyandingan lebih sesuai; tidak perlu memasukkan kedua variasi sekaligus. | Produk Reksa Dana pada Bibit `225626`/`224150`; alternatif row Promo & Voucher pada profil Bibit. |
| Ekspor | Gunakan geometri keluarga logout, diputar sehingga panah menunjuk ke atas; susun ulang pada kanvas yang sama bila perlu agar sejajar secara optis. | Logout Stockbit `230018`/DOM Stockbit. |
| Impor | Pasangan ekspor dari geometri yang sama, panah menunjuk ke bawah. | Sumber logout yang sama. |

Rotasi ditentukan oleh arah panah hasil akhir, bukan angka rotasi yang diasumsikan sebelum melihat geometri sumber. Label `Ekspor`/`Impor` tetap disertakan pada tindakan. Tidak menambah metafora ikon baru di luar keputusan ini.

Kebutuhan ini memperbarui item I32, I37 dan I38 pada [pemetaan UI](design/PEMETAAN-ROMBAK-UI-2026-11-20.md). Master vektor final empat fungsi tersebut belum dibuat.

## 2. Pilihan transaksi berulang

Tampilkan urutan dan label berikut pada pemilih frekuensi. Pilihan ditampilkan dalam bottom sheet/radio seperti referensi, dengan rincian tambahan hanya untuk pilihan yang memerlukannya.

| No. | Label UI | Arti aturan |
| --- | --- | --- |
| 1 | Setiap Hari | Setiap satu hari kalender dari tanggal mulai. |
| 2 | Setiap Hari Tertentu | Pilih satu atau beberapa hari Senin–Minggu. Tidak otomatis dianggap Senin–Jumat; hari dipilih pengguna. |
| 3 | Setiap Minggu | Interval 1 minggu / 7 hari kalender. |
| 4 | Setiap 2 Minggu | Interval 2 minggu / 14 hari kalender. |
| 5 | Setiap 4 Minggu | Interval 4 minggu / 28 hari kalender; tidak disamakan dengan satu bulan. |
| 6 | Setiap Bulan | Interval 1 bulan, mengikuti tanggal acuan. |
| 7 | Setiap Akhir Bulan | Tanggal kalender terakhir pada setiap bulan, termasuk Februari. |
| 8 | Setiap 2 Bulan | Interval 2 bulan dari bulan/tanggal acuan. |
| 9 | Setiap 3 Bulan | Interval 3 bulan dari bulan/tanggal acuan. |
| 10 | Setiap 4 Bulan | Interval 4 bulan dari bulan/tanggal acuan. |
| 11 | Setiap 6 Bulan | Interval 6 bulan dari bulan/tanggal acuan. |
| 12 | Setiap Tahun | Interval 1 tahun dari bulan/tanggal acuan. |

`Setiap Hari Tertentu` di atas adalah interpretasi kerja dari istilah pengguna, yaitu pemilih hari dalam minggu. Cantumkan nama hari yang dipilih pada ringkasan supaya tidak ambigu. Jangan membuat satu kejadian terpisah ganda untuk tanggal yang sama.

### Tanggal, waktu, dan tanggal yang tidak ada

- Semua kejadian mempertahankan jam/menit serta zona waktu aturan. Operasi mingguan memakai tanggal kalender lokal, bukan penambahan detik UTC yang dapat menggeser jam pada zona dengan DST.
- Jika tanggal bulanan tidak tersedia, pakai tanggal terakhir bulan tersebut, tetapi **simpan tanggal acuan semula**. Contoh bulanan tanggal 31: 31 Januari → 28/29 Februari → 31 Maret, bukan bergeser permanen ke tanggal 28.
- Untuk tahunan 29 Februari: gunakan 28 Februari pada tahun nonkabisat dan kembali ke 29 Februari pada tahun kabisat. Pengguna menyerahkan keputusan penanganan ini.
- Akhir bulan merupakan aturan eksplisit; berbeda dengan aturan tanggal 28/29/30/31 yang hanya dipangkas ketika tanggal tidak tersedia.
- Mingguan dan kelipatannya dihitung dari tanggal mulai/acuan, bukan dari waktu aplikasi terakhir dibuka atau transaksi terakhir dikonfirmasi.
- Untuk hari tertentu, hanya tanggal pada/setelah mulai yang hari minggunya terpilih yang menjadi kejadian; tanggal akhir dan batas jumlah tetap dihormati.
- Mode otomatis/konfirmasi, pratinjau, jeda/lanjutkan, lewati, hentikan, catch-up, pencegahan duplikasi dan cicilan yang sudah ada tetap berlaku.
- Perubahan nominal/tanggal aktual saat konfirmasi tidak menggeser pola aturan berikutnya tanpa pengeditan aturan yang eksplisit.
- Jadwal Mandiri pribadi Rp5.500 pada tanggal 4 dan Rp6.000 pada akhir bulan tetap contoh pengguna, bukan preset otomatis semua instalasi.

### Implikasi model dan kompatibilitas

Sebagian preset dapat memakai frekuensi + interval yang sudah ada; pemilih hari tertentu membutuhkan representasi hari mingguan yang eksplisit. Jangan menganggap menambah label UI saja sudah memenuhi fitur. Jadwal lama harus mempertahankan arti, tanggal acuan, progres cicilan dan ID kejadian setelah migrasi/restore.

## 3. Transfer dengan biaya pengirim dan penerima

### Form dan keadaan awal

1. Saklar utama `Biaya transfer` tetap tersedia. Saat mati, form biaya tersembunyi dan kedua nilai biaya efektif nol.
2. Saat diaktifkan, pilihan `Biaya pengirim` aktif secara default; `Biaya penerima` belum aktif.
3. Kedua pilihan dapat diaktifkan bersama; pengguna juga dapat memakai penerima saja dengan mematikan pilihan pengirim.
4. Tampilkan field nominal hanya untuk pihak yang aktif. Jika saklar utama aktif tetapi tidak ada pihak dipilih, minta pilih pihak atau matikan biaya sebelum menyimpan.
5. Nilai biaya dimasukkan pengguna; jangan menerapkan tarif bank/platform otomatis. Biaya tidak boleh negatif. Saldo aset tetap boleh menjadi negatif sesuai aturan aplikasi.
6. Preview menampilkan `Dikirim`, `Biaya pengirim`, `Biaya penerima`, `Diterima bersih`, dan perubahan saldo masing-masing pihak. Pihak nonaktif disimpan sebagai biaya nol.

### Perhitungan mata uang sama

Untuk pokok transfer **P**, biaya pengirim **Fs**, biaya penerima **Fr**:

- Saldo pengirim berkurang `P + Fs`.
- Saldo penerima bertambah `P - Fr`.
- Total kekayaan berubah sebesar `-(Fs + Fr)`.
- Pokok transfer tidak masuk pemasukan/pengeluaran. Kedua biaya masuk pengeluaran tepat sekali, dengan asal aset dan jenis biaya yang jelas.

Contoh P = Rp100.000, Fs = Rp2.500, Fr = Rp1.000: pengirim berkurang Rp102.500, penerima bertambah Rp99.000, total berkurang Rp3.500. Pengirim saja menghasilkan penerimaan Rp100.000; penerima saja tidak membebani tambahan pada pengirim.

Untuk transfer mata uang berbeda, biaya pengirim memakai mata uang aset sumber, biaya penerima memakai mata uang tujuan. Hitung penerimaan bruto dengan nominal/kurs transfer yang disimpan, kemudian kurangi biaya penerima. Jangan menjumlahkan dua mata uang sebagai angka mentah atau menganggap kurs hilang sebagai nol. Kondisi penerimaan bersih nol/negatif harus terlihat jelas dalam preview; jangan menolaknya hanya dengan alasan saldo aset tidak boleh minus.

### Persistensi dan pengeditan

- Pokok, debit biaya pengirim, dan debit biaya penerima disimpan dalam satu operasi atomik dengan relasi ke transfer yang sama.
- Detail/riwayat tidak menampilkan biaya sebagai transfer pokok tambahan. Grafik, laporan dan ekspor harus mencegah hitung ganda.
- Edit/hapus membalik efek lama lalu menerapkan efek baru tepat sekali; kegagalan tidak menyimpan separuh transfer.
- Transfer berulang/konfirmasi/cicilan dapat mempertahankan kedua pilihan dan nilai biaya tanpa mengubah pembagian pokok cicilan secara diam-diam.
- Backup/restore membawa kedua field dan mata uangnya. Fee transfer versi lama dipetakan ke biaya pengirim; biaya penerima lama nol. Pembacaan backup lama tetap didukung melalui migrasi yang sesuai.

## 4. Kelas Debit dengan kantong bersaldo sendiri

### Perubahan dari keputusan lama

**Debit kini merupakan kelas aset tersendiri dengan saldo dan mutasinya sendiri**, karena kartu debit pengguna memakai kantong yang berbeda dari bank sumber. Ini menggantikan spesifikasi lama yang memperlakukan kartu hanya sebagai alias/metode pembayaran terhadap saldo rekening bank.

Daftar kelas yang perlu tersedia: Tunai, Bank, Dompet digital, Exchange / Sekuritas, **Debit**, Utang / Kartu kredit, dan Piutang / Dana belum cair. Kelas yang sudah ada tidak dihapus hanya karena tidak disebut ulang dalam pesan terbaru. Klasifikasi instrumen investasi saham/crypto/reksa dana tetap terpisah dari kelas wadah saldo tersebut.

- Contoh nama aset: `Debit Jago Syariah`.
- Debit memiliki nama, mata uang, saldo awal, riwayat, status aktif/arsip dan dukungan saldo minus yang sama dengan wadah noninvestasi terkait.
- Bank/platform sumber boleh dicatat sebagai metadata, bukan relasi yang otomatis menyamakan saldo atau mendebit bank saat debit dipakai.
- Mengisi kantong Debit dari Bank dicatat sebagai **transfer Bank → Debit**, bukan pemasukan. Pengeluaran dari Debit hanya mengurangi Debit.
- Total kekayaan menjumlahkan saldo kedua kantong yang benar-benar terpisah. Jangan menyalin saldo Bank sebagai saldo awal Debit secara otomatis.
- Bila angka bank yang dibaca pengguna merupakan saldo gabungan beberapa kantong, jelaskan agar ia mencatat bagian masing-masing kantong; jangan memasukkan saldo gabungan lalu menjumlahkan kantong yang sama lagi.
- Daftar, pemilih sumber/tujuan, filter, chart komposisi, jadwal, bunga yang diisi pengguna, CSV dan backup harus mengenali kelas Debit.

### Migrasi kartu lama

- Data kartu lama yang hanya menunjuk rekening bank tidak boleh otomatis menggandakan saldo atau mengalihkan seluruh transaksi historis ke Debit.
- Jika kartu lama dikonversi menjadi aset Debit, mulai dari saldo nol sampai pengguna mengisi saldo awal yang benar atau mencatat transfer kantong; tidak menyalin saldo rekening sumber.
- Pertahankan mutasi lama pada aset asal dan sediakan ringkasan migrasi yang jelas. Metadata kartu dapat tetap ditautkan ke aset Debit jika diperlukan; jangan menampilkan dua entitas saldo untuk satu kantong yang sama.
- Relasi backup versi lama harus diterima dengan aturan migrasi yang eksplisit, dan tidak menghasilkan kehilangan kartu maupun duplikasi kekayaan.

## 5. Ringkasan Aset, Liabilitas, Total di bagian atas

Bagian atas halaman Aset menampilkan tiga angka berlabel **Aset**, **Liabilitas**, **Total**. Hierarki yang sama digunakan pada ringkasan kekayaan bila relevan. Label tiga angka tetap terlihat walau nominal disembunyikan menjadi titik.

- **Aset**: nilai positif harta yang dihitung, termasuk saldo wadah, piutang/dana belum cair yang sah, dan investasi sesuai cakupan ringkasan.
- **Liabilitas**: besaran kewajiban ditampilkan positif sebagai pengurang, termasuk utang/kartu kredit dan saldo negatif wadah noninvestasi. Kredit/kelebihan bayar yang benar-benar menjadi hak pengguna diperlakukan sesuai tanda ledger, bukan dipaksa menjadi kewajiban positif.
- **Total = Aset − Liabilitas**. Total boleh negatif. Saldo negatif tidak dimasukkan sekaligus sebagai pengurang Aset dan tambahan Liabilitas.
- Normalisasi mengikuti tanda serta substansi ledger. Jangan menggunakan `abs()` terhadap seluruh rekening utang tanpa memeriksa kelebihan bayar atau tanda saldo yang disimpan.
- Contoh: nilai aset positif Rp2.000.000, utang Rp250.000, saldo wadah lain −Rp50.000 → Aset Rp2.000.000, Liabilitas Rp300.000, Total Rp1.700.000.
- Internal transfer Bank → Debit tanpa biaya tidak mengubah ketiga total; hanya komposisi kantongnya berubah. Biaya transfer mengurangi Total sebesar kedua biaya.
- Cakupan harus eksplisit: angka halaman Aset yang memuat seluruh kekayaan menyertakan investasi satu kali; ringkasan khusus noninvestasi diberi keterangan. Label “Total” tidak boleh berganti arti tanpa penjelasan.
- Chart komposisi tidak mempunyai slice negatif; kewajiban/pengurang ditampilkan terpisah. Posisi investasi, pending transaksi dan piutang tidak dihitung dua kali ketika mewakili dana yang sama.
- Mata uang berbeda memakai kurs dan tanggal yang jelas. Jika kurs/harga tidak tersedia, tampilkan cakupan yang belum dapat dinilai; jangan membuat angka nol seolah lengkap.

## 6. Kebutuhan desain FigCraft

Tambahkan ke halaman komponen dan flow dalam **tema gelap dan terang**:

- Master vektor/varian ikon kelompok 2, staking, bunga, ekspor dan impor dengan rujukan sumber.
- Pemilih 12 frekuensi berulang, state pemilih beberapa hari, pratinjau tanggal, serta keterangan tanggal 29 Februari/tanggal bulanan yang dipangkas.
- Form transfer: biaya mati, pengirim saja (default saat aktif), penerima saja, kedua pihak, error nominal, serta preview saldo/penerimaan.
- Tambah/edit/daftar/detail **Debit**, pemilih aset transfer, dan perpindahan Bank → Debit.
- Header **Aset / Liabilitas / Total**: normal, nominal disembunyikan, total negatif dan valuasi belum lengkap.
- Keadaan migrasi kartu lama yang menjelaskan kantong terpisah tanpa menggandakan saldo.
- Tata letak tetap aman dari navigasi Samsung/keyboard, teks besar, dan layar sempit. Pola card/list/sheet mengikuti [pemetaan referensi](design/PEMETAAN-ROMBAK-UI-2026-11-20.md).

FigCraft lama belum mencakup keputusan terbaru ini. Jangan menandai flow selesai hanya karena layar kartu debit lama sudah ada.

## 7. Kriteria penerimaan untuk coding dan tes berikutnya

- [ ] Dua belas label urutannya sesuai permintaan, dan masing-masing menghasilkan tanggal yang benar.
- [ ] Hari tertentu hanya menghasilkan hari terpilih, termasuk batas mulai/akhir dan catch-up tanpa duplikasi.
- [ ] Empat minggu berbeda dari satu bulan; interval 2/3/4/6 bulan tidak bergeser setelah Februari.
- [ ] Tahunan 29 Februari → 28 Februari pada nonkabisat → 29 Februari ketika kabisat; waktu aturan tetap.
- [ ] Transfer tanpa biaya, pengirim saja, penerima saja, dan kedua pihak cocok dengan perhitungan; biaya tidak dihitung dua kali.
- [ ] Edit/hapus/berulang, mata uang berbeda dan backup lama/baru mempertahankan kedua jenis biaya dengan benar.
- [ ] Debit dapat dibuat sebagai kelas aset, mempunyai saldo sendiri, dan hanya saldo itu berubah ketika dipakai.
- [ ] Transfer Bank → Debit tanpa biaya mempertahankan kekayaan dan tidak menjadi pemasukan.
- [ ] Migrasi kartu lama tidak menyalin saldo bank atau memindahkan riwayat tanpa aturan yang jelas.
- [ ] Header Aset/Liabilitas/Total benar untuk utang, saldo noninvestasi negatif, piutang, investasi, kurs hilang dan privasi nominal.
- [ ] Ikon diperiksa berdampingan dengan sumber; dark/light, ukuran tampil dan padding konsisten.
- [ ] Seluruh state/flow baru dicerminkan pada FigCraft, implementasi, dokumentasi pengguna dan checklist pengujian saat tahap tersebut dikerjakan.

Dokumen ini menambah pekerjaan di atas tiga bug HP, reset PIN biometrik, rombak UI dan sisa pengujian yang sudah tercatat. Tidak menyatakan pekerjaan tersebut selesai.
