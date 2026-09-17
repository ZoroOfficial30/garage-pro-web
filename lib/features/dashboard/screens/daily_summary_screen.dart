import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/currency/currency_manager.dart';
import '../../../core/localization/app_locale.dart';
import '../../../data/models/transaction_record.dart';
import '../../../data/models/expense_record.dart';
import '../../../data/repositories/garage_repository.dart';
import '../widgets/record_income_modal.dart';
import '../../expenses/widgets/add_edit_expense_modal.dart';
import '../../../shared/widgets/statement_modal_helper.dart';
import '../../../shared/widgets/common_print_header.dart';

class DailySummaryScreen extends StatefulWidget {
  final DateTime? initialDate;

  const DailySummaryScreen({super.key, this.initialDate});

  @override
  State<DailySummaryScreen> createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends State<DailySummaryScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = widget.initialDate ?? DateTime(now.year, now.month, now.day);
  }

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
  }

  void _nextDay() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_selectedDate.isBefore(today)) {
      setState(() {
        _selectedDate = _selectedDate.add(const Duration(days: 1));
      });
    }
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  void _showDailyStatementModal(
    BuildContext context,
    DailyIncomeBreakdown income,
    DailyExpenseBreakdown expense,
    CurrencyManager currency,
    AppLocaleManager locale,
  ) {
    final repo = Provider.of<GarageRepository>(context, listen: false);
    final profile = repo.workshopProfile;
    final workshopName = repo.getWorkshopName();
    final address = profile['address'] ?? '';
    final phone = profile['phone'] ?? '';
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(_selectedDate);
    final net = income.totalIncome - expense.totalExpense;
    final isSurplus = net >= 0;

    final buffer = StringBuffer();
    buffer.writeln('========================================');
    buffer.writeln(workshopName.toUpperCase());
    if (address.isNotEmpty) buffer.writeln(address);
    if (phone.isNotEmpty) buffer.writeln('Phone: $phone');
    buffer.writeln('========================================');
    buffer.writeln('DAILY CLOSE & ACCOUNTS STATEMENT');
    buffer.writeln('Date: $dateStr');
    buffer.writeln('----------------------------------------');
    buffer.writeln('INCOME SUMMARY:');
    buffer.writeln('• Car Wash:       ${currency.format(income.carWashIncome)} (${income.carWashCount} cars)');
    buffer.writeln('• Settle Payments: ${currency.format(income.settlePaymentIncome)} (${income.settlePaymentCount} payments)');
    buffer.writeln('• Other Services:  ${currency.format(income.otherIncome)} (${income.otherIncomeCount} items)');
    buffer.writeln('TOTAL INCOME:     ${currency.format(income.totalIncome)}');
    buffer.writeln('----------------------------------------');
    buffer.writeln('EXPENSE SUMMARY:');
    if (expense.categoryTotals.isEmpty) {
      buffer.writeln('• No expenses logged for this day.');
    } else {
      expense.categoryTotals.forEach((category, amount) {
        buffer.writeln('• $category: ${currency.format(amount)}');
      });
    }
    buffer.writeln('TOTAL EXPENSE:    ${currency.format(expense.totalExpense)}');
    buffer.writeln('----------------------------------------');
    buffer.writeln(isSurplus
        ? 'NET CASH IN-HAND / SURPLUS: +${currency.format(net)}'
        : 'NET CASH DEFICIT:          ${currency.format(net)}');
    buffer.writeln('========================================');
    buffer.writeln('End of Daily Statement');

    final plainText = buffer.toString();

    StatementModalHelper.show(
      context: context,
      title: locale.isBangla ? 'দৈনিক ক্লোজিং বিবরণী' : 'Daily Close Statement',
      subtitle: dateStr,
      textStatement: plainText,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: isSurplus ? AppColors.success.withValues(alpha: 0.1) : AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSurplus ? AppColors.success.withValues(alpha: 0.3) : AppColors.danger.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isSurplus
                      ? (locale.isBangla ? 'নীট উদ্বৃত্ত (ক্যাশ ইন-হ্যান্ড)' : 'Net Cash Surplus')
                      : (locale.isBangla ? 'নীট ঘাটতি' : 'Net Deficit'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isSurplus ? AppColors.success : AppColors.danger,
                  ),
                ),
                Text(
                  '${isSurplus ? '+' : ''}${currency.format(net)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isSurplus ? AppColors.success : AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale.isBangla ? 'মোট আয়' : 'Total Income',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currency.format(income.totalIncome),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.success),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale.isBangla ? 'মোট খরচ' : 'Total Expense',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currency.format(expense.totalExpense),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.danger),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            locale.isBangla ? 'আয়ের খাতসমূহ' : 'Income Breakdown',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildReceiptSummaryRow('Car Wash (${income.carWashCount})', currency.format(income.carWashIncome)),
                const Divider(height: 12, color: AppColors.border),
                _buildReceiptSummaryRow('Settled Bills (${income.settlePaymentCount})', currency.format(income.settlePaymentIncome)),
                const Divider(height: 12, color: AppColors.border),
                _buildReceiptSummaryRow('Other Services (${income.otherIncomeCount})', currency.format(income.otherIncome)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            locale.isBangla ? 'খরচের খাতসমূহ' : 'Expense Breakdown',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: expense.categoryTotals.isEmpty
                ? Text(
                    locale.isBangla ? 'এই দিনে কোনো খরচ নেই' : 'No expenses recorded for this date',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  )
                : Column(
                    children: expense.categoryTotals.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: _buildReceiptSummaryRow(e.key, currency.format(e.value)),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  static Widget _buildReceiptSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<GarageRepository>(context);
    final currency = Provider.of<CurrencyManager>(context);
    final locale = Provider.of<AppLocaleManager>(context);

    final incomeBreakdown = repo.getDailyIncomeBreakdown(_selectedDate);
    final expenseBreakdown = repo.getDailyExpenseBreakdown(_selectedDate);
    final isClosed = repo.isDayClosed(_selectedDate);
    final closedRecord = repo.getDayCloseRecord(_selectedDate);

    final netAmount = incomeBreakdown.totalIncome - expenseBreakdown.totalExpense;
    final isSurplus = netAmount >= 0;
    final dateStr = DateFormat('EEE, d MMM yyyy').format(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 6),
                Text(
                  locale.isBangla ? 'দৈনিক হিসাব ও সারাংশ' : 'Daily Income & Expense',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            Text(
              _isToday ? 'Today\'s Close • $dateStr' : dateStr,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: locale.isBangla ? 'দৈনিক বিবরণী প্রিন্ট / শেয়ার' : 'Print / Share Daily Statement',
            icon: const Icon(Icons.print_rounded, color: AppColors.textPrimary),
            onPressed: () => _showDailyStatementModal(
              context,
              incomeBreakdown,
              expenseBreakdown,
              currency,
              locale,
            ),
          ),
          IconButton(
            tooltip: 'Log Income',
            icon: const Icon(Icons.add_chart_rounded, color: AppColors.success),
            onPressed: () => _handleQuickAction(
              context,
              isClosed,
              () => RecordIncomeModal.show(context),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.5),
          child: Divider(height: 1.5, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 0. Workshop Report Header
                _buildWorkshopReportHeader(repo, locale),
                const SizedBox(height: 14),

                // 1. Day Navigation Ribbon
                _buildDayNavigationRibbon(),
                const SizedBox(height: 16),

                // 1.5. Day Closed & Locked Banner
                if (isClosed && closedRecord != null) ...[
                  _buildClosedDayBanner(closedRecord, repo, locale),
                  const SizedBox(height: 16),
                ],

                // 2. Net Cash Status Hero Card (Large & Prominent)
                _buildNetStatusCard(
                  netAmount,
                  isSurplus,
                  incomeBreakdown,
                  expenseBreakdown,
                  currency,
                  isClosed: isClosed,
                ),
                const SizedBox(height: 20),

                // 3. Quick Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.local_car_wash_rounded, size: 20),
                        label: Text(
                          locale.isBangla ? '+ কার ওয়াশ / আয়' : '+ Car Wash / Income',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        onPressed: () => _handleQuickAction(
                          context,
                          isClosed,
                          () => RecordIncomeModal.show(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                        label: Text(
                          locale.isBangla ? '+ খরচ যুক্ত করুন' : '+ Log Expense',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        onPressed: () => _handleQuickAction(
                          context,
                          isClosed,
                          () => AddEditExpenseModal.show(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 4. Income Side Breakdown Card
                _buildIncomeBreakdownSection(incomeBreakdown, currency, locale),
                const SizedBox(height: 20),

                // 5. Expense Side Breakdown Card
                _buildExpenseBreakdownSection(expenseBreakdown, currency, locale),
                const SizedBox(height: 20),

                // 6. Prominent End of Day Button
                _buildEndOfDayButton(
                  context,
                  repo,
                  currency,
                  locale,
                  incomeBreakdown,
                  expenseBreakdown,
                  netAmount,
                  isSurplus,
                  isClosed,
                  closedRecord,
                ),
                const SizedBox(height: 12),

                // 7. Footer Copy Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.print_rounded, color: AppColors.primary, size: 18),
                    label: Text(
                      locale.isBangla ? 'দৈনিক হিসাব প্রিন্ট / শেয়ার করুন' : 'Print / Share Daily Statement',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        fontSize: 14,
                      ),
                    ),
                    onPressed: () => _showDailyStatementModal(
                      context,
                      incomeBreakdown,
                      expenseBreakdown,
                      currency,
                      locale,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildWorkshopReportHeader(GarageRepository repo, AppLocaleManager locale) {
    return CommonPrintHeader(
      title: locale.isBangla ? 'দৈনিক রিপোর্ট' : 'DAILY REPORT',
      subtitle: DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
      date: _selectedDate,
      showDivider: false,
    );
  }

  Widget _buildDayNavigationRibbon() {
    final now = DateTime.now();
    final isTomorrowBlocked = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day >= now.day;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            color: AppColors.textPrimary,
            tooltip: 'Previous Day',
            onPressed: _previousDay,
          ),
          GestureDetector(
            onTap: () => _pickDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 28),
                color: isTomorrowBlocked ? AppColors.textSecondary.withValues(alpha: 0.3) : AppColors.textPrimary,
                tooltip: 'Next Day',
                onPressed: isTomorrowBlocked ? null : _nextDay,
              ),
              if (!_isToday) ...[
                const SizedBox(width: 4),
                TextButton(
                  onPressed: _goToToday,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Today', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _handleQuickAction(BuildContext context, bool isClosed, VoidCallback action) {
    if (isClosed) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.lock_rounded, color: AppColors.warning),
              SizedBox(width: 8),
              Text('Ledger Locked'),
            ],
          ),
          content: const Text(
            'This day\'s ledger is already closed and locked. To add new entries for this date, please re-open the ledger first or select an open date.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    action();
  }

  Widget _buildClosedDayBanner(
    DayCloseRecord record,
    GarageRepository repo,
    AppLocaleManager locale,
  ) {
    final closeTimeStr = DateFormat('hh:mm a • d MMM yyyy').format(record.closedAt);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.lock_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                locale.isBangla ? 'দিন সমাপ্ত ও হিসাব লকড' : 'Day Closed & Ledger Locked',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.successLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'FINALIZED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Closed by ${record.closedBy} • $closeTimeStr',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.lock_open_rounded, color: AppColors.textSecondary, size: 22),
                tooltip: 'Re-open Ledger',
                onPressed: () => _confirmReopenDay(context, repo, locale),
              ),
            ],
          ),
          if (record.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.note_alt_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Closing Note: ${record.notes}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEndOfDayButton(
    BuildContext context,
    GarageRepository repo,
    CurrencyManager currency,
    AppLocaleManager locale,
    DailyIncomeBreakdown income,
    DailyExpenseBreakdown expense,
    double netAmount,
    bool isSurplus,
    bool isClosed,
    DayCloseRecord? closedRecord,
  ) {
    if (isClosed) {
      return Container(
        width: double.infinity,
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.successLight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.success, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_rounded, color: AppColors.success, size: 24),
            const SizedBox(width: 10),
            Text(
              locale.isBangla ? 'দিন সমাপ্ত ও হিসাব লক করা হয়েছে' : 'End of Day Completed • Ledger Locked',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        icon: const Icon(Icons.lock_clock_rounded, size: 24),
        label: Text(
          locale.isBangla ? 'দিন সমাপ্ত করুন (হিসাব লক)' : 'End of Day (Lock Ledger)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        onPressed: () => _showEndOfDayDialog(
          context,
          repo,
          currency,
          locale,
          income,
          expense,
          netAmount,
          isSurplus,
        ),
      ),
    );
  }

  void _showEndOfDayDialog(
    BuildContext context,
    GarageRepository repo,
    CurrencyManager currency,
    AppLocaleManager locale,
    DailyIncomeBreakdown income,
    DailyExpenseBreakdown expense,
    double netAmount,
    bool isSurplus,
  ) {
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(_selectedDate);
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_clock_rounded, color: AppColors.primaryDark, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                locale.isBangla ? 'দিন সমাপ্ত ও হিসাব লক করুন' : 'Confirm End of Day',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to finalize and lock the financial ledger for $dateStr?',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              // Snapshot Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Income:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        Text(currency.format(income.totalIncome), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.success)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Expense:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        Text(currency.format(expense.totalExpense), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.danger)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Final Net:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                        Text(
                          isSurplus ? '+${currency.format(netAmount)}' : currency.format(netAmount),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: isSurplus ? AppColors.success : AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Optional Closing Notes
              TextField(
                controller: notesCtrl,
                decoration: InputDecoration(
                  labelText: locale.isBangla ? 'ক্লোজিং নোট / মন্তব্য (ঐচ্ছিক)' : 'Closing Notes / Comments (Optional)',
                  hintText: 'e.g., Safe cash verified, workshop locked',
                  prefixIcon: const Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warningLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Closing the day locks today\'s report to prevent accidental changes.',
                        style: TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(locale.translate('cancel')),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.lock_rounded, size: 18),
            label: Text(locale.isBangla ? 'লক নিশ্চিত করুন' : 'Confirm & Lock Day'),
            onPressed: () async {
              Navigator.pop(ctx);
              await repo.closeDay(
                _selectedDate,
                closedBy: 'Manager',
                notes: notesCtrl.text.trim(),
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'End of Day completed! Ledger for $dateStr is now finalized and locked.',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: AppColors.primaryDark,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmReopenDay(BuildContext context, GarageRepository repo, AppLocaleManager locale) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.lock_open_rounded, color: AppColors.warning),
            SizedBox(width: 10),
            Text('Re-open Day Ledger?'),
          ],
        ),
        content: const Text(
          'Unlocking this day will allow recording new income and expenses or making adjustments to the ledger.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(locale.translate('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await repo.reopenDay(_selectedDate);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Day ledger unlocked for editing.'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              }
            },
            child: const Text('Unlock & Re-open'),
          ),
        ],
      ),
    );
  }

  Widget _buildNetStatusCard(
    double netAmount,
    bool isSurplus,
    DailyIncomeBreakdown income,
    DailyExpenseBreakdown expense,
    CurrencyManager currency, {
    bool isClosed = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isSurplus ? AppColors.successLight.withValues(alpha: 0.4) : AppColors.dangerLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSurplus ? AppColors.success : AppColors.danger,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSurplus ? AppColors.success : AppColors.danger,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSurplus ? Icons.check_circle_rounded : Icons.warning_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isSurplus ? 'NET SURPLUS (CASH IN-HAND)' : 'NET DEFICIT',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (isClosed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.lock_rounded, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'LOCKED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  _isToday ? 'Real-time calculation' : 'Open Ledger',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Big Net Number
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                isSurplus
                    ? '+${currency.format(netAmount)}'
                    : currency.format(netAmount),
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: isSurplus ? AppColors.success : AppColors.danger,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              if (income.totalIncome > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '${((netAmount / income.totalIncome) * 100).toStringAsFixed(1)}% margin',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSurplus ? AppColors.success : AppColors.danger,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),

          // Quick 2-Column comparison
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_downward_rounded, color: AppColors.success, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL INCOME',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          currency.format(income.totalIncome),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 35, color: AppColors.border),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.dangerLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_upward_rounded, color: AppColors.danger, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL EXPENSE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          currency.format(expense.totalExpense),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeBreakdownSection(
    DailyIncomeBreakdown income,
    CurrencyManager currency,
    AppLocaleManager locale,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.trending_up_rounded, color: AppColors.success, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    locale.isBangla ? 'আয়ের খাত ও বিবরণী' : 'Income Breakdown',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                currency.format(income.totalIncome),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),

          // 3 Distinct Income Pillars
          _buildBreakdownRow(
            title: 'Car Wash Income',
            subtitle: '${income.carWashCount} vehicles washed',
            amount: currency.format(income.carWashIncome),
            icon: Icons.local_car_wash_rounded,
            iconColor: AppColors.primary,
            iconBgColor: AppColors.primaryLight,
          ),
          const SizedBox(height: 10),
          _buildBreakdownRow(
            title: 'Customer Dues Collected',
            subtitle: '${income.settlePaymentCount} settle payments received',
            amount: currency.format(income.settlePaymentIncome),
            icon: Icons.payments_rounded,
            iconColor: AppColors.success,
            iconBgColor: AppColors.successLight,
          ),
          const SizedBox(height: 10),
          _buildBreakdownRow(
            title: 'Other Services & Income',
            subtitle: '${income.otherIncomeCount} transactions',
            amount: currency.format(income.otherIncome),
            icon: Icons.build_circle_rounded,
            iconColor: Colors.purple,
            iconBgColor: Colors.purple.shade50,
          ),
          const SizedBox(height: 16),

          // Income Transactions List
          if (income.transactions.isNotEmpty) ...[
            const Text(
              'TODAY\'S INFLOW TRANSACTIONS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            ...income.transactions.map((tx) => _buildTransactionItem(tx, currency)),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              alignment: Alignment.center,
              child: const Text(
                'No income transactions recorded for this day.',
                style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpenseBreakdownSection(
    DailyExpenseBreakdown expense,
    CurrencyManager currency,
    AppLocaleManager locale,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.trending_down_rounded, color: AppColors.danger, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    locale.isBangla ? 'খরচের খাত ও বিবরণী' : 'Expense Breakdown',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                currency.format(expense.totalExpense),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),

          // Categorized Expense Summary
          if (expense.categoryTotals.isNotEmpty) ...[
            ...expense.categoryTotals.entries.map((entry) {
              final pct = expense.totalExpense > 0 ? (entry.value / expense.totalExpense) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(_getCategoryIcon(entry.key), size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          currency.format(entry.value),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 5,
                        backgroundColor: AppColors.border.withValues(alpha: 0.5),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.danger),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: const Text(
                'No expenses logged for this day.',
                style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Expenses List
          if (expense.expenses.isNotEmpty) ...[
            const Text(
              'EXPENSE ENTRIES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            ...expense.expenses.map((exp) => _buildExpenseItem(exp, currency)),
          ],
        ],
      ),
    );
  }

  Widget _buildBreakdownRow({
    required String title,
    required String subtitle,
    required String amount,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(TransactionRecord tx, CurrencyManager currency) {
    final timeStr = DateFormat('hh:mm a').format(tx.date);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: tx.isCarWash ? AppColors.primaryLight : AppColors.successLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tx.isCarWash ? 'CAR WASH' : 'PAYMENT',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: tx.isCarWash ? AppColors.primary : AppColors.success,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description.isNotEmpty ? tx.description : tx.customerName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${tx.customerName} • $timeStr • ${tx.paymentMethod.toUpperCase()}',
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '+${currency.format(tx.amount)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(ExpenseRecord exp, CurrencyManager currency) {
    final timeStr = DateFormat('hh:mm a').format(exp.date);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.dangerLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              exp.category.toUpperCase(),
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppColors.danger,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exp.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '$timeStr • ${exp.paymentMethod.toUpperCase()}',
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '-${currency.format(exp.amount)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'tools & equipment':
      case 'tools':
        return Icons.construction_rounded;
      case 'electricity / utilities':
      case 'electricity':
      case 'utilities':
        return Icons.electric_bolt_rounded;
      case 'staff food & tea':
      case 'food':
        return Icons.restaurant_rounded;
      case 'staff salary':
      case 'salary':
        return Icons.badge_outlined;
      case 'rent':
        return Icons.store_rounded;
      case 'consumables':
        return Icons.water_drop_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }
}
