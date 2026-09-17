import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:garage_accounting_pro/core/theme/app_theme.dart';
import 'package:garage_accounting_pro/core/currency/currency_manager.dart';
import 'package:garage_accounting_pro/core/localization/app_locale.dart';
import 'package:garage_accounting_pro/data/repositories/garage_repository.dart';
import 'package:garage_accounting_pro/features/navigation/main_scaffold.dart';

void main() {
  testWidgets('Renders MainScaffold and Home Screen with 5 Quick Action buttons', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => GarageRepository()),
          ChangeNotifierProvider(create: (_) => CurrencyManager()),
          ChangeNotifierProvider(create: (_) => AppLocaleManager()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          home: const MainScaffold(),
        ),
      ),
    );

    expect(find.text('Apex Auto Workshop'), findsOneWidget);
    expect(find.text('+ Due'), findsOneWidget);
    expect(find.text('– Pay'), findsOneWidget);
    expect(find.text('Stock Out'), findsOneWidget);
    expect(find.text('Expense'), findsOneWidget);
    expect(find.text('New Job'), findsOneWidget);
    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    expect(find.text('Jobs'), findsOneWidget);
  });
}
