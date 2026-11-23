# Arta 0.3.0+5 — APK debug tersedia

Tanggal: 19 November 2026, Asia/Jakarta.

Pengguna menyetujui build setelah menerima permintaan konfirmasi. **APK debug 0.3.0+5 berhasil dibuat dan identitas serta tanda tangannya diverifikasi.** Unduh [arta-0.3.0-debug.apk](../build/app/outputs/flutter-apk/arta-0.3.0-debug.apk). Paket `id.arta.arta` dan sertifikat sama dengan versi sebelumnya; simpan backup lalu pasang sebagai pembaruan tanpa uninstall. APK belum dipasang atau diuji di HP. Tidak memakai emulator, tidak menguji login Google, dan tidak menjalankan reset limit. Reset limit dilakukan pengguna sendiri.

Ukuran APK 175.286.998 byte; Android minimal API 24, target API 36. SHA-256: `12e4cedde3b14c08f89bf005f70c43a3af05eed2fc17eaaec1e27338a99b0a86`. Identitas lengkap tersedia di [catatan build](BUILD-0.3.0.json).

## Fitur yang diimplementasikan

### Kunci aplikasi opsional

- Menu **Pengaturan > Kunci aplikasi**. Instalasi baru tidak terkunci dan tidak meminta login.
- Aktivasi meminta PIN Arta 6 angka dan pengulangannya melalui keypad angka kustom, tanpa keyboard teks. Mata untuk melihat/sembunyikan PIN dan tombol hapus angka tersedia.
- Pilihan **Utamakan sidik jari** aktif secara default jika sidik jari tersedia dan terdaftar di HP. Ini memakai dialog sistem Android, bukan data sidik jari yang disimpan aplikasi. Android 7–8.0 menggunakan PIN aplikasi; dialog biometrik native tersedia mulai Android 9.
- PIN Arta terpisah dari PIN layar kunci HP. PIN tidak disimpan sebagai teks biasa: verifier memakai PBKDF2 600.000 iterasi dengan salt acak 16 byte. Konfigurasi/verifier dienkripsi AES-GCM memakai kunci Android Keystore. Android 8+ menggunakan HMAC-SHA256; kompatibilitas Android 7 menggunakan HMAC-SHA1.
- Setelah lima PIN salah, jeda dimulai 30 detik, lalu 60, 120, 240 dan maksimal 300 detik. Hitungan tersimpan di perangkat. Pada boot yang sama, timer native memakai waktu monoton agar perubahan jam HP tidak memotong jeda. Sidik jari yang berhasil dapat membuka aplikasi dan menghapus hitungan gagal.
- Kunci aktif saat aplikasi masuk latar belakang, termasuk saat memilih foto/file. Halaman dan draft form dipertahankan di balik layar kunci. Hasil autentikasi terlambat setelah sesi dibatalkan tidak membuka layar.
- Mengubah PIN/pilihan biometrik atau menonaktifkan kunci memerlukan autentikasi ulang. Tersedia **Kunci sekarang**.
- Saat kunci aktif, Android FLAG_SECURE melindungi screenshot dan pratinjau aplikasi. Karena itu screenshot pengujian HP mungkin ditolak sampai kunci dinonaktifkan. Screenshot widget yang disertakan berasal dari pengujian komputer.
- Error membaca konfigurasi keamanan tidak dianggap sebagai kunci nonaktif. Tampilan tetap tertutup dan menyediakan percobaan ulang.
- Konfigurasi keamanan tidak masuk backup keuangan. Restore tidak mengganti PIN atau pengaturan kunci perangkat tujuan. Hapus data melalui Android menghapus konfigurasi aplikasi; sidik jari dan PIN sistem HP tidak berubah. Tidak tersedia reset PIN melalui akun online.

Kunci ini membatasi akses UI aplikasi. SQLite tidak diubah menjadi database terenkripsi; backup terenkripsi tetap merupakan fitur terpisah. Jika lupa PIN dan biometrik tidak dapat dipakai, pemulihan memerlukan backup yang dimiliki pengguna setelah menghapus data aplikasi. Aplikasi tidak menjalankan penghapusan data tersebut otomatis.

