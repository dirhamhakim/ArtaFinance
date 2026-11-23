# Brief UI/UX untuk FigCraft

> **Tahap 2 selesai — 21 November 2026:** [UI lengkap FigCraft dan panduan](../../design/full-ui-2026-11-21/README.md) memuat 176 pasangan layar/state/pemilih (352 artboard), dua QA 360 px, logo/loading Arta, DOKU, 45 pasangan sheet dan alur fitur terbaru. File native: `Arta-UI-Lengkap-2026-11-21.figcraft`. Ini desain/prototype; kode Flutter/APK belum berubah. Informasi status lama di bawah tetap sebagai riwayat.

> **Tahap master selesai — 21 November 2026:** [file native baru](../../design/Arta-Master-Ikon-Komponen-2026-11-21.figcraft) dan [handoff master](../../design/master-components-2026-11-21/README.md) memuat 52 glyph editable, 12 logo, 97 master UI/contoh, 6 component sets, token dua tema, state PIN/overlay dan tambahan kebutuhan terbaru. Ini belum merupakan rombak seluruh layar proyek lama atau implementasi Flutter. Catatan “belum diterapkan” di bawah merujuk kondisi sebelum tahap master; kebutuhan tambahan sudah dicontohkan dalam master dan masih harus diterapkan ke seluruh alur/aplikasi.

> **Pemilih penyedia Aset:** terapkan [pilihan logo Bank/E-wallet Indonesia](LOGO-BANK-DAN-EWALLET-INDONESIA.md), termasuk bottom sheet pencarian, Bank lainnya/E-wallet lainnya dengan ikon generik tetap, nama aset kustom, dan state terang/gelap. Kelas Debit dapat memakai identitas bank dengan saldo kantongnya sendiri. Katalog/logo belum diterapkan pada desain atau APK.

> **Tambahan 21 November 2026:** [perubahan kebutuhan terbaru](../PERUBAHAN-KEBUTUHAN-2026-11-21.md) wajib diterapkan bersama pemetaan UI: pengerjaan vektor mengikuti referensi, ikon staking/bunga/impor/ekspor, 12 pilihan berulang, biaya transfer pengirim dan penerima, kelas **Debit dengan saldo kantong sendiri**, serta header **Aset / Liabilitas / Total**. Aturan kartu debit yang hanya membaca saldo bank sudah digantikan. Semua ini masih spesifikasi, belum diterapkan ke file FigCraft.

> **Acuan rombak terbaru — 20 November 2026:** baca [Pemetaan Bibit/Stockbit dan layar PIN](PEMETAAN-ROMBAK-UI-2026-11-20.md) sebelum melanjutkan desain. Pengguna meminta rombak total mengikuti referensi baru, navigasi ikon tanpa teks, istilah **Aset** menggantikan Akun untuk wadah saldo, card bertingkat Bibit, dan line chart/filter Stockbit. Bagian di bawah mendeskripsikan desain lama; keputusan yang bertentangan digantikan oleh pemetaan terbaru. Pemetaan baru belum diterapkan pada FigCraft atau Flutter.

Status: desain native FigCraft revisi v3 mempunyai 174 layar/state dan 15 flow. Bentuk/ukuran komponen dan font mengikuti [59 screenshot pengguna](ANALISIS-REFERENSI-SCREENSHOT.md). Hasil utama bertema gelap; semua alur tambahan logo/loading, katalog IDX dan saldo minus memiliki pasangan terang. Lihat [hasil dan panduan review](../../design/README.md).
Tanggal: 18 November 2026.

## Arah yang disepakati

- Aplikasi pencatat keuangan pribadi Android, Flutter, SQLite lokal, seluruh pencatatan offline.
- Referensi visual Stockbit; pola form berulang/cicilan mengikuti kenyamanan Money Manager Realbyte.
- Wajib tema terang dan gelap, dengan pilihan mengikuti sistem dan preferensi yang tersimpan lokal.
- Pengguna memasukkan akun, aturan bunga dan biaya sendiri. Tidak membuat preset bank aktif.
- Saldo noninvestasi boleh negatif. Form pengeluaran/transfer/berulang tidak menolak karena saldo tidak cukup; tampilkan saldo setelah transaksi dengan tanda minus jika sesuai.
- Logo aplikasi, prototype loading dan state saldo negatif sudah ditambahkan ke file native. Master vektor/launcher berada pada halaman 07; seluruh alur katalog pada halaman 08. Spesifikasi ada pada [Identitas dan loading](IDENTITAS-DAN-LOADING.md). Ini desain/prototype; animasi Flutter dan impor nyata belum diimplementasikan.
- Harga Yahoo/CoinGecko/NAB manual memakai cache bertanggal, bukan janji realtime.
- Tidak ada login/cloud sync/backend web pada versi yang sedang dirancang.
- Baca [Rancangan](../RANCANGAN.md), [Panduan draft](../PANDUAN.md), [Referensi Stockbit](REFERENSI-STOCKBIT.md) dan [tokens.json](tokens.json) sebelum membuat layar.

## Peta navigasi yang diusulkan

