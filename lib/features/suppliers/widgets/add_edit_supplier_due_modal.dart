import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/currency/currency_manager.dart';
import '../../../data/models/supplier_due.dart';
import '../../../data/repositories/garage_repository.dart';

class AddEditSupplierDueModal extends StatefulWidget {
  final SupplierDue? due; // null for add mode, non-null for edit mode

  const AddEditSupplierDueModal({super.key, this.due});

  static Future<void> show(BuildContext context, {SupplierDue? due}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditSupplierDueModal(due: due),
    );
  }

  @override
  State<AddEditSupplierDueModal> createState() => _AddEditSupplierDueModalState();
}

class _AddEditSupplierDueModalState extends State<AddEditSupplierDueModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _companyController;
  late final TextEditingController _amountController;
  late final TextEditingController _itemsController;
  late final TextEditingController _notesController;

  late DateTime _selectedDate;
  bool _isSubmitting = false;

  final List<String> _supplierSuggestions = [
    'Castrol Lubricants Oman',
    'Shell Helix Oman',
    'Mann-Filter Middle East',
    'Bosch Auto Parts',
    'Mobil 1 Lubricants',
    'Total Energies Oman',
    'Denso Aftermarket',
    'Bridgestone Tires Oman',
  ];

  final List<String> _itemChips = [
    'Engine Oil',
    'Oil Filters',
    'Brake Pads',
    'Spark Plugs',
    'Air Filters',
    'Tires',
    'Batteries',
    'Paint & Body',
  ];

  @override
  void initState() {
    super.initState();
    final d = widget.due;
    _companyController = TextEditingController(text: d?.companyName ?? '');
    _amountController = TextEditingController(
      text: d != null ? d.totalAmount.toStringAsFixed(3) : '',
    );
    _itemsController = TextEditingController(text: d?.itemsPurchased ?? '');
    _notesController = TextEditingController(text: d?.notes ?? '');
    _selectedDate = d?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _companyController.dispose();
    _amountController.dispose();
    _itemsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _appendItemChip(String chip) {
    final current = _itemsController.text.trim();
    if (current.isEmpty) {
      _itemsController.text = chip;
    } else if (!current.toLowerCase().contains(chip.toLowerCase())) {
      _itemsController.text = '$current, $chip';
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<GarageRepository>();
    final locale = context.watch<AppLocale>();
    final currency = context.watch<CurrencyManager>();
    final isEdit = widget.due != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isEdit ? Icons.edit_note_rounded : Icons.add_shopping_cart_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEdit
                                  ? (locale.isBangla ? 'কোম্পানির দেনা সম্পাদনা' : 'Edit Supplier Due')
                                  : (locale.isBangla ? 'নতুন কোম্পানির দেনা যোগ' : 'Add Supplier Due'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              locale.isBangla
                                  ? 'তেল, পার্টস ও সাপ্লায়ারের বকেয়া হিসাব'
                                  : 'Track payables for oil, filters, parts & materials',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Company Name
                  TextFormField(
                    controller: _companyController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: locale.isBangla ? 'কোম্পানি / সাপ্লায়ারের নাম *' : 'Company / Supplier Name *',
                      hintText: 'e.g. Castrol Lubricants Oman',
                      prefixIcon: const Icon(Icons.domain_rounded, color: AppColors.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return locale.isBangla
                            ? 'কোম্পানির নাম লিখুন'
                            : 'Enter company / supplier name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Quick Company Chips
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _supplierSuggestions.length,
                      separatorBuilder: (ctx, idx) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final name = _supplierSuggestions[index];
                        return ActionChip(
                          label: Text(
                            name,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: AppColors.background,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          onPressed: () {
                            setState(() {
                              _companyController.text = name;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amount Input
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: locale.isBangla ? 'মোট বিলের পরিমাণ *' : 'Total Invoice Amount *',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Text(
                          currency.currentInfo.symbol,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return locale.isBangla
                            ? 'মোট টাকার পরিমাণ দিন'
                            : 'Enter total amount';
                      }
                      final amt = double.tryParse(val.trim());
                      if (amt == null || amt <= 0) {
                        return locale.isBangla
                            ? 'সঠিক পরিমাণ দিন'
                            : 'Enter a valid amount';
                      }
                      if (isEdit && amt < widget.due!.paidAmount - 0.001) {
                        return locale.isBangla
                            ? 'ইতিমধ্যে পরিশোধিত টাকার চেয়ে কম হতে পারবে না (${currency.format(widget.due!.paidAmount)})'
                            : 'Cannot be less than already paid amount (${currency.format(widget.due!.paidAmount)})';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Items Purchased
                  TextFormField(
                    controller: _itemsController,
                    decoration: InputDecoration(
                      labelText: locale.isBangla ? 'কি কি কেনা হয়েছে (তেল, পার্টস ইত্যাদি) *' : 'What Was Purchased *',
                      hintText: 'e.g. 5W-30 Oil, Oil Filters, Spark Plugs',
                      prefixIcon: const Icon(Icons.category_rounded, color: AppColors.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return locale.isBangla
                            ? 'পণ্যের বিবরণ দিন'
                            : 'Enter what items were purchased';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Quick Item Suggestion Chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _itemChips.map((chip) {
                      return ActionChip(
                        label: Text(
                          '+ $chip',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: AppColors.background,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        onPressed: () => _appendItemChip(chip),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Purchase Date Picker
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.textSecondary),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('dd MMMM yyyy').format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Optional Notes
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: locale.isBangla ? 'মন্তব্য / ইনভয়েস নম্বর (ঐচ্ছিক)' : 'Notes / Invoice # (Optional)',
                      hintText: locale.isBangla ? 'যেমন: ইনভয়েস #CAS-9941, ৩০ দিনের বাকি' : 'e.g. Invoice #CAS-9941, 30 days credit term',
                      prefixIcon: const Icon(Icons.notes_rounded, color: AppColors.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              setState(() => _isSubmitting = true);
                              try {
                                final comp = _companyController.text.trim();
                                final amt = double.parse(_amountController.text.trim());
                                final itms = _itemsController.text.trim();
                                final nts = _notesController.text.trim();
                                final nav = Navigator.of(context);

                                if (isEdit) {
                                  final updated = widget.due!.copyWith(
                                    companyName: comp,
                                    totalAmount: amt,
                                    itemsPurchased: itms,
                                    date: _selectedDate,
                                    notes: nts,
                                  );
                                  await repo.updateSupplierDue(updated);
                                } else {
                                  await repo.addSupplierDue(
                                    companyName: comp,
                                    totalAmount: amt,
                                    itemsPurchased: itms,
                                    date: _selectedDate,
                                    notes: nts,
                                  );
                                }
                                nav.pop();
                              } finally {
                                if (mounted) {
                                  setState(() => _isSubmitting = false);
                                }
                              }
                            },
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(isEdit ? Icons.check_rounded : Icons.add_task_rounded, size: 20),
                      label: Text(
                        _isSubmitting
                            ? (locale.isBangla ? 'সংরক্ষণ হচ্ছে...' : 'Saving...')
                            : (isEdit
                                ? (locale.isBangla ? 'আপডেট সম্পন্ন করুন' : 'Update Supplier Due')
                                : (locale.isBangla ? 'কোম্পানির দেনা যুক্ত করুন' : 'Save Supplier Due')),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
