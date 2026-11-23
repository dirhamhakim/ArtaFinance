# Arta — master ikon dan komponen

> Revisi 21 November 2026: card Aset/Liabilitas/Total dan privasinya memakai dua kolom atas dan Total selebar card di bawah. [Aturan saldo besar dan preview](../full-ui-2026-11-21/revisi-saldo/README.md).

Dibuat 21 November 2026 melalui **MCP FigCraft, backend headless**. Tidak membuka aplikasi desktop, tidak mengubah kode Flutter dan tidak membuild APK.

File utama: [Arta-Master-Ikon-Komponen-2026-11-21.figcraft](../Arta-Master-Ikon-Komponen-2026-11-21.figcraft). [Preview sampul](previews/cover.png). Proyek lama `Arta-Keuangan-Pribadi.figcraft` tetap dipertahankan.

## Isi yang sudah dibuat

- **161 main components:** 52 glyph vektor, 12 logo penyedia, dan 97 master UI/contoh komposisi.
- **6 component sets** untuk state tombol, field nominal, radio, toggle, navigasi dan pihak biaya transfer.
- **33 variabel** dalam koleksi Theme (Dark/Light) serta IconTone; **6 text styles** Bit Sans.
- Contoh UI utama dibuat berpasangan gelap/terang. Katalog glyph mempunyai papan kedua tema; sumber logo mempertahankan warna mereknya.
- **4 flow demo** dengan 43 interaksi yang dipasang: komposisi, PIN/overlay, biaya dua pihak, dan pemilih bank. Ini wiring prototype, bukan aplikasi yang menjalankan autentikasi atau transaksi.
- **14 PNG preview**, 52 SVG glyph, 12 SVG badge berwarna dan 12 SVG logo penyedia.

| Halaman native | Isi |
| --- | --- |
| 00 · Mulai & Rujukan | Sampul dari instance ukuran asli; potongan screenshot Bibit, PIN dan Stockbit sebagai pembanding |
| 01 · Token & Tipografi | Bit Sans Regular/Bold, hierarki ukuran, nested section/card/strip informasi |
| 02 · Master Ikon | 52 glyph editable, 12 badge tint, atlas 12 logo penyedia; dua tema untuk glyph/badge |
| 03 · Kontrol & Form | Tombol dan state, field dan error/fokus, search, sandi/mata, dropdown, radio, toggle, chip, navigasi ikon, indikator carousel, tab dan 4 keadaan biaya |
| 04 · Card & Daftar | Aset/Liabilitas/Total, privasi nominal, Debit, investasi, produk, informasi/peringatan, baris aset/holdings/transaksi/jadwal/menu/staking, preview transfer, auto layout dan slot konten |
| 05 · Sheet & Pemilih | 12 frekuensi, hari tertentu, filter, urutkan, bank/e-wallet, opsi Lainnya, rincian saldo, tema, restore, kalender dan jam 24 jam |
| 06 · Chart & State | Line/area, portfolio-vs-IHSG, tooltip, pemasukan/pengeluaran, donut, kosong/satu titik/harga hilang, ilustrasi keuangan, skeleton/error/retry/load-more |
| 07 · PIN & Biometrik | PIN kosong/terisi/error, loading scrim penuh, reset via biometrik, buat dan konfirmasi PIN; keypad 4×3 dengan sidik kiri bawah |
| 08 · Komposisi & QA | Contoh Ringkasan, Aset, transfer pengirim/dua pihak, portofolio, reflow 360px dengan teks 130%, serta frame demo |

## Referensi dan batas kesamaan

Acuan: [pemetaan Bibit/Stockbit](../../docs/design/PEMETAAN-ROMBAK-UI-2026-11-20.md), [kebutuhan 21 November](../../docs/PERUBAHAN-KEBUTUHAN-2026-11-21.md), dan [katalog logo](../../docs/design/LOGO-BANK-DAN-EWALLET-INDONESIA.md).

Geometri asli DOM digunakan ketika tersedia, termasuk rumah/pie/panah Bibit, produk saham/reksa dana dan keluarga logout Stockbit. Sidik jari memakai path yang diekstrak dari resource APK Stockbit dengan viewport 18 yang benar, bukan gambar raster. Ikon lain digambar ulang mengikuti bentuk referensi atau adaptasi yang diizinkan pengguna; **tidak diklaim seluruh 52 glyph identik piksel dengan aplikasi referensi**. Status masing-masing ada pada [icon-sources.json](icon-sources.json) dan description komponen native.

Staking memakai gembok, bunga memakai tunas reksa dana, dan ekspor/impor memakai logout yang diputar sesuai arah panah. Jago Syariah menggunakan logo Jago sesuai keputusan pengguna. Ikon generik tersedia untuk Bank/E-wallet lainnya.

