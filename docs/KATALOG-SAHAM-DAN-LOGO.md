# Katalog saham Indonesia, simbol harga, dan logo

Rancangan awal 18 November 2026; diperbarui untuk kode **0.4.0**. Pencarian lokal, impor/ekspor XLSX/JSON, preview dan penyimpanan SQLite sudah diimplementasikan. Parser dicocokkan dengan Excel asli untuk 944 saham dan kelima kolom sumber. APK 0.4.0 belum dibuild. Cara pakai serta perbedaan implementasi dari rancangan ada di [panduan tahap 4](TAHAP-4-0.4.0.md). Jumlah lembar disimpan sebagai string digit di body JSON SQLite, tanpa konversi floating point.

## Sumber yang sudah diperiksa

Berkas `C:\Users\User\Downloads\Daftar Saham  - 20261118.xlsx`, sheet `Sheet1`, rentang `A1:F945`, berisi **944 baris dengan 944 kode unik**. Pengguna menyatakan mengunduhnya dari IDX pada 18 November 2026. Tanggal tersebut adalah tanggal unduh menurut pengguna; workbook tidak memberikan tanggal efektif keseluruhan katalog, sehingga `source_as_of` tetap `null`. Kelengkapan daftar dibanding seluruh emiten IDX pada tanggal itu belum diverifikasi.

| Kolom sumber | Penggunaan |
| --- | --- |
| No | Opsional, diabaikan; bukan ID instrumen dan tidak perlu disimpan |
| Kode | Kode lokal, misalnya `BBCA` |
| Nama Perusahaan | Nama untuk tampilan/pencarian, mengikuti teks sumber |
| Tanggal Pencatatan | Metadata `listing_date`, dinormalisasi menjadi `YYYY-MM-DD` |
| Saham | Disimpan sebagai `shares_count`: jumlah lembar saham sesuai sumber IDX, terpisah dari harga dan kepemilikan pengguna |
| Papan Pencatatan | Metadata `listing_board`; tidak dipakai untuk menyimpulkan status aktif/suspensi |

Hasil pemeriksaan:

- Tidak ada kode duplikat, kode/nama kosong, formula atau sel error. Semua kode terdiri dari empat huruf dan tetap disimpan sebagai teks, termasuk kode `TRUE`.
- Seluruh 944 baris masuk ke seed tanpa baris yang dibuang. Tanggal pencatatan pada sumber berkisar 10 Agustus 1977 sampai 10 Juli 2026; ini bukan tanggal pembaruan katalog.
- Papan: Utama 294, Pengembangan 547, Akselerasi 42, Pemantauan Khusus 60, Ekonomi Baru 1. Seluruh papan tetap disertakan dalam pencarian.
- Panjang nama maksimum yang ditemukan 30 karakter; 190 nama mencapai batas ini. Beberapa jelas terpotong, misalnya BBRI (`Bank Rakyat Indonesia (Persero`, sel `C331`) dan MGLV (`NexAI Digital Infrastruktur Tb`, sel `C2`). Tidak semua nama sepanjang 30 karakter terpotong. Nama tidak dilengkapi dengan tebakan; aplikasi nanti perlu mendukung koreksi nama tanpa mengubah ID instrumen/riwayat transaksi.
- Pembentukan simbol `.JK` bersifat mapping awal. Harga Yahoo dan logo Stockbit belum diuji untuk seluruh kode.

Hasil konversi: [seed JSON](../assets/data/idx_stocks.json) dan [laporan validasi](data/idx-catalog-validation.json). SHA-256 workbook dicatat di keduanya; workbook asli tidak diubah. JSON diurutkan berdasarkan kode dan menyimpan nomor baris sumber untuk penelusuran.

Seed berisi metadata katalog dan array `stocks`. Metadata menyimpan versi skema, versi katalog, jumlah baris, tanggal unduh, hash sumber, status verifikasi mapping Yahoo dan template URL logo. Setiap saham menyimpan kode, nama, bursa, tipe instrumen, simbol Yahoo, tanggal pencatatan, jumlah lembar saham (`shares_count`), papan pencatatan dan baris sumber. Seluruh lima kolom sumber selain `No` dipertahankan. `source_row` hanya penunjuk lokasi untuk pemeriksaan, bukan salinan nilai kolom `No`. ID relasional dibuat/disimpan saat impor ke database aplikasi, bukan dihitung ulang dari urutan baris seed. Metadata sumber dan tanggal unduh bukan data harga.

