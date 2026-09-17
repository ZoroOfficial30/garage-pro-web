import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/currency/currency_manager.dart';
import '../../../core/localization/app_locale.dart';
import '../../../data/repositories/garage_repository.dart';

class RecordIncomeModal extends StatefulWidget {
  final String? initialCategory;

  const RecordIncomeModal({
    super.key,
    this.initialCategory,
  });

  static Future<void> show(BuildContext context, {String? category}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => RecordIncomeModal(initialCategory: category),
    );
  }

  @override
  State<RecordIncomeModal> createState() => _RecordIncomeModalState();
}

class _RecordIncomeModalState extends State<RecordIncomeModal> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();
  String _category = 'Car Wash';
  String _paymentMethod = 'cash';

  final List<Map<String, dynamic>> _quickPresets = [
    {
      'label': 'Express Body Wash',
      'category': 'Car Wash',
      'amount': '1.500',
      'desc': 'Express Exterior Car Wash',
    },
    {
      'label': 'Full Wash & Vacuum',
      'category': 'Car Wash',
      'amount': '3.000',
      'desc': 'Full Exterior Wash + Interior Vacuum',
    },
    {
      'label': 'Deep Polish & Wash',
      'category': 'Car Wash',
      'amount': '6.000',
      'desc': 'Deep Foam Wash, Wax & Polish',
    },
    {
      'label': 'Oil Change Service',
      'category': 'Service',
      'amount': '4.000',
      'desc': 'Oil & Filter Replacement Labor',
    },
    {
      'label': 'Tire Pressure & Puncture',
      'category': 'Service',
      'amount': '1.000',
      'desc': 'Tire Puncture Repair & Pressure Calibration',
    },
    {
      'label': 'AC Gas Top-up',
      'category': 'Service',
      'amount': '8.000',
      'desc': 'R134a AC Refrigerant Refill',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _category = widget.initialCategory!;
    }
    _customerCtrl.text = 'Walk-in Customer';
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _customerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<GarageRepository>(context, listen: false);
    final currency = Provider.of<CurrencyManager>(context);
    final locale = Provider.of<AppLocaleManager>(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modal Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_car_wash_rounded,
                    color: AppColors.success,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale.isBangla
                            ? 'দৈনিক আয় / কার ওয়াশ রেকর্ড'
                            : 'Log Daily Income / Car Wash',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Instant direct revenue entry',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quick Service Presets Chips
            const Text(
              'Quick Service Presets',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickPresets.map((preset) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      backgroundColor: AppColors.primaryLight.withValues(alpha: 0.5),
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                      label: Text(
                        '${preset['label']} (${currency.symbol} ${preset['amount']})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _category = preset['category'];
                          _amountCtrl.text = preset['amount'];
                          _descCtrl.text = preset['desc'];
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Category Selection
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildCategoryOption('Car Wash', Icons.local_car_wash_outlined),
                const SizedBox(width: 8),
                _buildCategoryOption('Service', Icons.build_circle_outlined),
                const SizedBox(width: 8),
                _buildCategoryOption('Other Income', Icons.attach_money_rounded),
              ],
            ),
            const SizedBox(height: 16),

            // Amount Input (Highlighted)
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.success,
              ),
              decoration: InputDecoration(
                labelText: 'Amount Received',
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    currency.symbol,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 0),
                hintText: '0.000',
              ),
            ),
            const SizedBox(height: 12),

            // Description Input
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description / Job Summary',
                hintText: 'e.g., Toyota Camry Full Foam Wash',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 12),

            // Customer / Vehicle Info (Optional)
            TextField(
              controller: _customerCtrl,
              decoration: const InputDecoration(
                labelText: 'Customer / Vehicle Plate (Optional)',
                hintText: 'e.g., Walk-in / Plate 4912-B',
                prefixIcon: Icon(Icons.directions_car_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Payment Method Selector
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildPaymentMethodOption('cash', 'Cash', Icons.money_rounded),
                const SizedBox(width: 8),
                _buildPaymentMethodOption('card', 'Card / POS', Icons.credit_card_rounded),
                const SizedBox(width: 8),
                _buildPaymentMethodOption('bank', 'Online / Bank', Icons.account_balance_rounded),
              ],
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 22),
                label: Text(
                  locale.isBangla ? 'আয় সংরক্ষণ করুন' : 'Confirm & Save Income',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                onPressed: () async {
                  final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
                  if (amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid amount greater than 0'),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                    return;
                  }

                  final desc = _descCtrl.text.trim().isNotEmpty
                      ? _descCtrl.text.trim()
                      : '$_category payment';
                  final customer = _customerCtrl.text.trim().isNotEmpty
                      ? _customerCtrl.text.trim()
                      : 'Walk-in Customer';

                  await repo.recordIncome(
                    category: _category,
                    amount: amount,
                    description: desc,
                    customerName: customer,
                    paymentMethod: _paymentMethod,
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Logged ${currency.format(amount)} income ($desc)',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryOption(String label, IconData icon) {
    final isSelected = _category == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _category = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption(String value, String label, IconData icon) {
    final isSelected = _paymentMethod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentMethod = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
