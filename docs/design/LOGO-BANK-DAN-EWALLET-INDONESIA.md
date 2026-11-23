# Pilihan bank dan e-wallet Indonesia untuk Aset

Tanggal: 21 November 2026. Status: **riset sumber dan spesifikasi untuk coding/FigCraft; belum diimplementasikan**.

Pembaruan desain: 12 logo yang diperiksa sudah menjadi master vektor, dan contoh pemilih Bank/E-wallet beserta Lainnya tersedia pada [master FigCraft baru](../../design/master-components-2026-11-21/README.md). Ini belum memasang katalog/logo ke APK; daftar penyedia lengkap tetap pekerjaan implementasi berikutnya.

## Kebutuhan pengguna

Ketika membuat Aset kelas Bank atau Dompet digital, sediakan pilihan penyedia di Indonesia beserta logo. Pengguna tetap dapat memilih `Bank lainnya` atau `E-wallet lainnya`, memasukkan nama sendiri, dan memakai ikon generik tetap. Tidak wajib mengunggah gambar.

Untuk kelas Debit yang memiliki kantong sendiri, identitas bank boleh memakai katalog bank yang sama; memilih logo tidak menautkan atau menyamakan saldonya dengan aset Bank.

## Sumber yang ditemukan dan diperiksa

Kandidat sumber: [idn-finlogos](https://github.com/hafidznoor/idn-finlogos). Pemeriksaan memakai commit `443e012b93e5ebeb9948a12de054abca4412a7e6`, bukan URL branch yang dapat berubah tanpa jejak. README saat diperiksa mencantumkan 160 logo kategori bank dan 27 logo kategori e-wallet; angka tersebut termasuk variasi logo dan **bukan jumlah penyedia unik yang akan dimasukkan ke Arta**.

SVG contoh yang berhasil diambil dan diparse: Mandiri, SeaBank, Jago, BCA, BRI, BNI, DANA, GoPay, OVO, ShopeePay, LinkAja, dan DOKU. Kumpulan aktif berisi 12 logo contoh; DOKU menggantikan i.saku pada tahap desain 2. Ukuran sumber dan ekspor dapat berbeda; ini belum menjadi tambahan ukuran APK.

Bukti pemeriksaan, metadata sumber, checksum commit, katalog sumber, dan salinan lisensi berada di `build/payment-logo-research-20261121/`. Logo contoh masih berada pada folder riset tersebut; belum didaftarkan sebagai aset Flutter atau dimasukkan ke FigCraft.

Koleksi berisi kategori dan logo lama/alternatif yang lebih luas dari kebutuhan Arta. Ambil hanya identitas penyedia yang cocok untuk daftar Indonesia; jangan otomatis memasukkan seluruh koleksi, logo lama sebagai penyedia berbeda, atau logo payment gateway sebagai dompet saldo.

Keputusan pengguna 21 November 2026: **Jago Syariah memakai logo yang sama dengan Jago**. Nama pilihan tetap `Jago Syariah`, dengan ID penyedia tersendiri dan kunci logo bersama `jago`; tidak perlu mencari atau membuat logo Syariah terpisah. Pemilihan penyedia tidak membuat aturan bunga, biaya, atau sinkronisasi bank otomatis.

### Ketentuan sumber

Repository membedakan lisensi tooling dan aset: SVG ditandai [CC BY-NC 4.0](https://github.com/hafidznoor/idn-finlogos/blob/main/LICENSE-ASSETS), dengan atribusi dan pembatasan nonkomersial. Simpan sumber/versi/atribusi dan pemberitahuan pemilik merek. Jangan menyebut seluruh logo berlisensi MIT hanya karena kode paketnya MIT. Ketentuan penggunaan aset perlu dibawa ke catatan sumber aplikasi saat distribusi; pekerjaan saat ini masih riset.

## Katalog yang disiapkan

- Prioritaskan pilihan pribadi pengguna: Mandiri, SeaBank, dan Jago Syariah.
- Calon bank lain untuk pemilih awal: BCA, BRI, BNI dan bank Indonesia lain yang telah dicocokkan namanya serta logonya. Daftar final tidak dianggap lengkap dari enam SVG contoh saja.
- Calon e-wallet awal: DANA, GoPay, OVO, ShopeePay, LinkAja, dan DOKU. Penyedia lain dapat ditambahkan setelah kecocokan identitas Indonesia diperiksa.
- Daftar penyedia pembayaran dapat dicocokkan dengan [daftar lembaga berizin Bank Indonesia](https://www.bi.go.id/id/layanan/informasi-perizinan/sistem-pembayaran/default.aspx). Katalog logo bukan bukti status layanan atau izin yang berlaku saat ini.
- Fokus Indonesia berlaku pada pilihan bawaan Bank/E-wallet. Aset global/platform lain yang sudah digunakan pengguna tidak dihapus; input manual tetap tersedia.
- Alias pencarian boleh memuat nama produk/aplikasi yang dikenal, tetapi nama aplikasi dan logo versi lama tidak otomatis menjadi bank bersaldo baru.

## Alur form dan desain

1. Pilih **Kelas aset**.
2. Pada Bank atau Dompet digital, tampilkan field **Bank** atau **E-wallet**. Sentuh field untuk membuka bottom sheet dengan search, daftar logo/nama, dan pilihan Lainnya.
3. Pilih penyedia untuk mengisi identitas/logo dan saran nama aset. **Nama aset tetap dapat diedit**, misalnya `Mandiri Harian` atau `DANA Belanja`.
4. Isi mata uang, saldo awal dan field aset lain sesuai form yang sudah ada. Pemilihan penyedia sendiri tidak membuat transaksi.
5. `Bank lainnya` memakai ikon bank generik tetap; `E-wallet lainnya` memakai ikon dompet generik tetap. Pengguna mengetik nama penyedia sendiri. Tidak mengambil gambar acak dari pencarian internet.
6. Bila logo bawaan gagal dirender/tidak tersedia, gunakan ikon generik kelas yang sama tanpa menghilangkan nama atau memblokir penyimpanan.

Bottom sheet/list mengikuti referensi Bibit untuk daftar bank/wallet (`224424`) dan pemilih (`224625`). Ukuran avatar, alignment, divider, search dan selected state mengikuti sistem komponen Arta yang sedang dipetakan. Ikon generik mengikuti keluarga vektor referensi yang sama.

Beberapa file koleksi berupa wordmark horizontal. Jangan memotong tulisan atau meregangkannya agar muat avatar lingkaran. Pilih varian emblem/icon yang cocok dan dapat diverifikasi, atau gunakan penempatan proporsional dengan padding. Pertahankan warna merek; tema hanya mengatur surface/kontras di sekelilingnya. Identitas merek berbeda dari ikon menu garis hijau/ungu.

State desain yang perlu dibuat dalam terang/gelap: belum memilih, pencarian, terpilih, hasil kosong, Bank lainnya, E-wallet lainnya, dan fallback logo. Katalog lokal tidak membutuhkan loading jaringan setiap form dibuka.

## Penyimpanan dan logika

- **Rekomendasi: bundel logo terpilih secara lokal**, dengan manifest kecil. Ini selaras dengan aplikasi offline dan menghindari API key, request per pembukaan, dan ketergantungan hotlink untuk identitas Aset.
- Tidak perlu memasang paket penuh beserta seluruh kategori jika hanya sebagian logo digunakan; ambil SVG terpilih dengan sumber/versi yang tercatat dan renderer yang sesuai saat coding.
- Simpan ID penyedia stabil, kelas aset, nama aset milik pengguna, serta kunci logo. Nama tampilan dan nama file logo bukan primary key transaksi.
- Dua aset dari penyedia yang sama tetap mempunyai ID, saldo dan riwayat masing-masing. Pemilihan Mandiri dua kali tidak menggabungkan saldonya.
- ID penyedia dan nama kustom masuk backup. File logo bawaan dapat tetap berasal dari katalog aplikasi; backup tidak perlu menggandakan setiap SVG bawaan.
- Perubahan logo/nama penyedia tidak mengubah riwayat keuangan. Entri yang tidak lagi ditawarkan pada daftar baru tetap dapat ditampilkan pada aset lama dengan nama/fallbacknya.
- Perilaku kelas Debit bersaldo sendiri, saldo noninvestasi minus, serta biaya/bunga yang diisi pengguna tetap mengikuti [perubahan kebutuhan terbaru](../PERUBAHAN-KEBUTUHAN-2026-11-21.md).
- Kebijakan logo bank/e-wallet lokal ini terpisah dari logo emiten Stockbit dan metadata logo crypto CoinGecko yang sudah disepakati.

## Penerimaan berikutnya

- [ ] Daftar bawaan Bank/E-wallet sesuai cakupan Indonesia dan tidak menggandakan penyedia karena alias/variasi logo.
- [x] Pengguna menetapkan Jago Syariah memakai logo Jago yang sama; nama/ID penyedia tetap berbeda.
- [ ] Logo Mandiri, SeaBank dan Jago sudah diperiksa tampilannya pada ukuran avatar dalam dua tema.
- [ ] Pencarian nama/alias, pilihan Lainnya, nama kustom dan beberapa aset satu bank bekerja offline.
- [ ] Logo/emblem tidak terpotong, meregang atau kehilangan kontras pada dua tema.
- [ ] Logo gagal memakai ikon generik tetap; penyimpanan aset tidak terhalang.
- [ ] Debit dapat memakai identitas bank tanpa menyalin atau menautkan saldo Bank.
- [ ] Backup/restore mempertahankan ID penyedia, nama kustom dan fallback.
- [ ] Sumber/versi/atribusi disertakan saat aset dimasukkan ke distribusi aplikasi.

Dokumen ini belum berarti katalog/logo sudah terpasang pada APK.
