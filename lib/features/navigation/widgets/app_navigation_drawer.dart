import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_locale.dart';
import '../../../data/repositories/garage_repository.dart';

class AppNavigationDrawer extends StatelessWidget {
  final VoidCallback onSelectCashbook;
  final VoidCallback onSelectInventory;
  final VoidCallback onSelectSupplierDues;
  final VoidCallback onSelectStaff;
  final VoidCallback onSelectDashboard;
  final VoidCallback onSelectSettings;

  const AppNavigationDrawer({
    super.key,
    required this.onSelectCashbook,
    required this.onSelectInventory,
    required this.onSelectSupplierDues,
    required this.onSelectStaff,
    required this.onSelectDashboard,
    required this.onSelectSettings,
  });

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<GarageRepository>(context);
    final locale = Provider.of<AppLocaleManager>(context);

    final profile = repo.workshopProfile;
    final workshopName = profile['name']?.isNotEmpty == true
        ? profile['name']!
        : (locale.isBangla ? 'এপেক্স অটো ওয়ার্কশপ' : 'Apex Auto Workshop');
    final activeDateStr = DateFormat('EEEE, d MMM yyyy').format(DateTime.now());

    return Drawer(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 1. DRAWER HEADER (Logo, Name, Date, Sync Badge)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Workshop Logo
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: (repo.workshopLogoBase64 != null &&
                                repo.workshopLogoBase64!.isNotEmpty)
                            ? Image.memory(
                                base64Decode(repo.workshopLogoBase64!),
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const Icon(
                                  Icons.garage_rounded,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              )
                            : const Icon(
                                Icons.garage_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              workshopName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activeDateStr,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Role Badge & Online Sync Active pill
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      // Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: repo.isOwner
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: repo.isOwner
                                ? AppColors.primary.withValues(alpha: 0.3)
                                : AppColors.warning.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              repo.isOwner
                                  ? Icons.admin_panel_settings_rounded
                                  : Icons.badge_rounded,
                              size: 13,
                              color: repo.isOwner ? AppColors.primary : AppColors.warning,
                            ),
                            const SizedBox(width: 5),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 170),
                              child: Text(
                                repo.isOwner
                                    ? (locale.isBangla ? 'মালিক / অ্যাডমিন' : 'OWNER / ADMIN')
                                    : (locale.isBangla
                                        ? 'স্টাফ • ${repo.currentUser?.name ?? "কর্মী"}'
                                        : 'STAFF • ${repo.currentUser?.name ?? "Staff"}'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: repo.isOwner ? AppColors.primary : AppColors.warning,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Online Sync Active pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 170),
                              child: Text(
                                locale.isBangla ? 'অনলাইন সিঙ্ক সক্রিয়' : 'Online Sync Active',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. MANAGEMENT MODULES (Role-based filtering)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Column(
                  children: [
                    if (repo.isOwner) ...[
                      // Item 1: Cashbook (Owner Only)
                      _buildDrawerTile(
                        context: context,
                        icon: Icons.menu_book_rounded,
                        title: locale.isBangla ? 'ক্যাশ বুক' : 'Cashbook',
                        subtitle: locale.isBangla
                            ? 'আয় ও ব্যয়ের একক লেজার'
                            : 'Unified Daily Cash Ledger',
                        color: AppColors.success,
                        onTap: () {
                          Navigator.pop(context);
                          onSelectCashbook();
                        },
                      ),

                      // Item 2: Stock / Inventory
                      _buildDrawerTile(
                        context: context,
                        icon: Icons.inventory_2_rounded,
                        title: locale.isBangla ? 'স্টক / ইনভেন্টরি' : 'Stock / Inventory',
                        subtitle: locale.isBangla
                            ? 'স্টক ও স্পেয়ার পার্টস'
                            : 'Stock & Parts Inventory',
                        color: AppColors.warning,
                        onTap: () {
                          Navigator.pop(context);
                          onSelectInventory();
                        },
                      ),

                      // Item 3: Supplier Dues (Owner Only)
                      _buildDrawerTile(
                        context: context,
                        icon: Icons.domain_rounded,
                        title: locale.isBangla ? 'কোম্পানির দেনা' : 'Supplier Dues',
                        subtitle: locale.isBangla
                            ? 'তেল, পার্টস ও কোম্পানির বকেয়া'
                            : 'Parts & Company Payables',
                        color: AppColors.primary,
                        badgeCount: repo.pendingSupplierDuesCount,
                        onTap: () {
                          Navigator.pop(context);
                          onSelectSupplierDues();
                        },
                      ),

                      // Item 4: Staff & Attendance
                      _buildDrawerTile(
                        context: context,
                        icon: Icons.badge_rounded,
                        title: locale.isBangla ? 'স্টাফ ও হাজিরা' : 'Staff & Attendance',
                        subtitle: locale.isBangla
                            ? 'উপস্থিতি ও বেতন পরিশোধ'
                            : 'Attendance & Payroll',
                        color: AppColors.primaryDark,
                        onTap: () {
                          Navigator.pop(context);
                          onSelectStaff();
                        },
                      ),

                      // Item 5: Dashboard (Owner Only)
                      _buildDrawerTile(
                        context: context,
                        icon: Icons.dashboard_rounded,
                        title: locale.isBangla ? 'ড্যাশবোর্ড' : 'Dashboard',
                        subtitle: locale.isBangla
                            ? 'কেপিআই ও ক্যাশফ্লো গ্রাফ'
                            : 'KPIs & Cash Flow Chart',
                        color: AppColors.primary,
                        onTap: () {
                          Navigator.pop(context);
                          onSelectDashboard();
                        },
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Divider(color: AppColors.border, height: 1),
                      ),

                      // Item 6: Settings (Owner Only)
                      _buildDrawerTile(
                        context: context,
                        icon: Icons.settings_rounded,
                        title: locale.isBangla ? 'সেটিংস' : 'Settings',
                        subtitle: locale.isBangla
                            ? 'প্রোফাইল, ভাষা ও ব্যাকআপ'
                            : 'Profile, Backup & Config',
                        color: AppColors.textSecondary,
                        onTap: () {
                          Navigator.pop(context);
                          onSelectSettings();
                        },
                      ),
                    ] else ...[
                      // STAFF VIEW: Limited strictly to Stock & Attendance
                      // Stock / Inventory
                      _buildDrawerTile(
                        context: context,
                        icon: Icons.inventory_2_rounded,
                        title: locale.isBangla ? 'স্টক / ইনভেন্টরি' : 'Stock / Inventory',
                        subtitle: locale.isBangla
                            ? 'স্টক দেখুন ও পার্টস ইস্যু করুন'
                            : 'View Stock & Dispense Parts',
                        color: AppColors.warning,
                        onTap: () {
                          Navigator.pop(context);
                          onSelectInventory();
                        },
                      ),

                      // Staff Attendance
                      _buildDrawerTile(
                        context: context,
                        icon: Icons.badge_rounded,
                        title: locale.isBangla ? 'স্টাফ ও হাজিরা' : 'Staff & Attendance',
                        subtitle: locale.isBangla
                            ? 'দৈনিক কাজের উপস্থিতি'
                            : 'Daily Workshop Attendance',
                        color: AppColors.primaryDark,
                        onTap: () {
                          Navigator.pop(context);
                          onSelectStaff();
                        },
                      ),
                    ],

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Divider(color: AppColors.border, height: 1),
                    ),

                    // Switch User / Logout
                    _buildDrawerTile(
                      context: context,
                      icon: Icons.logout_rounded,
                      title: locale.isBangla
                          ? 'লগআউট / ইউজার পরিবর্তন'
                          : 'Switch User / Logout',
                      subtitle: locale.isBangla
                          ? 'বর্তমান অ্যাকাউন্ট থেকে বের হন'
                          : 'End session & return to login',
                      color: AppColors.danger,
                      onTap: () => _showLogoutDialog(context, repo, locale),
                    ),
                  ],
                ),
              ),
            ),

            // 3. DRAWER FOOTER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      locale.isBangla
                          ? 'গ্যারেজ অ্যাকাউন্টিং প্রো • সানলাইট ডিএস'
                          : 'Garage Accounting Pro • Sunlight DS',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minLeadingWidth: 0,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        minVerticalPadding: 2,
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeCount != null && badgeCount > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.warning,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textSecondary),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, GarageRepository repo, AppLocaleManager locale) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.danger),
            const SizedBox(width: 8),
            Text(
              locale.isBangla ? 'লগআউট করবেন?' : 'Switch User / Logout?',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
          ],
        ),
        content: Text(
          locale.isBangla
              ? 'আপনি কি বর্তমান অ্যাকাউন্ট সেশন বন্ধ করে লগইন স্ক্রিনে ফিরে যেতে চান?'
              : 'Are you sure you want to end the current user session and return to the login screen?',
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
            onPressed: () {
              Navigator.pop(dialogCtx);
              Navigator.of(context).popUntil((route) => route.isFirst);
              repo.logout();
            },
            child: Text(
              locale.isBangla ? 'লগআউট' : 'Logout',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
