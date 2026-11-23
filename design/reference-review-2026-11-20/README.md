# Bukti pemetaan UI — 20 November 2026

Acuan utama: [pemetaan rombak UI](../../docs/design/PEMETAAN-ROMBAK-UI-2026-11-20.md).

- `inventory.json`: 126 sumber asli, ukuran raster, checksum dan metode tinjau.
- `new-screens.csv`: katalog 67 screenshot baru beserta nama layar.
- `vector-manifest.json`: 23 SVG generik yang disalin dari DOM pengguna untuk referensi, bukan aset produksi.
- `source-vector-viewer.html`: spesimen vektor sumber. Tidak mengandung data saldo, identitas, nomor rekening atau token sesi pengguna.
- `verified-feather-geometry.json`: empat pembandingan geometri yang benar-benar identik; bukan kesimpulan bahwa semua ikon Bibit memakai Feather.
- `official-*.json`: permintaan publik yang berhasil/gagal dicatat apa adanya. Tidak memakai sesi login atau API privat.
- `verified-public-vector-matches.json`: hasil terbatas pada bundle yang diperiksa.

File screenshot asli tidak dimodifikasi. Contact sheet dan 59 potongan screenshot panjang berada pada `build/ui-reference-review-20261120/`. Penggunaan warna dalam viewer adalah spesimen sumber, bukan klaim token mobile final. Folder ini tidak didaftarkan sebagai assets Flutter.
