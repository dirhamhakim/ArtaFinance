# Revisi ringkasan saldo

Revisi pengguna, 21 November 2026. Sudah diterapkan lewat MCP pada master dan file UI lengkap, tema Dark/Light.

- **Baris atas:** Aset dan Liabilitas, masing-masing setengah lebar card.
- **Baris bawah:** Total selebar card, font 24 px, dipisahkan divider tipis. Rumus singkat dan tombol mata berada pada baris judul Total. Area sentuh mata 48×48 px.
- Card privasi memakai susunan yang sama dengan nominal berupa titik. Tinggi card normal 183 px dan dapat bertambah mengikuti isi. Susunan card bertingkat, radius dan warna tetap mengikuti referensi Bibit.

## Nominal besar

Angka lengkap dipakai selama masih muat. Jika tidak muat, gunakan format ringkas yang satuannya jelas: `jt` = juta, `M` = miliar, `T` = triliun. Pengukuran dilakukan terhadap ruang/font aktual, termasuk skala teks aksesibilitas; jangan hanya memakai batas jumlah digit.

Total mendapat prioritas angka lengkap karena ruangnya lebih lebar. Pada layar sempit dengan font besar, Total juga boleh memakai format ringkas. Ketuk nominal untuk membuka rincian dengan angka penuh. Jangan memakai ellipsis untuk membuang digit, menampilkan notasi ilmiah, atau mengecilkan font sampai sulit dibaca. Untuk skala teks ekstrem yang membuat label pun tidak muat, baris Aset/Liabilitas dapat ditumpuk sebagai fallback aksesibilitas.

Pembulatan hanya pada tampilan ringkas. Nilai database, ekspor, perhitungan Total dan rincian tetap memakai presisi aslinya. Total dihitung dari nilai asli terlebih dahulu, lalu diformat. Warna Total mengikuti tanda nilai, bukan selalu dianggap positif.

## Contoh yang diperiksa

| Nilai | Nominal asli | Ringkas |
| --- | --- | --- |
| Aset | Rp987.654.321.987.654 | Rp987,65 T |
| Liabilitas | Rp123.456.789.123.456 | Rp123,46 T |
| Total | Rp864.197.532.864.198 | Rp864,20 T |

- [412 px, dua tema](01-nominal-besar-dua-tema.png): Total tampil lengkap.
- [360 px, teks 130%, dua tema](02-360-font130.png): ringkasan tetap terbaca.
- [Rincian nominal utuh](03-rincian-nominal-utuh.png): angka lengkap memakai ukuran body 16 px × 130%.
- Pengujian geometry 10 halaman baru kembali tidak menemukan overflow. [qa.json](qa.json).

Enam frame review tambahan berada pada halaman **18 · QA & Panduan**. Nominal contoh dan interaksi rincian merupakan simulasi prototype; formatter adaptif belum diimplementasikan pada Flutter. Tidak ada perubahan APK/database pada revisi ini.
