# Pemetaan rombak UI Arta — Bibit dan Stockbit

> **Pembaruan 21 November 2026:** [perubahan kebutuhan terbaru](../PERUBAHAN-KEBUTUHAN-2026-11-21.md) menetapkan bentuk awal ikon staking/bunga/impor/ekspor, pengerjaan ulang vektor, 12 frekuensi berulang, dua pihak biaya transfer, Debit sebagai kantong bersaldo sendiri, serta header Aset/Liabilitas/Total. Pekerjaan desain/kode belum dilakukan.

Tanggal: 20 November 2026. Status: **analisis referensi dan spesifikasi; belum mengubah Flutter, FigCraft, atau APK**.

Dokumen ini menjadi acuan terbaru untuk rombak UI. Keputusan visual lama yang bertentangan dengannya digantikan oleh instruksi pengguna pada sesi ini, terutama navigasi tanpa teks, penggunaan istilah **Aset**, card bertingkat Bibit, dan layar PIN baru. Fitur serta perhitungan keuangan tetap mengacu pada rancangan aplikasi yang sudah ada.

## 1. Sumber dan cara pemeriksaan

- Referensi lama: 59 screenshot Stockbit dalam `design/refferences/`.
- Referensi baru: 67 gambar dalam `design/refferences/new/`: 1 layar PIN, 51 screenshot Bibit, 15 screenshot Stockbit.
- Semua 126 gambar ditinjau melalui contact sheet. Sebanyak 24 gambar panjang baru juga diperiksa dalam 59 potongan agar detail bagian tengah/bawah tidak hilang saat gambar diperkecil.
- Berkas `C:/Users/User/Downloads/BIBIT.txt` dan `STOCKBIT.txt` menjadi bukti SVG/DOM web. Ini dibedakan dari screenshot mobile; kesamaan bentuk tidak otomatis membuktikan ukuran/warna web sama dengan mobile.
- [Analisis APK](../../design/ANALISIS-APK-BIBIT-STOCKBIT-2026-11-20.md) menjadi sumber font, warna native, ukuran dp/sp, dan aset terkemas.
- Inventaris dan sumber vektor: [folder bukti](../../design/reference-review-2026-11-20/). Berkas sementara/network/contact sheet ada di `build/ui-reference-review-20261120/`.

Screenshot baru mayoritas 1080 px lebar. Layar PIN adalah tangkapan komputer 383 × 859 px. Ukuran raster tidak dianggap sebagai dp/sp Android. Ukuran APK yang pasti dan perkiraan screenshot harus tetap diberi label berbeda.

## 2. Aturan yang wajib diikuti

1. Bibit menjadi referensi utama susunan beranda, permukaan/card, ikon, navigasi dan bottom sheet. Stockbit menjadi referensi utama portofolio, filter, daftar numerik dan line chart.
2. Setiap komponen/ikon harus mempunyai rujukan file dan bagian yang jelas. Jangan mengganti ikon dengan ikon library yang hanya mirip tanpa mencatat perbedaannya.
3. Istilah untuk wadah saldo pengguna adalah **Aset**, bukan Akun: daftar aset, tambah aset, aset sumber/tujuan, saldo aset, bunga aset, dan filter aset. Rekening masih boleh digunakan ketika secara spesifik berarti rekening bank. Nama internal database/kode tidak perlu diubah hanya untuk penggantian teks UI.
4. Navigasi bawah berupa ikon saja, aktif hijau, tidak aktif abu-abu. Tidak ada pill aktif, gelembung latar, capsule, floating dock, bayangan tambahan, atau teks visual. Tetap ada label aksesibilitas dan petunjuk long press.
5. Ikon menu di luar navigasi boleh memakai garis warna dan lingkaran tint senada seperti Bibit. Jangan membuat semua ikon ungu: saham ungu, reksa dana hijau, dan peran lain mengikuti rujukan masing-masing.
6. Card mempunyai hierarki: section/surface, card di dalam section, dan strip informasi. Tidak semua baris daftar dijadikan card terpisah.
7. Pilihan/filter/rincian singkat memakai bottom sheet sesuai contoh; form panjang tetap dapat menjadi halaman penuh dengan kalender dan pemilih jam 24 jam yang sudah diminta.
8. Tema gelap dan terang tetap wajib. Screenshot baru terutama membuktikan tema gelap; tema terang dicocokkan dengan resource terang APK, bukan membalik warna gambar.
9. Tidak menambahkan fitur promosi, referral, berita, Academy, transaksi broker, atau login hanya karena tampil dalam referensi. Yang dipindahkan adalah pola visual untuk fitur Arta.
10. Tidak menggunakan kucing. Logo Arta tetap menjadi identitas aplikasi.

