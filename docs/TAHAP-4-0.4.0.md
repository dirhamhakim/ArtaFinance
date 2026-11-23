# Arta 0.4.0+6 — keuangan dan investasi lokal

APK debug **0.4.0+6 sudah dibuild** setelah pengguna meminta build untuk pengujian mandiri. [Unduh APK](../build/app/outputs/flutter-apk/arta-0.4.0-debug.apk), [identitas dan checksum build](BUILD-0.4.0.json). Package dan tanda tangan sama dengan versi sebelumnya. Pasang sebagai pembaruan setelah menyimpan backup, tanpa uninstall. Pengujian HP belum dilakukan; tidak memakai emulator atau koneksi HP.

Gunakan [markdown testing lama yang sudah diperbarui menjadi 80 kasus lengkap](TESTING-APK-0.2.0.md) untuk langkah, checkbox, angka pembanding, hasil aktual dan laporan bug. Nama file lama dipertahankan agar laporan pengguna tetap di satu tempat.

## Menu dan cakupan

- Ringkasan > **Portofolio investasi**, atau Pengaturan > Portofolio investasi.
- Pengaturan > **Katalog saham & instrumen**: saham IDX offline, crypto, dan reksa dana.
- Pengaturan > **Sumber harga & mata uang**: CoinGecko, Yahoo, CSV/spreadsheet, API key dan kurs.
- Pengaturan > **Bunga & bagi hasil**: aturan pengguna dan bunga aktual.
- Pengaturan > **Utang & piutang**: pokok pinjaman, belanja kartu kredit dan dana belum cair.
- Pengaturan > **Ekspor CSV transaksi/kepemilikan/harga**. JSON biasa/terenkripsi tetap merupakan backup lengkap.

Pencatatan seluruh platform bersifat manual. Nama Bibit, Stockbit, Floq, Triv, Tokocrypto, MetaMask, RedotPay, Bybit ID, Pyypl dan Getplu dapat dipakai sebagai nama akun/lokasi; aplikasi tidak masuk ke akun tersebut, mengambil mutasi, mengirim uang, atau mengirim order.

## Alur uang dan investasi

1. Buat akun bank dan akun **Saldo exchange / sekuritas**. Saldo awal exchange/RDN hanya uang tunai yang belum dibelanjakan, bukan nilai total portofolio.
2. Catat bank → RDN/exchange melalui **Transaksi > Transfer**. Transfer tidak menjadi pengeluaran konsumsi. Toggle biaya hanya diaktifkan bila ada biaya.
3. Buka Portofolio > Catat investasi, pilih instrumen dan lokasi/akun kas, lalu masukkan unit serta nominal bruto aktual. Beli mengurangi kas sebesar bruto + biaya dan menambah unit dalam satu perubahan SQLite atomik.
4. Jual mengurangi unit dan menambah kas sebesar bruto − biaya. Hasil penjualan bukan seluruhnya pendapatan; laba/rugi terealisasi dihitung dari modal unit yang dilepas.
5. Tarik uang ke bank menggunakan Transfer akun kas exchange → bank. Jangan membuat pemasukan kedua kali.

Saldo uang tunai boleh minus. Unit saham/crypto/reksa dana tidak boleh minus. Edit atau hapus transaksi investasi menghitung ulang urutan historis; perubahan ditolak dan di-rollback jika membuat penjualan/perpindahan berikutnya kehabisan unit.

| Jenis investasi | Kas | Unit / modal |
| --- | --- | --- |
| Beli | Berkurang bruto + biaya | Bertambah; biaya masuk modal |
| Jual | Bertambah bruto − biaya | Berkurang dengan modal rata-rata tertimbang |
| Saldo unit awal | Tidak berubah | Isi unit dan total modal historis, atau tandai modal tidak diketahui |
| Pindah unit | Hanya berkurang bila ada biaya tunai | Modal ikut ke lokasi tujuan; biaya jaringan unit mengurangi unit/modal asal |
| Dividen / hasil tunai | Bertambah bruto − potongan | Tidak mengubah unit; bruto masuk laporan pendapatan dan potongan masuk biaya |
| Reward unit | Tidak berubah | Bertambah dengan modal nol |
| Split / reverse split | Tidak berubah | Unit dikalikan faktor, total modal tetap |

