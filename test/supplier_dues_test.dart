import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:garage_accounting_pro/core/theme/app_theme.dart';
import 'package:garage_accounting_pro/core/currency/currency_manager.dart';
import 'package:garage_accounting_pro/core/localization/app_locale.dart';
import 'package:garage_accounting_pro/data/models/supplier_due.dart';
import 'package:garage_accounting_pro/data/repositories/garage_repository.dart';
import 'package:garage_accounting_pro/features/navigation/main_scaffold.dart';
import 'package:garage_accounting_pro/features/suppliers/screens/supplier_dues_screen.dart';
import 'package:garage_accounting_pro/features/suppliers/widgets/add_edit_supplier_due_modal.dart';
import 'package:garage_accounting_pro/features/suppliers/widgets/pay_supplier_due_modal.dart';

void main() {
  Widget createTestApp({required Widget child, GarageRepository? repo}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GarageRepository>(create: (_) => repo ?? GarageRepository()),
        ChangeNotifierProvider<CurrencyManager>(create: (_) => CurrencyManager()),
        ChangeNotifierProvider<AppLocaleManager>(create: (_) => AppLocaleManager()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme(),
        home: child,
      ),
    );
  }

  group('1. SupplierDue & SupplierPayment Data Model Tests', () {
    test('Calculates dueAmount, isFullyPaid, isPartiallyPaid, isUnpaid accurately', () {
      final now = DateTime.now();
      final unpaidDue = SupplierDue(
        id: 'due-1',
        companyName: 'Castrol Lubricants',
        totalAmount: 400.0,
        paidAmount: 0.0,
        itemsPurchased: 'Engine Oil 5W-30',
        date: now,
        createdAt: now,
        updatedAt: now,
      );

      expect(unpaidDue.dueAmount, 400.0);
      expect(unpaidDue.isUnpaid, isTrue);
      expect(unpaidDue.isPartiallyPaid, isFalse);
      expect(unpaidDue.isFullyPaid, isFalse);

      final partialDue = unpaidDue.copyWith(paidAmount: 150.0);
      expect(partialDue.dueAmount, 250.0);
      expect(partialDue.isUnpaid, isFalse);
      expect(partialDue.isPartiallyPaid, isTrue);
      expect(partialDue.isFullyPaid, isFalse);

      final fullyPaidDue = unpaidDue.copyWith(paidAmount: 400.0);
      expect(fullyPaidDue.dueAmount, 0.0);
      expect(fullyPaidDue.isUnpaid, isFalse);
      expect(fullyPaidDue.isPartiallyPaid, isFalse);
      expect(fullyPaidDue.isFullyPaid, isTrue);
    });

    test('SupplierPayment serialization and deserialization roundtrip', () {
      final now = DateTime.now();
      final payment = SupplierPayment(
        id: 'pay-1',
        amount: 150.0,
        date: now,
        paymentMethod: 'Bank Transfer',
        notes: 'Bank Muscat Transfer #991',
        expenseId: 'exp-991',
      );

      final map = payment.toMap();
      final fromMap = SupplierPayment.fromMap(map);

      expect(fromMap.id, payment.id);
      expect(fromMap.amount, payment.amount);
      expect(fromMap.paymentMethod, payment.paymentMethod);
      expect(fromMap.notes, payment.notes);
      expect(fromMap.expenseId, payment.expenseId);
    });

    test('SupplierDue serialization and deserialization roundtrip with payments', () {
      final now = DateTime.now();
      final payment = SupplierPayment(
        id: 'pay-1',
        amount: 100.0,
        date: now,
        paymentMethod: 'Cash',
      );

      final due = SupplierDue(
        id: 'due-100',
        companyName: 'Mann-Filter ME',
        totalAmount: 300.0,
        paidAmount: 100.0,
        itemsPurchased: 'Oil & Air Filters',
        date: now,
        notes: 'Invoice #MF-90',
        payments: [payment],
        createdAt: now,
        updatedAt: now,
      );

      final map = due.toMap();
      final fromMap = SupplierDue.fromMap(map);

      expect(fromMap.id, due.id);
      expect(fromMap.companyName, due.companyName);
      expect(fromMap.totalAmount, 300.0);
      expect(fromMap.paidAmount, 100.0);
      expect(fromMap.dueAmount, 200.0);
      expect(fromMap.itemsPurchased, 'Oil & Air Filters');
      expect(fromMap.payments.length, 1);
      expect(fromMap.payments.first.amount, 100.0);
    });
  });

  group('2. GarageRepository Supplier Dues Business Logic Tests', () {
    late GarageRepository repo;

    setUp(() {
      repo = GarageRepository();
    });

    tearDown(() {
      repo.dispose();
    });

    test('addSupplierDue adds record and updates outstanding supplier dues', () async {
      expect(repo.supplierDues.isEmpty, isTrue);

      final due = await repo.addSupplierDue(
        companyName: 'Shell Helix Oman',
        totalAmount: 250.0,
        itemsPurchased: 'Synthetic 5W-40 (5 cartons)',
      );

      expect(repo.supplierDues.length, 1);
      expect(repo.supplierDues.first.id, due.id);
      expect(repo.totalOutstandingSupplierDues, 250.0);
      expect(repo.totalPaidSupplierDues, 0.0);
      expect(repo.pendingSupplierDuesCount, 1);
    });

    test('recordSupplierPayment reduces due balance and syncs expense to Cashbook', () async {
      final due = await repo.addSupplierDue(
        companyName: 'Bosch Auto Parts',
        totalAmount: 300.0,
        itemsPurchased: 'Brake Pads & Spark Plugs',
      );

      final initialExpensesCount = repo.expenses.length;
      final initialCustomerDues = repo.totalOutstandingDues;

      // Make partial payment of 100.0
      await repo.recordSupplierPayment(
        dueId: due.id,
        amount: 100.0,
        paymentMethod: 'Cash',
        notes: 'Cash advance receipt #001',
      );

      final updated = repo.supplierDues.firstWhere((d) => d.id == due.id);
      expect(updated.paidAmount, 100.0);
      expect(updated.dueAmount, 200.0);
      expect(updated.isPartiallyPaid, isTrue);
      expect(repo.totalOutstandingSupplierDues, 200.0);
      expect(repo.totalPaidSupplierDues, 100.0);

      // Verify Expense was added with 'Supplier Payment' category
      expect(repo.expenses.length, initialExpensesCount + 1);
      final expense = repo.expenses.first;
      expect(expense.category, 'Supplier Payment');
      expect(expense.amount, 100.0);
      expect(expense.title, contains('Bosch Auto Parts'));

      // Verify Customer dues remain 100% untouched
      expect(repo.totalOutstandingDues, initialCustomerDues);
    });

    test('Full payment marks supplier due as fully settled', () async {
      final due = await repo.addSupplierDue(
        companyName: 'Mann-Filter',
        totalAmount: 150.0,
        itemsPurchased: 'Air Filters',
      );

      await repo.recordSupplierPayment(
        dueId: due.id,
        amount: 150.0,
        paymentMethod: 'Bank Transfer',
      );

      final updated = repo.supplierDues.firstWhere((d) => d.id == due.id);
      expect(updated.dueAmount, 0.0);
      expect(updated.isFullyPaid, isTrue);
      expect(repo.totalOutstandingSupplierDues, 0.0);
      expect(repo.pendingSupplierDuesCount, 0);
    });

    test('Undo payment reverts supplier due balance and deletes logged expense', () async {
      final due = await repo.addSupplierDue(
        companyName: 'Castrol Lubricants',
        totalAmount: 500.0,
        itemsPurchased: 'Engine Oil',
      );

      await repo.recordSupplierPayment(
        dueId: due.id,
        amount: 200.0,
        paymentMethod: 'Cheque',
      );

      expect(repo.totalOutstandingSupplierDues, 300.0);
      expect(repo.expenses.any((e) => e.category == 'Supplier Payment'), isTrue);
      expect(repo.lastUndoAction, isNotNull);
      expect(repo.lastUndoAction!.type, 'supplier_payment');

      // Execute Undo
      await repo.undoLastAction();

      final reverted = repo.supplierDues.firstWhere((d) => d.id == due.id);
      expect(reverted.paidAmount, 0.0);
      expect(reverted.dueAmount, 500.0);
      expect(repo.totalOutstandingSupplierDues, 500.0);
      expect(repo.expenses.any((e) => e.category == 'Supplier Payment'), isFalse);
    });

    test('Undo delete restores deleted supplier due', () async {
      final due = await repo.addSupplierDue(
        companyName: 'Oman Battery Co.',
        totalAmount: 180.0,
        itemsPurchased: '12V 70Ah Batteries',
      );

      expect(repo.supplierDues.length, 1);

      await repo.deleteSupplierDue(due.id);
      expect(repo.supplierDues.isEmpty, isTrue);
      expect(repo.lastUndoAction, isNotNull);
      expect(repo.lastUndoAction!.type, 'supplier_due_delete');

      // Execute Undo
      await repo.undoLastAction();
      expect(repo.supplierDues.length, 1);
      expect(repo.supplierDues.first.companyName, 'Oman Battery Co.');
    });
  });

  group('3. Supplier Dues UI & Widget Integration Tests', () {
    testWidgets('SupplierDuesScreen renders summary KPI card and list items', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = GarageRepository();

      await repo.addSupplierDue(
        companyName: 'Castrol Oman',
        totalAmount: 450.0,
        itemsPurchased: 'Edge 0W-40 Synthetic Oil',
      );
      await repo.addSupplierDue(
        companyName: 'Mann-Filter ME',
        totalAmount: 120.0,
        itemsPurchased: 'Oil Filters',
      );
      repo.clearUndoWindow();

      await tester.pumpWidget(createTestApp(
        repo: repo,
        child: const SupplierDuesScreen(),
      ));
      await tester.pump(const Duration(milliseconds: 300));

      // Verify screen title & KPI card
      expect(find.text('Supplier Dues'), findsWidgets);
      expect(find.text('TOTAL SUPPLIER DUES'), findsOneWidget);
      expect(find.text('570.000'), findsOneWidget); // 450 + 120

      // Verify dues cards
      expect(find.text('Castrol Oman'), findsOneWidget);
      expect(find.text('Mann-Filter ME'), findsOneWidget);
      expect(find.text('Edge 0W-40 Synthetic Oil'), findsOneWidget);

      // Verify Filter chips
      expect(find.text('All (2)'), findsOneWidget);
      expect(find.text('Pending (2)'), findsOneWidget);
      expect(find.text('Paid (0)'), findsOneWidget);
    });

    testWidgets('AddEditSupplierDueModal opens and validates inputs', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = GarageRepository();

      await tester.pumpWidget(createTestApp(
        repo: repo,
        child: const Scaffold(body: AddEditSupplierDueModal()),
      ));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Add Supplier Due'), findsOneWidget);
      expect(find.text('Save Supplier Due'), findsOneWidget);

      // Tap quick company suggestion chip
      expect(find.text('Castrol Lubricants Oman'), findsOneWidget);
      await tester.tap(find.text('Castrol Lubricants Oman'));
      await tester.pump();

      // Tap item chip
      expect(find.text('+ Engine Oil'), findsOneWidget);
      await tester.tap(find.text('+ Engine Oil'));
      await tester.pump();

      // Enter amount
      await tester.enterText(find.byType(TextFormField).at(1), '350.0');
      await tester.pump();

      // Tap Save
      await tester.tap(find.text('Save Supplier Due'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(repo.supplierDues.length, 1);
      expect(repo.supplierDues.first.companyName, 'Castrol Lubricants Oman');
      expect(repo.supplierDues.first.totalAmount, 350.0);
      repo.clearUndoWindow();
    });

    testWidgets('PaySupplierDueModal opens and records payment', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = GarageRepository();

      final due = await repo.addSupplierDue(
        companyName: 'Shell Helix',
        totalAmount: 200.0,
        itemsPurchased: 'Helix Ultra 5W-40',
      );
      repo.clearUndoWindow();

      await tester.pumpWidget(createTestApp(
        repo: repo,
        child: Scaffold(body: PaySupplierDueModal(due: due)),
      ));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Pay Supplier Due'), findsOneWidget);
      expect(find.text('Shell Helix'), findsOneWidget);
      expect(find.text('Confirm Payment (OMR 200.000)'), findsOneWidget);

      // Tap 50% preset button
      await tester.tap(find.text('50% (OMR 100.000)'));
      await tester.pump();

      expect(find.text('Confirm Payment (OMR 100.000)'), findsOneWidget);

      // Submit payment
      await tester.tap(find.text('Confirm Payment (OMR 100.000)'));
      await tester.pump(const Duration(milliseconds: 300));

      final updated = repo.supplierDues.first;
      expect(updated.paidAmount, 100.0);
      expect(updated.dueAmount, 100.0);
      expect(repo.expenses.length, 1);
      expect(repo.expenses.first.category, 'Supplier Payment');
      repo.clearUndoWindow();
    });

    testWidgets('AppNavigationDrawer contains Supplier Dues and navigates to screen', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = GarageRepository();

      await repo.addSupplierDue(
        companyName: 'Castrol Oman',
        totalAmount: 300.0,
        itemsPurchased: 'Oil',
      );
      repo.clearUndoWindow();

      await tester.pumpWidget(createTestApp(
        repo: repo,
        child: const MainScaffold(),
      ));
      await tester.pump(const Duration(milliseconds: 300));

      // Open drawer from top bar hamburger icon
      final menuButton = find.byTooltip('Menu');
      expect(menuButton, findsOneWidget);
      await tester.tap(menuButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));

      // Verify "Supplier Dues" item in drawer with pending count badge "1"
      expect(find.text('Supplier Dues'), findsOneWidget);
      expect(find.text('Parts & Company Payables'), findsOneWidget);
      expect(find.text('1'), findsOneWidget); // Pending badge count

      // Tap "Supplier Dues" in drawer
      await tester.tap(find.text('Supplier Dues'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));

      // Verify SupplierDuesScreen is pushed
      expect(find.byType(SupplierDuesScreen), findsOneWidget);
      expect(find.text('TOTAL SUPPLIER DUES'), findsOneWidget);
      repo.clearUndoWindow();
    });
  });
}
