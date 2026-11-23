# Arta 0.2.1 — startup dan diagnostik penyimpanan

Versi: `0.2.1+3`. Perubahan ini menindaklanjuti BUG-001 pada [laporan perangkat](TESTING-APK-0.2.0.md): Samsung A05s, Android 15, berhenti dengan pesan penyimpanan lokal gagal dan retry tidak membantu.

## Perubahan

- Jika pengambilan direktori melalui `path_provider` gagal pada Android, gunakan MethodChannel aplikasi untuk mengambil `applicationContext.filesDir` langsung dari Android.
- Lokasi tetap sama dengan direktori aplikasi yang dipakai sebelumnya, dengan nama database `arta.sqlite`. Tidak memilih cache/direktori sementara, mengganti database, atau menghapus data.
- Kegagalan membuka SQLite/migrasi ditangkap sebelum masuk ke layar utama. Retry membuat percobaan baru dan menutup koneksi yang gagal.
- Tombol retry tidak menjalankan dua pembukaan bersamaan. Hasil operasi yang selesai setelah layar ditutup diabaikan dengan pembersihan sumber daya yang sudah dibuat.
- Halaman gagal membuka penyimpanan memiliki **Rincian error** dan **Salin rincian**, termasuk versi, tahap, dan pesan teknis. Debug log menyimpan error beserta stack startup.
- Tidak menambahkan izin penyimpanan umum. Direktori privat aplikasi tidak memerlukan izin tersebut menurut [Android](https://developer.android.com/training/data-storage/app-specific).

## Hasil dan batas verifikasi

48 pengujian otomatis lulus, termasuk simulasi provider direktori gagal, penggunaan lokasi database lama dengan saldo/transaksi tetap utuh, penolakan lokasi native tidak valid, tampilan diagnostik, retry bersamaan, dan penutupan layar saat operasi masih menunggu. Hasil build dan analyzer final dicatat di `BUILD-0.2.1.json`.

**Uji fisik 19 November 2026:** Samsung A05s SM-A057F, Android 15, terhubung melalui USB. Pembaruan dari 0.2.0+2 ke 0.2.1+3 berhasil tanpa uninstall atau hapus data. Aplikasi berhasil masuk Ringkasan, membuat database privat, lalu berhasil masuk kembali setelah force-stop dan dibuka ulang. BUG-001 tidak muncul pada dua pembukaan ini. Akun masih kosong sehingga pelestarian catatan lama pada HP ini belum dapat diuji; sudah diuji dalam pengujian otomatis.

Akar masalah versi lama belum dapat dipastikan karena catch lama tidak mencatat error asli. Keberhasilan patch tidak membuktikan penyebab tertentu secara terpisah. Bukti: `build/physical-device/arta-startup-021.xml`, `arta-reopen-021.xml`, dan `arta-reopen-021.png`. Uji ini hanya mencakup startup, bukan seluruh fitur checklist. Emulator sempat digunakan untuk diagnosis awal, kemudian dihentikan atas permintaan pengguna dan tidak digunakan lagi untuk verifikasi patch ini.

Pada sesi lanjutan di HP yang sama, 8 kelompok integration test serta alur file Android lulus. Pembaruan APK final mempertahankan 5 akun dan 1 transaksi QA. Hasil, batas cakupan, dan cleanup dicatat pada [laporan pengujian HP](TESTING-HP-2026-11-19.md). Pengujian berakhir dengan APK normal terbuka dan data kembali kosong seperti sebelum sesi; seluruh 26 urutan manual belum diulang persis.

## Uji ulang pada Samsung A05s

1. Ikuti [panduan USB](KONEKSI-HP-USB.md) dan pastikan ADB menunjukkan status `device`.
2. Sebelum mengganti APK, baca log startup versi yang gagal jika memungkinkan.
3. Pasang 0.2.1 sebagai pembaruan, lalu buka. Jangan uninstall/hapus data untuk menguji perbaikan.
4. Jika masuk Ringkasan, periksa akun/transaksi lama dan lakukan tutup-buka sekali lagi.
5. Jika masih gagal, buka **Rincian error > Salin rincian**, catat tahap/kode error di BUG-001 dan ambil log aplikasi Arta.
6. Tandai hasil uji ulang T01, lalu lanjutkan checklist lainnya setelah startup berhasil.

Modul harga CoinGecko belum diimplementasikan pada versi ini. Tidak ada API key yang diperlukan untuk membuka database atau menggunakan pencatatan offline.
