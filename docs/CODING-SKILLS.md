# Skill untuk implementasi Arta

Sebelas skill berhasil dipasang dan diverifikasi pada 18 November 2026 di `C:\Users\User\.codex\skills`. Skill tersedia bagi agen mulai giliran berikutnya. Ini panduan kerja agen, bukan dependency APK, Flutter SDK, atau kode aplikasi.

Sumber: repositori resmi [Flutter](https://github.com/flutter/agent-plugins) dan [Dart](https://github.com/dart-lang/skills). Revisi sumber, hash manifest, dan hasil verifikasi berada di [receipt JSON](CODING-SKILLS.json). Tidak ada skill lama yang ditimpa.

| Skill | Kegunaan untuk proyek |
| --- | --- |
| flutter-apply-architecture-best-practices | Pisahkan widget, controller, repository dan service |
| flutter-build-responsive-layout | Ukuran Android berbeda dan teks membesar |
| flutter-fix-layout-issues | Perbaiki overflow, scroll dan keyboard |
| flutter-add-widget-test | Uji interaksi form/komponen yang penting |
| flutter-implement-json-serialization | Model, data sumber dan format backup |
| flutter-setup-localization | Bahasa Indonesia, tanggal dan format angka |
| flutter-use-http-package | Adapter harga dan pengambilan data HTTP |
| dart-add-unit-test | Uji ledger, modal, jadwal, bunga dan restore |
| dart-run-static-analysis | Pemeriksaan analyzer dan perbaikan lint |
| dart-resolve-package-conflicts | Atasi ketidakcocokan versi dependency |
| dart-use-path-package | Jalur file backup dan cache lintas perangkat |

Ketentuan proyek dalam [RANCANGAN.md](RANCANGAN.md) tetap menjadi acuan: folder `controllers`, `repositories`, `services`, database lokal Drift/SQLite, tanpa backend/cloud/login untuk versi ini. Contoh struktur atau library dalam skill tidak otomatis mengganti keputusan pengguna. Perhitungan keuangan harus memakai desimal eksak, bukan contoh floating point yang mungkin ada di panduan umum.

Tidak dipasang skill Supabase, Express atau PostgreSQL karena bukan arsitektur aplikasi ini. Tidak ada skill khusus Drift yang diklaim telah dipasang; implementasi transaksi database/migrasi mengikuti [dokumentasi Drift](https://drift.simonbinder.eu/migrations/) serta pengujian integritas data.

Installer bawaan dijalankan dengan runtime Python yang sudah ada. Karena runtime memakai jalur modul terisolasi dan unduhan Python/Git terputus, [wrapper lokal](../scripts/install-coding-skills.py) hanya menyesuaikan jalur import dan memasok arsip yang diunduh melalui HTTPS Windows. Validasi nama/path, ekstraksi aman, dan penanganan folder tujuan tetap dilakukan installer bawaan. SDK atau instalasi Python sistem tidak diubah.
