# Analisis 59 screenshot Stockbit dan penerapan ke Arta

Tanggal: 18 November 2026. Sumber utama adalah seluruh 59 JPG dalam [design/refferences](../../design/refferences/). Semua gambar ditinjau melalui contact sheet; delapan gambar panjang juga diperiksa sebagai 24 potongan pada lebar 412. File asli tidak diubah. [Inventaris ukuran](../../design/reference-analysis/inventory.json) dan [histogram warna](../../design/reference-analysis/sampled-palette.json) menyimpan bukti analisis.

## Cara membaca ukuran dan kepastian

Seluruh sumber berlebar **1080 pixel raster**. Tinggi biasa 2192; screenshot panjang mencapai 13236. Angka desain dinormalisasi dengan `ukuran raster × 412 / 1080`, kemudian dibulatkan ke grid yang konsisten. Ini **bukan bukti density perangkat atau ukuran dp/sp asli**. Screenshot panjang tidak dikecilkan seluruhnya untuk menentukan ukuran komponen.

- **Teramati:** alignment, urutan, jenis kontrol, bentuk umum, scroll, outline, divider dan warna relatif.
- **Perkiraan:** ukuran font, stroke, radius dan HEX karena tidak tersedia file desain/metadata font dan sumber berupa JPEG.
- **Adaptasi Arta:** target sentuh, kontras, warna aksi dan pola yang dibutuhkan domain pencatatan keuangan.

## Tipografi

Nama font asli tidak dapat dipastikan dari screenshot. Bentuk huruf/angka dibandingkan secara visual dengan Lato, Inter dan Roboto; **Lato Regular/Bold dipakai sebagai padanan visual** pada revisi. Tidak ada sumber resmi yang membuktikan bahwa font mobile Stockbit tersebut adalah Lato. Wordmark Stockbit dan logo pada avatar merupakan aset merek, bukan font teks UI. Contoh pembanding ada di halaman FigCraft `06 · Referensi & Spesifikasi v2`.

| Peran | Perkiraan normalisasi referensi | Keputusan Arta v2 |
| --- | --- | --- |
| Judul app bar | 16–18, tebal, terpusat | Lato Bold 18, line height 25 |
| Angka harga utama | 30–34, tebal | 32, tabular figures bila didukung |
| Judul section | 14–16 tebal | 16/22 Bold |
| Kode/nilai list | 14–16 tebal | 14–15 Bold, nominal rata kanan |
| Isi/input | 13–15 normal | 14/20 Regular |
| Label form | 13–14 tebal | 13/18 Bold, di luar field |
| Caption/nama sekunder | 11–13 | 12/17 Regular |
| Tab/chip | 11–13 | 12; aktif Bold + hijau |
| Label bottom nav | 9–11 | 10/14 |

Hierarki pada versi pertama terlalu besar untuk header serta terlalu banyak menggunakan card berisi. Revisi mengecilkan header 22/28 menjadi 18 dan nominal 36 menjadi 32. State kosong memakai headline 18 dan ilustrasi outline tanpa panel hijau besar.

## Warna

Histogram memakai bucket 8 tingkat per channel; hasil seperti `#101010` berarti rentang sampel, bukan HEX sumber yang pasti. Area overlay juga menggelapkan latar, sehingga tidak dipakai sebagai warna halaman utama. Sampel JPEG dominan mendukung latar sekitar `#111111`, sheet sekitar `#282828`, teks sekitar `#CCCCCC` dan hijau sekitar `#00AC6E`.

