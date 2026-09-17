import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_locale.dart';
import '../../../data/repositories/garage_repository.dart';
import '../../settings/widgets/cloud_account_modal.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _showFreshSetupModal(BuildContext context, GarageRepository repo, AppLocaleManager locale) {
    final nameCtrl = TextEditingController(text: repo.workshopProfile['name'] ?? 'Apex Auto Workshop');
    final pinCtrl = TextEditingController(text: '1234');
    final confirmPinCtrl = TextEditingController(text: '1234');
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add_business_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          locale.isBangla ? 'নতুন গ্যারেজ সেটআপ' : 'Setup New Garage',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    locale.isBangla
                        ? 'আপনার ওয়ার্কশপের নাম ও মালিকের পিন (PIN) নির্ধারণ করুন:'
                        : 'Configure your workshop name and Owner login PIN:',
                    style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  if (error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.dangerLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              error!,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.danger,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  // Workshop Name Input
                  Text(
                    locale.isBangla ? 'ওয়ার্কশপের নাম' : 'Workshop Name',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: locale.isBangla ? 'যেমন: এপেক্স অটো ওয়ার্কশপ' : 'e.g. Apex Auto Workshop',
                      prefixIcon: const Icon(Icons.store_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Owner PIN Input
                  Text(
                    locale.isBangla ? 'মালিকের পিন (৪-৬ সংখ্যা)' : 'Owner PIN (4-6 digits)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: pinCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      hintText: '1234',
                      counterText: '',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Confirm PIN Input
                  Text(
                    locale.isBangla ? 'পিন নিশ্চিত করুন' : 'Confirm PIN',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: confirmPinCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      hintText: '1234',
                      counterText: '',
                      prefixIcon: const Icon(Icons.lock_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final pin = pinCtrl.text.trim();
                        final confirm = confirmPinCtrl.text.trim();

                        if (pin.length < 4) {
                          setModalState(() {
                            error = locale.isBangla
                                ? 'পিন অন্তত ৪ সংখ্যার হতে হবে'
                                : 'PIN must be at least 4 digits';
                          });
                          return;
                        }

                        if (pin != confirm) {
                          setModalState(() {
                            error = locale.isBangla
                                ? 'পিন দুটি মিলছে না'
                                : 'PINs do not match';
                          });
                          return;
                        }

                        Navigator.pop(modalCtx);
                        await repo.completeFreshSetup(name: name, pin: pin);
                      },
                      child: Text(
                        locale.isBangla
                            ? 'গ্যারেজ তৈরি ও ড্যাশবোর্ডে প্রবেশ করুন'
                            : 'Create Garage & Enter Dashboard',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<GarageRepository>(context);
    final locale = Provider.of<AppLocaleManager>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: AppColors.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            icon: const Icon(Icons.translate_rounded, size: 18),
            label: Text(
              locale.isBangla ? 'English' : 'বাংলা',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            onPressed: () => locale.toggleLanguage(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Brand Icon & Badge
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFC72C), Color(0xFFFF9E00)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.garage_rounded,
                      size: 44,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // App Title
                  Text(
                    locale.isBangla
                        ? 'গ্যারেজ অ্যাকাউন্টিং প্রো'
                        : 'Garage Accounting Pro',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    locale.isBangla
                        ? 'আপনার ওয়ার্কশপ পরিচালনায় শুরু করতে নিচের যেকোনো একটি বিকল্প বেছে নিন'
                        : 'Select an option to get started with your workshop management',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Option A: Start Fresh Garage
                  _buildOptionCard(
                    context: context,
                    icon: Icons.add_business_rounded,
                    iconColor: AppColors.primary,
                    iconBgColor: AppColors.primaryLight,
                    title: locale.isBangla ? 'নতুন গ্যারেজ শুরু করুন' : 'Start Fresh Garage',
                    subtitle: locale.isBangla
                        ? 'এই ডিভাইসে একটি নতুন ওয়ার্কশপ প্রোফাইল এবং মালিকের পিন তৈরি করুন।'
                        : 'Set up a brand new workshop profile and Owner PIN code on this device.',
                    badge: locale.isBangla ? 'নতুন ইন্সটল' : 'NEW WORKSHOP',
                    badgeColor: AppColors.primaryLight,
                    badgeTextColor: const Color(0xFF8A6500),
                    buttonText: locale.isBangla ? 'গ্যারেজ সেটআপ করুন' : 'Setup New Garage',
                    isPrimaryButton: true,
                    onTap: () => _showFreshSetupModal(context, repo, locale),
                  ),
                  const SizedBox(height: 18),

                  // Option B: Restore from Cloud / Existing Account
                  _buildOptionCard(
                    context: context,
                    icon: Icons.cloud_download_rounded,
                    iconColor: const Color(0xFF2563EB),
                    iconBgColor: const Color(0xFFDBEAFE),
                    title: locale.isBangla ? 'ক্লাউড থেকে রিস্টোর করুন' : 'Restore from Cloud',
                    subtitle: locale.isBangla
                        ? 'অন্য ডিভাইস বা পূর্বের ক্লাউড ব্যাকআপ থেকে সমস্ত ডেটা এই ডিভাইসে সিঙ্ক করুন।'
                        : 'Log into your Supabase account to sync existing customers, jobs, and transactions to this device.',
                    badge: locale.isBangla ? 'মাল্টি-ডিভাইস' : 'MULTI-DEVICE',
                    badgeColor: const Color(0xFFDBEAFE),
                    badgeTextColor: const Color(0xFF1D4ED8),
                    buttonText: locale.isBangla ? 'ক্লাউডে লগইন ও সিঙ্ক' : 'Log In & Restore',
                    isPrimaryButton: false,
                    onTap: () {
                      CloudAccountModal.show(
                        context,
                        isRestoreFlow: true,
                        onLoginSuccess: () async {
                          await repo.completeCloudRestoreSetup();
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // Offline First Guarantee Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.offline_bolt_rounded, size: 16, color: AppColors.success),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          locale.isBangla
                              ? '১০০% অফলাইন কার্যকরী • রিয়েল-টাইম ক্লাউড সিঙ্ক'
                              : '100% Offline Capable • Real-Time Cloud Sync',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required Color badgeTextColor,
    required String buttonText,
    required bool isPrimaryButton,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPrimaryButton ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
          width: isPrimaryButton ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: badgeTextColor,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: isPrimaryButton
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: onTap,
                    child: Text(
                      buttonText,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                  )
                : OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: onTap,
                    child: Text(
                      buttonText,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
