import 'dart:async';

import 'package:arta/app.dart';
import 'package:arta/controllers/app_lock_controller.dart';
import 'package:arta/controllers/finance_controller.dart';
import 'package:arta/database/app_database.dart';
import 'package:arta/models/ledger.dart';
import 'package:arta/models/money.dart';
import 'package:arta/repositories/finance_repository.dart';
import 'package:arta/screens/account_form.dart';
import 'package:arta/screens/transaction_form.dart';
import 'package:arta/theme/app_theme.dart';
import 'package:arta/widgets/balance_card.dart';
import 'package:arta/widgets/finance_select.dart';
import 'package:arta/widgets/pin_keypad.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../fixtures.dart';
import '../fakes/fake_lock_service.dart';
import 'finance_flow_test.dart' show loadFonts, capture, captureKey;

void phone(WidgetTester tester, Size size, {double scale = 1}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
}

void resetView(WidgetTester tester) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<FinanceController> prepareDesign({AppLockController? security}) async {
  final db = AppDatabase.memory(), repo = FinanceRepository(db);
  await repo.addAccount(
    Account(
      id: 'bank',
      name: 'Mandiri',
      kind: AccountKind.bank,
      opening: Money.input('2500000'),
      createdAt: '2026-11-01T00:00:00Z',
      providerId: 'mandiri',
    ),
  );
  await repo.addAccount(
    Account(
      id: 'debit',
      name: 'Debit Jago Syariah',
      kind: AccountKind.debit,
      opening: Money.input('-300000'),
      createdAt: '2026-11-01T00:00:00Z',
      providerId: 'jago',
    ),
  );
  await repo.setPreference('market_daily_auto', 'false');
  await repo.saveTransaction(
    transaction(id: 'design-expense', amount: '35000', date: '2026-11-20'),
  );
  final c = FinanceController(
    repo,
    clock: () => DateTime.utc(2026, 11, 21),
    security: security,
  );
  await c.initialize();
  addTearDown(() async {
    c.dispose();
    await db.close();
  });
  return c;
}