| Peran | Token gelap Arta v2 | Perlakuan |
| --- | --- | --- |
| Latar/panel biasa | `#111111` | Panel ringkasan dibedakan dengan outline, bukan latar card tebal |
| Raised/section | `#202020` | Search filled, track, section header |
| Sheet | `#282828` | Lebih terang daripada halaman |
| Teks utama | `#D0D0D0` | Mendekati teks abu terang referensi |
| Teks sekunder | `#949494` | Sedikit dinaikkan untuk keterbacaan di sheet |
| Aksen/positif | `#27B58B` | Link, tab, chart, perubahan positif |
| Tombol aksi | `#008356` | Lebih gelap dari sampel agar teks putih 14 terbaca |
| Teks aksi | `#FFFFFF` | Dipakai pada warna action, bukan semua bidang hijau |
| Negatif | `#F06469` | Tanda minus dan teks tetap menyertai warna |
| Divider | `#303030` | Dekoratif, bukan satu-satunya penanda input |
| Batas kontrol | `#767676` | Lebih terang dari sebagian contoh untuk kontras |

[Token aktif](tokens.json) dan ekspor native [JSON](../../design/theme-variables.json)/[Dart](../../design/theme-tokens.dart) sudah diperbarui. Dark dan Light dipertahankan. Theme Light adalah adaptasi Arta; semua screenshot baru ini gelap.

## Spesifikasi per komponen

| Bagian | Yang terlihat pada sumber | Penerapan ukuran/bentuk Arta |
| --- | --- | --- |
| App bar | Back tipis kiri, judul kecil tengah, aksi kanan | Slot tinggi 56; judul 18; target aksi/back 48; chevron sempit 8–9 × 16–18 |
| Bottom navigation | Lima tujuan, outline, label kecil; aktif hijau | Tinggi visual 64; lima slot; ikon 20–24; label 10 |
| Ikon | Outline tipis abu-abu, sedikit ikon solid dalam avatar | Stroke sekitar 1,25–1,5; ikon utama 20–24; glyph editable |
| Tombol primer | Lebar hampir penuh, sudut kecil, label putih tebal | Tinggi 48, radius 4, margin layar 20, label 14 Bold |
| Tombol sekunder/destruktif | Transparan + outline; aksi bahaya merah | Tinggi 48, stroke 1, radius 4; label dan konteks tindakan jelas |
| Tombol empty state | Kadang pill ringkas, bukan selalu lebar penuh | Native CTA pencatatan tetap 48; state memakai ilustrasi outline dan headline 18 |
| Tab utama | Label sejajar; aktif hijau dengan garis bawah | Tinggi target 48; underline 2; tanpa wadah segmented abu besar |
| Periode chart | Label periode kecil, underline pendek saat aktif | Target 48; underline 22 × 2; area/garis tetap editable |
| Filter chip | Pill outline tipis, isi gelap sama dengan layar | Visual tinggi 30–32, radius 15–16, target 48 |
| Search | Magnifier kiri, placeholder abu; outline atau filled | Visual 42, target 48, radius 4, icon 17–20, padding teks 42 |
| Field/form | Label tebal di luar input, outline kecil, isi kiri | Input tinggi 48, radius 4, stroke 1, inset 14, label 13 dan value 14 |
| Form dua kolom | Rentang From/To dengan label section di atas | Dipakai bila dua nilai pendek cukup; form keuangan panjang tetap satu kolom |
| Card ringkasan | Latar halaman, outline tipis, sudut kecil | Radius 4, stroke 1, padding 16; tanpa drop shadow |
| Card konten/editorial | Thumbnail dan teks; sebagian rounded kecil | Dicatat sebagai referensi; feed editorial tidak ditambahkan ke Arta |
| List aset | Avatar bulat, kode tebal, nama redup, sparkline, angka kanan | Tinggi 68, avatar 36, caption 12, nilai 15, sparkline 48 × 20 |
| List menu/akun | Ikon/label kiri, subtitle opsional, chevron kanan | Tinggi 64, datar, divider 1; tidak membungkus setiap row dalam card |
| Divider/group header | Rule sangat halus; strip abu-abu untuk kelompok | Divider dekoratif 1; section spacing mempertahankan kelompok |
| Radio single select | Ring di kanan; terpilih lingkaran hijau bercentang putih | Diameter 20, stroke 1–1,25; seluruh row 56–68 dapat disentuh |
| Multi select | Pada filter movers tampak beberapa lingkaran centang sekaligus | Dicatat berbeda dari radio; tidak disimpulkan sebagai single select |
| Toggle | Track hijau/abu, thumb putih; label terpisah | Sekitar 46 × 26, thumb 18–20; row dapat ditinjau bersama keterangan |
| Bottom sheet | Gray surface, top corners, handle, judul, list datar | `#282828`, radius atas 16, handle 40 × 4, judul 16 terpusat, CTA 48 |
| Action menu | Ikon kiri dan label; danger merah; tanpa radio | Actions jadwal tetap daftar tindakan, bukan pilihan radio |
| Tooltip | Bubble hijau atau panel gelap pada titik chart | Nilai/tanggal eksplisit; tidak mengganti data grafik |
| Tabel | Header ringkas, row dengan rule, angka kanan, sort | Specimen header 40, row 48–56; kolom lebar dapat scroll horizontal |
| Pagination | Tidak terlihat nomor halaman pada seluruh 59 file | Gunakan scroll, pemilih periode dan Tampilkan Semua; komponen Muat lebih banyak adalah adaptasi |
| Date picker | Sheet wheel dan sheet input manual | Pola dicatat; kalender Arta dipertahankan untuk tanggal/jadwal akhir bulan |
| Gesture swipe | Beli hijau kiri dan Hapus merah kanan pada watchlist | Dicatat sebagai referensi; tidak menambahkan fungsi order pada pencatat pribadi |
| Empty state | Ilustrasi outline hijau, headline kecil, caption abu, CTA | Background ilustrasi besar dihapus; pesan dan aksi tunggal jelas |
| Chart | Candle dengan data pasar; line/area dan kombinasi bar/line | Arta tetap line/bar/donut sesuai datanya; tidak meniru candle dari satu harga penutupan |

