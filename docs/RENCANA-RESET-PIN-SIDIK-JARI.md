# Reset PIN Arta menggunakan sidik jari

Status: diminta pengguna 20 November 2026, **belum diimplementasikan**. Sesi saat ini dibatasi pada pencatatan kebutuhan dan riset UI/UX APK; kode aplikasi serta APK Arta tidak diubah.

## Perilaku yang diminta

Tautan **Lupa PIN?** pada layar kunci memberi pilihan **Reset PIN dengan sidik jari**. Setelah autentikasi biometrik Android berhasil, pengguna membuat PIN Arta enam angka baru dan mengulanginya pada keypad angka khusus. Tidak perlu memasukkan PIN lama dan tidak ada akun/login online. Reset PIN tidak menghapus data finansial.

Kondisi yang harus ditetapkan: sidik jari Android tersedia dan sudah diaktifkan untuk keamanan Arta sebelumnya. Jika sebelumnya hanya memakai PIN tanpa biometrik Arta, keberadaan sensor saja tidak boleh otomatis menjadi jalur perubahan PIN tanpa otorisasi. Penambahan/perubahan sidik jari perangkat dan validitas kunci keamanan perlu diperiksa saat implementasi native.

## Alur yang direncanakan

1. Layar terkunci → Lupa PIN? → penjelasan singkat → Reset dengan sidik jari.
2. Panggil autentikasi biometrik Android untuk perubahan PIN, terikat ke sesi perubahan tersebut. Tampilan dialog sistem tetap milik Android.
3. Autentikasi sukses → buat PIN baru → konfirmasi PIN baru. Keypad khusus, titik penyamaran dan tombol mata mengikuti pola Arta.
4. Simpan kredensial baru secara atomik; setelah berhasil, PIN lama tidak berlaku dan hitungan gagal PIN disetel ulang. Keadaan pilihan biometrik tetap dipertahankan.
5. Batalkan/gagal sensor, masuk latar belakang, sesi kedaluwarsa atau gagal penyimpanan → tidak mengubah PIN/data. Konfirmasi berbeda memberi kesempatan mengulang tanpa mengganti PIN lama.

Kegagalan PIN berulang tidak boleh menyediakan jalan pintas tanpa autentikasi; biometrik yang sah perlu tetap dapat dipakai sesuai aturan native. Tidak memakai PIN layar kunci Android sebagai pengganti PIN Arta dan tidak menampilkan form reset sebelum otorisasi berhasil. Tidak membuat jalur reset online atau menghapus data otomatis ketika biometrik gagal.

Kode saat ini sudah mempunyai alur perubahan PIN melalui Pengaturan setelah `authorizeChange()`, yang dapat dipenuhi biometrik. Fitur baru memerlukan jalur Lupa PIN yang jelas dan verifikasi otorisasi native; bukan sekadar menampilkan form PIN dari tombol baru. Pemeriksaan kode tersebut dilakukan read-only pada sesi ini.

## Pemeriksaan implementasi berikutnya

- [ ] Sensor asli: PIN terlupa → sidik jari benar → PIN baru; PIN lama gagal dan data tetap sama.
- [ ] Batal sensor, jari salah, sensor tidak tersedia/belum diaktifkan, dan lockout biometrik tidak membuka form reset.
- [ ] Konfirmasi PIN berbeda, tombol hapus/mata, serta keyboard khusus bekerja.
- [ ] Background/resume dan tutup aplikasi selama reset membatalkan otorisasi yang tidak lagi sah.
- [ ] Gagal penyimpanan tidak meninggalkan kredensial setengah berubah.
- [ ] Penundaan setelah PIN salah tidak memberi bypass; perubahan PIN sah mereset hitungan kegagalan.
- [ ] Perubahan pendaftaran sidik jari perangkat mengikuti kebijakan kunci native yang ditetapkan.
- [ ] Backup finansial tidak memuat PIN, rahasia biometrik atau token otorisasi reset.
- [ ] Hapus data Arta tetap mengembalikan keadaan baru tanpa kunci lama; tidak pernah mereset data otomatis dari alur Lupa PIN.
