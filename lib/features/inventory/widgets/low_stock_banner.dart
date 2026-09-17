import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_locale.dart';
import '../../../data/models/stock_item.dart';
import 'add_stock_modal.dart';

class LowStockBanner extends StatelessWidget {
  final List<StockItem> lowStockItems;

  const LowStockBanner({
    super.key,
    required this.lowStockItems,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<AppLocaleManager>(context);

    if (lowStockItems.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                locale.isBangla
                    ? 'সব পার্টসের পর্যাপ্ত স্টক মজুদ আছে (০ টি সংকটপূর্ণ)'
                    : 'All inventory items are well-stocked (0 critical alerts)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF166534),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: AppColors.danger, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              locale.isBangla
                ? 'জরুরী স্টক এলার্ট (${lowStockItems.length} টি পণ্যে রিঅর্ডার প্রয়োজন)'
                : 'ACTION REQUIRED (${lowStockItems.length} ITEMS LOW / OUT OF STOCK)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: lowStockItems.length,
            separatorBuilder: (_, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = lowStockItems[index];
              final isOutOfStock = item.isOutOfStock;

              return Container(
                width: 290,
                decoration: BoxDecoration(
                  color: isOutOfStock
                      ? const Color(0xFFFFECEC)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isOutOfStock
                        ? AppColors.danger.withValues(alpha: 0.35)
                        : AppColors.warning.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isOutOfStock
                              ? AppColors.danger
                              : AppColors.warning)
                          .withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isOutOfStock
                                ? AppColors.danger
                                : AppColors.warning,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isOutOfStock
                                ? Icons.warning_rounded
                                : Icons.inventory_2_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: isOutOfStock
                                      ? const Color(0xFF93000A)
                                      : const Color(0xFF92400E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isOutOfStock
                                    ? '0 ${item.unit} left (OUT OF STOCK)'
                                    : '${item.quantity} ${item.unit} left (Min req: ${item.reorderThreshold})',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isOutOfStock
                                      ? AppColors.danger
                                      : const Color(0xFFB45309),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isOutOfStock
                              ? AppColors.danger
                              : AppColors.warning,
                          foregroundColor: Colors.white,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () =>
                            AddStockModal.show(context, item: item),
                        icon: const Icon(Icons.add_shopping_cart_rounded,
                            size: 16),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            locale.isBangla
                                ? 'স্টক বৃদ্ধি / রিস্টক'
                                : 'Reorder / Add Stock',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
