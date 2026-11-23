# Arta — UI lengkap, 21 November 2026

> **Penerapan Flutter selesai pada 0.7.0:** [preview runtime](../flutter-0.7.0/README.md) dan [panduan APK](../../docs/TAHAP-7-0.7.0.md). Catatan di bawah tetap mendokumentasikan tahap FigCraft, ketika kode/APK belum diubah.

> **Revisi saldo besar:** Aset dan Liabilitas kini sebaris; Total berada di bawah selebar card. Ada enam frame review tambahan untuk nominal besar, layar 360 px/font 130%, dan rincian nilai utuh. Lihat [catatan dan preview revisi](revisi-saldo/README.md).

Tahap 2 desain dibuat lewat **MCP FigCraft headless**, tanpa membuka aplikasi desktop. File utama: [Arta-UI-Lengkap-2026-11-21.figcraft](../Arta-UI-Lengkap-2026-11-21.figcraft). Master tahap 1 tetap ada pada [file terpisah](../Arta-Master-Ikon-Komponen-2026-11-21.figcraft).

Ini desain dan prototype untuk implementasi berikutnya. **Kode Flutter, database dan APK tidak diubah atau dibuild pada tahap ini.** Nilai uang, harga, tanggal dan jumlah baris pada desain adalah contoh, bukan data keuangan pengguna atau hasil permintaan API.

## Hasil

- **176 layar/state/pemilih × dua tema = 352 artboard baru**, ditambah dua contoh QA 360 × 800 dengan teks 130%. Dari 176 pasangan, 45 merupakan sheet/dialog/pemilih.
- Halaman 00–08 mempertahankan library master; halaman 09–18 memuat layar baru dan QA. Ikon, controls dan banyak card/chart tetap merupakan instance master. Delapan donut dengan data yang berbeda dilepas menjadi frame vektor editable agar bentuk arc dan legenda dapat mengikuti konteksnya.
- Theme Dark/Light memakai variabel semantik yang sama. Font desain **Bit Sans Regular/Bold** mengikuti sumber referensi. Lato pada aplikasi lama tidak diganti pada tahap desain ini.
- 12 tujuan awal prototype tersedia per tema: ringkasan, transaksi, aset, investasi, benchmark, staking, berulang, katalog, backup, PIN, awal penggunaan, harga. Dua flow tambahan menunjukkan loading logo Arta. Demo master lama tetap tersimpan.
- **1.908 interaksi** terpasang pada halaman baru dan QA, termasuk navigasi, overlay, timer loading, shortcut dan pemilih. Angka ini menghitung event yang dipasang; bukan jumlah operasi keuangan yang benar-benar dijalankan.
- **19 PNG preview** sudah dirender dengan font sesi MCP. PNG dapat dilihat tanpa memasang font.
- DOKU menggantikan i.saku dalam master logo, pemilih e-wallet, contoh aset dan form. Jago Syariah memakai logo Jago. Debit memiliki saldo kantong sendiri.

## Mulai meninjau

1. Buka file native di atas. Halaman awal yang disimpan adalah **09 · Ringkasan & Laporan**. Setiap pasangan menempatkan Dark di kiri dan Light di kanan.
2. Untuk melihat tanpa kebutuhan font editor, buka [ringkasan gelap](previews/01-ringkasan.png), [ringkasan terang](previews/02-ringkasan-terang.png) atau [konten ringkasan penuh](previews/19-home-konten-penuh.png).
3. Gunakan flow starting point pada prototype. Halaman panjang mempunyai viewport dan konten vertikal; tombol simpan/navigasi dipisahkan dari konten.
4. Tinjau [transfer dua biaya](previews/04-transfer-dua-biaya.png), [benchmark IHSG](previews/06-benchmark-ihsg.png), [12 frekuensi](previews/09-frekuensi-12.png), [DOKU](previews/10-doku-ewallet.png), [PIN](previews/11-pin.png), [overlay biometrik](previews/12-biometrik-overlay.png) dan [QA teks besar](previews/15-qa-360-font130.png).
5. Peta seluruh route dan ID kedua tema tersedia di [CAKUPAN-LAYAR.md](CAKUPAN-LAYAR.md) dan [screen-manifest.json](screen-manifest.json).

## Cakupan desain