## 3. Layar PIN dan biometrik

Sumber utama: [Screenshot 2026-11-20 020102.png](../../design/refferences/new/Screenshot%202026-11-20%20020102.png).

Susunan: judul atas, ikon gembok dalam lingkaran tint hijau, `Masukkan PIN Kamu`, field PIN berbingkai, ruang fleksibel, `Lupa PIN?`, tombol `Lanjut`, lalu keypad. Pertahankan proporsi dan ketenangannya; jangan mengisi ruang kosong dengan card atau ornamen baru.

| Baris | Kolom 1 | Kolom 2 | Kolom 3 |
| --- | --- | --- | --- |
| 1 | 1 | 2 | 3 |
| 2 | 4 | 5 | 6 |
| 3 | 7 | 8 | 9 |
| 4 | Sidik jari | 0 | Hapus satu angka |

- Keypad menempel pada bagian bawah area aman, sel sama besar, pemisah halus; bukan tombol angka bulat atau keyboard sistem.
- PIN Arta tetap enam angka. Field menampilkan titik saat disamarkan; kontrol mata yang sebelumnya diminta tetap tersedia dengan rujukan gaya kontrol referensi. Tampilan angka/dot di dalam field, bukan enam card baru.
- `Lanjut` disabled sebelum enam angka lengkap dan aktif setelah lengkap. Tombol tetap berada pada tempat yang sama. Detail salah PIN/penundaan tidak mengubah struktur keypad.
- Hapus tombol Bantuan kanan atas. Pada layar kunci awal tidak perlu tombol kembali. Alur buat/ubah PIN boleh mempunyai kembali/batal bila benar-benar ada langkah sebelumnya.
- Sidik jari menggunakan autentikasi Android. Slot kiri bawah tetap disediakan; ketika tidak tersedia/diaktifkan, jangan menjalankan autentikasi yang tidak dapat dipenuhi.
- `Lupa PIN?` menuju reset dengan sidik jari yang sudah diotorisasi untuk Arta, lalu buat dan konfirmasi PIN baru; data tidak dihapus. Lihat [rencana reset PIN](../RENCANA-RESET-PIN-SIDIK-JARI.md).

### Loading membuka biometrik

Gunakan lapisan penuh di atas halaman PIN: halaman tetap terpasang dengan ukuran yang sama, scrim hitam transparan dan indikator di tengah. Input keypad diblokir selama satu permintaan autentikasi berjalan. **Tidak** menambahkan spinner kecil ke Column/header sehingga layout bergeser.

Overlay Arta hanya mengatur keadaan menunggu di halaman Arta. Dialog sensor sendiri tetap digambar Android, tanpa ditimpa atau ditiru aplikasi. Batal/gagal mengembalikan halaman PIN yang sama; tidak membuka data, mengubah PIN, atau mengulang dialog tanpa henti. Overlay dibersihkan pada sukses, batal, error, atau pembatalan sesi karena lifecycle.

## 4. Pemetaan layar dan komponen

Nama file pendek berikut mengacu pada `design/refferences/new/Screenshot_20261120_{waktu}_{aplikasi}.jpg`.

