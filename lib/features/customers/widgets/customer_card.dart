import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/currency/currency_manager.dart';
import '../../../core/localization/app_locale.dart';
import '../../../data/models/customer.dart';
import '../../../data/repositories/garage_repository.dart';
import '../../../shared/utils/communication_helper.dart';

class CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback onCollectPay;
  final VoidCallback onCall;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onDelete;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.onTap,
    required this.onCollectPay,
    required this.onCall,
    this.onWhatsApp,
    this.onDelete,
  });

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'CU';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<GarageRepository>(context, listen: false);
    final currency = Provider.of<CurrencyManager>(context);
    final locale = Provider.of<AppLocaleManager>(context);
    final hasDue = customer.totalDue > 0;
    final isHighOverdue = customer.totalDue >= 1000.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighOverdue
              ? AppColors.danger.withValues(alpha: 0.4)
              : AppColors.border,
          width: isHighOverdue ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isHighOverdue
                ? AppColors.danger.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Avatar, Name + VIP, Due badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar circle
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isHighOverdue
                            ? AppColors.dangerLight
                            : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isHighOverdue
                              ? AppColors.danger.withValues(alpha: 0.3)
                              : AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: customer.avatarBase64 != null && customer.avatarBase64!.isNotEmpty
                            ? Image.memory(
                                base64Decode(customer.avatarBase64!),
                                fit: BoxFit.cover,
                                width: 48,
                                height: 48,
                              )
                            : Center(
                                child: Text(
                                  _getInitials(customer.name),
                                  style: TextStyle(
                                    color: isHighOverdue
                                        ? AppColors.danger
                                        : AppColors.primary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name & Phone
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  customer.name,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                ),
                              ),
                              if (customer.isVip) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFE4E6),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: AppColors.danger.withValues(alpha: 0.3)),
                                  ),
                                  child: const Text(
                                    'VIP',
                                    style: TextStyle(
                                      color: AppColors.danger,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.phone_iphone_rounded,
                                size: 14,
                                color: AppColors.textSecondary.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  customer.phone.isNotEmpty
                                      ? customer.phone
                                      : 'No phone registered',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Due badge
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 105),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 5),
                        decoration: BoxDecoration(
                          color: hasDue
                              ? AppColors.dangerLight
                              : AppColors.successLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: hasDue
                                ? AppColors.danger.withValues(alpha: 0.3)
                                : AppColors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasDue
                                  ? Icons.account_balance_wallet_outlined
                                  : Icons.check_circle_rounded,
                              size: 13,
                              color: hasDue
                                  ? AppColors.danger
                                  : AppColors.success,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  hasDue
                                      ? '${currency.format(customer.totalDue)} DUE'
                                      : '${currency.format(0)} PAID',
                                  style: TextStyle(
                                    color: hasDue
                                        ? AppColors.danger
                                        : AppColors.success,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    // 3-dot options menu
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline_rounded,
                                    size: 18, color: AppColors.textPrimary),
                                const SizedBox(width: 8),
                                Text(
                                  locale.isBangla ? 'প্রোফাইল দেখুন' : 'View Profile',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          if (repo.isOwner)
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_outline_rounded,
                                      size: 18, color: AppColors.danger),
                                  const SizedBox(width: 8),
                                  Text(
                                    locale.isBangla ? 'কাস্টমার ডিলিট' : 'Delete Customer',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.danger,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        onSelected: (val) {
                          if (val == 'view') {
                            onTap();
                          } else if (val == 'delete') {
                            if (onDelete != null) {
                              onDelete!();
                            } else {
                              _showDeleteCustomerDialog(
                                  context, repo, customer, currency, locale);
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Vehicle & Plate info tag (Responsive Wrap)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
                  ),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.directions_car_filled_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              customer.vehicleModel.isNotEmpty
                                  ? customer.vehicleModel
                                  : 'Vehicle Not Set',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (customer.plateNumber.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: AppColors.border, width: 0.8),
                          ),
                          child: Text(
                            customer.plateNumber,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Bottom Buttons row
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.border, width: 0.8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hasDue
                                  ? (isHighOverdue
                                      ? AppColors.danger
                                      : AppColors.primary)
                                  : AppColors.surface,
                              foregroundColor: hasDue
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              elevation: hasDue ? 1 : 0,
                              side: hasDue
                                  ? BorderSide.none
                                  : const BorderSide(
                                      color: AppColors.border, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: onCollectPay,
                            icon: Icon(
                              hasDue
                                  ? Icons.payments_rounded
                                  : Icons.add_circle_outline_rounded,
                              size: 18,
                              color: hasDue ? Colors.white : AppColors.primary,
                            ),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                hasDue
                                    ? locale.translate('collect_pay')
                                    : locale.translate('new_job_bill'),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: hasDue
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // WhatsApp Action Button
                      SizedBox(
                        height: 48,
                        width: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: const Color(0xFFDCFCE7),
                            side: const BorderSide(
                                color: Color(0xFF86EFAC), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            if (onWhatsApp != null) {
                              onWhatsApp!();
                            } else {
                              final formattedDue = currency.format(customer.totalDue);
                              final msg = repo.formatWhatsAppDueMessage(
                                amount: customer.totalDue,
                                formattedAmount: formattedDue,
                              );
                              CommunicationHelper.sendWhatsAppMessage(
                                context,
                                rawPhone: customer.phone,
                                message: msg,
                              );
                            }
                          },
                          child: const Icon(
                            Icons.chat_rounded,
                            color: Color(0xFF16A34A),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Phone Call Button
                      SizedBox(
                        height: 48,
                        width: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: AppColors.surface,
                            side: const BorderSide(
                                color: AppColors.border, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: onCall,
                          child: const Icon(
                            Icons.call_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteCustomerDialog(
    BuildContext context,
    GarageRepository repo,
    Customer customer,
    CurrencyManager currency,
    AppLocaleManager locale,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                locale.isBangla ? 'কাস্টমার ডিলিট করবেন?' : 'Delete Customer?',
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
              locale.isBangla
                  ? 'আপনি কি নিশ্চিত যে "${customer.name}" প্রোফাইলটি ডিলিট করতে চান?'
                  : 'Are you sure you want to delete "${customer.name}"?',
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (customer.totalDue > 0) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        locale.isBangla
                            ? 'সতর্কতা: এই কাস্টমারের ${currency.format(customer.totalDue)} বকেয়া রয়েছে। ডিলিট করলে সকল লেনদেনের হিসাব মুছে যাবে।'
                            : 'Warning: This customer has an outstanding balance of ${currency.format(customer.totalDue)}. Deleting will remove all associated records.',
                        style: const TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              locale.isBangla
                  ? 'ডিলিট করার পর ৫ সেকেন্ডের মধ্যে আনডু করার সুযোগ পাবেন।'
                  : 'You can undo this deletion within 5 seconds after confirming.',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              locale.isBangla ? 'বাতিল' : 'Cancel',
              style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await repo.deleteCustomer(customer.id);
            },
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: Text(
              locale.isBangla ? 'ডিলিট করুন' : 'Delete Customer',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
