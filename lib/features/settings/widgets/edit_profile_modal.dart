import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/garage_repository.dart';
import '../../../shared/utils/image_picker_helper.dart';

class EditProfileModal extends StatefulWidget {
  final GarageRepository repo;

  const EditProfileModal({super.key, required this.repo});

  static void show(BuildContext context, GarageRepository repo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => EditProfileModal(repo: repo),
    );
  }

  @override
  State<EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends State<EditProfileModal> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _taxIdController;
  late final TextEditingController _addressController;
  String? _logoBase64;

  @override
  void initState() {
    super.initState();
    final profile = widget.repo.workshopProfile;
    _nameController = TextEditingController(text: profile['name']);
    _phoneController = TextEditingController(text: profile['phone']);
    _taxIdController = TextEditingController(text: profile['taxId']);
    _addressController = TextEditingController(text: profile['address']);
    _logoBase64 = profile['logoBase64'];
  }

  Future<void> _pickLogo() async {
    final picked = await ImagePickerHelper.showPhotoSourceDialog(
      context: context,
      hasExistingPhoto: _logoBase64 != null && _logoBase64!.isNotEmpty,
      title: 'Workshop Logo / Profile Image',
      removeLabel: 'Remove Logo',
      removeSubtitle: 'Revert back to default garage icon',
    );
    if (picked != null) {
      setState(() {
        _logoBase64 = picked;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _taxIdController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 20,
          right: 20,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              const Text(
                'Edit Workshop Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Logo Avatar with Camera Badge & Actions
          Center(
            child: GestureDetector(
              onTap: _pickLogo,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: (_logoBase64 != null && _logoBase64!.isNotEmpty)
                        ? Image.memory(
                            base64Decode(_logoBase64!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.garage_rounded,
                              color: AppColors.primary,
                              size: 40,
                            ),
                          )
                        : const Icon(
                            Icons.garage_rounded,
                            color: AppColors.primary,
                            size: 40,
                          ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: _pickLogo,
              icon: Icon(
                _logoBase64 != null && _logoBase64!.isNotEmpty
                    ? Icons.sync_rounded
                    : Icons.add_photo_alternate_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              label: Text(
                _logoBase64 != null && _logoBase64!.isNotEmpty
                    ? 'Change Workshop Logo'
                    : 'Upload Workshop Logo',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Workshop Name',
              hintText: 'e.g. Apex Auto Workshop',
              prefixIcon: Icon(Icons.garage_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Contact Phone',
              hintText: 'e.g. +880 1711-234567',
              prefixIcon: Icon(Icons.call_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _taxIdController,
            decoration: const InputDecoration(
              labelText: 'Tax ID / CR Number',
              hintText: 'e.g. VAT-89210-AUTO',
              prefixIcon: Icon(Icons.receipt_long_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Workshop Address',
              hintText: 'e.g. Industrial Bay 4',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () async {
                final name = _nameController.text.trim();
                final phone = _phoneController.text.trim();
                final taxId = _taxIdController.text.trim();
                final address = _addressController.text.trim();

                if (name.isNotEmpty) {
                  await widget.repo.updateWorkshopProfile(
                    name: name,
                    phone: phone,
                    taxId: taxId,
                    address: address,
                    logoBase64: _logoBase64,
                  );
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text(
                'Save Profile',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
