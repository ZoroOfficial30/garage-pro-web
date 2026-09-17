import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/currency/currency_manager.dart';
import '../../../core/localization/app_locale.dart';
import '../../../data/repositories/garage_repository.dart';
import '../../home/widgets/action_confirmation_card.dart';
import '../widgets/kpi_card.dart';
import '../widgets/weekly_cash_flow_chart.dart';
import '../../navigation/widgets/drawer_helper.dart';
import '../../employees/screens/employees_screen.dart';
import '../../settings/screens/settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback? onNavigateToCustomers;
  final VoidCallback? onNavigateToStock;
  final VoidCallback? onNavigateToExpenses;
  final VoidCallback? onNavigateToStaff;

  const DashboardScreen({
    super.key,
    this.onNavigateToCustomers,
    this.onNavigateToStock,
    this.onNavigateToExpenses,
    this.onNavigateToStaff,
  });

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<GarageRepository>(context);
    final currency = Provider.of<CurrencyManager>(context);
    final locale = Provider.of<AppLocaleManager>(context);

    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMM yyyy • hh:mm a').format(now);

    final netMargin = repo.todayIncome - repo.todayExpense;
    final overdueCount = repo.customers.where((c) => c.totalDue > 0).length;

    // Low stock item names preview
    final lowStockNames = repo.lowStockItems.map((s) => s.name.split(' ').first).take(3).join(', ');
    final lowStockSubtitle = lowStockNames.isNotEmpty ? lowStockNames : 'All stock levels optimal';

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      drawer: buildAppDrawer(context),
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                iconSize: 24,
                tooltip: 'Back',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () => Navigator.of(context).pop(),
              )
            : buildDrawerHamburgerButton(context),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.garage_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  locale.translate('executive_dashboard'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.5),
          child: Divider(height: 1.5, color: AppColors.border),
        ),
        actions: [
          IconButton(
            tooltip: locale.isBangla ? 'স্টাফ ও বেতন' : 'Staff & Attendance',
            icon: const Icon(Icons.badge_outlined, color: AppColors.textPrimary),
            onPressed: () {
              if (onNavigateToStaff != null) {
                onNavigateToStaff!();
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EmployeesScreen()),
                );
              }
            },
          ),
          IconButton(
            tooltip: locale.translate('settings'),
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 5-second Undo Bar (Destructive / State Change Undo Window)
                if (repo.lastUndoAction != null) ...[
                  ActionConfirmationCard(
                    title: repo.lastUndoAction!.title,
                    description: repo.lastUndoAction!.description,
                    countdownSeconds: repo.undoCountdown,
                    onUndo: () => repo.undoLastAction(),
                  ),
                  const SizedBox(height: 16),
                ],

                // 1. 2x2 KPI Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 650;
                    final crossAxisCount = isWide ? 4 : 2;
                    final cardAspectRatio = isWide
                        ? 1.3
                        : (constraints.maxWidth < 360 ? 0.88 : (constraints.maxWidth < 400 ? 0.95 : 1.05));

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: cardAspectRatio,
                      children: [
                        // Card 1: Today's Income
                        KpiCard(
                          title: locale.translate('today_income'),
                          amount: currency.format(repo.todayIncome),
                          subtitle: '+18% vs yesterday • ${repo.todaySettledJobsCount} Settled',
                          icon: Icons.payments_rounded,
                          accentColor: AppColors.primary,
                          subtitleIcon: Icons.trending_up,
                          badgeBgColor: AppColors.primaryLight,
                          badgeTextColor: AppColors.primary,
                          onTap: onNavigateToExpenses,
                        ),

                        // Card 2: Today's Expense
                        KpiCard(
                          title: locale.translate('today_expense'),
                          amount: currency.format(repo.todayExpense),
                          subtitle: netMargin >= 0
                              ? 'Net: +${currency.format(netMargin)}'
                              : 'Net: ${currency.format(netMargin)}',
                          icon: Icons.receipt_long_rounded,
                          accentColor: AppColors.danger,
                          subtitleIcon: Icons.account_balance_wallet_outlined,
                          badgeBgColor: netMargin >= 0
                              ? AppColors.successLight
                              : AppColors.dangerLight,
                          badgeTextColor:
                              netMargin >= 0 ? AppColors.success : AppColors.danger,
                          onTap: onNavigateToExpenses,
                        ),

                        // Card 3: Total Outstanding Due
                        KpiCard(
                          title: locale.translate('total_dues'),
                          amount: currency.format(repo.totalOutstandingDues),
                          subtitle: '$overdueCount Customers with Due',
                          icon: Icons.warning_amber_rounded,
                          accentColor: AppColors.danger,
                          subtitleIcon: Icons.warning_rounded,
                          badgeBgColor: AppColors.danger,
                          badgeTextColor: Colors.white,
                          isAlert: true,
                          onTap: onNavigateToCustomers,
                        ),

                        // Card 4: Low Stock Alerts
                        KpiCard(
                          title: 'LOW STOCK ALERTS',
                          amount: '${repo.lowStockCount} ITEMS',
                          subtitle: lowStockSubtitle,
                          icon: Icons.inventory_2_rounded,
                          accentColor: AppColors.warning,
                          subtitleIcon: Icons.notification_important_rounded,
                          badgeBgColor: AppColors.warningLight,
                          badgeTextColor: AppColors.warning,
                          onTap: onNavigateToStock,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                // 2. 7-Day Cash Flow Bar Chart
                WeeklyCashFlowChart(
                  cashFlowData: repo.getWeeklyCashFlow(),
                  weekInflow: repo.getWeeklyInflow(),
                  currency: currency,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
