# Checklist pengujian HP — Arta 0.7.2

## Pengelolaan kategori 0.7.2

[Panduan kategori](PATCH-0.7.2.md). Kasus berikut **belum diuji pada HP**; hasil otomatis dicatat terpisah di laporan build. HP tidak diakses karena sedang digunakan pemiliknya. PIN/sidik jari tidak perlu diuji ulang.

Validasi laptop 0.7.2: **201/201 tes unit/widget lulus; analyzer bersih**. Hasil ini tidak mencentang kasus manual HP di bawah.

- [ ] **T143 — Menu dan kategori tanpa transaksi.** Buka Pengaturan → Pencatatan → Kategori. Pilih Pengeluaran, tambahkan `Servis kendaraan`. Kembali ke form transaksi dan cari nama tersebut. Diharapkan: tersedia walau belum ada transaksi, tetap tersedia setelah aplikasi dibuka ulang.
- [ ] **T144 — Pemisahan jenis dan validasi.** Buat kategori bernama sama pada Pemasukan. Coba buat nama sama lagi dalam jenis yang sama, termasuk beda huruf besar/kecil dan spasi di tepi. Diharapkan: kedua jenis terpisah; duplikasi dalam jenis sama ditolak. Nama kosong ditolak.
- [ ] **T145 — Pengubahan nama dan riwayat.** Buat transaksi dan jadwal menggunakan kategori itu. Ubah nama kategori dari Pengaturan. Diharapkan: label transaksi/jadwal serta pilihan form mengikuti nama baru, saldo/nominal/tanggal/lampiran tetap, kejadian jadwal tidak tercatat ganda.
- [ ] **T146 — Arsip dan pemulihan.** Arsipkan kategori bawaan atau kategori sendiri. Diharapkan: hilang dari pilihan baru, tersedia di filter Arsip, riwayat tetap ada dan jadwal lama tetap berjalan. Aktifkan kembali, pastikan muncul lagi. Nama yang masih diarsipkan tidak dapat dibuat ulang dalam jenis sama.
- [ ] **T147 — Kategori kustom dan penghapusan transaksi.** Ketik kategori baru langsung di form transaksi, simpan, lalu hapus transaksinya. Diharapkan: kategori tetap tersedia di Pengaturan serta pilihan form.
- [ ] **T148 — Backup lengkap dan versi lama.** Buat kategori yang belum dipakai serta kategori arsip. Backup JSON dan terenkripsi, lalu pulihkan dan cocokkan keduanya. Diharapkan: nama/jenis/status sama. Backup lama v1–v5 tetap dapat dipulihkan dengan kategori bawaan dan kategori historisnya.
- [ ] **T149 — Tampilan kategori.** Periksa tema gelap/terang, pencarian, panel tambah/ubah, keyboard, orientasi landscape dan font besar. Diharapkan: bisa digulir, tidak ada overflow atau tombol terpotong.

Hasil aktual HP 0.7.2: …

## Riwayat pengujian 0.7.1

Sesi 21 November 2026 selesai: **188 unit/widget lulus, 13 skenario native Android lulus, analyzer bersih**. APK 0.7.1+10 sudah terpasang pada Samsung A05s Android 15. PIN/sidik jari tidak diuji ulang sesuai instruksi pengguna; hasilnya USER_REPORTED_PASS.

[Laporan lengkap dan batas pengujian](TESTING-HP-2026-11-21.md) · [Hasil JSON](TESTING-HP-2026-11-21.json) · [APK final](../build/app/outputs/flutter-apk/arta-0.7.1-debug.apk) · [SHA-256/build](BUILD-0.7.1.json)

## Pemeriksaan 0.7.1

- [x] **T135 — Pilihan kategori**. Langkah: pilih default, cari, buat khusus, ganti pemasukan/pengeluaran/transfer, simpan dan buka kembali. Hasil: LULUS; daftar terpisah, draft kembali, kategori tersimpan. Bukti: category_flow_test, Android P09, M04.
- [x] **T136 — Header dan privasi card**. Langkah: periksa header semua halaman, hide melalui card, pindah tab dan tampilkan kembali. Hasil: LULUS; header tanpa mata/loading, privasi tersimpan. Bukti: suite layar, M19.
- [x] **T137 — Restore besar dan struk**. Langkah: pulihkan demo lengkap, ekspor, bandingkan semua tabel/foto dan ulang dengan enkripsi. Hasil: LULUS; native restore sekitar 4,3 detik, isi round-trip sama. Bukti: Android P10, M02–M07.
- [x] **T138 — Pengaturan setelah digulir**. Langkah: gulir, pindah Ringkasan, kembali Pengaturan, perluas CSV dan ekspor ketiga tabel. Hasil: LULUS; tidak ada error double/bool. Bukti: tes regresi, M08/M09.
- [x] **T139 — Isolasi gangguan harga**. Langkah: simulasi saham 404 dan provider 429, periksa saham lain/crypto serta cache. Hasil: LULUS; sumber lain tetap diproses dan request dibatasi. Bukti: 35 tes sumber harga, termasuk dua kasus baru.
- [x] **T140 — File dan pencarian asli Android**. Langkah: impor Excel IDX, tambah saham simulasi JSON, impor NAB CSV, cari BBCA di Yahoo dan Chainlink di CoinGecko. Hasil: LULUS; metadata lengkap, tidak ada duplikasi/kehilangan holdings. Bukti: M10–M14.
- [x] **T141 — Harga online dan key**. Langkah: simpan key di form, refresh manual, ambil penutupan, buka ulang. Hasil: LULUS; 15 quote live, penutupan seluruh 10 crypto default dan IHSG sampai 20 Nov, live tidak mengubah valuasi close. Bukti: M15–M17/M20.
- [x] **T142 — Akhir pengujian**. Langkah: cadangkan hasil, pulihkan data awal, periksa SQLite/key, buang paket QA dan kembalikan setting HP. Hasil: LULUS; data awal kembali, keamanan tetap, key terpasang, mode pesawat mati. Bukti: M18–M21.

Catatan batas: Google Sheets live memerlukan URL; reset destruktif paket utama dan perangkat Android lain tidak dijalankan. Rincian metode/hasil setiap fitur ada pada laporan sesi. Kasus T01–T134 berikut menyimpan riwayat versi sebelumnya.

## Riwayat checklist 0.7.0

**Arsip sesi 0.7.0+9:** penerapan desain FigCraft ke Flutter. Kasus T109–T134 di bawah belum diuji pada HP. Hasil USB 0.6.0 di bagian riwayat tidak dihitung sebagai hasil HP versi baru.

APK: [arta-0.7.0-debug.apk](../build/app/outputs/flutter-apk/arta-0.7.0-debug.apk) · [Panduan perubahan dan cara pakai](TAHAP-7-0.7.0.md) · [Identitas/verifikasi build](BUILD-0.7.0.json).

Gunakan file Markdown ini untuk mencatat hasil, lalu simpan dan kirim **review hasil testing**. Isi Status dengan LULUS/GAGAL/SEBAGIAN/TERHALANG; centang setelah kasus selesai diperiksa. Jangan menulis PIN, API key, sandi atau data pribadi asli.

| Identitas sesi 0.7.0 | Isian pengguna |
| --- | --- |
| Tanggal/jam | … |
| HP / Android | Samsung A05s / Android 15, atau … |
| Versi terpasang | 0.7.0+9 / … |
| Pemasangan dan data awal | Pembaruan / baru; backup sudah disimpan: … |
| Navigasi / ukuran font | Tiga tombol / gestur; normal / … |

Ulangi regresi T01–T108 yang relevan. Bagian tersebut menyimpan hasil 0.6.0 sebagai riwayat; tulis hasil ulang dengan awalan **0.7.0:** pada Hasil aktual, tanpa menghapus catatan lama. Tidak perlu emulator atau login Google. Jangan matikan hotspot/data bila laptop bergantung pada koneksi HP.

## Pemeriksaan tambahan 0.7.0

- [ ] **T109 — Pembaruan APK dan data lama**
  - Langkah: Cadangkan data, lalu pasang APK 0.7.0 sebagai pembaruan tanpa uninstall. Buka aplikasi dan periksa aset, transaksi, jadwal serta investasi lama.
  - Diharapkan: Tidak ada data hilang atau saldo berubah hanya karena pembaruan UI.
  - Status: BELUM
  - Hasil aktual 0.7.0: …

- [ ] **T110 — Lima tab ikon**
  - Langkah: Buka kelima ikon bawah: Ringkasan, Investasi, Aset, Transaksi, Pengaturan. Pindah tab setelah menggulir.
  - Diharapkan: Ikon aktif hijau, tidak ada teks/pill, tiap halaman memiliki posisi gulir sendiri; sentuhan nyaman.
  - Status: BELUM
  - Hasil aktual 0.7.0: …

- [ ] **T111 — Tema dan font offline**
  - Langkah: Ubah Gelap/Terang/Ikuti perangkat pada Pengaturan. Tutup-buka aplikasi tanpa internet.
  - Diharapkan: Pilihan tersimpan, teks Bit Sans tetap tampil; tidak perlu menginstal font atau mengunduhnya.
  - Status: BELUM
  - Hasil aktual 0.7.0: …

- [ ] **T112 — Layar kecil, landscape dan teks besar**
  - Langkah: Uji font normal, 130% dan 200%, portrait dan landscape. Gulir Ringkasan, Aset, Investasi, form, panel pilihan dan Pengaturan.
  - Diharapkan: Tidak ada garis overflow, angka hilang, tombol terpotong atau konten yang tidak dapat digulir.
  - Status: BELUM
  - Hasil aktual 0.7.0: …

- [ ] **T113 — Saldo besar dan angka utuh**
  - Langkah: Gunakan aset uji nominal besar. Periksa Aset/Liabilitas sebaris dan Total di bawah. Ketuk nominal pada card.
  - Diharapkan: Angka disingkat hanya jika perlu; rincian menampilkan nilai utuh. Total berasal dari angka asli, bukan penjumlahan pembulatan.
  - Status: BELUM
  - Hasil aktual 0.7.0: …

- [ ] **T114 — Privasi nominal**
  - Langkah: Tekan mata pada Ringkasan. Buka Aset, Transaksi, Investasi dan grafik. Tutup-buka aplikasi, lalu tampilkan kembali.
  - Diharapkan: Titik menggantikan nominal; grafik sensitif tersembunyi; preferensi bertahan dan saldo tidak berubah.
  - Status: BELUM
  - Hasil aktual 0.7.0: …

- [ ] **T115 — Logo bank, DOKU dan Lainnya**
  - Langkah: Tambah aset bank/e-wallet, buka pemilih, cari DOKU dan Jago, lalu pilih Lainnya dan isi nama sendiri. Buka ulang aplikasi.
  - Diharapkan: Logo tepat, Jago Syariah memakai Jago, pilihan tersimpan, Lainnya memiliki ikon tetap.
  - Status: BELUM
  - Hasil aktual 0.7.0: …

- [ ] **T116 — Kantong debit terpisah**
  - Langkah: Buat bank uji Rp100.000 dan Debit Jago saldo 0. Transfer Rp20.000 tanpa biaya.
  - Diharapkan: Bank Rp80.000, Debit Rp20.000, Total tetap Rp100.000. Saldo minus tetap diperbolehkan.
  - Status: BELUM
  - Hasil aktual 0.7.0: …

- [ ] **T117 — Panel bawah dan radio**
  - Langkah: Buka pemilih aset, kelas, frekuensi, tema dan konfirmasi. Pilih, batalkan, lalu buka lagi.
  - Diharapkan: Panel muncul dari bawah, pilihan aktif jelas, Batal tidak mengubah data, panel bisa digulir dan tidak tertutup keyboard.
  - Status: BELUM
  - Hasil aktual 0.7.0: …

- [ ] **T118 — Simpan dan navigasi tiga tombol**
  - Langkah: Aktifkan navigasi tiga tombol Samsung. Isi form transaksi dengan keyboard terbuka lalu tutup keyboard.
  - Diharapkan: Simpan tetap dapat diketuk dan berada di atas area navigasi Android; tidak terselip di bawah tombol sistem.
  - Status: BELUM
  - Hasil aktual 0.7.0: …

- [ ] **T119 — Jenis, kalender dan jam 24**
  - Langkah: Ganti tab Pengeluaran/Pemasukan/Transfer. Pilih tanggal melalui kalender dan waktu 23:45 melalui dial jam. Simpan dan edit ulang.
  - Diharapkan: Jenis jelas, jam tanpa AM/PM, tanggal dan menit tersimpan dengan benar.
  - Status: BELUM
  - Hasil aktual 0.7.0: …

- [ ] **T120 — Transfer dua biaya**
  - Langkah: Transfer pokok Rp100.000, biaya pengirim Rp2.500 dan penerima Rp1.000.
  - Diharapkan: Pengirim -Rp102.500, penerima +Rp99.000, pengeluaran biaya Rp3.500; pokok tidak menjadi arus kas.
  - Status: BELUM
  - Hasil aktual 0.7.0: …

- [ ] **T121 — Toggle biaya dan edit**
  - Langkah: Uji hanya pengirim, hanya penerima, keduanya, dan toggle utama mati setelah mengisi draft biaya. Edit transaksi yang sama.
  - Diharapkan: Hanya biaya aktif dihitung sekali; draft tersembunyi tidak dipakai; edit tidak menggandakan transaksi.
  - Status: BELUM
  - Hasil aktual 0.7.0: …

- [ ] **T122 — Biaya penerima lintas mata uang**
  - Langkah: Transfer IDR ke USD: nominal tujuan USD10, biaya penerima USD0,50, kurs tujuan Rp16.000/USD.
  - Diharapkan: Tujuan bertambah USD9,50; beban penerima Rp8.000, ditambah biaya pengirim jika ada. Kurs tujuan wajib sesuai.
  - Status: BELUM
  - Hasil aktual 0.7.0: …

- [ ] **T123 — Dua belas pilihan berulang**
  - Langkah: Buka Frekuensi dan cocokkan semua 12 pilihan dengan panduan 0.7.0. Pilih hari Senin/Rabu/Jumat.
  - Diharapkan: Semua pilihan ada; hanya hari terpilih yang muncul dalam preview/jatuh tempo; hari sama tidak diduplikasi.
  - Status: BELUM
  - Hasil aktual 0.7.0: …

- [ ] **T124 — Kalender, cicilan dan biaya jadwal**
  - Langkah: Uji 4 minggu vs bulanan tanggal 31, akhir bulan, serta tahunan 29 Februari. Coba jadwal transfer dua biaya dan ubah biaya aktual satu kejadian.
  - Diharapkan: 4 minggu tetap 28 hari; jangkar bulanan/tahunan kembali pada tanggal asli; biaya kejadian lain tidak ikut berubah; cicilan menjumlah tepat.
  - Status: BELUM
  - Hasil aktual 0.7.0: …

- [ ] **T125 — Susunan PIN**
  - Langkah: Aktifkan kunci opsional, kunci kembali, isi/enam angka, gunakan mata/hapus, tekan Lanjut.
  - Diharapkan: Grid 4×3; sidik jari kiri bawah, 0 tengah, hapus kanan; tidak membuka keyboard; tidak ada bantuan atau back yang tidak diperlukan.
  - Status: BELUM
  - Hasil aktual 0.7.0: …

- [ ] **T126 — Overlay sidik jari**
  - Langkah: Panggil sidik jari dari keypad, lalu batalkan dan coba kembali.
  - Diharapkan: Sensor/dialog berasal dari Android; loading menimpa halaman dan tidak menggeser posisi field/keypad.
  - Status: BELUM
  - Hasil aktual 0.7.0: …

