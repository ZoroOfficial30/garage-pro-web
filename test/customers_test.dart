import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:garage_accounting_pro/core/theme/app_theme.dart';
import 'package:garage_accounting_pro/core/currency/currency_manager.dart';
import 'package:garage_accounting_pro/core/localization/app_locale.dart';
import 'package:garage_accounting_pro/data/models/customer.dart';
import 'package:garage_accounting_pro/data/repositories/garage_repository.dart';
import 'package:garage_accounting_pro/features/customers/widgets/customer_card.dart';
import 'package:garage_accounting_pro/features/customers/screens/customers_list_screen.dart';
import 'package:garage_accounting_pro/features/customers/screens/customer_detail_screen.dart';

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

  group('CustomerCard Widget Tests', () {
    testWidgets('Renders customer details and DUE badge when balance > 0', (tester) async {
      bool tapped = false;
      bool collected = false;
      bool called = false;

      final testCustomer = Customer(
        id: 'cust-1',
        name: 'Karim Chowdhury',
        phone: '+880 1711-234567',
        vehicleModel: 'Toyota Corolla 2019',
        plateNumber: 'GA 23-8910',
        totalDue: 450.0,
        totalBilled: 1650.0,
        totalPaid: 1200.0,
        isVip: true,
        notes: 'VIP customer',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestWidget(
          Scaffold(
            body: CustomerCard(
              customer: testCustomer,
              onTap: () => tapped = true,
              onCollectPay: () => collected = true,
              onCall: () => called = true,
            ),
          ),
        ),
      );

      // Check name, initials, VIP badge
      expect(find.text('Karim Chowdhury'), findsOneWidget);
      expect(find.text('KC'), findsOneWidget);
      expect(find.text('VIP'), findsOneWidget);
      expect(find.text('+880 1711-234567'), findsOneWidget);
      expect(find.text('Toyota Corolla 2019'), findsOneWidget);
      expect(find.text('GA 23-8910'), findsOneWidget);

      // Check due badge
      expect(find.text('OMR 450.000 DUE'), findsOneWidget);
      expect(find.text('Collect Pay'), findsOneWidget);

      // Test callbacks
      await tester.tap(find.text('Collect Pay'));
      await tester.pump();
      expect(collected, isTrue);

      await tester.tap(find.byIcon(Icons.call_rounded));
      await tester.pump();
      expect(called, isTrue);

      await tester.tap(find.text('Karim Chowdhury'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('Renders PAID badge when balance == 0', (tester) async {
      final clearedCustomer = Customer(
        id: 'cust-2',
        name: 'Ahmed Al-Mansoor',
        phone: '+971 50 123 4567',
        vehicleModel: 'Nissan Patrol',
        plateNumber: 'DXB 88124',
        totalDue: 0.0,
        totalBilled: 800.0,
        totalPaid: 800.0,
        isVip: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestWidget(
          Scaffold(
            body: CustomerCard(
              customer: clearedCustomer,
              onTap: () {},
              onCollectPay: () {},
              onCall: () {},
            ),
          ),
        ),
      );

      expect(find.text('Ahmed Al-Mansoor'), findsOneWidget);
      expect(find.text('AA'), findsOneWidget);
      expect(find.text('VIP'), findsNothing);
      expect(find.text('OMR 0.000 PAID'), findsOneWidget);
      expect(find.text('New Job / Bill'), findsOneWidget);
    });

    testWidgets('Renders 3-dot menu and triggers delete confirmation dialog', (tester) async {
      final customer = Customer(
        id: 'cust-menu-1',
        name: 'Rashid Al-Hajri',
        phone: '+968 9234 5678',
        vehicleModel: 'Toyota Prado',
        plateNumber: '9900 D',
        totalDue: 40.0,
        totalBilled: 40.0,
        totalPaid: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestWidget(
          Scaffold(
            body: CustomerCard(
              customer: customer,
              onTap: () {},
              onCollectPay: () {},
              onCall: () {},
            ),
          ),
        ),
      );

      // Verify 3-dot menu icon exists
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);

      // Tap 3-dot icon
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      // Verify menu options
      expect(find.text('View Profile'), findsOneWidget);
      expect(find.text('Delete Customer'), findsOneWidget);

      // Tap Delete Customer
      await tester.tap(find.text('Delete Customer'));
      await tester.pumpAndSettle();

      // Verify confirmation dialog
      expect(find.text('Delete Customer?'), findsOneWidget);
      expect(find.textContaining('Rashid Al-Hajri'), findsWidgets);
      expect(find.textContaining('Warning: This customer has an outstanding balance'), findsOneWidget);
    });
  });

  group('CustomersListScreen Tests', () {
    testWidgets('Renders Customers & Dues header, summary hero card, search bar, and filter tabs', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const CustomersListScreen()),
      );

      expect(find.text('Customers & Dues'), findsOneWidget);
      expect(find.text('TOTAL OUTSTANDING DUES'), findsOneWidget);
      expect(find.text('Send Bulk Reminder SMS'), findsOneWidget);
      expect(find.text('Search customer name, phone, plate #...'), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
      expect(find.text('Add Customer'), findsOneWidget);
    });
  });

  group('CustomerDetailScreen Tests', () {
    testWidgets('Shows fallback when customer is not found', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const CustomerDetailScreen(customerId: 'non-existent-id')),
      );

      expect(find.text('Customer Not Found'), findsOneWidget);
      expect(find.text('Go Back'), findsOneWidget);
    });

    testWidgets('Renders Opening Due in Transaction History for customer with initial balance', (tester) async {
      final repo = GarageRepository();
      final customerWithDue = Customer(
        id: 'cust-open-due-1',
        name: 'Tariq Al-Balushi',
        phone: '+968 9123 4567',
        vehicleModel: 'Lexus LX570',
        plateNumber: '1234 A',
        totalDue: 85.0,
        totalBilled: 85.0,
        totalPaid: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.createCustomer(customerWithDue);

      // Verify transaction exists in repository
      final txs = repo.getTransactionsForCustomer(customerWithDue.id, customerWithDue.name);
      expect(txs.isNotEmpty, isTrue);
      expect(txs.first.description, 'Opening Due');
      expect(txs.first.amount, 85.0);
      expect(txs.first.isDue, isTrue);

      await tester.pumpWidget(
        createTestWidget(
          CustomerDetailScreen(customerId: customerWithDue.id),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tariq Al-Balushi'), findsWidgets);
      expect(find.text('Opening Due'), findsOneWidget);
      expect(find.text('DEBIT'), findsOneWidget);
      expect(find.text('+OMR 85.000'), findsOneWidget);

      // Verify Delete icon button exists in AppBar
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

      // Tap delete icon to open confirmation dialog
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Delete Customer?'), findsOneWidget);
      expect(find.textContaining('Warning: This customer has an outstanding balance of OMR 85.000'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete Customer'), findsOneWidget);
    });
  });

  group('Customer Delete and Undo Repository Tests', () {
    test('createCustomer with initial due generates opening due transaction record', () async {
      final repo = GarageRepository();
      final customer = Customer(
        id: 'cust-opening-test',
        name: 'Opening Balance Test User',
        phone: '+968 9000 0000',
        vehicleModel: 'Toyota Land Cruiser',
        plateNumber: '7788 B',
        totalDue: 120.0,
        totalBilled: 120.0,
        totalPaid: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.createCustomer(customer);

      final txs = repo.getTransactionsForCustomer(customer.id, customer.name);
      expect(txs.length, 1);
      expect(txs.first.description, 'Opening Due');
      expect(txs.first.amount, 120.0);
      expect(txs.first.type, 'due');
    });

    test('deleteCustomer removes customer & transactions and allows 5-second undo restoration', () async {
      final repo = GarageRepository();
      final customer = Customer(
        id: 'cust-undo-test',
        name: 'Salim Al-Harthy',
        phone: '+968 9988 7766',
        vehicleModel: 'Nissan Patrol',
        plateNumber: '5544 C',
        totalDue: 50.0,
        totalBilled: 50.0,
        totalPaid: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.createCustomer(customer);
      expect(repo.getCustomerById(customer.id), isNotNull);
      expect(repo.getTransactionsForCustomer(customer.id, customer.name).isNotEmpty, isTrue);

      // Delete customer
      await repo.deleteCustomer(customer.id);
      expect(repo.getCustomerById(customer.id), isNull);
      expect(repo.lastUndoAction, isNotNull);
      expect(repo.lastUndoAction!.type, 'customer_delete');

      // Undo deletion
      await repo.undoLastAction();
      expect(repo.getCustomerById(customer.id), isNotNull);
      final restoredTxs = repo.getTransactionsForCustomer(customer.id, customer.name);
      expect(restoredTxs.isNotEmpty, isTrue);
      expect(restoredTxs.first.description, 'Opening Due');
    });
  });
}
