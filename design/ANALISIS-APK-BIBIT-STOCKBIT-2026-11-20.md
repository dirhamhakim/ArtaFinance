# Analisis UI/UX dari APK Bibit dan Stockbit

Status: analisis statis selesai, 20 November 2026. **Kode, tema, font, aset produksi, dan project FigCraft Arta belum diubah. Kedua aplikasi belum dibuka di HP dalam sesi ini.**

## Sumber dan cara pemeriksaan

| Aplikasi | Paket/versi pada APK | Sumber lokal |
| --- | --- | --- |
| Bibit | `com.bibit.bibitid` / 3.112.4 | [Manifest salinan](references-apk/bibit/extraction.json) |
| Stockbit | `com.stockbit.android` / 3.23.0 | [Manifest salinan](references-apk/stockbit/extraction.json) |

Enam APK dasar/split diperiksa sebagai arsip. Android SDK `aapt2` membaca resource terkompilasi; fontTools membaca metadata font. Checksum seluruh salinan tetap cocok. Layout, style, tema, selector, font, ikon dan contoh ilustrasi dianalisis; data akun, sesi login, jaringan aplikasi dan logika perdagangan tidak diambil.

Bukti terstruktur: [manifest analisis](apk-analysis-2026-11-20/analysis-manifest.json), [resource Bibit](apk-analysis-2026-11-20/bibit/resource-facts.json), [resource Stockbit](apk-analysis-2026-11-20/stockbit/resource-facts.json). Potongan XML yang sudah diterjemahkan dari ID resource berada dalam folder `resource-excerpts` masing-masing aplikasi. Dump lengkap sementara dan skrip pemeriksaan berada di `build/apk-ui-research-2026-11-20/`.

Keberadaan suatu resource membuktikan resource tersebut dikemas, **belum membuktikan komponen sedang dipakai pada layar yang terlihat saat ini**. Versi lama, SDK pihak ketiga, varian produk, tema, dan flag runtime bisa berada dalam satu APK.

## Font yang dapat diidentifikasi

Kedua APK memuat **Bit Sans Regular dan Bit Sans Bold**, dengan metadata PostScript `BitSans-Regular` dan `BitSans-Bold`, bobot 400/700. Bibit mereferensikannya dari tema aplikasi; Stockbit mereferensikannya dari keluarga font dan `TypeStyles`. Beberapa style Stockbit masih bernama `RobotoTextViewStyle`/`RobotoButtonStyle`, tetapi isinya menunjuk Bit Sans. Nama style tersebut bukan bukti penggunaan Roboto.

Temuan ini memperbarui pengetahuan tentang **aplikasi mobile**. Catatan Lato dari pemeriksaan web dan implementasi Arta sebelumnya tetap merupakan catatan web/Arta, bukan identifikasi font APK mobile. Stockbit juga memuat Noto Color Emoji dan OCR A Extended untuk kebutuhan khusus; keduanya bukan font utama UI.

Font dari APK hanya dipakai membuat contoh pembanding lokal; tidak dimasukkan ke `assets/` Arta. Metadata Bit Sans yang diperiksa tidak memuat keterangan izin distribusi. Pemilihan font produksi belum diubah.

### Skala teks Stockbit yang terkemas

| Style `TypeStyles` | Ukuran / tinggi baris | Bobot |
| --- | --- | --- |
| BodyLarge | 16sp / 22sp | Regular |
| BodyRegular | 14sp / 19sp | Regular |
| BodySmall | 13sp / 18sp | Regular |
| BodyXSmall | 12sp / 16sp | Regular |
| BodyXXSmall | 11sp / 15sp | Regular |
| HeadingLarge / Medium / Regular | 16/22, 15/20, 14/19sp | Bold |
| HeadlineLarge / Regular | 20/22, 18/20sp | Bold |
| Nominal / NominalLarge | 24sp / 32sp | Bold |
| NominalXLarge | 34sp / 46sp | Bold |
| ParagraphRegular | 14sp / 21sp | Regular |

Style lain yang ditemukan: `SbTextView.PageTitle` 18sp bold, `SbEditTextStyle` 14sp, caption 12sp, tombol 16sp, label navigasi bawah 10sp. Ini beberapa keluarga style yang hidup berdampingan, bukan satu ukuran untuk seluruh layar.

Bibit memiliki `Body1` dengan `_14ssp` dan `Body2` dengan `_11ssp`. Resource SSP berubah menurut lebar perangkat: `_14ssp` bernilai 14sp default, sekitar 16,8sp pada `sw360dp`, 18,2sp pada `sw390dp`. Karena itu ukuran bernama 14 tidak boleh langsung disamakan dengan 14 piksel screenshot atau ukuran tetap Flutter. Bagian WebView juga dapat memiliki tipografi sendiri.

## Warna terang dan gelap

Nilai berikut dibaca dari resource, bukan ditebak dari gambar. Tabel menggunakan RGB untuk warna opak.

