# Arta 0.2.2 — perubahan UI ringan

Catatan ini merekam versi 0.2.2. APK lanjutan [0.3.0](TAHAP-3-0.3.0.md) sudah dibuat dan diverifikasi; pengujian versi tersebut di HP masih menunggu.

Tanggal pengerjaan: 19 November 2026 (Asia/Jakarta). Batch ini dikerjakan tanpa emulator, koneksi HP, login Google, atau penghapusan data aplikasi. Tidak ada reset limit yang dijalankan; pengguna mengatur reset limit sendiri.

## Yang tersedia

- Toggle **Biaya transaksi** pada transfer, transfer berulang, dan konfirmasi satu kejadian. Secara bawaan nonaktif untuk transaksi baru; biaya lama yang bukan nol mengaktifkannya saat diedit. Form biaya hanya tampil ketika aktif.
- Mematikan toggle menyimpan biaya nol, meskipun field sebelumnya berisi angka. Draft dipertahankan selama form terbuka bila diaktifkan lagi. Saat berpindah ke pemasukan/pengeluaran, biaya efektif tetap nol. Pencatatan biaya masih khusus transfer sesuai kemampuan ledger saat ini.
- Mengubah biaya aktual satu kejadian tidak mengubah aturan atau kejadian berikutnya. Mengubah jadwal tetap menggunakan alur penggantian jadwal yang sudah ada.
- Tombol mata terpisah untuk sandi dan konfirmasi sandi backup. Saat dialog dibuka ulang, sandi kosong dan tersembunyi. Pembukaan backup terenkripsi menggunakan field yang sama.
- Tombol mata pada header menyamarkan nominal dengan enam titik **••••••** pada ringkasan, akun, transaksi, biaya, serta daftar/detail/riwayat jadwal. Grafik arus kas disembunyikan saat nominal disamarkan agar perbandingan nominal tidak bocor. Teks yang ditampilkan dan dibaca aksesibilitas menggunakan nilai yang sudah disamarkan.
- Pengaturan penyamaran disimpan di tabel preferences milik perangkat, tetap berlaku setelah aplikasi dibuka ulang, dan tidak diubah oleh restore. Nilai asli tidak diubah. Form input/edit tetap menampilkan nominal agar pengguna dapat mengoreksinya.

Tidak ada perubahan skema SQLite (tetap 2), format backup JSON (tetap 2), atau format enkripsi. Preferensi penyamaran tidak dibawa ke HP lain melalui backup. Database yang benar-benar baru memakai nominal terlihat dan tema gelap. Reset penuh melalui pengaturan Android menghapus preferensi lokal; file ekspor di Downloads tetap ada.

## Pemeriksaan otomatis

- [x] Analyzer bersih setelah seluruh perubahan: `No issues found`.
- [x] 55 kasus unit/widget terverifikasi: 48 kasus lama lulus pada suite, tujuh kasus baru lulus setelah dua masalah scroll/animasi pada test harness diperbaiki. Lima kasus repository dijalankan ulang setelah menambahkan pemeriksaan persistensi preferensi pada file SQLite. Verifikasi akhir dilakukan melalui suite awal dan rerun terarah, bukan klaim satu eksekusi suite akhir tanpa kegagalan.
- [x] APK debug 0.2.2+4 berhasil dibangun; paket `id.arta.arta`, minimum Android API 24, target API 36. Tanda tangan valid dan sertifikat sama dengan 0.2.1. Build selesai dalam sekitar 219 detik.

APK: [arta-0.2.2-debug.apk](../build/app/outputs/flutter-apk/arta-0.2.2-debug.apk). Identitas dan checksum: [BUILD-0.2.2.json](BUILD-0.2.2.json). Screenshot widget ringkasan tema gelap dan terang telah ditinjau; pengecekan ini tidak menggantikan uji HP fisik.

## Checklist manual APK 0.2.2

Status seluruh checklist di bawah: **BELUM DIUJI di HP untuk versi 0.2.2**. Pengujian fisik versi 0.2.1 bukan hasil uji versi ini. Salin backup sebelum pembaruan; pasang sebagai update, jangan uninstall aplikasi.

