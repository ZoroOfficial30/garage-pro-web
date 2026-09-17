import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:garage_accounting_pro/core/theme/app_theme.dart';
import 'package:garage_accounting_pro/core/currency/currency_manager.dart';
import 'package:garage_accounting_pro/core/localization/app_locale.dart';
import 'package:garage_accounting_pro/data/repositories/garage_repository.dart';
import 'package:garage_accounting_pro/data/models/customer.dart';
import 'package:garage_accounting_pro/data/models/stock_item.dart';
import 'package:garage_accounting_pro/data/models/bay_job.dart';
import 'package:garage_accounting_pro/data/models/transaction_record.dart';
import 'package:garage_accounting_pro/data/models/expense_record.dart';
import 'package:garage_accounting_pro/features/customers/widgets/customer_card.dart';
import 'package:garage_accounting_pro/features/inventory/widgets/stock_item_card.dart';
import 'package:garage_accounting_pro/features/dashboard/widgets/bay_job_card.dart';
import 'package:garage_accounting_pro/features/dashboard/widgets/kpi_card.dart';
import 'package:garage_accounting_pro/features/home/widgets/chat_feed_item.dart';
import 'package:garage_accounting_pro/features/expenses/widgets/expense_card.dart';
import 'package:garage_accounting_pro/features/home/widgets/customer_command_suggestions.dart';
import 'package:garage_accounting_pro/features/home/widgets/expense_category_suggestions.dart';
import 'package:garage_accounting_pro/features/home/widgets/income_preset_suggestions.dart';
import 'package:garage_accounting_pro/features/home/services/command_parser.dart';

void main() {
  Widget wrapWithTheme(Widget child, {Size size = const Size(320, 700)}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GarageRepository()),
        ChangeNotifierProvider(create: (_) => CurrencyManager()),
        ChangeNotifierProvider(create: (_) => AppLocaleManager()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme(),
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: size.width,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('Mobile Responsive Layout & Text Overflow Tests (320px screen)', () {
    testWidgets('CustomerCard renders long customer name without overflowing', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final customer = Customer(
        id: 'cust-long',
        name: 'Mohammed Al-Mansoor Bin Khalid Al-Hashimi Supreme Motors Enterprise Logistics',
        phone: '+968 9123 4567 8901',
        vehicleModel: 'Toyota Land Cruiser V8 Twin Turbo 2024 GR-Sport Edition',
        plateNumber: 'DXB-98765-Oman-Special-Plate',
        totalDue: 45890.750,
        isVip: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        wrapWithTheme(
          CustomerCard(
            customer: customer,
            onTap: () {},
            onCollectPay: () {},
            onCall: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CustomerCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('StockItemCard renders multi-line item name and formatted prices without overflowing', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final stock = StockItem(
        id: 'stock-long',
        name: 'Premium High Performance Semi-Synthetic Heavy Duty Engine Motor Oil 5W-30 Titanium',
        brand: 'Mobil 1 / Liqui Moly Ultra Extended',
        sku: 'OIL-MOB1-5W30-LONG-SKU-999',
        quantity: 9999,
        reorderThreshold: 50,
        costPrice: 1250.500,
        sellingPrice: 1890.750,
        unit: 'Liters',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        wrapWithTheme(
          StockItemCard(
            item: stock,
            onDispense: () {},
            onAddStock: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StockItemCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('BayJobCard renders long task description and vehicle model without overflowing', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final job = BayJob(
        id: 'job-long',
        bayNumber: 'Bay 04 Heavy Lift System',
        customerName: 'Sheikh Abdullah Bin Abdulaziz Al-Hassan',
        vehicleModel: 'Mercedes-Benz AMG G63 V8 Biturbo Edition 1 Night Package',
        taskDescription: 'Complete automatic transmission fluid flush, brake caliper replacement, ceramic rotor resurfacing, and high-pressure fuel injector diagnosis',
        technicianName: 'Master Lead Specialist Eng. Tariq Rahman',
        estimatedCost: 8950.000,
        status: 'in_progress',
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        wrapWithTheme(
          BayJobCard(
            job: job,
            currency: CurrencyManager(),
            onStatusChange: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BayJobCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ChatFeedItem renders 3-line speech bubble and confirmation badge without overflowing', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final record = TransactionRecord(
        id: 'tx-long',
        customerId: 'c1',
        customerName: 'Sheikh Mohammed',
        type: 'due',
        amount: 15400.0,
        description: 'Brake pads replacement and full engine overhaul with ceramic brake fluid flush and synthetic oil change service',
        date: DateTime.now(),
        runningBalance: 32500.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        wrapWithTheme(
          ChatFeedItem(
            record: record,
            formattedAmount: 'OMR 15,400.000',
            formattedRunningBalance: 'OMR 32,500.000',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChatFeedItem), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ExpenseCard renders long title and wrapped tags without overflowing', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final expense = ExpenseRecord(
        id: 'exp-long',
        title: 'Monthly Industrial Hydraulic Lift Inspection Certification and Safety Overhaul Fee',
        category: 'Heavy Equipment Maintenance & Tools',
        amount: 4500.0,
        paymentMethod: 'Commercial Bank Direct Wire Transfer',
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        wrapWithTheme(
          ExpenseCard(
            expense: expense,
            onEdit: () {},
            onDelete: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ExpenseCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('KpiCard renders with responsive aspect ratio and title wrapping', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        wrapWithTheme(
          KpiCard(
            title: 'TOTAL OUTSTANDING CUSTOMER OVERDUE BALANCES',
            amount: 'OMR 125,980.500',
            subtitle: '48 Customers with pending dues',
            icon: Icons.warning_amber_rounded,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(KpiCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Suggestions overlays render cleanly on 320px width', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final draftDue = CommandDraft(
        type: CommandType.due,
        query: 'Abdul',
        amount: 2500.0,
        rawText: '+due Abdul 2500',
      );

      final customer = Customer(
        id: 'c-test',
        name: 'Abdul Latif Al-Qasimi',
        phone: '+968 99887766',
        vehicleModel: 'Lexus LX600 Turbo',
        plateNumber: 'DXB-12345',
        totalDue: 1850.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        wrapWithTheme(
          CustomerCommandSuggestions(
            draft: draftDue,
            matchingCustomers: [customer],
            currency: CurrencyManager(),
            onSelectCustomer: (_) {},
            onCreateNewCustomer: (_) {},
            onClose: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CustomerCommandSuggestions), findsOneWidget);
      expect(tester.takeException(), isNull);

      final draftExp = CommandDraft(
        type: CommandType.expense,
        query: '',
        amount: 350.0,
        rawText: 'ex 350',
      );

      await tester.pumpWidget(
        wrapWithTheme(
          ExpenseCategorySuggestions(
            draft: draftExp,
            currency: CurrencyManager(),
            onSelectCategory: (catKey, catLabel) {},
            onClose: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ExpenseCategorySuggestions), findsOneWidget);
      expect(tester.takeException(), isNull);

      final draftIn = CommandDraft(
        type: CommandType.income,
        query: '',
        amount: 75.0,
        rawText: 'in 75',
      );

      await tester.pumpWidget(
        wrapWithTheme(
          IncomePresetSuggestions(
            draft: draftIn,
            currency: CurrencyManager(),
            onSelectCategory: (category, displayLabel) {},
            onClose: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(IncomePresetSuggestions), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