| Peran / resource Stockbit | Terang | Gelap |
| --- | --- | --- |
| Aksen tema `green_text` | `#00AB6B` | `#00AB6B` |
| Permukaan utama | `#FFFFFF` | `#121212` |
| Permukaan varian | `#F7F7F7` | `#1F1F1F` |
| Border artboard | `#EDEDED` | `#2E2E2E` |
| Teks utama `TypeStyles` | `#333333` | `#CBCBCB` |
| Teks sekunder `TypeStyles` | `#858585` | `#858585` |
| Teks tersier `TypeStyles` | `#B5B5B5` | `#787878` |
| Teks hijau `TypeStyles` | `#00AB6B` | `#0BA16B` |
| Teks merah `TypeStyles` | `#EE4A49` | `#D74342` |

Style Stockbit lain memakai warna teks putih ber-alpha `#DEFFFFFF`/`#99FFFFFF`; ini format **AARRGGBB**, bukan RGB biasa. Campuran terhadap latar memengaruhi warna yang terlihat. Jangan mengambil satu token dan menganggapnya berlaku untuk semua komponen.

Bibit: `artBoardGreenDefault=#00AB6B`, latar gelap `grey7=#121212`, teks utama terang `#333333` dan gelap `#CBCBCB`. `artBoardGreenLow` adalah `#EBF8F3` terang / `#152E24` malam; border `#EDEDED` / `#292929`. `colorPrimary` Bibit justru `#414141`, sedangkan aksen menunjuk hijau: nama resource saja tidak cukup untuk menentukan perannya.

[Contoh font dan palet](apk-analysis-2026-11-20/font-palette-specimen.png) adalah lembar spesimen, **bukan screenshot aplikasi atau desain baru Arta**. Ukuran sampel pada gambar bersifat ilustratif; angka style pasti ada pada tabel/JSON.

## Catatan per komponen

| Bagian | Bukti dari APK | Implikasi untuk referensi Arta berikutnya |
| --- | --- | --- |
| Pencarian Stockbit | `comp_search_bar_rounded`: tinggi 40dp, ikon 24dp, ikon hapus 16dp, margin 10dp/atas 6dp, padding input 10dp/16dp; style input 14sp. Shape outline terkait radius 8dp dan garis 1dp. Ada indikator loading dan tombol clear. | Bedakan pencarian kosong, mengetik, loading, hasil kosong, dan gagal. Ukuran ikon visual dipisahkan dari area sentuh. |
| Field/input | `SbEditTextStyle` memakai teks/hint semantik; `bg_rounded_edit_text` radius 8dp, garis 1dp; selector fokus terpisah. | Label, hint, nilai, fokus, invalid dan disabled perlu aturan konsisten. |
| Radio/pilihan | `comp_field_radio` memuat label, penanda wajib, dan grid dua kolom. | Perlu pemeriksaan runtime terhadap bentuk item, selected state dan panjang label; grid dua kolom bukan kewajiban untuk semua form. |
| Pilihan Bibit | `ic_checkbox` berupa lingkaran 18×18dp, stroke 1,5; ada selected asset dan selector. | Nama checkbox tidak selalu berarti bentuk kotak. Bentuk visual dan perilaku single/multi-select harus diperiksa terpisah. |
| Chip/filter | Ada selector warna background, stroke dan teks untuk selected/pressed; `ChipsGroup` memiliki jarak item/baris 8dp. | Jangan hanya mengganti warna teks saat aktif; periksa outline/background dan status tekan. |
| Tombol | Ada keluarga tombol berbeda. Bibit `BaseOutlinedButton` radius 4dp; resource Stockbit lama `ButtonSecondary` radius 5dp/teks 12sp, sementara keluarga teks tombol lain 16sp. | Hindari menyalin style lama sebagai ukuran universal. Tentukan tombol utama/sekunder/link berdasarkan layar runtime. |
| Bottom sheet | Bibit shape atas 16dp, bawah 0; Stockbit `bg_top_rounded_20` radius atas 20dp. Stockbit memiliki footer CTA tunggal/vertikal/horizontal. | Sheet punya sudut atas dan footer yang jelas; keyboard dan navigasi Android perlu ruang bawah, terutama setelah BUG-003 Arta. |
| Daftar portofolio | Baris ConstraintLayout/RelativeLayout dengan kode, notasi, angka, action; header metrik menggunakan padding horizontal 20dp dan jarak 12dp. Ada empty/error/shimmer terpisah. | Hierarki kode/nama/angka dan kolom konsisten lebih penting daripada membungkus tiap informasi dalam kartu besar. Ukuran layar akhir perlu runtime. |
| Saldo tersembunyi | `comp_hidden_value_portfolio` menggambar beberapa dot berukuran 6dp, jarak 8dp. | Mendukung arah desain titik untuk privasi; angka/chart tersembunyi harus konsisten di seluruh Arta. |
| Pagination | `comp_paging_load_more`: footer 48dp dengan loading dan retry; ada varian watchlist/history. | Ada dukungan muat lanjutan dan gagal ulang. Belum membuktikan trigger scroll otomatis atau ukuran batch data. |
| Navigasi | XML menu memuat Watchlist, Stream, Search, Canvas, Chat, Portfolio beserta ikon. | Resource memuat enam item; jumlah yang tampil di HP bisa diubah runtime. Jangan menyimpulkan keenamnya selalu terlihat atau menyalinnya ke empat menu Arta. |
| Grafik | Ada layout periode, marker, empty/loading/error, alokasi dan performa; animasi live chart hijau/merah juga dikemas. | Interaksi tooltip, gesture, legend, pergantian periode dan keadaan data kurang masih perlu observasi layar berjalan. |

