import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_locale.dart';
import '../../../data/models/employee.dart';
import '../../../data/repositories/garage_repository.dart';

class StaffLoginManagementModal {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _StaffLoginManagementSheet(),
    );
  }
}

class _StaffLoginManagementSheet extends StatefulWidget {
  const _StaffLoginManagementSheet();

  @override
  State<_StaffLoginManagementSheet> createState() => _StaffLoginManagementSheetState();
}

class _StaffLoginManagementSheetState extends State<_StaffLoginManagementSheet> {
  // Track which employee PINs are revealed
  final Set<String> _revealedPins = {};

  void _toggleRevealPin(String empId) {
    setState(() {
      if (_revealedPins.contains(empId)) {
        _revealedPins.remove(empId);
      } else {
        _revealedPins.add(empId);
      }
    });
  }

  void _showSetPinDialog(BuildContext context, GarageRepository repo, Employee emp, AppLocaleManager locale) {
    final pinController = TextEditingController(text: emp.pin == '0000' ? '' : emp.pin);
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.key_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locale.isBangla ? 'লগইন পিন সেট করুন' : 'Set Staff Login PIN',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    Text(
                      emp.name,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                locale.isBangla
                    ? '৪ থেকে ৬ ডিজিটের একটি সহজ পিন কোড লিখুন যা ব্যবহার করে ${emp.name} অ্যাপে প্রবেশ করতে পারবে।'
                    : 'Enter a 4–6 digit numeric PIN code that ${emp.name} will use to log in.',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: locale.isBangla ? 'পিন কোড (৪-৬ ডিজিট)' : 'Login PIN (4–6 digits)',
                  hintText: 'e.g. 4321',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  errorText: errorText,
                ),
                onChanged: (val) {
                  if (errorText != null) {
                    setDialogState(() => errorText = null);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                locale.isBangla ? 'বাতিল' : 'Cancel',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final pin = pinController.text.trim();
                if (pin.length < 4 || pin.length > 6) {
                  setDialogState(() {
                    errorText = locale.isBangla
                        ? 'পিন অবশ্যই ৪ থেকে ৬ ডিজিটের হতে হবে'
                        : 'PIN must be between 4 and 6 digits';
                  });
                  return;
                }
                Navigator.pop(dialogCtx);
                await repo.setEmployeePin(emp.id, pin);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(locale.isBangla
                          ? '${emp.name}-এর পিন কোড সফলভাবে সংরক্ষিত হয়েছে'
                          : 'PIN successfully saved for ${emp.name} (Login enabled)'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: Text(
                locale.isBangla ? 'সংরক্ষণ করুন' : 'Save PIN',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmToggleLogin(BuildContext context, GarageRepository repo, Employee emp, bool enable, AppLocaleManager locale) {
    if (enable) {
      // Enabling login
      repo.toggleEmployeeLoginEnabled(emp.id, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(locale.isBangla
              ? '${emp.name}-এর লগইন সুবিধা সক্রিয় করা হয়েছে'
              : 'Login enabled for ${emp.name}'),
          backgroundColor: AppColors.success,
        ),
      );
      return;
    }

    // Disabling login -> show confirmation dialog
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                locale.isBangla ? 'লগইন নিষ্ক্রিয় করবেন?' : 'Disable Staff Login?',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Text(
          locale.isBangla
              ? 'আপনি কি ${emp.name}-এর লগইন সুবিধা নিষ্ক্রিয় করতে চান? লগইন বন্ধ করলে তিনি অ্যাপে প্রবেশ করতে পারবেন না।'
              : 'Are you sure you want to disable login access for "${emp.name}"? They will not be able to log in until re-enabled.',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              locale.isBangla ? 'বাতিল' : 'Cancel',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await repo.toggleEmployeeLoginEnabled(emp.id, false);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(locale.isBangla
                        ? '${emp.name}-এর লগইন নিষ্ক্রিয় করা হয়েছে'
                        : 'Login disabled for ${emp.name}'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            child: Text(
              locale.isBangla ? 'নিষ্ক্রিয় করুন' : 'Disable Login',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<GarageRepository>(context);
    final locale = Provider.of<AppLocaleManager>(context);
    final employees = repo.employees;
    final enabledCount = employees.where((e) => e.isLoginEnabled).length;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.lock_person_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              locale.isBangla ? 'স্টাফ লগইন ও পিন নিয়ন্ত্রণ' : 'Staff Login & Access',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'OWNER ONLY',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          locale.isBangla
                              ? '$enabledCount/${employees.length} জন কর্মীর লগইন সক্রিয় আছে'
                              : '$enabledCount of ${employees.length} staff have login enabled',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.border),

            // Info note
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      locale.isBangla
                          ? 'কর্মীদের জন্য পিন কোড সেট করুন। কর্মীরা শুধুমাত্র তাদের নির্দিষ্ট পিন দিয়ে নির্ধারিত কাজ দেখতে পারবেন।'
                          : 'Assign 4–6 digit PINs to staff. Staff accounts have role-based restrictions and cannot access financial totals.',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            // List of staff
            Expanded(
              child: employees.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_outline_rounded, size: 48, color: AppColors.textSecondary),
                          const SizedBox(height: 12),
                          Text(
                            locale.isBangla
                                ? 'কোনো কর্মী তালিকাভুক্ত নেই'
                                : 'No staff members registered yet',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      itemCount: employees.length,
                      itemBuilder: (ctx, index) {
                        final emp = employees[index];
                        final isRevealed = _revealedPins.contains(emp.id);
                        final isEnabled = emp.isLoginEnabled;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isEnabled
                                  ? AppColors.primary.withValues(alpha: 0.3)
                                  : AppColors.border,
                              width: isEnabled ? 1.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Avatar, Name & Role, Status Badge
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Avatar
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isEnabled ? AppColors.primaryLight : AppColors.background,
                                      border: Border.all(
                                        color: isEnabled
                                            ? AppColors.primary.withValues(alpha: 0.3)
                                            : AppColors.border,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: (emp.avatarBase64 != null && emp.avatarBase64!.isNotEmpty)
                                          ? Image.memory(
                                              base64Decode(emp.avatarBase64!),
                                              fit: BoxFit.cover,
                                            )
                                          : Center(
                                              child: Text(
                                                emp.name.isNotEmpty ? emp.name[0].toUpperCase() : 'S',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w900,
                                                  color: isEnabled ? AppColors.primary : AppColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Name & Role
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          emp.name,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${emp.role} • ${emp.phone}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Status Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isEnabled
                                          ? AppColors.successLight
                                          : AppColors.background,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isEnabled
                                            ? AppColors.success.withValues(alpha: 0.4)
                                            : AppColors.border,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isEnabled ? Icons.check_circle_rounded : Icons.block_rounded,
                                          size: 13,
                                          color: isEnabled ? AppColors.success : AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isEnabled
                                              ? (locale.isBangla ? 'লগইন সক্রিয়' : 'Login Enabled')
                                              : (locale.isBangla ? 'লগইন বন্ধ' : 'Disabled'),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: isEnabled ? AppColors.success : AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),
                              const Divider(height: 1, color: AppColors.border),
                              const SizedBox(height: 10),

                              // Bottom Row: PIN Preview & Actions
                              Row(
                                children: [
                                  // PIN display with Reveal toggle
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.password_rounded, size: 16, color: AppColors.textSecondary),
                                        const SizedBox(width: 6),
                                        Text(
                                          locale.isBangla ? 'পিন: ' : 'PIN: ',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          isRevealed ? emp.pin : ('•' * emp.pin.length),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.textPrimary,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        InkWell(
                                          onTap: () => _toggleRevealPin(emp.id),
                                          borderRadius: BorderRadius.circular(12),
                                          child: Padding(
                                            padding: const EdgeInsets.all(4),
                                            child: Icon(
                                              isRevealed ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                              size: 16,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Set/Change PIN Button
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(color: AppColors.primary, width: 1.2),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: const Size(0, 36),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.edit_outlined, size: 15),
                                    label: Text(
                                      emp.pin == '0000'
                                          ? (locale.isBangla ? 'পিন সেট করুন' : 'Set PIN')
                                          : (locale.isBangla ? 'পিন পরিবর্তন' : 'Change PIN'),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                                    ),
                                    onPressed: () => _showSetPinDialog(context, repo, emp, locale),
                                  ),
                                  const SizedBox(width: 8),

                                  // Enable / Disable Toggle Switch Button
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isEnabled ? AppColors.dangerLight : AppColors.successLight,
                                      foregroundColor: isEnabled ? AppColors.danger : AppColors.success,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: const Size(0, 36),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: BorderSide(
                                          color: isEnabled
                                              ? AppColors.danger.withValues(alpha: 0.4)
                                              : AppColors.success.withValues(alpha: 0.4),
                                        ),
                                      ),
                                    ),
                                    onPressed: () => _confirmToggleLogin(context, repo, emp, !isEnabled, locale),
                                    child: Text(
                                      isEnabled
                                          ? (locale.isBangla ? 'বন্ধ করুন' : 'Disable')
                                          : (locale.isBangla ? 'সক্রিয় করুন' : 'Enable'),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
