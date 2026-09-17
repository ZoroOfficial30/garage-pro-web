import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_accounting_pro/core/currency/currency_manager.dart';
import 'package:garage_accounting_pro/core/theme/app_theme.dart';
import 'package:garage_accounting_pro/data/models/customer.dart';
import 'package:garage_accounting_pro/features/home/services/command_parser.dart';
import 'package:garage_accounting_pro/features/home/widgets/customer_command_suggestions.dart';

void main() {
  final testCustomer1 = Customer(
    id: 'c-1',
    name: 'Karim Chowdhury',
    phone: '01711234567',
    vehicleModel: 'Toyota Corolla',
    plateNumber: 'GA-2345',
    totalDue: 150.0,
    totalBilled: 500.0,
    totalPaid: 350.0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final testCustomer2 = Customer(
    id: 'c-2',
    name: 'Karim Ullah',
    phone: '01899999999',
    vehicleModel: 'Honda Civic',
    plateNumber: 'DHA-8899',
    totalDue: 0.0,
    totalBilled: 300.0,
    totalPaid: 300.0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  Widget createWidget({
    required CommandDraft draft,
    required List<Customer> matchingCustomers,
    required ValueChanged<Customer> onSelectCustomer,
    required ValueChanged<String> onCreateNewCustomer,
    required VoidCallback onClose,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme(),
      home: Scaffold(
        body: CustomerCommandSuggestions(
          draft: draft,
          matchingCustomers: matchingCustomers,
          currency: CurrencyManager(),
          onSelectCustomer: onSelectCustomer,
          onCreateNewCustomer: onCreateNewCustomer,
          onClose: onClose,
        ),
      ),
    );
  }

  group('CustomerCommandSuggestions Widget Tests', () {
    testWidgets('Renders action header and matching customer cards', (tester) async {
      Customer? selected;
      String? newCustomerCreated;
      bool closed = false;

      final draft = CommandDraft(
        type: CommandType.due,
        query: 'Karim',
        amount: 50.0,
        rawText: 'ad Karim 50',
      );

      await tester.pumpWidget(
        createWidget(
          draft: draft,
          matchingCustomers: [testCustomer1, testCustomer2],
          onSelectCustomer: (c) => selected = c,
          onCreateNewCustomer: (name) => newCustomerCreated = name,
          onClose: () => closed = true,
        ),
      );

      final currency = CurrencyManager();

      // Verify Header & Amount Pill
      expect(find.textContaining('Add Due'), findsOneWidget);
      expect(find.text(currency.format(50.0)), findsOneWidget);

      // Verify Customer cards
      expect(find.text('Karim Chowdhury'), findsOneWidget);
      expect(find.text('Karim Ullah'), findsOneWidget);
      expect(find.text(currency.format(150.0)), findsOneWidget);
      expect(find.text('Cleared'), findsOneWidget);

      // Tap on first customer
      await tester.tap(find.text('Karim Chowdhury'));
      await tester.pump();
      expect(selected?.id, 'c-1');

      // Tap on Create New Customer
      expect(find.textContaining('Create New Customer: "Karim"'), findsOneWidget);
      await tester.tap(find.textContaining('Create New Customer: "Karim"'));
      await tester.pump();
      expect(newCustomerCreated, 'Karim');

      // Tap on Close
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(closed, isTrue);
    });

    testWidgets('Renders settle payment style for sp / -pay draft', (tester) async {
      final currency = CurrencyManager();
      final draft = CommandDraft(
        type: CommandType.pay,
        query: '01711234567',
        amount: 30.0,
        rawText: 'sp 01711234567 30',
      );

      await tester.pumpWidget(
        createWidget(
          draft: draft,
          matchingCustomers: [testCustomer1],
          onSelectCustomer: (_) {},
          onCreateNewCustomer: (_) {},
          onClose: () {},
        ),
      );

      expect(find.textContaining('Settle Payment'), findsOneWidget);
      expect(find.text(currency.format(30.0)), findsOneWidget);
      expect(find.text('Karim Chowdhury'), findsOneWidget);
    });
  });
}
