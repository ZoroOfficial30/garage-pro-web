import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/currency/currency_manager.dart';
import '../../../data/models/supplier_due.dart';
import '../../../data/repositories/garage_repository.dart';
import 'pay_supplier_due_modal.dart';
import 'add_edit_supplier_due_modal.dart';
import 'supplier_payment_history_modal.dart';
import '../../../shared/widgets/statement_modal_helper.dart';

class SupplierDueCard extends StatelessWidget {
  final SupplierDue due;

  const SupplierDueCard({super.key, required this.due});

  void _showDeleteConfirmation(BuildContext context) {
    final repo = context.read<GarageRepository>();
    final locale = context.read<AppLocale>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: AppColors.danger, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              locale.isBangla ? 'মুছে ফেলার নিশ্চিতকরণ' : 'Delete Supplier Due',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Text(
          locale.isBangla
              ? 'আপনি কি নিশ্চিত যে "${due.companyName}" এর এই দেনার রেকর্ডটি মুছে ফেলতে চান? আপনি পরবর্তী ৫ সেকেন্ডের মধ্যে এটি UNDO করতে পারবেন।'
              : 'Are you sure you want to delete this supplier due record for "${due.companyName}"? You can undo this action within 5 seconds.',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              locale.isBangla ? 'বাতিল' : 'Cancel',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              repo.deleteSupplierDue(due.id);
            },
            child: Text(
              locale.isBangla ? 'মুছে ফেলুন' : 'Delete',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<GarageRepository>();
    final locale = context.watch<AppLocale>();
    final currency = context.watch<CurrencyManager>();

    // Fetch latest instance of due
    final currentDue = repo.supplierDues.firstWhere(
      (d) => d.id == due.id,
      orElse: () => due,
    );

    final dateStr = DateFormat('dd MMM yyyy').format(currentDue.date);
    final progress = (currentDue.totalAmount > 0)
        ? (currentDue.paidAmount / currentDue.totalAmount).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: currentDue.isFullyPaid
              ? AppColors.border
              : (currentDue.isPartiallyPaid
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.warning.withValues(alpha: 0.5)),
          width: currentDue.isFullyPaid ? 1.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER (Avatar, Company Name, Date, Status Badge, More Menu)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: currentDue.isFullyPaid
                        ? AppColors.successLight
                        : (currentDue.isPartiallyPaid
                            ? AppColors.primaryLight
                            : AppColors.warningLight),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: currentDue.isFullyPaid
                          ? AppColors.success.withValues(alpha: 0.3)
                          : (currentDue.isPartiallyPaid
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : AppColors.warning.withValues(alpha: 0.3)),
                    ),
                  ),
                  child: Icon(
                    currentDue.isFullyPaid
                        ? Icons.check_circle_rounded
                        : (currentDue.isPartiallyPaid
                            ? Icons.storefront_rounded
                            : Icons.domain_rounded),
                    color: currentDue.isFullyPaid
                        ? AppColors.success
                        : (currentDue.isPartiallyPaid
                            ? AppColors.primary
                            : AppColors.warning),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Company Name & Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentDue.companyName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 5),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status Badge
                _buildStatusBadge(locale, currentDue, currency),

