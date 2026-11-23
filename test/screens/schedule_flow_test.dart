import 'package:arta/app.dart';
import 'package:arta/controllers/finance_controller.dart';
import 'package:arta/database/app_database.dart';
import 'package:arta/models/money.dart';
import 'package:arta/models/schedule.dart';
import 'package:arta/repositories/finance_repository.dart';
import 'package:arta/screens/occurrence_form.dart';
import 'package:arta/screens/schedules_screen.dart';
import 'package:arta/screens/transaction_form.dart';
import 'package:arta/services/schedule_engine.dart';
import 'package:arta/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../fixtures.dart';
import 'finance_flow_test.dart' show capture, captureKey, loadFonts;

Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'edit setelah Januari mempertahankan tanggal 31 dan status jeda',
    (tester) async {
      final db = AppDatabase.memory();
      final repo = FinanceRepository(db);
      var now = DateTime.utc(2026, 2, 1);
      await repo.addAccount(account('bank', '0'));
      await repo.saveSchedule(
        schedule(start: '2026-01-31', mode: ScheduleMode.automatic),
        processAt: now,
      );
      await repo.setScheduleState('rule', ScheduleState.paused, now);
      final controller = FinanceController(repo, clock: () => now);
      addTearDown(() async {
        controller.dispose();
        await db.close();
      });
      await controller.initialize();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.create(Brightness.dark),
          home: TransactionForm(
            controller: controller,
            replaces: controller.snapshot.schedules.single,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('save-transaction')));
      await tester.tap(find.byKey(const Key('save-transaction')));
      await tester.pumpAndSettle();
      expect(controller.snapshot.schedules, hasLength(2));
      final replacement = controller.snapshot.schedules.last;
      expect(replacement.state, ScheduleState.paused);
      expect(replacement.monthDay, 31);
      expect(replacement.dateAt(0), '2026-02-28');
      expect(replacement.dateAt(1), '2026-03-31');
      expect(controller.snapshot.transactions, hasLength(1));
      now = DateTime.utc(2026, 3, 31);
      await controller.setScheduleState(replacement.id, ScheduleState.active);
      await tester.pumpAndSettle();
      expect(controller.snapshot.transactions, hasLength(3));
      expect(controller.snapshot.total, Money.input('-18000'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'buat aturan akhir bulan dari menu; otomatis sekali dan tema mengikuti aplikasi',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await loadFonts(tester);
      var now = DateTime.utc(2026, 11, 19);
      final db = AppDatabase.memory();
      final repo = FinanceRepository(db);
      await repo.addAccount(account('bank', '0'));
      final controller = FinanceController(repo, clock: () => now);
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
      await tester.tap(find.byKey(const Key('nav-4')));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('schedules-menu')));
      await tester.tap(find.byKey(const Key('schedules-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-schedule')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Transaksi berulang').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('transaction-amount')),
        '6000',
      );
      await tester.enterText(
        find.byKey(const Key('transaction-category')),
        'Biaya bank',
      );
      await reveal(tester, find.byKey(const Key('schedule-name')));
      await tester.enterText(
        find.byKey(const Key('schedule-name')),
        'Mandiri akhir bulan',
      );
      await reveal(tester, find.byKey(const Key('schedule-end-of-month')));
      await tester.tap(find.byKey(const Key('schedule-end-of-month')));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('schedule-mode')));
      await tester.tap(find.byKey(const Key('schedule-mode')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Catat otomatis saat jatuh tempo').last);
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('save-transaction')));
      await capture(tester, 'schedule-form-dark');
      await tester.tap(find.byKey(const Key('save-transaction')));
      await tester.pumpAndSettle();
      expect(controller.snapshot.schedules, hasLength(1));
      expect(controller.snapshot.schedules.single.endOfMonth, true);
      expect(controller.snapshot.transactions, isEmpty);
      expect(tester.takeException(), isNull);
      await capture(tester, 'schedules-dark');
      await tester.tap(find.text('Mandiri akhir bulan'));
      await tester.pumpAndSettle();
      await capture(tester, 'schedule-detail-dark');
      now = DateTime.utc(2026, 11, 30);
      await controller.refreshSchedules();
      await tester.pumpAndSettle();
      await controller.refreshSchedules();
      await tester.pumpAndSettle();
      expect(controller.snapshot.transactions, hasLength(1));
      expect(controller.snapshot.total, Money.input('-6000'));
      await controller.setTheme('light');
      await tester.pumpAndSettle();
      await capture(tester, 'schedule-detail-light');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('kejadian konfirmasi dapat diubah nominalnya lalu dicatat', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    final repo = FinanceRepository(db);
    await repo.addAccount(account('bank', '0'));
    final rule = schedule(start: '2026-11-04');
    await repo.saveSchedule(rule);
    final controller = FinanceController(
      repo,
      clock: () => DateTime.utc(2026, 11, 19),
    );
    addTearDown(() async {
      controller.dispose();
      await db.close();
    });
    await controller.initialize();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.create(Brightness.dark),
        home: OccurrenceForm(
          controller: controller,
          item: PendingOccurrence(rule, 0, '2026-11-04'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('occurrence-amount')), '6500');
    await reveal(tester, find.byKey(const Key('post-occurrence')));
    await tester.tap(find.byKey(const Key('post-occurrence')));
    await tester.pumpAndSettle();
    expect(controller.snapshot.transactions.single.amount, Money.input('6500'));
    expect(controller.snapshot.schedules.single.amount, Money.input('6000'));
    expect(controller.snapshot.occurrences.single.ordinal, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'layar jadwal dan formulir cicilan mendukung font besar dan landscape',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final db = AppDatabase.memory();
      final repo = FinanceRepository(db);
      await repo.addAccount(account('bank', '0'));
      await repo.saveSchedule(
        schedule(start: '2026-11-30', installments: true, count: 3),
      );
      final controller = FinanceController(
        repo,
        clock: () => DateTime.utc(2026, 11, 19),
      );
      addTearDown(() async {
        controller.dispose();
        await db.close();
      });
      await controller.initialize();
      for (final size in [const Size(360, 800), const Size(800, 360)]) {
        tester.view.physicalSize = size;
        for (final screen in <Widget>[
          SchedulesScreen(controller: controller),
          ScheduleDetailScreen(controller: controller, id: 'rule'),
          TransactionForm(
            controller: controller,
            initialMode: EntryMode.installment,
          ),
        ]) {
          await tester.pumpWidget(
            MaterialApp(theme: AppTheme.create(Brightness.dark), home: screen),
          );
          await tester.pumpAndSettle();
          final scrollable = find.byType(Scrollable).first;
          for (var i = 0; i < 12; i++) {
            await tester.drag(scrollable, const Offset(0, -260));
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    },
  );
}
