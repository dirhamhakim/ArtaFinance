# Font Flutter dan FigCraft

Flutter dapat menggunakan TTF/OTF yang disertakan bersama aplikasi. Font tidak perlu diinstal pada Windows, emulator, maupun HP dan tidak memerlukan download saat aplikasi dibuka.

Proyek Arta saat ini sudah mendaftarkan Lato Regular/Bold pada `pubspec.yaml`. Pola untuk font lain sama:

```yaml
flutter:
  fonts:
    - family: NamaFont
      fonts:
        - asset: assets/fonts/NamaFont-Regular.otf
        - asset: assets/fonts/NamaFont-Bold.otf
          weight: 700
```

Kemudian theme Flutter memakai `fontFamily: 'NamaFont'`. Contoh ini hanya dokumentasi; `pubspec.yaml` tidak diubah pada tahap desain.

FigCraft menggunakan Bit Sans sesuai referensi Bibit. File OTF berada pada `fonts-reference`. `text.loadFont` memuat file ke sesi engine MCP tanpa instalasi Windows. Ketersediaan pada sesi itu tidak otomatis berlaku pada aplikasi desktop/sesi lain; native file yang disimpan belum menyematkan file font. Preview PNG dapat dilihat di mana pun tanpa memasang font. Periksa `file.fontReport` sebelum render baru.