| Bagian Arta | Referensi yang dipakai | Yang harus diikuti |
| --- | --- | --- |
| Beranda/Ringkasan | Bibit `224150` | Header ringkas, nominal utama + sembunyikan, subnilai dua kolom, pintasan, section bertingkat dan card di dalam section. Isi memakai kekayaan/aset/arus kas/jadwal Arta. |
| Navigasi utama | Bibit `225626`, `225440`, `225656` | Ikon tanpa teks, aktif hijau, bar datar dan ukuran visual tipis. |
| Menu Aset dan detail saldo | Bibit `224342`, `224424`, `224506` | Ringkasan Aset/Liabilitas/Total di atas, identitas aset, aksi ringkas, riwayat; rincian saldo dalam sheet. Sesuai perubahan 21 November, Debit Jago Syariah menjadi kelas kantong bersaldo sendiri; perpindahan dari Bank dicatat sebagai transfer. |
| Pemilih aset sumber/tujuan | Bibit `224424`, `224625`, `225243` | Kelompok daftar bank/wallet dengan logo, nama, keterangan dan chevron; sheet pilihan dengan selected state. |
| Ringkasan investasi | Bibit `225440`; Stockbit `230215` | Nilai, modal, laba/rugi dipisahkan, angka sejajar, aksi performa dan pengelolaan. |
| Halaman portofolio/performa lengkap | Stockbit `230121` | Urutan nilai/equity, line chart, ringkasan return, perbandingan dengan IHSG, alokasi donut. Tidak menyalin angka contoh pengguna ke Arta. |
| Perbandingan saham vs IHSG | Stockbit `230121`, bagian Cumulative Portfolio Return | Garis portofolio hijau, IHSG ungu, legenda berupa dua bidang ringkas berisi label dan persentase; sumbu persen dan baseline sama. Perhitungan tetap TWR Arta, bukan perubahan saldo. |
| Line chart nilai/harga | Stockbit `230121`; lama `162237` | Garis tipis, label sumbu redup, grid minimal, periode dengan underline hijau, titik/tanggal/nilai saat disentuh. Isi area hanya pada contoh yang memang berarea. |
| Donut alokasi | Stockbit `230121`; Bibit `225440` | Ring bersih, nilai/jumlah di tengah bila sesuai data, kategori dan rincian terbaca. Saldo negatif tetap pengurang terpisah, bukan slice negatif. |
| Carousel ringkasan | Bibit `224150`, `224601`, `224659`; `225440` untuk susunan ringkasan | Swipe horizontal dan indikator halaman yang terikat posisi. Titik aktif hijau berbentuk pill pendek; nonaktif titik abu-abu. Pengguna secara eksplisit meminta dot merespons swipe. |
| Daftar saham/crypto | Bibit `225626`, `225638`; Stockbit `230324` | Logo kiri, kode/nama, nominal dan perubahan rata kanan; sparkline bila ada data, divider halus. |
| Filter transaksi | Bibit `225709` | Sheet berjudul, kelompok pilihan, dropdown, chip status/jenis/periode, Reset dan Terapkan. Filter Arta mengikuti aset/jenis/kategori yang benar-benar tersedia. |
| Filter periode/custom | Stockbit `230138`, `230144` | Radio di kanan, daftar periode, tanggal mulai/akhir saat custom, footer Terapkan. Tanggal Arta tetap memakai kalender. |
| Urutkan portofolio/aset | Stockbit `230223` | Sheet satu pilihan: nama, nilai/modal atau laba/rugi sesuai data yang ada; selected hijau bercentang. |
| Kelola tampilan portofolio | Stockbit `230215` | Sheet pengelolaan, row urutkan, toggle privasi; tidak mengadopsi fitur order/jual seluruh broker. |
| Riwayat transaksi | Bibit `225656`; Stockbit `230241` | Kelompok tanggal/bulan, daftar ringkas, filter/search. Tabel numerik dipakai di detail investasi bila muat; transaksi pribadi tetap nyaman dibaca. |
| Form nominal/transaksi | Bibit `224506`, `224601`, `224903` | Label di luar field, outline halus, nominal/keterangan terpisah, footer CTA aman dari navigasi/keyboard. Toggle biaya mengungkap field biaya yang sudah ada. |
| Transaksi berulang/cicilan | Bibit `224601`, bagian SIP; `224903`, bagian Frekuensi/Berlaku Hingga | Gaya form, section aturan, dropdown dan ringkasan. Logika tetap Arta/Realbyte: tanggal tertentu/akhir bulan, auto/konfirmasi, cicilan; bukan autodebit bank. |
| Bunga aset | Bibit `224903`, bagian simulasi/rincian | Gaya field parameter, hasil bruto/potongan/neto dan section rincian. Bukan menyalin proyeksi obligasi sebagai bunga bank. |
| Staking | Bibit `224903` untuk form/rincian; `225709` untuk filter | Pola form/list yang sama untuk aktivitas manual. Referensi tidak memuat layar staking; jangan mengklaim desain staking Bibit sudah diamati. |
| Impor katalog IDX/harga | Bibit `224903` untuk form/rincian; `225751` untuk ringkasan konfirmasi; Stockbit lama `161941` untuk tabel | Pilih file native, preview perubahan, error per baris, konfirmasi hasil. Tidak menambahkan ilustrasi unggah tanpa rujukan. |
| Backup/restore | Bibit `225751` untuk konfirmasi dan `225745` untuk daftar pengaturan | Pemilihan tindakan, ringkasan dampak, tombol batal/lanjut, sandi dengan mata. Tetap memakai pemilih file Android. |
| Radio/checkbox | Bibit `224822`; Stockbit `230138`, lama `162154` | Opsi single/multi dibedakan secara perilaku; visual lingkaran tipis dan hijau tercentang ketika dipilih. |
| Filter chips | Bibit `224829`, `225709`; Stockbit `230241` | Pill outline tipis, selected hijau, label pendek; bukan card besar. |
| Bottom sheet informasi | Bibit `224358`, `224518`, `225601` | Sudut atas, scrim, judul kiri dan close kanan, isi berkelompok; footer aman. |
| Bottom sheet tindakan | Bibit `224528`, `225445`; Stockbit `230232` | Row ikon/label, divider halus, toggle hanya untuk preferensi. |
| Pengaturan | Bibit `225715`, `225745`; Stockbit `230018` | List datar dikelompokkan, ikon tipis, chevron/toggle; tanpa profil/login online di Arta. |
| Keadaan kosong | Bibit `225332`; Stockbit `230232`; lama `162014`, `162024` | Ilustrasi keuangan, judul, deskripsi dan aksi singkat bila sesuai. Kotak kosong cocok riwayat; pie kosong cocok portofolio. Ilustrasi robot/referral Bibit tidak otomatis dipindahkan. |
| FAQ/penjelasan istilah | Bibit `225930`, `225601` | Pola informasi/card dan sheet penjelasan untuk istilah yang sudah diperlukan Arta; tidak membuat pusat konten baru. |

