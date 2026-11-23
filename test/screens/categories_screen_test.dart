import 'package:arta/app.dart';
import 'package:arta/controllers/finance_controller.dart';
import 'package:arta/database/app_database.dart';
import 'package:arta/models/ledger.dart';
import 'package:arta/models/transaction_category.dart';
import 'package:arta/repositories/finance_repository.dart';
import 'package:arta/screens/categories_screen.dart';
import 'package:arta/screens/transaction_form.dart';
import 'package:arta/services/transaction_category_service.dart';
import 'package:arta/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../fixtures.dart';
import 'finance_flow_test.dart' show loadFonts, capture, captureKey;

void main() {
  late AppDatabase db;
  late FinanceController c;
  setUp(() async {
    db = AppDatabase.memory();
    c = FinanceController(FinanceRepository(db));
    await c.repository.addAccount(account('bank', '100000'));
    await c.initialize();
  });
  tearDown(() async {
    c.dispose();
    await db.close();
  });
  Future<void> screen(
    WidgetTester tester, {
    Brightness brightness = Brightness.dark,
  }) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.create(brightness),
        home: CategoriesScreen(controller: c),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> create(WidgetTester tester, String name) async {
    await tester.tap(find.byKey(const Key('add-category')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('category-name')), name);
    await tester.tap(find.byKey(const Key('save-category')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Settings opens category manager; add unused category is immediately selectable in transaction',
    (tester) async {
      await tester.pumpWidget(ArtaApp(controller: c));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-4')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('categories-menu')));
      await tester.tap(find.byKey(const Key('categories-menu')));
      await tester.pumpAndSettle();
      expect(find.byType(CategoriesScreen), findsOneWidget);
      await create(tester, 'Servis kendaraan');
      expect(c.snapshot.transactions, isEmpty);
      expect(
        TransactionCategoryService.options(c.snapshot, TransactionKind.expense),
        contains('Servis kendaraan'),
      );
      await tester.pumpWidget(
        MaterialApp(home: TransactionForm(controller: c)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('choose-transaction-category')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('category-search')),
        'Servis kendaraan',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Servis kendaraan'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('transaction-category')),
            )
            .controller!
            .text,
        'Servis kendaraan',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'rename, archive and reactivate flow preserves kind separation and validates duplicate names',
    (tester) async {
      await screen(tester, brightness: Brightness.light);
      await create(tester, 'Royalti');
      await tester.enterText(
        find.byKey(const Key('categories-search')),
        'Royalti',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Royalti'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('category-name')),
        'Makan & Minum',
      );
      await tester.tap(find.byKey(const Key('save-category')));
      await tester.pumpAndSettle();
      expect(find.text('Nama sudah ada, termasuk di arsip.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('category-name')),
        'Royalti Baru',
      );
      await tester.tap(find.byKey(const Key('save-category')));
      await tester.pumpAndSettle();
      final category = TransactionCategoryService.all(c.snapshot)
          .firstWhere((v) => v.name == 'Royalti Baru');
      await tester.tap(find.byKey(ValueKey('archive-category-${category.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Arsipkan'));
      await tester.pumpAndSettle();
      expect(find.text('Royalti Baru'), findsNothing);
      await tester.tap(find.byKey(const Key('categories-archive-filter')));
      await tester.pumpAndSettle();
      expect(find.text('Royalti Baru'), findsOneWidget);
      await tester.tap(find.byKey(ValueKey('archive-category-${category.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aktifkan'));
      await tester.pumpAndSettle();
      expect(find.text('Royalti Baru'), findsNothing);
      await tester.tap(find.byKey(const Key('categories-archive-filter')));
      await tester.tap(find.byKey(const Key('category-kind-income')));
      await tester.pumpAndSettle();
      await create(tester, 'Royalti Baru');
      expect(
        TransactionCategoryService.all(c.snapshot)
            .where((v) => v.name == 'Royalti Baru'),
        hasLength(2),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'archived category cannot be typed into a new transaction but old transaction remains editable',
    (tester) async {
      final tx = transaction(category: 'Makan & Minum');
      await c.repository.saveTransaction(tx);
      await c.initialize();
      final category = TransactionCategoryService.all(c.snapshot)
          .firstWhere((v) => v.name == 'Makan & Minum');
      await c.saveCategory(category.copy(archived: true), edit: true);
      await tester.pumpWidget(
        MaterialApp(home: TransactionForm(controller: c)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('transaction-category')),
        'Makan & Minum',
      );
      var state = tester.state<FormFieldState<String>>(
        find.byKey(const Key('transaction-category')),
      );
      expect(state.validate(), false);
      await tester.pumpAndSettle();
      expect(
        find.text('Kategori diarsipkan. Aktifkan kembali di Pengaturan.'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        MaterialApp(
          home: TransactionForm(controller: c, existing: tx),
        ),
      );
      await tester.pumpAndSettle();
      state = tester.state<FormFieldState<String>>(
        find.byKey(const Key('transaction-category')),
      );
      expect(state.validate(), true);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'large text and landscape manager stay scrollable without overflow',
    (tester) async {
      await c.saveCategory(
        const TransactionCategory(
          id: 'long',
          kind: TransactionKind.expense,
          name: 'Perawatan kendaraan dan kebutuhan rumah tangga lainnya',
        ),
      );
      tester.view.physicalSize = const Size(700, 320);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (ctx, child) => MediaQuery(
            data: MediaQuery.of(ctx)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: CategoriesScreen(controller: c),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('capture category manager in both themes', (tester) async {
    await loadFonts(tester);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(
        RepaintBoundary(
          key: captureKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.create(brightness),
            home: CategoriesScreen(controller: c),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await capture(tester, 'categories-${brightness.name}-0.7.2');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });
}
