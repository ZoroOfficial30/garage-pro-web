import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/currency/currency_manager.dart';
import '../../../core/localization/app_locale.dart';
import '../../../data/models/employee.dart';
import '../../../data/repositories/garage_repository.dart';
import '../../../shared/utils/image_picker_helper.dart';

class AddEditEmployeeModal {
  static void show(BuildContext context, {Employee? existingEmployee}) {
    final repo = Provider.of<GarageRepository>(context, listen: false);
    final currency = Provider.of<CurrencyManager>(context, listen: false);
    final locale = Provider.of<AppLocaleManager>(context, listen: false);

    final isEditing = existingEmployee != null;
    final nameCtrl = TextEditingController(text: existingEmployee?.name ?? '');
    final phoneCtrl = TextEditingController(text: existingEmployee?.phone ?? '');
    final pinCtrl = TextEditingController(text: existingEmployee?.pin ?? '0000');
    final salaryCtrl = TextEditingController(
      text: existingEmployee != null
          ? existingEmployee.monthlySalary.toStringAsFixed(2)
          : '250.00',
    );

    final standardRoles = [
      'Head Mechanic',
      'Mechanic',
      'Auto Electrician',
      'Car Detailer / Wash',
      'Helper / Apprentice',
      'Service Advisor',
      'Storekeeper',
    ];

    String selectedRole = existingEmployee != null && standardRoles.contains(existingEmployee.role)
        ? existingEmployee.role
        : 'Mechanic';
    String? avatarBase64 = existingEmployee?.avatarBase64;

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
                          child: Icon(
                            isEditing ? Icons.badge_outlined : Icons.person_add_alt_1_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isEditing
                              ? (locale.isBangla ? 'কর্মচারী সম্পাদনা' : 'Edit Staff Profile')
                              : (locale.isBangla ? 'নতুন কর্মচারী যোগ করুন' : 'Add New Staff Member'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Avatar Circle with Camera badge
                    Center(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final result = await ImagePickerHelper.showPhotoSourceDialog(
                                context: context,
                                hasExistingPhoto: avatarBase64 != null && avatarBase64!.isNotEmpty,
                              );
                              if (result != null) {
                                setModalState(() {
                                  avatarBase64 = result.isEmpty ? null : result;
                                });
                              }
                            },
                            child: Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryLight,
                                border: Border.all(color: AppColors.primary, width: 2),
                              ),
                              child: ClipOval(
                                child: avatarBase64 != null && avatarBase64!.isNotEmpty
                                    ? Image.memory(
                                        base64Decode(avatarBase64!),
                                        fit: BoxFit.cover,
                                        width: 84,
                                        height: 84,
                                      )
                                    : Center(
                                        child: Text(
                                          nameCtrl.text.isNotEmpty
                                              ? nameCtrl.text[0].toUpperCase()
                                              : 'S',
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () async {
                                final result = await ImagePickerHelper.showPhotoSourceDialog(
                                  context: context,
                                  hasExistingPhoto: avatarBase64 != null && avatarBase64!.isNotEmpty,
                                );
                                if (result != null) {
                                  setModalState(() {
                                    avatarBase64 = result.isEmpty ? null : result;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        locale.isBangla ? 'ছবি পরিবর্তন করতে ট্যাপ করুন' : 'Tap to add/change photo',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Full Name
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Staff Name *',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 14),

                    // Phone Number
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number *',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Role / Designation Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role / Designation *',
                        prefixIcon: Icon(Icons.engineering_outlined),
                      ),
                      items: standardRoles
                          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedRole = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Monthly Salary
                    TextField(
                      controller: salaryCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Monthly Salary (${currency.currentInfo.symbol}) *',
                        prefixIcon: const Icon(Icons.payments_outlined),
                        suffixText: currency.currentInfo.symbol,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Staff Login PIN (4-6 digits)
                    TextField(
                      controller: pinCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: 'Staff Login PIN (4–6 digits) *',
                        hintText: 'e.g. 1111',
                        prefixIcon: Icon(Icons.pin_outlined),
                        helperText: 'Used by this staff member to log in to the app',
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Save Button
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
                          final name = nameCtrl.text.trim();
                          final phone = phoneCtrl.text.trim();
                          final pin = pinCtrl.text.trim().isNotEmpty ? pinCtrl.text.trim() : '0000';
                          final salary = double.tryParse(salaryCtrl.text.trim()) ?? 250.0;

                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter staff name')),
                            );
                            return;
                          }

                          if (isEditing) {
                            final updated = existingEmployee.copyWith(
                              name: name,
                              phone: phone,
                              role: selectedRole,
                              pin: pin,
                              avatarBase64: avatarBase64,
                              monthlySalary: salary,
                              updatedAt: DateTime.now(),
                            );
                            await repo.updateEmployee(updated);
                          } else {
                            const uuid = Uuid();
                            final newEmp = Employee(
                              id: uuid.v4(),
                              name: name,
                              phone: phone,
                              role: selectedRole,
                              pin: pin,
                              avatarBase64: avatarBase64,
                              monthlySalary: salary,
                              isSalaryPaid: false,
                              isPresent: true,
                              lastAttendanceDate: DateTime.now(),
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            );
                            await repo.createEmployee(newEmp);
                          }

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isEditing
                                    ? 'Updated profile for $name'
                                    : 'Added $name to staff directory'),
                                backgroundColor: AppColors.primaryDark,
                              ),
                            );
                          }
                        },
                        child: Text(
                          isEditing
                              ? (locale.isBangla ? 'সংরক্ষণ করুন' : 'Save Changes')
                              : (locale.isBangla ? 'কর্মচারী যুক্ত করুন' : 'Add Staff Member'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
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
