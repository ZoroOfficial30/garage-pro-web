import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/currency/currency_manager.dart';
import '../../../core/localization/app_locale.dart';
import '../../../data/models/stock_item.dart';
import '../../../data/repositories/garage_repository.dart';

class AddStockModal {
  static void show(BuildContext context, {required StockItem item}) {
    final repo = Provider.of<GarageRepository>(context, listen: false);
    final currency = Provider.of<CurrencyManager>(context, listen: false);
    final locale = Provider.of<AppLocaleManager>(context, listen: false);

    int quantityToAdd = 5;
    final notesController = TextEditingController(text: 'Restock / New Shipment');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final totalCost = quantityToAdd * item.costPrice;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add_shopping_cart_rounded,
                              color: AppColors.success, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                locale.isBangla
                                    ? 'স্টক বৃদ্ধি / নতুন চালান'
                                    : 'Add Stock (Restock Item)',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                '${item.name} (${item.brand})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Stock Info Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.inventory_2_outlined,
                                  size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                'Current: ${item.quantity} ${item.unit}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ],
                          ),
                          Text(
                            'Sell: ${currency.format(item.sellingPrice)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quantity Stepper
                    Center(
                      child: Column(
                        children: [
                          Text(
                            locale.isBangla
                                ? 'নতুন যোগ করার পরিমাণ'
                                : 'Quantity to Add (${item.unit})',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Minus
                              IconButton(
                                iconSize: 36,
                                onPressed: quantityToAdd > 1
                                    ? () {
                                        setModalState(() => quantityToAdd--);
                                      }
                                    : null,
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: quantityToAdd > 1
                                        ? AppColors.primaryLight
                                        : AppColors.background,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Icon(
                                    Icons.remove,
                                    color: quantityToAdd > 1
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Big Number
                              Container(
                                constraints: const BoxConstraints(minWidth: 80),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppColors.success, width: 2),
                                ),
                                child: Text(
                                  '+$quantityToAdd',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Plus
                              IconButton(
                                iconSize: 36,
                                onPressed: () {
                                  setModalState(() => quantityToAdd++);
                                },
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.successLight,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppColors.success
                                            .withValues(alpha: 0.3)),
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: AppColors.success,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Quick increment pills
                          Wrap(
                            spacing: 8,
                            children: [5, 10, 20, 50].map((inc) {
                              return ActionChip(
                                label: Text('+$inc'),
                                backgroundColor: AppColors.background,
                                labelStyle: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: AppColors.primary,
                                ),
                                onPressed: () {
                                  setModalState(() => quantityToAdd += inc);
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Supplier / Invoice Notes
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Supplier / PO / Invoice Ref',
                        prefixIcon: Icon(Icons.receipt_long_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cost Preview (Owner Only)
                    if (repo.isOwner) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              locale.isBangla
                                  ? 'মোট ক্রয় খরচ:'
                                  : 'Estimated Purchase Outflow:',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              currency.format(totalCost),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Confirm Button (54px)
                    SizedBox(
                      height: 54,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          repo.addStock(
                            itemName: item.name,
                            itemId: item.id,
                            quantity: quantityToAdd,
                            notes: notesController.text.trim(),
                          );
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.check_circle_rounded, size: 20),
                        label: Text(
                          locale.isBangla
                              ? 'স্টক সংরক্ষণ করুন'
                              : 'Confirm Restock (+$quantityToAdd ${item.unit})',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
