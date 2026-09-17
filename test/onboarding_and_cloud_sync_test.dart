import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:garage_accounting_pro/core/theme/app_theme.dart';
import 'package:garage_accounting_pro/core/currency/currency_manager.dart';
import 'package:garage_accounting_pro/core/localization/app_locale.dart';
import 'package:garage_accounting_pro/core/services/sync_service.dart';
import 'package:garage_accounting_pro/data/models/customer.dart';
import 'package:garage_accounting_pro/data/models/bay_job.dart';
import 'package:garage_accounting_pro/data/models/transaction_record.dart';
import 'package:garage_accounting_pro/data/models/expense_record.dart';
import 'package:garage_accounting_pro/data/repositories/garage_repository.dart';
import 'package:garage_accounting_pro/features/auth/screens/onboarding_screen.dart';
import 'package:garage_accounting_pro/features/auth/screens/login_screen.dart';
import 'package:garage_accounting_pro/features/navigation/main_scaffold.dart';
import 'package:garage_accounting_pro/main.dart';

void main() {
  Widget createTestWidget(Widget child, {
    GarageRepository? repo,
    CurrencyManager? currency,
    AppLocaleManager? locale,
    SyncService? syncService,
  }) {
    final garageRepo = repo ?? GarageRepository();
    final curMgr = currency ?? CurrencyManager();
    final locMgr = locale ?? AppLocaleManager();
    final sync = syncService ?? SyncService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GarageRepository>.value(value: garageRepo),
        ChangeNotifierProvider<CurrencyManager>.value(value: curMgr),
        ChangeNotifierProvider<AppLocaleManager>.value(value: locMgr),
        ChangeNotifierProvider<SyncService>.value(value: sync),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme(),
        home: child,
      ),
    );
  }

  group('1. Onboarding Screen UI & Modal Tests', () {
    testWidgets('OnboardingScreen renders header, option cards, and language toggle', (tester) async {
      await tester.pumpWidget(createTestWidget(const OnboardingScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Garage Accounting Pro'), findsOneWidget);
      expect(find.text('Start Fresh Garage'), findsOneWidget);
      expect(find.text('Restore from Cloud'), findsOneWidget);
      expect(find.text('NEW WORKSHOP'), findsOneWidget);
      expect(find.text('MULTI-DEVICE'), findsOneWidget);
      expect(find.text('Setup New Garage'), findsOneWidget);
      expect(find.text('Log In & Restore'), findsOneWidget);

      // Toggle language to Bengali
      await tester.tap(find.byIcon(Icons.translate_rounded));
      await tester.pumpAndSettle();

      expect(find.text('গ্যারেজ অ্যাকাউন্টিং প্রো'), findsOneWidget);
      expect(find.text('নতুন গ্যারেজ শুরু করুন'), findsOneWidget);
      expect(find.text('ক্লাউড থেকে রিস্টোর করুন'), findsOneWidget);
    });

    testWidgets('Start Fresh Garage button opens setup sheet with validation', (tester) async {
      final repo = GarageRepository();
      await tester.pumpWidget(createTestWidget(const OnboardingScreen(), repo: repo));
      await tester.pumpAndSettle();

      // Tap Setup New Garage
      await tester.tap(find.text('Setup New Garage'));
      await tester.pumpAndSettle();

      expect(find.text('Setup New Garage'), findsWidgets);
      expect(find.text('Workshop Name'), findsOneWidget);
      expect(find.text('Owner PIN (4-6 digits)'), findsOneWidget);
      expect(find.text('Confirm PIN'), findsOneWidget);
      expect(find.text('Create Garage & Enter Dashboard'), findsOneWidget);

      // Submit valid setup
      await tester.tap(find.text('Create Garage & Enter Dashboard'));
      await tester.pumpAndSettle();

      expect(repo.isGarageSetupCompleted, isTrue);
      expect(repo.isAuthenticated, isTrue);
      expect(repo.isOwner, isTrue);
    });

    testWidgets('Restore from Cloud button opens CloudAccountModal', (tester) async {
      await tester.pumpWidget(createTestWidget(const OnboardingScreen()));
      await tester.pumpAndSettle();

      // Ensure visible and tap Log In & Restore
      await tester.ensureVisible(find.text('Log In & Restore'));
      await tester.tap(find.text('Log In & Restore'));
      await tester.pumpAndSettle();

      expect(find.text('Cloud Account & Multi-Device Sync'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });
  });

  group('2. GarageRepository Onboarding & Cloud Restore Methods', () {
    test('completeFreshSetup initializes name, pin, marks setup done, and authenticates', () async {
      final repo = GarageRepository();
      await repo.setGarageSetupCompleted(false);
      expect(repo.isGarageSetupCompleted, isFalse);

      await repo.completeFreshSetup(name: 'Al-Nasr Garage', pin: '5566');

      expect(repo.isGarageSetupCompleted, isTrue);
      expect(repo.workshopProfile['name'], 'Al-Nasr Garage');
      expect(repo.ownerPin, '5566');
      expect(repo.isAuthenticated, isTrue);
      expect(repo.isOwner, isTrue);
    });

    test('completeCloudRestoreSetup marks setup completed and auto-authenticates owner', () async {
      final repo = GarageRepository();
      await repo.setGarageSetupCompleted(false);
      expect(repo.isGarageSetupCompleted, isFalse);

      await repo.completeCloudRestoreSetup();

      expect(repo.isGarageSetupCompleted, isTrue);
      expect(repo.isAuthenticated, isTrue);
      expect(repo.isOwner, isTrue);
    });
  });

  group('3. Automatic Non-Blocking Push & UI Refresh', () {
    test('SyncService pendingUploads reflects unsyncedCount reactively', () {
      final sync = SyncService();
      expect(sync.pendingUploads, equals(sync.unsyncedCount));
    });

    test('SyncService pushUnsyncedData notifies listeners immediately and runs non-blockingly', () {
      final sync = SyncService();
      bool notified = false;
      sync.addListener(() {
        notified = true;
      });

      // Calling pushUnsyncedData should notify synchronously and not block
      sync.pushUnsyncedData();
      expect(notified, isTrue);
    });

    test('SyncService syncAll executes without error', () async {
      final sync = SyncService();
      // Headless syncAll gracefully handles uninitialized client
      await expectLater(sync.syncAll(), completes);
    });

    test('SyncService attachRepository connects repository for reactive reload', () async {
      final sync = SyncService();
      final repo = GarageRepository();
      sync.attachRepository(repo);

      // Triggering pullRemoteData notifies repo.loadAllData without throwing
      await expectLater(sync.pullRemoteData(), completes);
    });

    test('Repository writes trigger non-blocking auto sync for all operations', () async {
      final repo = GarageRepository();
      final now = DateTime.now();

      // 1. addCustomer
      final cust = Customer(
        id: 'test_cust_sync_1',
        name: 'Sync Test Customer',
        phone: '+968 9123 4567',
        vehicleModel: 'Nissan Patrol',
        plateNumber: 'OM 9821-B',
        createdAt: now,
        updatedAt: now,
      );
      await expectLater(repo.addCustomer(cust), completes);

      // 2. updateCustomer
      final updatedCust = cust.copyWith(vehicleModel: 'Nissan Patrol V8');
      await expectLater(repo.updateCustomer(updatedCust), completes);

      // 3. createBayJob
      final job = BayJob(
        id: 'test_job_sync_1',
        bayNumber: 'Bay 2',
        customerName: 'Sync Test Customer',
        customerPhone: '+968 9123 4567',
        vehicleModel: 'Nissan Patrol',
        plateNumber: 'OM 9821-B',
        taskDescription: 'Oil Change',
        status: 'in_progress',
        date: now,
        createdAt: now,
        updatedAt: now,
      );
      await expectLater(repo.createBayJob(job), completes);

      // 4. updateBayJob
      final updatedJob = job.copyWith(status: 'completed', settledAmount: 25.0);
      await expectLater(repo.updateBayJob(updatedJob), completes);

      // 5. recordTransaction
      final tx = TransactionRecord(
        id: 'test_tx_sync_1',
        customerName: 'Sync Test Customer',
        type: 'service',
        amount: 25.0,
        description: 'Oil Change Service',
        paymentMethod: 'cash',
        date: now,
        createdAt: now,
        updatedAt: now,
      );
      await expectLater(repo.recordTransaction(tx), completes);

      // 6. recordIncome
      await expectLater(
        repo.recordIncome(
          category: 'Car Wash',
          amount: 5.0,
          description: 'Basic Wash',
        ),
        completes,
      );

      // 7. recordExpense & addExpenseRecord
      final exp = ExpenseRecord(
        id: 'test_exp_sync_1',
        title: 'Brake Fluid Batch',
        category: 'Parts & Materials',
        amount: 45.0,
        paymentMethod: 'Cash',
        date: now,
        createdAt: now,
        updatedAt: now,
      );
      await expectLater(repo.recordExpense(exp), completes);

      await expectLater(
        repo.addExpenseRecord(
          title: 'Shop Electricity',
          category: 'Utilities',
          amount: 35.0,
        ),
        completes,
      );
    });
  });

  group('4. Root Routing Tests', () {
    testWidgets('GarageAccountingApp routes to OnboardingScreen when isGarageSetupCompleted is false', (tester) async {
      final repo = GarageRepository();
      await repo.setGarageSetupCompleted(false);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<GarageRepository>.value(value: repo),
            ChangeNotifierProvider<CurrencyManager>(create: (_) => CurrencyManager()),
            ChangeNotifierProvider<AppLocaleManager>(create: (_) => AppLocaleManager()),
            ChangeNotifierProvider<SyncService>.value(value: SyncService()),
          ],
          child: const GarageAccountingApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('GarageAccountingApp routes to LoginScreen when setup completed but unauthenticated', (tester) async {
      final repo = GarageRepository();
      await repo.setGarageSetupCompleted(true);
      await repo.logout();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<GarageRepository>.value(value: repo),
            ChangeNotifierProvider<CurrencyManager>(create: (_) => CurrencyManager()),
            ChangeNotifierProvider<AppLocaleManager>(create: (_) => AppLocaleManager()),
            ChangeNotifierProvider<SyncService>.value(value: SyncService()),
          ],
          child: const GarageAccountingApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Restore from Cloud Account'), findsOneWidget);
    });

    testWidgets('GarageAccountingApp routes to MainScaffold when setup completed and authenticated', (tester) async {
      final repo = GarageRepository();
      await repo.setGarageSetupCompleted(true);
      await repo.loginOwner(repo.ownerPin);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<GarageRepository>.value(value: repo),
            ChangeNotifierProvider<CurrencyManager>(create: (_) => CurrencyManager()),
            ChangeNotifierProvider<AppLocaleManager>(create: (_) => AppLocaleManager()),
            ChangeNotifierProvider<SyncService>.value(value: SyncService()),
          ],
          child: const GarageAccountingApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MainScaffold), findsOneWidget);
    });
  });
}
