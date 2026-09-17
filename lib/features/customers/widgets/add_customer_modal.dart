import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/currency/currency_manager.dart';
import '../../../core/localization/app_locale.dart';
import '../../../data/models/customer.dart';
import '../../../data/repositories/garage_repository.dart';
import '../../../shared/utils/image_picker_helper.dart';

class AddCustomerModal {
  static void show(BuildContext context) {
    final repo = Provider.of<GarageRepository>(context, listen: false);
    final locale = Provider.of<AppLocaleManager>(context, listen: false);
    final currency = Provider.of<CurrencyManager>(context, listen: false);

    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final vehicleController = TextEditingController();
    final plateController = TextEditingController();
    final dueController = TextEditingController();
    final notesController = TextEditingController();
    bool isVip = false;
    String? avatarBase64;

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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.person_add_alt_1_rounded,
                              color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          locale.isBangla ? 'নতুন কাস্টমার যোগ করুন' : 'Add New Customer',
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

                    // Avatar Photo Picker
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
                              width: 76,
                              height: 76,
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
                                        width: 76,
                                        height: 76,
                                      )
                                    : Center(
                                        child: Text(
                                          nameController.text.isNotEmpty
                                              ? nameController.text[0].toUpperCase()
                                              : 'C',
                                          style: const TextStyle(
                                            fontSize: 28,
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
                                  size: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        locale.isBangla ? 'কাস্টমারের ছবি তুলুন / যোগ করুন' : 'Tap to take or choose photo',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: '${locale.translate('customer_name')} *',
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: vehicleController,
                            decoration: const InputDecoration(
                              labelText: 'Vehicle Model',
                              prefixIcon: Icon(Icons.directions_car_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: plateController,
                            decoration: const InputDecoration(
                              labelText: 'Plate Number',
                              prefixIcon: Icon(Icons.pin_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dueController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText:
                            'Opening Due Balance (${currency.currentInfo.symbol})',
                        prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Workshop Notes',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: isVip,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            setModalState(() => isVip = val ?? false);
                          },
                        ),
                        const Text(
                          'Mark as VIP Customer',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;
                        final initialDue =
                            double.tryParse(dueController.text.trim()) ?? 0.0;

                        final newCust = Customer(
                          id: const Uuid().v4(),
                          name: name,
                          phone: phoneController.text.trim(),
                          vehicleModel: vehicleController.text.trim().isEmpty
                              ? 'Vehicle'
                              : vehicleController.text.trim(),
                          plateNumber: plateController.text.trim(),
                          totalDue: initialDue,
                          totalBilled: initialDue,
                          totalPaid: 0.0,
                          isVip: isVip,
                          notes: notesController.text.trim(),
                          avatarBase64: avatarBase64,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );

                        await repo.createCustomer(newCust);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Customer "$name" created successfully!',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              backgroundColor: AppColors.primaryDark,
                            ),
                          );
                        }
                      },
                      child: Text(
                        locale.isBangla ? 'কাস্টমার সংরক্ষণ করুন' : 'Save Customer',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
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
