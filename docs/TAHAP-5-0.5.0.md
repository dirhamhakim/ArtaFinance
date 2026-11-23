# Arta 0.5.0+7 — chart aset, crypto bawaan, staking, dan harga harian

**Source 0.5.0 telah lulus 150 pengujian unit/widget dan analyzer bersih; APK versi ini belum dibuild sesuai instruksi pengguna.** APK yang tersedia tetap [0.4.0](../build/app/outputs/flutter-apk/arta-0.4.0-debug.apk). Tidak memasang aplikasi ke HP atau menjalankan emulator. Hasil validasi akhir dicatat di [VALIDASI-0.5.0.json](VALIDASI-0.5.0.json).

## Menu chart

- Ringkasan atau Pengaturan > **Analisis & grafik**: pilih Gabungan aset, Portofolio investasi, Aset noninvestasi, atau Pemasukan & pengeluaran.
- Portofolio > **Grafik portofolio** langsung memilih investasi. Menu Akun > **Grafik aset noninvestasi** memilih saldo akun.
- Periode 1B, 3B, 6B, 1T, Semua. Ketuk/geser line chart untuk melihat tanggal dan nilai IDR. Donut dapat diketuk pada segmen atau legendanya; komposisi menunjukkan keadaan saat ini, sedangkan periode hanya memfilter grafik riwayat.
- Portofolio investasi menghitung nilai unit saham/crypto/reksa dana, termasuk unit staking satu kali. Saldo akun mencakup bank, e-wallet, kas, piutang/utang dan kas RDN/exchange yang belum dibelanjakan. Kartu debit tidak menciptakan saldo kedua.
- Donut hanya memakai nilai positif. Utang/saldo negatif ditampilkan terpisah sebagai pengurang nilai bersih, termasuk ketika rekening positif dan negatif berada pada jenis akun yang sama. Akun/posisi tanpa kurs/harga diberi penanda komposisi belum lengkap.
- Line chart aset adalah perkembangan **nilai**, bukan persentase return investasi. Setoran, penarikan, bunga, transaksi dan perubahan harga dapat mengubah garis. Arus kas memiliki dua garis pemasukan/pengeluaran; transfer pokok dan hasil jual investasi tidak dianggap pendapatan/konsumsi baru.
- Tombol mata menyembunyikan angka, garis dan donut. Tema gelap/terang mengikuti tema aplikasi. Legenda dan angka pilihan tetap dapat dibaca pada font besar.

## Riwayat dan harga yang belum lengkap

Riwayat dihitung ulang dari transaksi berdasarkan tanggal, unit pada tanggal itu, harga penutupan/manual terakhir yang tersedia, dan kurs historis yang diketahui. Harga terbaru dari tombol manual dipisahkan. Harga/kurs tanggal setelah titik chart tidak digunakan untuk mengisi titik sebelumnya. Jika posisi nonnol belum memiliki harga/kurs, nilai titik menjadi tidak lengkap dan garis diputus; tidak menampilkan nol seolah seluruh portofolio sudah dinilai.

Harga terakhir dapat dibawa sampai observasi selanjutnya; ini bukan jaminan harga pasar tidak berubah selama jeda. Tidak membuat riwayat sebelum observasi pertama. Impor CSV tambahan mengisi harga tanpa mengubah transaksi/unit.

File pengguna `harga_penutupan_saham.json` dan `crypto_penutupan.json` telah diperiksa dan disiapkan sebagai referensi offline: **918 saham dengan riwayat, 26 tanpa data, dan 10 crypto**, total **2.963.202 observasi**. Semua sembilan default sebelumnya tersedia; XRP ditambahkan karena ada dalam file. Data crypto menyediakan USD dan IDR hasil konversi kurs harian, bukan harga langsung bursa IDR. Tanggal terakhir mengikuti masing-masing instrumen; tidak diasumsikan semua aktif diperdagangkan pada hari yang sama.