Perpindahan crypto: **jumlah unit adalah yang diterima tujuan**, sedangkan biaya jaringan unit ditambahkan pada pengurangan asal. Contoh kirim 0,4 BTC dengan biaya 0,001 BTC: asal berkurang 0,401; tujuan bertambah 0,4. Biaya tunai, jika ada, memakai mata uang akun asal. Modal unit biaya jaringan dikeluarkan dari modal posisi; tidak menebak nilai pasar biaya tersebut sebagai pengeluaran kas.

Untuk saham, unit disimpan dalam lembar bulat; toggle input lot mengalikan 100. Faktor split boleh desimal, tetapi hasil kepemilikan saham harus tetap lembar bulat. Penyelesaian pecahan atau corporate action lain yang tidak terwakili memerlukan pencatatan sesuai konfirmasi sekuritas.

Modal pembelian, penjualan dan laba/rugi dihitung dalam IDR menggunakan kurs historis transaksi. Modal tidak diketahui menghasilkan label tidak diketahui, bukan laba fiktif dari modal nol. Ini metode rata-rata tertimbang untuk pelacakan pribadi, bukan laporan pajak/broker otomatis.

## Reksa dana Bibit manual

1. Buat akun kas Bibit atau **Dana dalam proses Bibit**.
2. Dana yang sudah dibayar tetapi belum memperoleh unit dicatat sebagai transfer bank → Dana dalam proses. Jangan membuat unit perkiraan.
3. Sesudah Bibit mengonfirmasi, catat **Beli**, gunakan akun dana dalam proses sebagai kas sumber, isi unit aktual dan total nominal bruto konfirmasi. Sisa/refund dipindahkan kembali menggunakan Transfer.
4. Kepemilikan lama dimasukkan melalui **Saldo unit awal**. Total modal adalah modal historis, bukan nilai NAB hari ini. Kas tidak dikurangi lagi.
5. Gunakan **Harga / NAB manual** untuk mengisi NAB per unit dan tanggal NAB. Nilai = unit × NAB; perubahan NAB tidak mengubah modal atau saldo kas.
6. Untuk pencairan yang belum masuk bank, catat Jual pada akun **Dana pencairan Bibit**. Akun ini mewakili klaim kas. Setelah uang masuk, transfer ke bank. Jangan membuat pendapatan seluruh hasil jual.

Unit dan harga mendukung sampai 12 desimal, memakai titik atau koma desimal tanpa pemisah ribuan. Nominal kas memakai format Indonesia dan dua desimal. Nominal bruto aktual dapat berbeda sedikit dari unit × harga karena konfirmasi/pembulatan; gunakan nilai platform. Kalkulator unit × harga tersedia sebagai bantuan input.

## Katalog IDX dan logo

Katalog awal berasal dari Excel IDX pengguna, unduhan 18 November 2026: **944 saham**. Parser Flutter sudah diuji terhadap file Excel asli dan kelima kolom cocok dengan seed, termasuk kode `TRUE` dan seluruh digit jumlah lembar.

1. Pilih **Impor IDX**, lalu `.xlsx` atau JSON katalog schema 1 melalui pemilih dokumen Android. Pemrosesan lokal tidak membutuhkan galeri/storage permission atau server.
2. Jika beberapa sheet cocok, pilih sheet. Header dikenali dari nama, bukan posisi tetap. Tanggal serial Excel serta format IDX seperti `08 Jun 2021`, `Agt`, `Okt`, `Des` didukung. Jumlah lembar dengan pemisah ribuan dinormalisasi menjadi digit teks tanpa konversi floating point.
3. Tinjau jumlah baru/berubah/tetap/tidak ditemukan, contoh baris, dan peringatan. Kolom baru disimpan sebagai metadata tambahan dan disebutkan pada preview; `No` diabaikan. Kode/nama wajib, tanggal, jumlah lembar, formula/error dan duplikasi divalidasi sebelum perubahan.
4. Tekan **Terapkan pembaruan**. Seluruh perubahan disimpan atomik; kegagalan tidak menghapus katalog lama. Kode yang absen pada file tidak dihapus atau dianggap delisting.
5. ID, riwayat, modal, harga, serta koreksi nama/mapping/logo tetap dipertahankan. Detail instrumen menyediakan arsip dan kembali ke metadata sumber. Ekspor IDX JSON berisi metadata sumber; backup keuangan lengkap juga menyimpan koreksi pengguna.

