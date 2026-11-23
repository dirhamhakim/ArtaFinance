import 'package:arta/widgets/finance_dialog.dart';
import 'package:arta/app.dart';
import 'package:arta/controllers/finance_controller.dart';
import 'package:arta/database/app_database.dart';
import 'package:arta/models/ledger.dart';
import 'package:arta/models/money.dart';
import 'package:arta/models/schedule.dart';
import 'package:arta/repositories/finance_repository.dart';
import 'package:arta/screens/occurrence_form.dart';
import 'package:arta/screens/schedules_screen.dart';
import 'package:arta/screens/transaction_form.dart';
import 'package:arta/services/backup_service.dart';
import 'package:arta/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures.dart';

Future<void> reveal(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    220,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<FinanceController> prepare() async {
  final db = AppDatabase.memory();
  final repo = FinanceRepository(db);
  await repo.addAccount(account('bank', '1000'));
  await repo.addAccount(account('wallet', '0'));
  final controller = FinanceController(
    repo,
    clock: () => DateTime.utc(2026, 11, 19),
  );
  addTearDown(() async {
    controller.dispose();
    await db.close();
  });
  await controller.initialize();
  return controller;
}

Future<void> openForm(WidgetTester tester, Widget form) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.create(Brightness.dark),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => form),
            ),
            child: const Text('Buka'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Buka'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('transfer baru tanpa biaya menyembunyikan field biaya', (
    tester,
  ) async {
    final controller = await prepare();
    await openForm(tester, TransactionForm(controller: controller));
    await tester.tap(find.text('Pengeluaran').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transfer').last);
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('fee-enabled')));
    expect(
      tester.widget<SwitchListTile>(find.byKey(const Key('fee-enabled'))).value,
      isFalse,
    );
    expect(find.byKey(const Key('fee-amount')), findsNothing);
    await tester.tap(find.byKey(const Key('fee-enabled')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('fee-amount')));
    expect(find.byKey(const Key('fee-amount')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'mematikan biaya saat edit tidak memakai draft atau mengubah nominal transfer',
    (tester) async {
      final controller = await prepare();
      await controller.repository.saveTransaction(
        transaction(
          kind: TransactionKind.transfer,
          destination: 'wallet',
          amount: '100',
          fee: '5',
        ),
      );
      await controller.initialize();
      await openForm(
        tester,
        TransactionForm(
          controller: controller,
          existing: controller.snapshot.transactions.single,
        ),
      );
      await reveal(tester, find.byKey(const Key('fee-amount')));
      expect(
        tester
            .widget<SwitchListTile>(find.byKey(const Key('fee-enabled')))
            .value,
        isTrue,
      );
      await tester.enterText(find.byKey(const Key('fee-amount')), '-999');
      await reveal(tester, find.byKey(const Key('fee-enabled')));
      await tester.tap(find.byKey(const Key('fee-enabled')));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('save-transaction')));
      await tester.tap(find.byKey(const Key('save-transaction')));
      await tester.pumpAndSettle();
      expect(controller.snapshot.transactions, hasLength(1));
      expect(controller.snapshot.transactions.single.fee, Money.zero);
      expect(controller.snapshot.balance('bank'), Money.input('900'));
      expect(controller.snapshot.balance('wallet'), Money.input('100'));
      expect(controller.snapshot.expenseForMonth('2026-11'), Money.zero);
      expect(tester.takeException(), isNull);
      // Aktifkan lagi dan pastikan biaya benar-benar dipotong satu kali.
      await openForm(
        tester,
        TransactionForm(
          controller: controller,
          existing: controller.snapshot.transactions.single,
        ),
      );
      await reveal(tester, find.byKey(const Key('fee-enabled')));
      await tester.tap(find.byKey(const Key('fee-enabled')));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('fee-amount')));
      await tester.enterText(find.byKey(const Key('fee-amount')), '2,50');
      await reveal(tester, find.byKey(const Key('save-transaction')));
      await tester.tap(find.byKey(const Key('save-transaction')));
      await tester.pumpAndSettle();
      expect(controller.snapshot.transactions, hasLength(1));
      expect(controller.snapshot.total, Money.input('997,50'));
      expect(
        controller.snapshot.expenseForMonth('2026-11'),
        Money.input('2,50'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('toggle biaya pada perubahan jadwal berlaku untuk jadwal baru', (
    tester,
  ) async {
    final controller = await prepare();
    final rule = schedule(
      kind: TransactionKind.transfer,
      destination: 'wallet',
      start: '2027-01-01',
      fee: '5',
    );
    await controller.saveSchedule(rule);
    await openForm(
      tester,
      TransactionForm(controller: controller, replaces: rule),
    );
    await reveal(tester, find.byKey(const Key('fee-enabled')));
    await tester.tap(find.byKey(const Key('fee-enabled')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('save-transaction')));
    await tester.tap(find.byKey(const Key('save-transaction')));
    await tester.pumpAndSettle();
    expect(controller.snapshot.schedules, hasLength(2));
    expect(
      controller.snapshot.schedules
          .singleWhere((s) => s.state == ScheduleState.active)
          .fee,
      Money.zero,
    );
    expect(controller.snapshot.transactions, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('biaya aktual nol hanya mengubah satu kejadian', (tester) async {
    final controller = await prepare();
    await controller.saveSchedule(
      schedule(
        kind: TransactionKind.transfer,
        destination: 'wallet',
        start: '2026-11-19',
        amount: '100',
        fee: '5',
      ),
    );
    await openForm(
      tester,
      OccurrenceForm(controller: controller, item: controller.due.single),
    );
    await reveal(tester, find.byKey(const Key('fee-enabled')));
    await tester.tap(find.byKey(const Key('fee-enabled')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('post-occurrence')));
    await tester.tap(find.byKey(const Key('post-occurrence')));
    await tester.pumpAndSettle();
    expect(controller.snapshot.transactions.single.fee, Money.zero);
    expect(controller.snapshot.schedules.single.fee, Money.input('5'));
    expect(controller.snapshot.total, Money.input('1000'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'sandi dan konfirmasi punya mata terpisah dan kembali tersembunyi',
    (tester) async {
      final controller = await prepare();
      await tester.pumpWidget(ArtaApp(controller: controller));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-4')));
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Backup terenkripsi'));
      await tester.tap(find.text('Backup terenkripsi'));
      // Loading di belakang dialog berjalan terus selama operasi backup.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final fields = find.descendant(
        of: find.byType(FinanceDialog),
        matching: find.byType(TextField),
      );
      expect(fields, findsNWidgets(2));
      await tester.enterText(fields.first, 'Rahasia123');
      expect(tester.widget<TextField>(fields.first).obscureText, isTrue);
      await tester.tap(find.byTooltip('Tampilkan kata sandi'));
      await tester.pump();
      expect(tester.widget<TextField>(fields.first).obscureText, isFalse);
      expect(tester.widget<TextField>(fields.last).obscureText, isTrue);
      expect(
        tester.widget<TextField>(fields.first).controller!.text,
        'Rahasia123',
      );
      await tester.tap(find.byTooltip('Tampilkan ulangi kata sandi'));
      await tester.pump();
      expect(tester.widget<TextField>(fields.last).obscureText, isFalse);
      await tester.tap(find.byTooltip('Sembunyikan kata sandi'));
      await tester.pump();
      expect(tester.widget<TextField>(fields.first).obscureText, isTrue);
      await tester.tap(find.text('Batal'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Backup terenkripsi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.widget<TextField>(fields.first).obscureText, isTrue);
      expect(tester.widget<TextField>(fields.first).controller!.text, isEmpty);
      await tester.tap(find.text('Batal'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'mata menyamarkan saldo, transaksi dan grafik serta tersimpan setelah muat ulang',
    (tester) async {
      final controller = await prepare();
      final tx = transaction(amount: '123,45');
      await controller.repository.saveTransaction(tx);
      await controller.initialize();
      await tester.pumpWidget(ArtaApp(controller: controller));
      await tester.pumpAndSettle();
      expect(find.text(controller.snapshot.netWorth.formatted), findsWidgets);
      await tester.tap(find.byKey(const Key('toggle-amounts')));
      await tester.pumpAndSettle();
      expect(controller.amountsHidden, isTrue);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text(controller.snapshot.total.formatted), findsNothing);
      expect(find.text('••••••'), findsWidgets);
      await tester.tap(find.byKey(const Key('nav-3')));
      await tester.pumpAndSettle();
      expect(find.text(tx.amount.formatted), findsNothing);
      expect(find.text('••••••'), findsOneWidget);
      final reloaded = FinanceController(controller.repository);
      addTearDown(reloaded.dispose);
      await reloaded.initialize();
      expect(reloaded.amountsHidden, isTrue);
      // Restore tidak boleh membuka nominal yang sedang disembunyikan.
      final backup = await BackupService().decode(
        BackupService().encode(controller.snapshot),
      );
      await controller.restore(backup);
      await tester.pumpAndSettle();
      expect(controller.amountsHidden, isTrue);
      await tester.tap(find.byKey(const Key('nav-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('toggle-amounts')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-3')));
      await tester.pumpAndSettle();
      expect(find.text((-tx.amount).formatted), findsOneWidget);
      expect(controller.snapshot.transactions.single.amount, tx.amount);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'nominal jadwal disamarkan dan database baru memakai preferensi awal',
    (tester) async {
      final controller = await prepare();
      expect(controller.amountsHidden, isFalse);
      await controller.saveSchedule(schedule(start: '2026-11-19'));
      await controller.setAmountsHidden(true);
      await tester.pumpWidget(
        MaterialApp(home: SchedulesScreen(controller: controller)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Rp'), findsNothing);
      await tester.pumpWidget(
        MaterialApp(
          home: ScheduleDetailScreen(controller: controller, id: 'rule'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Rp'), findsNothing);
      expect(find.text('••••••'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
