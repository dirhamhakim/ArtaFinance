# Arta — seluruh tampilan versi 0.7.2+11

File utama: [Arta-0.7.2-Seluruh-Tampilan.figcraft](../Arta-0.7.2-Seluruh-Tampilan.figcraft).

Dibuat melalui MCP FigCraft sebagai satu dokumen native yang dapat diedit. Berisi 286 keadaan UI dalam dua tema (572 artboard), 13 halaman APP, satu halaman indeks, dan sembilan halaman LIB berisi master ikon/komponen. Jumlah keadaan mencakup variasi form, pemilih, popup, konfirmasi, kosong, error, dan hasil; bukan 286 fitur terpisah.

## Membuka dan menelusuri

1. Buka file `.figcraft`, mulai dari halaman `00 · Panduan & Cakupan 0.7.2`.
2. Buka halaman berawalan `APP` untuk tampilan versi terbaru. Pasangan Dark di kiri dan Light di kanan.
3. Form dan daftar panjang memakai viewport gulir. Bagian yang tidak tampak pada tangkapan pertama tetap ada dalam konten gulir.
4. Jalankan prototype dari salah satu dari 30 titik awal. Indeks memiliki tombol tema dan tautan kelompok layar.
5. Gunakan [CAKUPAN-LAYAR.md](CAKUPAN-LAYAR.md) untuk mencari route, judul, sumber Flutter dan ID artboard.

Halaman LIB adalah pustaka dan contoh lama untuk referensi komponen, bukan tampilan tambahan yang diklaim tersedia di APK. Tampilan APP didokumentasikan berdasarkan kode 0.7.2+11. Ukuran artboard mobile 400 × 900 logical pixels.

## Cakupan

Ringkasan dan analisis; aset/tunai/bank/e-wallet/debit/utang/piutang; transaksi pemasukan, pengeluaran, transfer, biaya kedua sisi dan lampiran; kategori pemasukan/pengeluaran beserta pencarian, pengarsipan dan aktivasi kembali; transaksi berulang, cicilan dan kejadian jadwal; portofolio saham/crypto/reksadana, transaksi investasi dan harga; grafik komposisi/nilai serta perbandingan saham–IHSG; staking manual; bunga/bagi hasil; katalog dan impor IDX; harga penutupan, refresh manual, kurs; pengaturan tema, backup/restore; PIN, biometrik dan pemulihan; kalender, jam 24 jam dan pemilih Android.

Teks, komponen, ikon dan chart APP berupa layer native yang dapat diedit. Warna diikat ke mode tema semantik. Angka, tanggal, harga, nama dan riwayat pada desain adalah contoh statis.

## Batas prototype

Koneksi mencontohkan navigasi dan perubahan keadaan. FigCraft tidak menjalankan SQLite, perhitungan keuangan, penyimpanan input, API harga, pembacaan file, kamera atau sensor sidik jari. Dialog file/foto/biometrik Android adalah representasi, bukan salinan pasti skin Samsung. Pengujian fungsi tersebut tetap dilakukan pada APK. Dokumen ini tidak mengubah kode atau membangun APK baru.

## Font

Menggunakan Bit Sans Regular/Bold seperti aset Flutter. Keduanya dimuat dan tersedia pada sesi MCP saat pembuatan; **font tidak tertanam dalam file native**. Jika editor menyatakan font hilang, gunakan berkas `assets/fonts/bit_sans_regular.otf` dan `assets/fonts/bit_sans_bold.otf` dari proyek. Folder `previews` menyediakan PNG untuk melihat render tanpa ketergantungan font editor.

## Verifikasi

Seluruh 572 artboard diperiksa secara struktural untuk batas layer dan tujuan prototype; laporan `qa-geometry.json` mencatat nol temuan containment dari aturan pemeriksaan dan nol tujuan tidak valid. Ini tidak menggantikan pemeriksaan visual setiap kemungkinan teks/data runtime. Sampel render yang ditinjau mencakup indeks, Ringkasan, analisis, portofolio/IHSG, staking, kategori, transfer beserta biaya, pengaturan, PIN terang dan pemilih waktu gelap. Semua layar belum diuji satu per satu secara interaktif di FigCraft.

Manifest, inventaris sumber, fingerprint sumber dan hasil simpan tersedia di folder ini. File native disimpan melalui MCP; skrip pendukung hanya menyusun command dan membaca hasil untuk audit.