Semua ukuran adalah spesifikasi rancangan Arta yang mengikuti proporsi referensi, bukan hasil ekstraksi file UI Stockbit. Target sentuh 48 dapat lebih besar dari bentuk visual chip/ikon. Font besar dan layout responsif tetap perlu diuji pada implementasi Flutter.

## Katalog setiap screenshot

| No./file | Layar | Bagian yang dicatat |
| --- | --- | --- |
| 01 / [161145](../../design/refferences/Screenshot_20261118_161145_Stockbit.jpg) | Watchlist dan peringatan | Kartu alert berbingkai, chip dropdown, row logo/kode/sparkline/harga. |
| 02 / [161201](../../design/refferences/Screenshot_20261118_161201_Stockbit.jpg) | Watchlist panjang | Pengulangan row konsisten; divider dan daftar scroll. |
| 03 / [161242](../../design/refferences/Screenshot_20261118_161242_Stockbit.jpg) | Swipe beli | Aksi hijau di kiri row; row bergeser horizontal. |
| 04 / [161247](../../design/refferences/Screenshot_20261118_161247_Stockbit.jpg) | Swipe hapus | Aksi destruktif merah di kanan; bukan card baru. |
| 05 / [161259](../../design/refferences/Screenshot_20261118_161259_Stockbit.jpg) | Tambah kode · sektor | Search outline, grid card radius kecil dan ikon lingkaran. |
| 06 / [161311](../../design/refferences/Screenshot_20261118_161311_Stockbit.jpg) | Tambah kode · grup | Card grup dua kolom, grid sektor, label/count. |
| 07 / [161326](../../design/refferences/Screenshot_20261118_161326_Stockbit.jpg) | Stock Groups | Search outline dan daftar avatar bulat; screenshot panjang. |
| 08 / [161350](../../design/refferences/Screenshot_20261118_161350_Stockbit.jpg) | Laporan | App bar terpusat, list judul multiline dan timestamp, tooltip. |
| 09 / [161358](../../design/refferences/Screenshot_20261118_161358_Stockbit.jpg) | Notifikasi · pengaturan | Section header abu-abu, toggle hijau/abu-abu, thumb putih. |
| 10 / [161418](../../design/refferences/Screenshot_20261118_161418_Stockbit.jpg) | e-IPO · pengantar | Ilustrasi outline, judul/isi, CTA lebar radius kecil. |
| 11 / [161435](../../design/refferences/Screenshot_20261118_161435_Stockbit.jpg) | Stream | Tab underline, search, filter pill, post, action icon dan komentar. |
| 12 / [161457](../../design/refferences/Screenshot_20261118_161457_Stockbit.jpg) | Riset | Menu ikon lingkaran berwarna, list editorial thumbnail kanan. |
| 13 / [161503](../../design/refferences/Screenshot_20261118_161503_Stockbit.jpg) | Berita | Search, judul tebal, metadata dan thumbnail kanan. |
| 14 / [161509](../../design/refferences/Screenshot_20261118_161509_Stockbit.jpg) | Buat postingan | Header dengan aksi kanan, editor kosong, tooltip hijau. |
| 15 / [161514](../../design/refferences/Screenshot_20261118_161514_Stockbit.jpg) | Siapa bisa berkomentar | Bottom sheet, handle, opsi ikon kiri + lingkaran kanan. |
| 16 / [161524](../../design/refferences/Screenshot_20261118_161524_Stockbit.jpg) | Notifikasi kosong | Tab underline dan empty state outline hijau. |
| 17 / [161549](../../design/refferences/Screenshot_20261118_161549_Stockbit.jpg) | Komentar | Teks panjang, metadata, ikon tipis dan input composer pill. |
| 18 / [161554](../../design/refferences/Screenshot_20261118_161554_Stockbit.jpg) | Menu postingan | Action sheet datar dengan ikon; aksi blokir merah. |
| 19 / [161605](../../design/refferences/Screenshot_20261118_161605_Stockbit.jpg) | Market overview panjang | Search, tab ikon, line chart, carousel metrik, list, sektor. |
| 20 / [161627](../../design/refferences/Screenshot_20261118_161627_Stockbit.jpg) | Sectors | Bar horizontal pembanding, row label/persentase dan chevron. |
| 21 / [161632](../../design/refferences/Screenshot_20261118_161632_Stockbit.jpg) | Academy | Card horizontal dengan thumbnail dan label, CTA Selengkapnya. |
| 22 / [161641](../../design/refferences/Screenshot_20261118_161641_Stockbit.jpg) | BBCA · chart harian | Kode/nama/angka besar, candle, range selector, tombol dan tab. |
| 23 / [161651](../../design/refferences/Screenshot_20261118_161651_Stockbit.jpg) | BBCA · chart mingguan | State rentang lain; underline pendek pada periode aktif. |
| 24 / [161659](../../design/refferences/Screenshot_20261118_161659_Stockbit.jpg) | Keystats | Filter pill dan tabel angka rata kanan; divider kelompok. |
| 25 / [161705](../../design/refferences/Screenshot_20261118_161705_Stockbit.jpg) | Orderbook | Tabel rapat, header kolom, garis tipis dan warna bid/ask. |
| 26 / [161711](../../design/refferences/Screenshot_20261118_161711_Stockbit.jpg) | Analisis | Ringkasan rating, bars, target range dan tooltip. |
| 27 / [161724](../../design/refferences/Screenshot_20261118_161724_Stockbit.jpg) | Finansial | Subtab pill, dropdown, tabel multi kolom yang dapat digeser. |
| 28 / [161744](../../design/refferences/Screenshot_20261118_161744_Stockbit.jpg) | Perbandingan | Card identitas berwarna dan nilai per kolom. |
| 29 / [161754](../../design/refferences/Screenshot_20261118_161754_Stockbit.jpg) | Corporate action | Filter pill, list blok key/value, nilai dan tanggal kanan. |
| 30 / [161802](../../design/refferences/Screenshot_20261118_161802_Stockbit.jpg) | Filter insider | Sheet radio; lingkaran terpilih bercentang di kanan. |
| 31 / [161809](../../design/refferences/Screenshot_20261118_161809_Stockbit.jpg) | Insider | Kelompok transaksi, nama tebal, rincian key/value dan chevron. |
| 32 / [161815](../../design/refferences/Screenshot_20261118_161815_Stockbit.jpg) | Profil panjang | Section, expand/collapse, periode, tabel, bars, tooltip, avatar. |
| 33 / [161850](../../design/refferences/Screenshot_20261118_161850_Stockbit.jpg) | Alert kosong | Dua tab underline, ilustrasi outline dan CTA ringkas. |
| 34 / [161901](../../design/refferences/Screenshot_20261118_161901_Stockbit.jpg) | Obligasi | Card outline radius kecil, avatar, tiga metrik per card. |
| 35 / [161907](../../design/refferences/Screenshot_20261118_161907_Stockbit.jpg) | Global index | Row logo/kode/nama dan nilai/perubahan kanan. |
| 36 / [161912](../../design/refferences/Screenshot_20261118_161912_Stockbit.jpg) | Reksa dana | Section strip abu-abu, row logo/kode/nama/NAB/perubahan. |
| 37 / [161921](../../design/refferences/Screenshot_20261118_161921_Stockbit.jpg) | Running trade | Toolbar chip dan tabel rapat; scroll vertikal. |
| 38 / [161927](../../design/refferences/Screenshot_20261118_161927_Stockbit.jpg) | Advance filter | Label di luar field outline, dua kolom, chip preset, toggle. |
| 39 / [161933](../../design/refferences/Screenshot_20261118_161933_Stockbit.jpg) | Stock to display | Search outline, grup radio berbingkai, count dan tombol disabled. |
| 40 / [161941](../../design/refferences/Screenshot_20261118_161941_Stockbit.jpg) | Top broker | Toolbar tanggal/dropdown, header sort dan tabel ber-divider. |
| 41 / [161954](../../design/refferences/Screenshot_20261118_161954_Stockbit.jpg) | Start date · rentang | Sheet opsi radio, tanggal mulai/akhir dan CTA Apply. |
| 42 / [162000](../../design/refferences/Screenshot_20261118_162000_Stockbit.jpg) | Kode broker | Sheet filter pill dan list nama/kode dengan chevron. |
| 43 / [162014](../../design/refferences/Screenshot_20261118_162014_Stockbit.jpg) | Portfolio kosong | Tab, summary outline, tooltip saldo, empty state dan CTA pill. |
| 44 / [162024](../../design/refferences/Screenshot_20261118_162024_Stockbit.jpg) | History kosong | Filter pill, search, header tabel dan empty state. |
| 45 / [162031](../../design/refferences/Screenshot_20261118_162031_Stockbit.jpg) | History realized | Summary outline, section bulan abu-abu, nilai +/- dan tanggal. |
| 46 / [162038](../../design/refferences/Screenshot_20261118_162038_Stockbit.jpg) | Chat list | Avatar, judul tebal, cuplikan, waktu dan unread badge pill. |
| 47 / [162046](../../design/refferences/Screenshot_20261118_162046_Stockbit.jpg) | Pesan baru | Search filled, row ikon bulat dan grouped menu. |
| 48 / [162056](../../design/refferences/Screenshot_20261118_162056_Stockbit.jpg) | Portfolio kosong · variasi | Hierarchy card/empty/CTA dengan ruang kosong besar. |
| 49 / [162143](../../design/refferences/Screenshot_20261118_162143_Stockbit.jpg) | Movers · harga | Tab underline, header sortable, logo dan nilai kanan. |
| 50 / [162148](../../design/refferences/Screenshot_20261118_162148_Stockbit.jpg) | Movers · kolom lain | Tabel horizontal; identitas kiri dan kolom metrik. |
| 51 / [162154](../../design/refferences/Screenshot_20261118_162154_Stockbit.jpg) | Filter movers | Sheet multi-pilih lingkaran, toggle, Reset outline dan Apply. |
| 52 / [162205](../../design/refferences/Screenshot_20261118_162205_Stockbit.jpg) | Unboxing saham | Filter pill, row editorial, thumbnail kanan, divider. |
| 53 / [162211](../../design/refferences/Screenshot_20261118_162211_Stockbit.jpg) | Index | Search outline, row monogram bulat, kode/nama/nilai kanan. |
| 54 / [162221](../../design/refferences/Screenshot_20261118_162221_Stockbit.jpg) | Basic-Ind | App bar dropdown, search/filter, chip dan list aset. |
| 55 / [162228](../../design/refferences/Screenshot_20261118_162228_Stockbit.jpg) | Market · chart | Line/area, tanggal kiri/kanan, metrik outline dan shortcut bulat. |
| 56 / [162237](../../design/refferences/Screenshot_20261118_162237_Stockbit.jpg) | Tanggal · wheel | Sheet input date, roda tiga kolom, baris terpilih dan CTA. |
| 57 / [162247](../../design/refferences/Screenshot_20261118_162247_Stockbit.jpg) | Tanggal · manual | Sheet pendek, field tanggal manual dan CTA. |
| 58 / [162258](../../design/refferences/Screenshot_20261118_162258_Stockbit.jpg) | Net foreign flow | Header metrik, pill, tanggal, bar/line chart dengan sumbu. |
| 59 / [162320](../../design/refferences/Screenshot_20261118_162320_Stockbit.jpg) | Bagikan | Sheet dengan preview, ikon berbagi melingkar dan tombol Batal. |