- [ ] **T127 — Lupa PIN dengan sidik jari**
  - Langkah: Catat PIN uji. Pada Lupa PIN, batalkan verifikasi dan pastikan PIN lama berlaku. Ulangi dengan sidik jari valid, buat serta konfirmasi PIN baru.
  - Diharapkan: Batal/gagal tidak mengganti PIN/data. Berhasil membuka pembuatan PIN baru; PIN baru kemudian dapat membuka aplikasi.
  - Status: BELUM
  - Hasil aktual 0.7.0: …

- [ ] **T128 — Carousel Ringkasan**
  - Langkah: Geser card arus kas kanan/kiri, termasuk saat nominal disembunyikan dan teks diperbesar.
  - Diharapkan: Halaman dan titik indikator merespons, konten terbaca, transfer pokok tidak menjadi pemasukan/pengeluaran.
  - Status: BELUM
  - Hasil aktual 0.7.0: …

- [ ] **T129 — Grafik seluruh lingkup**
  - Langkah: Dengan data uji yang memiliki harga, buka grafik investasi, komposisi portofolio, noninvestasi, gabungan, arus kas dan Saham vs IHSG. Ganti periode/ketuk garis.
  - Diharapkan: Line/donut tersedia, legenda dan warna jelas; IHSG ungu dan saham hijau; data hilang tidak menjadi keuntungan palsu.
  - Status: BELUM
  - Hasil aktual 0.7.0: …

- [ ] **T130 — Restore dan preferensi otomatis**
  - Langkah: Matikan penutupan harian otomatis, sembunyikan nominal, buat backup JSON, lalu pulihkan.
  - Diharapkan: Pilihan otomatis tetap mati dan nominal tetap tersembunyi. Transaksi, debit, penyedia, hari pilihan dan kedua biaya tetap utuh.
  - Status: BELUM
  - Hasil aktual 0.7.0: …

- [ ] **T131 — CSV biaya penerima**
  - Langkah: Ekspor CSV transaksi yang berisi dua biaya dan transaksi investasi/bunga.
  - Diharapkan: receiver_fee dan receiver_fee_idr_rate tersedia; jumlah kolom konsisten; file bukan pengganti backup JSON.
  - Status: BELUM
  - Hasil aktual 0.7.0: …

- [ ] **T132 — Versi dan atribusi**
  - Langkah: Buka Pengaturan → Tentang/Sumber & lisensi.
  - Diharapkan: Versi 0.7.0 sesuai APK; sumber/lisensi logo tersedia; tidak lagi menampilkan footer 0.4.0.
  - Status: BELUM
  - Hasil aktual 0.7.0: …

- [ ] **T133 — Impor daftar IDX setelah redesign**
  - Langkah: Impor Excel/JSON valid, batalkan preview, lalu coba file rusak. Coba kembali dan konfirmasikan data valid.
  - Diharapkan: Kode/perusahaan/kolom sumber tetap terjaga; batal/gagal tidak mengubah katalog; holdings dan histori tetap tersambung.
  - Status: BELUM
  - Hasil aktual 0.7.0: …

- [ ] **T134 — Keamanan saat kembali dari picker**
  - Langkah: Buka Photo Picker/SAF dari form atau backup, kembali ke Arta saat kunci aktif.
  - Diharapkan: Tidak meminta akses galeri/penyimpanan luas; kunci kembali sesuai pengaturan; draft form tetap ada setelah autentikasi.
  - Status: BELUM
  - Hasil aktual 0.7.0: …

## Riwayat sesi 0.6.0 — hasil lama dipertahankan

# Checklist pengujian HP — Arta 0.6.0

Hasil sesi USB: **LULUS: 18**, **GAGAL: 2**, **SEBAGIAN: 50**, **TERHALANG: 1**, **BELUM: 37**. Tiga bug baru dicatat; hasil ini bukan pernyataan seluruh fitur sudah bebas bug.

Dokumen ini diisi pengguna saat menguji APK di HP Android. Setelah diisi, **simpan file ini lalu kirim pesan `review hasil testing`**. Codex akan membaca hasil aktual, status, dan laporan bug di dokumen ini untuk menentukan perbaikan.

APK: [`arta-0.6.0-debug.apk`](../build/app/outputs/flutter-apk/arta-0.6.0-debug.apk) · [Identitas build](BUILD-0.6.0.json) · [Panduan terbaru](TAHAP-6-0.6.0.md) · [Panduan investasi dan bunga](TAHAP-4-0.4.0.md).

Nama file markdown lama dipertahankan agar laporan tetap di satu tempat. Checklist ini sekarang mencakup **108 kasus untuk versi 0.6.0**, bukan hanya fitur versi 0.2.0. Hasil pengujian USB 20 November 2026 sudah diisi; kasus yang belum lengkap diberi **SEBAGIAN** dan tetap tidak dicentang. Hasil komputer (168 tes lulus) tidak berarti tes HP sudah lulus. Riwayat startup versi lama tetap disimpan pada T01 dan BUG-001; laporan USB lama tersedia di [laporan Samsung A05s](TESTING-HP-2026-11-19.md).

**Tambahan 0.5.0:** T81–T100 di bawah mencakup chart, sepuluh crypto bawaan, staking, penutupan otomatis dan referensi riwayat offline. Semua fitur tambahan ini sudah masuk APK 0.6.0; gunakan APK terbaru untuk mengujinya. Lihat [panduan 0.5.0](TAHAP-5-0.5.0.md). Ulangi regresi T01–T80; perubahan versi: backup baru schema 5, harga terbaru manual terpisah, dan toggle refresh lima menit pada T61 diganti penutupan harian otomatis default aktif.

**Tambahan 0.6.0:** T101–T108 mencakup redesign tanpa kucing, IHSG, estimasi TWR dan pencarian IPO. Semua fitur 0.5.0 tetap ada. SQLite menjadi skema 5; format backup finansial tetap schema 5. APK 0.6.0 sudah dibuild dan identitas/tanda tangannya terverifikasi; hasil HP tersedia pada [laporan 20 November](TESTING-HP-2026-11-20.md); belum semua cabang diuji. Lihat [panduan 0.6.0](TAHAP-6-0.6.0.md).

## Identitas pengujian

| Isian | Jawaban pengguna |
| --- | --- |
| Nama penguji | Codex melalui ADB; sidik jari dibantu pemilik HP |
| Tanggal dan jam pengujian | 20 November 2026, mulai 11:28 WIB |
| Merek/model HP | Samsung A05s |
| Versi Android | 15 |
| Versi aplikasi | 0.6.0+8 — cocokkan dengan APK yang dipasang |
| Pemasangan | Memperbarui versi … / instalasi baru |
| Zona waktu HP | … (disarankan WIB untuk mengikuti contoh) |
| Ukuran font awal | Normal / lainnya: … |
| Ada data pribadi sebelum pengujian? | Tidak; database awal kosong, snapshot baseline disimpan |
| Catatan perangkat lain yang digunakan | … |

**Status pengujian 0.6.0:** diuji melalui USB pada Samsung A05s Android 15, 20 November 2026; lihat [laporan hasil](TESTING-HP-2026-11-20.md). Kamu dapat menguji manual tanpa kabel USB; tidak perlu emulator atau login Google. [Panduan USB](KONEKSI-HP-USB.md) hanya dibutuhkan bila nanti ingin mengambil log. Jangan menulis API key, PIN, atau sandi asli dalam laporan/bukti.

Urutan yang disarankan: T01–T26 untuk regresi dasar, T27–T78 untuk fitur tambahan, lanjutkan T81–T108 untuk chart, staking, penutupan harian, redesign dan IHSG; lakukan T79–T80 untuk reset dan pemulihan terakhir. Boleh dibagi beberapa sesi; simpan backup dan catat nomor terakhir. Pengujian online meliputi T46, T58–T61, T63, T93–T94, T102 dan T107; kasus lain dapat memakai data lokal.

## Cara mengisi hasil

- `[ ]` berarti belum selesai diperiksa (`BELUM` atau `SEBAGIAN`). Ganti menjadi `[x]` setelah hasil kasus ditutup, termasuk jika hasilnya gagal atau terhalang. Rincian langkah yang belum dijalankan tetap dicantumkan.
- Ubah `Status: BELUM` menjadi `LULUS`, `GAGAL`, `SEBAGIAN`, atau `TERHALANG`.
- `SEBAGIAN`: hanya subpemeriksaan yang tertulis pada hasil aktual sudah dijalankan; checkbox tetap kosong. Kasus gagal dapat ditutup setelah kegagalan terkonfirmasi, dengan subpemeriksaan lain yang belum dijalankan tetap disebutkan.
- `LULUS`: semua hasil yang diharapkan sesuai. `GAGAL`: ada hasil yang berbeda. `TERHALANG`: tidak bisa menyelesaikan pengujian; tulis alasannya.
- Isi **Hasil aktual** dengan angka, tanggal, pesan error, atau perilaku yang terlihat. Untuk kegagalan, gunakan ID `BUG-002`, `BUG-003`, dan seterusnya; BUG-001 adalah riwayat lama pada bagian **Laporan bug** di akhir.
- Screenshot/video membantu menjelaskan bug. Simpan bukti di `docs/testing/bukti/` lalu tulis nama filenya. Bukti tidak wajib untuk kasus yang lulus.
- Ikuti urutan kasus. Jika satu kasus gagal dan saldo berbeda, tandai kasus berikutnya yang bergantung padanya sebagai `TERHALANG`, atau tulis keadaan awal pengganti yang digunakan. Jangan memaksakan hasil berikutnya agar cocok.
- Beberapa kasus memiliki beberapa langkah; centang kasus setelah semua langkah dan hasilnya diperiksa. Catat bagian yang gagal bila hanya sebagian yang berhasil.

Contoh pengisian:

```markdown
- [x] **T05 — Transfer dengan biaya**
  Status: GAGAL
  Hasil aktual: QA Mandiri -35.000, QA Wallet 5.000. Biaya 1.000 tidak terpotong.
  Bug/bukti: BUG-002 / testing/bukti/BUG-002.png
```

## Persiapan

1. Gunakan data uji untuk mengikuti angka di bawah. Jika aplikasi sudah berisi data pribadi, **ekspor backup lebih dahulu**, pastikan file tersimpan di luar folder privat aplikasi, dan catat lokasinya. Restore pada bagian akhir memang mengganti seluruh data.
2. Jangan uninstall atau hapus data aplikasi untuk tes tutup/buka. Kedua tindakan tersebut berbeda dari menutup aplikasi dan dapat menghilangkan database lokal.
3. Salin APK ke HP, lalu pasang. Jika memperbarui versi lama, pasang sebagai pembaruan agar data lama dipertahankan.
4. Siapkan folder dokumen di HP, misalnya `Documents/Arta-Uji`, untuk hasil ekspor dan cadangan sebelum restore. Pilih penyimpanan lokal saat menguji dalam mode pesawat.
5. Salin tiga file berikut ke folder uji di HP:
   - [`arta-backup-v1-uji.json`](testing/fixtures/arta-backup-v1-uji.json): contoh backup lama yang valid, berisi data palsu.
   - [`arta-backup-versi-tidak-didukung.json`](testing/fixtures/arta-backup-versi-tidak-didukung.json): JSON dengan versi yang sengaja tidak didukung.
   - [`arta-backup-rusak-uji.json`](testing/fixtures/arta-backup-rusak-uji.json): JSON yang sengaja terpotong; diharapkan ditolak.
6. Nominal mengikuti format Indonesia: `100000` atau `100.000`, desimal `0,10`. Semua tanggal historis di checklist sengaja dipilih agar pengujian bisa dilakukan sekarang. **Tidak perlu mengubah tanggal/jam HP.**
7. Setiap aturan uji otomatis harus memakai batas **jumlah kejadian** yang disebutkan. Jangan membiarkan aturan historis otomatis tanpa batas.
8. Salin Excel IDX asli dari laptop ke HP: `C:\Users\User\Downloads\Daftar Saham  - 20261118.xlsx`. File ini berisi 944 saham. Salin juga [CSV harga valid](testing/fixtures/harga-valid-0.4.0.csv) dan [CSV harga tidak valid](testing/fixtures/harga-tidak-valid-0.4.0.csv). Perubahan contoh file dilakukan pada salinan data uji.
9. Ini aplikasi pencatatan manual: tidak menyambungkan login bank/exchange, tidak mengeksekusi order, tidak sinkron antarperangkat. Jadwal/bunga otomatis diproses saat aplikasi aktif/dibuka; tidak ada worker atau notifikasi Android. Hal-hal tersebut bukan bug versi ini.
10. T01–T26 memakai rangkaian saldo yang saling bergantung. T27 dan seterusnya memakai akun QA baru agar tidak merusak angka pembanding awal. Jangan menghapus atau mengganti hasil lama ketika menemukan bug baru.
11. Saldo kas memakai dua desimal; unit/harga investasi hingga 12 desimal. Unit investasi memakai desimal titik/koma tanpa pemisah ribuan. Harga pasar dalam checklist adalah angka uji, bukan instruksi investasi.

## A. Pemasangan dan transaksi dasar

- [ ] **T01 — Instalasi, logo, dan buka pertama**

  1. Pasang APK, lalu buka melalui ikon Arta di launcher.
  2. Periksa ikon, splash, dan layar awal. Tutup aplikasi lalu buka sekali lagi.
  3. Jika memperbarui versi lama, periksa akun, saldo, transaksi, foto, kartu, kunci, jadwal, dan tema lama sebelum membuat data uji. Catat apakah pemeriksaan pembaruan ini bisa dilakukan.

  **Diharapkan:** aplikasi dapat dibuka tanpa crash; logo tampil; loading selesai setelah data siap. Pada pembaruan, data lama tetap ada. Loading yang sangat singkat tidak dianggap gagal.

  Status: SEBAGIAN
  Hasil aktual 0.6.0: USB 20 November 2026 — Startup dan beberapa force-stop/buka ulang berhasil; logo dan loading terlihat. APK terpasang cocok SHA256. Instalasi/upgrade tidak dijalankan dalam sesi ini; data awal kosong.
  Bug/bukti 0.6.0: [Laporan HP](TESTING-HP-2026-11-20.md); `../build/physical-device-0.6.0/` — initial; cold-reopen; final-ready-summary.

  Riwayat versi lama (bukan hasil 0.6.0):
  Riwayat 0.2.0: Berdasarkan laporan pengguna di percakapan, setelah APK dipasang dan dibuka muncul "Penyimpanan lokal belum dapat dibuka". Menekan Coba lagi menghasilkan pesan yang sama. HP Samsung A05s, Android 15.
  Pemeriksaan pembaruan 0.1.0: Belum dilaporkan
  Hasil aktual 0.2.1: berhasil masuk Ringkasan setelah pembaruan dan buka ulang; pembaruan berikutnya mempertahankan 5 akun + 1 transaksi QA. Bukti: [laporan HP](TESTING-HP-2026-11-19.md) dan `build/physical-device/final-cold-reopen.png`.
  Uji ulang 0.2.1+3 melalui USB, 19 November 2026: LULUS untuk startup. Pembaruan berhasil, masuk Ringkasan, lalu berhasil setelah force-stop/buka ulang. Tidak ada akun lama sehingga pemeriksaan pelestarian data pengguna belum dilakukan. Bukti: `../build/physical-device/arta-reopen-021.png` dan `.xml`. Hasil gagal 0.2.0 di atas dipertahankan sebagai riwayat.

