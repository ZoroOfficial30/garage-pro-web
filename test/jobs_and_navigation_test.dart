import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:garage_accounting_pro/core/theme/app_theme.dart';
import 'package:garage_accounting_pro/core/currency/currency_manager.dart';
import 'package:garage_accounting_pro/core/localization/app_locale.dart';
import 'package:garage_accounting_pro/data/repositories/garage_repository.dart';
import 'package:garage_accounting_pro/data/models/bay_job.dart';
import 'package:garage_accounting_pro/data/models/customer.dart';
import 'package:garage_accounting_pro/features/navigation/main_scaffold.dart';
import 'package:garage_accounting_pro/features/navigation/widgets/app_navigation_drawer.dart';
import 'package:garage_accounting_pro/features/jobs/screens/jobs_screen.dart';
import 'package:garage_accounting_pro/features/jobs/widgets/job_card.dart';
import 'package:garage_accounting_pro/features/dashboard/screens/dashboard_screen.dart';
import 'package:garage_accounting_pro/features/dashboard/widgets/weekly_cash_flow_chart.dart';
import 'package:garage_accounting_pro/features/cashbook/screens/cashbook_screen.dart';
import 'package:garage_accounting_pro/features/inventory/screens/stock_inventory_screen.dart';
import 'package:garage_accounting_pro/features/employees/screens/employees_screen.dart';
import 'package:garage_accounting_pro/features/settings/screens/settings_screen.dart';

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

  group('Navigation Structure: Bottom Bar & Drawer Tests', () {
    testWidgets('MainScaffold renders strictly 3 bottom tabs (Home, Customers, Jobs) and zero secondary tabs', (tester) async {
      await tester.pumpWidget(createTestApp(child: const MainScaffold()));
      await tester.pump(const Duration(milliseconds: 300));

      // Verify strictly 3 operational tabs
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Customers'), findsOneWidget);
      expect(find.text('Jobs'), findsOneWidget);

      // Verify secondary management modules are NOT in bottom navigation bar
      expect(find.text('Stock'), findsNothing);
      expect(find.text('Cashbook'), findsNothing);
      expect(find.text('Staff'), findsNothing);
      expect(find.text('Dashboard'), findsNothing);

      // Verify exactly 3 NavigationDestination items
      final destinations = find.byType(NavigationDestination);
      expect(destinations, findsNWidgets(3));

      // Tap Jobs tab to switch directly
      await tester.tap(find.text('Jobs'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Jobs & Active Bays'), findsOneWidget);
      expect(find.text('+ Open New Job'), findsOneWidget);
    });

    testWidgets('Navigation Drawer contains strictly 5 secondary management modules with zero duplicates', (tester) async {
      await tester.pumpWidget(createTestApp(child: const MainScaffold()));
      await tester.pump(const Duration(milliseconds: 300));

      // Open drawer via hamburger button
      final menuBtn = find.byIcon(Icons.menu_rounded);
      expect(menuBtn, findsWidgets);
      await tester.tap(menuBtn.first);
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Drawer is open
      expect(find.byType(AppNavigationDrawer), findsOneWidget);

      // Verify header contents
      expect(find.descendant(of: find.byType(AppNavigationDrawer), matching: find.text('Online Sync Active')), findsOneWidget);

      // Verify strictly 5 secondary management items
      expect(find.text('Cashbook'), findsOneWidget);
      expect(find.text('Stock / Inventory'), findsOneWidget);
      expect(find.text('Staff & Attendance'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Verify zero duplicates: Home, Customers, and Jobs are NOT in the drawer
      expect(find.text('Jobs / Active Bays'), findsNothing);
      // 'Home' and 'Customers' only exist in the bottom bar, not duplicated in the drawer list
      expect(find.widgetWithText(ListTile, 'Home'), findsNothing);
      expect(find.widgetWithText(ListTile, 'Customers'), findsNothing);
      expect(find.widgetWithText(ListTile, 'Jobs'), findsNothing);
    });

    testWidgets('Navigation Drawer opens secondary screens on tap', (tester) async {
      await tester.pumpWidget(createTestApp(child: const MainScaffold()));
      await tester.pump(const Duration(milliseconds: 300));

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu_rounded).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));

      // Tap Cashbook
      await tester.tap(find.text('Cashbook'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));

      // Verify CashbookScreen is open with prominent back button (canPop is true)
      expect(find.byType(CashbookScreen), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      // Tap back button to return to MainScaffold
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));

      // Verify returned to MainScaffold
      expect(find.byType(CashbookScreen), findsNothing);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('Sub-screens consistently render hamburger button and drawer', (tester) async {
      final repo = GarageRepository();

      // Test JobsScreen
      await tester.pumpWidget(createTestApp(child: const JobsScreen(), repo: repo));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);

      // Test StockInventoryScreen
      await tester.pumpWidget(createTestApp(child: const StockInventoryScreen(), repo: repo));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);

      // Test DashboardScreen
      await tester.pumpWidget(createTestApp(child: const DashboardScreen(), repo: repo));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);

      // Test SettingsScreen
      await tester.pumpWidget(createTestApp(child: const SettingsScreen(), repo: repo));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);

      // Test EmployeesScreen
      await tester.pumpWidget(createTestApp(child: const EmployeesScreen(), repo: repo));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
    });
  });

  group('Step 3: Dedicated Jobs & Active Bays Screen Tests', () {
    testWidgets('JobsScreen renders + Open New Job button and KPI metrics', (tester) async {
      final repo = GarageRepository();
      await tester.pumpWidget(createTestApp(child: const JobsScreen(), repo: repo));
      await tester.pumpAndSettle();

      // Verify header and primary 54px action button
      expect(find.text('Jobs & Active Bays'), findsOneWidget);
      expect(find.text('+ Open New Job'), findsOneWidget);

      // Verify KPI metrics and filters
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Waiting'), findsWidgets);
      expect(find.text('Ready'), findsWidgets);
      expect(find.textContaining('All Active'), findsOneWidget);
      expect(find.textContaining('Ready for Pickup'), findsWidgets);
      expect(find.textContaining('Completed'), findsWidgets);
    });

    testWidgets('JobCard renders Waiting job with Edit Details and Mark Ready buttons', (tester) async {
      final repo = GarageRepository();
      final job = BayJob(
        id: 'job-1',
        bayNumber: 'Bay 1',
        customerName: 'Ahmed Al-Busaidi',
        customerPhone: '96891234567',
        vehicleModel: 'Toyota Land Cruiser',
        plateNumber: '1234 DX',
        taskDescription: 'Front brake pad replacement and disc skimming',
        estimatedCost: 65.0,
        status: 'waiting',
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestApp(child: Scaffold(body: JobCard(job: job)), repo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Bay 1'), findsOneWidget);
      expect(find.text('Ahmed Al-Busaidi'), findsOneWidget);
      expect(find.text('Toyota Land Cruiser'), findsOneWidget);
      expect(find.text('1234 DX'), findsOneWidget);
      expect(find.text('Edit / Bargain'), findsOneWidget);
      expect(find.text('Mark Ready'), findsOneWidget);
    });

    testWidgets('JobCard Mark Ready displays Ready for Pickup banner with Send WhatsApp and close (X) button that dismisses it', (tester) async {
      final repo = GarageRepository();
      final job = BayJob(
        id: 'job-mark-ready',
        bayNumber: 'Bay 3',
        customerName: 'Tariq Rahman',
        customerPhone: '96891112233',
        vehicleModel: 'Honda Civic',
        plateNumber: '9988 HC',
        taskDescription: 'Brake pad inspection',
        estimatedCost: 35.0,
        status: 'waiting',
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestApp(child: Scaffold(body: JobCard(job: job)), repo: repo));
      await tester.pumpAndSettle();

      // Tap Mark Ready
      await tester.tap(find.text('Mark Ready'));
      await tester.pumpAndSettle(); // let SnackBar entrance animation settle

      // Verify banner content, Send WhatsApp action, and close (X) button
      expect(find.text('Job #Bay 3 is marked Ready for Pickup!'), findsOneWidget);
      expect(find.text('Send WhatsApp'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Verify touch target for close button
      final closeButtonFinder = find.byWidgetPredicate((w) => w is IconButton && w.icon is Icon && (w.icon as Icon).icon == Icons.close);
      expect(closeButtonFinder, findsOneWidget);
      final size = tester.getSize(closeButtonFinder);
      expect(size.width, greaterThanOrEqualTo(40.0));
      expect(size.height, greaterThanOrEqualTo(40.0));

      // Tap close (X) button
      await tester.tap(closeButtonFinder);
      await tester.pumpAndSettle();

      // Banner should disappear completely
      expect(find.text('Job #Bay 3 is marked Ready for Pickup!'), findsNothing);
    });

    testWidgets('JobCard renders Ready for Pickup with WhatsApp Alert and Complete & Settle buttons', (tester) async {
      final repo = GarageRepository();
      final job = BayJob(
        id: 'job-2',
        bayNumber: 'Bay 2',
        customerName: 'Sultan Al-Harthy',
        customerPhone: '96898765432',
        vehicleModel: 'Nissan Patrol',
        plateNumber: '5678 AA',
        taskDescription: 'Synthetic oil service and spark plugs',
        estimatedCost: 80.0,
        status: 'ready_for_pickup',
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestApp(child: Scaffold(body: JobCard(job: job)), repo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Bay 2'), findsOneWidget);
      expect(find.text('Send Ready Alert (WhatsApp)'), findsOneWidget);
      expect(find.text('Complete & Settle'), findsOneWidget);
    });

    testWidgets('GarageRepository settles job with partial payment split and supports undo', (tester) async {
      final repo = GarageRepository();

      // Register a customer
      final customer = Customer(
        id: 'cust-split',
        name: 'Rashid Al-Noor',
        phone: '96895551234',
        vehicleModel: 'Mitsubishi Pajero',
        plateNumber: '4455 OB',
        totalDue: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repo.createCustomer(customer);

      // Create a job
      final job = BayJob(
        id: 'job-split',
        bayNumber: 'Bay 3',
        customerId: customer.id,
        customerName: customer.name,
        customerPhone: customer.phone,
        vehicleModel: 'Mitsubishi Pajero',
        plateNumber: '4455 OB',
        taskDescription: 'Clutch replacement',
        estimatedCost: 100.0,
        status: 'ready_for_pickup',
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repo.createBayJob(job);

      // Settle job: 100 total, 60 paid now, 40 remaining as due
      final initialIncome = repo.todayIncome;
      await repo.settleBayJob(
        jobId: job.id,
        finalBill: 100.0,
        paidNow: 60.0,
        remainingDue: 40.0,
        paymentMethod: 'cash',
      );

      // Verify settled status
      final settledJob = repo.bayJobs.firstWhere((j) => j.id == job.id);
      expect(settledJob.status, 'completed');
      expect(settledJob.paidAmount, 60.0);
      expect(settledJob.dueAmount, 40.0);

      // Verify income increased by 60
      expect(repo.todayIncome, initialIncome + 60.0);

      // Verify customer due updated to 40
      final updatedCust = repo.customers.firstWhere((c) => c.id == customer.id);
      expect(updatedCust.totalDue, 40.0);

      // Verify 5-second undo window is active
      expect(repo.lastUndoAction, isNotNull);
      expect(repo.lastUndoAction!.title, contains('Job Settled'));

      // Undo the settlement
      await repo.undoLastAction();

      // Verify job restored to ready_for_pickup
      final restoredJob = repo.bayJobs.firstWhere((j) => j.id == job.id);
      expect(restoredJob.status, 'ready_for_pickup');

      // Verify income reverted
      expect(repo.todayIncome, initialIncome);

      // Verify customer due reverted to 0
      final restoredCust = repo.customers.firstWhere((c) => c.id == customer.id);
      expect(restoredCust.totalDue, 0.0);
    });
  });

  group('Step 3: Dashboard Cleanup Tests', () {
    testWidgets('DashboardScreen renders 2x2 KPI cards and WeeklyCashFlowChart without active bay jobs', (tester) async {
      final repo = GarageRepository();
      await tester.pumpWidget(createTestApp(child: const DashboardScreen(), repo: repo));
      await tester.pumpAndSettle();

      // KPI cards exist
      expect(find.text("TODAY'S INCOME"), findsOneWidget);
      expect(find.text("TODAY'S EXPENSE"), findsOneWidget);
      expect(find.text('TOTAL OUTSTANDING DUES'), findsOneWidget);
      expect(find.text('LOW STOCK ALERTS'), findsOneWidget);

      // Weekly cash flow chart exists
      expect(find.byType(WeeklyCashFlowChart), findsOneWidget);
      expect(find.text('Weekly Cash Flow'), findsOneWidget);

      // Active bay jobs section should NOT be present on Dashboard
      expect(find.text('Active Bay Jobs'), findsNothing);
      expect(find.text('No active bay jobs currently in shop.'), findsNothing);
    });
  });
}
