import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/currency/currency_manager.dart';
import '../../../core/localization/app_locale.dart';

class ExpenseHeroCard extends StatelessWidget {
  final String period; // 'today', 'week', 'month'
  final double totalExpense;
  final double cashExpense;
  final double digitalExpense;
  final int count;

  const ExpenseHeroCard({
    super.key,
    required this.period,
    required this.totalExpense,
    required this.cashExpense,
    required this.digitalExpense,
    required this.count,
  });

  String _getPeriodLabel(AppLocaleManager locale) {
    if (period == 'today') {
      return locale.isBangla ? 'আজকের মোট খরচ' : 'TOTAL OUTFLOW (TODAY)';
    } else if (period == 'week') {
      return locale.isBangla ? 'চলতি সপ্তাহের খরচ' : 'TOTAL OUTFLOW (THIS WEEK)';
    } else if (period == 'month') {
      return locale.isBangla ? 'চলতি মাসের খরচ' : 'TOTAL OUTFLOW (THIS MONTH)';
    } else {
      return 'TOTAL OUTFLOW (${period.toUpperCase()})';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = Provider.of<CurrencyManager>(context);
    final locale = Provider.of<AppLocaleManager>(context);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          // Large background watermark icon
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              Icons.receipt_long_rounded,
              size: 110,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),

          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getPeriodLabel(locale),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                currency.format(totalExpense),
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),

              // Breakdown divider & stats
              Container(
                padding: const EdgeInsets.only(top: 14),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.payments_rounded,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.9)),
                            const SizedBox(width: 6),
                            Text(
                              locale.isBangla ? 'ক্যাশ / নগদ:' : 'Cash Payment:',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          currency.format(cashExpense),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.credit_card_rounded,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.9)),
                            const SizedBox(width: 6),
                            Text(
                              locale.isBangla ? 'ব্যাংক / কার্ড:' : 'Bank / Card / POS:',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          currency.format(digitalExpense),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$count ${locale.isBangla ? "টি খরচের রসিদ সংরক্ষিত" : "Receipts / Records"}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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
}
