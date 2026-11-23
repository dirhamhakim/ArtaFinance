import 'dart:convert';
import 'dart:typed_data';

import 'ledger.dart';

/// Foto yang dipilih disalin ke SQLite privat dan ikut backup, tanpa URL galeri.
final class ReceiptImage {
  const ReceiptImage({required this.id, required this.data});
  static const maxCount = 3;
  static const maxBytes = 2 * 1024 * 1024;
  final String id, data;
  Uint8List get bytes => base64Decode(data);
  Map<String, Object?> toJson() => {
    'id': id,
    'mime': 'image/jpeg',
    'data': data,
  };
  factory ReceiptImage.fromJson(Map<String, Object?> json) {
    exactKeys(json, {'id', 'mime', 'data'});
    final encoded = stringField(json, 'data');
    if (json['mime'] != 'image/jpeg' ||
        encoded.length > (maxBytes + 2) ~/ 3 * 4) {
      throw const FormatException('Lampiran harus JPEG maksimal 2 MB.');
    }
    final bytes = base64Decode(encoded);
    if (bytes.length < 4 ||
        bytes.length > maxBytes ||
        bytes[0] != 0xff ||
        bytes[1] != 0xd8 ||
        bytes[2] != 0xff) {
      throw const FormatException('Lampiran gambar tidak valid.');
    }
    if (bytes[bytes.length - 2] != 0xff ||
        bytes.last != 0xd9 ||
        !_hasSafeDimensions(bytes)) {
      throw const FormatException('Dimensi atau isi JPEG tidak valid.');
    }
    return ReceiptImage(id: stringField(json, 'id'), data: encoded);
  }

  static bool _hasSafeDimensions(Uint8List bytes) {
    var offset = 2;
    while (offset + 3 < bytes.length) {
      if (bytes[offset++] != 0xff) return false;
      while (offset < bytes.length && bytes[offset] == 0xff) {
        offset++;
      }
      if (offset >= bytes.length) return false;
      final marker = bytes[offset++];
      if (marker == 0xda || marker == 0xd9) return false;
      if (offset + 1 >= bytes.length) return false;
      final length = bytes[offset] * 256 + bytes[offset + 1];
      if (length < 2 || offset + length > bytes.length) return false;
      if ({0xc0, 0xc1, 0xc2}.contains(marker)) {
        if (length < 8) return false;
        final height = bytes[offset + 3] * 256 + bytes[offset + 4];
        final width = bytes[offset + 5] * 256 + bytes[offset + 6];
        return width > 0 && height > 0 && width <= 4096 && height <= 4096;
      }
      offset += length;
    }
    return false;
  }
}
