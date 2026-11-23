import 'dart:io';

import 'package:arta/app.dart';

import 'package:arta/controllers/app_lock_controller.dart';
import 'package:arta/controllers/finance_controller.dart';
import 'package:arta/database/app_database.dart';
import 'package:arta/models/receipt_image.dart';
import 'package:arta/repositories/finance_repository.dart';
import 'package:arta/screens/cards_screen.dart';
import 'package:arta/services/photo_picker_service.dart';
import 'package:arta/theme/app_theme.dart';
import 'package:arta/widgets/app_lock_gate.dart';
import 'package:arta/widgets/finance_empty_state.dart';
import 'package:arta/widgets/pin_keypad.dart';
import 'package:arta/widgets/receipt_images_field.dart';
import 'package:arta/widgets/transaction_time_field.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../fakes/fake_lock_service.dart';
import '../fixtures.dart';
import 'finance_flow_test.dart' show loadFonts, capture, captureKey;

void phoneView(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> enterPin(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    await tester.tap(find.byKey(Key('pin-digit-$digit')));
    await tester.pump();
  }
  await tester.pumpAndSettle();
  if (find.text('Lanjut').evaluate().isNotEmpty) {
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets(
    'aktivasi, konfirmasi PIN, kunci dan nonaktif melalui aplikasi penuh',
    (tester) async {
      phoneView(tester);
      final service = FakeLockService();
      final security = AppLockController(service);
      await security.initialize();
      final db = AppDatabase.memory();
      final controller = FinanceController(
        FinanceRepository(db),
        security: security,
      );
      addTearDown(() async {
        controller.dispose();
        await db.close();
      });
      await controller.initialize();
      await tester.pumpWidget(ArtaApp(controller: controller));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-4')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('security-menu')),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('security-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('configure-app-lock')));
      await tester.pumpAndSettle();
      await enterPin(tester, '123456');
      await enterPin(tester, '111111');
      expect(service.enabled, isFalse);
      expect(find.text('PIN berbeda. Buat ulang PIN Anda.'), findsOneWidget);
      await enterPin(tester, '654321');
      await enterPin(tester, '654321');
      expect(service.enabled, isTrue);
      expect(find.text('Kunci aplikasi aktif'), findsOneWidget);
      await tester.ensureVisible(find.text('Kunci sekarang'));
      await tester.tap(find.text('Kunci sekarang'));
      await tester.pumpAndSettle();
      expect(find.text('Verifikasi PIN'), findsOneWidget);
      await enterPin(tester, '654321');
      await tester.ensureVisible(find.text('Nonaktifkan kunci aplikasi'));
      await tester.tap(find.text('Nonaktifkan kunci aplikasi'));
      await tester.pumpAndSettle();
      expect(find.text('Verifikasi PIN'), findsOneWidget);
      await enterPin(tester, '654321');
      await tester.tap(find.text('Nonaktifkan'));
      await tester.pumpAndSettle();
      expect(service.enabled, isFalse);
      expect(find.text('Kunci aplikasi opsional'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('keypad PIN kustom tanpa TextField, hapus dan mata bekerja', (
    tester,
  ) async {
    phoneView(tester);
    String? submitted;
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: PinKeypad(
            onComplete: (pin) async {
              submitted = pin;
            },
          ),
        ),
      ),
    );
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.byKey(const Key('pin-digit-1')));
    await tester.pump();
    await tester.tap(find.byTooltip('Tampilkan PIN'));
    await tester.pump();
    expect(find.text('1'), findsNWidgets(2));
    await tester.tap(find.byKey(const Key('pin-delete')));
    await tester.pump();
    await enterPin(tester, '654321');
    expect(submitted, '654321');
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets(
    'gate menyembunyikan data, buka lewat PIN, dan terkunci setelah background',
    (tester) async {
      phoneView(tester);
      final service = FakeLockService(enabled: true, preferBiometric: false);
      final lock = AppLockController(service);
      addTearDown(lock.dispose);
      await lock.initialize();
      await loadFonts(tester);
      await tester.pumpWidget(
        RepaintBoundary(
          key: captureKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.create(Brightness.dark),
            builder: (_, child) => AppLockGate(controller: lock, child: child!),
            home: const Scaffold(
              body: Column(
                children: [
                  Text('Saldo rahasia 1000000'),
                  TextField(key: Key('private-draft')),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Saldo rahasia 1000000'), findsNothing);
      await capture(tester, 'pin-lock-dark');
      await enterPin(tester, '123456');
      expect(find.text('Saldo rahasia 1000000'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('private-draft')),
        'draft struk',
      );
      await tester.showKeyboard(find.byKey(const Key('private-draft')));
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isTrue);
      lock.background();
      await tester.pumpAndSettle();
      expect(find.text('Saldo rahasia 1000000'), findsNothing);
      expect(tester.testTextInput.isVisible, isFalse);
      lock.resumed();
      await tester.pumpAndSettle();
      await enterPin(tester, '123456');
      expect(find.text('Saldo rahasia 1000000'), findsOneWidget);
      expect(find.text('draft struk'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('jam analog selalu 24 jam dan tidak memiliki AM/PM', (
    tester,
  ) async {
    phoneView(tester);
    String? selected;
    await loadFonts(tester);
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.create(Brightness.dark),
          home: Scaffold(
            body: TransactionTimeField(
              value: '23:45',
              onChanged: (v) => selected = v,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('transaction-time')));
    await tester.pumpAndSettle();
    expect(find.text('AM'), findsNothing);
    expect(find.text('PM'), findsNothing);
    expect(find.text('23'), findsWidgets);
    expect(
      tester
          .widget<TimePickerDialog>(find.byType(TimePickerDialog))
          .initialEntryMode,
      TimePickerEntryMode.dialOnly,
    );
    await capture(tester, 'time-picker-dark');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(selected, '23:45');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'bottom sheet foto memakai Photo Picker, lampiran dapat ditambah dan dihapus',
    (tester) async {
      phoneView(tester);
      final bytes = File('test/fixtures/receipt.jpg').readAsBytesSync();
      var calls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(PhotoPickerService.channel, (call) async {
            expect(call.method, 'pickReceipt');
            calls++;
            return bytes;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(PhotoPickerService.channel, null),
      );
      var images = <ReceiptImage>[];
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, update) => ListView(
                children: [
                  ReceiptImagesField(
                    images: images,
                    onChanged: (v) => update(() => images = v),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('add-receipt')));
      await tester.pumpAndSettle();
      expect(find.text('Pilih foto'), findsOneWidget);
      await tester.tap(find.text('Pilih foto'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(images, hasLength(1));
      expect(images.single.bytes, bytes);
      expect(find.byType(Image), findsOneWidget);
      await tester.tap(find.byTooltip('Hapus foto struk'));
      await tester.pumpAndSettle();
      expect(images, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'kartu Jago dapat dibuat lewat menu dan tidak menggandakan saldo',
    (tester) async {
      phoneView(tester);
      final db = AppDatabase.memory();
      final repo = FinanceRepository(db);
      await repo.addAccount(account('bank', '1000'));
      final controller = FinanceController(repo);
      addTearDown(() async {
        controller.dispose();
        await db.close();
      });
      await controller.initialize();
      await loadFonts(tester);
      await tester.pumpWidget(
        RepaintBoundary(
          key: captureKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.create(Brightness.dark),
            home: CardsScreen(controller: controller),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('add-card')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save-card')));
      await tester.pumpAndSettle();
      expect(controller.snapshot.cards.single.name, 'Debit Jago Syariah');
      expect(controller.snapshot.total.input, '1000');
      await capture(tester, 'cards-dark');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'ilustrasi keuangan menyesuaikan tema terang dan gelap tanpa overflow',
    (tester) async {
      phoneView(tester);
      await loadFonts(tester);
      for (final brightness in [Brightness.dark, Brightness.light]) {
        await tester.pumpWidget(
          RepaintBoundary(
            key: captureKey,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.create(brightness),
              home: Scaffold(
                body: const Center(
                  child: FinanceEmptyState(
                    message: 'Belum ada transaksi.',
                    kind: EmptyKind.transactions,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await capture(tester, 'finance-empty-${brightness.name}');
        expect(tester.takeException(), isNull);
      }
    },
  );
}
