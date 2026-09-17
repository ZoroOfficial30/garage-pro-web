import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:garage_accounting_pro/core/theme/app_theme.dart';
import 'package:garage_accounting_pro/core/currency/currency_manager.dart';
import 'package:garage_accounting_pro/core/localization/app_locale.dart';
import 'package:garage_accounting_pro/core/constants/api_constants.dart';
import 'package:garage_accounting_pro/core/services/sync_service.dart';
import 'package:garage_accounting_pro/data/models/customer.dart';
import 'package:garage_accounting_pro/data/models/bay_job.dart';
import 'package:garage_accounting_pro/data/models/transaction_record.dart';
import 'package:garage_accounting_pro/data/repositories/garage_repository.dart';
import 'package:garage_accounting_pro/features/settings/screens/settings_screen.dart';
import 'package:garage_accounting_pro/features/settings/widgets/cloud_account_modal.dart';

void main() {
  group('1. Supabase Constants & Configuration Tests', () {
    test('ApiConstants contains valid Supabase URL and publishable key', () {
      expect(ApiConstants.supabaseUrl, equals('https://dnrnfvleqkttwiwanyts.supabase.co'));
      expect(ApiConstants.supabaseAnonKey, startsWith('sb_publishable_'));
    });
  });

  group('2. Serialization & Supabase Mapping Tests', () {
    test('Customer model serialization and deserialization (camelCase & snake_case)', () {
      final now = DateTime(2026, 9, 13, 12, 0);
      final customer = Customer(
        id: 'cust-101',
        name: 'Tariq Al-Fahad',
        phone: '+968 9123 4567',
        vehicleModel: 'Toyota Land Cruiser',
        plateNumber: '9988 AA',
        totalDue: 250.0,
        totalBilled: 1000.0,
        totalPaid: 750.0,
        createdAt: now,
        updatedAt: now,
        isSynced: false,
      );

      // toMap
      final localMap = customer.toMap();
      expect(localMap['id'], 'cust-101');
      expect(localMap['vehicleModel'], 'Toyota Land Cruiser');
      expect(localMap['plateNumber'], '9988 AA');
      expect(localMap['isSynced'], false);

      // toSupabaseMap
      final remoteMap = customer.toSupabaseMap('user-uuid-999');
      expect(remoteMap['id'], 'cust-101');
      expect(remoteMap['plate_number'], '9988 AA');
      expect(remoteMap['total_due'], 250.0);
      expect(remoteMap['user_id'], 'user-uuid-999');

      // fromMap (snake_case from Supabase)
      final restoredFromRemote = Customer.fromMap({
        'id': 'cust-101',
        'name': 'Tariq Al-Fahad',
        'phone': '+968 9123 4567',
        'plate_number': '9988 AA',
        'vehicle_model': 'Toyota Land Cruiser',
        'total_due': 250.0,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'user_id': 'user-uuid-999',
      });
      expect(restoredFromRemote.id, 'cust-101');
      expect(restoredFromRemote.plateNumber, '9988 AA');
      expect(restoredFromRemote.vehicleModel, 'Toyota Land Cruiser');
      expect(restoredFromRemote.totalDue, 250.0);
    });

    test('BayJob model serialization and deserialization', () {
      final now = DateTime(2026, 9, 13, 12, 0);
      final job = BayJob(
        id: 'job-501',
        bayNumber: 'Bay 2',
        customerName: 'Rashid Khan',
        vehicleModel: 'Nissan Patrol',
        plateNumber: '5566 DX',
        taskDescription: 'Full Service',
        estimatedCost: 120.0,
        status: 'ready_for_pickup',
        settledAmount: 120.0,
        paidAmount: 100.0,
        dueAmount: 20.0,
        paymentMethod: 'cash',
        date: now,
        createdAt: now,
        updatedAt: now,
        isSynced: false,
      );

      final supabaseMap = job.toSupabaseMap('user-uuid-999');
      expect(supabaseMap['id'], 'job-501');
      expect(supabaseMap['customer_name'], 'Rashid Khan');
      expect(supabaseMap['vehicle_model'], 'Nissan Patrol');
      expect(supabaseMap['plate_number'], '5566 DX');
      expect(supabaseMap['status'], 'ready_for_pickup');
      expect(supabaseMap['settled_amount'], 120.0);
      expect(supabaseMap['user_id'], 'user-uuid-999');

      final fromRemote = BayJob.fromMap(supabaseMap);
      expect(fromRemote.id, 'job-501');
      expect(fromRemote.customerName, 'Rashid Khan');
      expect(fromRemote.vehicleModel, 'Nissan Patrol');
      expect(fromRemote.settledAmount, 120.0);
    });

    test('TransactionRecord model serialization and deserialization', () {
      final now = DateTime(2026, 9, 13, 12, 0);
      final tx = TransactionRecord(
        id: 'tx-801',
        customerName: 'Rashid Khan',
        type: 'payment',
        amount: 100.0,
        runningBalance: 20.0,
        description: 'Brake overhaul partial payment',
        paymentMethod: 'cash',
        date: now,
        createdAt: now,
        updatedAt: now,
        isSynced: false,
      );

      final supabaseMap = tx.toSupabaseMap('user-uuid-999');
      expect(supabaseMap['id'], 'tx-801');
      expect(supabaseMap['type'], 'payment');
      expect(supabaseMap['amount'], 100.0);
      expect(supabaseMap['user_id'], 'user-uuid-999');

      final fromRemote = TransactionRecord.fromMap(supabaseMap);
      expect(fromRemote.id, 'tx-801');
      expect(fromRemote.amount, 100.0);
      expect(fromRemote.type, 'payment');
    });
  });

  group('3. SyncService State & Integrity Tests', () {
    test('SyncService singleton returns consistent instance', () {
      final s1 = SyncService();
      final s2 = SyncService();
      expect(identical(s1, s2), isTrue);
      expect(s1.isSyncing, isFalse);
    });

    test('SyncService handles unauthenticated state gracefully without crashing', () async {
      final sync = SyncService();
      expect(sync.isCloudAuthenticated, isFalse);
      expect(sync.currentCloudUser, isNull);

      // pushUnsynced and pullRemoteData should exit safely without error when unauthenticated
      await sync.pushUnsynced();
      await sync.pullRemoteData();
      await sync.syncAll();
      expect(sync.isSyncing, isFalse);
    });
  });

  group('4. Cloud Account UI & Modal Widget Tests', () {
    Widget buildTestApp({required Widget child}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => GarageRepository()),
          ChangeNotifierProvider(create: (_) => CurrencyManager()),
          ChangeNotifierProvider(create: (_) => AppLocaleManager()),
          ChangeNotifierProvider.value(value: SyncService()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          home: child,
        ),
      );
    }

    testWidgets('CloudAccountModal renders unauthenticated login and signup form', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => CloudAccountModal.show(ctx),
                child: const Text('Open Cloud Modal'),
              ),
            ),
          ),
        ),
      );

      // Open Modal
      await tester.tap(find.text('Open Cloud Modal'));
      await tester.pumpAndSettle();

      // Header & Title
      expect(find.text('Cloud Account & Multi-Device Sync'), findsOneWidget);
      expect(find.text('Supabase Cloud • Real-Time Offline Sync'), findsOneWidget);

      // Form controls
      expect(find.text('Log In'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password (min 6 characters)'), findsOneWidget);
      expect(find.text('Log In & Sync Device'), findsOneWidget);

      // Switch to Create Account
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      // Confirm password field appears
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Sign Up for Cloud'), findsOneWidget);
    });

    testWidgets('SettingsScreen contains Cloud Account & Multi-Device Sync tile and opens modal', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tile exists
      final tileFinder = find.text('Cloud Account & Multi-Device Sync');
      expect(tileFinder, findsOneWidget);

      // Existing Cloud Backup tile is still preserved
      expect(find.text('Cloud Backup (Google Drive)'), findsOneWidget);

      // Scroll to & Tap Cloud Account tile
      await tester.ensureVisible(tileFinder);
      await tester.pumpAndSettle();
      await tester.tap(tileFinder);
      await tester.pumpAndSettle();

      // Modal is displayed
      expect(find.text('Supabase Cloud • Real-Time Offline Sync'), findsOneWidget);
    });
  });
}
