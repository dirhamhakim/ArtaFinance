# Arta — aset identitas

Dibuat melalui MCP FigCraft pada revisi desain v3. Arta tetap nama kerja. Monogram A terdiri dari tiga vector path yang bisa diedit: `Rise`, `Balance`, `Bridge`. Wordmark menggunakan Lato Bold dengan tracking yang disesuaikan.

## Berkas

- `arta-symbol-dark.svg`, `arta-symbol-light.svg`: simbol untuk latar gelap/terang.
- `arta-symbol-white.svg`, `arta-symbol-black.svg`: monokrom.
- `arta-lockup-dark.svg`, `arta-lockup-light.svg`: simbol dan wordmark; teks diekspor sebagai outline.
- `arta-symbol-dark.png`: PNG transparan untuk keperluan raster.
- `arta-launcher-preview.png`: preview ikon persegi 1024 px. Masking akhir mengikuti launcher Android.
- `arta-adaptive-foreground.png`, `arta-adaptive-background.png`: layer terpisah 432 px dari master 108 unit. Foreground transparan dan bagian logo berada di area tengah.
- `arta-symbol-dark.xml`: hasil ekspor Android Vector Drawable; tidak ada peringatan ekspor, belum dikompilasi/diuji dalam APK.
- `loading-motion-spec.json`: urutan penekanan opacity tiga bagian logo, gerakan dikurangi, dan ID flow prototype. Ini spesifikasi gerak untuk implementasi Flutter, bukan file animasi Lottie/Rive atau kode aplikasi.

Master editable ada pada halaman **07 · Identitas & Loading** di [file native](../Arta-Keuangan-Pribadi.figcraft). Splash, tiga fase loading, versi statis, kegagalan pembukaan dan halaman Tentang tersedia dalam Dark/Light. Logo juga ditambahkan pada header Beranda dan Lainnya.

Motion runtime direncanakan berulang selama pekerjaan nyata berlangsung, lalu berhenti saat selesai. Timer prototype hanya untuk demonstrasi transisi; tidak menetapkan waktu tunggu wajib aplikasi. Harga/logo daring tidak menahan pembukaan data lokal. Gunakan bentuk statis ketika gerakan dikurangi.
