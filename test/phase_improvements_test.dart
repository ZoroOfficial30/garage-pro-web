import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:garage_accounting_pro/core/currency/currency_manager.dart';
import 'package:garage_accounting_pro/core/localization/app_locale.dart';
import 'package:garage_accounting_pro/core/theme/app_theme.dart';
import 'package:garage_accounting_pro/data/models/customer.dart';
import 'package:garage_accounting_pro/data/models/employee.dart';
import 'package:garage_accounting_pro/data/models/expense_record.dart';
import 'package:garage_accounting_pro/data/models/stock_item.dart';
import 'package:garage_accounting_pro/data/models/transaction_record.dart';
import 'package:garage_accounting_pro/data/repositories/garage_repository.dart';
import 'package:garage_accounting_pro/features/dashboard/screens/daily_summary_screen.dart';
import 'package:garage_accounting_pro/features/employees/screens/employees_screen.dart';
import 'package:garage_accounting_pro/features/navigation/main_scaffold.dart';

void main() {
  group('1. Stock / Inventory Edit & Delete Tests', () {
    test('Can update stock item properties', () {
      final item = StockItem(
        id: 's-1',
        name: 'Castrol 5W-30',
        brand: 'Castrol',
        sku: 'CAS-01',
        quantity: 10,
        reorderThreshold: 5,
        costPrice: 8.0,
        sellingPrice: 12.0,
        unit: 'Can',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = item.copyWith(
        name: 'Castrol Edge 5W-30 Gold',
        quantity: 15,
        sellingPrice: 14.5,
      );

      expect(updated.name, 'Castrol Edge 5W-30 Gold');
      expect(updated.quantity, 15);
      expect(updated.sellingPrice, 14.5);
      expect(updated.costPrice, 8.0);
    });
  });

  group('2. Expenses Date Viewing & Calculations Tests', () {
    test('Correctly filters expenses by date and category', () {
      final d1 = DateTime(2026, 9, 9, 10, 0);
      final d2 = DateTime(2026, 9, 8, 14, 0);

      final exp1 = ExpenseRecord(
        id: 'e-1',
        title: 'Brake cleaner cans',
        category: 'Consumables',
        amount: 15.0,
        paymentMethod: 'cash',
        date: d1,
        createdAt: d1,
        updatedAt: d1,
      );

      final exp2 = ExpenseRecord(
        id: 'e-2',
        title: 'Shop electricity bill',
        category: 'Electricity / Utilities',
        amount: 85.0,
        paymentMethod: 'bank',
        date: d1,
        createdAt: d1,
        updatedAt: d1,
      );

      final exp3 = ExpenseRecord(
        id: 'e-3',
        title: 'Old tool repair',
        category: 'Tools & Equipment',
        amount: 25.0,
        paymentMethod: 'cash',
        date: d2,
        createdAt: d2,
        updatedAt: d2,
      );

      final allExpenses = [exp1, exp2, exp3];

      // Filter for d1
      final d1Expenses = allExpenses.where((e) =>
          e.date.year == d1.year &&
          e.date.month == d1.month &&
          e.date.day == d1.day).toList();

      expect(d1Expenses.length, 2);
      final total = d1Expenses.fold(0.0, (sum, e) => sum + e.amount);
      expect(total, 100.0);
      expect(exp1.isCash, isTrue);
      expect(exp2.isCash, isFalse);
    });
  });

  group('3. Staff / Employees Module Tests', () {
    test('Employee model serialization, attendance toggle, and salary status', () {
      final emp = Employee(
        id: 'emp-1',
        name: 'Rashid Khan',
        phone: '+968 9123 4567',
        role: 'Master Mechanic',
        monthlySalary: 280.0,
        isSalaryPaid: false,
        isPresent: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(emp.name, 'Rashid Khan');
      expect(emp.monthlySalary, 280.0);
      expect(emp.isSalaryPaid, isFalse);
      expect(emp.isPresent, isTrue);

      // Attendance toggle
      final toggled = emp.copyWith(isPresent: false);
      expect(toggled.isPresent, isFalse);

      // Mark salary paid
      final paid = emp.copyWith(
        isSalaryPaid: true,
        lastSalaryPaidDate: DateTime.now(),
      );
      expect(paid.isSalaryPaid, isTrue);
      expect(paid.lastSalaryPaidDate, isNotNull);

      // Map serialization & deserialization
      final map = emp.toMap();
      final fromMap = Employee.fromMap(map);
      expect(fromMap.name, emp.name);
      expect(fromMap.monthlySalary, emp.monthlySalary);
      expect(fromMap.role, emp.role);
    });
  });

  group('4. Customer Profile Photo Support Tests', () {
    test('Customer model avatarBase64 support and copyWith', () {
      const mockPhoto = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

      final cust = Customer(
        id: 'cust-1',
        name: 'Hassan Al-Balushi',
        phone: '99887766',
        vehicleModel: 'Nissan Patrol',
        plateNumber: '3941-B',
        avatarBase64: mockPhoto,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(cust.avatarBase64, isNotNull);
      expect(cust.avatarBase64, mockPhoto);

      // Update photo via copyWith
      const updatedPhoto = 'data:image/png;base64,UPDATED_BASE64_STRING';
      final updatedCust = cust.copyWith(avatarBase64: updatedPhoto);
      expect(updatedCust.avatarBase64, updatedPhoto);

      // Map conversion
      final map = updatedCust.toMap();
      expect(map['avatarBase64'], updatedPhoto);
      final restored = Customer.fromMap(map);
      expect(restored.avatarBase64, updatedPhoto);
    });
  });

  group('5. Daily Income & Expense Summary Tests', () {
    test('TransactionRecord income getters work for car_wash, payment, service', () {
      final t1 = TransactionRecord(
        id: 't-1',
        customerName: 'Walk-in',
        type: 'car_wash',
        amount: 3.5,
        description: 'Full body foam wash',
        paymentMethod: 'cash',
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final t2 = TransactionRecord(
        id: 't-2',
        customerName: 'Salim',
        type: 'payment',
        amount: 50.0,
        description: 'Settled invoice due',
        paymentMethod: 'cash',
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final t3 = TransactionRecord(
        id: 't-3',
        customerName: 'Tariq',
        type: 'due',
        amount: 75.0,
        description: 'Engine overhaul balance',
        paymentMethod: 'credit',
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(t1.isCarWash, isTrue);
      expect(t1.isIncome, isTrue);

      expect(t2.isPayment, isTrue);
      expect(t2.isIncome, isTrue);

      expect(t3.isDue, isTrue);
      expect(t3.isIncome, isFalse);
    });

    test('Daily breakdown aggregates car wash, dues collected, and expenses', () {
      final today = DateTime(2026, 9, 9);

      final tx1 = TransactionRecord(
        id: '1',
        customerName: 'Car 1',
        type: 'car_wash',
        amount: 3.0,
        description: 'Exterior Wash',
        paymentMethod: 'cash',
        date: DateTime(2026, 9, 9, 9, 30),
        createdAt: today,
        updatedAt: today,
      );

      final tx2 = TransactionRecord(
        id: '2',
        customerName: 'Car 2',
        type: 'car_wash',
        amount: 6.0,
        description: 'Full Wash & Polish',
        paymentMethod: 'card',
        date: DateTime(2026, 9, 9, 11, 0),
        createdAt: today,
        updatedAt: today,
      );

      final tx3 = TransactionRecord(
        id: '3',
        customerName: 'Ahmed',
        type: 'payment',
        amount: 45.0,
        description: 'Paid pending dues',
        paymentMethod: 'cash',
        date: DateTime(2026, 9, 9, 14, 0),
        createdAt: today,
        updatedAt: today,
      );

      final exp1 = ExpenseRecord(
        id: 'e1',
        title: 'Shampoo & Degreaser',
        category: 'Consumables',
        amount: 14.0,
        paymentMethod: 'cash',
        date: DateTime(2026, 9, 9, 10, 0),
        createdAt: today,
        updatedAt: today,
      );

      final dayTxs = [tx1, tx2, tx3];
      final dayExpenses = [exp1];

      final totalIncome = dayTxs.fold(0.0, (s, t) => s + t.amount);
      final totalExpense = dayExpenses.fold(0.0, (s, e) => s + e.amount);
      final netAmount = totalIncome - totalExpense;

      expect(totalIncome, 54.0); // 3 + 6 + 45
      expect(totalExpense, 14.0);
      expect(netAmount, 40.0); // Surplus!
      expect(netAmount >= 0, isTrue);
    });
  });

  group('6. Screen Widget Rendering Tests', () {
    Widget buildTestApp(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => GarageRepository()),
          ChangeNotifierProvider(create: (_) => CurrencyManager()),
          ChangeNotifierProvider(create: (_) => AppLocaleManager()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          home: child,
        ),
      );
    }

    testWidgets('EmployeesScreen renders staff list and KPIs correctly', (tester) async {
      await tester.pumpWidget(buildTestApp(const EmployeesScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Staff & Payroll Management'), findsOneWidget);
      expect(find.text('TOTAL TEAM'), findsOneWidget);
      expect(find.text('SALARY DUE'), findsOneWidget);
      expect(find.text('+ Add Staff'), findsOneWidget);
    });

    testWidgets('DailySummaryScreen renders Net status and breakdown cards', (tester) async {
      await tester.pumpWidget(buildTestApp(const DailySummaryScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Daily Income & Expense'), findsOneWidget);
      expect(find.text('+ Car Wash / Income'), findsOneWidget);
      expect(find.text('+ Log Expense'), findsOneWidget);
      expect(find.text('Car Wash Income'), findsOneWidget);
      expect(find.text('Customer Dues Collected'), findsOneWidget);
      expect(find.text('Income Breakdown'), findsOneWidget);
      expect(find.text('Expense Breakdown'), findsOneWidget);
    });

    testWidgets('MainScaffold renders strictly 3 operational tabs (Home, Customers, Jobs) and navigates to Jobs and Staff via Drawer', (tester) async {
      await tester.pumpWidget(buildTestApp(const MainScaffold()));
      await tester.pump(const Duration(milliseconds: 300));

      // Strictly 3 operational tabs in bottom navigation bar
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Customers'), findsOneWidget);
      expect(find.text('Jobs'), findsOneWidget);
      expect(find.text('Stock'), findsNothing);
      expect(find.text('Cashbook'), findsNothing);
      expect(find.text('Dashboard'), findsNothing);

      // Tap Jobs tab
      await tester.tap(find.text('Jobs'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Jobs & Active Bays'), findsOneWidget);
      expect(find.text('+ Open New Job'), findsOneWidget);

      // Open Drawer via hamburger button
      final menuBtn = find.byIcon(Icons.menu_rounded);
      expect(menuBtn, findsWidgets);
      await tester.tap(menuBtn.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));

      // Tap Staff & Attendance in Drawer
      expect(find.text('Staff & Attendance'), findsOneWidget);
      await tester.tap(find.text('Staff & Attendance'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Staff & Payroll Management'), findsOneWidget);
    });

    testWidgets('DailySummaryScreen renders End of Day button and opens confirmation dialog', (tester) async {
      await tester.pumpWidget(buildTestApp(const DailySummaryScreen()));
      await tester.pumpAndSettle();

      final eodBtn = find.text('End of Day (Lock Ledger)');
      expect(eodBtn, findsOneWidget);

      await tester.ensureVisible(eodBtn);
      await tester.tap(eodBtn);
      await tester.pumpAndSettle();

      expect(find.text('Confirm End of Day'), findsOneWidget);
      expect(find.text('Confirm & Lock Day'), findsOneWidget);
    });
  });

  group('7. End of Day & Ledger Lock Tests', () {
    test('DayCloseRecord serializes and deserializes accurately', () {
      final record = DayCloseRecord(
        dateKey: '2026-09-09',
        date: DateTime(2026, 9, 9),
        closedAt: DateTime(2026, 9, 9, 21, 30),
        totalIncome: 150.0,
        totalExpense: 45.0,
        netAmount: 105.0,
        carWashIncome: 50.0,
        carWashCount: 5,
        settlePaymentIncome: 80.0,
        settlePaymentCount: 2,
        otherIncome: 20.0,
        otherIncomeCount: 1,
        categoryExpenses: {'Consumables': 25.0, 'Electricity': 20.0},
        closedBy: 'Manager',
        notes: 'End of day ledger balanced perfectly.',
      );

      final map = record.toMap();
      final restored = DayCloseRecord.fromMap(map);

      expect(restored.dateKey, '2026-09-09');
      expect(restored.totalIncome, 150.0);
      expect(restored.totalExpense, 45.0);
      expect(restored.netAmount, 105.0);
      expect(restored.carWashCount, 5);
      expect(restored.closedBy, 'Manager');
      expect(restored.notes, 'End of day ledger balanced perfectly.');
      expect(restored.categoryExpenses['Consumables'], 25.0);
    });

    test('GarageRepository closes and reopens days correctly', () {
      final repo = GarageRepository();
      final targetDate = DateTime(2026, 9, 9);
      expect(repo.isDayClosed(targetDate), isFalse);

      repo.closeDay(
        targetDate,
        closedBy: 'Head Cashier',
        notes: 'Cash verified with drawer.',
      );

      expect(repo.isDayClosed(targetDate), isTrue);
      expect(repo.getDayCloseRecord(targetDate)?.closedBy, 'Head Cashier');

      repo.reopenDay(targetDate);
      expect(repo.isDayClosed(targetDate), isFalse);
    });
  });
}
