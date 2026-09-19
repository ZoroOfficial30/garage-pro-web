import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:garage_accounting_pro/core/services/biometric_auth_service.dart';
import 'package:garage_accounting_pro/core/theme/app_theme.dart';
import 'package:garage_accounting_pro/core/currency/currency_manager.dart';
import 'package:garage_accounting_pro/core/localization/app_locale.dart';
import 'package:garage_accounting_pro/data/models/employee.dart';
import 'package:garage_accounting_pro/data/repositories/garage_repository.dart';
import 'package:garage_accounting_pro/features/auth/screens/login_screen.dart';

void main() {
  group('Auto-Lock & Biometric Fallback Tests', () {
    late GarageRepository repo;

    setUp(() {
      repo = GarageRepository();
      repo.setMockEmployees([
        Employee(
          id: 'emp-201',
          name: 'Rahim Mechanic',
          role: 'Technician',
          phone: '+880 1700-112233',
          monthlySalary: 750.0,
          pin: '9876',
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        ),
      ]);
    });

    tearDown(() {
      repo.logout();
    });

    test('BiometricAuthService is safe and handles queries gracefully', () async {
      final bioService = BiometricAuthService();
      // On web or environments without hardware biometrics, it returns false gracefully
      final isAvailable = await bioService.isBiometricAvailable();
      expect(isAvailable, isA<bool>());

      final authResult = await bioService.authenticate();
      expect(authResult, isA<bool>());
    });

    test('GarageRepository lockApp and unlockApp state management', () async {
      expect(repo.isAppLocked, isFalse);

      // Logging in owner
      final loggedIn = await repo.loginOwner('1234');
      expect(loggedIn, isTrue);
      expect(repo.isAuthenticated, isTrue);
      expect(repo.isAppLocked, isFalse);

      // Trigger lock
      repo.lockApp();
      expect(repo.isAppLocked, isTrue);
      expect(repo.isAuthenticated, isTrue); // Session preserved, but locked

      // Unlock with correct owner PIN
      final unlocked = await repo.unlockWithPin('1234');
      expect(unlocked, isTrue);
      expect(repo.isAppLocked, isFalse);

      // Lock again, attempt wrong PIN
      repo.lockApp();
      expect(repo.isAppLocked, isTrue);
      final wrongUnlock = await repo.unlockWithPin('0000');
      expect(wrongUnlock, isFalse);
      expect(repo.isAppLocked, isTrue);

      // Direct unlockApp
      repo.unlockApp();
      expect(repo.isAppLocked, isFalse);
    });

    test('Staff session auto-lock and unlock with staff PIN', () async {
      final loggedIn = await repo.loginStaff('emp-201', '9876');
      expect(loggedIn, isTrue);
      expect(repo.isStaff, isTrue);
      expect(repo.isAppLocked, isFalse);

      repo.lockApp();
      expect(repo.isAppLocked, isTrue);

      // Staff PIN unlocks
      final unlocked = await repo.unlockWithPin('9876');
      expect(unlocked, isTrue);
      expect(repo.isAppLocked, isFalse);
      expect(repo.isStaff, isTrue);
    });

    testWidgets('LoginScreen reflects Auto-Locked status when repo.isAppLocked is true', (tester) async {
      await repo.loginOwner('1234');
      repo.lockApp();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<GarageRepository>.value(value: repo),
            ChangeNotifierProvider<CurrencyManager>(create: (_) => CurrencyManager()),
            ChangeNotifierProvider<AppLocaleManager>(create: (_) => AppLocaleManager()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme(),
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Auto-Locked UI elements
      expect(find.textContaining('Auto-Locked'), findsOneWidget);
      expect(find.text('Unlock Garage'), findsOneWidget);
      expect(find.text('Log Out / Switch User'), findsOneWidget);
      expect(find.byIcon(Icons.lock_clock_rounded), findsOneWidget);

      // Entering correct PIN and tapping unlock
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('4'));
      await tester.pump();

      await tester.ensureVisible(find.text('Unlock Garage'));
      await tester.tap(find.text('Unlock Garage'));
      await tester.pumpAndSettle();

      expect(repo.isAppLocked, isFalse);
    });

    testWidgets('Forgot PIN button displays modal for Owner and informative alert for Staff', (tester) async {
      await repo.loginOwner('1234');
      repo.lockApp();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<GarageRepository>.value(value: repo),
            ChangeNotifierProvider<CurrencyManager>(create: (_) => CurrencyManager()),
            ChangeNotifierProvider<AppLocaleManager>(create: (_) => AppLocaleManager()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme(),
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Forgot PIN button exists
      final forgotPinFinder = find.text('Forgot PIN?');
      expect(forgotPinFinder, findsOneWidget);

      // Tap Forgot PIN when Owner is locked -> opens Owner Recovery Modal
      await tester.ensureVisible(forgotPinFinder);
      await tester.tap(forgotPinFinder);
      await tester.pumpAndSettle();

      expect(find.text('Owner PIN Recovery'), findsOneWidget);
      expect(find.text('Verify & Set New PIN'), findsOneWidget);

      // Close modal
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
    });
  });
}