- [ ] **T02 — Akun dan saldo awal offline, termasuk minus**

  1. Aktifkan mode pesawat, lalu buka Arta.
  2. Buat lima akun berikut melalui menu **Akun**. Gunakan nama persis agar mudah ditemukan:

     | Nama | Jenis | Saldo awal |
     | --- | --- | ---: |
     | QA Mandiri | Bank | 100.000 |
     | QA Wallet | Dompet digital | 0 |
     | QA Minus | Bank | -1.000 |
     | QA Jadwal | Bank | 0 |
     | QA Cicilan | Bank | 0 |

  3. Periksa daftar akun dan Ringkasan.

  **Diharapkan:** kelima akun tersimpan tanpa internet. QA Minus tetap `-Rp 1.000`. Saldo awal tidak menjadi pemasukan/transaksi baru. Jumlah kelima saldo QA adalah `Rp 99.000`; total aplikasi sama hanya jika tidak ada akun lain.

  Status: SEBAGIAN
  Hasil aktual: …
  Bug/bukti: …

- [x] **T03 — Cadangan keadaan awal**

  1. Buka **Pengaturan > Ekspor JSON biasa**.
  2. Simpan dengan nama `QA-Awal.json` di folder dokumen HP. Jika pemilih file menambahkan ekstensi sendiri, hindari menggandakan `.json`.
  3. Periksa lewat aplikasi Files/File Manager bahwa file ada dan ukurannya bukan nol.

  **Diharapkan:** file berhasil disimpan melalui pemilih dokumen Android. Setelah kembali ke Arta, akun dan saldo tidak berubah. Simpan file ini untuk pemulihan jika pengujian perlu diulang; restore akan mengganti seluruh data.

  Status: LULUS
  Hasil aktual/nama dan lokasi file: …
  Bug/bukti: …

- [x] **T04 — Pengeluaran melampaui saldo dan pemasukan**

  1. Catat **Pengeluaran**, akun QA Mandiri, nominal `150.000`, kategori `QA Belanja`, tanggal hari ini, catatan `QA pengeluaran awal`.
  2. Periksa saldo: seharusnya `-Rp 50.000`.
  3. Catat **Pemasukan**, QA Mandiri, nominal `20.000`, kategori `QA Gaji`, tanggal hari ini, catatan `QA pemasukan`.

  **Diharapkan:** pengeluaran tidak ditolak karena saldo kurang. Setelah kedua transaksi, QA Mandiri `-Rp 30.000`; kedua transaksi tampil sekali pada daftar.

  Status: LULUS
  Hasil aktual/saldo: …
  Bug/bukti: …

- [x] **T05 — Transfer dengan biaya**

  1. Catat **Transfer** dari QA Mandiri ke QA Wallet, nominal `5.000`, biaya `1.000`, tanggal hari ini, catatan `QA transfer`.
  2. Periksa kedua saldo dan jumlah transaksi transfer.

  **Diharapkan:** QA Mandiri `-Rp 36.000`, QA Wallet `Rp 5.000`. Hanya ada satu catatan transfer dengan dua akun. Total seluruh saldo turun `Rp 1.000`, yaitu biaya; nominal transfer tidak menjadi pemasukan/pengeluaran biasa.

  Status: LULUS
  Hasil aktual/saldo kedua akun: …
  Bug/bukti: …

- [x] **T06 — Edit dan hapus menghitung ulang saldo**

  1. Buka transaksi `QA Belanja` dari T04 dan ubah nominal dari `150.000` menjadi `100.000`.
  2. Periksa QA Mandiri: `Rp 14.000`; transaksi tetap satu, bukan bertambah.
  3. Hapus transaksi QA Belanja tersebut melalui ikon tempat sampah dan konfirmasi.

  **Diharapkan:** setelah hapus, QA Mandiri `Rp 114.000`, QA Wallet `Rp 5.000`, QA Minus `-Rp 1.000`. Pemasukan dan transfer tetap ada. Jumlah saldo kelima akun QA adalah `Rp 118.000`.

  Status: LULUS
  Hasil aktual/saldo setelah edit dan setelah hapus: …
  Bug/bukti: …

- [ ] **T07 — Validasi dan pembatalan formulir**

  1. Coba simpan pengeluaran dengan nominal kosong, `0`, atau negatif; coba kategori kosong.
  2. Coba transfer tanpa tujuan dan dengan biaya negatif. Periksa bahwa akun asal tidak dapat dipilih sebagai akun tujuan yang sama.
  3. Isi transaksi valid, tetapi tekan kembali tanpa menyimpan. Coba hapus transaksi lain lalu pilih **Batal** pada dialog.

  **Diharapkan:** isian tidak valid ditolak dengan pesan yang terbaca. Pembatalan tidak mengubah transaksi atau saldo dari T06. Saldo akun negatif tetap diperbolehkan; yang ditolak adalah nominal transaksi negatif.

  Status: SEBAGIAN
  Hasil aktual/pesan validasi: …
  Bug/bukti: …

- [x] **T08 — Presisi desimal**

  1. Pada QA Minus, catat pemasukan `0,10` dengan kategori `QA Desimal`.
  2. Catat pemasukan `0,20` pada akun yang sama.
  3. Catat pengeluaran `0,30` pada akun yang sama.

  **Diharapkan:** saldo berturut-turut `-Rp 999,90`, `-Rp 999,70`, lalu kembali tepat `-Rp 1.000`. Tidak ada sisa pembulatan. Tiga transaksi desimal tersebut tetap tersimpan.

  Status: LULUS
  Hasil aktual/ketiga saldo: …
  Bug/bukti: …

- [x] **T09 — Pencarian dan grafik arus kas**

  1. Pada daftar Transaksi, cari `QA Gaji`, `QA transfer`, dan `QA Wallet` secara bergantian.
  2. Cari teks yang tidak ada, lalu kosongkan pencarian.
  3. Buka Ringkasan dan periksa grafik bulan ini, sebelum menjalankan pengujian jadwal berikutnya.

  **Diharapkan:** hasil pencarian sesuai kategori/catatan/akun; pencarian kosong mengembalikan daftar. Jika hanya data QA yang digunakan dan T04–T08 memakai hari ini, pemasukan bulan ini `Rp 20.000,30`, pengeluaran `Rp 1.000,30`. Pengeluaran QA Belanja yang dihapus tidak dihitung; transfer hanya menyumbang biaya `1.000`.

  Status: LULUS
  Hasil aktual/angka grafik: …
  Bug/bukti: …

- [ ] **T10 — Data tetap ada setelah aplikasi dihentikan**

  1. Catat saldo dan jumlah transaksi saat ini.
  2. Buka pengaturan Android untuk Arta, pilih **Paksa berhenti/Force stop**, lalu buka kembali. Jangan pilih hapus data atau uninstall.
  3. Periksa data dalam mode pesawat. Jika memungkinkan, ulangi setelah me-restart HP.

  **Diharapkan:** akun, transaksi dan saldo tetap sama; tidak ada transaksi ganda atau loading tanpa akhir. Catat terpisah jika restart HP belum dicoba.

  Status: SEBAGIAN
  Hasil aktual/sebelum dan sesudah: …
  Restart HP: Belum / Lulus / Gagal
  Bug/bukti: …

## B. Transaksi berulang

Gunakan akun **QA Jadwal**, yang saldonya masih `0` sebelum T11. Buka **Pengaturan > Transaksi berulang > +**. Untuk aturan bulanan tanggal tertentu, matikan **Hari terakhir setiap bulan** dan pilih tanggal melalui **Mulai**. Pada kalender gunakan pemilih tahun untuk tanggal historis.

- [ ] **T11 — Dua jadwal Mandiri: tanggal 4 dan akhir bulan**

  1. Buat aturan `QA Biaya tanggal 4`: Pengeluaran, QA Jadwal, kategori `QA Biaya bank`, nominal `5.500`, mulai **4 Januari 2024**, bulanan, N `1`, jumlah kejadian **3**, mode **Catat otomatis saat jatuh tempo**.
  2. Periksa tiga transaksi bertanggal **4 Januari, 4 Februari, 4 Maret 2024**. Saldo QA Jadwal `-Rp 16.500`.
  3. Buat aturan `QA Biaya akhir bulan`: isian sama, nominal `6.000`, mulai **4 Januari 2024**, aktifkan **Hari terakhir setiap bulan**, jumlah kejadian **3**, mode otomatis.

  **Diharapkan:** aturan kedua mencatat **31 Januari, 29 Februari, 31 Maret 2024**. Total ada enam transaksi dari kedua aturan dan QA Jadwal `-Rp 34.500`. Keduanya selesai setelah tiga kejadian; tidak mencatat bulan-bulan setelah Maret 2024.

  Status: SEBAGIAN
  Hasil aktual/tanggal, jumlah transaksi, saldo: …
  Bug/bukti: …

- [x] **T12 — Refresh, buka ulang, dan ketukan berulang tidak menggandakan transaksi**

  1. Tekan ikon periksa/refresh di halaman Transaksi berulang beberapa kali.
  2. Pindah ke aplikasi lain lalu kembali. Paksa berhenti Arta, lalu buka lagi.
  3. Periksa kedua aturan T11 dan transaksi QA Jadwal.

  **Diharapkan:** tetap enam transaksi, QA Jadwal tetap `-Rp 34.500`. Tidak ada transaksi tambahan karena refresh, resume, atau buka ulang.

  Status: LULUS
  Hasil aktual/jumlah sebelum dan sesudah: …
  Bug/bukti: …

- [ ] **T13 — Konfirmasi dengan nominal dan tanggal aktual**

  1. Buat aturan `QA Konfirmasi`: Pengeluaran, QA Jadwal, nominal `7.000`, kategori `QA Tagihan`, mulai **10 April 2024**, bulanan, jumlah **1**, mode **Minta konfirmasi**.
  2. Pastikan saldo belum berubah dan kejadian tampil pada bagian Jatuh tempo.
  3. Ketuk kejadian, ubah nominal aktual menjadi `7.500`, tanggal aktual **11 April 2024**, lalu catat. Ketuk tombol simpan dengan cepat dua kali bila memungkinkan.

  **Diharapkan:** satu transaksi aktual `7.500` pada 11 April; jatuh tempo di riwayat tetap 10 April. Nominal aturan tetap `7.000`. QA Jadwal menjadi `-Rp 42.000`; kejadian tidak menunggu dicatat lagi.

  Status: SEBAGIAN
  Hasil aktual/nominal, kedua tanggal, saldo: …
  Bug/bukti: …

- [ ] **T14 — Lewati sekali**

  1. Buat aturan `QA Lewati`: Pengeluaran `8.000`, QA Jadwal, mulai **1 Mei 2024**, bulanan, jumlah **1**, mode konfirmasi.
  2. Buka kejadian lalu pilih **Lewati sekali**, dan konfirmasi.
  3. Refresh dan buka ulang aplikasi.

  **Diharapkan:** tidak ada transaksi baru; QA Jadwal tetap `-Rp 42.000`. Riwayat menunjukkan **Dilewati** dan kejadian tidak muncul ulang untuk dicatat.

  Status: BELUM
  Hasil aktual/riwayat dan saldo: …
  Bug/bukti: …

- [ ] **T15 — Hapus transaksi jadwal tanpa dibuat ulang**

  1. Dari riwayat `QA Biaya tanggal 4`, buka transaksi **4 Januari 2024** senilai `5.500`.
  2. Hapus transaksi itu dan periksa status kejadian pada riwayat aturan.
  3. Refresh, paksa berhenti, lalu buka aplikasi kembali.

  **Diharapkan:** QA Jadwal naik menjadi `-Rp 36.500`. Kejadian bertanda **Transaksi dihapus** dan tidak terbentuk lagi. Transaksi Februari dan Maret tetap ada.

  Status: BELUM
  Hasil aktual/status dan saldo setelah buka ulang: …
  Bug/bukti: …

- [ ] **T16 — Edit jadwal dijeda, jangkar tanggal 31, dan lanjutkan seluruh kejadian**

  1. Buat `QA Jeda`: Pengeluaran `9.000`, QA Jadwal, mulai **31 Januari 2025**, bulanan, jumlah **3**, mode konfirmasi.
  2. Catat hanya kejadian pertama, 31 Januari, senilai `9.000`. QA Jadwal sekarang `-Rp 45.500`.
  3. Buka detail aturan dan pilih **Jeda jadwal**. Refresh; tidak boleh ada transaksi berikutnya yang tercatat.
  4. Pilih **Ubah jadwal mendatang**. Ubah nama menjadi `QA Jeda baru`, nominal per kejadian `10.000`, dan mode otomatis. **Jangan ubah tanggal mulai yang sudah terisi 28 Februari 2025.** Jumlah sisa harus 2. Simpan.
  5. Periksa aturan baru masih **Dijeda**, dengan kejadian **28 Februari dan 31 Maret 2025**. Saldo masih `-Rp 45.500`. Aturan lama ada pada filter Semua sebagai dihentikan; transaksi Januari tetap `9.000`.
  6. Pada aturan baru, pilih **Lanjutkan jadwal > Proses semua yang lewat**.

  **Diharapkan:** dua transaksi baru masing-masing `10.000` pada 28 Februari dan 31 Maret. QA Jadwal `-Rp 65.500`. Refresh tidak mengulangnya. Edit tidak mengaktifkan jadwal yang dijeda atau menggeser Maret menjadi tanggal 28.

  Status: BELUM
  Hasil aktual/status, tanggal, riwayat lama dan saldo: …
  Bug/bukti: …

- [ ] **T17 — Lanjutkan dengan melewati sebelum hari ini**

  1. Buat `QA Lewati masa jeda`: Pengeluaran `2.000`, QA Jadwal, **harian**, N `1`, mulai **kemarin**, jumlah **2**, mode konfirmasi.
  2. Jeda aturan lalu pilih **Lanjutkan jadwal > Lewati sebelum hari ini**.
  3. Periksa riwayat dan daftar Jatuh tempo. Setelah diperiksa, **hentikan aturan ini** agar tidak mengganggu pengujian berikutnya.

  **Diharapkan:** kejadian kemarin dilewati; kejadian hari ini masih menunggu konfirmasi. Tidak ada transaksi baru dan QA Jadwal tetap `-Rp 65.500`. Menghentikannya membatalkan kejadian hari ini yang belum diproses.

  Status: BELUM
  Hasil aktual/kejadian kemarin dan hari ini: …
  Bug/bukti: …

- [ ] **T18 — Hentikan aturan tanpa menghapus transaksi lama**

  1. Buat `QA Hentikan`: Pengeluaran `1.000`, QA Jadwal, mulai **hari ini**, bulanan, jumlah **3**, mode konfirmasi.
  2. Catat kejadian pertama, lalu pilih **Hentikan pengulangan** dan konfirmasi.
  3. Cari aturan pada filter Semua, refresh dan buka ulang.

  **Diharapkan:** transaksi pertama tetap ada; QA Jadwal `-Rp 66.500`. Aturan berstatus dihentikan dan tidak dapat dilanjutkan. Kejadian berikutnya tidak dapat diproses dari aturan itu.

  Status: BELUM
  Hasil aktual/transaksi lama dan saldo: …
  Bug/bukti: …