### Pemetaan navigasi yang disiapkan

Usulan penempatan fungsi memakai lima slot seperti proporsi Bibit, dengan simbol yang sesuai makna. Ini pemetaan fungsi Arta, bukan klaim bahwa Bibit mempunyai tab Aset/Pengaturan dengan ikon tersebut.

| Tujuan Arta | Simbol referensi | Sumber |
| --- | --- | --- |
| Ringkasan | Rumah | Navigasi Bibit `225626`; SVG DOM `nav-ringkasan-rumah.svg` |
| Investasi | Pie terpotong | Navigasi Bibit `225440`; SVG DOM `nav-investasi-pie.svg` |
| Aset | Dompet/saldo | Bibit RDN Wallet `224342`/profil `225715`; glyph final dicocokkan dengan screenshot, belum diekspor vektornya |
| Transaksi | Dua panah berlawanan | Navigasi Bibit `225656`; SVG DOM `nav-transaksi-panah.svg` |
| Pengaturan | Gear | Baris Settings Bibit `225715`; bukan menyalin ikon profil untuk fitur tanpa login |

Pencarian tetap menjadi kontrol di halaman yang relevan; ikon kaca pembesar tidak dipaksakan berarti Aset. Label tetap disimpan untuk pembaca layar meskipun tidak dicetak di bilah.

## 5. Pemetaan ikon dan sumbernya

