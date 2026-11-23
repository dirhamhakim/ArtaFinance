# Identitas aplikasi dan loading

Status: desain v3 dibuat melalui MCP FigCraft pada 18 November 2026. Logo vektor, aset ikon launcher dan prototype loading sudah dibuat; animasi Flutter belum diimplementasikan. Arta masih nama kerja pada desain UI.

Pengguna menginginkan identitas sendiri serta loading berdasarkan logo. Hasil revisi memakai monogram A dari tiga bagian vector path (`Rise`, `Balance`, `Bridge`) dan wordmark Lato Bold. Master, varian terang/gelap/monokrom, ukuran kecil dan preview launcher tersedia pada halaman **07 · Identitas & Loading**. Arta dapat diganti bila pengguna memilih nama lain.

## Alat dan hasil yang dituju

- Editor vektor untuk master logo: gunakan FigCraft yang sudah tersedia melalui MCP. Tool ekspornya mendukung SVG, PNG dan XML Android Vector Drawable, dengan peringatan kompatibilitas yang harus diperiksa. VectorCraft/DesignCraft/PhotoCraft belum tersedia sebagai MCP pada sesi pemeriksaan ini; pencarian plugin dengan ketiga nama tersebut juga tidak menemukan hasil. Ini tidak menyatakan aplikasi tersebut tidak ada atau tidak dapat disambungkan nanti.
- Jika VectorCraft nantinya terhubung, periksa kemampuan layer/path dan ekspor vektornya sebelum memilihnya sebagai editor master. Aplikasi raster dapat membantu eksplorasi visual bila diperlukan; master logo sederhana sebaiknya tetap dapat diedit sebagai vektor.
- Master SVG dan file native editable, varian warna/monokrom untuk terang/gelap, PNG transparan, serta layer foreground/background launcher icon sudah tersedia pada direktori branding. Ikon memakai simbol ringkas dengan area aman/masking Android yang tetap perlu diuji ketika diintegrasikan ke aplikasi.
- Untuk loading sederhana, gunakan animasi Flutter bawaan dengan `AnimationController` dan transisi/drawing yang diperlukan. Rekomendasi awal ini menghindari kebutuhan layanan animasi daring atau editor berbayar; format animasi lain baru dipilih jika gerakan final membutuhkannya. Animasi/logo dibundel di aplikasi dan bekerja offline.

## Perilaku loading

Pisahkan splash saat peluncuran yang dikelola Android dari loading di dalam Flutter. Android 12+ mempunyai splash sistem dengan ikon/latar yang dapat disesuaikan; SVG master perlu diadaptasi ke resource Android yang sesuai. Jangan menjanjikan layout splash layar penuh yang sepenuhnya bebas dari aturan platform.

Rancang transisi splash ke aplikasi dengan identitas yang sama, tanpa sengaja menambahkan dua layar tunggu atau durasi minimum yang memperlambat akses. Loading Flutter dapat memakai bagian simbol yang muncul bertahap, perubahan skala/opacity yang halus atau gerakan sederhana lain setelah bentuk logo dipilih. Jangan memutuskan animasi sebelum bentuk logonya ada.

- Logo/light/dark kontras dengan latar; loader ringkas dan versi splash memakai bentuk yang konsisten.
- Animasi hanya berjalan selama pekerjaan berlangsung, berhenti ketika selesai/layar ditutup, dan menyediakan versi statis saat pengguna mengurangi animasi.
- Jangan menampilkan persentase kemajuan jika kemajuan pekerjaan tidak terukur. Tampilkan status yang sesuai, seperti membuka data atau mengimpor katalog.
- Jangan menahan layar utama untuk menunggu harga/logo daring. Data lokal dibuka terlebih dahulu; harga/cache dimuat sesuai kebutuhan halaman.
- Kegagalan pekerjaan mengakhiri loading dan menampilkan hasil/error yang dapat ditindaklanjuti. Animasi bukan indikator keberhasilan operasi.

## Referensi teknis

- [Flutter: Animations tutorial](https://docs.flutter.dev/ui/animations/tutorial) — animasi bawaan, controller dan transisi.
- [Android: Splash screens](https://developer.android.com/develop/ui/views/launch/splash-screen) — splash sistem, varian tema, resource ikon/latar dan masking.

Master logo yang sama digunakan pada header Beranda/Lainnya, Tentang, splash dan loading. Tiga fase loading bergantian menekankan satu bagian simbol dengan opacity penuh, sementara dua bagian lain 18%. Seluruh tujuh state pembukaan mempunyai pasangan terang. Prototype memakai timer/smart animate untuk review; runtime harus mengikuti kesiapan data dan pilihan gerakan dikurangi.

Hasil dan file: [aset branding](../../design/branding/README.md), [spesifikasi motion](../../design/branding/loading-motion-spec.json), serta [panduan review](../../design/README.md). Ekspor Android Vector Drawable tanpa peringatan belum membuktikan hasil telah dikompilasi/berjalan di Android. Arta masih nama kerja; aset dapat direvisi sebelum implementasi.