Seluruh kolom sumber selain No dipertahankan, termasuk tanggal pencatatan, jumlah lembar dan papan pencatatan. Jumlah lembar emiten tidak sama dengan unit milik pengguna. Nilai ini tersimpan sebagai string digit dalam body JSON SQLite dan ekspor, sehingga tidak kehilangan presisi.

Pencarian saham dibatasi katalog IDX lokal. Yahoo hanya mengambil harga simbol `KODE.JK`. Logo saham memakai pola URL Stockbit yang diberikan pengguna; logo crypto memakai URL hasil CoinGecko. Logo dipanggil saat diperlukan melalui cache gambar Flutter; saat gagal/offline tampil kode/ikon. Tidak mengunduh seluruh logo atau menyediakan server storage.

## Harga, cache dan API key

- Tombol **Perbarui harga** hanya mengambil instrumen yang sedang dimiliki. Crypto digabung dalam satu request; saham dipanggil per simbol. NAB reksa dana tetap manual.
- Yahoo memakai close biasa, bukan adjusted close. Sesi hari ini dipakai setelah waktu akhir regular session yang dikirim Yahoo + 15 menit; sebelumnya memakai penutupan sesi terdahulu. Tanggal sesi, waktu pengambilan, mata uang dan sumber terpisah. Endpoint ini telah berhasil diuji dari laptop untuk BBCA.JK, tetapi bukan kontrak API publik yang dijamin stabil.
- CoinGecko menyimpan timestamp harga sumber. Key Demo dikirim lewat header, bukan query URL. Key disimpan terenkripsi dengan Android Keystore dan tidak dimasukkan ke APK/source/backup. Setelah restore ke HP lain, masukkan key perangkat tersebut kembali.
- Key pengguna berhasil diuji dari laptop: HTTP 200 untuk Bitcoin dan Ethereum dalam IDR/USD. Tidak ada key asli dalam fixture, log uji, atau metadata build. Key belum disetel ke HP karena versi ini belum dipasang.
- Refresh otomatis **opsional, default nonaktif**, setiap 5 menit hanya ketika halaman portofolio aktif, route terdepan, dan aplikasi tidak terkunci. Tidak berjalan di background. Refresh manual diberi jeda minimal satu menit yang tersimpan di perangkat. Respons 429 memberi backoff 1–60 menit sesuai Retry-After yang dibatasi, default 5 menit.
- Kuota CoinGecko tetap berlaku. Dashboard key adalah patokan limit akun; jangan menganggap Demo atau akses tanpa key unlimited.
- Error, offline, respons null atau nol tidak mengganti harga terakhir. Harga tidak tersedia diberi label belum dinilai. Ringkasan menandai jumlah posisi/akun tanpa harga/kurs; total tersebut belum lengkap.
- Cache menyimpan satu observasi terakhir per instrumen/tanggal/sumber. Grafik memakai harga yang benar-benar pernah disimpan; tidak membuat riwayat palsu sebelum aplikasi digunakan. Grafik ini grafik harga, bukan grafik return portofolio yang sudah disesuaikan setoran.

Cadangan: **Impor harga / NAB CSV** dengan header `code,date,price,currency`. Harga memakai desimal titik; tanggal `YYYY-MM-DD`. Contoh: `BBCA,2026-11-18,9000,IDR`. Gunakan ID instrumen ketika simbol crypto ambigu. Preview dan validasi seluruh file dilakukan sebelum penyimpanan.

Google Sheets publik dapat menyediakan tabel yang sama melalui URL CSV HTTPS `docs.google.com/spreadsheets/...`. Simpan URL pada pengaturan lalu **Ambil harga spreadsheet tersimpan**. Aplikasi tidak membuat spreadsheet/login Google. Isi tabel dan tanggal harga harus diverifikasi pengguna. Data historis GOOGLEFINANCE tidak dijanjikan dapat diakses lewat Sheets API/Apps Script; dukungan simbol juga bervariasi. Fallback CSV lokal/manual tetap tersedia.

## Mata uang