Keputusan pengguna: walaupun belum ditampilkan/digunakan oleh fitur, jumlah lembar saham tetap disimpan di database, ekspor katalog dan backup lengkap. Pemetaan lima kolom: `Kode` → `code`, `Nama Perusahaan` → `name`, `Tanggal Pencatatan` → `listing_date`, `Saham` → `shares_count`, `Papan Pencatatan` → `listing_board`. Skema database Flutter belum dibuat; pemetaan ini menjadi kontrak implementasi.

`shares_count` adalah bilangan bulat nonnegatif: misalnya teks Excel `2.087.100.500` dinormalisasi menjadi string JSON `"2087100500"`, lalu INTEGER 64-bit di SQLite. Jangan memakai pecahan/floating point atau mengartikannya sebagai lot. JSON memakai string digit agar presisi tetap utuh lintas alat. Nilai kosong/kolom yang tidak disertakan pada impor parsial bukan nol: pertahankan nilai lama, atau `null` pada instrumen baru. Nol eksplisit hanya disimpan jika memang berasal dari sumber. Angka yang tidak valid atau di luar kapasitas penyimpanan menolak impor, bukan dibulatkan.

Perubahan jumlah lembar dalam impor berikutnya hanya memperbarui metadata emiten. Jangan otomatis mengubah unit kepemilikan, harga/modal, atau menghasilkan transaksi/corporate action. Jumlah ini mengikuti file sumber beserta tanggal/provenansinya dan tidak diasumsikan sebagai angka historis pada tanggal transaksi pengguna.

Konversi lokal dapat diulang menggunakan [skrip standar Python](../scripts/prepare-idx-catalog.py), tanpa paket tambahan. Contoh dari root proyek, menggunakan runtime Python yang tersedia pada komputer ini:

```powershell
& 'C:\Program Files\PostgreSQL\18\pgAdmin 4\python\python.exe' `
  'scripts\prepare-idx-catalog.py' `
  'C:\Users\User\Downloads\Daftar Saham  - 20261118.xlsx' `
  --downloaded-on 2026-11-18
