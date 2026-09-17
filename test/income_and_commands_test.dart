import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:garage_accounting_pro/core/theme/app_theme.dart';
import 'package:garage_accounting_pro/core/currency/currency_manager.dart';
import 'package:garage_accounting_pro/core/localization/app_locale.dart';
import 'package:garage_accounting_pro/data/models/transaction_record.dart';
import 'package:garage_accounting_pro/data/repositories/garage_repository.dart';
import 'package:garage_accounting_pro/features/cashbook/screens/cashbook_screen.dart';
import 'package:garage_accounting_pro/features/home/services/command_parser.dart';
import 'package:garage_accounting_pro/features/home/widgets/expense_category_suggestions.dart';
import 'package:garage_accounting_pro/features/home/widgets/income_preset_suggestions.dart';

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

  group('Income Recording & Undo Repository Tests', () {
    test('recordIncome logs transaction and triggers 5-second undo window', () async {
      final repo = GarageRepository();

      await repo.recordIncome(
        category: 'Car Wash',
        amount: 25.0,
        description: 'Full Foam Wash',
        customerName: 'Customer X',
      );

      final breakdown = repo.getDailyIncomeBreakdown(DateTime.now());
      expect(breakdown.carWashIncome, greaterThanOrEqualTo(25.0));
      expect(repo.lastUndoAction, isNotNull);
      expect(repo.lastUndoAction!.type, 'income');
      expect(repo.undoCountdown, 5);

      // Perform undo
      await repo.undoLastAction();
      expect(repo.lastUndoAction, isNull);
    });

    test('deleteIncomeRecord removes transaction and triggers undo window', () async {
      final repo = GarageRepository();

      await repo.recordIncome(
        category: 'Service',
        amount: 35.0,
        description: 'AC Gas Refill',
      );

      final tx = repo.transactions.firstWhere((t) => t.description == 'AC Gas Refill');
      await repo.deleteIncomeRecord(tx.id);

      expect(repo.lastUndoAction, isNotNull);
      expect(repo.lastUndoAction!.type, 'income_deleted');

      // Undo deletion restores transaction
      await repo.undoLastAction();
      expect(repo.transactions.any((t) => t.description == 'AC Gas Refill'), isTrue);
    });
  });

  group('Category Suggestions Widgets Tests', () {
    testWidgets('ExpenseCategorySuggestions renders all 7 categories and triggers callback', (tester) async {
      String? selectedCategory;
      String? selectedLabel;

      final draft = CommandDraft(
        type: CommandType.expense,
        query: 'foo',
        amount: 50.0,
        rawText: 'ex 50',
      );

      await tester.pumpWidget(
        createTestWidget(
          Scaffold(
            body: ExpenseCategorySuggestions(
              draft: draft,
              currency: CurrencyManager(),
              onSelectCategory: (cat, label) {
                selectedCategory = cat;
                selectedLabel = label;
              },
              onClose: () {},
            ),
          ),
        ),
      );

      expect(find.text('Expense Category (ex / out)'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Tools'), findsOneWidget);
      expect(find.text('Rent'), findsOneWidget);
      expect(find.text('Staff Salary'), findsOneWidget);
      expect(find.text('Utilities'), findsOneWidget);
      expect(find.text('Consumables'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);

      await tester.tap(find.text('Food'));
      await tester.pump();

      expect(selectedCategory, 'Staff Food & Tea');
      expect(selectedLabel, 'Food');
    });

    testWidgets('IncomePresetSuggestions renders presets and triggers callback', (tester) async {
      String? selectedCat;

      final draft = CommandDraft(
        type: CommandType.income,
        query: '',
        amount: 20.0,
        rawText: 'in 20',
      );

      await tester.pumpWidget(
        createTestWidget(
          Scaffold(
            body: IncomePresetSuggestions(
              draft: draft,
              currency: CurrencyManager(),
              onSelectCategory: (cat, label) {
                selectedCat = cat;
              },
              onClose: () {},
            ),
          ),
        ),
      );

      expect(find.text('Direct Income (in)'), findsOneWidget);
      expect(find.text('Car Wash'), findsOneWidget);
      expect(find.text('Service / Repair'), findsOneWidget);
      expect(find.text('Other Income'), findsOneWidget);

      await tester.tap(find.text('Car Wash'));
      await tester.pump();

      expect(selectedCat, 'Car Wash');
    });
  });

  group('CashbookScreen Income & Collection History Tests', () {
    testWidgets('Renders COLLECTIONS & INFLOW HISTORY section and records', (tester) async {
      final repo = GarageRepository();
      await repo.recordIncome(
        category: 'Car Wash',
        amount: 15.0,
        description: 'Express Polish Wash',
        customerName: 'Tariq Al-Balushi',
      );

      await tester.pumpWidget(
        createTestWidget(const CashbookScreen(), repo: repo),
      );
      await tester.pumpAndSettle();

      expect(find.text('COLLECTIONS & INFLOW HISTORY'), findsOneWidget);
      expect(find.text('Car Wash'), findsAtLeastNWidgets(1));
      expect(find.text('Express Polish Wash (Client: Tariq Al-Balushi)'), findsOneWidget);
      expect(find.text('+OMR 15.000'), findsAtLeastNWidgets(1));

      // Advance past the 5-second undo timer
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('Renders Due Settled record with Customer name', (tester) async {
      final repo = GarageRepository();
      repo.setMockTransactions([
        TransactionRecord(
          id: 'tx-pay-1',
          customerName: 'Karim Chowdhury',
          type: 'payment',
          amount: 50.0,
          description: 'Payment Collected',
          paymentMethod: 'cash',
          date: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);

      await tester.pumpWidget(
        createTestWidget(const CashbookScreen(), repo: repo),
      );
      await tester.pumpAndSettle();

      expect(find.text('COLLECTIONS & INFLOW HISTORY'), findsOneWidget);
      expect(find.text('Due Settled'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Karim Chowdhury'), findsOneWidget);
      expect(find.text('+OMR 50.000'), findsAtLeastNWidgets(1));
    });
  });
}