Lima tab bawah: **Beranda**, **Transaksi**, **Investasi**, **Akun**, **Lainnya**.

- Beranda: kekayaan bersih, ringkasan pemasukan/pengeluaran, chart, jadwal terdekat dan transaksi terakhir.
- Transaksi: tampilan harian/kalender/bulanan, pencarian/filter, tombol tambah transaksi yang mudah dijangkau.
- Investasi: kas investasi, nilai kepemilikan dan laba/rugi dipisahkan; tab saham/crypto/reksa dana; daftar aset dan alokasi.
- Akun: saldo bank/kas/exchange/wallet, akun kewajiban bila digunakan, detail mutasi dan transfer.
- Lainnya: laporan/anggaran, transaksi berulang dan cicilan, bunga akun, backup/restore, kategori, tampilan dan pengaturan harga.

Tab investasi dan form cukup menyebut **Catat pembelian/penjualan**, tidak memberi kesan mengirim order ke exchange/sekuritas.

## Layar dan alur yang perlu dirancang

| Layar/alur | Elemen penting |
| --- | --- |
| Beranda | Kekayaan bersih, sembunyikan nominal, periode, chart, pintasan tambah, jadwal mendatang |
| Transaksi | Daftar berdasarkan tanggal, kalender, filter akun/kategori/jenis, ringkasan pemasukan/pengeluaran |
| Tambah/edit transaksi | Pemasukan/Pengeluaran/Transfer, akun, tanggal, kategori, nominal, catatan, lampiran opsional |
| Berulang | Pilihan pada bagian tanggal: Sekali / Berulang / Cicilan; tanggal mulai, frekuensi, interval, akhir opsional |
| Jadwal bulanan | Radio Tanggal tertentu / Hari terakhir setiap bulan; preview kejadian berikutnya |
| Daftar aturan | Aktif/jeda, kejadian berikutnya, mode otomatis/konfirmasi, edit, lewati, hentikan |
| Cicilan | Total vs nominal per periode, jumlah periode, urutan, rincian bagian, sisa dan status |
| Investasi | Ringkasan, kelas aset, daftar kepemilikan, chart alokasi, label sumber/tanggal harga |
| Detail aset | Jumlah, modal, valuasi, laba/rugi, chart yang tersedia, riwayat, catat beli/jual/transfer |
| Reksa dana | Unit terkonfirmasi, NAB/unit dan tanggal, input harga manual, pending pembelian/pencairan |
| Akun/detail akun | Kelompok akun, saldo, mutasi, transfer, pintasan aturan bunga opsional |
| Bunga akun | Akun, tarif dan tanggal efektif, tingkatan/dasar saldo, kredit harian/bulanan, bruto/potongan/neto, preview |
| Laporan/anggaran | Chart pemasukan/pengeluaran, kategori, alokasi, progres anggaran, pilihan periode |
| Backup/restore | Backup lengkap vs CSV, lokasi file, enkripsi, ringkasan/validasi restore dan dampak penggantian data |
| Tampilan | Ikuti sistem / Terang / Gelap, preview dan penyimpanan pilihan |
| Identitas/loading | Logo/wordmark Arta editable, splash, tiga fase, versi statis, error/coba lagi dan Tentang; gelap/terang |
| Katalog IDX | Impor Excel/JSON lokal, file picker, lima kolom sumber, pratinjau/perbandingan, validasi, sukses/gagal, kode yang tetap disimpan, detail/edit dan ekspor |
| Saldo minus | Preview Rp100.000 − Rp150.000 = −Rp50.000; tombol simpan aktif dan detail akun bertanda negatif |

Contoh konkret pengguna dalam desain Berulang:

1. Mandiri, pengeluaran Rp5.500, setiap bulan tanggal 4.
2. Mandiri, pengeluaran Rp6.000, hari terakhir setiap bulan.

Nama kategori mengikuti input pengguna. Contoh tersebut tidak menjadi jadwal bawaan untuk semua pengguna.

## Sistem komponen

Siapkan komponen reusable: app bar, bottom navigation, tombol utama/sekunder/destruktif, field nominal/tanggal, pemilih akun/aset, segmented control, chip filter/periode, kartu ringkasan, baris transaksi, baris kepemilikan, status badge, calendar cell, chart/legend/tooltip, sheet dan confirmation dialog.

Komponen form mempunyai state normal, focused, filled, error dan disabled. Komponen jadwal membedakan rencana, menunggu konfirmasi, tercatat, dilewati dan dijeda. Jangan mengandalkan warna sebagai satu-satunya penanda.

Tambahkan state saldo negatif pada kartu akun, daftar akun, detail/mutasi, ringkasan dan preview saldo form dalam dua tema. Tampilkan tanda minus dan nominal lengkap; warna merah hanya penanda tambahan, bukan status error yang memblokir. Contoh saldo Rp100.000 dikurangi pengeluaran Rp150.000 menjadi -Rp50.000. Perhitungan kekayaan bersih memakai saldo bertanda; diagram donut tidak menggambar potongan dengan ukuran negatif. Jika menampilkan komposisi, pisahkan besaran saldo positif/negatif dengan label jelas sementara total tetap mengikuti nilai bertanda.