`DOM` berarti SVG asli dari file pengguna; `screenshot` berarti bentuk teramati tetapi sumber vektornya belum cocok; `publik` berarti URL berhasil diakses, bukan bukti lisensi semua aset aplikasi. Salinan referensi tidak dimasukkan ke aset Flutter.

| ID | Ikon pada referensi | Pemakaian Arta | Kepastian sumber / pekerjaan |
| --- | --- | --- | --- |
| I01 | Rumah navigasi Bibit | Ringkasan | DOM tersedia, geometri 20-unit; tidak otomatis diganti Feather home 24-unit. |
| I02 | Pie navigasi Bibit | Investasi/performa | DOM tersedia; beda dari pie-chart Feather standar. |
| I03 | Panah dua arah navigasi Bibit | Transaksi/transfer | DOM tersedia. |
| I04 | Kaca pembesar Bibit | Search transaksi/aset/katalog | DOM tersedia; sesuaikan ukuran per konteks, jangan mengganti glyph nav dengan bentuk lain. |
| I05 | Profil navigasi Bibit | Referensi bentuk saja | DOM tersedia; tidak dibuat login/profil online Arta. |
| I06 | Dompet RDN Bibit | Aset bank/kas/wallet dan akses Aset | Screenshot `224342`/`225715`; vektor belum dicocokkan. |
| I07 | Gear Settings Bibit | Pengaturan | Screenshot `225715`; vektor final belum dicocokkan. |
| I08 | Dua candle ungu Bibit | Saham/katalog saham | DOM img 10 tersedia; lingkaran dan tint ungu mengikuti `225626`/`224150`. |
| I09 | Tunas reksa dana Bibit | Reksa dana | DOM img 7 tersedia; hijau dengan circle tint seperti `225626`. |
| I10 | Kalender panah SIP Bibit | Berulang/cicilan | DOM img 3/37 tersedia; gunakan kalender SIP, bukan kalender biasa jika konteks jadwal. |
| I11 | Pie pintasan Portofolio Bibit | Grafik/alokasi/portofolio | DOM img 2 dan inline 10 tersedia; bedakan versi pintasan berwarna dengan nav tipis. |
| I12 | Grid empat titik Lainnya Bibit | Menu tindakan tambahan | DOM img 5 tersedia; cocok untuk pembuka sheet pintasan, bukan empat card baru. |
| I13 | Gembok Bibit | Kunci aplikasi/PIN | DOM inline 1 tersedia untuk gembok privasi; ikon pusat PIN harus dicocokkan lagi dengan screenshot PIN karena proporsinya dapat berbeda. |
| I14 | Sidik jari Bibit | Tombol biometrik keypad/pengaturan | Screenshot `225715`; lokasi keypad kiri bawah adalah instruksi pengguna, bukan bagian yang terlihat pada screenshot PIN. Sumber vektor belum cocok. |
| I15 | Mata / mata tertutup | Privasi saldo/sandi | Fungsi diminta pengguna; pilih varian yang benar-benar ditemukan pada referensi/asset; belum ada sumber identik terverifikasi dari screenshot baru. |
| I16 | Hapus angka PIN | Backspace keypad | Screenshot PIN; bentuk tombol hapus berbingkai dengan tanda x, bukan ikon tempat sampah. Vektor belum diekspor. |
| I17 | Chevron kiri | Back bersyarat/halaman detail | DOM inline 11 dan Feather publik mempunyai points identik; warna/ukuran mengikuti konteks. |
| I18 | Chevron kanan | Row menuju detail | DOM inline 3/4/12 dan Feather publik mempunyai points identik. |
| I19 | Chevron bawah | Dropdown/expand | DOM inline 18/19 dan Feather publik mempunyai points identik. |
| I20 | Bell Bibit | Peringatan/jadwal dalam aplikasi bila diperlukan | Dua path DOM inline 0 identik dengan Feather bell publik. Ini tidak menambah fitur notifikasi Android. |
| I21 | Plus dalam lingkaran | Tambah aset/instrumen | Screenshot `225626`/`225440`; ambil varian circle-plus referensi, belum diekspor dari DOM home. |
| I22 | Sliders/filter | Filter transaksi/riwayat | Screenshot `225709` dan Stockbit `230204`; vektor belum dicocokkan. |
| I23 | Sort garis | Urutkan daftar | Bibit `224829`, Stockbit `230223`; vektor belum dicocokkan. |
| I24 | Check dalam lingkaran | Selected radio/multiselect | Bibit `224822`, Stockbit `230138`; resource native checkbox lingkaran 18dp ditemukan sebelumnya. |
| I25 | Informasi dalam lingkaran | Penjelasan valuasi/return/bunga | Bibit `224358`, `225601`; gunakan versi referensi. |
| I26 | Tiga titik | Kelola portofolio/tindakan | Bibit `225445`, Stockbit `230215`; posisi/glyph sesuai sumber. |
| I27 | Salin | Salin nomor/detail | Bibit `224444`; glyph salin screenshot, tidak mengganti dengan clipboard yang bentuknya lain. |
| I28 | Ponsel / ATM / kartu | Kartu debit/aset dan instruksi terkait | Bibit `224444`/`224459`; konteks kartu debit memakai kartu, bukan logo investasi. |
| I29 | Dua arah deposit/withdraw | Catat transfer masuk/keluar | Bibit `224342`; bentuk/glyph perlu dicocokkan; tidak berarti transfer sungguhan ke bank. |
| I30 | Riwayat panah melingkar | Riwayat aset/aktivitas | Stockbit `230018`; gunakan simbol riwayat referensi bila cocok. |
| I31 | Dokumen E-Statement | Ekspor/laporan | Bibit `225715`; adaptasi fungsi ekspor dicatat, bukan bukti Bibit mempunyai backup lokal Arta. |
| I32 | Keluarga logout dengan panah diputar | Impor/ekspor file | Keputusan pengguna 21 November: gunakan bentuk logout referensi, ekspor panah atas dan impor panah bawah. Master vektor pasangan ini belum dibuat. |
| I33 | Kalender kecil | Tanggal/periode | Stockbit `230144`, Bibit `224903`; tanggal memakai kalender Arta yang diminta sebelumnya. |
| I34 | Panah naik/kanan dan turun/kanan | Perubahan nilai/performa | Bibit `225626`, Stockbit `230151`; selalu sertakan tanda/nilai, bukan hanya warna. |
| I35 | Bulan / setengah lingkaran tema | Pilih tampilan | Bibit `225715`, Stockbit `230018`; keduanya berbeda makna/status, pilih glyph tema sesuai row. |
| I36 | X / close sheet | Tutup sheet/banner | Bibit `224358`, `225709`; vektor DOM close tersedia untuk banner, cocokkan ukuran sheet. |
| I37 | Tunas reksa dana Bibit | Bunga aset | Keputusan pengguna 21 November mengizinkan tunas reksa dana atau Promo & Voucher; pilihan kerja utama tunas, varian final dicocokkan bersama ikon lainnya. |
| I38 | Gembok yang digambar ulang selaras Bibit | Staking | Referensi tidak memuat menu staking. Pengguna mengizinkan adaptasi 21 November; gunakan keluarga gembok PIN/keamanan sebagai acuan unit terkunci. Master vektor belum dibuat. |
| I39 | Logo bank/platform | Aset Seabank/Mandiri/Jago/wallet/exchange | Gunakan logo identitas yang benar; daftar Bibit `224424` menjadi acuan ukuran/posisi, bukan sumber seluruh logo platform pengguna. |
| I40 | Logo saham/coin | Instrumen/posisi investasi | Stockbit `230324`, Bibit `225626`; logo emiten memakai URL Stockbit yang sudah disepakati, coin memakai metadata CoinGecko. |
| I41 | Pie kosong outline Stockbit | Portofolio belum ada | Lama `162014`/`162056`; sumber ilustrasi terkemas ditemukan pada analisis APK, cocokkan varian final. |
| I42 | Kotak/riwayat kosong Stockbit | Transaksi/aktivitas belum ada | Baru `230232`, lama `162024`; tidak memakai ilustrasi video untuk transaksi. |
| I43 | Ilustrasi koneksi/error keuangan | Gagal harga/jaringan | Bundle publik Bibit menyebut SVG error-internet dark/light; tampilan perlu dicocokkan sebelum dipilih. |

