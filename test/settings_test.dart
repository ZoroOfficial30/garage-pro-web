import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:garage_accounting_pro/core/theme/app_theme.dart';
import 'package:garage_accounting_pro/core/currency/currency_manager.dart';
import 'package:garage_accounting_pro/core/localization/app_locale.dart';
import 'package:garage_accounting_pro/data/repositories/garage_repository.dart';
import 'package:garage_accounting_pro/features/settings/screens/settings_screen.dart';
import 'package:garage_accounting_pro/features/home/screens/home_screen.dart';
import 'package:garage_accounting_pro/features/dashboard/screens/daily_summary_screen.dart';

void main() {
  Widget createTestWidget(Widget child, {
    GarageRepository? repo,
    CurrencyManager? currency,
    AppLocaleManager? locale,
  }) {
    final garageRepo = repo ?? GarageRepository();
    final curMgr = currency ?? CurrencyManager();
    final locMgr = locale ?? AppLocaleManager();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: garageRepo),
        ChangeNotifierProvider.value(value: curMgr),
        ChangeNotifierProvider.value(value: locMgr),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme(),
        home: child,
      ),
    );
  }

  group('CurrencyManager Tests', () {
    test('Switches between all 7 supported currencies properly', () {
      final currency = CurrencyManager();

      // Default: OMR (3 decimal places)
      expect(currency.currentCurrency, CurrencyCode.omr);
      expect(currency.format(150.5), 'OMR 150.500');

      // Switch to USD
      currency.setCurrency(CurrencyCode.usd);
      expect(currency.currentCurrency, CurrencyCode.usd);
      expect(currency.format(150.5), r'$150.50');

      // Switch to BDT
      currency.setCurrency(CurrencyCode.bdt);
      expect(currency.currentCurrency, CurrencyCode.bdt);
      expect(currency.format(150.5), '৳150.50');

      // Switch to INR
      currency.setCurrency(CurrencyCode.inr);
      expect(currency.currentCurrency, CurrencyCode.inr);
      expect(currency.format(150.5), '₹150.50');

      // Switch to AED
      currency.setCurrency(CurrencyCode.aed);
      expect(currency.currentCurrency, CurrencyCode.aed);
      expect(currency.format(150.5), 'AED 150.50');

      // Switch to EUR
      currency.setCurrency(CurrencyCode.eur);
      expect(currency.currentCurrency, CurrencyCode.eur);
      expect(currency.format(150.5), '€150.50');

      // Switch to GBP
      currency.setCurrency(CurrencyCode.gbp);
      expect(currency.currentCurrency, CurrencyCode.gbp);
      expect(currency.format(150.5), '£150.50');
    });
  });

  group('AppLocaleManager Tests', () {
    test('Translates keys across English, Bengali, Arabic, and Hindi', () {
      final locale = AppLocaleManager();

      // English
      expect(locale.translate('executive_dashboard'), 'Executive Dashboard');
      expect(locale.translate('workshop_settings'), 'Workshop Settings');

      // Bengali
      locale.setLanguage(AppLanguage.bn);
      expect(locale.translate('executive_dashboard'), 'এক্সিকিউটিভ ড্যাশবোর্ড');
      expect(locale.translate('workshop_settings'), 'ওয়ার্কশপ সেটিংস');

      // Arabic
      locale.setLanguage(AppLanguage.ar);
      expect(locale.translate('executive_dashboard'), 'لوحة القيادة التنفيذية');
      expect(locale.translate('workshop_settings'), 'إعدادات الورشة');

      // Hindi
      locale.setLanguage(AppLanguage.hi);
      expect(locale.translate('executive_dashboard'), 'एग्जीक्यूटिव डैशबोर्ड');
      expect(locale.translate('workshop_settings'), 'वर्कशॉप सेटिंग्स');
    });
  });

  group('SettingsScreen Widget Tests', () {
    testWidgets('Renders all settings sections and options', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const SettingsScreen(),
        ),
      );

      // Section titles & content
      expect(find.text('Workshop Settings'), findsOneWidget);
      expect(find.text('Apex Auto Workshop'), findsOneWidget);
      expect(find.text('Primary Currency'), findsOneWidget);
      expect(find.text('Voice Assistant Language'), findsOneWidget);
      expect(find.text('Display & Ergonomics'), findsOneWidget);
      expect(find.text('Security & Access'), findsOneWidget);
      expect(find.text('Data Management'), findsOneWidget);

      // Currency chips exist
      expect(find.text('OMR (Omani Rial)'), findsOneWidget);
      expect(find.text('USD (US Dollar)'), findsOneWidget);

      // Language chips exist
      expect(find.text('English'), findsOneWidget);
      expect(find.text('বাংলা'), findsOneWidget);
      expect(find.text('हिन्दी'), findsOneWidget);
      expect(find.text('العربية'), findsOneWidget);

      // Toggles
      expect(find.text('Sunlight High-Contrast Mode'), findsOneWidget);
      expect(find.text('Extra-Large Text & Keypad'), findsOneWidget);
      expect(find.text('Voice Audio Feedback'), findsOneWidget);
      expect(find.text('Quick 4-Digit PIN Lock'), findsOneWidget);
      expect(find.text('Biometric Fingerprint Lock'), findsOneWidget);

      // Data management options
      expect(find.text('Export Ledger to Excel / CSV'), findsOneWidget);
      expect(find.text('Cloud Backup (Google Drive)'), findsOneWidget);
      expect(find.text('Print Monthly Statement (PDF)'), findsOneWidget);
      expect(find.text('Reset / Reload Demo Data'), findsOneWidget);
    });
  });

  group('Workshop Profile & Logo Repository Tests', () {
    const sampleLogoBase64 =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

    test('Initial profile has default values and empty logo', () {
      final repo = GarageRepository();
      final profile = repo.workshopProfile;

      expect(profile['name'], 'Apex Auto Workshop');
      expect(profile['phone'], '+880 1711-234567');
      expect(profile['taxId'], 'VAT-89210-AUTO');
      expect(profile['logoBase64'], isEmpty);
      expect(repo.workshopLogoBase64, isNull);
    });

    test('updateWorkshopLogo stores and retrieves logo accurately', () async {
      final repo = GarageRepository();

      await repo.updateWorkshopLogo(sampleLogoBase64);
      expect(repo.workshopProfile['logoBase64'], sampleLogoBase64);
      expect(repo.workshopLogoBase64, sampleLogoBase64);

      // Remove logo
      await repo.updateWorkshopLogo('');
      expect(repo.workshopProfile['logoBase64'], isEmpty);
      expect(repo.workshopLogoBase64, isNull);
    });

    test('updateWorkshopProfile updates all fields including logoBase64', () async {
      final repo = GarageRepository();

      await repo.updateWorkshopProfile(
        name: 'Speedy Garage & Diagnostics',
        phone: '+880 1999-888777',
        taxId: 'VAT-999-SPEEDY',
        address: 'Plot 12, Sector 3',
        logoBase64: sampleLogoBase64,
      );

      final profile = repo.workshopProfile;
      expect(profile['name'], 'Speedy Garage & Diagnostics');
      expect(profile['phone'], '+880 1999-888777');
      expect(profile['taxId'], 'VAT-999-SPEEDY');
      expect(profile['address'], 'Plot 12, Sector 3');
      expect(profile['logoBase64'], sampleLogoBase64);
      expect(repo.workshopLogoBase64, sampleLogoBase64);
    });
  });

  group('Workshop Logo UI & Screen Integration Widget Tests', () {
    const sampleLogoBase64 =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

    testWidgets('SettingsScreen displays workshop logo avatar with camera badge and opens EditProfileModal', (tester) async {
      final repo = GarageRepository();
      await repo.updateWorkshopProfile(
        name: 'Apex Super Garage',
        phone: '+880 1711-234567',
        taxId: 'VAT-89210-AUTO',
        logoBase64: sampleLogoBase64,
      );

      await tester.pumpWidget(createTestWidget(const SettingsScreen(), repo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Apex Super Garage'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_rounded), findsWidgets);

      // Open Edit Profile Modal
      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Workshop Profile'), findsOneWidget);
      expect(find.text('Change Workshop Logo'), findsOneWidget);
      expect(find.text('Save Profile'), findsOneWidget);
    });

    testWidgets('HomeScreen renders custom workshop name and logo in top branding bar', (tester) async {
      final repo = GarageRepository();
      await repo.updateWorkshopProfile(
        name: 'Speedy Workshop Pro',
        phone: '+880 1711-234567',
        taxId: 'VAT-89210-AUTO',
        logoBase64: sampleLogoBase64,
      );

      await tester.pumpWidget(createTestWidget(const HomeScreen(), repo: repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Speedy Workshop Pro'), findsOneWidget);
    });

    testWidgets('DailySummaryScreen renders Workshop Report Header with logo and name', (tester) async {
      final repo = GarageRepository();
      await repo.updateWorkshopProfile(
        name: 'Turbo Auto Garage',
        phone: '+880 1711-234567',
        taxId: 'VAT-89210-AUTO',
        address: 'Bay 5 Auto Hub',
        logoBase64: sampleLogoBase64,
      );

      await tester.pumpWidget(createTestWidget(const DailySummaryScreen(), repo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Turbo Auto Garage'), findsOneWidget);
      expect(find.text('DAILY REPORT'), findsOneWidget);
    });
  });
}
