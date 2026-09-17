import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/currency/currency_manager.dart';
import '../../../core/localization/app_locale.dart';
import '../../../data/models/stock_item.dart';
import '../../../data/repositories/garage_repository.dart';

class DispenseStockModal {
  static void show(BuildContext context, {required StockItem item}) {
    final repo = Provider.of<GarageRepository>(context, listen: false);
    final currency = Provider.of<CurrencyManager>(context, listen: false);
    final locale = Provider.of<AppLocaleManager>(context, listen: false);

    int quantityToDispense = 1;
    String selectedBay = 'Bay 1';
    String selectedPaymentMethod = 'Cash';

    final available = item.quantity;
    if (available <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} is completely out of stock!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final bays = ['Bay 1', 'Bay 2', 'Bay 3', 'Quick Bay', 'Counter / Walk-in'];
    final paymentMethods = ['Cash', 'Card', 'Bank Transfer'];

    final priceController = TextEditingController(
      text: (1 * item.sellingPrice).toStringAsFixed(currency.currentInfo.decimalPlaces),
    );

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
            final standardAmount = quantityToDispense * item.sellingPrice;
            final enteredPrice = double.tryParse(priceController.text.trim()) ?? standardAmount;
            final isDiscountedOrBargained = (enteredPrice - standardAmount).abs() > 0.001;

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
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.remove_circle_outline_rounded,
                              color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                locale.isBangla
                                    ? 'পার্টস বিক্রি / স্টক আউট'
                                    : 'Sell & Dispense Part',
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
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.inventory_2_outlined,
                                    size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Stock: ${item.quantity} ${item.unit}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Unit: ${currency.format(item.sellingPrice)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
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
                                ? 'পরিমাণ নির্বাচন করুন'
                                : 'Select Quantity (${item.unit})',
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
                                onPressed: quantityToDispense > 1
                                    ? () {
                                        setModalState(() {
                                          quantityToDispense--;
                                          priceController.text = (quantityToDispense * item.sellingPrice)
                                              .toStringAsFixed(currency.currentInfo.decimalPlaces);
                                        });
                                      }
                                    : null,
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: quantityToDispense > 1
                                        ? AppColors.primaryLight
                                        : AppColors.background,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Icon(
                                    Icons.remove,
                                    color: quantityToDispense > 1
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
                                      color: AppColors.primary, width: 2),
                                ),
                                child: Text(
                                  '$quantityToDispense',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Plus
                              IconButton(
                                iconSize: 36,
                                onPressed: quantityToDispense < available
                                    ? () {
                                        setModalState(() {
                                          quantityToDispense++;
                                          priceController.text = (quantityToDispense * item.sellingPrice)
                                              .toStringAsFixed(currency.currentInfo.decimalPlaces);
                                        });
                                      }
                                    : null,
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: quantityToDispense < available
                                        ? AppColors.primaryLight
                                        : AppColors.background,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    color: quantityToDispense < available
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Destination Bay
                    Text(
                      locale.isBangla
                          ? 'গ্যারেজ বে / গন্তব্য নির্বাচন করুন'
                          : 'Assign to Workshop Bay:',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: bays.map((bay) {
                        final isSelected = selectedBay == bay;
                        return ChoiceChip(
                          label: Text(bay),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setModalState(() => selectedBay = bay);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Editable Selling Price (Bargain / Custom Price)
                    Text(
                      locale.isBangla
                          ? 'বিক্রয়মূল্য / আদায়কৃত টাকা (দরদাম পরিবর্তনযোগ্য)'
                          : 'Sale Price / Received Amount (Editable for Bargain):',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Final Selling Price (${currency.currentInfo.symbol})',
                        helperText: '💡 Edit if customer bargained, paid less, or got a discount',
                        helperStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                        prefixIcon: const Icon(Icons.price_change_outlined, color: AppColors.primary),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDiscountedOrBargained ? AppColors.warning : AppColors.border,
                            width: isDiscountedOrBargained ? 1.5 : 1.0,
                          ),
                        ),
                      ),
                      onChanged: (val) {
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(height: 16),

                    // Payment Method Selector
                    Text(
                      locale.isBangla ? 'পেমেন্ট পদ্ধতি' : 'Payment Method:',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: paymentMethods.map((method) {
                        final isSelected = selectedPaymentMethod == method;
                        return ChoiceChip(
                          avatar: Icon(
                            method == 'Cash'
                                ? Icons.money_rounded
                                : (method == 'Card'
                                    ? Icons.credit_card_rounded
                                    : Icons.account_balance_rounded),
                            size: 16,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                          label: Text(method),
                          selected: isSelected,
                          selectedColor: AppColors.success,
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setModalState(() => selectedPaymentMethod = method);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Bill Summary & Income Recording Notice
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDiscountedOrBargained ? const Color(0xFFFEF3C7) : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: isDiscountedOrBargained
                                ? AppColors.warning
                                : AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    locale.isBangla
                                        ? 'ক্যাশবুকে জমা হবে (আয়):'
                                        : 'Recorded as Income in Cashbook:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isDiscountedOrBargained
                                          ? const Color(0xFF92400E)
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  if (isDiscountedOrBargained)
                                    Text(
                                      'Standard: ${currency.format(standardAmount)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                currency.format(enteredPrice),
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: isDiscountedOrBargained
                                      ? const Color(0xFF92400E)
                                      : AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                          if (isDiscountedOrBargained) ...[
                            const SizedBox(height: 6),
                            Text(
                              '✓ Custom bargained price applied ($selectedPaymentMethod)',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Confirm Button (54px)
                    SizedBox(
                      height: 54,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          final parsedPrice = double.tryParse(priceController.text.trim());
                          if (parsedPrice == null || parsedPrice < 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a valid price amount'),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                            return;
                          }

                          repo.dispenseStock(
                            itemName: item.name,
                            itemId: item.id,
                            quantity: quantityToDispense,
                            targetBay: selectedBay,
                            customPrice: parsedPrice,
                            paymentMethod: selectedPaymentMethod,
                          );
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.check_circle_outline_rounded,
                            size: 20),
                        label: Text(
                          locale.isBangla
                              ? 'বিক্রি ও স্টক আউট নিশ্চিত করুন'
                              : 'Confirm Dispense ($quantityToDispense ${item.unit})',
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
    ).whenComplete(() => priceController.dispose());
  }
}
