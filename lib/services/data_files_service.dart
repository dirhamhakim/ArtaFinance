import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

final class PickedData {
  PickedData(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

final class DataFilesService {
  Future<PickedData?> pick(
    List<String> extensions, {
    int maxBytes = 10 * 1024 * 1024,
  }) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: extensions,
      dialogTitle: 'Pilih file data Arta',
    );
    if (file == null) return null;
    final length = await file.length();
    if (length != null && length > maxBytes) {
      throw const FormatException('Ukuran file terlalu besar.');
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in file.readAsByteStream()) {
      if (bytes.length + chunk.length > maxBytes) {
        throw const FormatException('Ukuran file terlalu besar.');
      }
      bytes.add(chunk);
    }
    return PickedData(file.name, bytes.takeBytes());
  }

  Future<bool> save(
    Uint8List bytes,
    String prefix, {
    String extension = 'csv',
  }) async {
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    return await FilePicker.saveFile(
          fileName: '$prefix-$stamp.$extension',
          bytes: bytes,
          mimeType: extension == 'csv' ? 'text/csv' : 'application/json',
          dialogTitle: 'Simpan data Arta',
        ) !=
        null;
  }
}