### Tanggal dan jam

- Tanggal tetap melalui kalender. Tombol jam menggunakan dial analog berformat **24 jam**, tanpa AM/PM; angka yang disimpan `HH:mm`.
- Transaksi baru memakai jam pada zona Indonesia yang dipilih/digunakan. Data transaksi lama tanpa jam tetap kosong, bukan diasumsikan pukul 00:00. Form menampilkan **belum dicatat** sampai pengguna memilih jam.
- Zona WIB, WITA dan WIT memakai zona yang sudah didukung mesin jadwal. Label waktu transaksi menampilkan zona agar terbaca jelas.
- Transaksi berulang/cicilan dapat mempunyai jam rencana. Kejadian hari ini baru jatuh tempo setelah jam tersebut; hari-hari terlewat tetap diproses saat aplikasi aktif/dibuka. Transaksi otomatis memakai jam rencana; konfirmasi manual dapat memilih jam aktual.
- Pemrosesan saat aplikasi aktif memeriksa perubahan menit, bukan hanya pergantian hari. Belum ada alarm/worker Android latar belakang atau notifikasi.
- Urutan transaksi bertanggal sama mengikuti jam, kemudian urutan penyimpanan. Transaksi lama tanpa jam tidak diberi waktu buatan. Pencarian juga mendukung jam.

### Foto struk

- Pada transaksi biasa/edit transaksi, gunakan **Foto struk > Tambah foto > Pilih foto**. Panel pilihan muncul dari bawah, kemudian Photo Picker sistem. Jika Photo Picker tidak tersedia, gunakan pemilih dokumen sistem.
- Tidak menambahkan izin galeri, seluruh penyimpanan, atau kamera. Belum ada pengambilan foto langsung melalui kamera.
- Gambar diperkecil dengan sisi terpanjang maksimal sekitar 1.600 piksel, diperbaiki orientasinya, dan diubah menjadi JPEG. Metadata asli tidak disertakan dalam hasil JPEG.
- Maksimal tiga gambar per transaksi, maksimal 2 MB per JPEG. Tersedia thumbnail, pembesaran, dan hapus lampiran sebelum disimpan.
- Salinan gambar disimpan sebagai data JPEG dalam JSON transaksi pada SQLite privat. Tidak memakai tautan galeri yang dapat hilang dan tidak mengunggah ke server. Menghapus transaksi ikut menghapus salinan gambar di database.
- Foto ikut backup JSON dan enkripsi. Batas keseluruhan backup tetap **25 MB**; lampiran menambah ukuran file. Jika batas terlampaui, ekspor ditolak tanpa menghapus data. Ukuran/perkembangan penyimpanan perlu ditinjau jika pengguna mulai menyimpan banyak foto.
- Aturan berulang tidak menduplikasi foto ke semua kejadian. Setelah kejadian dicatat, lampirkan foto dengan mengedit transaksi aktualnya.

### Ilustrasi kosong

Vektor kucing dibuat melalui CustomPainter dan ikon Flutter, tanpa unduhan gambar tambahan, dependensi desain baru, atau MCP baru. Variannya mencakup akun/dompet, transaksi/struk, kalender jadwal, pencarian, kartu, dan lampiran kosong. Warna mengikuti tema gelap/terang; dekorasi tidak dibacakan berulang oleh pembaca layar.

### Kartu debit Jago Syariah

