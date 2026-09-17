import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:garage_accounting_pro/core/theme/app_theme.dart';
import 'package:garage_accounting_pro/core/currency/currency_manager.dart';
import 'package:garage_accounting_pro/core/localization/app_locale.dart';
import 'package:garage_accounting_pro/data/models/bay_job.dart';
import 'package:garage_accounting_pro/data/repositories/garage_repository.dart';
import 'package:garage_accounting_pro/features/dashboard/widgets/kpi_card.dart';
import 'package:garage_accounting_pro/features/dashboard/widgets/bay_job_card.dart';
import 'package:garage_accounting_pro/features/dashboard/widgets/weekly_cash_flow_chart.dart';
import 'package:garage_accounting_pro/features/dashboard/screens/dashboard_screen.dart';

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

  group('Dashboard Component Tests', () {
    testWidgets('KpiCard renders title, amount, subtitle, and badge', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        createTestWidget(
          Scaffold(
            body: KpiCard(
              title: "Today's Income",
              amount: 'OMR 1,450.000',
              subtitle: '+18% vs yesterday • 6 Settled',
              icon: Icons.payments_rounded,
              subtitleIcon: Icons.trending_up,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text("TODAY'S INCOME"), findsOneWidget);
      expect(find.text('OMR 1,450.000'), findsOneWidget);
      expect(find.text('+18% vs yesterday • 6 Settled'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);

      await tester.tap(find.byType(KpiCard));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('BayJobCard renders bay, customer, vehicle, and status pill', (tester) async {
      String? updatedStatus;

      final job = BayJob(
        id: 'bay-job-1',
        bayNumber: 'Bay 1',
        customerName: 'Karim Chowdhury',
        vehicleModel: 'Toyota Corolla 2019',
        taskDescription: 'Brake Overhaul & Rotor Turn',
        estimatedCost: 150.0,
        technicianName: 'Tech Sumon',
        status: 'ready_for_pickup',
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestWidget(
          Scaffold(
            body: BayJobCard(
              job: job,
              currency: CurrencyManager(),
              onStatusChange: (status) => updatedStatus = status,
            ),
          ),
        ),
      );

      expect(find.text('BAY 1 • TOYOTA COROLLA 2019 (KARIM CHOWDHURY)'), findsOneWidget);
      expect(find.text('Brake Overhaul & Rotor Turn'), findsOneWidget);
      expect(find.text('OMR 150.000'), findsOneWidget);
      expect(find.text('READY FOR PICKUP'), findsOneWidget);
      expect(find.text('Tech Sumon'), findsOneWidget);

      // Tap card to open change status modal
      await tester.tap(find.byType(BayJobCard));
      await tester.pumpAndSettle();

      expect(find.text('Update Bay 1 Status'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);

      await tester.tap(find.text('In Progress'));
      await tester.pumpAndSettle();

      expect(updatedStatus, 'in_progress');
    });

    testWidgets('WeeklyCashFlowChart renders 7 days and inflow summary', (tester) async {
      final now = DateTime.now();
      final cashFlowData = List.generate(
        7,
        (i) => DailyCashFlow(
          date: now.subtract(Duration(days: 6 - i)),
          dayLabel: ['Wed', 'Thu', 'Fri', 'Sat', 'Sun', 'Mon', 'Tue'][i],
          income: (i + 1) * 200.0,
          expense: (i + 1) * 50.0,
          isToday: i == 6,
        ),
      );

      await tester.pumpWidget(
        createTestWidget(
          Scaffold(
            body: WeeklyCashFlowChart(
              cashFlowData: cashFlowData,
              weekInflow: 5600.0,
              currency: CurrencyManager(),
            ),
          ),
        ),
      );

      expect(find.text('Weekly Cash Flow'), findsOneWidget);
      expect(find.text('Last 7 Days (Income vs Expense)'), findsOneWidget);
      expect(find.text('OMR 5,600.000'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
    });

    testWidgets('DashboardScreen renders KPIs and header', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const DashboardScreen(),
        ),
      );

      expect(find.text('Executive Dashboard'), findsOneWidget);
      expect(find.text("TODAY'S INCOME"), findsOneWidget);
      expect(find.text("TODAY'S EXPENSE"), findsOneWidget);
      expect(find.text('TOTAL OUTSTANDING DUES'), findsOneWidget);
      expect(find.text('LOW STOCK ALERTS'), findsOneWidget);
    });
  });
}
