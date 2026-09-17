import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:garage_accounting_pro/core/theme/app_theme.dart';
import 'package:garage_accounting_pro/core/currency/currency_manager.dart';
import 'package:garage_accounting_pro/core/localization/app_locale.dart';
import 'package:garage_accounting_pro/data/models/expense_record.dart';
import 'package:garage_accounting_pro/data/repositories/garage_repository.dart';
import 'package:garage_accounting_pro/features/expenses/widgets/expense_card.dart';
import 'package:garage_accounting_pro/features/expenses/widgets/expense_hero_card.dart';
import 'package:garage_accounting_pro/features/expenses/screens/expenses_screen.dart';

void main() {
  Widget createTestWidget(Widget child, {GarageRepository? repo}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => repo ?? GarageRepository()),
        ChangeNotifierProvider(create: (_) => CurrencyManager()),
        ChangeNotifierProvider(create: (_) => AppLocaleManager()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme(),
        home: child,
      ),
    );
  }

  group('ExpenseCard Tests', () {
    testWidgets('Renders expense details, category badge, and amount in OMR', (tester) async {
      bool edited = false;

      final expense = ExpenseRecord(
        id: 'exp-1',
        title: 'Torque Wrench Calibration & Socket Set',
        category: 'Tools & Gear',
        amount: 120.0,
        paymentMethod: 'Cash',
        date: DateTime(2026, 9, 8, 10, 45),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestWidget(
          Scaffold(
            body: ExpenseCard(
              expense: expense,
              onEdit: () => edited = true,
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Torque Wrench Calibration & Socket Set'), findsOneWidget);
      expect(find.text('Tools & Gear'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('OMR 120.000'), findsOneWidget);
      expect(find.byIcon(Icons.build_rounded), findsOneWidget);

      // Open options menu
      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(edited, isTrue);
    });
  });

  group('ExpenseHeroCard Tests', () {
    testWidgets('Renders total outflow and Cash vs Digital breakdown', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const Scaffold(
            body: ExpenseHeroCard(
              period: 'today',
              totalExpense: 340.0,
              cashExpense: 210.0,
              digitalExpense: 130.0,
              count: 4,
            ),
          ),
        ),
      );

      expect(find.text('TOTAL OUTFLOW (TODAY)'), findsOneWidget);
      expect(find.text('OMR 340.000'), findsOneWidget);
      expect(find.text('OMR 210.000'), findsOneWidget);
      expect(find.text('OMR 130.000'), findsOneWidget);
      expect(find.text('4 Receipts / Records'), findsOneWidget);
    });
  });

  group('ExpensesScreen / CashbookScreen Tests', () {
    testWidgets('Renders screen header, period toggle tabs, income & expense sections, and action buttons', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const ExpensesScreen()),
      );

      expect(find.text('Cashbook'), findsOneWidget);
      expect(find.text('Today'), findsAtLeastNWidgets(1));
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('Pick Date'), findsOneWidget);
      expect(find.text('NET CASH BALANCE'), findsOneWidget);
      expect(find.text('INCOME & COLLECTIONS'), findsOneWidget);
      expect(find.text('EXPENSES & OUTFLOWS'), findsOneWidget);
      expect(find.text('Car Wash'), findsOneWidget);
      expect(find.text('Dues Settled'), findsOneWidget);
      expect(find.text('+ Log Expense'), findsAtLeastNWidgets(1));
    });
  });
}