- Akses dari **Akun > Kartu debit** atau **Pengaturan > Kartu debit**.
- Tambahkan akun bank yang mewakili rekening/kantong sumber Jago dahulu. Buat kartu dan pilih sumbernya. Tidak menyimpan nomor kartu, PIN ATM, atau CVV.
- Kartu adalah metode pembayaran tanpa saldo sendiri. Membuat kartu tidak menambah total aset.
- Pada transaksi biasa, pilih rekening sumber lalu pilih kartu yang tertaut melalui **Metode pembayaran**. Nominal mengurangi rekening sumber sesuai jenis transaksi; saldo boleh minus seperti akun lain.
- Mengubah tautan kartu hanya mengubah pilihan sumber untuk transaksi baru. Sumber transaksi lama tetap tersimpan. Mengedit catatan transaksi lama tidak memindahkannya ke rekening baru. Pemulihan backup juga mempertahankan sumber historis tersebut.
- Ini kartu debit, bukan pencatatan utang kartu kredit. Saat ini aturan berulang tetap memilih akun langsung; metadata kartu dapat dipilih pada transaksi aktual setelah dicatat.

## Data dan kompatibilitas

SQLite naik dari versi 2 ke **3**, dengan tabel baru `payment_cards`. Waktu dan lampiran menjadi field opsional pada body transaksi. Jadwal mempunyai waktu opsional. Jalur migrasi versi 1 tetap membuat tabel jadwal, kemudian tabel kartu; versi 2 hanya menambahkan tabel kartu.

Backup baru memakai schema **3** dan menyertakan kartu/foto/jam. Backup schema **1 dan 2 tetap dapat diimpor**. Versi aplikasi lama tidak dapat membaca backup v3; simpan backup lama sebelum memasang pembaruan. Format amplop enkripsi tetap versi 1.

## Validasi komputer

- [x] Analyzer bersih pada kode final: `No issues found`.
- [x] **75 kasus Dart/Flutter terverifikasi**: satu eksekusi suite berisi 74 kasus lulus, kemudian tujuh kasus UI dijalankan ulang setelah penambahan satu kasus alur aktivasi/nonaktif dan perbaikan penutupan fokus keyboard. Tujuh kasus UI final tersebut lulus. Jumlah kasus unik terverifikasi 75; bukan klaim satu eksekusi suite akhir berisi 75 kasus. Termasuk migrasi SQLite v1/v2 ke v3.
- [x] Pemeriksaan tipe empat berkas Kotlin Android melalui compiler Kotlin 2.4.20 terhadap Android SDK/Flutter embedding cache. **Ini tidak membuat APK dan tidak menjalankan Gradle assemble.**
- [x] Uji PIN di JVM: validasi enam angka, jadwal jeda progresif, kedua KDF, panjang verifier, perubahan PIN dan salt. Menjalankan `scripts/check-android-native.ps1`.
- [x] Tinjauan screenshot widget ponsel 360 × 800 untuk layar kunci, jam, kartu, serta ilustrasi gelap/terang. Alur kunci juga menguji keyboard form lama ditutup saat dikunci dan draft tetap ada sesudah dibuka.
- [x] Build APK debug setelah persetujuan pengguna; versi 0.3.0+5, paket, checksum dan tanda tangan terverifikasi. Sertifikat sama dengan APK sebelumnya.
- [ ] Pengujian Samsung A05s Android 15: **belum dijalankan untuk versi ini**.

Hasil rinci tercatat pada [VALIDASI-0.3.0.json](VALIDASI-0.3.0.json) dan [BUILD-0.3.0.json](BUILD-0.3.0.json). Tes fake biometrik tidak menggantikan pengujian sensor HP, Keystore perangkat, lifecycle Android asli, dan pemilih foto sistem.

Log: [suite 74 kasus](../build/tests-0.3.0.log), [rerun tujuh kasus UI final](../build/ui-final-0.3.0.log). Preview: [kunci PIN](../build/ui-review/pin-lock-dark.png), [jam analog](../build/ui-review/time-picker-dark.png), [kartu debit](../build/ui-review/cards-dark.png), [kucing gelap](../build/ui-review/cat-empty-dark.png), dan [kucing terang](../build/ui-review/cat-empty-light.png).

## Checklist pengujian APK di HP

Semua item berikut **BELUM DIUJI di HP pada versi 0.3.0**. Gunakan data uji/backup terlebih dahulu. Jangan uninstall aplikasi utama untuk memperbarui APK.