## Penerapan dalam file FigCraft

File utama: [Arta-Keuangan-Pribadi.figcraft](../../design/Arta-Keuangan-Pribadi.figcraft). Revisi diterapkan ke 95 layar/state yang sudah ada, bukan hanya membuat board referensi. Enam flow prototype dan 709 interaksi tetap dipertahankan.

Halaman ketujuh `06 · Referensi & Spesifikasi v2` memuat specimen native tombol, form, search, radio, list, card, chip, tabel, load-more, pembanding font, ukuran dan warna. Sepuluh contact sheet serta empat sheet detail gambar panjang ditempatkan sebagai **bukti referensi raster**. Layar aplikasi, chart dan specimen komponen tetap layer editable.

Perubahan utama: Inter → Lato; header terpusat 18; angka utama 32; warna abu netral; tombol 48/radius 4; input outline; tab underline; chip outline; list lebih rapat/datar; radio centang kanan; sheet abu; sparkline contoh; empty state outline. Semua fungsi pencatatan yang sudah dirancang dipertahankan.

[Versi sebelum revisi](../../design/archive/Arta-v1-sebelum-revisi-referensi.figcraft) tersedia. [Panduan hasil](../../design/README.md) memuat cara meninjau prototype dan batas simulasi. PNG semua layar tersedia di `design/review-v2/`; preview ringkas di `design/previews/`.

## Verifikasi

- Semua 59 file sumber mempunyai catatan katalog; delapan screenshot panjang diperiksa pada potongan lebar 412.
- Layer bounds, font tersedia, target prototype, tampilan 360, Light preview dan hasil raster diperiksa melalui FigCraft.
- Validator warna memeriksa 114 pasangan teks/chart/kontrol pada kedua mode, termasuk surface sheet dan pasangan teks putih/action. Seluruhnya lulus; kontras teks terendah 4,65:1 (Light) dan 4,72:1 (Dark). Divider dekoratif dan alpha chart ditinjau terpisah.
- Preview memakai data contoh. Ini revisi UI/UX, bukan implementasi database, harga pasar, backup atau transaksi yang berjalan.

