# Arta — aturan visual 0.6.0

Implementasi langsung di Flutter, mengacu pada temuan HTML publik/elemen yang diberikan pengguna dari Bibit dan Stockbit. Tidak memindahkan HTML login atau data akun ke repository.

| Bagian | Keputusan |
| --- | --- |
| Ikon | Feather, garis konsisten; Material hanya untuk sidik jari sistem |
| Font | Lato regular dan bold 700, tersedia offline, lisensi OFL |
| Warna utama terang | `#00875A` |
| Warna aksen gelap | `#32C99A` |
| Latar terang / gelap | `#F5F8F9` / `#0E1215` |
| Permukaan terang / gelap | `#FFFFFF` / `#15191C` |
| Teks utama terang / gelap | `#20292E` / `#F0F3F5` |
| Teks sekunder terang / gelap | `#67757D` / `#A1ADB3` |
| Garis terang / gelap | `#E6ECEF` / `#2C353B` |
| Garis IHSG | Biru `#669DFF`; portofolio memakai aksen hijau tema |
| Heading / angka utama | 19–20 / 30 logical px; bold, mengikuti skala font sistem |
| Teks isi / pendukung | 14 / 12 logical px |
| Radius | Kartu 18; hero 22; field/tombol 12; chip periode 9 |
| Jarak | Halaman 16; hero 22; antarbagian 16–24 |
| Target sentuh | Tombol minimal 48 logical px; ukuran ikon tidak menentukan target sentuh |
| Keadaan kosong | Ilustrasi dokumen/dompet/kartu/kalender/pencarian/lampiran; tanpa kucing |

Kartu hero memakai aksen transparan yang lembut. Badge ikon memberi penanda kategori tanpa warna berlebihan. Form memakai latar netral dan garis fokus hijau. Pilihan periode berbentuk chip dengan status aktif yang jelas. Navigasi bawah tetap Ringkasan, Akun, Transaksi, Pengaturan agar kebiasaan pengguna terjaga.

Data tidak lengkap, nol, negatif, loading, offline dan nominal tersembunyi adalah keadaan yang berbeda. Warna bukan satu-satunya penanda: label, angka, nama garis dan pesan tetap menjelaskan kondisi. Ilustrasi dekoratif dikeluarkan dari pembacaan screen reader. Logo Arta dan loading khusus dipertahankan; tidak mengunduh ikon brand sebagai pengganti ikon navigasi aplikasi.

Preview hasil widget tersedia di `build/ui-review/*-0.6.0.png`. Angka portofolio pada preview adalah fixture pengujian, bukan data pengguna. Uji font 200%, portrait dan landscape dilakukan melalui widget tests; APK 0.6.0 sudah dibuild; uji fisik Samsung menunggu pengguna memasang dan mengujinya.
