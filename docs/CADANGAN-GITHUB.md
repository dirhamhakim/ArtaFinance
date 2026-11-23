# Cadangan GitHub

Repository: https://github.com/dirhamhakim/ArtaFinance

Cadangan awal disiapkan 23 November 2026, berdasarkan proyek Arta 0.7.2+11. Source Flutter/Android, aset aplikasi dan riwayat harga bawaan, pengujian, skrip, dokumentasi, contoh data, referensi desain dan file native FigCraft disertakan.

## Yang tidak disertakan

- `build/`, `.dart_tool/`, `.tooling/`, cache Gradle dan file IDE: hasil build, dependensi/cache dan SDK yang dapat disiapkan ulang.
- APK/AAB hasil build serta APK Bibit/Stockbit untuk referensi. APK bukan pengganti source dan beberapa melebihi batas ukuran file GitHub.
- `.env` dan variasinya, signing key, konfigurasi lokal Android, database SQLite pribadi dan folder `backups/`.

Database yang sudah dipakai di HP tidak otomatis dicadangkan oleh Git. Ekspor backup dari aplikasi untuk menyimpan transaksi pribadi; simpan secara privat di tempat terpisah.

## Memulihkan proyek

1. Clone repository dan masuk ke direktori proyek.
2. Siapkan Flutter/Dart, JDK dan Android SDK sesuai README. Folder `.tooling/` lokal tidak disalin oleh Git.
3. Pulihkan konfigurasi lokal atau signing key secara terpisah bila diperlukan.
4. Jalankan `flutter pub get`, lalu pengujian/build sesuai panduan proyek. Isi API key CoinGecko melalui Pengaturan aplikasi.
5. Buka desain dari `design/Arta-0.7.2-Seluruh-Tampilan.figcraft`; panduannya ada di `design/runtime-0.7.2/README.md`.

Push ke GitHub tidak menghapus atau mengecilkan folder lokal. Jangan hapus source/desain/data pribadi hanya karena file build/cache dikecualikan dari Git. Verifikasi hasil push sebelum mempertimbangkan pembersihan lokal.
