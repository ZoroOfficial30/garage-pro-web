import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/currency/currency_manager.dart';
import '../../../core/localization/app_locale.dart';
import '../../../data/models/bay_job.dart';
import '../../../data/repositories/garage_repository.dart';

class SettleJobModal extends StatefulWidget {
  final BayJob job;

  const SettleJobModal({super.key, required this.job});

  static Future<void> show(BuildContext context, BayJob job) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SettleJobModal(job: job),
    );
  }

  @override
  State<SettleJobModal> createState() => _SettleJobModalState();
}

class _SettleJobModalState extends State<SettleJobModal> {
  late TextEditingController _finalBillController;
  late TextEditingController _paidNowController;
  String _paymentMethod = 'Cash';

  final List<String> _methods = ['Cash', 'Bank', 'Card', 'Due'];

  @override
  void initState() {
    super.initState();
    final initialCost = widget.job.estimatedCost > 0 ? widget.job.estimatedCost : 50.0;
    _finalBillController = TextEditingController(text: initialCost.toStringAsFixed(2));
    _paidNowController = TextEditingController(text: initialCost.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _finalBillController.dispose();
    _paidNowController.dispose();
    super.dispose();
  }

  double get _finalBill => double.tryParse(_finalBillController.text.trim()) ?? 0.0;
  double get _paidNow => double.tryParse(_paidNowController.text.trim()) ?? 0.0;
  double get _remainingDue => (_finalBill - _paidNow).clamp(0.0, double.infinity);

  void _onFinalBillChanged(String val) {
    final bill = double.tryParse(val.trim()) ?? 0.0;
    if (_paymentMethod != 'Due') {
      _paidNowController.text = bill.toStringAsFixed(2);
    }
    setState(() {});
  }

  void _onPaidNowChanged(String val) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<GarageRepository>(context, listen: false);
    final locale = Provider.of<AppLocaleManager>(context);
    final currency = Provider.of<CurrencyManager>(context);

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
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.price_check_rounded, color: AppColors.success, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale.isBangla ? 'কাজের বিল নিষ্পত্তি ও ক্লোজ' : 'Complete & Settle Job',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '${widget.job.bayNumber} • ${widget.job.customerName}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
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

            // Service Summary Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.build_circle_outlined, size: 20, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.job.taskDescription,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.job.vehicleModel.isNotEmpty)
                          Text(
                            '${widget.job.vehicleModel}${widget.job.plateNumber.isNotEmpty ? " • ${widget.job.plateNumber}" : ""}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 1. Final Bill Amount (Editable)
            Text(
              locale.isBangla ? 'চূড়ান্ত বিলের পরিমাণ (ডিসকাউন্ট প্রযোজ্য)' : 'Final Bill Amount (Editable for Discounts)',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _finalBillController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: _onFinalBillChanged,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary),
              decoration: InputDecoration(
                prefixText: '${currency.currentInfo.symbol} ',
                prefixStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary),
                prefixIcon: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                helperText: 'Original estimated: ${currency.format(widget.job.estimatedCost)}',
              ),
            ),
            const SizedBox(height: 16),

            // 2. Payment Method Selector
            Text(
              locale.isBangla ? 'পরিশোধের মাধ্যম' : 'Payment Method',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _methods.map((m) {
                final isSelected = _paymentMethod == m;
                return ChoiceChip(
                  label: Text(m),
                  selected: isSelected,
                  selectedColor: AppColors.primaryLight,
                  labelStyle: TextStyle(
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _paymentMethod = m;
                        if (m == 'Due') {
                          _paidNowController.text = '0.00';
                        } else if (_paidNow == 0) {
                          _paidNowController.text = _finalBill.toStringAsFixed(2);
                        }
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 3. Partial Payment Split Inputs
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 1.2),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Amount Paid Now
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              locale.isBangla ? 'এখন পরিশোধ (ক্যাশ)' : 'Amount Paid Now',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success),
                            ),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _paidNowController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: _onPaidNowChanged,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.success),
                              decoration: InputDecoration(
                                isDense: true,
                                prefixText: '${currency.currentInfo.symbol} ',
                                prefixStyle: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.success),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Remaining as Due
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              locale.isBangla ? 'বকেয়া থাকবে (Due)' : 'Remaining as Due',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _remainingDue > 0 ? AppColors.danger : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                color: _remainingDue > 0 ? AppColors.dangerLight : AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _remainingDue > 0
                                      ? AppColors.danger.withValues(alpha: 0.3)
                                      : AppColors.border,
                                ),
                              ),
                              child: Text(
                                currency.format(_remainingDue),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: _remainingDue > 0 ? AppColors.danger : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Preset Quick Buttons
                  Row(
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          setState(() {
                            _paidNowController.text = _finalBill.toStringAsFixed(2);
                          });
                        },
                        child: const Text('100% Paid', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          setState(() {
                            _paidNowController.text = (_finalBill / 2).toStringAsFixed(2);
                          });
                        },
                        child: const Text('50% Split', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          setState(() {
                            _paidNowController.text = '0.00';
                            _paymentMethod = 'Due';
                          });
                        },
                        child: const Text('100% Due', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Settlement Action Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 22),
                label: Text(
                  locale.isBangla ? 'নিষ্পত্তি নিশ্চিত করুন' : 'Confirm Settlement & Close Job',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                onPressed: () async {
                  if (_finalBill <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid bill amount.'),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                    return;
                  }

                  final paid = _paidNow;
                  final due = _remainingDue;

                  Navigator.pop(context);

                  await repo.settleBayJob(
                    jobId: widget.job.id,
                    finalBill: _finalBill,
                    paidNow: paid,
                    remainingDue: due,
                    paymentMethod: _paymentMethod,
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          paid > 0
                              ? 'Job settled! ${currency.format(paid)} recorded in Cashbook${due > 0 ? " • ${currency.format(due)} added to due" : ""}'
                              : 'Job settled! ${currency.format(due)} added to customer due ledger.',
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
}
