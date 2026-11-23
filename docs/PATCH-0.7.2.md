# Arta 0.7.2 — Pengelolaan kategori

Menu **Pengaturan → Pencatatan → Kategori** kini mengelola kategori pemasukan dan pengeluaran. Pada 0.7.1 yang tersedia hanya pilihan kategori dalam form transaksi.

## Cara menggunakan

1. Pilih **Pengeluaran** atau **Pemasukan**, lalu **Tambah kategori**. Isi nama dan simpan. Kategori langsung tersedia di form transaksi, transaksi berulang, dan cicilan, meskipun belum pernah dipakai.
2. Ketuk kategori untuk mengganti namanya. Seluruh transaksi dan jadwal dengan kategori dan jenis yang sama ikut berganti label. Nominal, tanggal, lampiran, saldo, serta riwayat kejadian jadwal tidak berubah. Kategori pemasukan dengan nama sama tidak ikut berubah ketika kategori pengeluaran diubah.
3. Gunakan ikon **Arsipkan kategori** untuk menyembunyikan kategori dari pilihan baru. Riwayat keuangan tetap tersimpan. Jadwal berulang yang sudah menggunakan kategori ini tetap berjalan; jeda/hentikan jadwal melalui menu transaksi berulang jika diinginkan.
4. Aktifkan filter **Arsip** untuk melihat kategori yang diarsipkan, mengganti namanya, atau mengaktifkannya kembali. Nama yang sama pada jenis yang sama tidak dapat dibuat dua kali, termasuk jika salah satunya diarsipkan. Jenis pemasukan dan pengeluaran boleh memiliki nama sama.
5. Kotak pencarian menyaring nama kategori pada jenis dan status arsip yang sedang dipilih. Kategori bawaan dapat diganti nama dan diarsipkan seperti kategori buatan sendiri.

Kategori yang diketik langsung dalam form juga disimpan setelah transaksi/jadwal berhasil disimpan. Menghapus transaksi terakhir tidak menghapus kategorinya. Transaksi lama dengan kategori yang diarsipkan tetap dapat diedit; untuk memakai kategori itu pada transaksi baru, aktifkan kembali terlebih dahulu. Tidak ada penghapusan permanen kategori dari menu ini; gunakan arsip agar hubungan riwayat tetap jelas.

## Penyimpanan dan kompatibilitas

- Daftar kategori tersimpan lokal bersama data keuangan, termasuk identitas, jenis, nama dan status arsip. Tidak memerlukan internet.
- Database SQLite tetap skema 5: katalog ditambahkan pada dokumen `finance_extras` yang sudah ada. Data lama tanpa katalog menggunakan kategori bawaan ditambah nama yang ditemukan di transaksi/jadwal, tanpa mengubah nilainya.
- Backup baru menggunakan **schema_version 6**. JSON biasa dan backup terenkripsi mencakup kategori yang belum digunakan serta arsip. Aplikasi menerima backup versi 1–6. Arta 0.7.1 dan sebelumnya belum mendukung backup versi 6.
- Restore mengganti katalog mengikuti isi backup. Backup lama tanpa katalog menggunakan daftar bawaan dan nama transaksi/jadwal di dalam file tersebut. Menghapus seluruh data aplikasi mengembalikan daftar kategori awal.
- Mengubah nama kategori dijalankan dalam satu transaksi database: katalog, transaksi dan jadwal diperbarui bersama atau dibatalkan bersama bila gagal.

## Verifikasi

**201/201 tes unit/widget lulus** dalam satu rangkaian akhir; analyzer tidak menemukan masalah. Penambahan mencakup 8 kasus repository kategori dan 5 kasus widget/preview: penyimpanan saat database dibuka ulang, kategori belum dipakai, backup terenkripsi, kompatibilitas backup lama, pengubahan nama lintas ledger/jadwal, pemisahan jenis, arsip/aktifkan kembali, duplikat, penghapusan transaksi terakhir, penolakan backup rusak dan rollback SQL ketika sebagian pembaruan gagal. Uji widget mencakup navigasi dari Pengaturan, pemilihan pada transaksi, validasi kategori arsip, landscape/font 200%, serta dua tema.

Hasil otomatis dan identitas APK dicatat pada [BUILD-0.7.2.json](BUILD-0.7.2.json). Checklist HP ditambahkan pada [checklist utama](TESTING-APK-0.2.0.md). Pengujian HP versi 0.7.2 belum dijalankan; pengguna sedang memakai HP dan meminta akses ditunda. PIN/sidik jari tidak diuji ulang pada perangkat. Tes regresi keamanan yang sudah ada tetap menjadi bagian dari suite otomatis laptop.