- [ ] **T19 — Frekuensi, interval, batas tanggal dan pratinjau masa depan**

  1. Buat empat aturan berikut pada QA Jadwal, nominal bebas positif, kategori `QA Kalender`, **semuanya mode konfirmasi**. Jangan mencatat kejadiannya.

     | Nama | Mulai | Frekuensi / N | Batas | Tanggal yang harus terlihat |
     | --- | --- | --- | --- | --- |
     | QA Interval | 31 Jan 2024 | Bulanan / 2 | Jumlah 3 | 31 Jan, 31 Mar, 31 Mei 2024 |
     | QA Mingguan | 23 Des 2024 | Mingguan / 2 | Jumlah 3 | 23 Des 2024, 6 Jan dan 20 Jan 2025 |
     | QA Tahunan | 29 Feb 2024 | Tahunan / 1 | Jumlah 5 | 29 Feb 2024; 28 Feb 2025/2026/2027; 29 Feb 2028 |
     | QA Batas tanggal | 28 Feb 2024 | Harian / 1 | Jumlah kosong; akhir 1 Mar 2024 | 28 Feb, 29 Feb, 1 Mar 2024; tidak ada 2 Mar |

  2. Buka detail masing-masing. Periksa pratinjau tidak mengubah saldo.
  3. Pada formulir baru yang kemudian dibatalkan, coba interval `0`, jumlah `0`, serta tanggal akhir sebelum mulai. Pastikan tidak dapat menyimpan aturan tidak valid.
  4. Periksa pilihan zona WIB/WITA/WIT tersedia dan WIB menjadi awal untuk aturan baru. Pilih WITA pada satu aturan konfirmasi, simpan, lalu buka lagi untuk memeriksa pilihannya tersimpan.

  **Diharapkan:** tanggal dan batas sesuai tabel, QA Jadwal tetap `-Rp 66.500`. Validasi terbaca. Rencana masa depan tidak masuk saldo. Pengujian tepat pergantian hari antarzona boleh dicatat sebagai belum dicoba; jangan mengganti jam HP untuk memaksanya.

  Status: BELUM
  Hasil aktual per aturan dan zona: …
  Bug/bukti: …

## C. Cicilan pengeluaran

- [ ] **T20 — Pembagian total dan pembulatan bagian terakhir**

  1. Dari menu tambah jadwal pilih **Cicilan pengeluaran**. Buat `QA Cicilan pembulatan`, akun QA Cicilan, kategori `QA Cicilan`, **total `100`**, jumlah bagian **3**, mulai **31 Januari 2024**, setiap `1` bulan, mode otomatis.
  2. Periksa tiga transaksi dan progres pada detail.
  3. Refresh dan buka ulang.

  **Diharapkan:** nominal `33,33`, `33,33`, `33,34` pada 31 Januari, 29 Februari, 31 Maret 2024. Jumlah tepat `100`, QA Cicilan `-Rp 100`, progres 3/3 dan sisa rencana 0. Tidak ada pengeluaran tambahan `100` di awal dan tidak ada bagian keempat. Jika hanya data QA sesuai urutan yang digunakan, total semua akun QA kini `Rp 51.400`.

  Status: SEBAGIAN
  Hasil aktual/ketiga nominal, jumlah dan progres: …
  Bug/bukti: …

- [ ] **T21 — Nominal aktual, bagian dilewati, dan hapus cicilan**

  1. Buat rencana kedua `QA Cicilan aktual`, QA Cicilan, total `100`, 3 bagian, mulai **31 Januari 2025**, bulanan, mode konfirmasi. Belum boleh mengubah saldo.
  2. Catat bagian pertama dengan **nominal aktual `30`**. Saldo QA Cicilan `-Rp 130`. Sisa rencana `66,67`, karena bagian rencana pertama bernilai `33,33`; bagian berikutnya tidak dibagi ulang.
  3. Lewati bagian kedua. Sisa rencana `33,34`, saldo tetap `-Rp 130`.
  4. Catat bagian ketiga `33,34`. Saldo QA Cicilan `-Rp 163,34`; progres 3/3, pengeluaran aktual rencana kedua `63,34`, sisa rencana 0.
  5. Dari riwayat rencana kedua, hapus transaksi bagian pertama `30`. Refresh dan buka ulang.

  **Diharapkan:** sesudah hapus, QA Cicilan `-Rp 133,34`. Rencana kedua tetap diproses 3/3, pengeluaran aktualnya `33,34`, sisa rencana 0. Bagian pertama dihapus, bagian kedua dilewati, bagian ketiga tercatat; keduanya yang tidak tercatat tidak muncul ulang.

  Status: BELUM
  Hasil aktual/saldo dan progres setiap langkah: …
  Bug/bukti: …

## D. Backup dan restore lewat Android

Selesaikan T22 sebelum T23–T26. File **QA-UjiLengkap.json** menjadi titik pemulihan, mencakup seluruh pengujian sampai T21. Aturan otomatis uji sudah memiliki batas dan selesai, sehingga restore saat ini seharusnya tidak menambah kejadian baru. Aturan konfirmasi tidak mencatat sendiri.

- [x] **T22 — Ekspor dan restore JSON lengkap**

  1. Catat saldo kelima akun, jumlah transaksi, jumlah aturan termasuk dihentikan, serta status kejadian T14/T15/T21 pada bagian **Snapshot pembanding** di bawah.
  2. Ekspor JSON biasa bernama **QA-UjiLengkap.json** melalui pemilih dokumen Android. Pastikan file ada di folder uji.
  3. Buat pemasukan sementara `1` ke QA Wallet, kategori `QA Setelah backup`. Wallet menjadi `5.001` jika langkah sebelumnya sesuai.
  4. Pilih **Pulihkan dari file**, pilih QA-UjiLengkap.json, baca pratinjau, lanjutkan, dan **simpan cadangan sebelum restore** dengan nama berbeda. Catat nama cadangan tersebut.
  5. Setelah restore, periksa saldo, riwayat kejadian, aturan dijeda/dihentikan/selesai, dan tema. Refresh lalu buka ulang.

  **Diharapkan:** pemasukan sementara hilang dan Wallet kembali `5.000`. Seluruh data cocok snapshot pembanding; status dilewati/dihapus tetap ada dan tidak dibuat ulang. File cadangan sebelum restore tersimpan. Tidak ada penggabungan data atau transaksi ganda.

  Status: LULUS
  Hasil aktual/nama kedua file dan perbandingan data: …
  Bug/bukti: …

### Snapshot pembanding T22

Isi dari aplikasi sebelum mengekspor, bukan sekadar menyalin angka yang diharapkan.

| Data | Sebelum ekspor | Sesudah restore T22 | Sesudah restore akhir T26 |
| --- | --- | --- | --- |
| QA Mandiri (target 114.000) | … | … | … |
| QA Wallet (target 5.000) | … | … | … |
| QA Minus (target -1.000) | … | … | … |
| QA Jadwal (target -66.500) | … | … | … |
| QA Cicilan (target -133,34) | … | … | … |
| Jumlah transaksi | … | … | … |
| Jumlah aturan termasuk dihentikan | … | … | … |
| Tema | … | … | … |
| QA Lewati: status kejadian | … | … | … |
| QA Biaya tanggal 4: kejadian Januari dihapus | … | … | … |
| QA Cicilan aktual: status ketiga bagian | … | … | … |

- [x] **T23 — Backup terenkripsi, kata sandi salah dan pemulihan**

  1. Pilih **Backup terenkripsi**. Coba kata sandi kurang dari 8 karakter dan konfirmasi kata sandi berbeda; pastikan validasi tampil.
  2. Simpan backup dengan kata sandi khusus data uji, misalnya `ArtaUji2026!`, bernama **QA-Terenkripsi.json**. Ingat kata sandinya.
  3. Tambahkan pemasukan sementara `2` ke QA Wallet, kategori `QA Setelah enkripsi`. Wallet menjadi `5.002`.
  4. Pilih restore file terenkripsi dan masukkan kata sandi salah. Periksa data tidak berubah.
  5. Ulangi dengan kata sandi benar. Simpan cadangan sebelum restore, lalu periksa data dan buka ulang aplikasi.

  **Diharapkan:** kata sandi salah menghasilkan pesan penolakan dan Wallet tetap `5.002`. Dengan kata sandi benar, data kembali seperti sebelum ekspor dan Wallet `5.000`; progres dan status jadwal tetap utuh. UI masih dapat menampilkan loading selama proses enkripsi.

  Status: LULUS
  Hasil aktual/pesan salah kata sandi dan hasil pemulihan: …
  Bug/bukti: …

- [x] **T24 — Pembatalan pemilih file dan penolakan backup tidak valid**

  1. Mulai ekspor dan batalkan pemilih lokasi. Mulai restore dan batalkan pemilih file. Pastikan dapat kembali ke aplikasi dan mencoba lagi.
  2. Buat pemasukan penanda `1` ke QA Wallet, kategori `QA Batal restore`. Wallet menjadi `5.001`.
  3. Pilih QA-UjiLengkap.json untuk restore, setujui pratinjau, lalu **batalkan saat diminta menyimpan cadangan sebelum restore**.
  4. Periksa pemasukan penanda tetap ada. Coba impor file `arta-backup-rusak-uji.json`, lalu `arta-backup-versi-tidak-didukung.json`.
  5. Setelah hasil dicatat, hapus hanya pemasukan penanda `QA Batal restore` agar Wallet kembali `5.000`.

  **Diharapkan:** pembatalan cadangan membatalkan restore; Wallet masih `5.001` sebelum penanda dibersihkan. Kedua file negatif ditolak dengan pesan yang terbaca, tanpa kehilangan/mengganti data. Aplikasi tetap dapat digunakan dan tidak terus terkunci pada status sibuk.

  Status: LULUS
  Hasil aktual/perilaku batal dan kedua pesan penolakan: …
  Bug/bukti: …

## E. Tampilan dan kompatibilitas backup lama

- [x] **T25 — Tema, ukuran teks, keyboard dan orientasi**

  1. Di Pengaturan, pilih Gelap, Terang, lalu Ikuti perangkat. Periksa Ringkasan, Akun, Transaksi, daftar/detail berulang, dan formulir transaksi/cicilan.
  2. Dengan Ikuti perangkat aktif, ubah tema Android dan periksa tampilan mengikuti. Pilih kembali tema yang diinginkan, tutup dan buka Arta untuk memeriksa penyimpanan pilihannya.
  3. Besarkan ukuran font Android, putar HP landscape, lalu buka formulir panjang. Tampilkan keyboard, gulir sampai tombol Simpan, tutup keyboard dan kembali tanpa menyimpan.
  4. Kembalikan ukuran font/orientasi yang nyaman. Jangan menyimpan transaksi tambahan pada pengujian ini.

  **Diharapkan:** teks, ikon, saldo minus, form dan tombol dapat dibaca/dijangkau pada kedua tema. Tidak ada elemen bertumpuk atau tombol terhalang permanen oleh keyboard. Nilai uang dan data tidak berubah karena pergantian tampilan. Catat ukuran font dan layar yang bermasalah jika ada.

  Status: GAGAL
  Hasil aktual/tema, font, orientasi dan layar: …
  Bug/bukti: …

- [ ] **T26 — Restore backup v1 dan kembali ke data uji lengkap**

  1. Pastikan QA-UjiLengkap.json dari T22 tersedia. Jika ada data yang baru ingin dipertahankan setelah T22, ekspor cadangan baru sebelum melanjutkan.
  2. Pulihkan `arta-backup-v1-uji.json`. Ikuti penyimpanan cadangan sebelum restore.
  3. Periksa hanya ada akun `QA Legacy` dengan saldo `-Rp 1.100`: saldo awal `-1.000`, satu pengeluaran `100`, tema terang, dan tidak ada aturan berulang. Data QA sebelumnya terganti karena ini restore snapshot.
  4. Pulihkan kembali **QA-UjiLengkap.json**, simpan cadangan sebelum restore, lalu isi kolom terakhir Snapshot pembanding T22. Refresh dan buka ulang.

  **Diharapkan:** backup v1 diterima dengan nilai tepat. Setelah kembali ke backup v2 lengkap, akun, transaksi, progres, kejadian dilewati/dihapus dan pengaturan cocok snapshot T22, tanpa duplikasi. Tema kembali ke yang tersimpan pada T22. Kasus ini menguji format backup lama; migrasi database dari instalasi 0.1.0 diperiksa terpisah pada T01.

  Status: BELUM
  Hasil aktual/saldo legacy dan perbandingan akhir: …
  Bug/bukti: …


## F. Waktu, biaya, privasi, dan foto

- [ ] **T27 — Kalender dan jam dinding 24 jam**

  1. Buat akun bank QA UI saldo 100.000.
  2. Buat pengeluaran 1.000 pada 18 November 2026 pukul 23:45 melalui kalender dan jam dinding; simpan.
  3. Buka kembali dan ubah menjadi 00:05, simpan, lalu buka ulang.

  **Diharapkan:** Tanggal dan menit tersimpan tepat, tersedia pemilih jam 24 jam tanpa AM/PM. Edit tidak membuat transaksi ganda; saldo tetap 99.000.

  Status: SEBAGIAN
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T28 — Zona waktu dan transaksi lama tanpa jam**

  1. Pada transaksi uji yang berbeda pilih WIB, WITA, WIT dan jam yang sama; periksa nilai setelah buka ulang.
  2. Periksa transaksi dari backup v1 pada T26 atau backup lama milikmu tanpa menimpa data utama tanpa cadangan.

  **Diharapkan:** Zona dan jam transaksi baru konsisten. Transaksi lama tanpa jam tidak mendapat jam palsu; tanggal tidak bergeser karena konversi zona.

  Status: BELUM
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T29 — Toggle biaya pada semua form terkait**

  1. Pada Transfer QA UI → QA Wallet isi 1.000 dan biaya 100; matikan toggle sebelum simpan.
  2. Periksa hanya 1.000 terpotong.
  3. Buat transfer kedua dengan biaya aktif 100.
  4. Ulangi pemeriksaan tampil/sembunyi pada jadwal, cicilan yang mendukung biaya, dan form investasi; batalkan form uji lain.

  **Diharapkan:** Field biaya muncul saat aktif; saat nonaktif biaya efektif nol meskipun sebelumnya terisi. Transfer kedua memotong asal 1.100 dan tujuan menerima 1.000. Tidak ada biaya tersembunyi.

  Status: SEBAGIAN
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T30 — Mata untuk menyembunyikan saldo**

  1. Tekan mata saldo; periksa Ringkasan, daftar akun, kartu, transaksi, portofolio, grafik dan rincian investasi.
  2. Tutup/buka aplikasi, lalu tampilkan kembali.

  **Diharapkan:** Nominal/kuantitas sensitif disamarkan titik ••••••, grafik sensitif tidak membocorkan nilai. Preferensi bertahan setelah buka ulang dan menampilkan kembali tidak mengubah data. Catat layar yang masih membocorkan angka.

  Status: SEBAGIAN
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T31 — Lampiran struk melalui Photo Picker**

  1. Buat transaksi pada QA UI dengan satu foto struk palsu dari HP; simpan, buka detail/edit, tambah hingga tiga foto lalu simpan.
  2. Force-stop/buka ulang dan buka struk.
  3. Jangan gunakan foto berisi data rahasia.

  **Diharapkan:** Pemilih foto Android muncul; tidak meminta akses seluruh galeri/storage. Maksimal tiga gambar, orientasi benar, foto tetap terbuka setelah restart aplikasi.

  Status: SEBAGIAN
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T32 — Foto: batal, hapus, dan batas**

  1. Batalkan pemilih foto, lalu buka lagi.
  2. Coba tambah foto keempat pada transaksi T31; hapus satu foto dan ganti foto lain.
  3. Buka form edit, ubah lampiran tetapi batalkan form, lalu periksa data tersimpan.

  **Diharapkan:** Pembatalan tidak membuat foto/transaksi kosong. Batas tiga ditegakkan, penghapusan/penggantian tersimpan hanya saat Simpan; edit yang dibatalkan mempertahankan foto lama. File tak didukung memberi pesan tanpa crash.

  Status: BELUM
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …


## G. Kunci opsional dan kartu debit

- [ ] **T33 — PIN aplikasi dengan keypad sendiri**

  1. Buka Pengaturan > Kunci aplikasi.
  2. Periksa kondisi nonaktif; aktifkan PIN Arta enam digit khusus uji, ulangi konfirmasi.
  3. Coba PIN konfirmasi berbeda terlebih dahulu.
  4. Pilih Kunci sekarang dan buka dengan PIN benar.

  **Diharapkan:** Kunci bersifat opsional, PIN Arta terpisah dari PIN HP. Keypad angka khusus, hapus dan konfirmasi berfungsi tanpa keyboard Android; PIN tidak muncul di laporan/backup.

  Status: SEBAGIAN
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T34 — PIN salah dan jeda percobaan**

  1. Saat terkunci masukkan PIN salah lima kali.
  2. Coba lagi saat timer aktif.
  3. Pindah aplikasi dan buka kembali, tunggu hingga jeda habis lalu gunakan PIN benar.

  **Diharapkan:** Data tidak terbuka dengan PIN salah. Ada jeda minimal 30 detik setelah lima kegagalan; membuka ulang tidak menghapus jeda. Setelah jeda, PIN benar berhasil. Catat durasi/tulisan yang terlihat.

  Status: SEBAGIAN
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [x] **T35 — Sidik jari HP dan fallback PIN Arta**

  1. Jika sidik jari sudah terdaftar di Android, aktifkan sidik jari Arta dengan PIN cadangan.
  2. Kunci dan buka memakai sidik jari benar; batalkan dialog sensor dan pilih PIN Arta.
  3. Jika sensor belum disetel, catat TERHALANG untuk bagian sensor.

  **Diharapkan:** Menggunakan dialog/sensor biometrik Android, bukan gambar sidik jari simulasi. Batal/gagal sensor tidak membuka data; PIN Arta tetap tersedia. PIN perangkat tidak dianggap otomatis sebagai PIN Arta.

  Status: LULUS
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T36 — Background, layar mati, dan draft**

  1. Isi form transaksi baru tanpa menyimpan.
  2. Pindah aplikasi, kembali dan autentikasi.
  3. Ulangi dengan mematikan/menyalakan layar, lalu force-stop/buka ulang.

  **Diharapkan:** Data sensitif tertutup sebelum autentikasi. Setelah background biasa, form/draft tetap dapat dilanjutkan tanpa duplikasi; setelah force-stop draft belum tersimpan boleh hilang. Saldo tidak berubah sebelum Simpan.

  Status: BELUM
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T37 — Ubah/nonaktifkan kunci dan sandi bermata**

  1. Coba ubah PIN atau nonaktifkan kunci; batalkan autentikasi dan pastikan pengaturan tidak berubah.
  2. Ulangi dengan autentikasi benar.
  3. Periksa tombol mata pada sandi backup dan API key di pengaturan harga.

  **Diharapkan:** Perubahan keamanan memerlukan autentikasi saat kunci aktif. Pembatalan tidak menonaktifkan kunci. Tombol mata menampilkan/menyamarkan nilai tanpa mengganti teks; jangan menyertakan rahasia dalam screenshot.

  Status: SEBAGIAN
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T38 — Kunci saat kembali dari pemilih dokumen/foto**

  1. Aktifkan kunci.
  2. Buka pemilih foto dari draft dan pemilih ekspor/import dokumen; batalkan/pilih file lalu kembali dan autentikasi jika diminta.
  3. Periksa draft dan status operasi.

  **Diharapkan:** Tidak ada layar data terbuka sebelum verifikasi, loop autentikasi, form hilang tanpa sebab, atau operasi tercatat dua kali. Setelah membuka kunci, alur file tetap dapat diteruskan.

  Status: BELUM
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T39 — Kartu debit Jago tertaut rekening**

  1. Buat bank QA Jago saldo 100.000.
  2. Melalui Kartu debit buat QA Debit Jago Syariah tertaut QA Jago.
  3. Catat pengeluaran 10.000 memakai kartu tersebut.

  **Diharapkan:** Saldo QA Jago menjadi 90.000. Kartu menampilkan sumber yang sama; kekayaan tidak bertambah 100.000 karena membuat kartu. Tidak perlu nomor kartu, CVV atau PIN kartu.

  Status: SEBAGIAN
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T40 — Relink kartu dan riwayat lama**

  1. Buat bank QA Jago Kantong saldo 50.000.
  2. Ubah sumber kartu T39 ke kantong ini.
  3. Catat pengeluaran kartu baru 5.000, kemudian periksa transaksi T39 dan kartu setelah buka ulang.

  **Diharapkan:** Pengeluaran lama tetap mengambil QA Jago (90.000). Pengeluaran baru mengambil kantong (45.000); relink tidak memindahkan riwayat/saldo lama.

  Status: BELUM
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …


## H. Ilustrasi, katalog IDX, dan instrumen

- [ ] **T41 — Empty state dan logo/loading**

  1. Cari transaksi dengan teks yang tidak ada dan buka portofolio sebelum membuat investasi.
  2. Periksa placeholder struk serta daftar kosong lain; lihat splash saat membuka aplikasi pada kedua tema.

  **Diharapkan:** Ilustrasi/ikon kucing dan logo Arta terbaca pada kedua tema. Loading selesai, tidak menutupi tombol permanen. Kondisi kosong memberi aksi yang relevan.

  Status: SEBAGIAN
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T42 — Katalog saham offline, detail, dan logo**

  1. Mode pesawat: buka Katalog saham & instrumen, filter Saham, cari BBCA dengan kode/nama lalu TRUE.
  2. Buka detail, lihat tanggal pencatatan, jumlah lembar dan papan.
  3. Hapus pencarian, gunakan Tampilkan 50 berikutnya.
  4. Ulangi online untuk logo.

  **Diharapkan:** Katalog awal 944 saham bila belum dimodifikasi. Hanya saham lokal IDX yang dicari; TRUE tetap teks kode. Seluruh metadata sumber selain No tersedia. Logo gagal memakai fallback tanpa crash; kode tidak memakai .JK pada logo Stockbit.

  Status: SEBAGIAN
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T43 — Impor Excel IDX asli dan JSON katalog**

  1. Pilih Impor IDX lalu file Excel asli 944 saham.
  2. Periksa sheet/preview dan jumlah baris; terapkan.
  3. Ekspor IDX JSON dan impor ulang file itu.

  **Diharapkan:** Impor berulang tidak menggandakan saham. Kode, nama, tanggal, seluruh digit jumlah lembar dan papan dipertahankan; No tidak diperlukan. Sheet dipilih jika ada beberapa yang cocok. JSON hasil ekspor dapat diimpor ulang.

  Status: SEBAGIAN
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T44 — Impor: batal, metadata tambahan, dan file negatif**

  1. Ekspor katalog terlebih dahulu.
  2. Buat salinan Excel kecil berisi BBCA/TRUE: ubah satu nama dan tambah kolom QA Catatan; preview lalu Batal, ulangi dan Terapkan.
  3. Coba salinan dengan kode duplikat, nama kosong, formula pada field penting, tanggal/jumlah lembar tidak valid, file rusak atau lebih dari 10 MB.

  **Diharapkan:** Batal tidak mengubah katalog. Impor valid menyimpan kolom baru sebagai metadata dan memberi peringatan. Saham yang absen tidak dihapus. File invalid ditolak seluruhnya tanpa perubahan sebagian. Catat tiap variasi yang dicoba; lainnya TERHALANG/belum dicoba.

  Status: BELUM
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T45 — Koreksi metadata, arsip, dan kembali ke sumber**

  1. Koreksi nama tampilan BBCA/logo HTTPS atau mapping yang tersedia.
  2. Impor ulang Excel sumber.
  3. Arsipkan BBCA, periksa pilihan transaksi baru; lalu buka detail dan kembali ke metadata sumber/nonarsipkan.

  **Diharapkan:** Koreksi tidak hilang saat impor ulang. Arsip tidak menghapus instrumen/riwayat/harga. Kembali ke sumber memulihkan metadata sumber; BBCA dapat dipakai kembali. Pastikan selesai dalam keadaan tidak diarsipkan.

  Status: BELUM
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T46 — Crypto: pencarian online dan ID manual**

  1. Online: Cari crypto online untuk bitcoin dan ethereum, pilih hasil yang tepat.
  2. Offline: buat instrumen crypto manual jika belum ada, simbol QA, ID unik khusus uji.
  3. Coba dua crypto bersimbol sama dengan ID berbeda.

  **Diharapkan:** ID CoinGecko tersimpan, bukan menebak dari simbol. Dua simbol sama dapat dibedakan ID; hasil online menampilkan identitas yang dapat dipilih. Tidak ada pencarian otomatis tiap ketukan atau logo wajib.

  Status: SEBAGIAN
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T47 — Instrumen reksa dana manual dan validasi**

  1. Buat reksa dana QA Bibit IDR, lalu coba instrumen tanpa nama/kode, kode saham duplikat, kode saham tidak valid, dan URL logo bukan HTTPS.
  2. Batalkan form invalid.

  **Diharapkan:** QA Bibit tersimpan dan dapat dicari offline. Instrumen invalid/duplikat ditolak dengan pesan terbaca. Tidak ada akun/unit/uang baru hanya karena membuat instrumen.

  Status: SEBAGIAN
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …


## I. Dana dan transaksi investasi

- [ ] **T48 — Transfer dana bank ke sekuritas/exchange**

  1. Buat QA Bank Invest saldo 5.000.000, QA RDN saldo 0 dan QA Exchange saldo 0, semuanya IDR.
  2. Transfer 3.000.000 dari bank ke RDN tanpa biaya; catat total ketiga akun.

  **Diharapkan:** Bank 2.000.000, RDN 3.000.000, Exchange 0. Jumlah tetap 5.000.000; transfer pokok bukan pengeluaran konsumsi atau pemasukan baru.

  Status: BELUM
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T49 — Dua pembelian saham, lot, dan modal rata-rata**

  1. Pada BBCA/QA RDN catat beli 1 lot (100 lembar), bruto 1.000.000 biaya 1.000 pada 16 November 2026 09:00.
  2. Catat beli 100 lembar, bruto 1.200.000 biaya 2.000 pada 17 November 09:00.
  3. Isi harga manual 12.000 per lembar tanggal 18 November.
  4. Gunakan input nominal aktual, bukan harga pasar online.

  **Diharapkan:** RDN 797.000; 200 lembar, total modal 2.203.000, rata-rata 11.015/lembar. Nilai pada harga uji 2.400.000, laba belum terealisasi 197.000. Pembelian tidak menjadi konsumsi atau mengurangi uang dua kali.

  Status: SEBAGIAN
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T50 — Penjualan sebagian, laba, dan penarikan**

  1. Lanjut T49: jual 50 lembar, bruto 650.000 biaya 1.000 pada 18 November 10:00.
  2. Tarik dana RDN → QA Bank Invest sebesar 100.000 tanpa biaya.

  **Diharapkan:** Setelah jual kas RDN 1.446.000; sisa 150 lembar dengan modal 1.652.250; laba terealisasi 98.250 (649.000 − 550.750). Setelah tarik: RDN 1.346.000, bank 2.100.000. Penjualan bukan pendapatan bruto 650.000 dan penarikan bukan pemasukan baru.

  Status: SEBAGIAN
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T51 — Edit/hapus investasi dan cegah unit negatif**

  1. Edit catatan penjualan T50 tanpa mengubah nominal/unit, pastikan satu event.
  2. Coba ubah unit penjualan menjadi 999, lalu batalkan/lihat penolakan.
  3. Coba hapus pembelian kedua T49; catat hitungan baru, lalu pulihkan pembelian dengan tanggal/nominal yang sama.
  4. Terakhir coba hapus seluruh pembelian yang menyisakan penjualan tanpa unit.

  **Diharapkan:** Edit/hapus valid menghitung ulang kas/modal berdasarkan urutan sejarah. Perubahan yang membuat unit historis negatif ditolak dan seluruh keadaan sebelumnya tetap utuh. Selesaikan dengan dua pembelian serta satu penjualan seperti T50 agar angka berikutnya dapat dibandingkan.

  Status: BELUM
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T52 — Saldo unit awal dan modal tidak diketahui**

  1. Buat lokasi QA Awal, isi saldo unit awal 10 lembar saham lain dengan modal historis 50.000; catat kas sebelum/sesudah.
  2. Di lokasi/instrumen berbeda isi unit awal dengan Modal awal tidak diketahui; beri harga manual.

  **Diharapkan:** Unit awal tidak mendebit kas. Modal diketahui tersimpan; modal tak diketahui diberi label, tidak dibuat nol dan tidak dianggap seluruh nilai pasar sebagai laba. Harga manual tidak mengubah unit/modal.

  Status: SEBAGIAN
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T53 — Pindah crypto dan biaya jaringan unit**

  1. Gunakan bitcoin IDR, lokasi QA Crypto Asal dan QA Crypto Tujuan saldo kas masing-masing 0.
  2. Isi unit awal 1 BTC dengan modal 1.000.000 di asal pada 16 November.
  3. Pada 17 November pindah 0,4 BTC (diterima tujuan), biaya jaringan 0,001 BTC dan biaya tunai 1.000.

  **Diharapkan:** Asal 0,599 BTC dengan modal 599.000; tujuan 0,4 BTC dengan modal 400.000. Modal biaya jaringan 1.000 keluar dari posisi. Kas asal menjadi −1.000; kas tujuan 0. Jangan menafsirkan 0,4 sebagai jumlah yang sudah termasuk biaya unit.

  Status: BELUM
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T54 — Dividen/hasil tunai dengan potongan**

  1. Pada BBCA/QA RDN catat dividen bruto 10.000 dan potongan/biaya 1.000; catat unit/modal sebelum dan sesudah.

  **Diharapkan:** Kas RDN naik 9.000. Unit dan modal tidak berubah. Laporan mencatat pendapatan bruto 10.000 dan potongan biaya 1.000; tidak membuat pembelian/unit baru.

  Status: BELUM
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T55 — Reward, split, dan reverse split**

  1. Pada crypto T53 catat reward 0,01 unit di asal; periksa modal tetap.
  2. Pada saham terpisah isi awal 100 lembar/modal 100.000, split faktor 2 lalu reverse faktor 0,5 pada tanggal berurutan.
  3. Coba reverse yang menghasilkan pecahan lembar.

  **Diharapkan:** Reward menambah unit dengan modal nol tanpa mengubah kas. Saham 100 → 200 → 100, modal tetap 100.000; pecahan lembar ditolak. Laba rata-rata menyesuaikan unit, tidak ada kas fiktif.

  Status: BELUM
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T56 — Bibit: pending, beli, NAB, dan pencairan**

  1. Buat QA Dana Bibit dan QA Cair Bibit IDR saldo 0.
  2. Transfer bank uji → Dana Bibit 100.000 (menunggu konfirmasi).
  3. Pada konfirmasi catat beli QA Bibit 12,345678901234 unit, bruto 100.000 tanpa biaya.
  4. Isi NAB 10.000 lalu 11.000 pada tanggal berbeda.
  5. Jual 1 unit, bruto 11.000 masuk QA Cair Bibit, lalu transfer 11.000 ke bank.

  **Diharapkan:** Sebelum konfirmasi hanya ada uang dalam proses, belum ada unit perkiraan. Setelah beli saldo Dana Bibit nol, unit presisi 12 desimal; NAB tidak mengubah kas/modal/unit. Jual menyisakan 11,345678901234 unit; dana belum cair tetap dicatat sampai transfer masuk bank. Tidak ada pendapatan ganda.

  Status: BELUM
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T57 — Portofolio, harga historis, dan kekayaan**

  1. Buka alokasi, daftar kepemilikan, rincian modal/laba, grafik harga serta riwayat semua transaksi.
  2. Isi dua harga manual berbeda tanggal.
  3. Periksa total dengan kalkulasi kas + nilai unit; coba mata privacy.

  **Diharapkan:** Nilai unit ditambahkan sekali bersama kas yang tersisa, bukan saldo awal setoran plus seluruh investasi. Grafik hanya memakai observasi tersimpan dan tanggal sumber, bukan riwayat palsu. Tanpa harga/kurs tampil total belum lengkap. Riwayat panjang dapat dibuka.

  Status: SEBAGIAN
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …


## J. API key, harga online, dan cache

- [ ] **T58 — API key perangkat dan mata password**

  1. Pengaturan > Sumber harga & mata uang: isi key Demo milikmu secara privat, tekan Simpan pengaturan harga.
  2. Coba mata tampil/sembunyi, pindah aplikasi saat lock aktif, buka ulang dan periksa pengaturan tersimpan.

  **Diharapkan:** Key disamarkan secara default, tidak tampil di log/bukti/backup. Konfigurasi tersimpan pada perangkat; kunci aktif memerlukan autentikasi saat perubahan sensitif. Key tidak ditanam di APK sehingga perlu diisi di HP.

  Status: SEBAGIAN
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T59 — Yahoo saham IDX: close terakhir**

  1. Pastikan memiliki BBCA.
  2. Online, Perbarui harga di portofolio; periksa sumber, mata uang, tanggal harga dan waktu pengambilan.
  3. Cocokkan penutupan sesi terakhir yang sudah selesai; catat angka/tanggal yang dilihat.

  **Diharapkan:** Mengambil BBCA.JK dan IDR. Sebelum sesi selesai + jeda 15 menit, memakai sesi tertutup sebelumnya; memakai close biasa. Jika Yahoo menolak/belum tersedia, error terbaca dan harga uji/cache tetap ada. Catat TERHALANG jika gangguan provider mencegah uji sukses.

  Status: SEBAGIAN
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [x] **T60 — CoinGecko crypto dengan key**

  1. Dengan bitcoin/ethereum yang dimiliki dan key benar, refresh harga setelah jeda minimal satu menit.
  2. Periksa harga, ID instrumen, sumber dan timestamp.
  3. Coba key tidak valid hanya jika perlu, lalu kembalikan key benar tanpa menuliskannya di laporan.

  **Diharapkan:** Harga melekat pada ID crypto yang tepat dan currency yang diminta. Timestamp sumber terpisah dari jam unduh. Key invalid/error tidak menimpa cache menjadi nol atau mengubah unit/kas.

  Status: LULUS
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T61 — Offline, jeda refresh, dan penutupan harian otomatis**

  1. Catat cache lalu mode pesawat dan refresh.
  2. Kembali online, coba refresh dua kali cepat.
  3. Aktifkan **Simpan penutupan harian otomatis**, buka aplikasi saat online dengan instrumen yang dimiliki, lalu periksa tanggal harga. Pindah halaman/background/kunci dan periksa status saat kembali. Lanjutkan rincian saham/crypto pada T93–T94.
  4. Matikan otomatis dan periksa bahwa pembaruan hanya berjalan ketika diminta manual; kembalikan pilihan sesuai kebutuhan setelah uji.

  **Diharapkan:** Offline tetap menampilkan harga terakhir/tanggalnya; refresh manual diberi jeda minimal satu menit. Penutupan otomatis hanya diproses saat aplikasi aktif, siap, dan tidak terkunci; tidak ada polling harga live lima menit. Target penutupan yang sudah diperiksa tidak diminta terus-menerus. Respons 429 bila terjadi memberi jeda, bukan loop. Jangan sengaja menghabiskan kuota untuk memancing 429; tulis belum teramati bila tidak terjadi.

  Status: SEBAGIAN
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T62 — Harga/NAB CSV: preview dan validasi**

  1. Impor harga-valid-0.4.0.csv, periksa preview lalu Batal: harga belum berubah.
  2. Ulangi Terapkan.
  3. Coba harga-tidak-valid-0.4.0.csv (baris kedua nol), mata uang salah, tanggal masa depan dan baris duplikat pada salinan.
  4. Ekspor harga lalu impor ulang hasilnya.

  **Diharapkan:** Valid BBCA/TRUE diterapkan pada tanggal yang tercantum. Satu baris invalid menolak seluruh file, tidak menyimpan baris valid sebagian. Batal tidak mengubah harga. Ekspor dapat diimpor ulang; simbol crypto ambigu memerlukan ID instrumen.

  Status: BELUM
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T63 — Google Sheets CSV sebagai cadangan**

  1. Opsional sumber: siapkan spreadsheet publik data uji kolom code,date,price,currency, isi BBCA dengan tanggal/harga penutupan yang tersedia; gunakan URL CSV HTTPS docs.google.com/spreadsheets/.
  2. Simpan URL, Ambil harga spreadsheet tersimpan dan periksa preview.
  3. Coba URL bukan HTTPS/host tidak diizinkan lalu batalkan.

  **Diharapkan:** Data CSV melewati validasi yang sama, tidak perlu login Google dalam Arta. URL tidak sah ditolak. Bila belum memiliki spreadsheet publik, tandai TERHALANG beserta alasannya; jangan menandainya lulus. GOOGLEFINANCE berada di spreadsheet, bukan koneksi broker aplikasi.

  Status: BELUM
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …


## K. Mata uang dan kurs

- [ ] **T64 — Akun asing dan nilai IDR**

  1. Buat QA USD saldo 10 USD, QA USDT saldo 2 USDT.
  2. Di sumber harga/kurs isi USD=15.000 IDR dan USDT=15.100 IDR dengan tanggal.
  3. Periksa daftar mata uang IDR/USD/USDT/SGD/EUR/MYR.

  **Diharapkan:** Valuasi QA USD 150.000 dan QA USDT 30.200; mata uang/token tidak diasumsikan sama. Mata uang asal dan dua desimal kas tetap terlihat. Tidak ada kurs 1:1 diam-diam.

  Status: SEBAGIAN
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T65 — Transfer lintas mata uang dengan biaya**

  1. Buat QA FX Bank IDR saldo 1.000.000 dan QA FX USD saldo 0.
  2. Transfer 150.000 IDR ke akun USD, isi nominal diterima 10 USD serta biaya asal 1.000.
  3. Coba simpan tanpa nominal tujuan terlebih dahulu.

  **Diharapkan:** Tanpa nominal tujuan ditolak; hasil valid bank 849.000 dan tujuan 10 USD. Biaya dalam mata uang asal; tidak menambahkan nominal 150.000 sebagai USD atau memakai kurs otomatis untuk mengganti hasil aktual.

  Status: BELUM
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T66 — Kurs historis, hilang, dan jadwal asing**

  1. Buat pengeluaran 1 USD pada QA FX USD dengan kurs historis 15.000.
  2. Ubah kurs valuasi USD menjadi 16.000; periksa laporan dan kekayaan.
  3. Pada mata uang yang belum punya kurs, buat akun/jadwal konfirmasi atau otomatis satu kejadian terbatas, kemudian isi kurs dan refresh.

  **Diharapkan:** Laporan pengeluaran lama tetap 15.000 IDR, saldo 9 USD saat ini dinilai 144.000. Kurs hilang ditandai total belum lengkap; jadwal otomatis menunggu tanpa merusak startup lalu mencatat sekali setelah kurs tersedia. Jadwal lintas mata uang belum didukung; gunakan transaksi manual.

  Status: BELUM
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …


## L. Bunga dan bagi hasil yang diinput pengguna

- [ ] **T67 — Estimasi harian dan dasar saldo**

  1. Buat QA Bunga saldo awal 1.000.000, tanpa transaksi lain.
  2. Tambah aturan 1–2 Januari 2024, kredit harian, tier awal 0 tarif 3,65%/tahun, basis 365, pajak 20%, saldo akhir hari sebelumnya, otomatis nonaktif.
  3. Buka preview sebelum konfirmasi.

  **Diharapkan:** Preview masing-masing hari bruto 100, pajak 20, net 80. Saldo tetap 1.000.000 sebelum konfirmasi. Tarif tidak diisi otomatis dari nama bank. Pilihan basis 360/365/366 tersedia; ini tarif uji, bukan tarif bank sebenarnya.

  Status: SEBAGIAN
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T68 — Bunga aktual, penggandaan, dan pembatalan**

  1. Konfirmasi periode pertama T67 dengan bruto aktual 110/pajak 22; saldo naik 88.
  2. Periksa estimasi hari kedua memakai saldo sebelumnya termasuk kredit aktual jika tanggal kredit sesuai.
  3. Refresh/buka ulang, lalu batalkan catatan bunga pertama melalui riwayat.

  **Diharapkan:** Satu kredit aktual net 88; pendapatan 110, pajak biaya 22. Tidak duplikat setelah refresh. Estimasi dapat berubah karena saldo, posting aktual lain tidak ditulis ulang. Pembatalan mengembalikan saldo dan menandai periode agar tidak otomatis tercatat ulang.

  Status: SEBAGIAN
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T69 — Bunga bulanan, tier, dan Februari kabisat**

  1. Gunakan akun terpisah QA Tier saldo tetap 1.500.000.
  2. Buat aturan bulanan 1–29 Februari 2024, basis 365, pajak 0, tier 0 tarif 0% dan tier 1.000.000 tarif 3,65%, otomatis nonaktif.
  3. Bandingkan saldo menyeluruh vs progresif memakai aturan/akun terpisah agar tidak bertumpuk.

  **Diharapkan:** Mode seluruh saldo: harian 150, bruto Februari 4.350. Progresif: hanya 500.000 berbunga, harian 50, bruto 1.450. Februari dihitung 29 hari; tidak dicatat sebelum periode berakhir. Saldo negatif menghasilkan estimasi nol.

  Status: BELUM
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T70 — Bunga otomatis terbatas, overlap, dan arsip**

  1. Buat akun QA Auto Bunga saldo 1.000.000, aturan hanya 1 Januari 2024 (mulai=akhir), tier 3,65%, basis 365, pajak 0, otomatis aktif.
  2. Buka ulang/refresh beberapa kali.
  3. Coba aturan aktif lain yang bertumpuk pada akun/periode sama.
  4. Nonaktifkan aturan selesai; coba membuat aturan baru dengan tanggal tidak bertumpuk.

  **Diharapkan:** Hanya satu kredit 100; tidak ada ribuan kredit tak terbatas. Overlap ditolak; histori tetap ada saat aturan dinonaktifkan. Perubahan tarif memakai aturan baru efektif mendatang. Catch-up panjang dibatasi per proses dan aplikasi tetap responsif.

  Status: BELUM
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …


## M. Utang, piutang, ekspor, dan pemulihan akhir

- [ ] **T71 — Pokok utang tidak menjadi pendapatan/belanja**

  1. Buat QA Utang saldo 0 dan QA Bank Utang saldo 0.
  2. Transfer utang → bank 100.000.
  3. Bayar pokok bank → utang 20.000, biaya 1.000.

  **Diharapkan:** Setelah pinjam bank 100.000/utang −100.000. Setelah bayar bank 79.000/utang −80.000. Kekayaan gabungan −1.000 (biaya), pokok tidak masuk pemasukan/konsumsi.

  Status: BELUM
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T72 — Piutang dan belanja kredit tanpa hitung ganda**

  1. Dengan akun bank uji yang cukup, beri pinjaman 30.000 lewat transfer bank → QA Piutang; terima kembali 10.000.
  2. Buat pengeluaran kartu kredit 5.000 dari akun utang, lalu bayar pokok 5.000 lewat transfer bank → utang.

  **Diharapkan:** Piutang tersisa 20.000; pokok tidak menjadi biaya/pemasukan. Pengeluaran kredit dihitung sekali saat belanja, pembayaran tagihan tidak menjadi pengeluaran kedua. Kartu debit Jago tetap berbeda dari akun utang.

  Status: BELUM
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T73 — Ekspor CSV transaksi, kepemilikan, harga**

  1. Ekspor tiga CSV dari Pengaturan ke dokumen HP dan buka di spreadsheet.
  2. Bandingkan contoh transaksi kas/investasi/bunga, unit, biaya unit, pajak, kurs/tanggal dan kepemilikan.
  3. Uji catatan berisi koma, kutip, baris baru dan awalan =1+1 pada data palsu.

  **Diharapkan:** UTF-8/aksen terbaca, kolom tidak bergeser, baris keuangan tidak tertukar jenisnya. Unit 12 desimal dan minus terbaca. Teks berawalan formula dilindungi, bukan dieksekusi. CSV bukan backup lengkap dan tidak memuat API key/PIN.

  Status: BELUM
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [x] **T74 — Backup v4 lengkap seluruh fitur**

  1. Catat snapshot akhir pada tabel di bawah.
  2. Ekspor QA-Lengkap-040.json biasa dan terenkripsi.
  3. Tambah transaksi penanda, ubah harga/metadata, lalu restore cadangan dan simpan backup sebelum restore.
  4. Ulangi dengan terenkripsi dan sandi uji benar; buka ulang/refresh.

  **Diharapkan:** Unit/modal/laba, foto, kartu/sumber historis, katalog beserta kolom tambahan, cache harga, kurs, bunga/void, jadwal/skip/delete dan tema kembali persis snapshot. Penanda hilang. Tidak ada bunga/jadwal ganda. PIN/key tetap preferensi perangkat, tidak tertimpa backup.

  Status: LULUS
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T75 — Backup lama v2/v3 dan kunci perangkat**

  1. Setelah QA-Lengkap-040.json aman, bila memiliki backup v2/v3 asli data uji, pulihkan satu per satu.
  2. Periksa akun/transaksi/jadwal dan foto/kartu pada v3; lalu kembalikan backup v4 lengkap.
  3. Jangan mengedit angka schema file untuk memalsukan backup lama.

  **Diharapkan:** Format v1/v2/v3 dibaca dengan default fitur baru yang sesuai dan data keuangan lama tetap tepat. API key dan kunci perangkat tidak diimpor dari file. Jika tidak punya backup v2/v3, tandai bagian ini TERHALANG; T26 sudah menguji v1.

  Status: SEBAGIAN
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [x] **T76 — Buka ulang offline setelah data lengkap**

  1. Catat jumlah akun/transaksi/event dan total terakhir.
  2. Mode pesawat, force-stop, buka ulang.
  3. Jika memungkinkan restart HP dan buka Arta, autentikasi lalu periksa portofolio/struk/katalog.

  **Diharapkan:** Tidak ada error penyimpanan, unit/modal/saldo tetap, foto terbuka dan cache harga tetap bertanggal sumber. Tidak membutuhkan login atau internet untuk transaksi. Tidak ada jadwal/bunga duplikat.

  Status: TERHALANG
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [x] **T77 — Semua layar: gelap/terang, font besar, landscape**

  1. Ulangi kedua tema pada katalog/preview impor, portofolio/detail/grafik, investasi, NAB, sumber harga/kurs, bunga, utang, kartu, keamanan dan file restore.
  2. Besarkan font Android hingga sekitar 200%, putar landscape dan tampilkan keyboard pada form panjang.

  **Diharapkan:** Tombol Simpan/Batal dan navigasi terjangkau lewat scroll, teks/ikon dan saldo minus terbaca, tidak ada overflow/tumpang tindih. Chart, dialog, keypad dan list panjang tetap dapat digunakan. Tulis nama layar persis bila gagal.

  Status: GAGAL
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [ ] **T78 — Pemilih file, ukuran, dan error tidak merusak data**

  1. Batalkan ekspor/import katalog/CSV/backup pada pemilih dokumen lalu coba kembali.
  2. Coba file format salah/JSON rusak.
  3. Jika ada file uji backup lebih dari 25 MB, coba dan catat penolakannya; tidak perlu membuat ribuan foto hanya untuk ini.

  **Diharapkan:** Tidak meminta akses luas galeri/storage; pembatalan tidak mengubah data atau membuat status sibuk permanen. Batas katalog 10 MB dan backup 25 MB ditolak dengan pesan, data utama tetap ada. Catat subkasus ukuran yang belum dicoba.

  Status: BELUM
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [x] **T79 — Hapus data Android menjadi instalasi baru**

  1. Lakukan PALING AKHIR dan hanya setelah backup v4 lengkap/terenkripsi tersimpan di Documents serta lokasi/sandinya diketahui.
  2. Android > Aplikasi > Arta > Penyimpanan > Hapus data (bukan hapus cache).
  3. Buka Arta dan periksa Pengaturan/saldo.

  **Diharapkan:** Data pengguna/foto/kartu/transaksi/unit/jadwal/bunga hilang; kunci Arta, key, URL dan preferensi kembali awal. Katalog bawaan dapat muncul kembali. Tanpa login, sidik jari/PIN Arta tidak diwarisi dari data yang dihapus. Ini tes yang sengaja menghapus data; bila belum siap tandai TERHALANG.

  Status: LULUS
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

