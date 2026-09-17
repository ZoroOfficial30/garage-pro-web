import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/currency/currency_manager.dart';
import '../../../data/models/supplier_due.dart';
import '../../../data/repositories/garage_repository.dart';
import '../../../shared/widgets/statement_modal_helper.dart';
import '../../home/widgets/action_confirmation_card.dart';
import '../../navigation/widgets/drawer_helper.dart';
import '../widgets/supplier_due_card.dart';
import '../widgets/add_edit_supplier_due_modal.dart';

enum SupplierDueFilter { all, pending, paid }

class SupplierDuesScreen extends StatefulWidget {
  const SupplierDuesScreen({super.key});

  @override
  State<SupplierDuesScreen> createState() => _SupplierDuesScreenState();
}

class _SupplierDuesScreenState extends State<SupplierDuesScreen> {
  SupplierDueFilter _filter = SupplierDueFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<GarageRepository>();
    final locale = context.watch<AppLocale>();
    final currency = context.watch<CurrencyManager>();

    final allDues = repo.supplierDues;
    final totalDue = repo.totalOutstandingSupplierDues;
    final totalPaid = repo.totalPaidSupplierDues;
    final pendingCount = repo.pendingSupplierDuesCount;
    final settledCount = allDues.where((d) => d.isFullyPaid).length;

