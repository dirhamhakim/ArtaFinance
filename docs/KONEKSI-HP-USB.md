# Menguji Arta melalui kabel USB — Samsung A05s, Android 15

Pengujian Android selanjutnya memakai HP langsung. Emulator sudah dimatikan atas permintaan pengguna. Android SDK dan ADB sudah tersedia pada laptop ini; tidak perlu membuka Android Studio.

## 1. Aktifkan Pilihan pengembang

1. Buka **Pengaturan > Tentang ponsel > Informasi perangkat lunak**.
2. Ketuk **Nomor versi / Build number** tujuh kali.
3. Masukkan PIN/pola HP jika diminta. Setelah pesan mode pengembang aktif, kembali ke halaman utama Pengaturan.
4. Buka **Pilihan pengembang / Developer options**, biasanya di bagian bawah daftar.
5. Aktifkan **Debugging USB / USB debugging** dan setujui dialog pada HP.

Nama menu dapat sedikit berbeda sesuai bahasa dan versi One UI. Langkah pengaktifan ini dijelaskan oleh [Samsung](https://www.samsung.com/uk/support/mobile-devices/how-do-i-turn-on-the-developer-options-menu-on-my-samsung-galaxy-device/).

Jika Debugging USB berwarna abu-abu atau diblokir **Pemblokir otomatis / Auto Blocker**, buka **Pengaturan > Keamanan dan privasi > Pemblokir otomatis**, lalu nonaktifkan sementara untuk sesi pengembangan. Samsung menjelaskan bahwa Auto Blocker dapat memblokir perintah melalui USB. Setelah sesi selesai, aktifkan lagi jika sebelumnya aktif. [Penjelasan Samsung](https://www.samsung.com/us/support/answer/ANS10003636/).

## 2. Sambungkan kabel dan izinkan komputer

1. Gunakan kabel USB yang mendukung **transfer data**; sebagian kabel hanya dapat mengisi daya.
2. Sambungkan langsung ke port laptop dan buka kunci layar HP.
3. Jika tersedia, buka notifikasi USB dan pilih **Transfer file / Android Auto**. Mode ini membantu memastikan sambungan data; izin debugging tetap diberikan melalui dialog terpisah.
4. Pada dialog **Izinkan debugging USB?**, pilih **Izinkan**. Untuk laptop pribadi ini, boleh centang **Selalu izinkan dari komputer ini**.
5. Biarkan HP tetap tersambung. Tidak perlu mengaktifkan tethering atau membagikan internet HP.

Android memakai persetujuan debugging untuk komunikasi ADB melalui USB. [Panduan Android](https://developer.android.com/studio/run/device).

## 3. Periksa dari PowerShell

Buka PowerShell pada laptop. Perintah ini bisa dijalankan dari folder mana pun:

```powershell
& 'C:\Users\User\AppData\Local\Android\Sdk\platform-tools\adb.exe' devices -l
```

Contoh hasil yang sudah siap:

```text
List of devices attached
SERIAL_HP    device product:... model:... device:...
```

Yang harus diperhatikan adalah status **`device`**. Nilai serial dan model akan mengikuti HP sebenarnya.

| Hasil | Langkah berikutnya |
| --- | --- |
| `device` | Sambungan sudah siap. Buka Arta dan kabari Codex bahwa HP sudah terhubung. |
| `unauthorized` | Buka kunci layar, setujui dialog debugging, lalu jalankan perintah lagi. |
| `offline` | Cabut/pasang kabel, tunggu perangkat siap, lalu periksa lagi. |
| Tidak ada perangkat | Periksa kabel data, port USB, Debugging USB, Auto Blocker, dan driver Samsung. |

Jika `unauthorized` tetap muncul tanpa dialog, buka **Pilihan pengembang > Cabut otorisasi debugging USB / Revoke USB debugging authorizations**, lalu sambungkan ulang dan setujui kembali laptop ini.

Jika Windows belum mengenali sambungan ADB Samsung, gunakan [Samsung Android USB Driver resmi](https://developer.samsung.com/android-usb-driver), lalu sambungkan ulang. Driver diperlukan pada Windows jika perangkat belum terdeteksi; tidak perlu memasangnya ulang jika status sudah `device`.

## 4. Ambil log kegagalan startup

Setelah status `device`, buka Arta. Jika pesan **Penyimpanan lokal belum dapat dibuka** muncul kembali, tekan **Coba lagi** sekali dan kabari Codex, misalnya:

> HP sudah terhubung, status device, dan error Arta sudah muncul.

Codex dapat memeriksa log aplikasi Arta, versi Android, dan tahap startup yang gagal melalui ADB. Tidak perlu menghapus data aplikasi, uninstall, atau mereset HP untuk mengumpulkan log.

Database privat aplikasi tidak memerlukan izin penyimpanan umum Android. Karena itu, jangan menganggap error startup ini pasti diselesaikan dengan mengaktifkan izin Files/Storage. Penyebab spesifik pada Samsung A05s perlu dikonfirmasi dari log HP. [Penyimpanan privat Android](https://developer.android.com/training/data-storage/app-specific).

Jika APK diagnostik 0.2.1 dipasang dan masih gagal, halaman error juga menyediakan **Rincian error > Salin rincian**. Teks itu dapat dicatat pada [laporan testing](TESTING-APK-0.2.0.md).

## 5. Menjalankan kode Flutter langsung ke HP (opsional)

Langkah ini tidak diperlukan hanya untuk membaca log APK yang sudah terpasang. Setelah ingin menjalankan kode proyek:

```powershell
Set-Location -LiteralPath 'D:\Aplikasi Keuangan'
.\scripts\flutter.ps1 -Task Run
```

Pilih HP fisik jika Flutter menampilkan pilihan perangkat. Helper memakai SDK lokal; tidak perlu memulai emulator. Menjalankan kode melakukan build dan pemasangan aplikasi pengujian, sehingga lebih berat daripada sekadar membaca log ADB.

## 6. Setelah selesai

Cabut kabel bila sesi sudah selesai. Matikan Debugging USB jika tidak sedang dipakai, dan kembalikan Auto Blocker ke keadaan sebelumnya jika tadi diubah. Biarkan data Arta tetap ada untuk pengujian penyimpanan/restore berikutnya.

## Catatan sesi

- Model HP: Samsung A05s.
- Versi Android: 15, menurut informasi pengguna.
- Status sambungan USB: berhasil terhubung dengan status `device` pada 19 November 2026; model terdeteksi SM-A057F, Android 15.
- Error yang dilaporkan: `Penyimpanan lokal belum dapat dibuka`; tombol Coba lagi menghasilkan pesan yang sama.
- Penyebab pada HP: belum dikonfirmasi dari log perangkat fisik.
- Hasil pengujian setelah patch: pembaruan 0.2.1+3 berhasil masuk Ringkasan dan berhasil setelah ditutup paksa lalu dibuka ulang. Uji startup melalui USB selesai; hasil sesi lanjutan tercantum di bawah.
- Sesi lanjutan: 8 kelompok integration test HP dan alur backup/restore Android lulus; lihat [laporan lengkap](TESTING-HP-2026-11-19.md). Wi-Fi aktif dan mode pesawat mati sudah dikembalikan setelah tes. APK normal tetap terpasang; paket QA sementara sudah dihapus.