### Hasil pencarian online

- **Tidak ditemukan paket publik lengkap yang terbukti merupakan seluruh ikon UI Bibit/Stockbit.** Hasil pencarian bernama “Bibit icon” banyak merujuk logo aplikasi, bukan komponen UI.
- Beberapa ikon standar memang tersedia persis di Feather: bell mempunyai dua path identik; chevron kiri/kanan/bawah mempunyai polyline points identik. Bukti perbandingan disimpan di folder referensi. Ini bukan bukti semua ikon Bibit berasal dari Feather.
- DOM pengguna mempunyai 38 inline SVG Bibit dan sejumlah SVG dalam data URI. Ikon produk/navigasi tertentu sudah memiliki vektor asli untuk dicocokkan; tidak perlu menebak path dari JPEG.
- URL resmi berikut berhasil GET 200 dengan `image/svg+xml`: [template dana 1](https://app.bibit.id/assets/images/portfolio/icon/green/1.svg), [template dana 16](https://app.bibit.id/assets/images/portfolio/icon/green/16.svg), dan [ilustrasi tutorial](https://app.bibit.id/static/svg/entry-point-tutorial.9fe6f55c.svg). Ini contoh ketersediaan SVG online, bukan klaim seluruh ikon produk mempunyai URL individual.
- Sumber resmi pembanding: [Feather bell](https://github.com/feathericons/feather/blob/main/icons/bell.svg), [chevron kanan](https://github.com/feathericons/feather/blob/main/icons/chevron-right.svg), [Feather](https://feathericons.com/), dan [aplikasi web Bibit](https://app.bibit.id/).
- Pencocokan path bell/gembok DOM juga menemukan path di bundle publik `profile.8c007594.js`. Kebanyakan ikon lain belum cocok pada sejumlah bundle yang diperiksa; jangan menyebut semuanya terverifikasi online.

### Kapan memakai Craft

1. Vektor sumber identik sudah ditemukan: gunakan geometri tersebut sebagai acuan; jangan menggambar ulang sampai meleset.
2. Hanya screenshot tersedia: VectorCraft cocok untuk tracing/penyuntingan path, stroke, cap, join dan bentuk. FigCraft juga cukup untuk ikon vektor sederhana dan komponennya dalam UI.
3. PhotoCraft dipakai bila perlu mengolah ilustrasi raster; bukan pilihan utama ikon garis kecil yang harus tajam pada berbagai ukuran.
4. FigCraft MCP tersedia pada sesi ini. VectorCraft/PhotoCraft belum muncul sebagai tool tersambung; tidak dipasang karena pekerjaan saat ini masih pemetaan.
5. Ekspor ikon final sebagai SVG/vector yang mendukung warna tema. Ukuran kanvas, geometri, tebal garis, padding optis dan lingkaran tint diperiksa berdampingan dengan potongan referensi pada ukuran yang sama. Jangan mengklaim identik hanya karena semantiknya sama.
6. SVG/fonts salinan analisis tetap berada pada folder referensi. Status sumber dan ketentuan penggunaan produksi dicatat sebelum memasukkannya ke distribusi Arta; metadata font APK sebelumnya belum memuat izin distribusi yang jelas.

## 6. Font, ukuran, warna, dan hierarki

- Font mobile native teridentifikasi **Bit Sans Regular/Bold**, bobot 400/700. CSS publik Bibit juga menulis `font-family:BitSans` untuk button/input/select. Lato pada Arta sekarang adalah padanan lama, bukan bukti font Bibit; pemilihan produksi belum diubah.
- Stockbit native mempunyai body 16/22, 14/19, 13/18, 12/16, 11/15; headline 20/22 dan 18/20 bold; nominal 24/32 atau 34/46. Ini keluarga style, bukan izin menerapkan ukuran terbesar ke semua layar.
- Style Bibit SSP dapat berubah menurut lebar perangkat; ukuran visual screenshot harus dicocokkan dengan hasil layout 360/412 dan skala font. Jangan menerapkan 1080 raster px secara langsung ke Flutter.
- APK mengonfirmasi aksen `#00AB6B`, background dark `#121212`, primary text dark `#CBCBCB`, light text `#333333`, light surface `#FFFFFF`, serta lapisan/border yang berbeda. Screenshot JPEG tampak sekitar `#111111`/`#222222`; simpan label estimasi bila memakai sampel gambar.
- Tidak memakai satu warna card untuk semua tingkat. Beranda mempunyai section, inner card berbingkai, dan strip informasi tint. Screenshot `224150` mengandung konten panjang/editorial, tetapi hanya strukturnya yang diadaptasi ke data Arta.
- Contoh saham memakai garis ungu + circle tint ungu, reksa dana garis hijau + circle tint hijau. Opasitas warna screenshot belum diklaim sebagai alpha asli; ambil dari sumber vektor/CSS yang cocok bila tersedia.
- Search native Stockbit 40dp, radius 8dp, stroke 1dp; sheet Bibit radius atas 16dp dan keluarga Stockbit 20dp adalah bukti APK. Pilih berdasarkan komponen yang sesuai screenshot, bukan membuat semua radius sama.
- Ikon nav SVG DOM berada pada kanvas 20/21 unit dengan garis 1,5; ikon menu umumnya kanvas 24 unit. Kanvas SVG tidak otomatis sama dengan ukuran sentuh: area sentuh tetap sekitar 48 logical px dan aman dari bilah Android.

## 7. Celah referensi yang masih terbuka

- Video/remote masih berguna untuk durasi animasi, respons swipe, drag tooltip, loading, keyboard, transisi sheet, dan pagination; screenshot membuktikan susunan/state tertentu, bukan seluruh interaksi.
- Screenshot PIN tidak menampilkan sensor; posisi tombol sidik jari ditentukan langsung oleh pengguna. Ikon sensor dapat dicocokkan dengan halaman profil Bibit, tetapi belum ada vektor identik terverifikasi.
- Arahan ikon staking, bunga dan impor/ekspor sekarang ditetapkan dalam perubahan 21 November; vektor finalnya belum dibuat. Sebagian kontrol lain masih perlu pencocokan/ekstraksi berdasarkan referensi. Jangan menutupi celah ini dengan paket ikon baru.
- Semua tema terang layar mobile baru belum dicontohkan dalam folder baru. Resource APK terang ada, tetapi tetap perlu review hasil desain terang Arta.
- Stockbit memiliki resource pemblokiran debugging; bila akses runtime diblokir, gunakan screenshot/rekaman manual yang diizinkan, tanpa memodifikasi APK atau melewati pembatasan. Hotspot/data pengguna tetap dipertahankan.

## 8. Checklist penerapan berikutnya

- [x] Inventaris dan tinjau 59 referensi lama + 67 baru.
- [x] Tinjau potongan semua gambar panjang baru.
- [x] Catat perubahan PIN, overlay biometrik dan istilah Aset.
- [x] Petakan layar, komponen dan ikon beserta sumber/gapnya.
- [x] Cocokkan sebagian geometri dengan sumber online resmi.
- [ ] Lengkapi glyph yang masih bertanda belum cocok.
- [ ] Tetapkan font produksi dan token final dua tema berdasarkan sumber yang cocok.
- [ ] Perbarui komponen dan layar FigCraft, termasuk state PIN/overlay/carousel/filter.
- [ ] Periksa visual FigCraft dan simpan file native, bukan hanya preview.
- [ ] Terapkan Flutter dan penggantian teks Akun → Aset, dengan migrasi hanya bila diperlukan oleh perubahan data nyata.
- [ ] Perbaiki tiga bug pengujian yang sudah tercatat dan implementasikan reset PIN biometrik.
- [ ] Build kandidat uji setelah coding; uji HP untuk safe area, keypad, sensor, font besar, tema dan seluruh fitur yang belum tuntas.

Tidak ada build atau perubahan fitur pada tahap pemetaan ini.