Akun dapat memakai IDR, USD, USDT, SGD, EUR atau MYR. Isi kurs di Sumber harga & mata uang: IDR per satu unit mata uang dan tanggalnya. Kurs valuasi berbeda dari kurs historis yang disimpan pada transaksi. USDT tidak otomatis dipatok 1 USD.

Transfer lintas mata uang memerlukan nominal keluar dan nominal aktual diterima. Biaya dibebankan pada mata uang asal. Jadwal transfer saat ini memakai dua akun bermata uang sama; nominal pertukaran yang berubah dicatat sebagai transfer sekali dengan nominal aktual. Jadwal akun asing menyimpan kurs yang tersedia saat kejadian diproses. Jika belum ada kurs, kejadian tetap menunggu; aplikasi tetap dapat dibuka untuk mengisi kurs.

Kas mempunyai dua desimal. Untuk token/unit crypto yang memerlukan pecahan lebih kecil, gunakan instrumen crypto (hingga 12 desimal), bukan menganggap akun kas USDT sebagai ledger token dengan presisi tak terbatas. Konversi laporan memakai kurs historis; ringkasan kekayaan memakai kurs valuasi terakhir. Akun tanpa kurs tidak diam-diam dianggap IDR.

## Bunga dan bagi hasil

1. Tambah aturan, pilih akun, nama, tanggal berlaku dan tanggal akhir opsional. Tidak ada preset bunga/biaya bank yang dipaksakan.
2. Atur kredit harian atau bulanan, saldo akhir hari perhitungan atau hari sebelumnya, basis 360/365/366 hari, tarif tahunan dan pajak.
3. Tier pertama dimulai saldo 0. Isi 0% bila saldo rendah tidak berbunga. Tier berikutnya berisi batas saldo dan tarif sendiri. Pilih tarif seluruh saldo atau progresif per rentang.
4. Estimasi dihitung sampai kemarin dalam WIB. Bulanan menunggu periode selesai; tanggal akhir aturan dapat menutup periode sebagian. Saldo negatif menghasilkan estimasi nol.
5. Default **konfirmasi**: buka periode dan sesuaikan bruto, pajak serta tanggal masuk dengan mutasi. Saldo bertambah neto sekali; bruto masuk pendapatan dan pajak masuk biaya.
6. Opsional **Catat otomatis saat aplikasi dibuka** menganggap estimasi sebagai aktual. Hanya aktifkan bila riwayat saldo, tarif dan pembulatan sudah sesuai. Bunga harian berikutnya memakai kredit aktual sebelumnya. Riwayat panjang diproses maksimal 100 periode per putaran foreground dan dilanjutkan pada refresh berikutnya; tidak memblokir startup hanya karena aturan lama. Tidak menjanjikan hasil sama dengan bank jika riwayat/aturan berbeda.
7. Dua aturan aktif pada akun sama tidak boleh tumpang tindih. Untuk tarif baru, nonaktifkan aturan lama dan buat aturan mulai periode baru. Catatan periode yang sudah diproses tidak boleh tumpang tindih lintas aturan.
8. Pembatalan bunga mengoreksi saldo tetapi mempertahankan penanda periode agar tidak dibuat ulang. Perubahan transaksi historis memperbarui estimasi, bukan menulis ulang bunga aktual terkonfirmasi.

Pembulatan setengah menjauh dari nol ke dua desimal pada bruto per periode, kemudian pajak. Basis hari diisi manual; tahun kabisat tidak otomatis mengganti 365 menjadi 366.

Biaya Mandiri Rp5.500 tanggal 4 dan Rp6.000 akhir bulan tetap dibuat sebagai dua pengeluaran berulang umum. Fitur bunga tidak membuat biaya tersebut otomatis. Jago Syariah tidak otomatis diberi bunga karena nama akunnya.

## Utang, piutang dan kartu kredit

Menu Utang & piutang membuat akun **Utang / kartu kredit** atau **Piutang / dana belum cair**. Utang awal ditulis minus; piutang awal positif. Saldo tersebut masuk kekayaan dengan tanda aslinya.

