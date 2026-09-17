import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/currency/currency_manager.dart';
import '../../../core/localization/app_locale.dart';
import '../../../data/repositories/garage_repository.dart';
import '../../jobs/widgets/new_job_modal.dart';

class QuickActionModals {
  static void showDueModal(
    BuildContext context, {
    String? initialCustomerName,
    String? customerId,
    double? initialAmount,
  }) {
    final repo = Provider.of<GarageRepository>(context, listen: false);
    final locale = Provider.of<AppLocaleManager>(context, listen: false);
    final currency = Provider.of<CurrencyManager>(context, listen: false);

    final nameController = TextEditingController(text: initialCustomerName ?? 'Karim Chowdhury');
    final amountController = TextEditingController(
      text: initialAmount != null && initialAmount > 0
          ? initialAmount.toStringAsFixed(currency.currentInfo.decimalPlaces)
          : '50.000',
    );
    final descController = TextEditingController(text: 'Front Brake Pads & Labor');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_circle_outline, color: AppColors.danger, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    locale.isBangla ? 'কাস্টমারের বাকি যোগ করুন' : 'Add Customer Due (+ Due)',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: locale.translate('customer_name'),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '${locale.translate('amount')} (${currency.currentInfo.symbol})',
                  prefixIcon: const Icon(Icons.monetization_on_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: locale.translate('reason'),
                  prefixIcon: const Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                onPressed: () {
                  final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                  if (nameController.text.trim().isNotEmpty && amt > 0) {
                    repo.addDue(
                      customerName: nameController.text.trim(),
                      customerId: customerId,
                      amount: amt,
                      description: descController.text.trim(),
                    );
                    Navigator.pop(ctx);
                  }
                },
                child: Text(
                  locale.isBangla ? 'বাকি নিশ্চিত করুন' : 'Confirm Due (+ Due)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static void showPayModal(
    BuildContext context, {
    String? initialCustomerName,
    String? customerId,
    double? initialAmount,
  }) {
    final repo = Provider.of<GarageRepository>(context, listen: false);
    final locale = Provider.of<AppLocaleManager>(context, listen: false);
    final currency = Provider.of<CurrencyManager>(context, listen: false);

    final nameController = TextEditingController(text: initialCustomerName ?? 'David Miller');
    final amountController = TextEditingController(
      text: initialAmount != null && initialAmount > 0
          ? initialAmount.toStringAsFixed(currency.currentInfo.decimalPlaces)
          : '100.000',
    );
    String paymentMethod = 'cash';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.payments_outlined, color: AppColors.success, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        locale.isBangla ? 'পেমেন্ট জমা নিন' : 'Collect Payment (– Pay)',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: locale.translate('customer_name'),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: '${locale.translate('amount')} (${currency.currentInfo.symbol})',
                      prefixIcon: const Icon(Icons.attach_money_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Cash'),
                        selected: paymentMethod == 'cash',
                        onSelected: (val) => setModalState(() => paymentMethod = 'cash'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Card / POS'),
                        selected: paymentMethod == 'card',
                        onSelected: (val) => setModalState(() => paymentMethod = 'card'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Bank Transfer'),
                        selected: paymentMethod == 'bank',
                        onSelected: (val) => setModalState(() => paymentMethod = 'bank'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                    onPressed: () {
                      final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                      if (nameController.text.trim().isNotEmpty && amt > 0) {
                        repo.addPayment(
                          customerName: nameController.text.trim(),
                          customerId: customerId,
                          amount: amt,
                          paymentMethod: paymentMethod,
                        );
                        Navigator.pop(ctx);
                      }
                    },
                    child: Text(
                      locale.isBangla ? 'পেমেন্ট রেকর্ড করুন' : 'Record Payment (– Pay)',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static void showStockOutModal(BuildContext context) {
    final repo = Provider.of<GarageRepository>(context, listen: false);
    final locale = Provider.of<AppLocaleManager>(context, listen: false);

    String selectedItem = repo.stockItems.isNotEmpty ? repo.stockItems.first.name : 'Castrol Edge';
    final qtyController = TextEditingController(text: '2');
    String targetBay = 'Bay 1';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        locale.isBangla ? 'স্টক পার্টস আউট' : 'Dispense Part (Stock Out)',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: repo.stockItems.any((s) => s.name == selectedItem)
                        ? selectedItem
                        : (repo.stockItems.isNotEmpty ? repo.stockItems.first.name : null),
                    items: repo.stockItems
                        .map((s) => DropdownMenuItem(
                              value: s.name,
                              child: Text('${s.name} (${s.quantity} ${s.unit})'),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedItem = val);
                    },
                    decoration: const InputDecoration(labelText: 'Select Inventory Part'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                            prefixIcon: Icon(Icons.format_list_numbered),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: targetBay,
                          items: ['Bay 1', 'Bay 2', 'Bay 3', 'Counter Sales']
                              .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => targetBay = val);
                          },
                          decoration: const InputDecoration(labelText: 'Bay Location'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      final qty = int.tryParse(qtyController.text.trim()) ?? 1;
                      repo.dispenseStock(
                        itemName: selectedItem,
                        quantity: qty,
                        targetBay: targetBay,
                      );
                      Navigator.pop(ctx);
                    },
                    child: Text(
                      locale.isBangla ? 'মাল আউট নিশ্চিত করুন' : 'Confirm Stock Out',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static void showExpenseModal(BuildContext context) {
    final repo = Provider.of<GarageRepository>(context, listen: false);
    final locale = Provider.of<AppLocaleManager>(context, listen: false);
    final currency = Provider.of<CurrencyManager>(context, listen: false);

    final titleController = TextEditingController(text: 'Staff Lunch & Tea');
    final amountController = TextEditingController(text: '15.000');
    String selectedCategory = 'Staff Food & Tea';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.warningLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.receipt_long_outlined, color: AppColors.warning, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        locale.isBangla ? 'দৈনিক খরচ লিখুন' : 'Log Workshop Expense',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: locale.translate('reason'),
                      prefixIcon: const Icon(Icons.edit_note_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: '${locale.translate('amount')} (${currency.currentInfo.symbol})',
                      prefixIcon: const Icon(Icons.money_off_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'Staff Food & Tea',
                      'Tools & Gear',
                      'Utilities/Bills',
                      'Shop Consumables',
                      'Rent',
                    ].map((cat) {
                      return ChoiceChip(
                        label: Text(cat),
                        selected: selectedCategory == cat,
                        onSelected: (val) => setModalState(() => selectedCategory = cat),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark),
                    onPressed: () {
                      final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                      if (titleController.text.trim().isNotEmpty && amt > 0) {
                        repo.addExpenseRecord(
                          title: titleController.text.trim(),
                          category: selectedCategory,
                          amount: amt,
                        );
                        Navigator.pop(ctx);
                      }
                    },
                    child: Text(
                      locale.isBangla ? 'খরচ রেকর্ড করুন' : 'Save Expense',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static void showNewJobModal(BuildContext context) {
    NewJobModal.show(context);
  }
}