- [x] **T80 — Pemulihan setelah reset dan laporan final**

  1. Setelah T79, restore QA-Lengkap-040.json atau versi terenkripsinya melalui pemilih dokumen, simpan cadangan instalasi baru jika diminta.
  2. Cocokkan snapshot T74.
  3. Setel kembali key/kunci secara privat bila ingin.
  4. Isi ringkasan dan bug lalu simpan markdown ini.

  **Diharapkan:** Semua data keuangan kembali, backup di Documents tetap ada setelah hapus data. Key/PIN tidak pulih otomatis; dapat dikonfigurasi ulang. Riwayat skip/void/delete mencegah duplikasi. Hasil siap direview melalui pesan review hasil testing.

  Status: LULUS
  Hasil aktual (angka/tanggal/pesan; sublangkah belum dicoba): …
  Bug/bukti: …

### Snapshot lengkap T74 / T80

Isi nilai aktual sebelum ekspor; jangan menyalin target sebagai hasil uji.

| Data | Sebelum ekspor T74 | Setelah restore T74 | Setelah reset/restore T80 |
| --- | --- | --- | --- |
| Jumlah akun / transaksi kas | … | … | … |
| Jumlah event investasi / unit per lokasi | … | … | … |
| Kas bank / RDN / exchange | … | … | … |
| Modal / laba terealisasi / nilai pasar | … | … | … |
| Harga, tanggal sumber, dan kurs | … | … | … |
| Katalog / koreksi / kolom tambahan | … | … | … |
| Jumlah foto / kartu dan sumber | … | … | … |
| Aturan / skip / transaksi jadwal dihapus | … | … | … |
| Bunga aktual / periode dibatalkan | … | … | … |
| Utang / piutang | … | … | … |
| Tema | … | … | … |
| Nama/lokasi backup / ukuran file | … | … | … |

## N. Fitur 0.5.0 — tersedia dalam APK 0.6.0

Gunakan akun uji baru agar angka T01–T80 tetap dapat dibandingkan. Semua kasus di bagian ini BELUM diuji di HP. Jangan menulis key, PIN, atau sandi asli pada laporan.

- [ ] **T81 — Line chart dan donut portofolio investasi**

  1. Buka Portofolio > Grafik portofolio setelah memiliki unit dan minimal dua harga bertanggal berbeda.
  2. Ganti periode 1B/3B/6B/1T/Semua; ketuk/geser garis dan legenda/segmen donut.

  **Diharapkan:** garis menunjukkan nilai unit berdasarkan kepemilikan/harga historis, tooltip tanggal/IDR; donut komposisi saat ini per instrumen, dijumlahkan lintas lokasi. Pokok staking tidak menambah total dua kali. Ini grafik nilai, bukan persen return.

  Status: SEBAGIAN
  Hasil aktual: …
  Bug/bukti: …

- [ ] **T82 — Dua garis pemasukan dan pengeluaran**

  1. Buat pemasukan 100, pengeluaran 20, transfer 30 dengan biaya 5 pada tanggal uji yang sama.
  2. Buka Analisis & grafik > Pemasukan & pengeluaran dan pilih titik/interval tanggal tersebut.

  **Diharapkan:** pemasukan 100, pengeluaran 25 bila hanya transaksi tersebut; pokok transfer tidak masuk. Beli/jual investasi tidak menjadi konsumsi/pemasukan bruto. Periode panjang menjumlahkan arus kas per interval.

  Status: SEBAGIAN
  Hasil aktual: …
  Bug/bukti: …

- [x] **T83 — Chart aset noninvestasi dan saldo negatif**

  1. Buka Akun > Grafik aset noninvestasi. Gunakan dua akun positif dan satu akun minus dari jenis Bank yang sama.
  2. Cocokkan line chart, angka bersih, donut dan daftar pengurang.

  **Diharapkan:** garis termasuk minus; donut hanya rekening positif. Saldo minus ditampilkan terpisah dan mengurangi nilai bersih, tidak dibalik menjadi aset positif atau disembunyikan dalam grup Bank. Kas RDN/exchange termasuk saldo akun; kartu debit tidak dihitung dua kali.

  Status: LULUS
  Hasil aktual: …
  Bug/bukti: …

- [ ] **T84 — Gabungan seluruh aset tanpa hitung ganda**

  1. Buat bank saldo 1.000. Transfer 200 ke RDN, lalu beli unit senilai 200 tanpa biaya; beri harga manual sehingga nilai unit tepat 200.
  2. Pilih Gabungan aset dan bandingkan komposisi Bank/Saldo exchange/Saham atau Crypto.

  **Diharapkan:** nilai bersih tetap 1.000 (kas 800 + investasi 200), bukan 1.200. RDN yang sudah dibelanjakan tidak dihitung lagi. Ketika harga naik, nilai gabungan ikut naik; tidak ada pemasukan palsu.

  Status: SEBAGIAN
  Hasil aktual: …
  Bug/bukti: …

- [ ] **T85 — Harga/kurs historis hilang dan impor susulan**

  1. Gunakan kepemilikan bertanggal sebelum observasi harga pertama dan akun asing sebelum kurs pertama.
  2. Periksa celah chart. Tambahkan harga/kurs bertanggal historis, lalu buka chart lagi.

  **Diharapkan:** titik yang tidak dapat dinilai lengkap diberi penanda/celah, bukan nol palsu. Harga masa depan tidak dipakai mundur. Harga terakhir yang diketahui dibawa sampai observasi berikutnya. Impor susulan mengisi riwayat yang sesuai tanpa mengubah unit/kas.

  Status: BELUM
  Hasil aktual: …
  Bug/bukti: …

- [ ] **T86 — Privasi, tema dan interaksi chart**

  1. Uji semua jenis analisis pada gelap/terang, font besar dan landscape.
  2. Tekan mata, pindah periode/scope, buka ulang dan tampilkan nominal kembali. Ketuk donut dan geser garis.

  **Diharapkan:** ketika tersembunyi, angka, garis, donut dan tooltip sensitif tidak tampil. Label sumbu/tanggal terbaca dengan font Lato, bukan kotak. Tombol dan legenda tidak overflow; info panjang tersedia melalui Tentang perhitungan.

  Status: SEBAGIAN
  Hasil aktual: …
  Bug/bukti: …

- [x] **T87 — Sepuluh crypto default dan update idempotent**

  1. Cari BTC, ETH, SOL, HYPE, USDT, USDC, XAUT, PAXG, BNB dan XRP di katalog tanpa internet.
  2. Periksa ID provider (BNB=binancecoin, XRP=ripple). Koreksi nama salah satu instrumen, buka ulang beberapa kali.

  **Diharapkan:** semua tersedia tanpa harus search online; tidak memiliki unit/uang otomatis. Tidak muncul duplikat saat restart/update; koreksi, arsip dan riwayat lama dipertahankan.

  Status: LULUS
  Hasil aktual: …
  Bug/bukti: …

- [ ] **T88 — Buat posisi dan stake manual**

  1. Isi unit awal 1 SOL dengan modal historis 1.000.000 pada lokasi QA Stake. Tambah posisi staking, jaringan/validator dan APR referensi opsional.
  2. Catat Stake unit 0,6. Coba jual atau stake tambahan 0,5 pada hari berikutnya.

  **Diharapkan:** total 1 SOL, aktif staking 0,6, bebas 0,4, modal tetap. Membuat posisi tidak mendebit kas. Percobaan 0,5 ditolak karena melebihi unit bebas; tidak membuat perubahan sebagian.

  Status: SEBAGIAN
  Hasil aktual: …
  Bug/bukti: …

- [ ] **T89 — Proses unstake dan cair aktual**

  1. Lanjut T88: Ajukan unstake 0,2, isi perkiraan cair. Periksa aktif 0,4/pending 0,2/bebas 0,4.
  2. Catat Unstake cair 0,2 dengan Ambil dari unit menunggu unstake aktif. Coba juga produk langsung dengan toggle nonaktif pada sebagian unit aktif.

  **Diharapkan:** setelah pencairan pending, bebas 0,6, aktif 0,4, pending 0, total tetap 1. Perkiraan tanggal lewat tidak otomatis mencairkan. Bucket salah/unit berlebih ditolak.

  Status: SEBAGIAN
  Hasil aktual: …
  Bug/bukti: …

- [ ] **T90 — Reward aktual, restake dan APR**

  1. Catat reward aktual 0,01 SOL sebagai unit bebas, lalu reward lain 0,02 dengan restake aktif pada tanggal berurutan.
  2. Isi APR referensi dan buka ulang; jangan mencatat reward tambahan.

  **Diharapkan:** total bertambah 0,03; hanya reward kedua menambah unit terkunci. Modal historis total tidak bertambah, kas tidak berubah. APR hanya estimasi, tidak membuat reward otomatis atau pendapatan kas fiktif.

  Status: SEBAGIAN
  Hasil aktual: …
  Bug/bukti: …

- [ ] **T91 — Slashing/biaya unit dan biaya tunai**

  1. Pada posisi uji terpisah awal 10 unit/modal 1.000, stake 6 lalu catat kehilangan 1 unit aktif.
  2. Periksa modal proporsional dan kas. Catat biaya tunai 5 pada aktivitas uji lain, jangan menduplikasi biaya token yang sama.

  **Diharapkan:** setelah kehilangan, total 9, aktif 5, bebas 4, modal 900; tidak ada hasil jual atau kas −100 palsu. Biaya tunai saja mengurangi saldo 5 dalam mata uang akun dan menjadi biaya laporan.

  Status: SEBAGIAN
  Hasil aktual: …
  Bug/bukti: …

- [ ] **T92 — Edit/hapus, arsip dan backup staking**

  1. Coba hapus stake awal yang sudah memiliki riwayat unstake/cair. Coba ganti crypto/lokasi posisi yang memiliki riwayat.
  2. Arsipkan, ekspor backup v5, restore, lalu refresh/buka ulang. Ekspor CSV transaksi/kepemilikan/harga.

  **Diharapkan:** perubahan historis yang membuat status tidak valid ditolak atomik. Arsip tidak menghapus posisi/riwayat. Backup memulihkan reward, locked/pending, modal, APR dan kurs historis; CSV memiliki identitas/status staking serta unit bebas/terkunci.

  Status: SEBAGIAN
  Hasil aktual: …
  Bug/bukti: …

- [ ] **T93 — Penutupan otomatis saham yang dimiliki**

  1. Aktifkan Simpan penutupan harian otomatis, online dan buka aplikasi dengan kepemilikan saham. Periksa sebelum dan sesudah jendela 18:00 WIB pada hari bursa; tidak perlu mengubah jam HP untuk memaksakan tes.
  2. Pindah halaman, buka ulang, background dan kunci aplikasi. Catat sublangkah yang belum sempat diamati.

  **Diharapkan:** harga sesi yang selesai disimpan dengan tanggal sebenarnya, termasuk sesi terdahulu pada akhir pekan/libur. Target yang sudah diperiksa tidak diminta berulang pada hari sama. Tidak ada request baru ketika background/terkunci; bukan mengambil seluruh 944 saham.

  Status: BELUM
  Hasil aktual/tanggal sesi dan waktu pengamatan: …
  Bug/bukti: …

- [ ] **T94 — Crypto penutupan UTC terpisah dari harga terbaru**

  1. Miliki crypto, masukkan key Demo privat, perbarui penutupan. Periksa tanggal periode dan as_of 00:00 UTC hari berikutnya.
  2. Tekan Harga terbaru (manual), periksa label/timestamp terpisah dan buka chart lagi.

  **Diharapkan:** referensi terakhir tersedia setelah sekitar 07:35 WIB, ekor data live tidak dianggap close. Harga terbaru manual tidak mengubah valuasi utama/chart penutupan. Tidak ada polling live otomatis; tutup/buka tidak menggandakan observasi harian.

  Status: SEBAGIAN
  Hasil aktual/tanggal periode/as_of: …
  Bug/bukti: …

- [ ] **T95 — Offline, jeda API dan pencatatan bersamaan**

  1. Saat harga otomatis mengambil data, buat transaksi biasa. Ulangi dengan mode pesawat lalu online; refresh beberapa kali tanpa menunggu lama.
  2. Jika provider memberi 429/error, catat pesan tanpa sengaja menghabiskan kuota. Periksa kas/unit dan cache setelah buka ulang.

  **Diharapkan:** input transaksi tetap dapat disimpan ketika jaringan lambat. Error tidak menimpa data/cache; tidak ada loop request rapat. Percobaan otomatis diberi jeda satu jam, manual minimal satu menit ditambah backoff provider. Perubahan transaksi tidak hilang saat hasil harga disimpan.

  Status: BELUM
  Hasil aktual: …
  Bug/bukti: …

- [ ] **T96 — Regresi backup lama dan ekspor live/close**

  1. Simpan backup lengkap terkini, lalu uji restore backup v4 data uji dan kembali ke v5. API key/PIN tetap lokal.
  2. Ekspor harga yang memiliki close dan live pada tanggal sama; impor ulang CSV hasil ekspor.

  **Diharapkan:** v4 dapat dibaca dengan default fitur baru kosong. Backup v5 mempertahankan semua riwayat. CSV mempertahankan kind close/live, tidak mengubah snapshot terbaru menjadi penutupan palsu. Jangan memulihkan backup baru dengan aplikasi lama.

  Status: SEBAGIAN
  Hasil aktual: …
  Bug/bukti: …

- [ ] **T97 — Referensi saham/crypto tersedia offline**

  1. Aktifkan mode pesawat, buka detail BBCA, BTC dan XRP tanpa memasukkan harga manual. Bandingkan beberapa tanggal/harga dengan file sumber pengguna.
  2. Gulir daftar sampai tombol 60 berikutnya, lalu muat halaman lanjutan. Buka kembali setelah restart.

  **Diharapkan:** grafik dan tanggal tersedia offline tanpa saldo/unit otomatis. Harga crypto IDR mengikuti kolom konversi IDR sumber. Daftar panjang ditampilkan bertahap dan tidak membuat aplikasi tidak merespons.

  Status: SEBAGIAN
  Hasil aktual/tanggal yang dibandingkan: …
  Bug/bukti: …

