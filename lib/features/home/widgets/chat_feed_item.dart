import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/transaction_record.dart';

class ChatFeedItem extends StatelessWidget {
  final TransactionRecord record;
  final String formattedAmount;
  final String formattedRunningBalance;

  const ChatFeedItem({
    super.key,
    required this.record,
    required this.formattedAmount,
    required this.formattedRunningBalance,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    Color badgeBg;
    IconData badgeIcon;
    String badgeLabel;

    if (record.isPayment) {
      badgeColor = AppColors.success;
      badgeBg = AppColors.successLight;
      badgeIcon = Icons.arrow_downward_rounded;
      badgeLabel = 'PAYMENT RECORDED';
    } else if (record.isDue) {
      badgeColor = AppColors.danger;
      badgeBg = AppColors.dangerLight;
      badgeIcon = Icons.arrow_upward_rounded;
      badgeLabel = 'DUE ADDED';
    } else if (record.isStockOut) {
      badgeColor = AppColors.primary;
      badgeBg = AppColors.primaryLight;
      badgeIcon = Icons.inventory_2_rounded;
      badgeLabel = 'STOCK OUT';
    } else if (record.isCarWash) {
      badgeColor = AppColors.primary;
      badgeBg = AppColors.primaryLight;
      badgeIcon = Icons.local_car_wash_rounded;
      badgeLabel = 'CAR WASH INCOME';
    } else if (record.type == 'service' || record.type == 'income') {
      badgeColor = AppColors.success;
      badgeBg = AppColors.successLight;
      badgeIcon = Icons.payments_rounded;
      badgeLabel = 'DIRECT INCOME';
    } else {
      badgeColor = AppColors.warning;
      badgeBg = AppColors.warningLight;
      badgeIcon = Icons.receipt_long_rounded;
      badgeLabel = 'WORK INVOICE';
    }

    final timeStr = DateFormat('hh:mm a').format(record.date);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Speech Bubble Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
                bottomRight: Radius.circular(14),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: AppColors.border, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.record_voice_over_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '"${record.description}"',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  timeStr,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Processed Transaction Confirmation Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 1.2),
            ),
            child: Row(
              children: [
                Icon(badgeIcon, color: badgeColor, size: 16),
                const SizedBox(width: 6),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          badgeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 85),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            record.isPayment
                                ? '+$formattedAmount'
                                : (record.isDue ? '+$formattedAmount' : formattedAmount),
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (record.runningBalance > 0) ...[
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 105),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Due: $formattedRunningBalance',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

