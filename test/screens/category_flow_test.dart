import 'package:arta/app.dart';
import 'package:arta/controllers/finance_controller.dart';
import 'package:arta/database/app_database.dart';
import 'package:arta/models/ledger.dart';
import 'package:arta/repositories/finance_repository.dart';
import 'package:arta/screens/transaction_form.dart';
import 'package:arta/services/backup_service.dart';
import 'package:arta/services/transaction_category_service.dart';
import 'package:arta/theme/app_theme.dart';
import 'package:arta/widgets/arta_logo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../fixtures.dart';

void main() {
  late AppDatabase db;
  late FinanceController controller;
  setUp(() async {
    db = AppDatabase.memory();
    controller = FinanceController(FinanceRepository(db));
    await controller.repository.addAccount(account('bank', '100000'));
    await controller.initialize();
  });
  tearDown(() async {
    controller.dispose();
    await db.close();
  });

  test('categories keep legacy/custom names and separate income from expenses after backup', () async {
    await controller.repository.saveTransaction(
      transaction(id: 'e1', category: '  Kucing Sehat  '),
    );
    await controller.repository.saveTransaction(
      transaction(id: 'e2', category: 'kucing sehat'),
    );
    await controller.repository.saveTransaction(
      transaction(id: 'i1', kind: TransactionKind.income, category: 'Royalti'),
    );
    await controller.repository.saveSchedule(
      schedule(id: 's1', category: 'Biaya admin khusus'),
    );
    final codec = BackupService();
    final data = await codec.decode(
      codec.encode(await controller.repository.load()),
    );
    final expense = TransactionCategoryService.options(
      data,
      TransactionKind.expense,
    );
    final income = TransactionCategoryService.options(
      data,
      TransactionKind.income,
    );
    expect(
      expense.where((v) => v.toLowerCase() == 'kucing sehat'),
      hasLength(1),
    );
    expect(expense, contains('Biaya admin khusus'));
    expect(expense, contains('Makan & Minum'));
    expect(income, containsAll(['Gaji', 'Royalti']));
    expect(income, isNot(contains('Kucing Sehat')));
    expect(expense, isNot(contains('Royalti')));
    expect(
      TransactionCategoryService.options(data, TransactionKind.transfer),
      isEmpty,
    );
  });

  testWidgets(
    'picker selects defaults, creates custom and keeps drafts separate by transaction type',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.create(Brightness.dark),
          home: TransactionForm(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('choose-transaction-category')));
      await tester.pumpAndSettle();
      expect(find.text('Kategori pengeluaran'), findsWidgets);
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
        'Royalti Buku',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gunakan "Royalti Buku"'));
      await tester.pumpAndSettle();
      expect(category().controller!.text, 'Royalti Buku');
      await tester.tap(find.text('Pengeluaran'));
      await tester.pumpAndSettle();
      expect(category().controller!.text, 'Makan & Minum');
      await tester.tap(find.text('Transfer'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('transaction-category')), findsNothing);
      await tester.tap(find.text('Pemasukan'));
      await tester.pumpAndSettle();
      expect(category().controller!.text, 'Royalti Buku');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'settings scroll offset does not replace the CSV expansion state on tab return',
    (tester) async {
      await tester.pumpWidget(ArtaApp(controller: controller));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-4')));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const PageStorageKey('main-tab-4')),
        const Offset(0, -1000),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-4')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Ekspor CSV'));
      await tester.tap(find.text('Ekspor CSV'));
      await tester.pumpAndSettle();
      expect(find.text('Ekspor CSV transaksi'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'home header has no privacy button or loading, balance card retains privacy',
    (tester) async {
      await tester.pumpWidget(ArtaApp(controller: controller));
      await tester.pumpAndSettle();
      final header = find.byType(AppBar).first;
      expect(
        find.descendant(
          of: header,
          matching: find.byKey(const Key('toggle-amounts')),
        ),
        findsNothing,
      );
      expect(
        find.descendant(of: header, matching: find.byType(ArtaLogo)),
        findsNothing,
      );
      expect(find.byKey(const Key('toggle-amounts')), findsOneWidget);
      await tester.tap(find.byKey(const Key('toggle-amounts')));
      await tester.pumpAndSettle();
      expect(controller.amountsHidden, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
