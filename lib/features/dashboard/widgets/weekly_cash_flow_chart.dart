import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/currency/currency_manager.dart';
import '../../../data/repositories/garage_repository.dart';

class WeeklyCashFlowChart extends StatefulWidget {
  final List<DailyCashFlow> cashFlowData;
  final double weekInflow;
  final CurrencyManager currency;

  const WeeklyCashFlowChart({
    super.key,
    required this.cashFlowData,
    required this.weekInflow,
    required this.currency,
  });

  @override
  State<WeeklyCashFlowChart> createState() => _WeeklyCashFlowChartState();
}

class _WeeklyCashFlowChartState extends State<WeeklyCashFlowChart> {
  int? _selectedDayIndex;

  @override
  Widget build(BuildContext context) {
    // Find max value for normalization
    double maxVal = 100.0;
    for (final day in widget.cashFlowData) {
      if (day.income > maxVal) maxVal = day.income;
      if (day.expense > maxVal) maxVal = day.expense;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Weekly Cash Flow',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Last 7 Days (Income vs Expense)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'TOTAL INFLOW',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.currency.format(widget.weekInflow),
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
          const SizedBox(height: 24),

          // Chart area
          SizedBox(
            height: 160,
            child: Stack(
              children: [
                // Horizontal grid lines
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    4,
                    (index) => const Divider(
                      height: 1,
                      color: Color(0xFFE2E8F0),
                    ),
                  ),
                ),

                // Bars row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(widget.cashFlowData.length, (index) {
                    final day = widget.cashFlowData[index];
                    final isSelected = _selectedDayIndex == index;

                    // Height ratios
                    final incomeRatio = (day.income / maxVal).clamp(0.06, 1.0);
                    final expenseRatio = (day.expense / maxVal).clamp(0.06, 1.0);

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDayIndex = isSelected ? null : index;
                          });
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Bars
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Income bar
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: 12,
                                    height: 130 * incomeRatio,
                                    decoration: BoxDecoration(
                                      color: day.income > 0
                                          ? AppColors.primary
                                          : AppColors.primary.withValues(alpha: 0.15),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  // Expense bar
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: 12,
                                    height: 130 * expenseRatio,
                                    decoration: BoxDecoration(
                                      color: day.expense > 0
                                          ? AppColors.danger
                                          : AppColors.danger.withValues(alpha: 0.15),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Day label
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: day.isToday
                                    ? AppColors.primaryLight
                                    : (isSelected ? Colors.grey.shade200 : Colors.transparent),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                day.dayLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: day.isToday ? FontWeight.w900 : FontWeight.w600,
                                  color: day.isToday
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // Selected day inspection detail
          if (_selectedDayIndex != null &&
              _selectedDayIndex! < widget.cashFlowData.length) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${widget.cashFlowData[_selectedDayIndex!].dayLabel} Details:',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  Row(
                    children: [
                      Text(
                        'In: ${widget.currency.format(widget.cashFlowData[_selectedDayIndex!].income)}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Out: ${widget.currency.format(widget.cashFlowData[_selectedDayIndex!].expense)}',
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Income',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Expense',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
