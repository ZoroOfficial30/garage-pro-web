import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/currency/currency_manager.dart';
import '../../../core/localization/app_locale.dart';
import '../../../data/models/expense_record.dart';
import '../../../data/repositories/garage_repository.dart';

class AddEditExpenseModal {
  static void show(
    BuildContext context, {
    ExpenseRecord? existingExpense,
    String? initialCategory,
  }) {
    final repo = Provider.of<GarageRepository>(context, listen: false);
    final currency = Provider.of<CurrencyManager>(context, listen: false);
    final locale = Provider.of<AppLocaleManager>(context, listen: false);

    final isEditing = existingExpense != null;

    final titleController =
        TextEditingController(text: existingExpense?.title ?? '');
    final amountController = TextEditingController(
      text: existingExpense != null
          ? existingExpense.amount
              .toStringAsFixed(currency.currentInfo.decimalPlaces)
          : '',
    );
    final notesController =
        TextEditingController(text: existingExpense?.receiptPath ?? '');

    String selectedCategory = existingExpense?.category ??
        (initialCategory ?? 'Tools & Gear');
    String selectedPaymentMethod = existingExpense?.paymentMethod ?? 'Cash';
    DateTime selectedDate = existingExpense?.date ?? DateTime.now();

    final categories = [
      'Tools & Gear',
      'Utilities/Bills',
      'Staff Food & Tea',
      'Workshop Rent',
      'Shop Consumables',
      'Logistics / Other',
    ];

    final paymentMethods = ['Cash', 'Card / POS', 'Bank Transfer'];

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
                            color: AppColors.dangerLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isEditing
                                ? Icons.edit_note_rounded
                                : Icons.receipt_long_rounded,
                            color: AppColors.danger,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isEditing
                              ? (locale.isBangla
                                  ? 'খরচ সম্পাদনা করুন'
                                  : 'Edit Expense Record')
                              : (locale.isBangla
                                  ? 'নতুন খরচ যোগ করুন'
                                  : 'Log Workshop Expense'),
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

                    // Expense Title
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: locale.isBangla
                            ? 'খরচের বিবরণ / কাজের নাম *'
                            : 'Expense Title / Description *',
                        prefixIcon: const Icon(Icons.description_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Amount in OMR
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        labelText:
                            '${locale.translate('amount')} (${currency.currentInfo.symbol}) *',
                        prefixIcon: const Icon(Icons.monetization_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Selector
                    Text(
                      locale.isBangla ? 'খরচের খাত নির্বাচন করুন:' : 'Expense Category:',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((cat) {
                        final isSelected = selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setModalState(() => selectedCategory = cat);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Payment Method Selector
                    Text(
                      locale.isBangla
                          ? 'পরিশোধের মাধ্যম নির্বাচন করুন:'
                          : 'Payment Method:',
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
                          label: Text(method),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setModalState(
                                  () => selectedPaymentMethod = method);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Date Picker Row
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (picked != null) {
                          setModalState(() {
                            selectedDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              selectedDate.hour,
                              selectedDate.minute,
                            );
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Text(
                              'Date: ${DateFormat('dd MMM yyyy').format(selectedDate)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            const Spacer(),
                            const Icon(Icons.edit_calendar_rounded,
                                size: 18, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Optional Notes / Receipt Ref
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Receipt No / Notes (Optional)',
                        prefixIcon: Icon(Icons.tag_rounded),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Save Button (54px)
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
                          final title = titleController.text.trim();
                          final amount =
                              double.tryParse(amountController.text.trim()) ??
                                  0.0;

                          if (title.isEmpty || amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter title and valid amount'),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                            return;
                          }

                          if (isEditing) {
                            final updated = existingExpense.copyWith(
                              title: title,
                              category: selectedCategory,
                              amount: amount,
                              paymentMethod: selectedPaymentMethod,
                              date: selectedDate,
                              receiptPath: notesController.text.trim().isEmpty
                                  ? null
                                  : notesController.text.trim(),
                              updatedAt: DateTime.now(),
                            );
                            repo.updateExpenseRecord(updated);
                          } else {
                            repo.addExpenseRecord(
                              title: title,
                              category: selectedCategory,
                              amount: amount,
                              paymentMethod: selectedPaymentMethod,
                              date: selectedDate,
                              receiptPath: notesController.text.trim().isEmpty
                                  ? null
                                  : notesController.text.trim(),
                            );
                          }

                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.check_circle_rounded, size: 20),
                        label: Text(
                          isEditing
                              ? (locale.isBangla
                                  ? 'আপডেট নিশ্চিত করুন'
                                  : 'Update Expense')
                              : (locale.isBangla
                                  ? 'খরচ সংরক্ষণ করুন'
                                  : 'Save Expense Record'),
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