| Bagian | Layar/alur yang disiapkan |
| --- | --- |
| Ringkasan & laporan | Total kekayaan, Aset/Liabilitas/Total, privasi titik, card bertingkat, carousel dua keadaan, arus kas, line/donut noninvestasi dan seluruh aset |
| Transaksi | Daftar/cari/filter/kalender, pemasukan, pengeluaran, transfer, pengirim/penerima biaya, catatan/struk, edit/hapus/duplikat, kategori, konfirmasi |
| Aset | Daftar, tambah/edit/arsip/kosong/minus, kelas Bank/E-wallet/Debit/dll., penyedia Indonesia dan Lainnya, DOKU, Jago Syariah, utang/piutang/pelunasan |
| Investasi | Portofolio/alokasi, saham/crypto/reksa dana, detail/riwayat, buy/sell/saldo awal, pindah unit, dividen/reward, split, pencarian IDX/Yahoo dan CoinGecko |
| Benchmark | Dua garis return saham dan IHSG pada periode yang sama, informasi TWR dan tanda kebutuhan histori lengkap; bukan membandingkan saldo rupiah dengan indeks mentah |
| Staking | Pokok, detail aktif, stake, proses unstake, dana cair, reward aktual/restake, biaya/slashing; APR referensi tidak menjadi reward otomatis |
| Reksa dana | Produk dan NAB manual, pembelian menunggu konfirmasi, unit/NAB aktual serta pencairan |
| Berulang & cicilan | 12 pilihan sesuai permintaan, hari tertentu, preview jatuh tempo, riwayat/jeda/lewati/berhenti/catch-up, nominal total atau per pembayaran dan penyesuaian terakhir |
| Bunga | Aturan manual, dasar saldo/hari, tarif bertingkat, pajak/pembulatan, estimasi dan catat aktual/riwayat |
| Harga & IDX | Penutupan saham/IHSG/crypto, permintaan terbaru manual, status cached/429/kosong, impor harga/Sheets CSV, kurs, katalog IDX/Excel/JSON/preview/merge/error |
| Data & pengaturan | Tema, panduan/sumber, backup JSON biasa/terenkripsi/lampiran, restore/password/preview/error/konfirmasi, ekspor CSV, hapus data menuju awal baru |
| Keamanan & pembukaan | Opsional sidik jari/PIN aplikasi, keypad 4×3 tanpa bantuan/back, loading menimpa tanpa menggeser, lupa PIN melalui verifikasi sidik jari, error/lockout, logo dan loading Arta, kesalahan penyimpanan |

## Perilaku yang harus dijaga saat coding

- Aset noninvestasi boleh minus. Liabilitas ditampilkan sebagai besaran kewajiban; kekayaan bersih tidak mengurangi saldo negatif dua kali. Header Total = Aset − Liabilitas.
- Transfer pokok tidak dihitung sebagai pendapatan/beban. Pengirim didebit P + biaya pengirim; penerima dikredit P − biaya penerima. Kedua biaya menjadi beban sekali. Saat biaya dinyalakan, pengirim aktif lebih dahulu; penerima opsional.
- Debit Jago bukan cermin saldo rekening Jago. Pengisian kantong dicatat sebagai transfer.
- Pilihan 4 minggu berarti 28 hari. Jadwal bulanan menjaga jangkar tanggal semula ketika sementara dijepit pada akhir bulan pendek. Tahunan 29 Februari memakai 28 Februari pada tahun nonkabisat dan kembali 29 Februari pada tahun kabisat.
- Preview Mandiri Rp5.500 tanggal 4 dan Rp6.000 akhir bulan adalah contoh input pengguna, bukan preset potongan aktif.
- Harga penutupan dan harga terbaru disimpan terpisah, dengan sumber/tanggal/zona waktu. Penutupan crypto memakai hari UTC selesai sebelumnya. Penutupan saham/IHSG memakai sesi selesai terakhir; hari libur tidak menciptakan titik palsu.
- Holdings, dana menunggu pencairan dan pokok staking dihitung sekali. Modal tidak diketahui, harga/kurs hilang dan histori tidak lengkap tidak berubah menjadi nol atau keuntungan fiktif.
- Impor IDX menggabungkan berdasarkan kode dan menjaga hubungan ke holdings/harga. Semua kolom sumber tetap disimpan; kolom No opsional. Ketiadaan kode pada file terbaru tidak otomatis menghapus instrumen lama.
- Sidik jari harus diverifikasi oleh Android sebelum PIN dapat direset. Prototype hanya menggambarkan hasil berhasil; tidak mengautentikasi siapa pun. Kegagalan/cancel tidak mengubah PIN/data.
- Photo Picker/SAF adalah batas akses file; tidak perlu izin galeri/penyimpanan luas untuk database internal.
- Hapus seluruh data menghapus preferensi/PIN juga dan kembali ke alur pertama. Restore harus divalidasi dan dikonfirmasi sebelum mengganti database; kegagalan mempertahankan data lama.
- Angka dan pilihan di prototype bersifat ilustratif. Keyboard, input teks, pemilihan berkas/foto, sensor Android, API dan database tidak dijalankan FigCraft. Tidak semua radio/pilihan menulis ulang contoh nilai pada layar sebelumnya. Ini tidak menggantikan uji APK.

