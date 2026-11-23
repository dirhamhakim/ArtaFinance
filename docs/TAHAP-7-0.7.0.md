# Arta 0.7.0 — penerapan referensi ke Flutter

Implementasi memakai [desain FigCraft 21 November](../design/full-ui-2026-11-21/README.md) dan revisi saldo besar. File FigCraft tetap tersimpan terpisah; perubahan tahap ini berada pada Flutter.

## Tampilan

- Lima tab ikon: Ringkasan, Investasi, Aset, Transaksi, Pengaturan. Ikon aktif hijau, tanpa teks atau lapisan indikator. Nama tetap tersedia untuk aksesibilitas.
- Bit Sans Regular/Bold dibundel sebagai aset APK. Tidak perlu memasang font pada Windows atau HP, dan tidak perlu mengunduh font saat aplikasi dibuka.
- Tema gelap/terang memakai warna semantik master, card bertingkat, ikon dalam lingkaran tint hijau/ungu, panel pilihan dari bawah, serta konfirmasi dan form sandi dalam panel bawah.
- Ringkasan memuat kekayaan, Aset/Liabilitas/Total, shortcut, produk investasi, carousel arus kas, laporan dan transaksi terbaru.
- Aset dan Liabilitas sebaris; Total memakai lebar penuh di bawah. Nominal yang tidak muat disingkat jt/M/T, dengan rincian angka utuh saat nominal pada card diketuk. Nilai database, ekspor, dan perhitungan tetap utuh. Mata menyembunyikan nominal menggunakan titik.
- Investasi memuat grafik nilai, komposisi yang dapat dibuka, filter kelas, pencarian, detail kepemilikan dan riwayat. Saham vs IHSG memakai hijau dan ungu; setoran tidak diperlakukan sebagai return.
- Pemilih bank/e-wallet memuat 12 logo lokal: BCA, BNI, BRI, Mandiri, Jago, SeaBank, DANA, DOKU, GoPay, LinkAja, OVO, ShopeePay. Jago Syariah memakai Jago. Penyedia lain dapat memakai nama sendiri dan ikon tetap. Sumber/lisensi tersedia melalui Pengaturan → Sumber & lisensi.
- Tombol Simpan transaksi berada di footer, dengan perlindungan inset Android dan keyboard. Halaman lain juga memperoleh SafeArea aplikasi. Teks besar dapat membuat konten lebih panjang dan tetap dapat digulir.

## Kartu debit dengan saldo sendiri

Buka **Aset → Tambah aset → Kelas aset → Kartu debit**. Pilih Jago dan beri nama misalnya Debit Jago Syariah. Saldo kantong ini berdiri sendiri; isi melalui **Transfer** dari bank.

Jika uang sudah tercatat pada saldo bank, gunakan transfer ke kantong debit, bukan membuat saldo awal yang menambah uang yang sama sekali lagi. Saldo noninvestasi tetap boleh minus.

Catatan kartu versi lama tetap disimpan sebagai metode pembayaran rekening. Data lama tidak otomatis diberi saldo baru. Bila ada, menu **Kartu terhubung** menyediakan akses ke catatan tersebut. Nama dan kelas aset lama tidak diubah otomatis.

## Transfer dengan dua biaya

Aktifkan **Biaya transaksi**. Biaya pengirim menjadi pilihan awal; biaya penerima dapat diaktifkan terpisah. Mematikan toggle utama mengabaikan draft kedua biaya saat menyimpan.

Contoh pokok Rp100.000, biaya pengirim Rp2.500, biaya penerima Rp1.000:

- Pengirim berkurang Rp102.500.
- Penerima bertambah Rp99.000.
- Pengeluaran biaya Rp3.500; pokok Rp100.000 tidak menjadi pemasukan atau pengeluaran.

Pada transfer lintas mata uang, nominal tujuan merupakan nominal sebelum biaya penerima. Biaya penerima memakai mata uang tujuan. Isi kurs historis tujuan bila diperlukan agar biaya IDR tidak memakai kurs mata uang asal secara keliru.

Jadwal transfer memakai dua aset bermata uang sama. Biaya aktual satu kejadian dapat diubah tanpa mengubah aturan kejadian berikutnya.

## Transaksi berulang

Form Frekuensi menyediakan 12 pilihan: Setiap Hari, Setiap Hari Tertentu, Setiap Minggu, Setiap 2 Minggu, Setiap 4 Minggu, Setiap Bulan, Setiap Akhir Bulan, Setiap 2/3/4/6 Bulan, dan Setiap Tahun.

**Hari tertentu** berarti memilih satu atau beberapa hari Senin–Minggu. Empat minggu berarti 28 hari. Jadwal tanggal 31 memakai hari terakhir pada bulan pendek dan kembali ke tanggal 31 berikutnya. Tahunan 29 Februari memakai 28 Februari pada tahun nonkabisat, lalu kembali ke 29 pada tahun kabisat.

Aturan lama dengan interval khusus tetap dapat diedit. Cicilan tetap menyimpan total dan membagi dalam sen; sisa pembulatan masuk cicilan terakhir. Tidak ada potongan Mandiri otomatis yang diaktifkan sebagai preset.

## PIN dan sidik jari

Kunci tetap opsional. Layar verifikasi memakai keypad 4×3, sidik jari di kiri bawah, 0 di tengah bawah dan hapus di kanan bawah. Setelah enam angka, tekan **Lanjut**. Loading berada pada lapisan di atas halaman dan tidak memindahkan keypad.

**Lupa PIN?** meminta sidik jari Android terlebih dahulu. Hanya setelah berhasil pengguna dapat membuat dan mengonfirmasi PIN baru. Batal/gagal tidak mengganti PIN dan tidak menghapus data. Jika sidik jari tidak diaktifkan/tersedia, aplikasi menjelaskan bahwa jalur tersebut tidak tersedia. Tidak ada pemulihan melalui login Google.

## Data dan kompatibilitas

SQLite tetap lokal dan tabel finansial tetap skema 5. Identitas penyedia, kelas debit, hari pilihan dan biaya penerima memakai kolom JSON opsional di body data. Backup lama tetap dibaca; gunakan versi 0.7.0 atau lebih baru untuk memulihkan backup yang berisi bidang baru tersebut.

CSV transaksi menambahkan `receiver_fee` dan `receiver_fee_idr_rate`. JSON merupakan format pemulihan lengkap. Saat restore, pilihan otomatis penutupan harian perangkat dipertahankan; API key tetap terpisah dari backup.

## Pengujian

Lihat [checklist HP yang sama](TESTING-APK-0.2.0.md). Hasil HP versi 0.6.0 tetap merupakan riwayat, bukan bukti versi 0.7.0 telah diuji di Samsung. Laporan komputer, hasil build dan identitas APK dicatat di `BUILD-0.7.0.json` setelah verifikasi selesai. Tidak ada emulator atau pemasangan ke HP dalam tahap ini.

Hasil akhir komputer: **182 tes unit/widget lulus**, analyzer bersih, APK versi 0.7.0+9 ditandatangani dengan sertifikat yang sama seperti 0.6.0, 52 master ikon/12 logo dan font terverifikasi di dalam APK. [Identitas/hash lengkap](BUILD-0.7.0.json). Font fallback Lato yang sudah dibundel menangani karakter yang tidak tersedia pada Bit Sans.
