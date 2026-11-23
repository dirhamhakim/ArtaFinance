import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../models/receipt_image.dart';

class PhotoPickerService {
  static const channel = MethodChannel('id.arta.arta/photos');
  Future<ReceiptImage?> pick() async {
    final bytes = await channel.invokeMethod<Uint8List>('pickReceipt');
    if (bytes == null) return null;
    return ReceiptImage.fromJson({
      'id': const Uuid().v4(),
      'mime': 'image/jpeg',
      'data': base64Encode(bytes),
    });
  }
}
