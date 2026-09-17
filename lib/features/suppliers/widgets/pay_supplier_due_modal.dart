import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/currency/currency_manager.dart';
import '../../../data/models/supplier_due.dart';
import '../../../data/repositories/garage_repository.dart';

class PaySupplierDueModal extends StatefulWidget {
  final SupplierDue due;

  const PaySupplierDueModal({super.key, required this.due});

  static Future<void> show(BuildContext context, SupplierDue due) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaySupplierDueModal(due: due),
    );
  }

  @override
  State<PaySupplierDueModal> createState() => _PaySupplierDueModalState();
}

class _PaySupplierDueModalState extends State<PaySupplierDueModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  final TextEditingController _notesController = TextEditingController();

  String _paymentMethod = 'Cash';
  late DateTime _paymentDate;
  bool _isSubmitting = false;

  final List<String> _paymentMethods = [
    'Cash',
    'Bank Transfer',
    'Cheque',
    'Card',
  ];

  @override
  void initState() {
    super.initState();
    _paymentDate = DateTime.now();
    // Default amount to full remaining due
    _amountController = TextEditingController(
      text: widget.due.dueAmount.toStringAsFixed(3),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _setPresetAmount(double amount) {
    setState(() {
      _amountController.text = amount.toStringAsFixed(3);
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<GarageRepository>();
    final locale = context.watch<AppLocale>();
    final currency = context.watch<CurrencyManager>();
    final currentDue = repo.supplierDues.firstWhere(
      (d) => d.id == widget.due.id,
      orElse: () => widget.due,
    );

    final enteredAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final remainingAfterPayment = (currentDue.dueAmount - enteredAmount).clamp(0.0, double.infinity);

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
                  // Drag Handle
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
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.payments_rounded,
                          color: AppColors.success,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              locale.isBangla ? 'কোম্পানির দেনা পরিশোধ' : 'Pay Supplier Due',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              currentDue.companyName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                  const SizedBox(height: 16),

                  // Balance Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricColumn(
                          label: locale.isBangla ? 'মোট বিল' : 'Total Bill',
                          value: currency.format(currentDue.totalAmount),
                          color: AppColors.textPrimary,
                        ),
                        Container(width: 1, height: 32, color: AppColors.border),
                        _buildMetricColumn(
                          label: locale.isBangla ? 'পরিশোধিত' : 'Paid',
                          value: currency.format(currentDue.paidAmount),
                          color: AppColors.success,
                        ),
                        Container(width: 1, height: 32, color: AppColors.border),
                        _buildMetricColumn(
                          label: locale.isBangla ? 'বর্তমান বকেয়া' : 'Current Due',
                          value: currency.format(currentDue.dueAmount),
                          color: AppColors.danger,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quick Amount Presets
                  Text(
                    locale.isBangla ? 'টাকার পরিমাণ নির্বাচন করুন' : 'Select Payment Amount',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: (enteredAmount - currentDue.dueAmount).abs() < 0.001
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: (enteredAmount - currentDue.dueAmount).abs() < 0.001 ? 2 : 1,
                            ),
                            backgroundColor: (enteredAmount - currentDue.dueAmount).abs() < 0.001
                                ? AppColors.primaryLight
                                : Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () => _setPresetAmount(currentDue.dueAmount),
                          child: Text(
                            locale.isBangla
                                ? 'সম্পূর্ণ (${currency.format(currentDue.dueAmount)})'
                                : 'Full (${currency.format(currentDue.dueAmount)})',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: (enteredAmount - currentDue.dueAmount).abs() < 0.001
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: (enteredAmount - (currentDue.dueAmount / 2)).abs() < 0.01
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: (enteredAmount - (currentDue.dueAmount / 2)).abs() < 0.01 ? 2 : 1,
                            ),
                            backgroundColor: (enteredAmount - (currentDue.dueAmount / 2)).abs() < 0.01
                                ? AppColors.primaryLight
                                : Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () => _setPresetAmount(currentDue.dueAmount / 2),
                          child: Text(
                            locale.isBangla
                                ? '৫০% (${currency.format(currentDue.dueAmount / 2)})'
                                : '50% (${currency.format(currentDue.dueAmount / 2)})',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: (enteredAmount - (currentDue.dueAmount / 2)).abs() < 0.01
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Amount Input Field
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: locale.isBangla ? 'পরিশোধের পরিমাণ' : 'Payment Amount',
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
                    onChanged: (_) => setState(() {}),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return locale.isBangla
                            ? 'অনুগ্রহ করে পরিমাণ দিন'
                            : 'Please enter payment amount';
                      }
                      final amt = double.tryParse(val.trim());
                      if (amt == null || amt <= 0) {
                        return locale.isBangla
                            ? 'সঠিক পরিমাণ দিন'
                            : 'Enter a valid amount';
                      }
                      if (amt > currentDue.dueAmount + 0.001) {
                        return locale.isBangla
                            ? 'বকেয়া পরিমাণের চেয়ে বেশি হতে পারবে না'
                            : 'Cannot exceed due balance (${currency.format(currentDue.dueAmount)})';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Payment Method Selector
                  Text(
                    locale.isBangla ? 'পরিশোধের মাধ্যম' : 'Payment Method',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _paymentMethods.map((m) {
                      final selected = _paymentMethod == m;
                      return ChoiceChip(
                        label: Text(m),
                        selected: selected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.background,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppColors.textPrimary,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: selected ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        onSelected: (_) => setState(() => _paymentMethod = m),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Payment Date Picker
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _paymentDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (picked != null) {
                        setState(() => _paymentDate = picked);
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
                            DateFormat('dd MMMM yyyy').format(_paymentDate),
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

                  // Notes input
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: locale.isBangla ? 'মন্তব্য / চেক নম্বর (ঐচ্ছিক)' : 'Notes / Cheque # (Optional)',
                      hintText: locale.isBangla ? 'যেমন: চেক #৪৫৯১, ইনভয়েস পরিশোধ' : 'e.g. Cheque #4591, Invoice partial',
                      prefixIcon: const Icon(Icons.note_alt_outlined, color: AppColors.textSecondary),
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
                  const SizedBox(height: 16),

                  // Real-time Preview Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              locale.isBangla ? 'পরিশোধের পর অবশিষ্ট বকেয়া:' : 'Remaining Due After Payment:',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              currency.format(remainingAfterPayment),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: remainingAfterPayment <= 0.001
                                    ? AppColors.success
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                locale.isBangla
                                    ? 'ক্যাশবুকে এটি "Supplier Payment" হিসেবে খরচ রেকর্ড হবে।'
                                    : 'This payment will be recorded in Cashbook under "Supplier Payment".',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Confirm Payment Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
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
                                final amt = double.parse(_amountController.text.trim());
                                final nav = Navigator.of(context);
                                await repo.recordSupplierPayment(
                                  dueId: currentDue.id,
                                  amount: amt,
                                  paymentMethod: _paymentMethod,
                                  date: _paymentDate,
                                  notes: _notesController.text.trim(),
                                );
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
                          : const Icon(Icons.check_circle_rounded, size: 20),
                      label: Text(
                        _isSubmitting
                            ? (locale.isBangla ? 'রেকর্ড হচ্ছে...' : 'Recording...')
                            : (locale.isBangla
                                ? 'পরিশোধ নিশ্চিত করুন (${currency.format(enteredAmount)})'
                                : 'Confirm Payment (${currency.format(enteredAmount)})'),
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

  Widget _buildMetricColumn({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
