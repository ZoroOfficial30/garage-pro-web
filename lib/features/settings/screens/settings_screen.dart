import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/currency/currency_manager.dart';
import '../../../core/localization/app_locale.dart';
import '../../../data/repositories/garage_repository.dart';
import '../../../shared/utils/image_picker_helper.dart';
import '../widgets/edit_profile_modal.dart';
import '../widgets/backup_restore_modal.dart';
import '../widgets/cloud_account_modal.dart';
import '../../../core/services/sync_service.dart';
import '../../employees/screens/employees_screen.dart';
import '../../employees/widgets/staff_login_management_modal.dart';
import '../../navigation/widgets/drawer_helper.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<GarageRepository>(context);
    final currency = Provider.of<CurrencyManager>(context);
    final locale = Provider.of<AppLocaleManager>(context);
    final profile = repo.workshopProfile;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      drawer: buildAppDrawer(context),
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                iconSize: 24,
                tooltip: 'Back',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () => Navigator.of(context).pop(),
              )
            : buildDrawerHamburgerButton(context),
        title: Text(
          locale.translate('workshop_settings'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.5),
          child: Divider(height: 1.5, color: AppColors.border),
        ),
        actions: [
          IconButton(
            tooltip: 'Switch Language',
            icon: const Icon(Icons.translate_rounded),
            onPressed: () => locale.toggleLanguage(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Workshop Profile Card
                _buildWorkshopProfileSection(context, repo, profile),
                const SizedBox(height: 20),

                // 2. Staff Management Section
                _buildStaffManagementSection(context, repo, locale),
                const SizedBox(height: 20),

                // 2. Primary Currency Selection
                _buildCurrencySection(context, currency, locale),
                const SizedBox(height: 20),

                // 3. Voice & App Language Selection
                _buildLanguageSection(context, locale),
                const SizedBox(height: 20),

                // 4. WhatsApp Due Reminder Message Customizer
                WhatsAppReminderSection(
                  repo: repo,
                  currency: currency,
                  locale: locale,
                ),
                const SizedBox(height: 20),

                // 5. Display & Ergonomics
                _buildDisplayErgonomicsSection(context, repo, locale),
                const SizedBox(height: 20),

                // 5. Security & Access
                _buildSecuritySection(context, repo, locale),
                const SizedBox(height: 20),

                // 6. Data Management
                _buildDataManagementSection(context, repo, locale),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkshopProfileSection(
    BuildContext context,
    GarageRepository repo,
    Map<String, String> profile,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  final hasLogo = profile['logoBase64'] != null && profile['logoBase64']!.isNotEmpty;
                  final picked = await ImagePickerHelper.showPhotoSourceDialog(
                    context: context,
                    hasExistingPhoto: hasLogo,
                    title: 'Workshop Logo / Profile Image',
                    removeLabel: 'Remove Logo',
                    removeSubtitle: 'Revert back to default garage icon',
                  );
                  if (picked != null) {
                    await repo.updateWorkshopLogo(picked);
                  }
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: (profile['logoBase64'] != null && profile['logoBase64']!.isNotEmpty)
                          ? Image.memory(
                              base64Decode(profile['logoBase64']!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.garage_rounded,
                                color: AppColors.primary,
                                size: 34,
                              ),
                            )
                          : const Icon(
                              Icons.garage_rounded,
                              color: AppColors.primary,
                              size: 34,
                            ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.surface, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile['name'] ?? 'Apex Auto Workshop',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.call, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          profile['phone'] ?? '+880 1711-234567',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.receipt_long, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Tax ID: ${profile['taxId'] ?? 'VAT-89210-AUTO'}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => EditProfileModal.show(context, repo),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text(
                'Edit Profile',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffManagementSection(
    BuildContext context,
    GarageRepository repo,
    AppLocaleManager locale,
  ) {
    final staff = repo.employees;
    final present = staff.where((e) => e.isPresent).length;
    final unpaid = staff.where((e) => !e.isSalaryPaid).length;
    final loginEnabledCount = staff.where((e) => e.isLoginEnabled).length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: InkWell(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EmployeesScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.badge_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                locale.isBangla
                                    ? 'কর্মচারী ও বেতন ব্যবস্থাপনা'
                                    : 'Staff & Team Directory',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${staff.length} Staff',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$present on duty today • $unpaid pending salaries',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 16, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // Sub-tile for Staff Login & Access PINs (Owner only)
          Material(
            color: Colors.transparent,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: InkWell(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              onTap: () => StaffLoginManagementModal.show(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.lock_person_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                locale.isBangla ? 'স্টাফ লগইন ও পিন ব্যবস্থাপনা' : 'Staff Login & Access PINs',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'OWNER',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            locale.isBangla
                                ? '$loginEnabledCount/${staff.length} জন কর্মীর লগইন সক্রিয় আছে'
                                : '$loginEnabledCount of ${staff.length} staff login enabled • Tap to configure',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencySection(
    BuildContext context,
    CurrencyManager currency,
    AppLocaleManager locale,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payments_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                locale.translate('primary_currency'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'All transactions, stock and invoices will format in this currency.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: CurrencyCode.values.map((code) {
              final info = CurrencyManager.currencies[code]!;
              final isSelected = currency.currentCurrency == code;

              return ChoiceChip(
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    currency.setCurrency(code);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Currency switched to ${info.englishName} (${info.symbol})'),
                        duration: const Duration(seconds: 2),
                        backgroundColor: AppColors.textPrimary,
                      ),
                    );
                  }
                },
                avatar: CircleAvatar(
                  backgroundColor: isSelected ? Colors.white : AppColors.background,
                  child: Text(
                    info.symbol,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ),
                label: Text(
                  '${info.code.name.toUpperCase()} (${info.englishName})',
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSection(
    BuildContext context,
    AppLocaleManager locale,
  ) {
    final languages = [
      {'code': AppLanguage.en, 'label': 'English', 'sub': 'English'},
      {'code': AppLanguage.bn, 'label': 'বাংলা', 'sub': 'Bengali'},
      {'code': AppLanguage.hi, 'label': 'हिन्दी', 'sub': 'Hindi'},
      {'code': AppLanguage.ar, 'label': 'العربية', 'sub': 'Arabic'},
      {'code': AppLanguage.ur, 'label': 'اردو', 'sub': 'Urdu'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.record_voice_over_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                locale.translate('voice_language'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: languages.map((lang) {
              final code = lang['code'] as AppLanguage;
              final isSelected = locale.currentLanguage == code;

              return ChoiceChip(
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    locale.setLanguage(code);
                  }
                },
                label: Text(
                  lang['label'] as String,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: const [
                Icon(Icons.graphic_eq_rounded, color: AppColors.success, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Multi-dialect voice command recognition active for garage terms',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayErgonomicsSection(
    BuildContext context,
    GarageRepository repo,
    AppLocaleManager locale,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.accessibility_new_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                locale.translate('display_ergonomics'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              locale.translate('sunlight_mode'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            subtitle: const Text(
              'Enhances contrast and typography for outdoor sunlight',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            value: repo.sunlightHighContrast,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => repo.setSunlightHighContrast(val),
          ),
          const Divider(height: 1, color: AppColors.border),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              locale.translate('extra_large_text'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            subtitle: const Text(
              'Enlarges buttons and numbers for mechanics wearing work gloves',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            value: repo.extraLargeText,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => repo.setExtraLargeText(val),
          ),
          const Divider(height: 1, color: AppColors.border),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              locale.translate('voice_feedback'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            subtitle: const Text(
              'Spoken audio confirmation when due or payment recorded',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            value: repo.voiceFeedback,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => repo.setVoiceFeedback(val),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(
    BuildContext context,
    GarageRepository repo,
    AppLocaleManager locale,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    locale.translate('security_access'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'OWNER ACCESS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              locale.translate('pin_lock'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            subtitle: Text(
              'Owner PIN: 4–6 digits (Current: ${repo.ownerPin})',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            value: repo.pinLockEnabled,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => repo.setPinLockEnabled(val),
          ),
          if (repo.pinLockEnabled) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _showChangePinDialog(context, repo),
                icon: const Icon(Icons.pin_outlined, size: 16),
                label: const Text('Change PIN Code'),
              ),
            ),
          ],
          const Divider(height: 1, color: AppColors.border),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              locale.translate('biometric_lock'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            subtitle: Text(
              kIsWeb
                  ? (locale.isBangla
                      ? 'ওয়েব ব্রাউজারে বায়োমেট্রিক উপলব্ধ নেই (মোবাইলে ফিঙ্গারপ্রিন্ট সমর্থিত)'
                      : 'Biometrics unavailable on Web (Supported on mobile devices)')
                  : 'Unlock with fingerprint sensor or Face ID',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            value: kIsWeb ? false : repo.biometricEnabled,
            activeThumbColor: AppColors.primary,
            onChanged: kIsWeb ? null : (val) => repo.setBiometricEnabled(val),
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagementSection(
    BuildContext context,
    GarageRepository repo,
    AppLocaleManager locale,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storage_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                locale.translate('data_management'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Backup & Restore Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.security_update_good_rounded, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          locale.translate('backup_restore'),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        '100% OFFLINE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  locale.translate('backup_desc'),
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.3),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => BackupRestoreModal.startBackupFlow(context, repo, locale),
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: Text(
                            locale.translate('backup_data'),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.border, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => BackupRestoreModal.startRestoreFlow(context, repo, locale),
                          icon: const Icon(Icons.upload_file_rounded, size: 18),
                          label: Text(
                            locale.translate('restore_data'),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),

          // Export CSV
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.table_view_rounded, color: AppColors.primary),
            ),
            title: Text(
              locale.translate('export_csv'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            subtitle: const Text('Save ledger of transactions and expenses as CSV'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showExportCsvDialog(context, repo),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Cloud Account & Multi-Device Sync
          ListenableBuilder(
            listenable: SyncService(),
            builder: (ctx, _) {
              final sync = SyncService();
              final isAuth = sync.isCloudAuthenticated;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isAuth ? AppColors.successLight : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isAuth ? Icons.cloud_done_rounded : Icons.cloud_sync_rounded,
                    color: isAuth ? AppColors.success : AppColors.primary,
                  ),
                ),
                title: Text(
                  locale.isBangla
                      ? 'ক্লাউড অ্যাকাউন্ট ও মাল্টি-ডিভাইস সিঙ্ক'
                      : 'Cloud Account & Multi-Device Sync',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                subtitle: Text(
                  isAuth
                      ? (locale.isBangla
                          ? 'কানেক্টেড: ${sync.currentCloudUser?.email}'
                          : 'Connected: ${sync.currentCloudUser?.email} • Auto-Sync Active')
                      : (locale.isBangla
                          ? 'ক্লাউড লগইন করুন • মাল্টি-ডিভাইস সিঙ্ক চালু করুন'
                          : 'Sign in to sync across phones, tablets & web'),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => CloudAccountModal.show(context),
              );
            },
          ),
          const Divider(height: 1, color: AppColors.border),

          // Cloud Backup
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.cloud_sync_rounded, color: AppColors.success),
            ),
            title: Text(
              locale.translate('cloud_backup'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            subtitle: const Text('Local Hive storage active • Ready for Supabase sync'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All local records saved safely in Hive.'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
          const Divider(height: 1, color: AppColors.border),

          // Print Statement
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.print_outlined, color: AppColors.textPrimary),
            ),
            title: Text(
              locale.translate('print_statement'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            subtitle: const Text('Generate printable monthly garage accounting summary'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPrintStatementDialog(context, repo),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Reset Demo Data
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.restart_alt_rounded, color: AppColors.danger),
            ),
            title: Text(
              locale.translate('reset_demo_data'),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.danger,
              ),
            ),
            subtitle: const Text('Clear all records and reset garage to a fresh clean state'),
            trailing: const Icon(Icons.chevron_right, color: AppColors.danger),
            onTap: () => _confirmResetDemoData(context, repo),
          ),
        ],
      ),
    );
  }

  void _showChangePinDialog(BuildContext context, GarageRepository repo) {
    final controller = TextEditingController(text: repo.ownerPin);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Owner PIN (4–6 Digits)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            hintText: 'Enter 4–6 digits (e.g. 1234)',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final pin = controller.text.trim();
              if (pin.length >= 4 && pin.length <= 6) {
                await repo.setPinCode(pin);
                await repo.setOwnerPin(pin);
                if (ctx.mounted) Navigator.of(ctx).pop();
              }
            },
            child: const Text('Save PIN'),
          ),
        ],
      ),
    );
  }

  void _showExportCsvDialog(BuildContext context, GarageRepository repo) {
    final csvContent = repo.generateLedgerCsv();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Ledger to CSV'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ledger CSV generated successfully. You can copy it directly to your clipboard:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    csvContent,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csvContent));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('CSV copied to clipboard!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy to Clipboard'),
          ),
        ],
      ),
    );
  }

  void _showPrintStatementDialog(BuildContext context, GarageRepository repo) {
    final currency = Provider.of<CurrencyManager>(context, listen: false);
    final totalDues = repo.totalOutstandingDues;
    final income = repo.todayIncome;
    final expense = repo.todayExpense;
    final profile = repo.workshopProfile;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${profile['name']} Statement'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Contact: ${profile['phone']}'),
              Text('Tax ID: ${profile['taxId']}'),
              const Divider(height: 24),
              Text(
                'Total Outstanding Customer Dues: ${currency.format(totalDues)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text('Today Collected Income: ${currency.format(income)}'),
              const SizedBox(height: 6),
              Text('Today Recorded Expense: ${currency.format(expense)}'),
              const SizedBox(height: 6),
              Text(
                'Net Today Margin: ${currency.format(income - expense)}',
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.success),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sent to wireless workshop printer!')),
              );
            },
            icon: const Icon(Icons.print),
            label: const Text('Print Now'),
          ),
        ],
      ),
    );
  }

  void _confirmResetDemoData(BuildContext context, GarageRepository repo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Garage Data?'),
        content: const Text(
          'This will clear all customers, transactions, job cards, stock items, and expenses to start completely fresh. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await repo.resetDemoData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All garage data reset to fresh state!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Reset All Data'),
          ),
        ],
      ),
    );
  }
}

class WhatsAppReminderSection extends StatefulWidget {
  final GarageRepository repo;
  final CurrencyManager currency;
  final AppLocaleManager locale;

  const WhatsAppReminderSection({
    super.key,
    required this.repo,
    required this.currency,
    required this.locale,
  });

  @override
  State<WhatsAppReminderSection> createState() => _WhatsAppReminderSectionState();
}

class _WhatsAppReminderSectionState extends State<WhatsAppReminderSection> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.repo.whatsappDueTemplate);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _insertPlaceholder(String placeholder) {
    final text = _controller.text;
    final selection = _controller.selection;
    if (selection.isValid && selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, placeholder);
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + placeholder.length),
      );
    } else {
      _controller.text = text + placeholder;
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final locale = widget.locale;
    final repo = widget.repo;
    const sampleAmount = 2500.0;
    final formattedSample = widget.currency.format(sampleAmount);
    final shopName = repo.workshopProfile['name']?.isNotEmpty == true
        ? repo.workshopProfile['name']!
        : 'Apex Auto Workshop';

    var previewText = _controller.text;
    previewText = previewText.replaceAll('{amount}', formattedSample);
    previewText = previewText.replaceAll('{workshopName}', shopName);
    previewText = previewText.replaceAll('{customerName}', 'Karim Ahmed');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.chat_rounded,
                  color: Color(0xFF16A34A),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locale.translate('due_reminder_title'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      locale.translate('due_reminder_desc'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Helper Tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Insert tags:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              ActionChip(
                backgroundColor: AppColors.primaryLight,
                label: const Text(
                  '{amount}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                onPressed: () => _insertPlaceholder('{amount}'),
              ),
              ActionChip(
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.border),
                label: const Text(
                  '{workshopName}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                onPressed: () => _insertPlaceholder('{workshopName}'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Message Template Input
          TextField(
            controller: _controller,
            maxLines: 4,
            minLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: locale.translate('due_reminder_hint'),
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Live Preview Container
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.visibility_outlined,
                      size: 16,
                      color: Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      locale.translate('message_preview'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF16A34A),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'WhatsApp',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  previewText.isNotEmpty ? previewText : '...',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF14532D),
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons: Save Template & Reset to Default
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      await repo.setWhatsAppDueTemplate(_controller.text);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(locale.translate('template_saved')),
                            backgroundColor: const Color(0xFF16A34A),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: Text(
                      locale.translate('save_message'),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      await repo.resetWhatsAppDueTemplate();
                      setState(() {
                        _controller.text = GarageRepository.defaultWhatsAppTemplate;
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(locale.translate('template_reset')),
                            backgroundColor: AppColors.primaryDark,
                          ),
                        );
                      }
                    },
                    child: Text(
                      locale.translate('reset_to_default'),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