## Font tanpa instalasi OS

**Flutter tidak membutuhkan font terpasang pada laptop atau HP.** File font dimasukkan sebagai asset dan didaftarkan pada `pubspec.yaml`, kemudian dibundel ke APK sehingga bekerja offline. Proyek saat ini sudah memakai cara ini untuk `assets/Lato-Regular.ttf` dan `assets/Lato-Bold.ttf`.

Untuk FigCraft, `text.loadFont` yang tersedia memuat font hanya pada sesi MCP. File native saat ini **tidak menyematkan file font** (`embeddedFontFiles: 0`). Membuka file di sesi/editor desktop lain bisa tetap memberi peringatan Bit Sans belum tersedia. Font referensi tersedia di [fonts-reference](fonts-reference); PNG preview sudah dirender dengan font yang benar.

Saat melanjutkan lewat MCP, muat kedua file OTF tersebut dengan perintah `text.loadFont {path: ...}`, lalu periksa `file.fontReport`. Ini tidak memasang font ke Windows. [Catatan Flutter dan font](FONT-FLUTTER.md) menjelaskan perbedaan kedua lingkungan.

## Verifikasi

- Font pada sesi render: tersedia, tidak ada keluarga hilang. [font-report.json](font-report.json).
- Seluruh pasangan tema mempunyai root yang tercatat dalam manifest.
- Pemeriksaan batas geometry pada 10 halaman baru: **tidak ada overflow** pada frame yang harus mengurung anaknya. Viewport scroll sengaja memiliki konten yang lebih panjang. [qa-final.json](qa-final.json).
- Layout 360×800, font 130% ditinjau dari render aktual. Lebar input, tab, row, switch dan footer disesuaikan; inset bawah dialokasikan 48 px. Screenshot tidak menggantikan uji font sistem dan SafeArea pada perangkat nyata.
- Layar normal mengalokasikan inset Android tiga tombol 48 px. Keypad PIN berakhir sebelum inset; scrim loading menimpa halaman tanpa memindahkan field atau grid.
- Screenshot aktual telah diperiksa untuk kedua tema, logo, arus kas, benchmark, impor, PIN, overlay, pilihan berulang dan QA. Preview hanya sampel dari seluruh artboard, bukan klaim bahwa setiap artboard ditinjau manual satu per satu.
- File native disimpan dan dibuka ulang; hasil disk/hash dan status tersimpan dicatat pada [saved-native.json](saved-native.json).

## Sumber

Pola utama: screenshot Bibit/Stockbit dari folder referensi pengguna, pemetaan `docs/design/PEMETAAN-ROMBAK-UI-2026-11-20.md`, dan master ikon tahap 1. Sebagian glyph merupakan vektor sumber, sebagian redraw/adaptasi yang sudah ditandai pada manifest master; tidak diklaim semuanya identik per piksel.

Logo penyedia dari [idn-finlogos](https://github.com/hafidznoor/idn-finlogos/tree/443e012b93e5ebeb9948a12de054abca4412a7e6), termasuk [DOKU](https://raw.githubusercontent.com/hafidznoor/idn-finlogos/443e012b93e5ebeb9948a12de054abca4412a7e6/icons/doku.svg). Lisensi aset dan atribusi tetap mengikuti [folder lisensi master](../master-components-2026-11-21/licenses). Logo Arta memakai vektor milik proyek di `design/branding`.