    // Filter by tab
    List<SupplierDue> displayedDues;
    switch (_filter) {
      case SupplierDueFilter.all:
        displayedDues = List.from(allDues);
        break;
      case SupplierDueFilter.pending:
        displayedDues = allDues.where((d) => !d.isFullyPaid).toList();
        break;
      case SupplierDueFilter.paid:
        displayedDues = allDues.where((d) => d.isFullyPaid).toList();
        break;
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      displayedDues = displayedDues.where((d) {
        return d.companyName.toLowerCase().contains(q) ||
            d.itemsPurchased.toLowerCase().contains(q) ||
            d.notes.toLowerCase().contains(q);
      }).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      drawer: buildAppDrawer(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                iconSize: 24,
                tooltip: 'Back',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () => Navigator.of(context).pop(),
              )
            : buildDrawerHamburgerButton(context),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.domain_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              locale.isBangla ? 'কোম্পানির দেনা' : 'Supplier Dues',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded, size: 22, color: AppColors.textPrimary),
            tooltip: locale.isBangla ? 'কোম্পানির দেনার বিবরণী প্রিন্ট' : 'Print Supplier Dues Statement',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => _showSupplierDuesStatementModal(context, repo, locale),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 28, color: AppColors.primary),
            tooltip: locale.isBangla ? 'নতুন দেনা যোগ করুন' : 'Add Supplier Due',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => AddEditSupplierDueModal.show(context),
          ),
          const SizedBox(width: 4),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: AppColors.border, height: 1),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          locale.isBangla ? '+ নতুন দেনা' : '+ Add Due',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        onPressed: () => AddEditSupplierDueModal.show(context),
      ),
      body: Column(
        children: [
          // 1. 5-Second Undo Bar
          if (repo.lastUndoAction != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ActionConfirmationCard(
                title: repo.lastUndoAction!.title,
                description: repo.lastUndoAction!.description,
                countdownSeconds: repo.undoCountdown,
                onUndo: () => repo.undoLastAction(),
              ),
            ),
          ],

          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                const SizedBox(height: 12),

                // 2. SUMMARY KPI CARD
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
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
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: Color(0xFF38BDF8),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                locale.isBangla
                                    ? 'মোট কোম্পানির দেনা'
                                    : 'TOTAL SUPPLIER DUES',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: totalDue > 0
                                  ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                                  : const Color(0xFF10B981).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: totalDue > 0
                                    ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                                    : const Color(0xFF10B981).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              totalDue > 0
                                  ? (locale.isBangla ? '$pendingCount টি বাকি' : '$pendingCount Pending')
                                  : (locale.isBangla ? 'সব পরিশোধিত' : 'All Settled'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: totalDue > 0 ? const Color(0xFFF59E0B) : const Color(0xFF34D399),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Large Amount Display
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            currency.currentInfo.symbol,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            totalDue.toStringAsFixed(3),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Sub-metrics (Total Paid & Settled count)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    locale.isBangla ? 'পরিশোধিত টাকা' : 'Total Settled',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    currency.format(totalPaid),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF34D399),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 26, color: Colors.white.withValues(alpha: 0.1)),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      locale.isBangla ? 'পরিশোধিত কোম্পানি' : 'Cleared Records',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$settledCount',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. SEARCH BAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: locale.isBangla
                          ? 'কোম্পানির নাম বা পার্টস দিয়ে খুঁজুন...'
                          : 'Search by supplier, oil, or parts...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 4. FILTER TABS (All, Pending, Paid)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: locale.isBangla ? 'সব (${allDues.length})' : 'All (${allDues.length})',
                        filter: SupplierDueFilter.all,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: locale.isBangla ? 'বাকি ($pendingCount)' : 'Pending ($pendingCount)',
                        filter: SupplierDueFilter.pending,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: locale.isBangla ? 'পরিশোধিত ($settledCount)' : 'Paid ($settledCount)',
                        filter: SupplierDueFilter.paid,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // 5. DUES LIST OR EMPTY STATE
                if (displayedDues.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              Icons.domain_verification_rounded,
                              size: 48,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? (locale.isBangla ? 'কোন দেনার রেকর্ড পাওয়া যায়নি' : 'No matching supplier dues')
                                : (locale.isBangla ? 'কোন বকেয়া দেনা নেই' : 'No supplier dues recorded'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _searchQuery.isNotEmpty
                                ? (locale.isBangla ? 'অন্য নাম দিয়ে সন্ধান করুন' : 'Try a different search query')
                                : (locale.isBangla
                                    ? 'তেল, পার্টস বা মালামালের বকেয়া হিসাব রাখতে নতুন দেনা যুক্ত করুন'
                                    : 'Add purchases from companies to track owner debts and settlements'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: Text(
                              locale.isBangla ? 'নতুন দেনা যোগ করুন' : 'Add Supplier Due',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            onPressed: () => AddEditSupplierDueModal.show(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  ...displayedDues.map((due) => SupplierDueCard(key: ValueKey(due.id), due: due)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required SupplierDueFilter filter,
  }) {
    final isSelected = _filter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (_) => setState(() => _filter = filter),
    );
  }

  void _showSupplierDuesStatementModal(
    BuildContext context,
    GarageRepository repo,
    AppLocale locale,
  ) {
    final currency = context.read<CurrencyManager>();
    final dues = repo.supplierDues;
    final totalOutstanding = repo.totalOutstandingSupplierDues;
    final totalContracted = dues.fold<double>(0, (sum, d) => sum + d.totalAmount);
    final totalPaid = dues.fold<double>(0, (sum, d) => sum + d.paidAmount);

    final profile = repo.workshopProfile;
    final workshopName = repo.getWorkshopName();
    final address = profile['address'] ?? '';
    final phone = profile['phone'] ?? '';
    final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final sb = StringBuffer();
    sb.writeln('========================================');
    sb.writeln(workshopName.toUpperCase());
    if (address.isNotEmpty) sb.writeln(address);
    if (phone.isNotEmpty) sb.writeln('Phone: $phone');
    sb.writeln('========================================');
    sb.writeln('SUPPLIER DUES & ACCOUNTS STATEMENT');
    sb.writeln('Generated: $nowStr');
    sb.writeln('Total Suppliers/Dues: ${dues.length}');
    sb.writeln('Total Contracted:     ${currency.format(totalContracted)}');
    sb.writeln('Total Paid:           ${currency.format(totalPaid)}');
    sb.writeln('OUTSTANDING DUE:      ${currency.format(totalOutstanding)}');
    sb.writeln('----------------------------------------');

    if (dues.isEmpty) {
      sb.writeln('No supplier dues recorded.');
    } else {
      for (int i = 0; i < dues.length; i++) {
        final d = dues[i];
        final dDate = DateFormat('dd MMM yyyy').format(d.date);
        sb.writeln('${i + 1}. ${d.companyName} ($dDate)');
        sb.writeln('   Items: ${d.itemsPurchased}');
        sb.writeln('   Total: ${currency.format(d.totalAmount)} | Paid: ${currency.format(d.paidAmount)}');
        if (d.dueAmount > 0) {
          sb.writeln('   Remaining Due: ${currency.format(d.dueAmount)}');
        } else {
          sb.writeln('   Status: FULLY SETTLED');
        }
        sb.writeln('');
      }
    }
    sb.writeln('========================================');
    sb.writeln('End of Supplier Dues Statement');

    final plainText = sb.toString();

    StatementModalHelper.show(
      context: context,
      title: locale.isBangla ? 'কোম্পানির দেনার বিবরণী' : 'Supplier Dues Statement',
      subtitle: '${dues.length} records • Outstanding: ${currency.format(totalOutstanding)}',
      textStatement: plainText,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bento metric header
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale.isBangla ? 'মোট বকেয়া দেনা' : 'Outstanding Due',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.danger),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currency.format(totalOutstanding),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.danger),
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
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale.isBangla ? 'পরিশোধিত জমা' : 'Total Paid',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currency.format(totalPaid),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.success),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            locale.isBangla ? 'কোম্পানিওয়ারি দেনা তালিকা' : 'Company Dues Breakdown',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          if (dues.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: Text(
                locale.isBangla ? 'কোন দেনার রেকর্ড নেই' : 'No supplier due records found',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            ...dues.map((d) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: d.dueAmount > 0
                        ? AppColors.danger.withValues(alpha: 0.3)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.companyName,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary),
                          ),
                          Text(
                            d.itemsPurchased,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          d.dueAmount > 0 ? currency.format(d.dueAmount) : 'PAID',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: d.dueAmount > 0 ? AppColors.danger : AppColors.success,
                          ),
                        ),
                        Text(
                          'Total: ${currency.format(d.totalAmount)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
