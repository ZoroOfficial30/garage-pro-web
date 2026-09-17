import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:garage_accounting_pro/core/theme/app_theme.dart';
import 'package:garage_accounting_pro/core/currency/currency_manager.dart';
import 'package:garage_accounting_pro/core/localization/app_locale.dart';
import 'package:garage_accounting_pro/data/models/bay_job.dart';
import 'package:garage_accounting_pro/data/models/supplier_due.dart';
import 'package:garage_accounting_pro/data/repositories/garage_repository.dart';
import 'package:garage_accounting_pro/shared/widgets/common_print_header.dart';
import 'package:garage_accounting_pro/shared/widgets/statement_modal_helper.dart';
import 'package:garage_accounting_pro/features/jobs/widgets/job_card.dart';
import 'package:garage_accounting_pro/features/jobs/screens/jobs_screen.dart';
import 'package:garage_accounting_pro/features/inventory/screens/stock_inventory_screen.dart';
import 'package:garage_accounting_pro/features/suppliers/screens/supplier_dues_screen.dart';
import 'package:garage_accounting_pro/features/suppliers/widgets/supplier_due_card.dart';
import 'package:garage_accounting_pro/features/dashboard/screens/daily_summary_screen.dart';

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
        home: Scaffold(body: child),
      ),
    );
  }

  group('1. CommonPrintHeader Widget Tests', () {
    testWidgets('Renders workshop profile information, title, and date', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const CommonPrintHeader(
            title: 'CUSTOMER STATEMENT',
            subtitle: 'Account Ledger',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check document title banner
      expect(find.text('CUSTOMER STATEMENT'), findsOneWidget);
      // Check document subtitle
      expect(find.text('Account Ledger'), findsOneWidget);
      // Check garage icon fallback when no logo
      expect(find.byIcon(Icons.garage_rounded), findsOneWidget);
    });
  });

  group('2. StatementModalHelper Widget Tests', () {
    testWidgets('Renders bottom sheet with content, Copy, WhatsApp, and Print buttons', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                StatementModalHelper.show(
                  context: context,
                  title: 'SERVICE RECEIPT',
                  subtitle: 'Bay 1 • Rahim Ahmed',
                  customerPhone: '01711223344',
                  textStatement: 'MOCK STATEMENT TEXT',
                  content: const Text('Inner Statement Content'),
                );
              },
              child: const Text('Open Modal'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Modal is open
      expect(find.text('SERVICE RECEIPT'), findsWidgets);
      expect(find.text('Inner Statement Content'), findsOneWidget);
      expect(find.text('Copy Text'), findsOneWidget);
      expect(find.byIcon(Icons.chat_rounded), findsOneWidget);
      expect(find.text('Print / Share'), findsOneWidget);
    });
  });

  group('3. Job Receipt on JobCard and JobsScreen', () {
    testWidgets('JobCard renders print receipt button and opens modal on click', (tester) async {
      final now = DateTime.now();
      final job = BayJob(
        id: 'job-1',
        bayNumber: 'Bay 1',
        customerName: 'Hasan Mahmud',
        customerPhone: '01819998877',
        vehicleModel: 'Toyota Corolla',
        plateNumber: 'DHK-1122',
        taskDescription: 'Full synthetic oil change and filter replacement',
        estimatedCost: 85.0,
        technicianName: 'Karim Bhai',
        status: 'in_progress',
        date: now,
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        createTestApp(
          child: JobCard(job: job),
        ),
      );
      await tester.pumpAndSettle();

      // Verify print receipt icon button exists on card
      final receiptBtn = find.byIcon(Icons.receipt_long_rounded);
      expect(receiptBtn, findsOneWidget);

      // Tap receipt button
      await tester.tap(receiptBtn);
      await tester.pumpAndSettle();

      // Check modal opens with receipt details
      expect(find.text('Job Card / Service Receipt'), findsOneWidget);
      expect(find.text('Full synthetic oil change and filter replacement'), findsWidgets);
      expect(find.text('Hasan Mahmud'), findsWidgets);
      expect(find.text('Copy Text'), findsOneWidget);
    });

    testWidgets('JobsScreen has Print Jobs & Bays Sheet action button', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const JobsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Print icon in AppBar
      expect(find.byIcon(Icons.print_rounded), findsOneWidget);
    });
  });

  group('4. Stock Inventory Report', () {
    testWidgets('StockInventoryScreen has Print Stock & Alert Report action', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const StockInventoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.print_rounded), findsOneWidget);
    });
  });

  group('5. Supplier Dues Statements', () {
    testWidgets('SupplierDuesScreen has Print Supplier Dues Statement action', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const SupplierDuesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.print_rounded), findsOneWidget);
    });

    testWidgets('SupplierDueCard has Print Statement in popup menu', (tester) async {
      final now = DateTime.now();
      final due = SupplierDue(
        id: 'due-101',
        companyName: 'TotalEnergies Lubricants',
        totalAmount: 500.0,
        paidAmount: 200.0,
        itemsPurchased: 'Quartz 9000 5W-40 Drums',
        date: now,
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        createTestApp(
          child: SupplierDueCard(due: due),
        ),
      );
      await tester.pumpAndSettle();

      // Open popup menu
      final moreBtn = find.byIcon(Icons.more_vert_rounded);
      expect(moreBtn, findsOneWidget);
      await tester.tap(moreBtn);
      await tester.pumpAndSettle();

      // Find Print Statement option
      expect(find.text('Print Statement'), findsOneWidget);
    });
  });

  group('6. Daily Summary Statement', () {
    testWidgets('DailySummaryScreen has print/share statement action and common header', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const DailySummaryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Header CommonPrintHeader is rendered
      expect(find.text('DAILY REPORT'), findsOneWidget);
      // AppBar print action
      expect(find.byIcon(Icons.print_rounded), findsWidgets);
    });
  });
}