- [ ] **T98 — Saham tanpa data dan prioritas harga tambahan**

  1. Buka WSKT/TECH yang termasuk 26 saham tanpa riwayat; buat posisi uji jika perlu. Jangan memasukkan harga dahulu.
  2. Masukkan harga manual bertanggal sama dengan salah satu referensi BBCA dan bandingkan nilai utama/chart portofolio. Ekspor harga lalu impor ulang.

  **Diharapkan:** saham tanpa data diberi status belum ada harga, bukan nol. Harga tambahan diprioritaskan pada tanggal sama; CSV hanya mencakup harga tambahan, bukan seluruh referensi bawaan.

  Status: BELUM
  Hasil aktual: …
  Bug/bukti: …

- [ ] **T99 — Basis split dan unit aktual**

  1. Pada data uji terpisah, isi 10 lembar BBCA pada 1 November 2026. Masukkan tiga baris CSV close bernilai 50 untuk 1, 2 dan 3 November, semuanya dengan `adjusted_through=2026-11-19`, agar harga sintetis ini mengalahkan referensi bawaan pada ketiga tanggal tersebut.
  2. Catat split faktor 2 pada 2 November. Buka chart portofolio tanggal 1–3 November; hapus data uji setelah selesai.

  **Diharapkan:** harga 50 adalah basis sesudah split. Nilai investasi tanggal 1–3 November tetap 1.000 (10×100, lalu 20×50). Split tidak dimasukkan otomatis dari referensi. Uji ini bersifat sintetis, bukan pernyataan aksi korporasi BBCA aktual; gunakan backup terpisah.

  Status: BELUM
  Hasil aktual: …
  Bug/bukti: …

- [ ] **T100 — Backup tetap kecil dan referensi dimuat ulang**

  1. Buat beberapa posisi saham/crypto lalu ekspor backup sebelum dan sesudah membuka banyak halaman riwayat bawaan.
  2. Pulihkan backup pada versi ini, tetap offline, lalu buka grafik kembali.

  **Diharapkan:** membuka referensi tidak menyalin jutaan harga ke backup. Transaksi/harga tambahan tetap dipulihkan; referensi tersedia lagi dari aset aplikasi. API key tidak ikut backup.

  Status: SEBAGIAN
  Hasil aktual/ukuran backup: …
  Bug/bukti: …

## O. Fitur 0.6.0 — desain dan pembanding IHSG

- [ ] **T101 — Desain, ikon, ilustrasi dan tema**

  1. Buka Ringkasan, Akun, Transaksi, Portofolio, Pengaturan, form transaksi dan katalog dalam tema gelap/terang.
  2. Periksa keadaan kosong, pencarian tanpa hasil dan lampiran kosong. Uji font sistem besar serta landscape.

  **Diharapkan:** ikon garis konsisten; ilustrasi keuangan tanpa kucing; angka dan label tetap terbaca, tombol mudah disentuh, tidak ada overflow atau fitur lama yang hilang. Tombol mata tetap memakai titik untuk nominal.

  Status: SEBAGIAN
  Hasil aktual: …
  Bug/bukti: …

- [ ] **T102 — IHSG offline dan pembaruan close**

  1. Saat offline buka Saham vs IHSG dengan kepemilikan saham uji yang memiliki harga lengkap. Periksa tanggal efektif dan dua garis.
  2. Online lalu tekan Perbarui IHSG. Buka ulang aplikasi, lalu ulangi offline.

  **Diharapkan:** referensi IHSG bawaan tersedia tanpa API key; simbol `^JKSE`, data harian. Tambahan disimpan per tanggal tanpa duplikat. Harga sesi berjalan belum selesai tidak masuk. Error/429 tidak menghapus cache; pembaruan otomatis mengikuti pengaturan serta hanya berjalan foreground/tidak terkunci.

  Status: SEBAGIAN
  Hasil aktual/tanggal terakhir IHSG: …
  Bug/bukti: …

- [ ] **T103 — Setoran tidak menjadi keuntungan**

  1. Pada data uji terpisah yang hanya memiliki satu saham, tambah manual saham sintetis IPOX. Isi harga 100 untuk 2 dan 3 November 2026; unit awal 1 lembar pada 2 November.
  2. Pada 3 November tambahkan unit awal 9 lembar atau beli 9 lembar gross 900 tanpa fee. Buka pembanding periode yang memuat kedua sesi.

  **Diharapkan:** nilai unit menjadi 1.000, tetapi return portofolio tetap 0%; setoran bukan +900%. IHSG bergerak sesuai data sumbernya. Tidak ada return sebelum baseline penutupan pertama.

  Status: SEBAGIAN
  Hasil aktual: …
  Bug/bukti: …

- [x] **T104 — Jual penuh, biaya dan return terealisasi**

  1. Pada data uji sintetis terpisah, mulai 1 lembar pada harga 100 tanggal 2 November. Jual penuh tanggal 3 November gross 120 dan fee 1; isi close sesi sesuai kebutuhan.
  2. Buka pembanding, lalu periksa saldo dan unit normal pada Portofolio/Akun.

  **Diharapkan:** return sesudah jual 19%, bukan −100% atau 0%; unit menjadi nol dan kas mengikuti hasil jual neto. Grafik tetap menunjukkan return yang sudah terbentuk. Pengujian ini tidak menyatakan harga saham nyata.

  Status: LULUS
  Hasil aktual: …
  Bug/bukti: …

- [ ] **T105 — Dividen dan kesetaraan pembanding**

  1. Data uji satu lembar: harga 100 pada 2 November, 90 pada 3 November; catat dividen gross 10 tanpa fee pada 3 November.
  2. Bandingkan toggle Sertakan dividen neto nonaktif dan aktif.

  **Diharapkan:** mode harga −10%; mode dengan distribusi dividen 0%. Label mode berubah jelas; IHSG tetap indeks harga. Tidak mengubah saldo atau menggandakan transaksi dividen.

  Status: BELUM
  Hasil aktual: …
  Bug/bukti: …

- [ ] **T106 — Split, transfer, periode dan celah harga**

  1. Uji 1×100 menjadi 2×50 melalui split; pindahkan sebagian unit ke lokasi kedua tanpa biaya.
  2. Tambah posisi saham lain tanpa harga di tengah periode, lalu harga pertama pada tanggal sesudahnya. Ganti periode dan ketuk/geser grafik.

  **Diharapkan:** split/transfer tidak menciptakan return atau modal baru. Harga masa depan tidak mengisi tanggal sebelumnya. Rantai return yang kehilangan valuasi tidak disambung fiktif; periode baru dapat mulai pada close bersama yang lengkap. Selisih return memakai poin persentase; tombol mata menyembunyikan return, selisih dan garis.

  Status: SEBAGIAN
  Hasil aktual: …
  Bug/bukti: …

- [ ] **T107 — Pencarian saham baru / IPO khusus IDX**

  1. Katalog > Cari saham online, cari nama/kode IDX lalu pilih hasil yang belum ada. Ulangi pada kode yang sudah ada.
  2. Cari saham luar negeri/indeks; ulangi ketika offline. Coba jalur impor IDX dan tambah manual sebagai cadangan.

  **Diharapkan:** hasil online hanya saham empat huruf `.JK`, tidak menyertakan indeks, saham luar negeri atau reksa dana. Mapping harga tersimpan, instrumen lama tidak ditimpa/duplikat. Yahoo yang belum mengenali IPO tidak menghalangi penambahan melalui katalog resmi atau manual. Pencarian crypto tetap berfungsi melalui CoinGecko.

  Status: SEBAGIAN
  Hasil aktual: …
  Bug/bukti: …

- [ ] **T108 — Update database, backup dan regresi**

  1. Setelah backup aman, update dari APK lama menggunakan identitas/tanda tangan yang sama; periksa akun, transaksi, jadwal, kartu, bunga dan staking.
  2. Ekspor/pulihkan backup v5; buka pembanding kembali saat offline. Ulangi kasus lama yang relevan.

  **Diharapkan:** migrasi SQLite v4→v5 tidak menghapus data. Backup finansial tidak membengkak karena referensi IHSG; referensi dibaca lagi dari aset/cache publik. API key/PIN tidak ikut backup. Tetap tanpa login/backend; data offline berfungsi.

  Status: SEBAGIAN
  Hasil aktual: …
  Bug/bukti: …

## Ringkasan hasil pengguna

Jumlah empat status harus **108**. Seluruh T01–T108 dapat diuji dengan APK 0.6.0. Status awal tetap BELUM sampai benar-benar dicoba di HP. Centang kasus yang sudah dicoba, termasuk GAGAL/TERHALANG. Jika hanya sebagian sublangkah dicoba, tulis rinci dan jangan memberi LULUS penuh. Kasus yang tidak punya file/sensor/koneksi dapat diberi TERHALANG beserta alasannya.

| Status | Jumlah |
| --- | ---: |
| LULUS | 0 |
| GAGAL | 0 |
| TERHALANG | 0 |
| BELUM | 108 |

- Tanggal/jam sesi terakhir dan nomor terakhir: …
- Kasus gagal beserta ID bug: …
- Kasus terhalang dan alasannya: …
- Crash/aplikasi tidak merespons: …
- Selisih saldo, unit/modal salah, data hilang, transaksi ganda: …
- Masalah penggunaan/desain yang paling mengganggu: …
- Nama/lokasi backup terakhir yang berhasil dipulihkan: …
- Subpemeriksaan yang belum dicoba: …

## Laporan bug

### BUG-001 — Penyimpanan lokal gagal saat membuka aplikasi

- Kasus terkait: T01.
- Perangkat: Samsung A05s, Android 15 (informasi pengguna).
- Versi yang dilaporkan: APK tahap 2, 0.2.0.
- Langkah: pasang APK, buka aplikasi, tekan Coba lagi.
- Diharapkan: database privat terbuka dan aplikasi masuk ke Ringkasan.
- Aktual: muncul `Penyimpanan lokal belum dapat dibuka`; retry menghasilkan pesan sama.
- Dampak: seluruh alur pencatatan belum dapat digunakan.
- Sumber bukti awal: laporan pengguna; bukti uji ulang USB dan screenshot ada pada laporan HP. Log awal 0.2.0 tidak menyimpan exception aslinya.
- Penyebab: belum dikonfirmasi. Pesan berasal dari tahap persiapan penyimpanan; izin storage umum tidak diperlukan untuk direktori privat Android.
- Penanganan: menyiapkan jalur cadangan ke direktori privat Android yang sama, logging tahap startup, dan rincian error yang dapat disalin. Uji ulang 0.2.1 pada HP ini berhasil; pembaruan APK final juga menjaga 5 akun dan 1 transaksi QA. Akar masalah spesifik versi lama belum dapat disimpulkan.
- Status: tidak muncul pada dua pembukaan 0.2.1+3 di HP SM-A057F Android 15 melalui USB; startup berhasil. Belum ada bukti untuk menyimpulkan akar masalah spesifik versi lama. Emulator tidak digunakan untuk uji patch.


### BUG-002 — Versi pada Pengaturan tertinggal

- Aktual: footer menampilkan `Arta · 0.4.0`, sementara paket terpasang terverifikasi 0.6.0+8.
- Dampak: pengguna sulit memastikan versi APK dari dalam aplikasi.
- Sumber: teks tetap di `lib/screens/home_screen.dart:816`.
- Bukti: `settings-backup.xml` dan screenshot sesi.
- Prioritas: rendah. Belum diperbaiki dalam sesi pengujian.

### BUG-003 — Tombol simpan tertutup navigasi Samsung

- Buka form transaksi dalam posisi portrait, gunakan navigasi Android tiga tombol, sembunyikan keyboard, lalu gulir ke paling bawah.
- Aktual: tombol `Simpan transaksi` berada pada y=2220–2355, sedangkan bilah navigasi Samsung mulai sekitar y=2265. Sebagian tombol tertutup dan sulit ditekan.
- Dampak: alur pencatatan dasar terhambat. Pengujian dapat dilanjutkan dengan keyboard tetap terbuka dan tombol digulir ke atas keyboard.
- Bukti: `expense-save-position.png`, `save-keyboard-hidden.png`, `save-with-keyboard.png`.
- Prioritas: tinggi. Belum diperbaiki; perlu uji ulang inset bawah di HP fisik.

### BUG-004 — Restore mengaktifkan kembali pembaruan harga otomatis

- Matikan `Simpan penutupan harian otomatis`, simpan, lalu pulihkan backup finansial yang valid.
- Aktual: preferensi `market_daily_auto=false` hilang setelah restore dan switch kembali aktif. API key tetap tersimpan terpisah.
- Sumber: daftar preferensi yang dipertahankan pada restore di `lib/repositories/finance_repository.dart:614` masih menyebut `market_auto`, bukan `market_daily_auto`.
- Dampak: pembaruan otomatis dapat berjalan kembali meskipun sebelumnya dimatikan pengguna.
- Bukti: `restore-auto-preference-reset.png/.xml`, perbandingan database sebelum/sesudah.
- Prioritas: sedang. Switch dimatikan kembali untuk melanjutkan pengujian deterministik; kode belum diperbaiki.


Salin blok berikut untuk setiap bug. Biarkan sebagai template sampai ada temuan; jangan menganggapnya bug yang sudah ditemukan.

### BUG-XXX — Judul singkat

- Kasus terkait: T…
- Dampak: Saldo/data salah atau hilang / fitur tidak dapat digunakan / masalah tampilan / lainnya: …
- Perangkat dan versi Android: …
- Kondisi awal (akun, saldo, tanggal, mode jadwal, status internet): …
- Langkah mengulang:
  1. …
  2. …
  3. …
- Hasil yang diharapkan: …
- Hasil aktual (sertakan angka/pesan persis): …
- Frekuensi: Selalu / kadang-kadang / baru sekali
- Tetap terjadi setelah aplikasi dibuka ulang: Ya / tidak / belum dicoba
- Bukti screenshot/video, misalnya `testing/bukti/BUG-002.png`: …
- Catatan tambahan: …

## Setelah selesai

1. Simpan perubahan file Markdown ini. Tidak perlu mengubah kode aplikasi atau mengirim kata sandi pribadi.
2. Jika tadi memakai data pribadi, pulihkan cadangan pribadi yang dibuat sebelum pengujian setelah hasil dan bukti uji aman tersimpan.
3. Kirim pesan **`review hasil testing`**. Codex akan membaca file ini dan bukti yang dirujuk, memisahkan bug dari kasus terhalang, lalu memprioritaskan perbaikan saldo/data, crash, fungsi, dan tampilan.

## Catatan review Codex

Bagian ini diisi Codex setelah membaca laporan pengguna.

- Versi yang akan direview: 0.6.0+8
- Tanggal review: 20 November 2026, pengujian USB langsung; hasil rinci pada TESTING-HP-2026-11-20.md
- Riwayat versi lama: lihat BUG-001 dan TESTING-HP-2026-11-19.md; bukan hasil HP 0.6.0
- Hasil yang sudah dapat dikonfirmasi: …
- Temuan prioritas dan kasus terkait: BUG-003 tombol simpan/nav bar; BUG-004 preferensi otomatis setelah restore; BUG-002 footer versi. Belum ada perbaikan kode dalam sesi ini.
- Informasi/bukti yang masih diperlukan: …
- Perbaikan yang dilakukan dan versi APK: tidak ada; APK tetap 0.6.0+8, tidak dibuild/dipasang ulang.
- Kasus yang perlu diuji ulang: …