```

Untuk unduhan baru, ubah path dan tanggal unduh yang sebenarnya. Perubahan header, kode duplikat/tidak valid, data wajib kosong, atau format tanggal yang tidak dikenal menghentikan konversi agar diperiksa. Skrip ini hanya menyiapkan berkas seed dan laporan; belum mengimpor database pengguna. Saat integrasi nanti, impor katalog harus memperbarui metadata tanpa mereset saldo/transaksi atau menghapus emiten yang absen pada unduhan berikutnya.

## Pemisahan tugas

| Data/aksi | Sumber dan penyimpanan |
| --- | --- |
| Cari kode/nama perusahaan | Katalog lokal SQLite, tersedia tanpa internet |
| Identitas investasi | ID instrumen internal stabil, bukan URL/simbol penyedia |
| Simbol harga | Mapping provider, misalnya `BBCA.JK` untuk Yahoo |
| Nilai harga | Cache harga bertanggal, terpisah dari metadata perusahaan |
| Logo | URL Stockbit berdasarkan kode lokal, lalu cache gambar di HP |

Yahoo memang mempunyai simbol [BBCA.JK](https://finance.yahoo.com/quote/BBCA.JK/) untuk PT Bank Central Asia Tbk. Akhiran `.JK` adalah bagian simbol Yahoo; kode yang ditampilkan dan dicari pengguna tetap `BBCA`. Metadata daftar perusahaan dapat dibandingkan dengan [profil perusahaan tercatat BEI](https://www.idx.id/id/perusahaan-tercatat/profil-perusahaan-tercatat/).

Katalog lokal bukan syarat teknis mutlak untuk menampilkan pencarian daring. Namun, ini pilihan yang sesuai kebutuhan offline: pencarian tidak membutuhkan koneksi/kuota Yahoo dan hasil dapat dibatasi pada instrumen saham Indonesia di katalog. Parameter bahasa/wilayah pada pencarian daring tidak dipakai sebagai jaminan bahwa seluruh hasil berasal dari BEI.

## Isi katalog

Kolom sumber minimum cukup `kode` dan `nama_perusahaan`, dalam CSV, Excel atau JSON. Tanggal data dan asal daftar berguna bila tersedia. Tidak perlu mengisi URL logo satu per satu.

Field aplikasi yang diusulkan:

- `id`: ID stabil untuk relasi transaksi/kepemilikan.
- `code`: kode BEI huruf besar, misalnya `BBCA`.
- `name`: nama perusahaan.
- `listing_date`: tanggal pencatatan sumber IDX.
- `shares_count`: jumlah lembar pada kolom `Saham` IDX, bilangan bulat eksak; disimpan walau belum digunakan UI.
- `listing_board`: papan pencatatan sumber IDX.
- `exchange`: enum aplikasi `IDX`.
- `instrument_type`: `stock`; bukan crypto, indeks, waran atau reksa dana.
- `yahoo_symbol`: misalnya `BBCA.JK`; simpan mapping eksplisit agar dapat dikoreksi.
- `aliases`: nama pencarian tambahan opsional, misalnya `BCA`.
- `status`, versi katalog, tanggal dan asal data; status yang tidak diketahui jangan ditebak dari daftar kode/nama saja.
- `logo_url_override` opsional bila pola default berubah untuk suatu emiten.

Seed JSON disertakan dalam aset aplikasi dan dimasukkan ke SQLite saat inisialisasi. Validasi duplikasi kode, nama kosong dan tipe instrumen sebelum impor. Pencarian memprioritaskan kode persis, awalan kode, lalu kecocokan nama/alias. Filter katalog membatasi picker saham ke `exchange=IDX` dan `instrument_type=stock`.

Perubahan daftar dilakukan melalui versi seed pada update aplikasi atau impor katalog pengguna. Tidak perlu mengambil ulang semua metadata saat aplikasi dibuka. Emiten baru memerlukan pembaruan katalog; tambahkan fallback input/koreksi manual bila belum tercantum. Emiten yang berganti nama/kode atau delisting tidak langsung dihapus dari riwayat kepemilikan. Katalog dan saldo/transaksi merupakan data terpisah.

## Impor katalog langsung dari Android

Keputusan produk: pengguna dapat memperbarui katalog tanpa rilis aplikasi baru dan tanpa menjalankan skrip Python. Istilah pada aplikasi adalah **Impor daftar saham**, karena file dibaca dan diproses di perangkat; tidak diunggah ke server. Seed bawaan tetap menyediakan katalog pada instalasi pertama.

Alur rancangan tersedia pada halaman **08 · Katalog Saham IDX** dalam [proyek FigCraft v3](../design/README.md), dengan 29 state per tema. Prototype tetap simulasi. Implementasi Flutter pemilih file, pencarian, koreksi nama/mapping/logo serta impor/ekspor sudah tersedia pada kode 0.4.0; kolom baru dipertahankan sebagai metadata dan diberi peringatan pada preview.

Lokasi menu yang direncanakan: **Lainnya > Pengaturan > Katalog saham Indonesia**. Halaman menampilkan jumlah saham, nama file sumber, waktu impor terakhir dan tanggal data bila diketahui. Tanggal unduh/impor tidak boleh diberi label tanggal efektif IDX. Sediakan pencarian katalog, koreksi metadata, tambah saham manual dan tombol **Impor daftar saham**.

Format versi awal:

| Format | Kegunaan dan kontrak |
| --- | --- |
| Excel IDX `.xlsx` | Pilihan utama: pilih hasil unduhan IDX langsung di HP. Petakan kolom berdasarkan judul, bukan posisi tetap. Simpan seluruh lima kolom selain `No`, termasuk `Saham` meski belum digunakan UI. Impor parsial minimal memerlukan `Kode`/`Nama Perusahaan`; kolom metadata yang tidak disertakan tidak menghapus data lama. Kolom `No` opsional dan diabaikan. Bila ada beberapa sheet yang cocok, pengguna memilih sheet pada pratinjau. Perubahan judul/kolom baru yang tidak dikenali meminta peninjauan pemetaan agar data tidak dibuang diam-diam. |
| JSON katalog aplikasi `.json` | Mendukung struktur seed saat ini: `schema_version: 1` dan array `stocks` berisi minimal `code`/`name`; metadata mencakup `listing_date`, `shares_count` (string digit), dan `listing_board`. Ekspor katalog menyertakan kelima field dalam format yang dapat diimpor kembali. Versi yang belum didukung ditolak dengan pesan yang jelas. JSON backup seluruh keuangan mempunyai kontrak terpisah dan tidak diproses sebagai katalog. |

Pembaca XLSX/JSON harus berjalan di Flutter/perangkat, bukan memanggil skrip persiapan seed pada komputer. Dukungan `.xls` lama atau format sembarang tidak dijanjikan. Parser XLSX tidak mengeksekusi formula/makro; sel wajib yang berupa formula/error ditolak. Kode seperti `TRUE` harus dipertahankan sebagai teks. Impor tidak memerlukan internet; pengambilan harga/logo tetap proses terpisah.

Alur penggunaan:

1. Unduh daftar baru dari IDX, lalu pilih **Impor daftar saham** dan pilih file melalui pemilih dokumen Android.
2. Aplikasi membaca file ke area sementara, memvalidasi format, lalu memperlihatkan sheet/kolom yang dipakai, jumlah baris dan tanggal sumber jika tersedia. Pengguna boleh mengisi tanggal unduh sebagai informasi terpisah.
3. Tampilkan ringkasan **baru**, **berubah**, **tetap**, **tidak ditemukan pada file ini** dan **bermasalah**, disertai daftar perubahan yang dapat dibuka. Jangan menyimpulkan kelengkapan pasar dari sebuah file.
4. Jika ada kode/nama wajib kosong, kode tidak valid, duplikasi kode setelah normalisasi, atau nilai wajib berupa formula/error, tampilkan nomor baris dan alasannya. Versi awal membatalkan seluruh impor sampai masalah diperbaiki; tidak membuang baris secara diam-diam. Nama yang tampak terpotong menjadi peringatan, bukan otomatis dilengkapi.
5. Setelah pengguna meninjau dan menekan **Terapkan pembaruan**, simpan seluruh perubahan katalog dalam satu transaksi database. Kegagalan sebelum selesai mengembalikan katalog ke keadaan sebelumnya.
6. Tampilkan hasil dan waktu impor. Pencarian langsung menggunakan katalog yang diperbarui. Impor ulang file yang sama tidak membuat saham atau perubahan metadata ganda.

Aturan penggabungan:

| Kondisi | Perlakuan |
| --- | --- |
| Kode baru | Tambahkan instrumen IDX bertipe saham, buat ID internal sekali dan mapping awal `KODE.JK`. Tidak membuat pembelian, saldo awal atau harga nol. |
| Kode sudah ada | Cocokkan berdasarkan bursa + tipe instrumen + kode yang dinormalisasi. Perbarui metadata sumber yang disediakan; pertahankan ID internal, transaksi, kepemilikan, modal dan cache harga. Field opsional yang tidak disediakan tidak menghapus nilai lama. |
| Nama/simbol/alias/logo dikoreksi manual | Simpan override pengguna terpisah dari nilai sumber. Pembaruan sumber tidak menimpa koreksi itu; pengguna dapat memilih memakai nilai sumber kembali. Khusus nama yang tampak terpotong, tampilkan peringatan pada pratinjau perubahan. |
| Kode lama tidak ada dalam file baru | Tetap simpan instrumen dan riwayat. Informasikan sebagai tidak ditemukan pada impor ini; jangan otomatis menghapus, menonaktifkan atau menyebutnya delisting. Pengguna dapat mengarsipkan secara terpisah. |
| Nama/kode emiten berganti | Nama baru dengan kode yang sama memperbarui metadata sumber. Kode berbeda tidak otomatis digabung berdasarkan kemiripan nama; perlukan peninjauan/pencocokan manual agar riwayat tetap terhubung ke ID instrumen yang benar. |

Normalisasi kode menghapus spasi tepi, menggunakan huruf besar dan menerima satu sufiks `.JK` untuk diubah ke kode lokal. Setelah itu validasi sebagai kode saham Indonesia yang didukung. Kode duplikat setelah normalisasi tetap dianggap konflik. Jangan menggunakan nomor urut/baris Excel sebagai ID database.

Impor katalog **tidak** memanggil Yahoo untuk semua kode dan **tidak** mengunduh semua logo. URL Stockbit dibentuk saat diperlukan dari kode lokal; simbol Yahoo default hanya diisi bila mapping belum tersedia. Nilai/mapping yang dikoreksi pengguna tidak direset oleh impor.

Sediakan **Ekspor katalog JSON** untuk menyimpan daftar sumber, versi skema dan override katalog yang didukung, tanpa transaksi/holdings atau ID relasional perangkat. Backup lengkap aplikasi tetap menyertakan katalog, ID internal, mapping, override dan metadata impor agar pemulihan hubungan transaksi konsisten. Ekspor katalog tidak menggantikan backup keuangan.

Pemeriksaan saat implementasi: impor Excel IDX langsung di Android tanpa internet; urutan kolom berubah; kolom `No` tidak ada/penomorannya berubah; kode `TRUE`; kelima kolom sumber tersimpan; jumlah lembar dinormalisasi tanpa perubahan nilai; angka kosong vs nol, pecahan, negatif dan overflow; JSON/backup mempertahankan jumlah lembar; file duplikat; kode/nama kosong; konflik setelah normalisasi; impor ulang; metadata manual tetap tersimpan; saham yang absen tetap tersimpan; kegagalan tulis di tengah impor tidak menyisakan pembaruan sebagian; perubahan jumlah lembar emiten tidak mengubah saldo, unit, modal dan jumlah transaksi pengguna.

## Logo dari Stockbit

Pola URL diberikan pengguna:

```text
https://assets.stockbit.com/logos/companies/{KODE_SAHAM}.png
https://assets.stockbit.com/logos/companies/BBCA.png
```

Gunakan kode lokal yang dinormalisasi/di-encode sebagai segmen URL. **Jangan memakai `BBCA.JK.png`**. Bila input sudah `BBCA.JK`, normalisasi ke `BBCA` satu kali, kemudian ambil simbol provider dari mapping; jangan menambahkan `.JK` berulang.

Tidak perlu mengunduh semua logo terlebih dahulu atau menyimpan gambar di storage server. Menampilkan gambar dari URL tetap mengunduh byte gambar lewat internet. Unduh hanya logo yang diperlukan, simpan cache disk terbatas, dan gunakan kembali saat offline. Cache dapat terhapus/diusir OS; bila belum tersedia/gagal, tampilkan inisial/kode. Kegagalan logo tidak boleh menghalangi pencatatan atau valuasi.

Simpan gambar di direktori cache aplikasi, bukan BLOB pada tabel instrumen. Cache logo dapat dikecualikan dari backup karena dapat dibangun ulang. Pola URL dibuat terpusat dan dapat diberi override, sehingga perubahan penyedia tidak memerlukan perubahan transaksi historis. Ini bukan klaim bahwa endpoint tersebut memiliki jaminan API atau ketersediaan permanen.

## Harga Yahoo

Alur: pengguna mencari `BCA`/`BBCA` di katalog → memilih instrumen BBCA → adapter mengambil harga memakai `BBCA.JK` → cache menyimpan harga, mata uang, tanggal sesi dan waktu pengambilan. Ambil hanya simbol yang diperlukan/diikuti, bukan seluruh katalog.

Target tetap harga penutupan sesi terakhir yang sudah selesai. Sufiks benar tidak menjamin endpoint selalu berhasil: tetap tangani 429, respons kosong, simbol belum didukung dan data lama. Pertahankan cache yang valid beserta tanggalnya; jangan mengganti harga gagal dengan nol. Input manual tetap tersedia. Pembukaan halaman Yahoo untuk verifikasi simbol bukan uji keberhasilan integrasi API aplikasi.
