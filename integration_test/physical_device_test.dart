import 'dart:convert';
import 'dart:io';

import 'package:arta/app.dart';
import 'package:arta/controllers/finance_controller.dart';
import 'package:arta/database/app_database.dart';
import 'package:arta/main.dart';
import 'package:arta/models/ledger.dart';
import 'package:arta/models/money.dart';
import 'package:arta/models/schedule.dart';
import 'package:arta/models/investment.dart';
import 'package:arta/models/decimal.dart';
import 'package:arta/models/interest.dart';
import 'package:arta/services/analytics_service.dart';
import 'package:arta/services/interest_engine.dart';
import 'package:arta/services/transaction_category_service.dart';
import 'package:arta/repositories/finance_repository.dart';
import 'package:arta/screens/transaction_form.dart';
import 'package:arta/screens/investment_form.dart';
import 'package:arta/screens/staking_screen.dart';
import 'package:arta/screens/interest_screen.dart';
import 'package:arta/services/backup_service.dart';
import 'package:arta/services/local_storage_service.dart';
import 'package:arta/services/schedule_engine.dart';
import 'package:arta/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

import '../test/fixtures.dart';

// Real Android plugins and file-backed SQLite. Production arta.sqlite is never
// opened by this suite; all mutations stay inside a new device-qa/run folder.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final results = <Map<String, Object?>>[];
  late Directory directory;
  late AppDatabase db;
  late FinanceRepository repo;
  late FinanceController controller;
  var index = 0;
  final now = DateTime.utc(2026, 11, 19, 5);

  setUpAll(() async {
    final location = await LocalStorageService().databaseFile();
    directory = Directory(
      p.join(
        location.parent.path,
        'device-qa',
        DateTime.now().millisecondsSinceEpoch.toString(),
      ),
    );
    await directory.create(recursive: true);
  });
  setUp(() async {
    db = AppDatabase.file(
      File(p.join(directory.path, 'case-${index++}.sqlite')),
    );
    repo = FinanceRepository(db);
    controller = FinanceController(repo, clock: () => now);
    await controller.initialize();
  });
  tearDown(() async {
    for (var attempt = 0; controller.busy && attempt < 200; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    controller.dispose();
    await db.close();
  });
  tearDownAll(() async {
    await File(p.join(directory.path, 'results.json'))
        .writeAsString(const JsonEncoder.withIndent('  ').convert(results));
    binding.reportData = {'results': results, 'directory': directory.path};
  });

  void passed(String id, String scope, String actual) {
    results.add({'id': id, 'scope': scope, 'status': 'PASS', 'actual': actual});
    // Visible both in the host test transcript and the application's logcat.
    // ignore: avoid_print
    print('ARTA_DEVICE_QA ${jsonEncode(results.last)}');
  }

  Future<void> reveal(WidgetTester tester, Finder target) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      target,
      260,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 30,
    );
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
  }

  Future<void> idle(WidgetTester tester) async {
    // pumpAndSettle only waits for frames. SQLite runs on a real background
    // isolate, so a save can still be in flight when animations have settled.
    for (var attempt = 0; controller.busy && attempt < 100; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(
      controller.busy,
      false,
      reason: 'Native database operation timed out',
    );
    await tester.pumpAndSettle();
  }

  Future<void> accounts() async {
    for (final pair in [
      ['bank', '100000'],
      ['wallet', '0'],
      ['minus', '-1000'],
      ['schedule', '0'],
      ['installment', '0'],
    ]) {
      await repo.addAccount(account(pair[0], pair[1]));
    }
    await controller.initialize();
  }

  Future<void> openRoute(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.create(Brightness.dark),
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => page),
              ),
              child: const Text('QA Buka'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('QA Buka'));
    await tester.pumpAndSettle();
  }

  testWidgets('P01 real Android directory, bootstrap and SQLite reopen', (
    tester,
  ) async {
    final file = File(p.join(directory.path, 'bootstrap.sqlite'));
    await tester.pumpWidget(BootstrapScreen(databaseFile: () async => file));
    await tester.pumpAndSettle();
    // Native opening is asynchronous; pump until either the main app or error.
    for (
      var attempt = 0;
      attempt < 60 && find.byType(ArtaApp).evaluate().isEmpty;
      attempt++
    ) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(ArtaApp), findsOneWidget);
    expect(find.text('Penyimpanan lokal belum dapat dibuka.'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await repo.addAccount(account('persist', '-1000'));
    await repo.saveTransaction(transaction(source: 'persist', amount: '100'));
    await db.close();
    db = AppDatabase.file(File(p.join(directory.path, 'case-0.sqlite')));
    repo = FinanceRepository(db);
    expect((await repo.load()).balance('persist'), Money.input('-1100'));
    passed(
      'P01',
      'Android + UI + SQLite',
      'Real directory and bootstrap open; negative balance and transaction survive file close/reopen.',
    );
  });

  testWidgets('P02 device UI creates negative account and validates form', (
    tester,
  ) async {
    await tester.pumpWidget(ArtaApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah aset pertama'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-account')));
    await tester.pumpAndSettle();
    expect(find.text('Isi nama aset.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('account-name')),
      'QA Device Minus',
    );
    await tester.enterText(find.byKey(const Key('opening-balance')), '-1000');
    await reveal(tester, find.byKey(const Key('save-account')));
    await tester.tap(find.byKey(const Key('save-account')));
    await idle(tester);
    expect(controller.snapshot.total, Money.input('-1000'));
    expect(controller.snapshot.transactions, isEmpty);
    await tester.tap(find.byTooltip('Catat transaksi'));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('save-transaction')));
    await tester.tap(find.byKey(const Key('save-transaction')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('transaction-category')));
    expect(find.text('Isi kategori.'), findsOneWidget);
    await reveal(tester, find.byKey(const Key('transaction-amount')));
    await tester.enterText(find.byKey(const Key('transaction-amount')), '0');
    await tester.enterText(
      find.byKey(const Key('transaction-category')),
      'QA Belanja',
    );
    await reveal(tester, find.byKey(const Key('save-transaction')));
    await tester.tap(find.byKey(const Key('save-transaction')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('transaction-amount')));
    expect(find.text('Nominal harus lebih dari 0.'), findsOneWidget);
    await reveal(tester, find.byKey(const Key('transaction-amount')));
    await tester.enterText(find.byKey(const Key('transaction-amount')), '5500');
    await reveal(tester, find.byKey(const Key('save-transaction')));
    await tester.tap(find.byKey(const Key('save-transaction')));
    await idle(tester);
    expect(controller.snapshot.total, Money.input('-6500'));
    expect(controller.snapshot.transactions, hasLength(1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    passed(
      'P02',
      'Android UI + SQLite',
      'Blank account rejected; -1000 account saved; zero expense rejected; expense 5500 yields exactly -6500.',
    );
  });

  testWidgets(
    'P03 financial ledger, transfer fees, edit, delete and decimals',
    (tester) async {
      await accounts();
      await repo.saveTransaction(transaction(id: 'expense', amount: '150000'));
      expect((await repo.load()).balance('bank'), Money.input('-50000'));
      await repo.saveTransaction(
        transaction(
          id: 'income',
          kind: TransactionKind.income,
          amount: '20000',
        ),
      );
      expect((await repo.load()).balance('bank'), Money.input('-30000'));
      await repo.saveTransaction(
        transaction(
          id: 'transfer',
          kind: TransactionKind.transfer,
          destination: 'wallet',
          amount: '5000',
          fee: '1000',
        ),
      );
      var data = await repo.load();
      expect(data.balance('bank'), Money.input('-36000'));
      expect(data.balance('wallet'), Money.input('5000'));
      await repo.saveTransaction(
        transaction(id: 'expense', amount: '100000'),
        edit: true,
      );
      expect((await repo.load()).balance('bank'), Money.input('14000'));
      await repo.deleteTransaction('expense');
      expect((await repo.load()).balance('bank'), Money.input('114000'));
      for (final entry in [
        ('d1', TransactionKind.income, '0,10', '-999,90'),
        ('d2', TransactionKind.income, '0,20', '-999,70'),
        ('d3', TransactionKind.expense, '0,30', '-1000'),
      ]) {
        await repo.saveTransaction(
          transaction(
            id: entry.$1,
            kind: entry.$2,
            source: 'minus',
            amount: entry.$3,
          ),
        );
        expect((await repo.load()).balance('minus'), Money.input(entry.$4));
      }
      data = await repo.load();
      expect(data.incomeForMonth('2026-11'), Money.input('20000,30'));
      expect(data.expenseForMonth('2026-11'), Money.input('1000,30'));
      for (final amount in ['0', '-1']) {
        await expectLater(
          repo.saveTransaction(transaction(id: 'bad', amount: amount)),
          throwsFormatException,
        );
      }
      await expectLater(
        repo.saveTransaction(
          transaction(
            id: 'bad',
            kind: TransactionKind.transfer,
            destination: 'bank',
          ),
        ),
        throwsFormatException,
      );
      await expectLater(
        repo.saveTransaction(
          transaction(
            id: 'bad',
            kind: TransactionKind.transfer,
            destination: 'wallet',
            fee: '-1',
          ),
        ),
        throwsFormatException,
      );
      expect((await repo.load()).transactions, hasLength(5));
      await controller.initialize();
      await tester.pumpWidget(ArtaApp(controller: controller));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-3')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('transaction-search')),
        'wallet',
      );
      await tester.pumpAndSettle();
      expect(find.text('Biaya bank'), findsNothing);
      await tester.enterText(
        find.byKey(const Key('transaction-search')),
        'no-match-QA',
      );
      await tester.pumpAndSettle();
      expect(find.text('Tidak ada transaksi yang cocok.'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('transaction-search')), '');
      await tester.pumpAndSettle();
      expect(find.text('Tidak ada transaksi yang cocok.'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      passed(
        'P03',
        'Native SQLite + search UI',
        'Bank 114000, wallet 5000, minus -1000; 5 transactions; monthly income 20000.30 and expense 1000.30; invalid transfer/fee rejected.',
      );
    },
  );

  testWidgets('P04 recurring Mandiri, confirmation, skip, deleted tombstone', (
    tester,
  ) async {
    await repo.addAccount(account('bank', '0'));
    await repo.saveSchedule(
      schedule(
        id: 'day4',
        start: '2024-01-04',
        amount: '5500',
        count: 3,
        mode: ScheduleMode.automatic,
      ),
      processAt: now,
    );
    await repo.saveSchedule(
      schedule(
        id: 'eom',
        start: '2024-01-04',
        amount: '6000',
        endOfMonth: true,
        count: 3,
        mode: ScheduleMode.automatic,
      ),
      processAt: now,
    );
    var data = await repo.load();
    expect(data.transactions, hasLength(6));
    expect(data.balance('bank'), Money.input('-34500'));
    expect(data.transactions.map((t) => t.date).toSet(), {
      '2024-01-04',
      '2024-02-04',
      '2024-03-04',
      '2024-01-31',
      '2024-02-29',
      '2024-03-31',
    });
    await repo.processAutomatic(now);
    await repo.processAutomatic(now);
    expect((await repo.load()).transactions, hasLength(6));
    await repo.saveSchedule(
      schedule(id: 'confirm', start: '2024-04-10', amount: '7000', count: 1),
      processAt: now,
    );
    expect((await repo.load()).balance('bank'), Money.input('-34500'));
    final attempts = await Future.wait([
      repo.resolveOccurrence(
        'confirm',
        0,
        now,
        amount: Money.input('7500'),
        date: '2024-04-11',
      ),
      repo.resolveOccurrence(
        'confirm',
        0,
        now,
        amount: Money.input('7500'),
        date: '2024-04-11',
      ),
    ]);
    expect(attempts.where((v) => v), hasLength(1));
    data = await repo.load();
    expect(data.balance('bank'), Money.input('-42000'));
    final occurrence = data.occurrences.singleWhere(
      (o) => o.scheduleId == 'confirm',
    );
    expect(occurrence.dueDate, '2024-04-10');
    expect(
      data.transactions
          .singleWhere((t) => t.id == occurrence.transactionId)
          .date,
      '2024-04-11',
    );
    expect(
      data.schedules.singleWhere((s) => s.id == 'confirm').amount,
      Money.input('7000'),
    );
    await repo.saveSchedule(
      schedule(id: 'skip', start: '2024-05-01', amount: '8000', count: 1),
    );
    await repo.resolveOccurrence('skip', 0, now, skip: true);
    data = await repo.load();
    expect(data.balance('bank'), Money.input('-42000'));
    final january = data.occurrences.singleWhere(
      (o) => o.scheduleId == 'day4' && o.ordinal == 0,
    );
    await repo.deleteTransaction(january.transactionId!);
    await repo.processAutomatic(now);
    data = await repo.load();
    expect(data.balance('bank'), Money.input('-36500'));
    expect(
      data.occurrences
          .singleWhere((o) => o.scheduleId == 'day4' && o.ordinal == 0)
          .state,
      OccurrenceState.deleted,
    );
    expect(await repo.resolveOccurrence('day4', 0, now), false);
    passed(
      'P04',
      'Native SQLite + scheduler',
      'Six Mandiri dates including leap day; refresh no duplicates; concurrent confirmation posts once; actual/due dates separate; skip and delete stay resolved.',
    );
  });

  testWidgets('P05 pause, edit anchor, resume policies, stop and calendar', (
    tester,
  ) async {
    await repo.addAccount(account('bank', '0'));
    await repo.saveSchedule(
      schedule(id: 'old', start: '2025-01-31', amount: '9000', count: 3),
    );
    await repo.resolveOccurrence('old', 0, now);
    await repo.setScheduleState('old', ScheduleState.paused, now);
    await repo.saveSchedule(
      schedule(
        id: 'new',
        start: '2025-02-28',
        monthDay: 31,
        amount: '10000',
        count: 2,
        mode: ScheduleMode.automatic,
        state: ScheduleState.paused,
      ),
      replacesId: 'old',
      replacesResolvedCount: 1,
      processAt: now,
    );
    var data = await repo.load();
    expect(data.balance('bank'), Money.input('-9000'));
    expect(data.schedules.last.state, ScheduleState.paused);
    expect(data.schedules.first.state, ScheduleState.stopped);
    await repo.setScheduleState('new', ScheduleState.active, now);
    data = await repo.load();
    expect(data.balance('bank'), Money.input('-29000'));
    expect(data.transactions.map((t) => t.date).toSet(), {
      '2025-01-31',
      '2025-02-28',
      '2025-03-31',
    });
    await repo.saveSchedule(
      schedule(
        id: 'daily',
        start: '2026-11-18',
        count: 2,
        frequency: RepeatFrequency.daily,
      ),
    );
    await repo.setScheduleState('daily', ScheduleState.paused, now);
    await repo.setScheduleState(
      'daily',
      ScheduleState.active,
      now,
      skipMissed: true,
    );
    data = await repo.load();
    expect(
      data.occurrences.singleWhere((o) => o.scheduleId == 'daily').state,
      OccurrenceState.skipped,
    );
    expect(ScheduleEngine.due(data, now).single.date, '2026-11-19');
    await repo.setScheduleState('daily', ScheduleState.stopped, now);
    await expectLater(
      repo.setScheduleState('daily', ScheduleState.active, now),
      throwsFormatException,
    );
    expect((await repo.load()).balance('bank'), Money.input('-29000'));
    final rules = [
      schedule(id: 'interval', start: '2024-01-31', interval: 2, count: 3),
      schedule(
        id: 'weekly',
        start: '2024-12-23',
        frequency: RepeatFrequency.weekly,
        interval: 2,
        count: 3,
      ),
      schedule(
        id: 'annual',
        start: '2024-02-29',
        frequency: RepeatFrequency.yearly,
        count: 5,
      ),
      schedule(
        id: 'end',
        start: '2024-02-28',
        frequency: RepeatFrequency.daily,
        end: '2024-03-01',
      ),
    ];
    final dates = [
      ['2024-01-31', '2024-03-31', '2024-05-31'],
      ['2024-12-23', '2025-01-06', '2025-01-20'],
      ['2024-02-29', '2025-02-28', '2026-02-28', '2027-02-28', '2028-02-29'],
      ['2024-02-28', '2024-02-29', '2024-03-01'],
    ];
    for (var i = 0; i < rules.length; i++) {
      await repo.saveSchedule(rules[i]);
      expect([
        for (var n = 0; n < dates[i].length; n++) rules[i].dateAt(n),
      ], dates[i]);
      expect(rules[i].dateAt(dates[i].length), isNull);
    }
    await repo.saveSchedule(
      schedule(
        id: 'zone',
        start: '2026-11-20',
        zone: 'Asia/Makassar',
        count: 1,
      ),
    );
    expect((await repo.load()).schedules.last.zone, 'Asia/Makassar');
    await expectLater(
      repo.saveSchedule(schedule(id: 'bad', interval: 0)),
      throwsFormatException,
    );
    await expectLater(
      repo.saveSchedule(schedule(id: 'bad', count: 0)),
      throwsFormatException,
    );
    final boundary = DateTime.parse('2026-11-03T16:30:00Z');
    expect(schedule(start: '2026-11-04').today(boundary), '2026-11-03');
    expect(
      schedule(start: '2026-11-04', zone: 'Asia/Jayapura').today(boundary),
      '2026-11-04',
    );
    passed(
      'P05',
      'Native SQLite + scheduler',
      'Paused edit preserves state and day-31 anchor; resume catches up exactly; skip-before-today and stop work; interval/week/leap-year/end-date/WITA persist and invalid rules rejected.',
    );
  });

  testWidgets(
    'P06 installment total, actual amounts, skip and deleted history',
    (tester) async {
      await repo.addAccount(account('bank', '0'));
      await repo.saveSchedule(
        schedule(
          id: 'auto',
          start: '2024-01-31',
          amount: '100',
          count: 3,
          installments: true,
          mode: ScheduleMode.automatic,
        ),
        processAt: now,
      );
      var data = await repo.load();
      final sorted = data.transactions.toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      expect(sorted.map((t) => t.amount.input), ['33,33', '33,33', '33,34']);
      expect(sorted.map((t) => t.date), [
        '2024-01-31',
        '2024-02-29',
        '2024-03-31',
      ]);
      expect(data.balance('bank'), Money.input('-100'));
      final manual = schedule(
        id: 'actual',
        start: '2025-01-31',
        amount: '100',
        count: 3,
        installments: true,
      );
      await repo.saveSchedule(manual);
      await repo.resolveOccurrence('actual', 0, now, amount: Money.input('30'));
      data = await repo.load();
      expect(data.balance('bank'), Money.input('-130'));
      expect(data.remainingForSchedule(manual), Money.input('66,67'));
      await repo.resolveOccurrence('actual', 1, now, skip: true);
      expect(
        (await repo.load()).remainingForSchedule(manual),
        Money.input('33,34'),
      );
      await repo.resolveOccurrence('actual', 2, now);
      data = await repo.load();
      expect(data.balance('bank'), Money.input('-163,34'));
      expect(data.actualExpenseForSchedule('actual'), Money.input('63,34'));
      final first = data.occurrences.singleWhere(
        (o) => o.scheduleId == 'actual' && o.ordinal == 0,
      );
      await repo.deleteTransaction(first.transactionId!);
      await repo.processAutomatic(now);
      data = await repo.load();
      expect(data.balance('bank'), Money.input('-133,34'));
      expect(data.actualExpenseForSchedule('actual'), Money.input('33,34'));
      expect(data.remainingForSchedule(manual), Money.zero);
      expect(
        data.occurrences
            .where((o) => o.scheduleId == 'actual')
            .map((o) => o.state),
        [
          OccurrenceState.deleted,
          OccurrenceState.skipped,
          OccurrenceState.posted,
        ],
      );
      passed(
        'P06',
        'Native SQLite + installment accounting',
        '100 splits 33.33/33.33/33.34; actual30 + skip + actual33.34 then delete30 gives final -133.34 including prior auto plan; history is deleted/skipped/posted.',
      );
    },
  );

  testWidgets('P07 native backup, encrypted wrong password, rejection and v1', (
    tester,
  ) async {
    await accounts();
    await repo.saveSchedule(
      schedule(
        id: 'auto',
        source: 'schedule',
        amount: '100',
        count: 3,
        installments: true,
        mode: ScheduleMode.automatic,
      ),
      processAt: now,
    );
    await repo.saveSchedule(schedule(id: 'skip', source: 'schedule', count: 1));
    await repo.resolveOccurrence('skip', 0, now, skip: true);
    var data = await repo.load();
    final deleted = data.occurrences.firstWhere((o) => o.scheduleId == 'auto');
    await repo.deleteTransaction(deleted.transactionId!);
    await repo.setTheme('light');
    data = await repo.load();
    final service = BackupService();
    final plain = await exportBackupInBackground(data);
    await File(p.join(directory.path, 'qa-complete.json')).writeAsBytes(plain);
    final imported = await importBackupInBackground(plain);
    await repo.saveTransaction(
      transaction(
        id: 'marker',
        kind: TransactionKind.income,
        source: 'wallet',
        amount: '1',
      ),
    );
    await repo.replace(imported, processAt: now);
    var restored = await repo.load();
    expect(
      utf8
          .decode(service.encode(restored))
          .replaceAll(RegExp(r'"created_at":"[^"]*"'), ''),
      utf8
          .decode(service.encode(data))
          .replaceAll(RegExp(r'"created_at":"[^"]*"'), ''),
    );
    final encrypted = await exportBackupInBackground(
      data,
      password: 'ArtaUji2026!',
    );
    await File(p.join(directory.path, 'qa-encrypted.json'))
        .writeAsBytes(encrypted);
    await expectLater(
      importBackupInBackground(encrypted, password: 'wrong'),
      throwsFormatException,
    );
    expect((await repo.load()).balance('wallet'), Money.zero);
    await repo.replace(
      await importBackupInBackground(encrypted, password: 'ArtaUji2026!'),
      processAt: now,
    );
    for (final bytes in [
      Uint8List.fromList(utf8.encode('{broken')),
      Uint8List.fromList(
        utf8.encode('{"format":"arta-backup","schema_version":999}'),
      ),
    ]) {
      await expectLater(importBackupInBackground(bytes), throwsFormatException);
    }
    final legacy = Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'format': 'arta-backup',
          'schema_version': 1,
          'created_at': '2026-11-19T00:00:00Z',
          'accounts': [account('legacy', '-1000').toJson()],
          'transactions': [
            transaction(source: 'legacy', amount: '100').toJson(),
          ],
          'preferences': {'theme': 'light'},
        }),
      ),
    );
    await repo.replace(await importBackupInBackground(legacy), processAt: now);
    restored = await repo.load();
    expect(restored.balance('legacy'), Money.input('-1100'));
    expect(restored.schedules, isEmpty);
    await repo.replace(imported, processAt: now);
    restored = await repo.load();
    expect(
      restored.occurrences.map((o) => o.toJson()),
      data.occurrences.map((o) => o.toJson()),
    );
    expect(
      restored.transactions.map((t) => t.toJson()),
      data.transactions.map((t) => t.toJson()),
    );
    expect(restored.theme, 'light');
    passed(
      'P07',
      'Native Android file + background isolate + SQLite',
      'Plain/encrypted snapshots restored exactly including skipped/deleted history; wrong password and malformed/unsupported JSON rejected; v1 -1100 and return to full v2 succeed. Android document picker is tested separately.',
    );
  }, timeout: const Timeout(Duration(minutes: 10)));

  testWidgets('P08 recurring form, themes and landscape', (tester) async {
    await repo.addAccount(account('bank', '0'));
    await controller.initialize();
    await tester.pumpWidget(ArtaApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-4')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('schedules-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-schedule')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transaksi berulang').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('transaction-amount')), '6000');
    await tester.enterText(
      find.byKey(const Key('transaction-category')),
      'QA Biaya bank',
    );
    await reveal(tester, find.byKey(const Key('schedule-name')));
    await tester.enterText(
      find.byKey(const Key('schedule-name')),
      'QA Device akhir bulan',
    );
    await reveal(tester, find.byKey(const Key('schedule-end-of-month')));
    await tester.tap(find.byKey(const Key('schedule-end-of-month')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('schedule-count')));
    await tester.enterText(find.byKey(const Key('schedule-count')), '3');
    await reveal(tester, find.byKey(const Key('save-transaction')));
    await tester.tap(find.byKey(const Key('save-transaction')));
    await idle(tester);
    expect(controller.snapshot.schedules, hasLength(1));
    expect(controller.snapshot.schedules.single.endOfMonth, true);
    expect(controller.snapshot.transactions, isEmpty);
    await tester.tap(find.text('QA Device akhir bulan'));
    await tester.pumpAndSettle();
    for (final theme in ['light', 'dark', 'system']) {
      expect(await controller.setTheme(theme), true);
      await tester.pumpAndSettle();
      expect(controller.snapshot.theme, theme);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
    ]);
    await tester.pump(const Duration(seconds: 2));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.create(Brightness.dark),
        home: TransactionForm(
          controller: controller,
          initialMode: EntryMode.installment,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('save-transaction')));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    await SystemChrome.setPreferredOrientations([]);
    passed(
      'P08',
      'Android UI + orientation',
      'Created end-of-month rule using form; detail themes light/dark/system; long installment form save reachable in landscape with simulated text scale 2. No transaction saved by preview.',
    );
  });

  testWidgets(
    'P09 native category picker and independent income expense drafts',
    (tester) async {
      await repo.addAccount(account('bank', '100000'));
      await controller.initialize();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.create(Brightness.dark),
          home: TransactionForm(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('choose-transaction-category')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('category-search')), 'Makan');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Makan & Minum'));
      await tester.pumpAndSettle();
      TextFormField category() => tester.widget<TextFormField>(
        find.byKey(const Key('transaction-category')),
      );
      expect(category().controller!.text, 'Makan & Minum');
      await tester.tap(find.text('Pemasukan'));
      await tester.pumpAndSettle();
      expect(category().controller!.text, isEmpty);
      await tester.tap(find.byKey(const Key('choose-transaction-category')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('category-search')),
        'QA Royalti',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gunakan "QA Royalti"'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pengeluaran'));
      await tester.pumpAndSettle();
      expect(category().controller!.text, 'Makan & Minum');
      await tester.tap(find.text('Pemasukan'));
      await tester.pumpAndSettle();
      expect(category().controller!.text, 'QA Royalti');
      await tester.enterText(
        find.byKey(const Key('transaction-amount')),
        '1000',
      );
      await tester.tap(find.byKey(const Key('save-transaction')));
      await idle(tester);
      expect(controller.snapshot.transactions.single.category, 'QA Royalti');
      expect(controller.snapshot.balance('bank'), Money.input('101000'));
      final reopened = await repo.load();
      expect(
        TransactionCategoryService.options(reopened, TransactionKind.income),
        contains('QA Royalti'),
      );
      expect(
        TransactionCategoryService.options(reopened, TransactionKind.expense),
        isNot(contains('QA Royalti')),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      passed(
        'P09',
        'Android UI + native SQLite',
        'Default picker/custom search, independent drafts, native save, exact balance and reused custom category.',
      );
    },
  );

  testWidgets('P10 full demo backup native restore charts staking and reopen', (
    tester,
  ) async {
    final location = await LocalStorageService().databaseFile();
    final file = File(p.join(location.parent.path, 'qa-demo.json'));
    expect(
      await file.exists(),
      isTrue,
      reason: 'Host must provision the public demo fixture before this suite.',
    );
    final backup = BackupService();
    final bytes = await file.readAsBytes();
    final demo = await backup.decode(bytes);
    final watch = Stopwatch()..start();
    await repo.setPreference('market_daily_auto', 'false');
    await repo.setAmountsHidden(true);
    await repo.replace(demo, processAt: DateTime.utc(2026, 11, 21, 5));
    final restored = await repo.load();
    expect(restored.accounts, hasLength(22));
    expect(restored.transactions, hasLength(202));
    expect(restored.extras.events, hasLength(46));
    expect(restored.extras.quotes, hasLength(2998));
    expect(restored.schedules, hasLength(18));
    expect(restored.occurrences, hasLength(17));
    expect(restored.extras.stakingPlans, hasLength(3));
    expect(restored.extras.interestPostings, hasLength(26));
    expect(restored.cards, hasLength(1));
    expect(await repo.preference('market_daily_auto'), 'false');
    expect(await repo.amountsHidden(), isTrue);
    for (final a in demo.accounts) {
      expect(restored.balance(a.id), demo.balance(a.id));
    }
    expect(restored.balance('debit'), Money.input('1970500'));
    final staking = replayPortfolio(restored.extras.events).staking;
    expect(staking['stake-eth']!.pending, Decimal.parse('0.0039'));
    expect(staking['stake-sol']!.staked, Decimal.parse('1.495'));
    expect(staking['stake-hype']!.locked.isZero, isTrue);
    final chart = AnalyticsService().history(
      restored,
      DateTime.utc(2026, 11, 21, 5),
      days: 173,
    );
    expect(chart, hasLength(174));
    expect(chart.every((p) => p.combined != null), isTrue);
    for (final scope in [
      AssetScope.investment,
      AssetScope.cash,
      AssetScope.combined,
    ]) {
      final composition = AnalyticsService().composition(restored, scope);
      expect(composition.missing, 0);
      expect(composition.positive, isNotEmpty);
    }
    expect(
      InterestEngine.pending(
        restored,
        DateTime.utc(2026, 11, 21, 5),
        automaticOnly: true,
      ),
      isEmpty,
    );
    final codecCopy = await backup.decode(backup.encode(restored));
    expect(codecCopy.extras.toJson(), demo.extras.toJson());
    expect(
      codecCopy.transactions
          .singleWhere((t) => t.images.isNotEmpty)
          .images
          .map((i) => i.data),
      demo.transactions
          .singleWhere((t) => t.images.isNotEmpty)
          .images
          .map((i) => i.data),
    );
    await db.close();
    db = AppDatabase.file(
      File(p.join(directory.path, 'case-${index - 1}.sqlite')),
    );
    repo = FinanceRepository(db);
    final reopened = await repo.load();
    expect(reopened.netWorth, restored.netWorth);
    expect(reopened.transactions.length, restored.transactions.length);
    watch.stop();
    passed(
      'P10',
      'Android file SQLite + real backup codec',
      'Full 1.3 MB fixture restored/reopened in ${watch.elapsedMilliseconds} ms; all balances, categories, 3 JPEGs, 12 investment kinds, staking, interest, schedules, catalog, FX, preferences and charts preserved.',
    );
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets('P11 Android investment purchase and manual NAV form', (
    tester,
  ) async {
    await repo.addAccount(account('broker', '1000000'));
    final fund = Instrument(
      id: 'fund:qa',
      code: 'QA-RD',
      name: 'QA Dana Manual',
      kind: InstrumentKind.fund,
    );
    await repo.saveInstrument(fund);
    await controller.initialize();
    await openRoute(
      tester,
      InvestmentForm(controller: controller, instrument: fund),
    );
    await tester.enterText(
      find.byKey(const Key('investment-units')),
      '123,456',
    );
    await reveal(tester, find.byKey(const Key('investment-gross')));
    await tester.enterText(find.byKey(const Key('investment-gross')), '150000');
    await reveal(tester, find.byKey(const Key('save-investment')));
    await tester.tap(find.byKey(const Key('save-investment')));
    await idle(tester);
    expect(controller.snapshot.balance('broker'), Money.input('850000'));
    expect(
      controller.snapshot.extras.holdings.single.quantity,
      Decimal.parse('123.456'),
    );
    await openRoute(
      tester,
      PriceForm(controller: controller, instrument: fund),
    );
    await tester.enterText(find.byKey(const Key('manual-price')), '1600,5');
    await reveal(tester, find.text('Simpan harga'));
    await tester.tap(find.text('Simpan harga'));
    await idle(tester);
    expect(controller.snapshot.investmentValue, Money.input('197591,33'));
    expect(controller.snapshot.balance('broker'), Money.input('850000'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    passed(
      'P11',
      'Android investment UI + SQLite',
      'Fractional fund buy debits cash once; manual NAV values units without changing cash.',
    );
  });

  testWidgets('P12 Android staking position and event form', (tester) async {
    await repo.addAccount(account('broker', '2000'));
    await repo.saveInstrument(
      Instrument(
        id: 'cg:ethereum',
        code: 'ETH',
        name: 'Ethereum',
        kind: InstrumentKind.crypto,
        providerId: 'ethereum',
      ),
    );
    await repo.saveInvestment(
      InvestmentEvent(
        id: 'opening',
        instrumentId: 'cg:ethereum',
        accountId: 'broker',
        kind: InvestmentKind.opening,
        quantity: Decimal.parse('10'),
        gross: Money.input('1000'),
        fee: Money.zero,
        date: '2026-11-01',
        createdAt: '2026-11-01T00:00:00Z',
        idrRate: Decimal.one,
      ),
    );
    await controller.initialize();
    await openRoute(tester, StakingPlanForm(controller: controller));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nama posisi / platform'),
      'QA Staking Native',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'APR referensi % (opsional)'),
      '5',
    );
    await reveal(tester, find.byKey(const Key('save-staking-plan')));
    await tester.tap(find.byKey(const Key('save-staking-plan')));
    await idle(tester);
    final plan = controller.snapshot.extras.stakingPlans.single;
    await openRoute(
      tester,
      StakingEventForm(controller: controller, plan: plan),
    );
    await tester.enterText(find.byKey(const Key('staking-units')), '6');
    await reveal(tester, find.byKey(const Key('save-staking-event')));
    await tester.tap(find.byKey(const Key('save-staking-event')));
    await idle(tester);
    expect(
      controller.snapshot.extras.holdings.single.locked,
      Decimal.parse('6'),
    );
    expect(
      controller.snapshot.extras.holdings.single.available,
      Decimal.parse('4'),
    );
    expect(controller.snapshot.balance('broker'), Money.input('2000'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    passed(
      'P12',
      'Android staking UI + SQLite',
      'Plan and stake saved through forms: 10 total = 6 locked + 4 available; APR does not mint units or cash.',
    );
  });

  testWidgets('P13 Android actual interest confirmation and void', (
    tester,
  ) async {
    await repo.addAccount(account('bank', '1000000'));
    await repo.saveInterestRule(
      InterestRule(
        id: 'interest',
        accountId: 'bank',
        name: 'QA Bunga',
        start: '2026-11-01',
        tiers: [InterestTier(Money.zero, Decimal.parse('3.65'))],
        taxPercent: Decimal.parse('20'),
      ),
    );
    await controller.initialize();
    final estimate = InterestEngine.pending(
      controller.snapshot,
      DateTime.utc(2026, 11, 2),
    ).single;
    await openRoute(
      tester,
      InterestPostForm(controller: controller, estimate: estimate),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Bunga bruto aktual'),
      '120',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Pajak aktual'),
      '24',
    );
    await reveal(tester, find.text('Catat bunga aktual'));
    await tester.tap(find.text('Catat bunga aktual'));
    await idle(tester);
    expect(controller.snapshot.balance('bank'), Money.input('1000096'));
    await repo.postInterest(controller.snapshot.extras.interestPostings.single);
    expect((await repo.load()).balance('bank'), Money.input('1000096'));
    await repo.voidInterest(
      controller.snapshot.extras.interestPostings.single.id,
    );
    expect((await repo.load()).balance('bank'), Money.input('1000000'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    passed(
      'P13',
      'Android interest UI + SQLite',
      'Actual gross 120 tax 24 yields net 96 once; duplicate ignored, void returns original balance.',
    );
  });
}