void main() {
  testWidgets(
    'off-screen invalid amounts remain validated before a transfer can save',
    (tester) async {
      final c = await prepareDesign();
      resetView(tester);
      phone(tester, const Size(360, 800));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.create(Brightness.dark),
          home: TransactionForm(
            controller: c,
            initialKind: TransactionKind.transfer,
            initialDestinationId: 'debit',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('transaction-amount')),
        'bukan angka',
      );
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -900),
      );
      await tester.pumpAndSettle();
      final count = c.snapshot.transactions.length;
      await tester.tap(find.byKey(const Key('save-transaction')));
      await tester.pumpAndSettle();
      expect(c.snapshot.transactions.length, count);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'five destinations remain usable at 360 and enlarged text in both themes',
    (tester) async {
      resetView(tester);
      final c = await prepareDesign();
      for (final size in [const Size(360, 800), const Size(800, 360)]) {
        phone(tester, size, scale: 1.3);
        for (final theme in ['dark', 'light']) {
          await c.setTheme(theme);
          await tester.pumpWidget(ArtaApp(controller: c));
          await tester.pumpAndSettle();
          for (final index in [0, 2, 3, 4, 1]) {
            await tester.tap(find.byKey(Key('nav-$index')));
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '$size $theme tab $index',
            );
          }
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        }
      }
    },
  );
  testWidgets(
    'large amounts compact without losing exact accessible detail; hidden balances stay hidden',
    (tester) async {
      resetView(tester);
      phone(tester, const Size(360, 800), scale: 1.3);
      await loadFonts(tester);
      final assets = Money.input('987654321987654'),
          liabilities = Money.input('123456789123456');
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.create(brightness),
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(20),
                child: BalanceCard(assets: assets, liabilities: liabilities),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Rp 987,65 T'), findsOneWidget);
        await tester.tap(find.text('Rp 987,65 T'));
        await tester.pumpAndSettle();
        expect(find.text(assets.formatted), findsOneWidget);
        expect(find.text((assets - liabilities).formatted), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceCard(
              assets: assets,
              liabilities: liabilities,
              hidden: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('987'), findsNothing);
      expect(find.text('••••••'), findsNWidgets(3));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('DOKU selection is saved with an independent debit asset', (
    tester,
  ) async {
    final c = await prepareDesign();
    resetView(tester);
    phone(tester, const Size(412, 915));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.create(Brightness.dark),
        home: AccountForm(controller: c, initialKind: AccountKind.ewallet),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih bank / e-wallet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DOKU'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('opening-balance')), '100000');
    await tester.ensureVisible(find.byKey(const Key('save-account')));
    await tester.tap(find.byKey(const Key('save-account')));
    await tester.pumpAndSettle();
    final doku = c.snapshot.accounts.singleWhere((a) => a.providerId == 'doku');
    expect(doku.name, 'DOKU');
    expect(Account.fromJson(doku.toJson()).providerId, 'doku');
    expect(c.snapshot.balance('debit'), Money.input('-300000'));
    expect(c.snapshot.balance('bank'), Money.input('2465000'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'PIN fingerprint occupies bottom left and six digits require Continue',
    (tester) async {
      resetView(tester);
      phone(tester, const Size(383, 859));
      var fingerprints = 0;
      String? value;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.create(Brightness.dark),
          home: Scaffold(
            body: PinKeypad(
              fullPage: true,
              onBiometric: () => fingerprints++,
              onComplete: (pin) async {
                value = pin;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final finger = tester.getCenter(find.byKey(const Key('pin-fingerprint'))),
          zero = tester.getCenter(find.byKey(const Key('pin-digit-0'))),
          back = tester.getCenter(find.byKey(const Key('pin-delete')));
      expect(finger.dx, lessThan(zero.dx));
      expect(zero.dx, lessThan(back.dx));
      expect(finger.dy, zero.dy);
      await tester.tap(find.byKey(const Key('pin-fingerprint')));
      expect(fingerprints, 1);
      for (final digit in '123456'.split('')) {
        await tester.tap(find.byKey(Key('pin-digit-$digit')));
        await tester.pump();
      }
      expect(value, isNull);
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      expect(value, '123456');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'save stays above Android navigation and selectors use bottom sheets',
    (tester) async {
      final c = await prepareDesign();
      resetView(tester);
      phone(tester, const Size(360, 800));
      tester.view.padding = const FakeViewPadding(bottom: 48);
      addTearDown(tester.view.resetPadding);
      await tester.pumpWidget(ArtaApp(controller: c));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Catat transaksi'));
      await tester.pumpAndSettle();
      expect(
        tester.getBottomRight(find.byKey(const Key('save-transaction'))).dy,
        lessThanOrEqualTo(752),
      );
      await tester.tap(find.byKey(const Key('source-account')));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(FinanceSelect<String>), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'forgot PIN verifies fingerprint before opening setup; loading overlays without moving keypad',
    (tester) async {
      resetView(tester);
      phone(tester, const Size(383, 859));
      final service = FakeLockService(enabled: true);
      final security = AppLockController(service);
      await security.initialize();
      final c = await prepareDesign(security: security);
      await tester.pumpWidget(ArtaApp(controller: c));
      await tester.pumpAndSettle();
      final before = tester.getTopLeft(find.byKey(const Key('pin-digit-1')));
      service.pendingBiometric = Completer<bool>();
      await tester.tap(find.byKey(const Key('forgot-pin')));
      await tester.pump();
      expect(tester.getTopLeft(find.byKey(const Key('pin-digit-1'))), before);
      expect(security.busy, isTrue);
      service.pendingBiometric!.complete(false);
      await tester.pumpAndSettle();
      expect(security.locked, isTrue);
      expect(service.expectedPin, '123456');
      expect(find.text('Buat PIN 6 angka'), findsNothing);
      service.pendingBiometric = null;
      service.biometricResult = true;
      await tester.tap(find.byKey(const Key('forgot-pin')));
      await tester.pumpAndSettle();
      expect(find.text('Buat PIN 6 angka'), findsOneWidget);
      for (var attempt = 0; attempt < 2; attempt++) {
        for (final digit in '654321'.split('')) {
          await tester.tap(find.byKey(Key('pin-digit-$digit')));
          await tester.pump();
        }
        await tester.pumpAndSettle();
      }
      expect(service.expectedPin, '654321');
      expect(security.locked, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
  testWidgets('render reference implementation for visual review', (
    tester,
  ) async {
    final c = await prepareDesign();
    resetView(tester);
    phone(tester, const Size(412, 915));
    await loadFonts(tester);
    for (final brightness in Brightness.values) {
      await c.setTheme(brightness.name);
      await tester.pumpWidget(
        RepaintBoundary(
          key: captureKey,
          child: ArtaApp(controller: c),
        ),
      );
      await tester.pumpAndSettle();
      for (final (index, name) in [
        (0, 'home'),
        (2, 'assets'),
        (3, 'transactions'),
        (4, 'settings'),
        (1, 'portfolio'),
      ]) {
        await tester.tap(find.byKey(Key('nav-$index')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await capture(tester, 'reference-$name-${brightness.name}-0.7.0');
      }
      await tester.pumpWidget(
        RepaintBoundary(
          key: captureKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.create(brightness),
            home: Scaffold(
              body: PinKeypad(
                fullPage: true,
                onBiometric: () {},
                onComplete: (_) async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await capture(tester, 'reference-pin-${brightness.name}-0.7.0');
      await tester.pumpWidget(
        RepaintBoundary(
          key: captureKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.create(brightness),
            home: TransactionForm(
              controller: c,
              initialKind: TransactionKind.transfer,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capture(tester, 'reference-transfer-${brightness.name}-0.7.0');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });
}