Bentuk, hierarki dan kepadatan mengikuti referensi; beberapa warna teks terang dan warna tombol disesuaikan untuk keterbacaan. Accent fill referensi `#00AB6B` tetap tersedia, sedangkan CTA memakai `Action #008354` dengan teks putih. Badge mempunyai tint tersendiri agar lingkarannya tetap terlihat di atas card yang juga berwarna. Token ini adalah keputusan Arta, bukan klaim spesifikasi resmi merek.

PNG sumber di papan Rujukan hanya menjadi bukti visual. Card, kontrol, ikon dan chart Arta tetap berupa layer/text/vector/component/instance yang dapat diedit. Data angka dalam contoh adalah data ilustrasi; tidak diambil dari keuangan pribadi pengguna.

## Pemeriksaan yang dilakukan

- Render aktual dari MCP untuk tema gelap/terang, komposisi, pemilih bank, PIN, transfer, chart dan katalog ikon.
- Perbaikan posisi path grafik dan penggunaan arc terbuka untuk donut/spinner tanpa garis radial.
- Baseline benchmark 0%; endpoint contoh portofolio +11,11% dan IHSG +2,96% konsisten dengan legenda.
- Perbandingan bounds PIN normal dan PIN loading: field serta **12 sel keypad identik**; overlay tidak menggeser halaman.
- Navigasi mempunyai area sentuh setinggi 48; keypad memakai seluruh sel. Tidak ada bantuan/back pada layar kunci awal dan tidak ada teks visual pada bilah navigasi.
- Reflow komponen ringkasan, baris dan container pada **360px, teks 130%**: nominal tidak terpotong/terpecah, ringkasan dapat turun baris. Ini contoh komponen responsif; belum membuktikan seluruh layar aplikasi sudah responsif.
- SVG hasil ekspor diparse dan file preview diverifikasi pada disk. [Bukti pemeriksaan native](qa-native.json) dan hasil verifikasi file tersedia pada `qa-files.json`.

## Cara menggunakan

1. Buka file native di atas. View awal diarahkan ke sampul halaman 00.
2. Gunakan halaman 02–07 atau panel Assets untuk mengambil master/variant. Gunakan instance agar perubahan master tetap mengalir ke contoh pemakaiannya.
3. Ubah mode Theme pada frame/instance untuk Light atau Dark. IconTone memisahkan neutral/green/purple/blue/red/muted.
4. Halaman 08 memuat flow demo. Navigasi menuju contoh yang tersedia; sheet bank dan frekuensi mempunyai close/outside dismissal. Toggle biaya pada demo memperlihatkan varian pengirim/dua pihak.
5. Pada demo PIN, tombol sidik menuju overlay lalu kembali ke PIN; ini hanya demonstrasi penempatan loading. Reset PIN menampilkan contoh langkah berikutnya, **tidak melakukan otorisasi biometrik sungguhan**. Input keypad, pencarian, kalender, chart tooltip/swipe carousel dan penyimpanan tidak diimplementasikan sebagai logika aplikasi dalam file desain.

### Font pada sesi lain

Bit Sans dimuat melalui `text.loadFont`; laporan sesi menyatakan tidak ada font hilang. File native melaporkan tidak mengembed font. Dua berkas referensi ada di `fonts-reference/`. Bila membuka pada sesi Craft lain yang belum mempunyai Bit Sans, muat kedua OTF tersebut melalui perintah MCP yang sama. Font ini disertakan untuk pekerjaan desain privat; pilihan/lisensi font produksi aplikasi tetap harus dituntaskan sebelum distribusi. Font Flutter saat ini belum diubah.

## Handoff

- [Manifest node native](component-manifest.json) memetakan nama fungsi ke ID; component-set variants dapat mempunyai nama native seperti `State=Default`.
- [Variabel tema](theme-variables.json) dapat diimpor kembali ke FigCraft.
- `icons/` dan `badges/` adalah ekspor dari master native. Warna SVG ekspor telah di-resolve; untuk Flutter berikutnya gunakan token/ColorFilter atau ekspor varian sesuai kebutuhan.
- `brand-logos/` mempertahankan rasio logo; simpan atribusi sumber. Lisensi dan NOTICE sumber ada pada `licenses/`.
- `svg-sources/` adalah input kerja sebelum penyuntingan native; ekspor final ada di `icons/`/`badges/`.
- Berkas generator dan penyiapan aset berada pada `build/figcraft-master-20261121/`. Native yang diserahkan adalah hasil akhir setelah inspeksi/koreksi MCP, bukan semata keluaran generator awal.

## Pekerjaan berikutnya

Gunakan master ini untuk merombak seluruh layar/alur FigCraft, lalu implementasikan Flutter dan pengujian. Ini **menyelesaikan tahap master ikon/komponen**, belum menggantikan seluruh 174 state proyek lama atau menyelesaikan bug/fitur APK yang masih tertunda. Tidak ada perubahan pada HP atau aplikasi Bibit/Stockbit selama pengerjaan ini.
