import 'dart:async';
import 'dart:io';

import 'package:arta/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets(
    'startup gagal menunjukkan rincian; retry tidak berjalan bersamaan',
    (tester) async {
      var calls = 0;
      final retry = Completer<File>();
      await tester.pumpWidget(
        BootstrapScreen(
          databaseFile: () async {
            calls++;
            if (calls == 1) throw StateError('simulated JNI failure');
            return retry.future;
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Penyimpanan lokal belum dapat dibuka.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('startup-details')));
      await tester.pumpAndSettle();
      expect(find.textContaining('simulated JNI failure'), findsOneWidget);
      expect(find.textContaining('Direktori privat aplikasi'), findsOneWidget);
      final button = tester.widget<TextButton>(
        find.byKey(const Key('startup-retry')),
      );
      button.onPressed!();
      button.onPressed!();
      await tester.pump();
      expect(calls, 2);
      retry.completeError(const FileSystemException('second failure'));
      await tester.pumpAndSettle();
      expect(
        find.text('Penyimpanan lokal belum dapat dibuka.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('startup-details')));
      await tester.pumpAndSettle();
      expect(find.textContaining('second failure'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'hasil startup terlambat setelah widget ditutup tidak membuka database',
    (tester) async {
      final operation = Completer<File>();
      await tester.pumpWidget(
        BootstrapScreen(databaseFile: () => operation.future),
      );
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      operation.complete(File('unused-after-dispose.sqlite'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
