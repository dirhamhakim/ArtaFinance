import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Both Android implementations resolve Context.filesDir, so existing data
/// keeps the same location if the platform plugin cannot be initialized.
final class LocalStorageService {
  LocalStorageService({
    Future<Directory> Function()? directoryProvider,
    bool? android,
    MethodChannel? channel,
  }) : directoryProvider = directoryProvider ?? getApplicationSupportDirectory,
       android = android ?? Platform.isAndroid,
       channel = channel ?? const MethodChannel('id.arta.arta/storage');

  final Future<Directory> Function() directoryProvider;
  final bool android;
  final MethodChannel channel;

  Future<File> databaseFile() async {
    late Directory directory;
    try {
      directory = await directoryProvider();
    } catch (error, stack) {
      if (!android) rethrow;
      developer.log(
        'Path provider unavailable; trying Android filesDir.',
        name: 'arta.startup',
        error: error,
        stackTrace: stack,
      );
      try {
        final path = await channel.invokeMethod<String>(
          'getApplicationSupportDirectory',
        );
        if (path == null || path.trim().isEmpty || !p.isAbsolute(path)) {
          throw const FormatException('Direktori privat Android tidak valid.');
        }
        directory = Directory(path);
      } catch (fallbackError) {
        throw LocalStorageException(error, fallbackError);
      }
    }
    if (!p.isAbsolute(directory.path)) {
      throw const FormatException(
        'Direktori penyimpanan harus berupa jalur absolut.',
      );
    }
    await directory.create(recursive: true);
    return File(p.join(directory.path, 'arta.sqlite'));
  }
}

final class LocalStorageException implements Exception {
  const LocalStorageException(this.providerError, this.androidError);
  final Object providerError, androidError;
  @override
  String toString() =>
      'Provider: $providerError\nAndroid filesDir: $androidError';
}
