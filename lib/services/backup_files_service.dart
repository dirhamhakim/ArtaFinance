import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'backup_service.dart';

final class BackupFilesService {
  Future<Uint8List?> pick() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
      dialogTitle: 'Pilih backup Arta',
    );
    if (file == null) return null;
    final length = await file.length();
    if (length != null && length > BackupService.maxBytes) {
      throw const FormatException('Ukuran backup maksimal 25 MB.');
    }
    final builder = BytesBuilder(copy: false);
    await for (final chunk in file.readAsByteStream()) {
      if (builder.length + chunk.length > BackupService.maxBytes) {
        throw const FormatException('Ukuran backup maksimal 25 MB.');
      }
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  Future<bool> save(Uint8List bytes, {required String prefix}) async {
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final result = await FilePicker.saveFile(
      fileName: '$prefix-$stamp.json',
      bytes: bytes,
      mimeType: 'application/json',
      dialogTitle: 'Simpan backup Arta',
    );
    return result != null;
  }
}
