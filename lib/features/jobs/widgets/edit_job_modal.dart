import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/currency/currency_manager.dart';
import '../../../core/localization/app_locale.dart';
import '../../../data/models/bay_job.dart';
import '../../../data/repositories/garage_repository.dart';

class EditJobModal extends StatefulWidget {
  final BayJob job;

  const EditJobModal({super.key, required this.job});

  static Future<void> show(BuildContext context, BayJob job) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => EditJobModal(job: job),
    );
  }

  @override
  State<EditJobModal> createState() => _EditJobModalState();
}

class _EditJobModalState extends State<EditJobModal> {
  late TextEditingController _taskController;
  late TextEditingController _priceController;
  late TextEditingController _vehicleController;
  late TextEditingController _plateController;
  late TextEditingController _techController;
  late String _selectedBay;

  final List<String> _bayOptions = const [
    'Bay 1',
    'Bay 2',
    'Bay 3',
    'Bay 4',
    'Quick Bay',
  ];

  @override
  void initState() {
    super.initState();
    _taskController = TextEditingController(text: widget.job.taskDescription);
    _priceController = TextEditingController(text: widget.job.estimatedCost.toStringAsFixed(2));
    _vehicleController = TextEditingController(text: widget.job.vehicleModel);
    _plateController = TextEditingController(text: widget.job.plateNumber);
    _techController = TextEditingController(text: widget.job.technicianName);
    _selectedBay = _bayOptions.contains(widget.job.bayNumber)
        ? widget.job.bayNumber
        : _bayOptions.first;
  }

  @override
  void dispose() {
    _taskController.dispose();
    _priceController.dispose();
    _vehicleController.dispose();
    _plateController.dispose();
    _techController.dispose();
    super.dispose();
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
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_note_rounded, color: AppColors.warning, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale.isBangla ? 'কাজের বিবরণ সংশোধন করুন' : 'Edit Job Details',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        'Customer: ${widget.job.customerName}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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

            // Quoted Price (Prominent)
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
              decoration: InputDecoration(
                labelText: locale.isBangla
                    ? 'চুক্তিমূল্য / কোটেড প্রাইজ (${currency.currentInfo.symbol})'
                    : 'Quoted Price (${currency.currentInfo.symbol})',
                prefixIcon: const Icon(Icons.price_change_outlined, color: AppColors.primary),
                helperText: locale.isBangla
                    ? 'গ্রাহকের সাথে দরদামের ভিত্তিতে পরিবর্তন করতে পারবেন'
                    : 'Adjustable based on customer negotiations or discounts',
              ),
            ),
            const SizedBox(height: 14),

            // Service Task
            TextField(
              controller: _taskController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: locale.isBangla ? 'কাজের বিবরণ / সার্ভিস নোট' : 'Service Task Description',
                prefixIcon: const Icon(Icons.engineering_outlined),
              ),
            ),
            const SizedBox(height: 14),

            // Vehicle Model & Plate Number
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _vehicleController,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Model',
                      prefixIcon: Icon(Icons.directions_car_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _plateController,
                    decoration: const InputDecoration(
                      labelText: 'Plate #',
                      prefixIcon: Icon(Icons.pin_outlined),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Bay Assignment & Technician
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedBay,
                    decoration: const InputDecoration(
                      labelText: 'Bay Assignment',
                      prefixIcon: Icon(Icons.garage_outlined),
                    ),
                    items: _bayOptions.map((bay) {
                      return DropdownMenuItem(value: bay, child: Text(bay));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedBay = val);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _techController,
                    decoration: const InputDecoration(
                      labelText: 'Mechanic / Tech',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.save_rounded, size: 20),
                label: Text(
                  locale.isBangla ? 'পরিবর্তন সংরক্ষণ করুন' : 'Save Changes',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                onPressed: () async {
                  final price = double.tryParse(_priceController.text.trim()) ?? widget.job.estimatedCost;
                  final updated = widget.job.copyWith(
                    taskDescription: _taskController.text.trim().isNotEmpty
                        ? _taskController.text.trim()
                        : widget.job.taskDescription,
                    estimatedCost: price,
                    vehicleModel: _vehicleController.text.trim().isNotEmpty
                        ? _vehicleController.text.trim()
                        : widget.job.vehicleModel,
                    plateNumber: _plateController.text.trim(),
                    bayNumber: _selectedBay,
                    technicianName: _techController.text.trim(),
                    updatedAt: DateTime.now(),
                  );
                  await repo.updateBayJob(updated);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(locale.isBangla
                            ? 'কাজের বিবরণ সফলভাবে আপডেট হয়েছে!'
                            : 'Job details updated successfully!'),
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
