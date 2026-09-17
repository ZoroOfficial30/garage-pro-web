import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:garage_accounting_pro/core/theme/app_theme.dart';
import 'package:garage_accounting_pro/core/currency/currency_manager.dart';
import 'package:garage_accounting_pro/core/localization/app_locale.dart';
import 'package:garage_accounting_pro/data/repositories/garage_repository.dart';
import 'package:garage_accounting_pro/features/home/screens/home_screen.dart';
import 'package:garage_accounting_pro/features/home/services/voice_service.dart';

void main() {
  group('1. VoiceService Unit Tests', () {
    test('VoiceService singleton instance integrity', () {
      final v1 = VoiceService();
      final v2 = VoiceService();
      expect(identical(v1, v2), isTrue);
    });

    test('VoiceService maps languages to correct speech recognition locales', () {
      final service = VoiceService();
      expect(service.getLocaleForLanguage(AppLanguage.en), 'en_US');
      expect(service.getLocaleForLanguage(AppLanguage.bn), 'bn_BD');
      expect(service.getLocaleForLanguage(AppLanguage.ar), 'ar_SA');
      expect(service.getLocaleForLanguage(AppLanguage.hi), 'hi_IN');
      expect(service.getLocaleForLanguage(AppLanguage.ur), 'ur_PK');
    });

    test('VoiceService handles initialization in test environment gracefully', () async {
      final service = VoiceService();
      final result = await service.initialize();
      expect(service.isInitialized, isTrue);
      expect(result, isFalse);
    });

    test('VoiceService.normalizeVoiceInput strips trailing punctuation and normalizes spoken numbers', () {
      // 1. Punctuation stripping
      expect(VoiceService.normalizeVoiceInput('ad Karim 50.'), 'ad Karim 50');
      expect(VoiceService.normalizeVoiceInput('sp David 30,'), 'sp David 30');
      expect(VoiceService.normalizeVoiceInput('+due Rahim 100?'), '+due Rahim 100');
      expect(VoiceService.normalizeVoiceInput('ad করিম ৫০।'), 'ad করিম ৫০');

      // 2. English spoken number words
      expect(VoiceService.normalizeVoiceInput('ad Karim fifty.'), 'ad Karim 50');
      expect(VoiceService.normalizeVoiceInput('sp David thirty'), 'sp David 30');
      expect(VoiceService.normalizeVoiceInput('sp David twenty five'), 'sp David 25');
      expect(VoiceService.normalizeVoiceInput('+due Jamal one hundred'), '+due Jamal 100');

      // 3. Bengali spoken number words
      expect(VoiceService.normalizeVoiceInput('ad করিম পঞ্চাশ।'), 'ad করিম 50');
      expect(VoiceService.normalizeVoiceInput('sp ডেভিড তিরিশ'), 'sp ডেভিড 30');
      expect(VoiceService.normalizeVoiceInput('ad জামাল একশো'), 'ad জামাল 100');

      // 4. Command synonyms
      expect(VoiceService.normalizeVoiceInput('add due Karim 50'), 'ad Karim 50');
      expect(VoiceService.normalizeVoiceInput('settle payment David 30'), 'sp David 30');
      expect(VoiceService.normalizeVoiceInput('বাকি রহিম ৫০'), 'ad রহিম ৫০');
      expect(VoiceService.normalizeVoiceInput('জমা ডেভিড ৩০'), 'sp ডেভিড ৩০');

      // 5. Edge cases
      expect(VoiceService.normalizeVoiceInput(''), '');
      expect(VoiceService.normalizeVoiceInput('   '), '');
    });
  });

  group('2. Home Screen Voice Input Widget Tests', () {
    Widget createHomeScreen() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => GarageRepository()),
          ChangeNotifierProvider(create: (_) => CurrencyManager()),
          ChangeNotifierProvider(create: (_) => AppLocaleManager()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          home: const HomeScreen(),
        ),
      );
    }

    testWidgets('HomeScreen renders inline microphone button and voice status', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Online Sync Active'), findsOneWidget);
    });

    testWidgets('Tapping mic button triggers voice fallback sheet in headless environment', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pump(const Duration(milliseconds: 100));

      final micFinder = find.byIcon(Icons.mic_rounded);
      await tester.tap(micFinder);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Microphone Permission Needed'), findsOneWidget);
      expect(find.text('ad Karim 50'), findsOneWidget);
      expect(find.text('sp David 30'), findsOneWidget);
      expect(find.text('ad করিম ৫০'), findsOneWidget);
      expect(find.text('sp ডেভিড ৩০'), findsOneWidget);
    });

    testWidgets('Tapping voice preset chip populates command field and triggers suggestions', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pump(const Duration(milliseconds: 100));

      final micFinder = find.byIcon(Icons.mic_rounded);
      await tester.tap(micFinder);
      await tester.pump(const Duration(milliseconds: 400));

      final chipFinder = find.text('ad Karim 50');
      expect(chipFinder, findsOneWidget);
      await tester.ensureVisible(chipFinder);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(chipFinder);
      // Wait for bottom sheet close transition to complete
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 200));

      // Command text should be filled in TextField
      expect(find.widgetWithText(TextField, 'ad Karim 50'), findsOneWidget);
      // Customer command suggestions overlay should be triggered
      expect(find.text('Add Due (+due / ad)'), findsOneWidget);
      expect(find.text('+ Create New Customer: "Karim"'), findsOneWidget);
      // Send button should be visible when text is present
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('Language toggle changes locale and speech presets correctly', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pump(const Duration(milliseconds: 100));

      final langFinder = find.text('EN 🇺🇸');
      expect(langFinder, findsOneWidget);
      await tester.tap(langFinder);
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('অনলাইন সিঙ্ক সক্রিয়'), findsOneWidget);
      expect(find.text('বাংলা 🇧🇩'), findsOneWidget);

      final micFinder = find.byIcon(Icons.mic_rounded);
      await tester.tap(micFinder);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('মাইক্রোফোন পারমিশন প্রয়োজন'), findsOneWidget);
      expect(find.text('দ্রুত ভয়েস কমান্ড বেছে নিন:'), findsOneWidget);
    });

    testWidgets('HomeScreen command bar has stable layout with inline mic suffix and send button', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pump(const Duration(milliseconds: 100));

      // Verify AnimatedCrossFade is present for smooth voice banner transitions
      expect(find.byType(AnimatedCrossFade), findsOneWidget);

      // Verify TextField exists with 52px height container
      expect(find.byType(TextField), findsOneWidget);

      // Verify the 20px inline microphone icon inside the 40px tap target
      final micIcon = tester.widget<Icon>(find.byIcon(Icons.mic_rounded));
      expect(micIcon.size, 20.0);

      // Verify Send button is hidden when TextField is empty
      expect(find.byIcon(Icons.send_rounded), findsNothing);

      // Enter text into TextField
      await tester.enterText(find.byType(TextField), 'ad Rahim 250');
      await tester.pump();

      // Verify Send button is now visible
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);

      // Verify command bar renders without overflow
      expect(tester.takeException(), isNull);
    });
  });
}