Terapkan auto layout dan component instances. Ikat warna ke koleksi semantik **Theme** dengan mode **Light** dan **Dark**. Teks, stroke, grid, tooltip, sheet, navigation dan input menggunakan token yang sama sesuai peran.

## Chart

- Default chart ringkasan memakai garis/area sederhana seperti referensi Stockbit.
- Pemasukan/pengeluaran memakai grouped bars; alokasi memakai donut dengan legenda dan rincian.
- Sediakan state normal, tooltip terpilih, kosong, satu titik, rentang tanpa data dan harga kedaluwarsa.
- Tidak menggambar candle tanpa OHLC, perbandingan benchmark tanpa datanya, atau history fiktif dari satu harga terbaru.
- Jelaskan perbedaan pertumbuhan total kekayaan dan return investasi; setoran tidak diberi label keuntungan.

## Penyusunan file FigCraft yang disarankan

1. Foundations: warna dua mode, tipografi, spacing dan aturan angka.
2. Components: komponen dan state yang digunakan.
3. Halaman fitur: Beranda & Transaksi, Investasi, Akun/Jadwal/Bunga, Laporan/Pengaturan.
4. States & Flows: panel pilihan, konfirmasi, kosong/error/sukses, preview terang dan ukuran 360 px. Enam flow tersedia pada prototype.

Mulai dari layar utama dan form transaksi/berulang untuk review, lalu lengkapi seluruh alur yang diminta. Jangan menganggap satu dashboard sebagai seluruh frontend yang selesai.

Ukuran utama usulan 412 x 915 logical pixels; periksa juga lebar 360, safe area Android dan teks membesar. Target sentuh minimal 48. Bahasa Indonesia dan format nominal lokal. Data contoh harus konsisten antar layar.

## Pemeriksaan sebelum penyerahan desain

- Tahap saat ini: alur lama utama dirancang gelap. Seluruh state tambahan v3 mempunyai pasangan terang, dengan tiga konteks navigasi terang dan preview beranda terang lama. Layar lama lainnya belum semuanya dipasangkan; perubahan tema tidak hanya mengganti latar.
- Teks biasa minimal kontras 4,5:1 pada surface aktual; kontrol/garis chart penting diperiksa terpisah. Divider/grid dekoratif bukan teks dan bukan satu-satunya batas kontrol.
- Nominal panjang, nama aset panjang, caption, legenda dan keypad tidak terpotong.
- Periode dan tanggal harga terlihat; offline tidak menghalangi form transaksi.
- Diagram/chart dan teks tetap editable; layar tidak diratakan sebagai satu gambar.
- Prototype back, close, simpan, pilihan akhir bulan dan ganti tema dapat ditinjau. Tandai interaksi yang hanya simulasi.
- Periksa layer tree dan screenshot aktual melalui MCP FigCraft; koreksi sebelum mengekspor preview dan menyimpan file native.

## Kesiapan MCP dan skill

- MCP FigCraft telah diuji baca melalui inspect_ui dan list_commands; sesi headless merespons.
- Variabel koleksi/mode, binding warna, auto layout, komponen, prototype dan penyimpanan native tersedia melalui command discovery.
- Tidak perlu plugin atau akun Figma untuk memakai MCP FigCraft ini.
- Skill lokal khusus **figcraft-ui-ux** telah divalidasi dan dipasang di `C:/Users/User/.codex/skills/figcraft-ui-ux/SKILL.md`; salinan yang dapat ditinjau ada di [skills/figcraft-ui-ux/SKILL.md](../../skills/figcraft-ui-ux/SKILL.md).
- Pemasangan skill pihak ketiga UI UX Pro Max melalui Git/unduh gagal karena koneksi GitHub terputus. Skill pihak ketiga tersebut tidak terpasang; skill lokal di atas adalah hasil yang dipasang.
- Browser host visual tidak tersedia pada percobaan ini; tiga screenshot resmi berhasil diunduh melalui curl dan diperiksa lewat view_image. Hal ini tidak menghalangi MCP FigCraft.
- Skill baru tersedia pada giliran berikutnya; pekerjaan desain berikutnya dapat menggunakan `$figcraft-ui-ux`.

## Hasil verifikasi persiapan

- Validator resmi skill-creator menghasilkan `Skill is valid!` sebelum pemasangan.
- Hash SHA-256 SKILL.md terpasang sama dengan salinan workspace.
- Ketiga screenshot referensi sudah dibuka melalui view_image.
- Pemeriksaan awal 86 pasangan warna di [check-design-contrast.cjs](../../scripts/check-design-contrast.cjs) lulus. Rasio teks terendah 4,62:1 pada tema terang dan 5,73:1 pada tema gelap; garis/seri chart serta border kontrol yang diperiksa melampaui 3:1.
- Angka kontras di atas hanya menguji pasangan token solid yang didefinisikan. Overlay, alpha, disabled state, penempatan aktual dan ukuran huruf tetap diperiksa pada desain FigCraft.
