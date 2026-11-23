import 'dart:io';
import 'dart:ui' as ui;

import 'package:arta/app.dart';
import 'package:arta/controllers/finance_controller.dart';
import 'package:arta/database/app_database.dart';
import 'package:arta/models/money.dart';
import 'package:arta/models/ledger.dart';
import 'package:arta/repositories/finance_repository.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

const captureKey = Key('capture');
Future<void> capture(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(captureKey),
    );
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory(p.join('build', 'ui-review'));
    await directory.create(recursive: true);
    await File(p.join(directory.path, '$name.png'))
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> loadFonts(WidgetTester tester) async {
  await tester.runAsync(() async {
    await (FontLoader('BitSans')
          ..addFont(rootBundle.load('assets/fonts/bit_sans_regular.otf'))
          ..addFont(rootBundle.load('assets/fonts/bit_sans_bold.otf')))
        .load();
    await (FontLoader('Lato')
          ..addFont(rootBundle.load('assets/Lato-Regular.ttf'))
          ..addFont(rootBundle.load('assets/Lato-Bold.ttf')))
        .load();
    await (FontLoader(
          'packages/feather_icons/Feather',
        )..addFont(rootBundle.load('packages/feather_icons/fonts/feather.ttf')))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
}

void main() {
  testWidgets('layar kecil, landscape, dan font besar tetap dapat dipakai', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    final controller = FinanceController(FinanceRepository(db));
    addTearDown(() async {
      controller.dispose();
      await db.close();
    });
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await controller.initialize();
    await controller.createAccount(
      'Rekening dengan nama panjang untuk pemeriksaan tampilan',
      AccountKind.bank,
      Money.input('-1234567890123456789,99'),
    );
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    for (final size in [const Size(360, 800), const Size(800, 360)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(ArtaApp(controller: controller));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Catat transaksi'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
  testWidgets('aset minus dan pengeluaran tersimpan pada layar ponsel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await loadFonts(tester);
    final db = AppDatabase.memory();
    final controller = FinanceController(FinanceRepository(db));
    addTearDown(() async {
      controller.dispose();
      await db.close();
    });
    await controller.initialize();
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureKey,
        child: ArtaApp(controller: controller),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(Scaffold)), const Size(360, 800));
    await capture(tester, 'empty-dark');
    await tester.ensureVisible(find.text('Tambah aset pertama'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah aset pertama'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('account-name')), 'Mandiri');
    await tester.enterText(find.byKey(const Key('opening-balance')), '-1000');
    await tester.ensureVisible(find.byKey(const Key('save-account')));
    await tester.tap(find.byKey(const Key('save-account')));
    await tester.pumpAndSettle();
    expect(controller.snapshot.accounts, hasLength(1));
    expect(controller.snapshot.total, Money.input('-1000'));
    await tester.tap(find.byTooltip('Catat transaksi'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('transaction-amount')), '5500');
    await tester.enterText(
      find.byKey(const Key('transaction-category')),
      'Biaya bank',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('save-transaction')),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('save-transaction')));
    await tester.pumpAndSettle();
    expect(controller.snapshot.total, Money.input('-6500'));
    expect(controller.snapshot.transactions, hasLength(1));
    expect(tester.takeException(), isNull);
    await capture(tester, 'overview-dark');
    await tester.tap(find.byKey(const Key('nav-4')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Gelap'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gelap'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terang').last);
    await tester.pumpAndSettle();
    expect(controller.snapshot.theme, 'light');
    expect(
      Theme.of(tester.element(find.text('Preferensi'))).brightness,
      Brightness.light,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('nav-0')));
    await tester.pumpAndSettle();
    await capture(tester, 'overview-light');
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