- Menerima pinjaman: transfer Utang → bank. Kas bertambah, utang makin negatif; pokok bukan pendapatan.
- Membayar pokok: transfer bank → Utang. Kas berkurang, utang mendekati nol; pokok bukan konsumsi. Bunga/biaya menjadi pengeluaran terpisah atau komponen biaya transfer.
- Belanja kartu kredit: pengeluaran dari akun Utang. Membayar tagihan melalui transfer bank → Utang, sehingga belanja tidak dihitung dua kali.
- Memberi pinjaman: transfer bank → Piutang. Ketika dibayar, transfer Piutang → bank. Pendapatan bunga yang benar-benar diterima dicatat sebagai pemasukan tersendiri.
- Cicilan pokok tetap dapat memakai jadwal Transfer; bunga/biaya memakai jadwal Pengeluaran terpisah. Isi rincian pemberi pinjaman, tidak ada tebakan amortisasi, minimum payment, limit kartu atau tanggal cetak.

Debit Jago tetap memakai fitur Kartu debit yang tertaut rekening; tidak memakai akun Utang.

## Backup dan ekspor

SQLite **schema 4**, backup JSON **schema 4**, amplop enkripsi tetap 1. Migrasi SQLite 1/2/3 dan impor backup 1/2/3 tetap didukung. Backup v4 menyertakan instrumen, kelima kolom saham, koreksi metadata, transaksi investasi, harga, kurs, aturan/riwayat bunga, kartu, foto, jadwal dan pengaturan tema. Kunci aplikasi, API key, refresh dan URL spreadsheet merupakan preferensi perangkat dan tidak dibagikan lewat backup.

Simpan backup lama sebelum update; aplikasi lama tidak membaca backup v4. Batas backup lengkap masih **25 MB**, termasuk lampiran, dan impor katalog maksimal 10 MB. Bila terlalu besar, ekspor ditolak dengan pesan; data utama tidak dihapus. CSV hanya tabel analisis, tidak memulihkan database lengkap. Sel CSV yang dapat dianggap formula diberi perlindungan saat ekspor.

## Pengujian dan batas verifikasi

Validasi kode akhir selesai pada 19 November 2026. Laporan lengkap tersedia di [VALIDASI-0.4.0.json](VALIDASI-0.4.0.json).

- [x] **121 pengujian unit/widget lulus dalam satu eksekusi suite akhir**, termasuk investasi, utang/piutang, kurs, bunga, backup dan migrasi SQLite 1/2/3 ke 4. [Log suite](../build/tests-final-0.4.0.log).
- [x] Analyzer bersih: `No issues found`. [Log analyzer](../build/analyze-0.4.0.log).
- [x] Empat berkas Kotlin berhasil diperiksa tipenya dan uji kebijakan PIN JVM lulus. Ini bukan build APK atau pengujian Keystore/sensor HP. [Log native](../build/native-check-0.4.0.log).
- [x] Satu smoke test jaringan langsung melewati **parser aplikasi produksi**, memakai Yahoo BBCA.JK dan CoinGecko Demo Bitcoin/Ethereum, bukan hanya memeriksa status HTTP. [Hasil](../build/market-parsers-live-0.4.0.json), [log](../build/market-parsers-live-0.4.0.log).
- [x] Excel IDX asli: 944 baris, nol perbedaan pada lima kolom terhadap seed, kode TRUE dipertahankan. [Hasil](../build/idx-import-0.4.0.json).
- [x] Pemeriksaan 178 file sumber/dokumentasi tidak menemukan key asli tertanam. [Hasil](../build/credential-scan-0.4.0.json).
- [x] Review preview tema gelap/terang dan pengujian widget layar 360 × 800, landscape 800 × 360, serta font 200%. [Portofolio gelap](../build/ui-review/portfolio-dark-0.4.0.png), [portofolio terang](../build/ui-review/portfolio-light-0.4.0.png), [grafik gelap](../build/ui-review/price-chart-dark-0.4.0.png), [grafik terang](../build/ui-review/price-chart-light-0.4.0.png).
- [x] Build APK 0.4.0 setelah instruksi pengguna; versi, package, tanda tangan dan checksum terverifikasi. Pemindaian 134 entri APK tidak menemukan key pengguna tertanam. [Catatan build](BUILD-0.4.0.json).
- [ ] Pasang, konfigurasi API key dan uji Samsung A05s Android 15.

