import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/currency/currency_manager.dart';
import '../../../core/localization/app_locale.dart';
import '../../../data/models/expense_record.dart';
import '../../../data/models/transaction_record.dart';
import '../../../data/repositories/garage_repository.dart';
import '../../home/widgets/action_confirmation_card.dart';
import '../../expenses/widgets/add_edit_expense_modal.dart';
import '../../dashboard/widgets/record_income_modal.dart';
import '../../navigation/widgets/drawer_helper.dart';
import '../../../shared/widgets/common_print_header.dart';

class CashbookScreen extends StatefulWidget {
  const CashbookScreen({super.key});

  @override
  State<CashbookScreen> createState() => _CashbookScreenState();
}

class _CashbookScreenState extends State<CashbookScreen> {
  String _selectedPeriod = 'today'; // 'today', 'week', 'month', 'custom'
  DateTime? _selectedCustomDate;

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedCustomDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
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
        _selectedPeriod = 'custom';
        _selectedCustomDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  DateTime get _effectiveDate {
    if (_selectedPeriod == 'custom' && _selectedCustomDate != null) {
      return _selectedCustomDate!;
    }
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool get _isSingleDayView =>
      _selectedPeriod == 'today' || _selectedPeriod == 'custom';

  String _getPeriodLabel(AppLocaleManager locale) {
    if (_selectedPeriod == 'today') {
      final now = DateTime.now();
      return '${locale.translate('today')} • ${DateFormat('EEE, d MMM yyyy').format(now)}';
    } else if (_selectedPeriod == 'week') {
      return locale.isBangla ? 'এই সপ্তাহ (গত ৭ দিন)' : 'This Week (Last 7 Days)';
    } else if (_selectedPeriod == 'month') {
      return locale.isBangla
          ? 'এই মাস (${DateFormat('MMMM yyyy').format(DateTime.now())})'
          : 'This Month (${DateFormat('MMMM yyyy').format(DateTime.now())})';
    } else if (_selectedPeriod == 'custom' && _selectedCustomDate != null) {
      return DateFormat('EEEE, d MMM yyyy').format(_selectedCustomDate!);
    }
    return locale.translate('cashbook');
  }

  void _confirmLockLedger(
    BuildContext context,
    GarageRepository repo,
    AppLocaleManager locale,
    CurrencyManager currency,
    DailyIncomeBreakdown income,
    DailyExpenseBreakdown expense,
  ) {
    final targetDate = _effectiveDate;
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(targetDate);
    final net = income.totalIncome - expense.totalExpense;
    final isSurplus = net >= 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_clock_rounded, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                locale.isBangla ? 'দিন সমাপ্তি ও লেজার লক' : 'Close Day & Lock Ledger',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locale.translate('lock_ledger_confirm'),
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
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
                      const Text('Date:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary)),
                      Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    ],
                  ),
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Income:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.success)),
                      Text(currency.format(income.totalIncome), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.success)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Expense:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.danger)),
                      Text(currency.format(expense.totalExpense), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.danger)),
                    ],
                  ),
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Net Cash Close:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      Text(
                        isSurplus ? '+${currency.format(net)}' : currency.format(net),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: isSurplus ? AppColors.success : AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(locale.translate('cancel')),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.lock_rounded, size: 16),
            label: Text(locale.isBangla ? 'লক নিশ্চিত করুন' : 'Confirm Lock'),
            onPressed: () async {
              await repo.closeDay(targetDate, closedBy: 'Manager');
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(locale.isBangla
                        ? 'দিন সফলভাবে সমাপ্ত ও লক করা হয়েছে!'
                        : 'Day successfully closed and ledger locked!'),
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

  void _showPrintStatementModal(
    BuildContext context,
    GarageRepository repo,
    AppLocaleManager locale,
    CurrencyManager currency,
    DailyIncomeBreakdown income,
    DailyExpenseBreakdown expense,
  ) {
    final profile = repo.workshopProfile;
    final workshopName = profile['name']?.isNotEmpty == true
        ? profile['name']!
        : 'Apex Auto Workshop';
    final workshopPhone = profile['phone'] ?? '';
    final workshopAddress = profile['address'] ?? '';
    final periodLabel = _getPeriodLabel(locale);
    final net = income.totalIncome - expense.totalExpense;
    final isSurplus = net >= 0;

    final textStatement = StringBuffer();
    textStatement.writeln('========================================');
    textStatement.writeln('       ${workshopName.toUpperCase()}');
    if (workshopAddress.isNotEmpty) textStatement.writeln('  $workshopAddress');
    if (workshopPhone.isNotEmpty) textStatement.writeln('  Tel: $workshopPhone');
    textStatement.writeln('========================================');
    textStatement.writeln('  CASHBOOK STATEMENT');
    textStatement.writeln('  Period: $periodLabel');
    textStatement.writeln('  Generated: ${DateFormat('d MMM yyyy, hh:mm a').format(DateTime.now())}');
    textStatement.writeln('----------------------------------------');
    textStatement.writeln('INCOME / COLLECTIONS:');
    textStatement.writeln(' • Car Wash: ${currency.format(income.carWashIncome)} (${income.carWashCount} vehicles)');
    textStatement.writeln(' • Dues Settled: ${currency.format(income.settlePaymentIncome)} (${income.settlePaymentCount} payments)');
    textStatement.writeln(' • Other Services: ${currency.format(income.otherIncome)} (${income.otherIncomeCount} items)');
    textStatement.writeln(' TOTAL INCOME: ${currency.format(income.totalIncome)}');
    if (income.transactions.isNotEmpty) {
      textStatement.writeln(' ITEMIZED COLLECTIONS:');
      for (final tx in income.transactions) {
        final custStr = tx.isPayment
            ? ' (From: ${tx.customerName})'
            : (tx.customerName.isNotEmpty && tx.customerName != 'Walk-in Customer'
                ? ' (${tx.customerName})'
                : '');
        textStatement.writeln(
            '   - ${tx.description}$custStr: ${currency.format(tx.amount)} [${tx.paymentMethod.toUpperCase()}]');
      }
    }
    textStatement.writeln('----------------------------------------');
    textStatement.writeln('EXPENSES / OUTFLOWS:');
    if (expense.categoryTotals.isEmpty) {
      textStatement.writeln(' • No expenses recorded in this period.');
    } else {
      expense.categoryTotals.forEach((cat, amt) {
        textStatement.writeln(' • $cat: ${currency.format(amt)}');
      });
    }
    textStatement.writeln(' TOTAL EXPENSE: ${currency.format(expense.totalExpense)}');
    textStatement.writeln('========================================');
    textStatement.writeln(isSurplus
        ? 'NET SURPLUS / IN-HAND: +${currency.format(net)}'
        : 'NET DEFICIT: ${currency.format(net)}');
    textStatement.writeln('========================================');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Common Workshop Print Header
              CommonPrintHeader(
                title: locale.isBangla ? 'ক্যাশ বুক বিবরণী' : 'CASHBOOK STATEMENT',
                subtitle: periodLabel,
                showDivider: false,
              ),
              const SizedBox(height: 8),

              // Surplus / Deficit Badge Banner
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSurplus ? AppColors.successLight : AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isSurplus ? 'SURPLUS' : 'DEFICIT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: isSurplus ? AppColors.success : AppColors.danger,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Income Breakdown Table
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            locale.isBangla ? 'আয়ের বিবরণী' : 'Income Breakdown',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary),
                          ),
                          Text(
                            currency.format(income.totalIncome),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    _buildStatementRow('Car Wash', currency.format(income.carWashIncome), '${income.carWashCount} jobs'),
                    _buildStatementRow('Dues Settled', currency.format(income.settlePaymentIncome), '${income.settlePaymentCount} payments'),
                    _buildStatementRow('Other Income', currency.format(income.otherIncome), '${income.otherIncomeCount} services'),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Expense Breakdown Table
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: const BoxDecoration(
                        color: AppColors.dangerLight,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            locale.isBangla ? 'ব্যয়ের বিবরণী' : 'Expense Breakdown',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.danger),
                          ),
                          Text(
                            currency.format(expense.totalExpense),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.danger),
                          ),
                        ],
                      ),
                    ),
                    if (expense.categoryTotals.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(14),
                        child: Text('No expenses recorded for this period.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      )
                    else
                      ...expense.categoryTotals.entries.map((e) => _buildStatementRow(e.key, currency.format(e.value), '')),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Big Net Summary Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSurplus ? AppColors.success.withValues(alpha: 0.1) : AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSurplus ? AppColors.success : AppColors.danger,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      isSurplus ? 'NET SURPLUS / CASH IN-HAND' : 'NET DEFICIT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isSurplus ? AppColors.success : AppColors.danger,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isSurplus ? '+${currency.format(net)}' : currency.format(net),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: isSurplus ? AppColors.success : AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.copy_rounded, color: AppColors.primary, size: 18),
                      label: Text(
                        locale.isBangla ? 'কপি করুন' : 'Copy Statement',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: textStatement.toString()));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: const [
                                Icon(Icons.assignment_turned_in_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text('Cashbook Statement copied to clipboard!', style: TextStyle(fontWeight: FontWeight.w700)),
                              ],
                            ),
                            backgroundColor: AppColors.primaryDark,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.print_rounded, size: 18),
                      label: Text(
                        locale.isBangla ? 'প্রিন্ট / শেয়ার' : 'Print / Share',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: textStatement.toString()));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Statement formatted and prepared for printing/sharing! (Copied to clipboard)'),
                            backgroundColor: AppColors.primaryDark,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatementRow(String label, String amount, String extra) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              if (extra.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text('($extra)', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ],
          ),
          Text(amount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  void _confirmDeleteIncome(BuildContext context, TransactionRecord tx) {
    final repo = Provider.of<GarageRepository>(context, listen: false);
    final locale = Provider.of<AppLocaleManager>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
            const SizedBox(width: 10),
            Text(
              locale.isBangla ? 'আয় মুছে ফেলতে চান?' : 'Delete Income Record?',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          tx.isPayment
              ? 'Remove payment of ${tx.amount} from "${tx.customerName}"?\nThis will restore the customer\'s due balance.'
              : 'Are you sure you want to remove "${tx.description}" (${tx.amount})?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(locale.translate('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              repo.deleteIncomeRecord(tx.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Removed income record: ${tx.description}'),
                  backgroundColor: AppColors.primaryDark,
                ),
              );
            },
            child: Text(locale.isBangla ? 'মুছে ফেলুন' : 'Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteExpense(BuildContext context, ExpenseRecord exp) {
    final repo = Provider.of<GarageRepository>(context, listen: false);
    final locale = Provider.of<AppLocaleManager>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
            const SizedBox(width: 10),
            Text(
              locale.isBangla ? 'খরচ মুছে ফেলতে চান?' : 'Delete Expense Record?',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${exp.title}" (${exp.category})?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(locale.translate('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              repo.deleteExpenseRecord(exp.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Removed expense: ${exp.title}'),
                  backgroundColor: AppColors.primaryDark,
                ),
              );
            },
            child: Text(locale.isBangla ? 'মুছে ফেলুন' : 'Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<GarageRepository>(context);
    final currency = Provider.of<CurrencyManager>(context);
    final locale = Provider.of<AppLocaleManager>(context);

    // Dynamic Income & Expense Breakdown based on selected period
    final DailyIncomeBreakdown income =
        repo.getIncomeBreakdownForPeriod(_selectedPeriod, customDate: _selectedCustomDate);
    final DailyExpenseBreakdown expense =
        repo.getExpenseBreakdownForPeriod(_selectedPeriod, customDate: _selectedCustomDate);

    final netAmount = income.totalIncome - expense.totalExpense;
    final isSurplus = netAmount >= 0;

    final targetDate = _effectiveDate;
    final isClosed = _isSingleDayView && repo.isDayClosed(targetDate);
    final closedRecord = isClosed ? repo.getDayCloseRecord(targetDate) : null;

    final quickCategories = [
      {'label': 'Tools & Gear', 'icon': '🔧'},
      {'label': 'Utilities/Bills', 'icon': '⚡'},
      {'label': 'Staff Food & Tea', 'icon': '🍱'},
      {'label': 'Workshop Rent', 'icon': '🏢'},
      {'label': 'Shop Consumables', 'icon': '🧴'},
      {'label': 'Staff Salary', 'icon': '💰'},
      {'label': 'Logistics / Other', 'icon': '🚚'},
    ];

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
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  locale.translate('cashbook'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            Text(
              _getPeriodLabel(locale),
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
            tooltip: locale.translate('print_share_statement'),
            icon: const Icon(Icons.print_outlined, color: AppColors.textPrimary),
            onPressed: () => _showPrintStatementModal(
              context,
              repo,
              locale,
              currency,
              income,
              expense,
            ),
          ),
          IconButton(
            tooltip: '+ Log Income',
            icon: const Icon(Icons.add_chart_rounded, color: AppColors.success),
            onPressed: () => RecordIncomeModal.show(context),
          ),
          IconButton(
            tooltip: '+ Log Expense',
            icon: const Icon(Icons.post_add_rounded, color: AppColors.danger),
            onPressed: () => AddEditExpenseModal.show(context),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.5),
          child: Divider(height: 1.5, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 950),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Undo Banner (destructions / updates)
                if (repo.lastUndoAction != null) ...[
                  ActionConfirmationCard(
                    title: repo.lastUndoAction!.title,
                    description: repo.lastUndoAction!.description,
                    countdownSeconds: repo.undoCountdown,
                    onUndo: () => repo.undoLastAction(),
                  ),
                  const SizedBox(height: 12),
                ],

                // 2. Period Selector: Today | This Week | This Month | Pick Date
                _buildPeriodSelector(locale),
                const SizedBox(height: 14),

                // 3. Day Closed Banner (if day locked)
                if (isClosed && closedRecord != null) ...[
                  _buildClosedDayBanner(closedRecord, repo, locale),
                  const SizedBox(height: 14),
                ],

                // 4. Big Net Amount Hero Card
                _buildNetHeroCard(
                  netAmount: netAmount,
                  isSurplus: isSurplus,
                  totalIncome: income.totalIncome,
                  totalExpense: expense.totalExpense,
                  currency: currency,
                  isClosed: isClosed,
                  onLockDay: _isSingleDayView
                      ? () => _confirmLockLedger(
                            context,
                            repo,
                            locale,
                            currency,
                            income,
                            expense,
                          )
                      : null,
                  onPrintStatement: () => _showPrintStatementModal(
                    context,
                    repo,
                    locale,
                    currency,
                    income,
                    expense,
                  ),
                  locale: locale,
                ),
                const SizedBox(height: 20),

                // 5. Clear Income Section
                _buildIncomeSection(
                  income: income,
                  currency: currency,
                  locale: locale,
                  isClosed: isClosed,
                ),
                const SizedBox(height: 20),

                // 6. Clear Expense Section
                _buildExpenseSection(
                  expense: expense,
                  currency: currency,
                  locale: locale,
                  quickCategories: quickCategories,
                  isClosed: isClosed,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildPeriodSelector(AppLocaleManager locale) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _buildPeriodPill('today', locale.isBangla ? 'আজকের' : 'Today'),
          _buildPeriodPill('week', locale.isBangla ? 'এই সপ্তাহ' : 'This Week'),
          _buildPeriodPill('month', locale.isBangla ? 'এই মাস' : 'This Month'),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _pickDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                decoration: BoxDecoration(
                  color: _selectedPeriod == 'custom'
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 16,
                      color: _selectedPeriod == 'custom'
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _selectedPeriod == 'custom' && _selectedCustomDate != null
                          ? DateFormat('d MMM').format(_selectedCustomDate!)
                          : (locale.isBangla ? 'তারিখ' : 'Pick Date'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _selectedPeriod == 'custom'
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodPill(String periodKey, String label) {
    final isSelected = _selectedPeriod == periodKey;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _selectedPeriod = periodKey),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClosedDayBanner(
    DayCloseRecord closedRecord,
    GarageRepository repo,
    AppLocaleManager locale,
  ) {
    final closedTimeStr = DateFormat('hh:mm a').format(closedRecord.closedAt);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      locale.isBangla ? 'লেজার লক করা হয়েছে' : 'LEDGER CLOSED & LOCKED',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: AppColors.success,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.lock_rounded, size: 14, color: AppColors.success),
                  ],
                ),
                Text(
                  'Locked at $closedTimeStr by ${closedRecord.closedBy}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              await repo.reopenDay(_effectiveDate);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ledger unlocked for modifications.'),
                    backgroundColor: AppColors.primaryDark,
                  ),
                );
              }
            },
            child: Text(
              locale.isBangla ? 'পুনরায় খুলুন' : 'Reopen',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetHeroCard({
    required double netAmount,
    required bool isSurplus,
    required double totalIncome,
    required double totalExpense,
    required CurrencyManager currency,
    required bool isClosed,
    required VoidCallback? onLockDay,
    required VoidCallback onPrintStatement,
    required AppLocaleManager locale,
  }) {
    final color = isSurplus ? AppColors.success : AppColors.danger;
    final bgColor = isSurplus ? AppColors.successLight : AppColors.dangerLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isSurplus ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    locale.isBangla ? 'নিট ক্যাশ ব্যালেন্স' : 'NET CASH BALANCE',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isSurplus ? 'SURPLUS' : 'DEFICIT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Big Net Amount Display
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              isSurplus ? '+${currency.format(netAmount)}' : currency.format(netAmount),
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Inflow vs Outflow Pills
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.arrow_downward_rounded, size: 14, color: AppColors.success),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Total Income',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          currency.format(totalIncome),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.success),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.arrow_upward_rounded, size: 14, color: AppColors.danger),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Total Expense',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          currency.format(totalExpense),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action Buttons: End of Day / Lock Ledger & Print / Share Statement
          Row(
            children: [
              if (onLockDay != null)
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isClosed ? AppColors.success : AppColors.primaryDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: Icon(isClosed ? Icons.lock_rounded : Icons.lock_clock_rounded, size: 18),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          isClosed
                              ? (locale.isBangla ? 'লেজার লক করা' : 'Day Locked')
                              : (locale.isBangla ? 'দিন সমাপ্ত / লেজার লক' : 'End of Day / Lock'),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ),
                      onPressed: isClosed ? null : onLockDay,
                    ),
                  ),
                ),
              if (onLockDay != null) const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.print_outlined, size: 18, color: AppColors.primary),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        locale.isBangla ? 'বিবরণী' : 'Statement',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary),
                      ),
                    ),
                    onPressed: onPrintStatement,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeSection({
    required DailyIncomeBreakdown income,
    required CurrencyManager currency,
    required AppLocaleManager locale,
    required bool isClosed,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.payments_rounded, color: AppColors.success, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    locale.isBangla ? 'আয় ও কালেকশন' : 'INCOME & COLLECTIONS',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  locale.isBangla ? '+ আয় লিখুন' : '+ Log Income',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
                onPressed: () => RecordIncomeModal.show(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3 Inflow Source Cards
          Row(
            children: [
              Expanded(
                child: _buildIncomeCard(
                  icon: Icons.local_car_wash_rounded,
                  title: 'Car Wash',
                  amount: currency.format(income.carWashIncome),
                  countStr: '${income.carWashCount} cars',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildIncomeCard(
                  icon: Icons.payments_rounded,
                  title: 'Dues Settled',
                  amount: currency.format(income.settlePaymentIncome),
                  countStr: '${income.settlePaymentCount} payments',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildIncomeCard(
                  icon: Icons.miscellaneous_services_rounded,
                  title: 'Other Income',
                  amount: currency.format(income.otherIncome),
                  countStr: '${income.otherIncomeCount} services',
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Total Income Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  locale.isBangla ? 'মোট সংগৃহীত আয়:' : 'Total Income Collected:',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.success),
                ),
                Text(
                  currency.format(income.totalIncome),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.success),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),

          // Income & Collection History Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                locale.isBangla ? 'কালেকশন ও আয়ের ইতিহাস' : 'COLLECTIONS & INFLOW HISTORY',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${income.transactions.length} Records',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (income.transactions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(Icons.account_balance_wallet_outlined,
                        size: 28, color: AppColors.success),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    locale.isBangla
                        ? 'এই সময়ে কোন আয় রেকর্ড নেই'
                        : 'No Income Transactions',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    locale.isBangla
                        ? 'পেমেন্ট গ্রহণ বা কার ওয়াশ এন্ট্রি করলে এখানে তালিকা দেখা যাবে।'
                        : 'Collect a customer payment or record car wash income to start.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: income.transactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (ctx, idx) {
                final tx = income.transactions[idx];
                return _buildIncomeHistoryItem(tx, currency, isClosed);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildIncomeHistoryItem(
    TransactionRecord tx,
    CurrencyManager currency,
    bool isClosed,
  ) {
    Color badgeColor;
    Color badgeBg;
    IconData badgeIcon;
    String badgeText;

    if (tx.isPayment) {
      badgeColor = AppColors.success;
      badgeBg = AppColors.successLight;
      badgeIcon = Icons.payments_rounded;
      badgeText = 'Due Settled';
    } else if (tx.isCarWash || tx.description.toLowerCase().contains('wash')) {
      badgeColor = AppColors.primary;
      badgeBg = AppColors.primaryLight;
      badgeIcon = Icons.local_car_wash_rounded;
      badgeText = 'Car Wash';
    } else if (tx.isStockSale || tx.type == 'stock_sale' || tx.description.toLowerCase().contains('stock')) {
      badgeColor = const Color(0xFFF59E0B);
      badgeBg = const Color(0xFFFEF3C7);
      badgeIcon = Icons.inventory_2_rounded;
      badgeText = 'Stock Sale';
    } else {
      badgeColor = const Color(0xFF6366F1);
      badgeBg = const Color(0xFFEEF2FF);
      badgeIcon = Icons.miscellaneous_services_rounded;
      badgeText = 'Other Income';
    }

    final timeStr = DateFormat('h:mm a • d MMM yyyy').format(tx.date);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badgeIcon, size: 13, color: badgeColor),
                          const SizedBox(width: 4),
                          Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: badgeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '+${currency.format(tx.amount)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                  if (!isClosed) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.textSecondary),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      tooltip: 'Delete',
                      onPressed: () => _confirmDeleteIncome(context, tx),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (tx.isPayment) ...[
                const Icon(Icons.person_rounded, size: 15, color: AppColors.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      children: [
                        const TextSpan(
                          text: 'From: ',
                          style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                        ),
                        TextSpan(
                          text: tx.customerName,
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        if (tx.description.isNotEmpty && tx.description != 'Payment Collected')
                          TextSpan(
                            text: ' • "${tx.description}"',
                            style: const TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                          ),
                      ],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else ...[
                Expanded(
                  child: Text(
                    tx.customerName.isNotEmpty && tx.customerName != 'Walk-in Customer'
                        ? '${tx.description} (Client: ${tx.customerName})'
                        : tx.description,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  tx.paymentMethod.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeCard({
    required IconData icon,
    required String title,
    required String amount,
    required String countStr,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              countStr,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseSection({
    required DailyExpenseBreakdown expense,
    required CurrencyManager currency,
    required AppLocaleManager locale,
    required List<Map<String, String>> quickCategories,
    required bool isClosed,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: AppColors.danger, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    locale.isBangla ? 'ব্যয় ও খরচসমূহ' : 'EXPENSES & OUTFLOWS',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  locale.isBangla ? '+ খরচ লিখুন' : '+ Log Expense',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
                onPressed: () => AddEditExpenseModal.show(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Total Expense Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.dangerLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  locale.isBangla ? 'মোট খরচ:' : 'Total Outflow:',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.danger),
                ),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      currency.format(expense.totalExpense),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.danger),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Quick Category Filter / Tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickCategories.map((c) {
              final catAmount = expense.categoryTotals[c['label']] ?? 0.0;
              return ActionChip(
                backgroundColor: catAmount > 0 ? AppColors.dangerLight : AppColors.background,
                side: BorderSide(
                  color: catAmount > 0 ? AppColors.danger : AppColors.border,
                ),
                avatar: Text(c['icon']!),
                label: Text(
                  catAmount > 0
                      ? '${c['label']}: ${currency.format(catAmount)}'
                      : c['label']!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: catAmount > 0 ? FontWeight.w800 : FontWeight.w600,
                    color: catAmount > 0 ? AppColors.danger : AppColors.textPrimary,
                  ),
                ),
                onPressed: () => AddEditExpenseModal.show(
                  context,
                  initialCategory: c['label'],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Detailed Expense Records List
          if (expense.expenses.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(Icons.receipt_long_outlined,
                        size: 28, color: AppColors.danger),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    locale.isBangla
                        ? 'এই সময়ে কোন খরচের রেকর্ড নেই'
                        : 'No Expense Records',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    locale.isBangla
                        ? 'দোকান বা গ্যারেজের খরচের হিসাব রাখতে উপরে খরচ ক্যাটাগরি বেছে নিন।'
                        : 'Tap any expense category above to record workshop spending.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: expense.expenses.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, index) {
                final exp = expense.expenses[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.receipt_rounded, color: AppColors.danger, size: 20),
                  ),
                  title: Text(
                    exp.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    '${exp.category} • ${exp.paymentMethod} • ${DateFormat('d MMM, hh:mm a').format(exp.date)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 88),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            currency.format(exp.amount),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.danger),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textSecondary),
                        onSelected: (val) {
                          if (val == 'edit') {
                            AddEditExpenseModal.show(context, existingExpense: exp);
                          } else if (val == 'delete') {
                            _confirmDeleteExpense(context, exp);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit Expense')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete Expense', style: TextStyle(color: AppColors.danger))),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
