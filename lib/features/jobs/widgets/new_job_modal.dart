import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/currency/currency_manager.dart';
import '../../../core/localization/app_locale.dart';
import '../../../data/models/bay_job.dart';
import '../../../data/models/customer.dart';
import '../../../data/repositories/garage_repository.dart';

class NewJobModal extends StatefulWidget {
  const NewJobModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const NewJobModal(),
    );
  }

  @override
  State<NewJobModal> createState() => _NewJobModalState();
}

class _NewJobModalState extends State<NewJobModal> {
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _vehicleController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _costController = TextEditingController(text: '45.00');
  final TextEditingController _techController = TextEditingController();

  Customer? _selectedCustomer;
  bool _showSuggestions = false;
  String _selectedBay = 'Bay 1';

  final List<String> _bayOptions = const [
    'Bay 1',
    'Bay 2',
    'Bay 3',
    'Bay 4',
    'Quick Bay',
  ];

  @override
  void dispose() {
    _customerController.dispose();
    _phoneController.dispose();
    _vehicleController.dispose();
    _plateController.dispose();
    _taskController.dispose();
    _costController.dispose();
    _techController.dispose();
    super.dispose();
  }

  void _onCustomerSelected(Customer customer) {
    setState(() {
      _selectedCustomer = customer;
      _customerController.text = customer.name;
      if (customer.phone.isNotEmpty) _phoneController.text = customer.phone;
      if (customer.vehicleModel.isNotEmpty) _vehicleController.text = customer.vehicleModel;
      if (customer.plateNumber.isNotEmpty) _plateController.text = customer.plateNumber;
      _showSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<GarageRepository>(context);
    final locale = Provider.of<AppLocaleManager>(context);
    final currency = Provider.of<CurrencyManager>(context);

    final query = _customerController.text.trim().toLowerCase();
    final matchingCustomers = query.isEmpty
        ? <Customer>[]
        : repo.customers.where((c) {
            return c.name.toLowerCase().contains(query) ||
                c.phone.contains(query) ||
                c.plateNumber.toLowerCase().contains(query);
          }).take(4).toList();

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
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.car_repair_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    locale.isBangla ? 'নতুন কাজের অর্ডার (New Job)' : 'Open New Work Order',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. Customer Autocomplete Search
            Text(
              locale.translate('customer_name'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _customerController,
              onChanged: (val) {
                setState(() {
                  _showSuggestions = true;
                  if (_selectedCustomer != null && _selectedCustomer!.name != val) {
                    _selectedCustomer = null;
                  }
                });
              },
              decoration: InputDecoration(
                hintText: locale.isBangla ? 'গ্রাহকের নাম বা ফোন দিয়ে খুঁজুন...' : 'Search customer or enter new name...',
                prefixIcon: const Icon(Icons.person_search_rounded, color: AppColors.primary),
                suffixIcon: _selectedCustomer != null
                    ? Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'EXISTING',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.success),
                        ),
                      )
                    : null,
              ),
            ),

            // Autocomplete Results Dropdown
            if (_showSuggestions && matchingCustomers.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: matchingCustomers.map((c) {
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                      ),
                      title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        '${c.phone}${c.vehicleModel.isNotEmpty ? " • ${c.vehicleModel}" : ""}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: c.totalDue > 0
                          ? Text(
                              'Due: ${currency.format(c.totalDue)}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.danger),
                            )
                          : null,
                      onTap: () => _onCustomerSelected(c),
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // 2. Phone Number
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: locale.translate('phone'),
                hintText: '+968 9123 4567',
                prefixIcon: const Icon(Icons.phone_rounded),
              ),
            ),
            const SizedBox(height: 12),

            // 3. Vehicle Model & Plate
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _vehicleController,
                    decoration: InputDecoration(
                      labelText: locale.translate('vehicle_model'),
                      hintText: 'Toyota Corolla',
                      prefixIcon: const Icon(Icons.directions_car_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _plateController,
                    decoration: InputDecoration(
                      labelText: locale.translate('plate_number'),
                      hintText: '12-3456',
                      prefixIcon: const Icon(Icons.pin_outlined),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 4. Service Task Description
            TextField(
              controller: _taskController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: locale.isBangla ? 'কাজের বিবরণ / সার্ভিস নোট' : 'Service Description / Work Notes',
                hintText: 'Brake pad replacement, Oil change, AC service...',
                prefixIcon: const Icon(Icons.engineering_outlined),
              ),
            ),
            const SizedBox(height: 12),

            // 5. Bay Assignment & Quoted Price
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
                    controller: _costController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Quoted Price (${currency.currentInfo.symbol})',
                      prefixIcon: const Icon(Icons.price_change_outlined),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add_task_rounded, size: 22),
                label: Text(
                  locale.isBangla ? 'কাজ শুরু করুন (Open Job)' : 'Open Job & Assign Bay',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                onPressed: () async {
                  final customerName = _customerController.text.trim();
                  final task = _taskController.text.trim();

                  if (customerName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please provide customer name.'),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                    return;
                  }

                  if (task.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please describe the repair/service task.'),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                    return;
                  }

                  final cost = double.tryParse(_costController.text.trim()) ?? 0.0;
                  const uuid = Uuid();
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);

                  // Save or register customer if needed
                  String? customerId = _selectedCustomer?.id;
                  if (customerId == null) {
                    final newCust = Customer(
                      id: uuid.v4(),
                      name: customerName,
                      phone: _phoneController.text.trim(),
                      vehicleModel: _vehicleController.text.trim(),
                      plateNumber: _plateController.text.trim(),
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    await repo.addCustomer(newCust);
                    customerId = newCust.id;
                  }

                  final newJob = BayJob(
                    id: uuid.v4(),
                    bayNumber: _selectedBay,
                    customerId: customerId,
                    customerName: customerName,
                    customerPhone: _phoneController.text.trim(),
                    vehicleModel: _vehicleController.text.trim(),
                    plateNumber: _plateController.text.trim(),
                    taskDescription: task,
                    estimatedCost: cost,
                    technicianName: _techController.text.trim(),
                    status: 'waiting',
                    date: DateTime.now(),
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  navigator.pop();
                  await repo.createBayJob(newJob);

                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('New job created in ${newJob.bayNumber} for ${newJob.customerName}!'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