Jangan menandai pengujian HP berikut sebagai lulus hanya karena tes komputer lulus. APK 0.3.0 sebelumnya tetap disimpan dan checksum-nya tidak berubah.

- [ ] **I01 — Update:** setelah build, pasang sebagai pembaruan tanpa uninstall. Saldo, foto, kartu, kunci, jadwal dan tema versi 0.3.0 tetap ada.
- [ ] **I02 — Dana investasi:** transfer bank → RDN/exchange; total tidak bertambah dan bukan konsumsi. Beli/jual kemudian tarik ke bank; tidak ada kas/unit ganda.
- [ ] **I03 — Modal:** dua pembelian dengan harga berbeda, jual sebagian, cocokkan modal rata-rata dan laba terealisasi. Uji edit/hapus historis dan penolakan unit negatif.
- [ ] **I04 — Crypto:** kirim unit antar lokasi dengan biaya jaringan/tunai; modal ikut, unit tujuan sesuai yang diterima.
- [ ] **I05 — Bibit:** saldo unit awal, beli terkonfirmasi, dana dalam proses/pencairan, NAB manual. Mengubah NAB tidak mengubah unit atau kas.
- [ ] **I06 — Aksi unit:** dividen, reward dan split/reverse split; periksa perubahan kas/unit/modal sesuai tabel.
- [ ] **I07 — Impor IDX:** file asli 944 saham, sheet pilihan, preview, batal dan terapkan. Uji kode TRUE, jumlah lembar, kolom baru, formula, duplikat, file rusak dan kode absen.
- [ ] **I08 — Koreksi:** ubah nama/mapping/logo, impor ulang, arsip dan kembali ke sumber; riwayat tidak hilang.
- [ ] **I09 — Harga:** isi key di HP, uji CoinGecko dan Yahoo, offline, 429 dan cache. Tanggal harga tidak berubah menjadi tanggal unduh. Refresh otomatis berhenti saat pindah halaman/background/kunci.
- [ ] **I10 — CSV/spreadsheet:** impor harga valid/invalid, mata uang salah, duplikat dan tanggal masa depan. Ekspor semua tabel dan buka di spreadsheet.
- [ ] **I11 — Kurs:** akun asing, transfer lintas mata uang, biaya asal, kurs historis dan perubahan kurs valuasi. Kekurangan kurs diberi label.
- [ ] **I12 — Bunga:** tier seluruh saldo/progresif, dasar saldo sebelumnya, pajak, kredit harian/bulanan dan akhir Februari; cocokkan perhitungan manual.
- [ ] **I13 — Idempotensi:** buka ulang setelah bunga otomatis, backup/restore, batalkan satu kredit; tidak ada bunga atau jadwal ganda.
- [ ] **I14 — Privasi:** mata menyembunyikan nominal/kuantitas/grafik, PIN/sidik jari, Photo Picker dan API key setelah background/resume.
- [ ] **I15 — Backup v4:** pulihkan unit/modal/harga/kurs/bunga/foto/kartu/jadwal; key dan kunci HP tujuan tetap lokal. File rusak tidak mengganti data.
- [ ] **I16 — Tampilan:** tema gelap/terang, layar kecil, landscape, font besar dan daftar panjang. Periksa gambar/logo gagal.
- [ ] **I17 — Utang/piutang:** terima pinjaman, bayar pokok, belanja kredit, beri dan terima piutang. Pokok bukan pendapatan/konsumsi dan total kekayaan tidak ganda.

Laporan per item: `Hasil LULUS/GAGAL; langkah; hasil aktual; error; model HP dan versi Android`. Tidak ada pengujian HP/emulator yang dijalankan untuk 0.4.0 pada tahap coding ini.

## Rujukan implementasi

- [CoinGecko Demo dan header API key](https://support.coingecko.com/articles/9471335603-user-guide-how-to-sign-up-for-coingecko-demo-api-and-generate-an-api-key)
- [Simple price dan timestamp sumber](https://docs.coingecko.com/reference/simple-price)
- [Batasan GOOGLEFINANCE](https://support.google.com/docs/answer/3093281?hl=en-en)
- [Paket HTTP](https://pub.dev/packages/http), [ZIP archive](https://pub.dev/packages/archive), [XML](https://pub.dev/packages/xml)
