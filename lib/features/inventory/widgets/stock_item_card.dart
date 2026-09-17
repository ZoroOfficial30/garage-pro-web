import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/currency/currency_manager.dart';
import '../../../core/localization/app_locale.dart';
import '../../../data/models/stock_item.dart';

class StockItemCard extends StatelessWidget {
  final StockItem item;
  final VoidCallback onDispense;
  final VoidCallback onAddStock;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const StockItemCard({
    super.key,
    required this.item,
    required this.onDispense,
    required this.onAddStock,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final currency = Provider.of<CurrencyManager>(context);
    final locale = Provider.of<AppLocaleManager>(context);

    final isOutOfStock = item.isOutOfStock;
    final isLowStock = item.isLowStock;

    // Color tokens for stock status
    final Color badgeBg;
    final Color badgeText;
    final Color dotColor;
    final String statusLabel;

    if (isOutOfStock) {
      badgeBg = const Color(0xFFFFDAD6);
      badgeText = const Color(0xFF93000A);
      dotColor = AppColors.danger;
      statusLabel = '0 ${item.unit} OUT OF STOCK';
    } else if (isLowStock) {
      badgeBg = const Color(0xFFFEF3C7);
      badgeText = const Color(0xFF92400E);
      dotColor = AppColors.warning;
      statusLabel = '${item.quantity} ${item.unit} LOW STOCK';
    } else {
      badgeBg = const Color(0xFFDCFCE7);
      badgeText = const Color(0xFF166534);
      dotColor = AppColors.success;
      statusLabel = '${item.quantity} ${item.unit} IN STOCK';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOutOfStock
              ? AppColors.danger.withValues(alpha: 0.35)
              : (isLowStock
                  ? AppColors.warning.withValues(alpha: 0.35)
                  : AppColors.border),
          width: (isOutOfStock || isLowStock) ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isOutOfStock
                ? AppColors.danger.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Status badge & SKU & Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: dotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  color: badgeText,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                item.sku,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (onEdit != null || onDelete != null) ...[
                            const SizedBox(width: 4),
                            PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert,
                                size: 20, color: AppColors.textSecondary),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            onSelected: (val) {
                              if (val == 'edit') {
                                onEdit?.call();
                              } else if (val == 'delete') {
                                onDelete?.call();
                              }
                            },
                            itemBuilder: (context) => [
                              if (onEdit != null)
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.edit_outlined,
                                          size: 18, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Text(
                                          locale.isBangla
                                              ? 'সম্পাদন'
                                              : 'Edit Item',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                              if (onDelete != null)
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.delete_outline_rounded,
                                          size: 18, color: AppColors.danger),
                                      const SizedBox(width: 8),
                                      Text(
                                          locale.isBangla
                                              ? 'মুছে ফেলুন'
                                              : 'Delete Item',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: AppColors.danger)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
                const SizedBox(height: 12),

                // Item Name (Max 3 lines, soft wrap)
                Text(
                  item.name,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
                const SizedBox(height: 8),

                // Brand & Threshold row (Responsive Wrap)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.brand,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Text(
                      'Min Threshold: ${item.reorderThreshold} ${item.unit}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Price and Quantity Row (2 Columns: Sell Price and Available Stock only)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      // Sell Price
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SELL / RETAIL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                currency.format(item.sellingPrice),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 28,
                        width: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        color: AppColors.border,
                      ),
                      // Quantity Number
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'IN STOCK',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${item.quantity} ${item.unit}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: isOutOfStock
                                      ? AppColors.danger
                                      : (isLowStock
                                          ? AppColors.warning
                                          : AppColors.success),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Buttons (52px split buttons)
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: Row(
              children: [
                // Dispense Button
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: Material(
                      color: isOutOfStock
                          ? AppColors.surface
                          : AppColors.surface,
                      borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16)),
                      child: InkWell(
                        borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16)),
                        onTap: isOutOfStock ? null : onDispense,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.remove_circle_outline_rounded,
                                size: 18,
                                color: isOutOfStock
                                    ? AppColors.textSecondary
                                        .withValues(alpha: 0.4)
                                    : AppColors.textPrimary,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    locale.isBangla
                                        ? 'ব্যবহার / আউট'
                                        : '– Dispense',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: isOutOfStock
                                          ? AppColors.textSecondary
                                              .withValues(alpha: 0.4)
                                          : AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 52,
                  color: AppColors.border,
                ),
                // Add Stock Button
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: Material(
                      color: isOutOfStock
                          ? AppColors.primary
                          : AppColors.primaryLight,
                      borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(16)),
                      child: InkWell(
                        borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(16)),
                        onTap: onAddStock,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_shopping_cart_rounded,
                                size: 18,
                                color: isOutOfStock
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    locale.isBangla ? '+ স্টক যোগ' : '+ Add Stock',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: isOutOfStock
                                          ? Colors.white
                                          : AppColors.primary,
                                    ),
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
