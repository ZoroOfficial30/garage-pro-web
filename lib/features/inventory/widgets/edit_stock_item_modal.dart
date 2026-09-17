import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/currency/currency_manager.dart';
import '../../../core/localization/app_locale.dart';
import '../../../data/models/stock_item.dart';
import '../../../data/repositories/garage_repository.dart';

class EditStockItemModal {
  static void show(BuildContext context, StockItem item) {
    final repo = Provider.of<GarageRepository>(context, listen: false);
    final currency = Provider.of<CurrencyManager>(context, listen: false);
    final locale = Provider.of<AppLocaleManager>(context, listen: false);

    final nameController = TextEditingController(text: item.name);
    final skuController = TextEditingController(text: item.sku);
    final qtyController = TextEditingController(text: item.quantity.toString());
    final reorderController = TextEditingController(text: item.reorderThreshold.toString());
    final costController = TextEditingController(text: item.costPrice.toStringAsFixed(2));
    final sellController = TextEditingController(text: item.sellingPrice.toStringAsFixed(2));

    final brands = [
      'Castrol',
      'Mobil',
      'Bosch',
      'Denso',
      'Toyota OEM',
      'NGK',
      'Liqui Moly',
      'Other'
    ];

    String selectedBrand = brands.contains(item.brand) ? item.brand : 'Other';
    final units = ['Pcs', 'Qts', 'Sets', 'Liters', 'Gal', 'Bottles', 'Boxes'];
    String selectedUnit = units.contains(item.unit) ? item.unit : 'Pcs';

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
                          child: const Icon(Icons.edit_note_rounded,
                              color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          locale.isBangla
                              ? 'স্টক আইটেম সম্পাদন'
                              : 'Edit Stock Item',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Part Name
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Part Name / Description *',
                        prefixIcon: Icon(Icons.inventory_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Brand Dropdown & Unit Dropdown
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedBrand,
                            decoration: const InputDecoration(labelText: 'Brand / OEM'),
                            items: brands
                                .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => selectedBrand = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedUnit,
                            decoration: const InputDecoration(labelText: 'Unit'),
                            items: units
                                .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => selectedUnit = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // SKU Code
                    TextField(
                      controller: skuController,
                      decoration: const InputDecoration(
                        labelText: 'SKU / Barcode *',
                        prefixIcon: Icon(Icons.qr_code_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Stock Quantity & Reorder Threshold
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: qtyController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Current Qty *',
                              prefixIcon: Icon(Icons.numbers_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: reorderController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Min Threshold',
                              prefixIcon: Icon(Icons.warning_amber_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Pricing: Buy Price & Sell Price
                    Row(
                      children: [
                        if (repo.isOwner) ...[
                          Expanded(
                            child: TextField(
                              controller: costController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Cost Price (Owner Only) *',
                                helperText: '🔒 Hidden from cards',
                                prefixIcon: Icon(Icons.lock_outline_rounded),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: TextField(
                            controller: sellController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Sell Price (${currency.currentInfo.symbol}) *',
                              prefixIcon: const Icon(Icons.attach_money_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final sku = skuController.text.trim();
                          final qty = int.tryParse(qtyController.text.trim()) ?? 0;
                          final threshold = int.tryParse(reorderController.text.trim()) ?? 5;
                          final cost = repo.isOwner
                              ? (double.tryParse(costController.text.trim()) ?? item.costPrice)
                              : item.costPrice;
                          final sell = double.tryParse(sellController.text.trim()) ?? 0.0;

                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter item name')),
                            );
                            return;
                          }

                          final updated = item.copyWith(
                            name: name,
                            brand: selectedBrand,
                            sku: sku.isNotEmpty ? sku : item.sku,
                            quantity: qty,
                            reorderThreshold: threshold,
                            costPrice: cost,
                            sellingPrice: sell,
                            unit: selectedUnit,
                            updatedAt: DateTime.now(),
                          );

                          await repo.updateStockItem(updated);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Updated item: $name'),
                                backgroundColor: AppColors.primaryDark,
                              ),
                            );
                          }
                        },
                        child: Text(
                          locale.isBangla ? 'পরিবর্তন সংরক্ষণ করুন' : 'Save Changes',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
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
