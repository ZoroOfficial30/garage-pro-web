import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:garage_accounting_pro/core/localization/app_locale.dart';
import 'package:garage_accounting_pro/core/currency/currency_manager.dart';
import 'package:garage_accounting_pro/data/repositories/garage_repository.dart';
import 'package:garage_accounting_pro/data/models/customer.dart';
import 'package:garage_accounting_pro/shared/utils/communication_helper.dart';
import 'package:garage_accounting_pro/features/settings/screens/settings_screen.dart';
import 'package:garage_accounting_pro/features/customers/widgets/customer_card.dart';
import 'package:garage_accounting_pro/features/customers/screens/customer_detail_screen.dart';

void main() {
  group('1. Multi-Language & RTL Unit Tests', () {
    test('AppLocaleManager supports 5 languages correctly', () {
      final localeMgr = AppLocaleManager();

      // 1. English (Default)
      localeMgr.setLanguage(AppLanguage.en);
      expect(localeMgr.currentLanguage, AppLanguage.en);
      expect(localeMgr.isEnglish, isTrue);
      expect(localeMgr.isRTL, isFalse);
      expect(localeMgr.textDirection, TextDirection.ltr);
      expect(localeMgr.locale.languageCode, 'en');
      expect(localeMgr.translate('due_reminder_title'), 'WhatsApp Due Reminder Message');

      // 2. Bengali
      localeMgr.setLanguage(AppLanguage.bn);
      expect(localeMgr.currentLanguage, AppLanguage.bn);
      expect(localeMgr.isBangla, isTrue);
      expect(localeMgr.isRTL, isFalse);
      expect(localeMgr.textDirection, TextDirection.ltr);
      expect(localeMgr.locale.languageCode, 'bn');
      expect(localeMgr.translate('due_reminder_title'), 'হোয়াটসঅ্যাপ বাকি রিমাইন্ডার বার্তা');

      // 3. Hindi
      localeMgr.setLanguage(AppLanguage.hi);
      expect(localeMgr.currentLanguage, AppLanguage.hi);
      expect(localeMgr.isHindi, isTrue);
      expect(localeMgr.isRTL, isFalse);
      expect(localeMgr.textDirection, TextDirection.ltr);
      expect(localeMgr.locale.languageCode, 'hi');
      expect(localeMgr.translate('due_reminder_title'), 'व्हाट्सएप बकाया रिमाइंडर संदेश');

      // 4. Arabic (RTL)
      localeMgr.setLanguage(AppLanguage.ar);
      expect(localeMgr.currentLanguage, AppLanguage.ar);
      expect(localeMgr.isArabic, isTrue);
      expect(localeMgr.isRTL, isTrue);
      expect(localeMgr.textDirection, TextDirection.rtl);
      expect(localeMgr.locale.languageCode, 'ar');
      expect(localeMgr.translate('due_reminder_title'), 'رسالة تذكير الديون عبر واتساب');

      // 5. Urdu (RTL)
      localeMgr.setLanguage(AppLanguage.ur);
      expect(localeMgr.currentLanguage, AppLanguage.ur);
      expect(localeMgr.isUrdu, isTrue);
      expect(localeMgr.isRTL, isTrue);
      expect(localeMgr.textDirection, TextDirection.rtl);
      expect(localeMgr.locale.languageCode, 'ur');
      expect(localeMgr.translate('due_reminder_title'), 'واٹس ایپ واجبات یاد دہانی پیغام');
      expect(localeMgr.translate('send_whatsapp'), 'واٹس ایپ بھیجیں');
      expect(localeMgr.translate('call_customer'), 'کال کریں');
      expect(localeMgr.translate('collect_pay'), 'رقم وصول کریں');
      expect(localeMgr.translate('new_job_bill'), 'نیا کام / بل');
    });
  });

  group('2. WhatsApp Due Reminder Template Unit Tests', () {
    test('GarageRepository template getters, setters, and formatting', () async {
      final repo = GarageRepository();

      // Default template check
      expect(repo.whatsappDueTemplate, contains('{amount}'));
      expect(repo.whatsappDueTemplate, contains('{workshopName}'));

      // Format with default template
      final msg = repo.formatWhatsAppDueMessage(
        amount: 350.0,
        formattedAmount: '৳350',
      );
      expect(msg, contains('৳350'));
      expect(msg, contains('Apex Auto Workshop'));

      // Set custom template
      const customTpl = 'Dear Sir, your outstanding bill is {amount}. Thanks - {workshopName}';
      await repo.setWhatsAppDueTemplate(customTpl);
      expect(repo.whatsappDueTemplate, customTpl);

      final customMsg = repo.formatWhatsAppDueMessage(
        amount: 1200.0,
        formattedAmount: '৳1,200',
      );
      expect(customMsg, 'Dear Sir, your outstanding bill is ৳1,200. Thanks - Apex Auto Workshop');

      // Reset template
      await repo.resetWhatsAppDueTemplate();
      expect(repo.whatsappDueTemplate, GarageRepository.defaultWhatsAppTemplate);
    });

    test('CommunicationHelper cleans phone numbers properly', () {
      expect(CommunicationHelper.cleanPhoneNumber('01711234567'), '8801711234567');
      expect(CommunicationHelper.cleanPhoneNumber('+880 1812-345678'), '8801812345678');
      expect(CommunicationHelper.cleanPhoneNumber('968 9123 4567'), '96891234567');
    });
  });

  group('3. Settings Screen Widget Tests (5 Languages & Template Editor)', () {
    testWidgets('Renders all 5 language chips and WhatsAppReminderSection', (tester) async {
      final repo = GarageRepository();
      final currency = CurrencyManager();
      final locale = AppLocaleManager();

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<GarageRepository>.value(value: repo),
            ChangeNotifierProvider<CurrencyManager>.value(value: currency),
            ChangeNotifierProvider<AppLocaleManager>.value(value: locale),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check language chips exist
      expect(find.text('English'), findsWidgets);
      expect(find.text('বাংলা'), findsWidgets);
      expect(find.text('हिन्दी'), findsWidgets);
      expect(find.text('العربية'), findsWidgets);
      expect(find.text('اردو'), findsWidgets);

      // Scroll to Urdu chip if needed and tap
      await tester.ensureVisible(find.text('اردو'));
      await tester.tap(find.text('اردو'));
      await tester.pumpAndSettle();
      expect(locale.currentLanguage, AppLanguage.ur);
      expect(locale.isRTL, isTrue);

      // Check WhatsApp Due Reminder Section
      expect(find.byType(WhatsAppReminderSection), findsOneWidget);
      await tester.ensureVisible(find.text('{amount}'));
      expect(find.text('{amount}'), findsOneWidget);
      expect(find.text('{workshopName}'), findsOneWidget);

      // Check Save and Reset buttons exist
      expect(find.text(locale.translate('save_message')), findsOneWidget);
      expect(find.text(locale.translate('reset_to_default')), findsOneWidget);

      // Restore to English
      locale.setLanguage(AppLanguage.en);
      await tester.pumpAndSettle();
    });
  });

  group('4. CustomerCard & CustomerDetailScreen WhatsApp & Call Tests', () {
    final testCustomer = Customer(
      id: 'cust-test-1',
      name: 'Rahim Chowdhury',
      phone: '01712345678',
      vehicleModel: 'Toyota Premio',
      plateNumber: 'DHK-7721',
      totalDue: 450.0,
      totalPaid: 1500.0,
      totalBilled: 1950.0,
      isVip: true,
      notes: 'Test customer',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    testWidgets('CustomerCard renders WhatsApp button and triggers callback', (tester) async {
      final repo = GarageRepository();
      final currency = CurrencyManager();
      final locale = AppLocaleManager();

      bool callTapped = false;
      bool whatsappTapped = false;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<GarageRepository>.value(value: repo),
            ChangeNotifierProvider<CurrencyManager>.value(value: currency),
            ChangeNotifierProvider<AppLocaleManager>.value(value: locale),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CustomerCard(
                customer: testCustomer,
                onTap: () {},
                onCollectPay: () {},
                onCall: () => callTapped = true,
                onWhatsApp: () => whatsappTapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify name, phone, due badge
      expect(find.text('Rahim Chowdhury'), findsOneWidget);
      expect(find.text('01712345678'), findsOneWidget);
      expect(find.byIcon(Icons.call_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chat_rounded), findsOneWidget);

      // Tap Call button
      await tester.tap(find.byIcon(Icons.call_rounded));
      await tester.pump();
      expect(callTapped, isTrue);

      // Tap WhatsApp button
      await tester.tap(find.byIcon(Icons.chat_rounded));
      await tester.pump();
      expect(whatsappTapped, isTrue);
    });

    testWidgets('CustomerDetailScreen renders Call, WhatsApp header and full-width reminder button', (tester) async {
      final repo = GarageRepository();
      repo.setMockCustomers([testCustomer]);

      final currency = CurrencyManager();
      final locale = AppLocaleManager();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<GarageRepository>.value(value: repo),
            ChangeNotifierProvider<CurrencyManager>.value(value: currency),
            ChangeNotifierProvider<AppLocaleManager>.value(value: locale),
          ],
          child: MaterialApp(
            home: CustomerDetailScreen(customerId: testCustomer.id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top card call & whatsapp buttons
      expect(find.byIcon(Icons.call_rounded), findsWidgets);
      expect(find.byIcon(Icons.chat_rounded), findsWidgets);

      // Since testCustomer has due (450.0 > 0), the full-width WhatsApp button should be visible
      expect(find.text(locale.translate('send_whatsapp')), findsOneWidget);
    });
  });
}