Data disimpan per instrumen dalam `assets/data/history/` sekitar 10,35 MB terkompresi. Aplikasi memuat riwayat instrumen yang pernah ditransaksikan atau sedang dibuka, melalui isolate; daftar detail menampilkan 60 baris dahulu. Referensi bawaan tidak disalin ke SQLite, CSV harga atau backup transaksi. Setelah restore pada versi ini, referensi dimuat lagi dari aset aplikasi. Harga tambahan/manual tetap tersimpan di database dan backup; pada tanggal sama, harga tambahan memiliki prioritas atas referensi bawaan. Jika ada kegagalan pembacaan referensi, tampilkan peringatan tanpa menghalangi pencatatan.

**Stock split:** file saham memakai Close yang sudah disesuaikan split, bukan dividen. Basis penyesuaian disimpan sebagai `adjusted_through=2026-11-19`. Grafik harga detail menampilkan harga pada basis sumber; valuasi portofolio mengonversinya ke unit aktual pada tanggal ledger memakai split yang kamu catat. Kamu tetap harus mencatat aksi split/reverse split aktual untuk posisi yang dimiliki; data harga tidak menciptakan transaksi split. Contoh 10 lembar sebelum split 1:2 dengan harga aktual 100 bernilai 1.000; sesudah split menjadi 20 lembar × 50, tetap 1.000. Split yang sama pada beberapa lokasi dihitung sekali untuk konversi harga. Tanpa catatan split yang benar, valuasi historis sekitar aksi korporasi dapat salah.

Saham tanpa referensi tetap tanpa harga: ARMY, BTEL, CBMF, CPRI, GAMA, HKMU, HOME, HOTL, IIKP, JSKY, KBRI, MAGP, META, NUSA, OCAP, POOL, POSA, PURE, RIMO, SCPI, SIMA, SMRU, TECH, TRAM, TRIO, WSKT. Tidak diisi nol. Harga manual atau pembaruan sumber yang kelak berhasil tetap bisa digunakan.

Persiapan ulang data: jalankan `python tools/prepare_reference_prices.py <file-saham.json> <file-crypto.json>`. Script memeriksa tanggal, harga, kecocokan katalog, dan mencatat hash sumber; file asli tidak diubah. Laporan pemeriksaan ada di `build/reference-data-0.5.0.json`.

Saldo awal rekening berlaku sejak tanggal pembuatan atau transaksi paling awal rekening, mana yang lebih dulu. Jika tanggal saldo awal sebenarnya berbeda, riwayat awal merupakan pendekatan dari tanggal yang tersedia. Harga saham memakai tanggal sesi WIB; crypto memakai label periode UTC dan menyimpan timestamp referensinya. Grafik harian adalah gabungan referensi harian tersebut, bukan valuasi serentak intraday semua pasar.

Rentang sangat panjang diringkas hingga sekitar 366 titik. Seluruh perubahan saldo/unit tetap diproses; pemasukan/pengeluaran dijumlahkan per interval. Engine replay investasi berjalan bertahap, tidak memutar ulang seluruh riwayat dari nol pada setiap titik. Menyimpan kurs bertanggal lama tidak menghapus kurs valuasi yang lebih baru; kedua observasi disimpan.

## Sepuluh crypto bawaan

| Kode | Nama | ID CoinGecko |
| --- | --- | --- |
| BTC | Bitcoin | bitcoin |
| ETH | Ethereum | ethereum |
| SOL | Solana | solana |
| HYPE | Hyperliquid | hyperliquid |
| USDT | Tether | tether |
| USDC | USDC | usd-coin |
| XAUT | Tether Gold | tether-gold |
| PAXG | PAX Gold | pax-gold |
| BNB | BNB | binancecoin |
| XRP | XRP | ripple |

Metadata dan URL logo berasal dari respons CoinGecko. Logo dipanggil saat diperlukan; tidak menyimpan file foto besar. Startup menambahkan instrumen yang belum ada berdasarkan ID atau mapping provider. Tidak menggandakan crypto yang sudah dicatat dengan ID lokal lain dan mapping sama; koreksi nama, arsip, riwayat serta kepemilikan lama dipertahankan. Instrumen bawaan tidak berarti pengguna memiliki saldo dan tidak memicu request seluruh katalog.

USDT/USDC sebagai unit investasi tetap mengikuti harga sumber, bukan diasumsikan tepat 1 USD. Jangan mencatat unit USDT yang sama sekaligus sebagai kepemilikan investasi dan saldo awal akun kas USDT, karena itu menggandakan aset. Pada lokasi wallet, kas dapat nol dan seluruh token dicatat sebagai unit.