## Ikon, ilustrasi, animasi, dan teknologi UI

Stockbit memuat Android VectorDrawable, PNG/WebP, JSON animasi yang bernama Lottie, dan **13 file Rive**. Bibit juga memiliki VectorDrawable serta PNG/WebP. Asset `abc_*`/`mtrl_*` menunjukkan komponen library, sedangkan nama khusus aplikasi menunjukkan asset yang dikemas untuk fitur aplikasi. Pembuat asli atau lisensi setiap ikon tidak dapat disimpulkan dari nama file; tidak ada dasar menyatakan semuanya dibuat sendiri atau seluruhnya memakai satu paket ikon.

Empat ilustrasi Stockbit dari split density sudah dilihat: grafik batang garis hijau dan donut dengan pola titik, masing-masing versi terang/gelap, sumber 480×360 piksel. [Lembar contoh ilustrasi terkemas](apk-analysis-2026-11-20/packaged-empty-state-examples.png). Ini memberi referensi yang sesuai keuangan tanpa kucing. Salinannya hanya untuk analisis; aset tersebut tidak dipasang ke aplikasi Arta.

Paket yang diperiksa memiliki layout Android native. Pada Bibit, `fragment_bibit_ui` memakai `BibitNativeWebView`; sebagian UI dimuat melalui lapisan web. Paket tidak memuat payload `flutter_assets` atau library Flutter pada split yang diperiksa. Temuan ini tidak mewajibkan Arta berpindah dari Flutter: bentuk ikon, warna, font dan layout bisa dibuat dengan Flutter. Resource native yang ditemukan tidak otomatis mewakili seluruh halaman WebView.

## Remote HP dibanding screenshot

| Cara | Yang paling berguna | Batas |
| --- | --- | --- |
| APK statis | Nama font, bobot, nilai resource warna, dp/sp, selector, shape, asset lokal | Tidak menunjukkan layar aktif, urutan UX, data dinamis, atau halaman yang diunduh saat runtime |
| Screenshot asli | Tampilan final: komposisi, warna hasil render, bentuk, jarak, hierarki | Tidak memastikan font hanya dari kemiripan; tidak menunjukkan alur/interaksi |
| Remote HP | Membuka menu/sheet, mengetik, scroll, tab/periode, state loading/error/keyboard; dapat menangkap screenshot per langkah | Mutu piksel tidak otomatis lebih tinggi daripada screenshot asli dari HP yang sama. UI tree tidak selalu menyediakan font/semua detail internal |

Pendekatan paling lengkap adalah **APK + observasi runtime + screenshot asli**. Untuk ukuran, catat resolusi, density Android dan skala font. Font paling pasti dari resource yang benar-benar direferensikan; remote diperlukan untuk memastikan komponen/style mana yang aktif, terutama Bibit WebView.

Stockbit memuat `activity_adb_block` dan pesan bahwa aplikasi tidak dapat diakses saat USB/wireless debugging aktif. Ini membuktikan dukungan kondisi pembatasan di APK, **belum membuktikan aturan sedang aktif pada HP pengguna**. Jika muncul, hentikan remote ADB untuk Stockbit dan gunakan screenshot/rekaman manual yang diizinkan atau observasi yang dijelaskan pengguna. Tidak mengubah APK atau melewati pembatasan. Mematikan USB debugging berbeda dari mematikan hotspot; koneksi data/hotspot pengguna tetap harus dipertahankan.

## Daftar observasi runtime berikutnya

- [ ] Pastikan aplikasi mengizinkan akses dengan metode remote yang tersedia; pengguna menangani login/biometrik.
- [ ] Ringkasan/home, portofolio, detail aset, histori, pencarian dan filter, masing-masing terang/gelap bila tersedia.
- [ ] Ukur hierarki nominal, judul, isi, caption; cocokkan style APK dan bagian WebView.
- [ ] Periksa radio/checkbox, disabled/selected/focus/error, dropdown, bottom sheet dan keyboard.
- [ ] Periksa loading, skeleton, empty, error, retry, dan pagination.
- [ ] Periksa chart, legend, tooltip sentuh, pilihan rentang dan privasi nominal.
- [ ] Catat semua perbedaan dari analisis statis sebelum menyusun perubahan Arta.

Permintaan baru reset PIN memakai sidik jari dicatat terpisah pada [rencana reset PIN](../docs/RENCANA-RESET-PIN-SIDIK-JARI.md). Implementasi dan pengujian lanjut menunggu tahap coding berikutnya; sesi ini hanya mencatat hasil riset.
