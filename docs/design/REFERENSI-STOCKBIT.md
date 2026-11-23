# Referensi visual Stockbit

Status: catatan riset awal v1. Riset ini telah dilengkapi dengan [analisis seluruh 59 screenshot pengguna dan spesifikasi v2](ANALISIS-REFERENSI-SCREENSHOT.md); file FigCraft sudah direvisi. Tabel token dan tipografi di bawah adalah usulan historis v1. Gunakan [tokens.json](tokens.json) dan analisis v2 sebagai acuan aktif.
Tanggal pengamatan: 18 November 2026, Asia/Jakarta.

## Sumber yang diperiksa

Screenshot berikut diunduh dari artikel bantuan resmi Stockbit dan telah dilihat secara visual. Gambar adalah referensi; data, logo, anotasi dan teks di dalamnya bukan data aplikasi pengguna.

| Sumber resmi | Salinan lokal | Hal yang diamati |
| --- | --- | --- |
| [Portfolio Performance](https://help.stockbit.com/id/article/performance-apa-itu-portfolio-performance-dan-bagaimana-cara-melihatnya-1m46xja/) | [Portfolio](references/stockbit-portfolio.png) | Ringkasan metrik, tabel kepemilikan, tab aktif, navigasi bawah |
| Artikel yang sama | [Performance](references/stockbit-performance.png) | Nilai utama, chart garis/area, pemilih periode, tabel return |
| [Panduan Chartbit](https://help.stockbit.com/id/article/chartbit-bagaimana-cara-menggunakan-dan-apa-fungsinya-1n4gg87/) | [Watchlist/company entry](references/stockbit-company-chart.png) | Logo aset, kode/nama, mini-chart, harga rata kanan |

URL sumber gambar:

- https://storage.crisp.chat/users/helpdesk/website/-/d/e/f/1/def1e0e71ae1e800/1_x34o1b.png
- https://storage.crisp.chat/users/helpdesk/website/-/d/e/f/1/def1e0e71ae1e800/2_e9s479.png
- https://storage.crisp.chat/users/helpdesk/website/-/d/e/f/1/def1e0e71ae1e800/image_rszkpz.png

Ketiga screenshot resmi yang telah diperiksa menggunakan tema gelap. Belum ada screenshot resmi tema terang mobile yang telah diperiksa secara visual pada riset ini. Versi terang di bawah adalah adaptasi untuk aplikasi kita, bukan klaim reproduksi persis Stockbit versi terbaru. Beberapa screenshot dapat berasal dari perangkat/versi berbeda.

## Pola visual yang terlihat

- Latar hampir hitam yang netral, dengan panel sedikit lebih terang dan garis pemisah tipis.
- Hijau digunakan pada tab aktif, tautan/tindakan, garis chart dan angka positif. Merah membedakan angka negatif.
- Jumlah utama lebih tebal dan besar; penjelas serta nama perusahaan menggunakan abu-abu yang lebih redup.
- Ringkasan portofolio berada di atas daftar; angka rata kanan dan judul kolom membantu pemindaian.
- Chart performance berupa garis tipis dengan area hijau transparan, label tanggal sederhana, dan pilihan rentang waktu.
- Tab terpilih memakai warna hijau/garis bawah; pilihan sekunder menggunakan chip atau tombol berbingkai.
- Daftar aset memakai logo, kode, nama singkat, nilai dan perubahan; beberapa baris memiliki mini-chart.
- Navigasi bawah berisi lima tujuan dengan ikon dan label.
- Kepadatan informasi tinggi tetapi struktur berulang membuat daftar mudah dipindai.

Tidak ada klaim mengenai font resmi atau kode HEX resmi: warna, ukuran dan tipografi berikut merupakan usulan yang perlu dinilai melalui prototype.

## Adaptasi untuk aplikasi pribadi

Pertahankan karakter netral, aksen hijau, hierarki angka, chart, dan daftar aset. Beri ruang sentuh serta ukuran label yang lebih nyaman untuk form keuangan Android. Tidak perlu membawa feed sosial, order book, atau alur eksekusi trading ke pencatat pribadi.

| Elemen referensi | Adaptasi |
| --- | --- |
| Ringkasan ekuitas | Kekayaan bersih dengan rincian kas, investasi dan kewajiban |
| Tabel portfolio | Daftar saham, crypto dan reksa dana, dengan detail jumlah/modal/valuasi |
| Performance chart | Pertumbuhan kekayaan dan hasil investasi sebagai grafik yang dibedakan maknanya |
| Range selector | 1B, 3B, 6B, YTD, 1T, Semua; tanggal/rentang kustom bila perlu |
| Stock watchlist | Kepemilikan aset, pencarian dan filter akun/kelas aset |
| Aksi beli/jual | Catat pembelian / Catat penjualan, karena aplikasi tidak mengeksekusi order |

## Tema terang dan gelap

Sediakan pengaturan **Ikuti sistem**, **Terang**, dan **Gelap**. Preferensi disimpan lokal dan tetap berlaku setelah aplikasi ditutup. Semua halaman, modal, keypad, menu, chart, tooltip, kalender dan status bar mengikuti tema.

Usulan token awal, terinspirasi referensi dan bukan warna resmi Stockbit:

| Peran | Terang | Gelap |
| --- | --- | --- |
| Latar | `#F6F7F8` | `#111111` |
| Panel | `#FFFFFF` | `#181818` |
| Panel naik/input | `#EDF1F0` | `#222222` |
| Teks utama | `#151A18` | `#F3F6F4` |
| Teks sekunder | `#59635F` | `#A0AAA4` |
| Pemisah/grid dekoratif | `#DCE2DF` | `#333A36` |
| Aksi utama | `#007A55` | `#00C896` |
| Teks tombol utama | `#FFFFFF` | `#06261C` |
| Positif | `#007A55` | `#00C896` |
| Negatif | `#C73535` | `#FF6B6B` |
| Peringatan | `#8A5700` | `#FFC46B` |
| Informasi | `#215FAD` | `#82B7FF` |

Warna aksi hijau pada tema terang lebih gelap untuk menjaga keterbacaan teks putih. Tema gelap memakai hijau lebih terang dengan teks gelap pada tombol. Keuntungan/kerugian tetap menyertakan tanda +/-, nominal dan persentase, bukan hanya warna.

Gunakan token semantik dalam [tokens.json](tokens.json). Nilai ini dapat diperbaiki setelah review FigCraft; struktur perannya tetap konsisten.

## Tipografi dan bentuk yang diusulkan

- Inter bila tersedia, dengan fallback Roboto; pemilihan ini bukan identifikasi font Stockbit.
- Angka utama 28-32, judul 20-24, isi 14-16, keterangan 12-13. Gunakan ukuran logis Android dan dukung pembesaran teks.
- Angka nominal menggunakan digit berlebar sama bila font mendukung; simbol mata uang dan presisi aset ditampilkan konsisten.
- Spasi berbasis 4/8, margin layar sekitar 16-20, panel radius 12, input 10-12, chip membulat.
- Target sentuh minimal 48 x 48; ukuran ikon biasanya 20-24. Hindari teks kecil dari screenshot sebagai ukuran wajib desain baru.
- Divider dan panel lebih diutamakan daripada bayangan berat. Chart boleh memiliki area transparan; seluruh layar tidak memerlukan gradasi dekoratif.

## Chart yang dibutuhkan

1. Garis/area kekayaan bersih dari riwayat yang tersedia.
2. Batang pemasukan dan pengeluaran per periode.
3. Donut alokasi kas/saham/crypto/reksa dana dengan legenda nominal dan persentase.
4. Chart nilai/harga pada detail aset jika riwayat cukup.
5. Grafik kategori pengeluaran serta progres anggaran.

Sediakan label satuan/periode, pilihan titik untuk melihat nilai, serta ringkasan teks. Data kosong/satu titik tidak digambar menjadi riwayat fiktif. Harga penutupan harian tidak diubah menjadi chart intraday atau candle tanpa data OHLC. Benchmark IHSG baru ditampilkan bila data dan perhitungannya tersedia.

## Batas kejujuran data

- Kekayaan bertambah karena setoran tidak otomatis berarti keuntungan investasi.
- Harga cache wajib menunjukkan tanggal harga, termasuk ketika offline.
- Harga tidak tersedia, modal tidak diketahui, dan NAB manual berbeda statusnya dari nilai nol.
- Bunga estimasi dan transaksi mendatang tidak bercampur dengan saldo yang sudah dicatat.
- Data pada mockup diberi konteks sebagai contoh. Jangan menyalin angka screenshot Stockbit sebagai data nyata pengguna.