- [ ] **N01 — Pembaruan:** pasang sebagai update dari 0.2.2; rekening, saldo minus, transaksi, jadwal, tema, dan pilihan sembunyikan nominal tetap sama.
- [ ] **N02 — Kunci nonaktif:** buka aplikasi; tidak diminta login, PIN, atau sidik jari sebelum diaktifkan.
- [ ] **N03 — Aktivasi:** buat PIN Arta enam angka, uji mata/hapus angka dan konfirmasi yang tidak cocok. Keyboard teks tidak muncul. Aktifkan sidik jari bila sudah terdaftar di HP.
- [ ] **N04 — Lifecycle:** gunakan Kunci sekarang, tutup/buka aplikasi, pindah aplikasi, serta buka pemilih foto/file. Data tidak terlihat sebelum autentikasi dan draft form tidak hilang setelah dibuka.
- [ ] **N05 — PIN dan sidik jari:** uji keduanya, batalkan dialog sidik jari, coba PIN salah lima kali, tutup/buka aplikasi selama jeda. Jeda tetap berlaku; setelah selesai PIN benar bisa membuka. Uji sidik jari setelah jeda PIN.
- [ ] **N06 — Pengaturan kunci:** ubah PIN dan nonaktifkan kunci. Keduanya harus meminta autentikasi ulang. Jangan melakukan clear data kecuali seluruh data sudah dicadangkan.
- [ ] **N07 — Jam:** buat/edit transaksi pukul 00:05, 12:00 dan 23:59. Kalender tanggal serta jam analog dapat digunakan tanpa AM/PM. Transaksi lama tetap tidak mempunyai jam buatan. Periksa urutan dan pencarian jam.
- [ ] **N08 — Jadwal berjam:** buat jadwal beberapa menit ke depan di zona yang sesuai; sebelum waktunya belum tercatat, setelah waktunya tercatat sekali selama aplikasi aktif. Buka ulang dan pastikan tidak ganda. Uji konfirmasi manual dan akhir bulan.
- [ ] **N09 — Foto:** pilih foto dari panel bawah. Tidak ada permintaan akses seluruh galeri/penyimpanan. Uji batal, orientasi foto, tiga lampiran, pembesaran, hapus lampiran, simpan dan buka ulang. Pastikan file asli di galeri tidak dihapus.
- [ ] **N10 — Kartu:** hubungkan Debit Jago Syariah ke akun sumber. Total aset tidak berubah. Catat pengeluaran melalui kartu; hanya sumber yang berkurang. Relink kartu ke kantong lain; sumber transaksi lama tetap.
- [ ] **N11 — Backup:** ekspor dan pulihkan backup v3 biasa/terenkripsi, termasuk foto/jam/kartu dan riwayat jadwal. PIN perangkat tujuan tidak berganti. Impor backup v1/v2 juga tetap bekerja. Jika file terlalu besar, pesan batas 25 MB tampil dan data asli tetap utuh.
- [ ] **N12 — Tampilan:** periksa ilustrasi akun, transaksi, pencarian, jadwal dan kartu dalam tema terang/gelap, font besar, portrait/landscape. Cek nominal tersamarkan di kartu/jadwal.
- [ ] **N13 — Reset:** hanya pada instalasi QA yang sudah dicadangkan, Hapus data Android harus menghasilkan aplikasi kosong dengan tema gelap dan kunci nonaktif. File backup di Downloads serta sidik jari/PIN sistem HP tetap ada.

Format laporan per item: `Hasil: LULUS/GAGAL; langkah; hasil aktual; pesan error; model HP/Android`. Jangan menandai lulus tanpa menjalankan langkah tersebut.

## Rujukan API

- [Autentikasi biometrik Android](https://developer.android.com/identity/sign-in/biometric-auth)
- [Android Keystore](https://developer.android.com/privacy-and-security/keystore)
- [Photo Picker Android](https://developer.android.com/training/data-storage/shared/photo-picker)
- [Time picker Flutter](https://api.flutter.dev/flutter/material/showTimePicker.html)
