import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:garage_accounting_pro/core/theme/app_theme.dart';
import 'package:garage_accounting_pro/core/currency/currency_manager.dart';
import 'package:garage_accounting_pro/core/localization/app_locale.dart';
import 'package:garage_accounting_pro/data/repositories/garage_repository.dart';
import 'package:garage_accounting_pro/data/services/backup_service.dart';
import 'package:garage_accounting_pro/features/settings/screens/settings_screen.dart';

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

  group('1. BackupService JSON Validation Tests', () {
    final service = BackupService();

    test('Valid backup payload passes validation', () {
      final validJson = jsonEncode({
        'app': 'Garage Accounting Pro',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'metadata': {
          'workshopName': 'Elite Precision Garage',
          'counts': {'customers': 2, 'stockItems': 4},
        },
        'data': {
          'customers': [
            {'id': 'c1', 'name': 'Karim Chowdhury', 'totalDue': 120.0},
            {'id': 'c2', 'name': 'David Miller', 'totalDue': 0.0},
          ],
          'stockItems': [
            {'id': 's1', 'name': 'Castrol 5W-30', 'quantity': 10},
          ],
          'transactions': [],
          'expenses': [],
          'employees': [],
          'attendance': [],
          'bayJobs': [],
          'supplierDues': [],
          'settings': {
            'profile_name': 'Elite Precision Garage',
            'profile_phone': '+880 1711-000000',
          },
        },
      });

      final result = service.validateBackup(validJson);
      expect(result.isValid, isTrue);
      expect(result.workshopName, 'Elite Precision Garage');
      expect(result.counts['customers'], 2);
      expect(result.counts['stockItems'], 1);
      expect(result.totalRecords, 3);
      expect(result.version, 1);
      expect(result.errorMessage, isNull);
    });

    test('Rejects empty or whitespace content', () {
      final result = service.validateBackup('   ');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('empty'));
    });

    test('Rejects invalid JSON syntax', () {
      final result = service.validateBackup('{ invalid json: true, ');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('JSON parse error'));
    });

    test('Rejects JSON that is a list instead of an object', () {
      final result = service.validateBackup('[1, 2, 3]');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Root JSON must be an object'));
    });

    test('Rejects JSON without "data" section', () {
      final result = service.validateBackup(jsonEncode({
        'app': 'Garage Accounting Pro',
        'version': 1,
      }));
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Missing "data" section'));
    });
  });

  group('2. GarageRepository Backup & Restore Methods Tests', () {
    test('exportBackupJson generates valid JSON structure', () async {
      final repo = GarageRepository();
      final jsonString = await repo.exportBackupJson(pretty: false);

      expect(jsonString.isNotEmpty, isTrue);
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      expect(decoded['app'], 'Garage Accounting Pro');
      expect(decoded['version'], 1);
      expect(decoded.containsKey('data'), isTrue);
      expect(decoded['data'], isA<Map>());
      expect(decoded.containsKey('metadata'), isTrue);
    });

    test('getDatabaseStatistics returns count breakdown', () {
      final repo = GarageRepository();
      final stats = repo.getDatabaseStatistics();

      expect(stats.containsKey('customers'), isTrue);
      expect(stats.containsKey('stockItems'), isTrue);
      expect(stats.containsKey('transactions'), isTrue);
      expect(stats.containsKey('expenses'), isTrue);
      expect(stats.containsKey('employees'), isTrue);
      expect(stats.containsKey('bayJobs'), isTrue);
      expect(stats.containsKey('supplierDues'), isTrue);
    });

    test('validateBackup via repo correctly validates JSON', () {
      final repo = GarageRepository();
      final invalid = repo.validateBackup('not json');
      expect(invalid.isValid, isFalse);

      final valid = repo.validateBackup(jsonEncode({
        'app': 'Garage Accounting Pro',
        'version': 1,
        'data': {
          'customers': [],
          'stockItems': [],
          'settings': {'profile_name': 'Test Workshop'},
        },
      }));
      expect(valid.isValid, isTrue);
      expect(valid.workshopName, 'Test Workshop');
    });

    test('restoreFromBackupJson rejects invalid backup safely', () async {
      final repo = GarageRepository();
      final result = await repo.restoreFromBackupJson('corrupted data');
      expect(result, isFalse);
    });
  });

  group('3. SettingsScreen UI Widget Tests for Backup & Restore', () {
    testWidgets('Renders Backup & Restore Card, Buttons, and Offline badge in Settings', (tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = GarageRepository();

      await tester.pumpWidget(
        createTestWidget(
          const SettingsScreen(),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      // Verify the section title and 100% OFFLINE badge are rendered
      expect(find.text('Backup & Restore'), findsOneWidget);
      expect(find.text('100% OFFLINE'), findsOneWidget);

      // Verify both action buttons are rendered
      expect(find.text('Backup Data'), findsOneWidget);
      expect(find.text('Restore Data'), findsOneWidget);

      // Verify download and upload icons
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
      expect(find.byIcon(Icons.upload_file_rounded), findsOneWidget);
    });

    testWidgets('Tapping Restore Data opens bottom sheet with JSON File and Paste options', (tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = GarageRepository();

      await tester.pumpWidget(
        createTestWidget(
          const SettingsScreen(),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Restore Data"
      await tester.tap(find.text('Restore Data'));
      await tester.pumpAndSettle();

      // Verify the restore options modal opens
      expect(find.text('Select .JSON Backup File'), findsOneWidget);
      expect(find.text('Paste Backup JSON Text'), findsOneWidget);

      // Tap "Paste Backup JSON Text"
      await tester.tap(find.text('Paste Backup JSON Text'));
      await tester.pumpAndSettle();

      // Verify Paste dialog opens with Verify & Restore button
      expect(find.text('Paste Backup JSON Text'), findsOneWidget);
      expect(find.text('Verify & Restore'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Cancel to dismiss cleanly
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });
  });
}