                // Actions Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textSecondary),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) {
                    if (val == 'statement') {
                      _showSupplierStatementModal(context, repo, currentDue, currency, locale);
                    } else if (val == 'edit') {
                      AddEditSupplierDueModal.show(context, due: currentDue);
                    } else if (val == 'history') {
                      SupplierPaymentHistoryModal.show(context, currentDue);
                    } else if (val == 'delete') {
                      _showDeleteConfirmation(context);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'statement',
                      child: Row(
                        children: [
                          const Icon(Icons.print_outlined, size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Text(locale.isBangla ? 'রসিদ / বিবরণী প্রিন্ট' : 'Print Statement'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 18, color: AppColors.textPrimary),
                          const SizedBox(width: 10),
                          Text(locale.isBangla ? 'সম্পাদনা করুন' : 'Edit Details'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'history',
                      child: Row(
                        children: [
                          const Icon(Icons.history_rounded, size: 18, color: AppColors.textPrimary),
                          const SizedBox(width: 10),
                          Text(locale.isBangla ? 'পেমেন্ট হিস্ট্রি' : 'Payment History'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                          const SizedBox(width: 10),
                          Text(
                            locale.isBangla ? 'মুছে ফেলুন' : 'Delete',
                            style: const TextStyle(color: AppColors.danger),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2. ITEMS PURCHASED CONTAINER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.inventory_2_outlined, size: 15, color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currentDue.itemsPurchased,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3. PAYMENT PROGRESS BAR
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      locale.isBangla ? 'পরিশোধের অগ্রগতি' : 'Payment Progress',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: currentDue.isFullyPaid ? AppColors.success : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      currentDue.isFullyPaid ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 4. FINANCIAL AMOUNTS ROW (Total, Paid, Due)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: currentDue.isFullyPaid
                    ? AppColors.successLight.withValues(alpha: 0.3)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildAmountBlock(
                      label: locale.isBangla ? 'মোট বিল' : 'Total Bill',
                      value: currency.format(currentDue.totalAmount),
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(width: 1, height: 26, color: AppColors.border),
                  Expanded(
                    child: _buildAmountBlock(
                      label: locale.isBangla ? 'পরিশোধিত' : 'Paid',
                      value: currency.format(currentDue.paidAmount),
                      color: AppColors.success,
                    ),
                  ),
                  Container(width: 1, height: 26, color: AppColors.border),
                  Expanded(
                    child: _buildAmountBlock(
                      label: locale.isBangla ? 'বাকি' : 'Remaining Due',
                      value: currency.format(currentDue.dueAmount),
                      color: currentDue.isFullyPaid ? AppColors.success : AppColors.danger,
                      isBold: !currentDue.isFullyPaid,
                    ),
                  ),
                ],
              ),
            ),

            // Notes if any
            if (currentDue.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note_alt_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      currentDue.notes,
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 14),

            // 5. ACTION BUTTONS (Pay Due, History)
            Row(
              children: [
                // History Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    minimumSize: const Size(0, 44),
                  ),
                  icon: const Icon(Icons.history_rounded, size: 16, color: AppColors.textPrimary),
                  label: Text(
                    currentDue.payments.isNotEmpty
                        ? '${locale.isBangla ? 'হিস্ট্রি' : 'History'} (${currentDue.payments.length})'
                        : (locale.isBangla ? 'হিস্ট্রি' : 'History'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  onPressed: () => SupplierPaymentHistoryModal.show(context, currentDue),
                ),

                const SizedBox(width: 10),

                // Pay Due Button (if not fully settled)
                if (!currentDue.isFullyPaid) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        minimumSize: const Size(0, 44),
                      ),
                      icon: const Icon(Icons.payments_rounded, size: 18),
                      label: Text(
                        locale.isBangla ? 'দেনা পরিশোধ করুন' : 'Pay Due',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onPressed: () => PaySupplierDueModal.show(context, currentDue),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified_rounded, size: 16, color: AppColors.success),
                          const SizedBox(width: 6),
                          Text(
                            locale.isBangla ? 'সম্পূর্ণ পরিশোধিত' : 'Fully Settled',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(AppLocale locale, SupplierDue due, CurrencyManager currency) {
    if (due.isFullyPaid) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.successLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              locale.isBangla ? 'পরিশোধিত' : 'PAID',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.success),
            ),
          ],
        ),
      );
    }

    if (due.isPartiallyPaid) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              locale.isBangla
                  ? 'আংশিক বাকি (${currency.format(due.dueAmount)})'
                  : 'PARTIAL (${currency.format(due.dueAmount)})',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            locale.isBangla
                ? 'বাকি (${currency.format(due.dueAmount)})'
                : 'DUE (${currency.format(due.dueAmount)})',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.warning),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountBlock({
    required String label,
    required String value,
    required Color color,
    bool isBold = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showSupplierStatementModal(
    BuildContext context,
    GarageRepository repo,
    SupplierDue d,
    CurrencyManager currency,
    AppLocale locale,
  ) {
    final profile = repo.workshopProfile;
    final workshopName = repo.getWorkshopName();
    final address = profile['address'] ?? '';
    final phone = profile['phone'] ?? '';
    final dateStr = DateFormat('dd MMM yyyy').format(d.date);

    final sb = StringBuffer();
    sb.writeln('========================================');
    sb.writeln(workshopName.toUpperCase());
    if (address.isNotEmpty) sb.writeln(address);
    if (phone.isNotEmpty) sb.writeln('Phone: $phone');
    sb.writeln('========================================');
    sb.writeln('SUPPLIER DUE / PURCHASE MEMO');
    sb.writeln('Date: $dateStr');
    sb.writeln('Company / Supplier: ${d.companyName}');
    sb.writeln('Items Purchased: ${d.itemsPurchased}');
    if (d.notes.isNotEmpty) {
      sb.writeln('Notes: ${d.notes}');
    }
    sb.writeln('----------------------------------------');
    sb.writeln('Total Contracted: ${currency.format(d.totalAmount)}');
    sb.writeln('Paid to Date:     ${currency.format(d.paidAmount)}');
    if (d.dueAmount > 0) {
      sb.writeln('Remaining Due:    ${currency.format(d.dueAmount)}');
    } else {
      sb.writeln('Status:           FULLY SETTLED');
    }
    if (d.payments.isNotEmpty) {
      sb.writeln('----------------------------------------');
      sb.writeln('PAYMENT TRANSACTIONS:');
      for (final p in d.payments) {
        final pDate = DateFormat('dd MMM yyyy, hh:mm a').format(p.date);
        sb.writeln('• $pDate : ${currency.format(p.amount)} (${p.paymentMethod.toUpperCase()})');
        if (p.notes.isNotEmpty) {
          sb.writeln('  Notes: ${p.notes}');
        }
      }
    }
    sb.writeln('========================================');

    final plainText = sb.toString();

    StatementModalHelper.show(
      context: context,
      title: locale.isBangla ? 'সাপ্লায়ার দেনার মেমো' : 'Supplier Due Memo',
      subtitle: '${d.companyName} • ${d.itemsPurchased}',
      textStatement: plainText,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  d.companyName,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
                ),
                Text(
                  dateStr,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
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
                  locale.isBangla ? 'ক্রয়কৃত সামগ্রী:' : 'Items Purchased:',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 3),
                Text(
                  d.itemsPurchased,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                if (d.notes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Notes: ${d.notes}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      locale.isBangla ? 'মোট চুক্তিমূল্য' : 'Total Amount',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                    ),
                    Text(
                      currency.format(d.totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      locale.isBangla ? 'পরিশোধিত' : 'Paid Amount',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.success),
                    ),
                    Text(
                      currency.format(d.paidAmount),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.success),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      locale.isBangla ? 'বকেয়া দেনা' : 'Remaining Due',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.danger),
                    ),
                    Text(
                      currency.format(d.dueAmount),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.danger),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