## Harga penutupan otomatis dan harga terbaru manual

Pengaturan > Sumber harga & mata uang menyediakan **Simpan penutupan harian otomatis**, default aktif. Pengambilan berjalan saat aplikasi aktif, tidak terkunci, dan internet/provider dapat diakses. Hanya instrumen yang dimiliki yang diambil, bukan 944 saham dan semua katalog. Pemeriksaan ringan dilakukan saat membuka/kembali ke aplikasi serta saat timer foreground berjalan. Tidak ada alarm/worker Android; jika aplikasi ditutup, tidak ada request. Saat dibuka kembali aplikasi memeriksa data yang tertinggal.

- **Saham:** Yahoo `KODE.JK`, close biasa sesi selesai dengan pemeriksaan waktu akhir sesi + 15 menit. Pemeriksaan harian otomatis memakai jendela konservatif sesudah 18:00 WIB untuk hari berjalan; sebelumnya memeriksa sesi terdahulu. Akhir pekan memakai hari kerja terakhir; pada hari libur/gangguan sumber, tanggal harga aktual tetap mengikuti sesi yang dikirim Yahoo.
- Respons Yahoo satu bulan terakhir juga disimpan per sesi yang sudah selesai, sehingga beberapa hari tertinggal dapat terisi dalam satu request per saham. Referensi bawaan menyediakan riwayat lebih panjang sesuai file pengguna. Tanggal yang tidak tersedia di sumber tetap tidak dibuat-buat.
- **Crypto:** CoinGecko `/coins/{id}/market_chart`, interval daily. Hanya observasi tepat **00:00 UTC** dipakai sebagai referensi akhir hari UTC sebelumnya. Timestamp referensi tetap disimpan pada `as_of`; ekor respons berisi harga live dibuang. Data hari terakhir ditunggu sampai **00:35 UTC (07:35 WIB)**. Ini referensi batas hari agregat CoinGecko, bukan harga transaksi terakhir suatu exchange atau jaminan candle OHLC exchange tertentu. Lihat [dokumentasi Demo CoinGecko](https://docs.coingecko.com/demo/reference/coins-id-market-chart).
- Request crypto mengambil minimal tujuh hari untuk mengisi jeda dan menerima revisi data dekat hari terakhir. Jika cache sudah lama, rentang diperlebar sesuai jeda, maksimal 365 hari, mengikuti batas Demo pada dokumentasi sumber. Harga yang sudah tercatat harian tidak diambil berulang pada target hari yang sama. Data lebih lama dari jangkauan sumber tetap memerlukan CSV/manual.
- Pemeriksaan/percobaan disimpan per instrumen dan target hari. Kegagalan otomatis diberi jeda satu jam; tombol manual minimal satu menit, ditambah backoff provider bila 429. Maksimal 12 instrumen per proses, sisanya dilanjutkan pada pemeriksaan berikutnya. Pada error, proses berhenti agar tidak mengirim rentetan permintaan yang gagal; instrumen lain dapat dilanjutkan pada pemeriksaan berikutnya. Tidak menjanjikan kuota gratis tanpa batas.
- Pembaruan otomatis tidak memakai status sibuk pencatatan; kamu tetap bisa mencatat transaksi ketika jaringan lambat. Penyimpanan hasil tetap atomik dan memuat data lokal terbaru agar tidak menimpa pencatatan yang berlangsung bersamaan.
- **Harga terbaru (manual)** mengambil snapshot terbaru crypto dan harga terbaru Yahoo (dapat tertunda). Nilai diberi timestamp dan ditampilkan terpisah di kepemilikan; tidak mengganti valuasi utama/line chart yang memakai penutupan. Tidak ada polling harga terbaru setiap lima menit.
- **Perbarui penutupan** memicu pemeriksaan penutupan lewat tombol. Reksa dana tetap NAB manual. Offline/error tidak menghapus cache, saldo, atau unit. API key tetap terenkripsi khusus perangkat dan tidak masuk source/APK/backup.

## Staking manual

1. Catat pembelian atau Saldo unit awal crypto di akun/lokasi yang tepat. Saldo unit awal tidak mengurangi kas lagi.
2. Portofolio atau Pengaturan > **Staking crypto > Tambah posisi staking**. Pilih akun dan crypto, beri nama platform/posisi; jaringan, validator/produk serta APR referensi opsional. Membuat posisi belum mengubah unit.
3. **Catat aktivitas > Stake unit** untuk mengunci unit bebas. Total unit, modal dan nilai portofolio tidak bertambah; unit terkunci tidak dapat dijual/dikirim/stake kembali.
4. **Ajukan unstake** memindahkan unit aktif staking ke status menunggu unstake. Tanggal perkiraan cair opsional; lewat tanggal tersebut tidak otomatis mengubah status.
5. Saat benar-benar cair, **Unstake cair / langsung**, aktifkan **Ambil dari unit menunggu unstake**. Untuk unstake langsung produk fleksibel, biarkan nonaktif agar mengambil unit aktif. Unit kembali bebas, tanpa pemasukan atau pembelian baru.
6. **Reward staking aktual** hanya untuk unit yang benar-benar diterima. Nonaktifkan restake bila menjadi unit bebas; aktifkan **Reward langsung di-stake kembali** jika langsung terkunci. Reward menambah unit dengan modal nol; bukan kas masuk. Reward belum diterima tidak dicatat sebagai saldo. APR referensi hanya estimasi sederhana setahun, tidak mengkreditkan unit dan bukan APY majemuk.
7. **Slashing / biaya unit staking** mengurangi unit dan modal proporsional dari bucket aktif atau menunggu unstake yang dipilih. Ini bukan hasil penjualan atau biaya kas fiktif. Biaya tunai terpisah memakai mata uang akun; jika biaya dibayar dalam token, gunakan aktivitas biaya unit sesuai bucket sumber. Jangan mencatat biaya yang sama dua kali.
8. Edit/hapus aktivitas dari riwayat. Seluruh urutan dihitung ulang; perubahan ditolak jika membuat unit bebas/terkunci/status unstake historis tidak cukup. Lokasi/crypto posisi yang sudah memiliki riwayat tidak bisa diganti; buat posisi lain. Posisi dapat diarsipkan tanpa menghapus riwayat.

Contoh: awal 1 SOL, stake 0,6 → bebas 0,4; ajukan unstake 0,2 → aktif 0,4, pending 0,2, bebas 0,4; cairkan pending 0,2 → aktif 0,4, pending 0, bebas 0,6. Total tetap 1 SOL di semua langkah. Reward aktual 0,01 SOL baru menambah total menjadi 1,01 SOL.

Pencatatan tidak mengirim transaksi staking, tidak meminta seed phrase/private key, dan tidak membuat liquid staking token sendiri. Untuk produk token turunan, catat token tersebut sebagai instrumen berbeda sesuai transaksi aktual; tidak menebak rasio konversi/rebase otomatis.

## Backup dan verifikasi

SQLite tetap skema 4 (tabel JSON keuangan yang sudah ada); payload diperluas secara kompatibel untuk pembaca baru. **Backup baru schema 5**, dapat memulihkan v1/v2/v3/v4/v5. Backup menyertakan posisi/aktivitas staking, status terkunci yang direkonstruksi, kurs historis dan pemisahan live/close. Versi aplikasi lama tidak memahami fitur/backup baru; simpan backup lama sebelum update. Kunci/API key tetap lokal perangkat.

CSV transaksi menambahkan identitas/status staking; kepemilikan menambah unit bebas/terkunci; harga menambah `kind=close/live` agar ekspor dan impor tidak mengubah snapshot terbaru menjadi penutupan palsu, serta `adjusted_through` untuk mempertahankan basis split. Ekspor harga mencakup harga tambahan yang disimpan pengguna, bukan jutaan referensi bawaan.

Checklist manual baru ditambahkan ke [markdown testing lama](TESTING-APK-0.2.0.md). Kasus baru **belum diuji pada HP**; menunggu instruksi build berikutnya. Hasil unit/widget/analyzer dan preview di komputer dicatat terpisah pada laporan validasi, bukan dianggap lulus uji HP.