- [ ] **M01 — Transfer tanpa biaya:** buat dua akun uji, catat saldo awal, pilih transfer. Pastikan toggle awal mati dan field biaya tidak muncul. Simpan; akun asal berkurang sebesar transfer, tujuan bertambah sama besar, total seluruh saldo tetap.
- [ ] **M02 — Transfer berbiaya:** aktifkan toggle, isi biaya Rp2,50, simpan. Pastikan biaya mengurangi akun asal dan masuk pengeluaran tepat satu kali. Edit transaksi: toggle harus aktif dengan biaya lama.
- [ ] **M03 — Matikan biaya:** edit transfer berbiaya, matikan toggle, simpan. Pastikan biaya menjadi nol, tidak ada transaksi tambahan, dan selisih saldo sebelumnya dipulihkan.
- [ ] **M04 — Jadwal transfer:** buat jadwal konfirmasi berbiaya. Buka kejadian jatuh tempo, matikan toggle biaya aktual, lalu catat. Pastikan kejadian itu tanpa biaya dan aturan berikutnya tetap memakai biaya semula.
- [ ] **M05 — Sandi backup:** buka Backup terenkripsi. Periksa tombol mata pada kedua field dapat bekerja sendiri-sendiri tanpa menghapus isi. Batalkan, buka ulang: field kosong dan tersembunyi. Uji juga pembukaan backup terenkripsi.
- [ ] **M06 — Sembunyikan nominal:** gunakan akun dengan saldo positif dan negatif serta transaksi berbiaya. Klik mata. Ringkasan, akun, transaksi, biaya, dan jadwal memakai titik; grafik tidak terlihat. Periksa juga detail dan riwayat jadwal, tema terang/gelap, font besar, serta pembaca layar jika tersedia.
- [ ] **M07 — Persistensi:** saat nominal tersembunyi, tutup dan buka aplikasi kembali. Nominal harus tetap tersembunyi. Restore backup pada kondisi tersebut tidak membuka nominal; klik mata lagi untuk menampilkan angka asli.
- [ ] **M08 — Instalasi baru/clear data:** hanya pada perangkat atau instalasi uji yang sudah dicadangkan, gunakan Hapus data Android. Pastikan aplikasi kosong, tema gelap, nominal terlihat, dan tidak meminta login. File backup di Downloads tetap ada. Jangan lakukan langkah ini pada data utama tanpa backup.

Untuk laporan, tambahkan setelah setiap item: `Hasil: LULUS/GAGAL; langkah yang gagal; hasil aktual; pesan error; model HP/Android`. Jangan menandai lulus jika belum dijalankan.

## Keputusan dan pekerjaan berikutnya

Permintaan berikut sudah dicatat tetapi **belum diimplementasikan dalam batch 0.2.2**:

- [ ] **Kunci aplikasi opsional:** sidik jari melalui autentikasi sistem HP sebagai pilihan utama jika tersedia. Keputusan terbaru pengguna: PIN terpisah milik aplikasi diperbolehkan, dengan keypad angka kustom dan tanpa keyboard teks. Pengaturan kunci tidak aktif pada instalasi baru. Implementasi perlu derivasi/hash PIN, penyimpanan aman, pembatasan percobaan, penguncian saat kembali dari background, serta penanganan lupa PIN yang tidak membuka data tanpa verifikasi. PIN dan pengaturan keamanan perangkat tidak masuk backup JSON.
- [ ] **Tanggal/jam:** kalender untuk tanggal dan jam analog berformat 24 jam tanpa AM/PM. Simpan jam/menit transaksi, tentukan semantik jam kejadian berulang, dan jaga kompatibilitas data lama/backup. Jangan mengarang jam transaksi lama.
- [ ] **Lampiran gambar:** panel pilihan dari bawah dan Android Photo Picker; hanya akses gambar yang dipilih, tanpa izin luas galeri/penyimpanan. Salin lampiran ke penyimpanan privat dan sertakan dalam rancangan backup.
- [ ] **Ilustrasi kosong:** vektor kucing bertema struk, dompet, kalender, dan pencarian; ikuti tema gelap/terang serta identitas Arta.
- [ ] **Kartu debit Jago Syariah:** menu kartu ditautkan ke rekening/kantong sumber. Kartu tidak menambah saldo atau total aset. Transaksi tetap menggunakan rekening sumber historis meskipun tautan kartu diubah kemudian. Bukan kartu kredit dan bukan akun saldo baru.

Aplikasi tetap offline tanpa backend dan tanpa login Google. Batch selanjutnya tidak otomatis dimulai berdasarkan waktu reset limit.
