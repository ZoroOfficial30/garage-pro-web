import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/currency/currency_manager.dart';
import '../../../core/localization/app_locale.dart';
import '../../../data/models/stock_item.dart';
import '../../../data/repositories/garage_repository.dart';

class CreateStockItemModal {
  static void show(BuildContext context) {
    final repo = Provider.of<GarageRepository>(context, listen: false);
    final currency = Provider.of<CurrencyManager>(context, listen: false);
    final locale = Provider.of<AppLocaleManager>(context, listen: false);

    final nameController = TextEditingController();
    final skuController = TextEditingController();
    final qtyController = TextEditingController(text: '10');
    final reorderController = TextEditingController(text: '5');
    final costController = TextEditingController();
    final sellController = TextEditingController();

    String selectedBrand = 'Castrol';
    String selectedUnit = 'Pcs';

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

    final units = ['Pcs', 'Qts', 'Sets', 'Liters', 'Gal', 'Bottles', 'Boxes'];

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
                          child: const Icon(Icons.add_box_rounded,
                              color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          locale.isBangla
                              ? 'নতুন পার্ট / স্টক যোগ করুন'
                              : 'Add New Inventory SKU',
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
                            decoration: const InputDecoration(
                              labelText: 'Brand / Manufacturer',
                              prefixIcon: Icon(Icons.verified_outlined),
                            ),
                            items: brands.map((b) {
                              return DropdownMenuItem(value: b, child: Text(b));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => selectedBrand = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedUnit,
                            decoration: const InputDecoration(
                              labelText: 'Unit of Measure',
                              prefixIcon: Icon(Icons.straighten_outlined),
                            ),
                            items: units.map((u) {
                              return DropdownMenuItem(value: u, child: Text(u));
                            }).toList(),
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

                    // SKU
                    TextField(
                      controller: skuController,
                      decoration: const InputDecoration(
                        labelText: 'SKU / Part Code / OEM #',
                        prefixIcon: Icon(Icons.qr_code_2_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Initial Quantity & Reorder Threshold
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: qtyController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Initial Qty in Stock',
                              prefixIcon: Icon(Icons.numbers_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: reorderController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Min Reorder Threshold',
                              prefixIcon: Icon(Icons.warning_amber_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Cost Price & Selling Price
                    Row(
                      children: [
                        if (repo.isOwner) ...[
                          Expanded(
                            child: TextField(
                              controller: costController,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Cost Price (Owner Only)',
                                helperText: '🔒 Hidden from cards',
                                prefixIcon: Icon(Icons.lock_outline_rounded),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: TextField(
                            controller: sellController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              labelText:
                                  'Sell Price (${currency.currentInfo.symbol})',
                              prefixIcon: const Icon(Icons.attach_money_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Save Button (54px)
                    SizedBox(
                      height: 54,
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          final name = nameController.text.trim();
                          if (name.isEmpty) return;

                          final qty = int.tryParse(qtyController.text.trim()) ?? 0;
                          final threshold =
                              int.tryParse(reorderController.text.trim()) ?? 5;
                          final cost =
                              double.tryParse(costController.text.trim()) ?? 0.0;
                          final sell =
                              double.tryParse(sellController.text.trim()) ?? 0.0;

                          String sku = skuController.text.trim();
                          if (sku.isEmpty) {
                            sku = '${selectedBrand.substring(0, 3).toUpperCase()}-${qty}X';
                          }

                          final newItem = StockItem(
                            id: const Uuid().v4(),
                            name: name,
                            brand: selectedBrand,
                            sku: sku,
                            quantity: qty,
                            reorderThreshold: threshold,
                            costPrice: cost,
                            sellingPrice: sell,
                            unit: selectedUnit,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          );

                          repo.createStockItem(newItem);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Item "$name" added to inventory!',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              backgroundColor: AppColors.primaryDark,
                            ),
                          );
                        },
                        child: Text(
                          locale.isBangla
                              ? 'আইটেম সংরক্ষণ করুন'
                              : 'Save Inventory Item',
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
