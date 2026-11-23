# CoinGecko gratis dan rencana pemakaian Arta

Dokumentasi diperiksa pada 19 November 2026. Modul harga kini tersedia pada kode **0.4.0**, dengan key Demo lokal terenkripsi, request crypto gabungan, cache dan refresh opsional. API key pengguna telah berhasil diuji dari laptop (HTTP 200); APK 0.4.0 belum dibuild/dipasang. Key tetap tidak diperlukan untuk pencatatan offline atau pembukaan database. Lihat [pengaturan dan batas implementasi](TAHAP-4-0.4.0.md).

| Akses | API key | Batas | Perbedaan utama |
| --- | --- | --- | --- |
| Keyless public | Tidak | Sekitar 5 request/menit, dinamis menurut beban server; berbagi batas berdasarkan IP | Tidak perlu daftar |
| Demo gratis | Ya | 100 request/menit dan 10.000 kredit/bulan | Endpoint utama yang sama dengan keyless, batas lebih tinggi dan pemantauan pemakaian |

Demo tetap berkuota dan tidak membuka seluruh fitur paket Pro. Angka tersebut berasal dari [dokumentasi keyless resmi](https://docs.coingecko.com/docs/keyless-public-api) dan [halaman harga resmi](https://www.coingecko.com/en/api/pricing). Ketentuan penyedia dapat berubah.

## Rekomendasi implementasi

- Gunakan Demo gratis saat modul harga dikerjakan. Pengguna belum perlu memberikan key untuk pengujian pencatatan offline sekarang.
- Ambil beberapa koin sekaligus menggunakan ID CoinGecko melalui `/simple/price`, bukan satu request untuk setiap koin. ID lebih aman daripada simbol yang dapat sama pada beberapa aset.
- Simpan harga, mata uang, sumber, dan waktu harga/refresh terakhir secara lokal. Saat tidak ada internet atau kuota habis, tampilkan harga tersimpan beserta waktunya.
- Refresh awal setiap 5 menit hanya saat halaman portofolio aktif, dengan tombol refresh manual yang tetap mengikuti pembatasan. Hentikan polling saat aplikasi berada di latar belakang.
- Satu request gabungan setiap menit sepanjang 30 hari mencapai 43.200 request; setiap 5 menit mencapai 8.640. Jadi batas per menit yang lebih tinggi tidak membuat kuota bulanan tak terbatas. Endpoint lain juga memakai kuota.
- Respons 429 memicu jeda sebelum mencoba ulang, bukan retry terus-menerus. Keyless dapat menjadi opsi pengguna, bukan cara menghindari pembatasan Demo.

Autentikasi Demo memakai header `x-cg-demo-api-key` pada `https://api.coingecko.com/api/v3`. Lihat [autentikasi resmi](https://docs.coingecko.com/demo/reference/authentication). Menu pengaturan API key belum ada pada APK 0.2.1 dan akan dibuat bersama modul harga.
