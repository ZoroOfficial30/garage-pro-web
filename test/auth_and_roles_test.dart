import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:garage_accounting_pro/core/theme/app_theme.dart';
import 'package:garage_accounting_pro/core/currency/currency_manager.dart';
import 'package:garage_accounting_pro/core/localization/app_locale.dart';
import 'package:garage_accounting_pro/data/models/app_user.dart';
import 'package:garage_accounting_pro/data/models/employee.dart';
import 'package:garage_accounting_pro/data/models/customer.dart';
import 'package:garage_accounting_pro/data/repositories/garage_repository.dart';
import 'package:garage_accounting_pro/features/auth/screens/login_screen.dart';
import 'package:garage_accounting_pro/features/employees/widgets/staff_login_management_modal.dart';
import 'package:garage_accounting_pro/features/navigation/widgets/app_navigation_drawer.dart';

void main() {
  group('Auth & RBAC Unit Tests', () {
    late GarageRepository repo;

    setUp(() {
      repo = GarageRepository();
      repo.setMockEmployees([
        Employee(
          id: 'emp-101',
          name: 'Rafiq Islam',
          role: 'Lead Mechanic',
          phone: '+880 1711-223344',
          monthlySalary: 800.0,
          pin: '4321',
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        ),
      ]);
    });

    tearDown(() {
      repo.logout();
    });

    test('Initial unauthenticated state', () {
      expect(repo.isAuthenticated, isFalse);
      expect(repo.currentUser, isNull);
      expect(repo.isOwner, isTrue); // Default fallback for backwards compatibility
      expect(repo.isStaff, isFalse);
    });

    test('Owner login with default PIN (1234) succeeds', () async {
      final success = await repo.loginOwner('1234');
      expect(success, isTrue);
      expect(repo.isAuthenticated, isTrue);
      expect(repo.isOwner, isTrue);
      expect(repo.isStaff, isFalse);
      expect(repo.currentUser?.name, 'Apex Auto Workshop');
      expect(repo.currentUser?.role, UserRole.owner);
    });

    test('Owner login with wrong PIN fails', () async {
      final success = await repo.loginOwner('9999');
      expect(success, isFalse);
      expect(repo.isAuthenticated, isFalse);
      expect(repo.currentUser, isNull);
    });

    test('Owner can update owner PIN', () async {
      await repo.setOwnerPin('5678');
      expect(repo.ownerPin, '5678');

      expect(await repo.loginOwner('1234'), isFalse);
      expect(await repo.loginOwner('5678'), isTrue);
    });

    test('Staff login with valid PIN succeeds', () async {
      final success = await repo.loginStaff('emp-101', '4321');
      expect(success, isTrue);
      expect(repo.isAuthenticated, isTrue);
      expect(repo.isStaff, isTrue);
      expect(repo.isOwner, isFalse);
      expect(repo.currentUser?.name, 'Rafiq Islam');
      expect(repo.currentUser?.role, UserRole.staff);
    });

    test('Staff login with incorrect PIN fails', () async {
      final success = await repo.loginStaff('emp-101', '0000');
      expect(success, isFalse);
      expect(repo.isAuthenticated, isFalse);
      expect(repo.currentUser, isNull);
    });

    test('Staff cannot delete customers', () async {
      final customer = Customer(
        id: 'cust-test-1',
        name: 'Test Customer',
        phone: '01700000000',
        vehicleModel: 'Toyota Corolla',
        plateNumber: 'DHK-1234',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repo.addCustomer(customer);
      expect(repo.getCustomerById('cust-test-1'), isNotNull);

      // Staff login
      await repo.loginStaff('emp-101', '4321');
      expect(repo.isStaff, isTrue);

      // Deletion blocked for Staff: customer remains intact
      await repo.deleteCustomer('cust-test-1');
      expect(repo.getCustomerById('cust-test-1'), isNotNull);

      // Owner login
      await repo.loginOwner('1234');
      expect(repo.isOwner, isTrue);

      // Deletion allowed for Owner: customer removed
      await repo.deleteCustomer('cust-test-1');
      expect(repo.getCustomerById('cust-test-1'), isNull);
    });

    test('Owner can set / change employee PIN and it auto-enables login', () async {
      await repo.loginOwner('1234');
      expect(repo.isOwner, isTrue);

      await repo.setEmployeePin('emp-101', '9876');
      final updatedEmp = repo.employees.firstWhere((e) => e.id == 'emp-101');
      expect(updatedEmp.pin, '9876');
      expect(updatedEmp.isLoginEnabled, isTrue);

      // Verify staff can now log in with new PIN
      await repo.logout();
      expect(await repo.loginStaff('emp-101', '4321'), isFalse);
      expect(await repo.loginStaff('emp-101', '9876'), isTrue);
    });

    test('Staff cannot set or change employee PIN', () async {
      await repo.loginStaff('emp-101', '4321');
      expect(repo.isStaff, isTrue);

      await repo.setEmployeePin('emp-101', '1111');
      expect(repo.employees.firstWhere((e) => e.id == 'emp-101').pin, '4321');
    });

    test('Owner can toggle employee login disabled and enabled', () async {
      await repo.loginOwner('1234');

      // Disable login
      await repo.toggleEmployeeLoginEnabled('emp-101', false);
      expect(repo.employees.firstWhere((e) => e.id == 'emp-101').isLoginEnabled, isFalse);

      // Re-enable login
      await repo.toggleEmployeeLoginEnabled('emp-101', true);
      expect(repo.employees.firstWhere((e) => e.id == 'emp-101').isLoginEnabled, isTrue);
    });

    test('Staff cannot toggle employee login state', () async {
      await repo.loginStaff('emp-101', '4321');
      expect(repo.isStaff, isTrue);

      await repo.toggleEmployeeLoginEnabled('emp-101', false);
      expect(repo.employees.firstWhere((e) => e.id == 'emp-101').isLoginEnabled, isTrue);
    });

    test('Staff login rejected when isLoginEnabled is false', () async {
      await repo.loginOwner('1234');
      await repo.toggleEmployeeLoginEnabled('emp-101', false);
      await repo.logout();

      // Attempt staff login even with correct PIN
      final success = await repo.loginStaff('emp-101', '4321');
      expect(success, isFalse);
      expect(repo.isAuthenticated, isFalse);
      expect(repo.currentUser, isNull);
    });

    test('Logout clears authenticated session', () async {
      await repo.loginOwner('1234');
      expect(repo.isAuthenticated, isTrue);

      await repo.logout();
      expect(repo.isAuthenticated, isFalse);
      expect(repo.currentUser, isNull);
    });
  });

  group('Auth & RBAC Widget Tests', () {
    testWidgets('LoginScreen renders segmented role toggle and PIN keypad', (tester) async {
      final repo = GarageRepository();
      repo.setMockEmployees([
        Employee(
          id: 'emp-101',
          name: 'Rafiq Islam',
          role: 'Lead Mechanic',
          phone: '+880 1711-223344',
          monthlySalary: 800.0,
          pin: '4321',
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        ),
      ]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: repo),
            ChangeNotifierProvider(create: (_) => CurrencyManager()),
            ChangeNotifierProvider(create: (_) => AppLocaleManager()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme(),
            home: const LoginScreen(),
          ),
        ),
      );

      // Verify Workshop Name & Role Toggles
      expect(find.text('Owner'), findsOneWidget);
      expect(find.text('Staff'), findsOneWidget);
      expect(find.text('Enter Owner PIN'), findsOneWidget);

      // Verify Keypad Digits
      for (int i = 0; i <= 9; i++) {
        expect(find.text('$i'), findsOneWidget);
      }

      // Tap digits '1', '2', '3', '4'
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('4'));
      await tester.pump();

      // Scroll to & Tap Login button
      await tester.ensureVisible(find.text('Login as Owner'));
      await tester.tap(find.text('Login as Owner'));
      await tester.pumpAndSettle();

      expect(repo.isAuthenticated, isTrue);
      expect(repo.isOwner, isTrue);
    });

    testWidgets('AppNavigationDrawer displays Owner view with all modules', (tester) async {
      final repo = GarageRepository();
      await repo.loginOwner('1234');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: repo),
            ChangeNotifierProvider(create: (_) => CurrencyManager()),
            ChangeNotifierProvider(create: (_) => AppLocaleManager()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme(),
            home: Scaffold(
              drawer: AppNavigationDrawer(
                onSelectCashbook: () {},
                onSelectInventory: () {},
                onSelectSupplierDues: () {},
                onSelectStaff: () {},
                onSelectDashboard: () {},
                onSelectSettings: () {},
              ),
              body: Container(),
            ),
          ),
        ),
      );

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('OWNER / ADMIN'), findsOneWidget);
      expect(find.text('Cashbook'), findsOneWidget);
      expect(find.text('Stock / Inventory'), findsOneWidget);
      expect(find.text('Supplier Dues'), findsOneWidget);
      expect(find.text('Staff & Attendance'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Switch User / Logout'), findsOneWidget);
    });

    testWidgets('AppNavigationDrawer displays Staff view hiding Cashbook, Supplier Dues, Dashboard & Settings', (tester) async {
      final repo = GarageRepository();
      repo.setMockEmployees([
        Employee(
          id: 'emp-102',
          name: 'Jamal Hossain',
          role: 'Technician',
          phone: '+880 1811-223344',
          monthlySalary: 700.0,
          pin: '5555',
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        ),
      ]);
      await repo.loginStaff('emp-102', '5555');
      expect(repo.isStaff, isTrue);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: repo),
            ChangeNotifierProvider(create: (_) => CurrencyManager()),
            ChangeNotifierProvider(create: (_) => AppLocaleManager()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme(),
            home: Scaffold(
              drawer: AppNavigationDrawer(
                onSelectCashbook: () {},
                onSelectInventory: () {},
                onSelectSupplierDues: () {},
                onSelectStaff: () {},
                onSelectDashboard: () {},
                onSelectSettings: () {},
              ),
              body: Container(),
            ),
          ),
        ),
      );

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('STAFF • Jamal Hossain'), findsOneWidget);
      expect(find.text('Stock / Inventory'), findsOneWidget);
      expect(find.text('Staff & Attendance'), findsOneWidget);
      expect(find.text('Switch User / Logout'), findsOneWidget);

      expect(find.text('Cashbook'), findsNothing);
      expect(find.text('Supplier Dues'), findsNothing);
      expect(find.text('Dashboard'), findsNothing);
      expect(find.text('Settings'), findsNothing);
    });

    testWidgets('LoginScreen filters out staff members with login disabled', (tester) async {
      final repo = GarageRepository();
      repo.setMockEmployees([
        Employee(
          id: 'emp-1',
          name: 'Active Staff',
          role: 'Mechanic',
          phone: '+880 1711-111111',
          monthlySalary: 600.0,
          pin: '1111',
          isLoginEnabled: true,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        ),
        Employee(
          id: 'emp-2',
          name: 'Disabled Staff',
          role: 'Cleaner',
          phone: '+880 1722-222222',
          monthlySalary: 400.0,
          pin: '2222',
          isLoginEnabled: false,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        ),
      ]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: repo),
            ChangeNotifierProvider(create: (_) => CurrencyManager()),
            ChangeNotifierProvider(create: (_) => AppLocaleManager()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme(),
            home: const LoginScreen(),
          ),
        ),
      );

      // Switch to Staff tab
      await tester.tap(find.text('Staff'));
      await tester.pumpAndSettle();

      // Dropdown should show Active Staff
      expect(find.text('Active Staff • Mechanic'), findsOneWidget);
      // Disabled Staff should not be selected or shown
      expect(find.text('Disabled Staff • Cleaner'), findsNothing);
    });

    testWidgets('StaffLoginManagementModal renders staff list with PIN controls for Owner', (tester) async {
      final repo = GarageRepository();
      await repo.loginOwner('1234');
      repo.setMockEmployees([
        Employee(
          id: 'emp-101',
          name: 'Rafiq Islam',
          role: 'Lead Mechanic',
          phone: '+880 1711-223344',
          monthlySalary: 800.0,
          pin: '4321',
          isLoginEnabled: true,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        ),
      ]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: repo),
            ChangeNotifierProvider(create: (_) => CurrencyManager()),
            ChangeNotifierProvider(create: (_) => AppLocaleManager()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme(),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => StaffLoginManagementModal.show(context),
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open Modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Verify Modal contents
      expect(find.text('Staff Login & Access'), findsOneWidget);
      expect(find.text('OWNER ONLY'), findsOneWidget);
      expect(find.text('Rafiq Islam'), findsOneWidget);
      expect(find.textContaining('Lead Mechanic'), findsOneWidget);
      expect(find.text('Change PIN'), findsOneWidget);
      expect(find.text('Disable'), findsOneWidget);
    });
  });
}
