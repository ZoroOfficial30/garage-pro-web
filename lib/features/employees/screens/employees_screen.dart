import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/currency/currency_manager.dart';
import '../../../core/localization/app_locale.dart';
import '../../../data/models/employee.dart';
import '../../../data/repositories/garage_repository.dart';
import '../widgets/add_edit_employee_modal.dart';
import '../widgets/monthly_attendance_modal.dart';
import '../widgets/staff_login_management_modal.dart';
import '../../navigation/widgets/drawer_helper.dart';

class EmployeesScreen extends StatefulWidget {
  final bool isTab;

  const EmployeesScreen({super.key, this.isTab = false});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  void _confirmMarkAllPresent(BuildContext context, GarageRepository repo, AppLocaleManager locale) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.done_all_rounded, color: AppColors.success, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                locale.translate('mark_all_present'),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          locale.translate('mark_all_present_confirm'),
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(locale.translate('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await repo.markAllPresentToday();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(locale.translate('all_present_success')),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: Text(locale.translate('confirm')),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteEmployee(BuildContext context, Employee emp) {
    final repo = Provider.of<GarageRepository>(context, listen: false);
    final locale = Provider.of<AppLocaleManager>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                locale.isBangla ? 'কর্মচারী মুছে ফেলতে চান?' : 'Remove Staff Member?',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${emp.name}" (${emp.role}) from the workshop staff directory? This cannot be undone.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(locale.isBangla ? 'বাতিল' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await repo.deleteEmployee(emp.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed staff member: ${emp.name}'),
                    backgroundColor: AppColors.primaryDark,
                  ),
                );
              }
            },
            child: Text(locale.isBangla ? 'মুছে ফেলুন' : 'Delete'),
          ),
        ],
      ),
    );
  }

  void _showSalaryPaymentDialog(BuildContext context, Employee emp) {
    final repo = Provider.of<GarageRepository>(context, listen: false);
    final currency = Provider.of<CurrencyManager>(context, listen: false);
    final locale = Provider.of<AppLocaleManager>(context, listen: false);

    String paymentMethod = 'Cash';
    final amountCtrl = TextEditingController(text: emp.monthlySalary.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.payments_rounded, color: AppColors.success, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    locale.isBangla ? 'বেতন পরিশোধ করুন' : 'Record Salary Payment',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Employee: ${emp.name} (${emp.role})',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Payment Amount (${currency.currentInfo.symbol})',
                    prefixIcon: const Icon(Icons.attach_money_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Payment Method:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Row(
                  children: ['Cash', 'Bank Transfer', 'Card'].map((method) {
                    final isSel = paymentMethod == method;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(method, style: const TextStyle(fontSize: 12)),
                        selected: isSel,
                        selectedColor: AppColors.primaryLight,
                        onSelected: (_) => setDialogState(() => paymentMethod = method),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    '💡 This will mark salary as Paid and automatically record an expense under "Staff Salary".',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(locale.isBangla ? 'বাতিল' : 'Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final amount = double.tryParse(amountCtrl.text.trim()) ?? emp.monthlySalary;
                  Navigator.pop(ctx);
                  await repo.recordSalaryPayment(emp.id, amount, paymentMethod);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Paid ${currency.format(amount)} salary to ${emp.name}'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                child: Text(locale.isBangla ? 'পরিশোধ সম্পন্ন' : 'Confirm Payment'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<GarageRepository>(context);
    final currency = Provider.of<CurrencyManager>(context);
    final locale = Provider.of<AppLocaleManager>(context);

    final staff = repo.employees;
    final presentCount = staff.where((e) => e.isPresent).length;
    final unpaidStaff = staff.where((e) => !e.isSalaryPaid).toList();
    final totalUnpaidSalary = unpaidStaff.fold(0.0, (sum, e) => sum + e.monthlySalary);

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      drawer: buildAppDrawer(context),
      appBar: AppBar(
        title: Text(
          locale.isBangla ? 'কর্মচারী ও বেতন হিসাব' : 'Staff & Payroll Management',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 19,
            color: AppColors.primary,
          ),
        ),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                iconSize: 24,
                tooltip: 'Back',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () => Navigator.of(context).pop(),
              )
            : buildDrawerHamburgerButton(context),
        actions: [
          if (repo.isOwner)
            IconButton(
              tooltip: locale.isBangla ? 'স্টাফ লগইন ও পিন' : 'Staff Logins & PINs',
              icon: const Icon(Icons.lock_person_rounded, color: AppColors.primary),
              onPressed: () => StaffLoginManagementModal.show(context),
            ),
          if (repo.isOwner)
            IconButton(
              tooltip: 'Add Staff Member',
              icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary),
              onPressed: () => AddEditEmployeeModal.show(context),
            ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => repo.loadAllData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // KPI Summary Row
            Row(
              children: [
                // Card 1: Total Staff
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL TEAM',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${staff.length}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$presentCount on duty today',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Card 2: Unpaid Salary
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: unpaidStaff.isNotEmpty
                            ? AppColors.warning.withValues(alpha: 0.4)
                            : AppColors.border,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SALARY DUE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currency.format(totalUnpaidSalary),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: unpaidStaff.isNotEmpty ? AppColors.warning : AppColors.success,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${unpaidStaff.length} unpaid staff',
                          style: TextStyle(
                            fontSize: 11,
                            color: unpaidStaff.isNotEmpty ? AppColors.warning : AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Owner Staff Login Management Banner
            if (repo.isOwner) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.lock_person_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                locale.isBangla ? 'স্টাফ লগইন ও পিন কোড' : 'Staff Login & Access',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
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
                                ? '${staff.where((e) => e.isLoginEnabled).length}/${staff.length} জনের লগইন সক্রিয়'
                                : '${staff.where((e) => e.isLoginEnabled).length} of ${staff.length} staff login enabled',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.key_rounded, size: 14),
                      label: Text(
                        locale.isBangla ? 'ম্যানেজ পিন' : 'Manage Logins',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                      onPressed: () => StaffLoginManagementModal.show(context),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locale.isBangla ? 'কর্মচারী তালিকা' : 'Staff Directory',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${staff.length} Members',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (staff.isNotEmpty)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 1,
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.done_all_rounded, size: 18),
                    label: Text(
                      locale.translate('mark_all_present'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                    onPressed: () => _confirmMarkAllPresent(context, repo, locale),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            if (staff.isEmpty)
              Container(
                padding: const EdgeInsets.all(36),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.people_outline_rounded,
                          size: 56, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      const Text(
                        'No Staff Members Added Yet',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Add your mechanics, electricians, helpers, and car detailers.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => AddEditEmployeeModal.show(context),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add First Staff'),
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final emp in staff) ...[
                Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: Avatar, Name + Role, More Menu
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar (Photo or initials)
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryLight,
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: ClipOval(
                                child: emp.avatarBase64 != null && emp.avatarBase64!.isNotEmpty
                                    ? Image.memory(
                                        base64Decode(emp.avatarBase64!),
                                        fit: BoxFit.cover,
                                        width: 50,
                                        height: 50,
                                      )
                                    : Center(
                                        child: Text(
                                          emp.name.isNotEmpty ? emp.name[0].toUpperCase() : 'S',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Name & Role
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    emp.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: true,
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLight,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          emp.role,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (emp.phone.isNotEmpty)
                                        Text(
                                          emp.phone,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      if (repo.isOwner) ...[
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            Icon(
                                              emp.isLoginEnabled
                                                  ? Icons.check_circle_rounded
                                                  : Icons.block_rounded,
                                              size: 13,
                                              color: emp.isLoginEnabled
                                                  ? AppColors.success
                                                  : AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              emp.isLoginEnabled
                                                  ? (locale.isBangla
                                                      ? 'লগইন: সক্রিয় (পিন: ••••)'
                                                      : 'Login: Enabled (PIN: ••••)')
                                                  : (locale.isBangla
                                                      ? 'লগইন: বন্ধ'
                                                      : 'Login: Disabled'),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: emp.isLoginEnabled
                                                    ? AppColors.success
                                                    : AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        InkWell(
                                          onTap: () => StaffLoginManagementModal.showResetPinDialog(context, emp),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryLight,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.password_rounded, size: 14, color: AppColors.primary),
                                                const SizedBox(width: 6),
                                                Text(
                                                  locale.isBangla ? 'স্টাফ পিন রিসেট করুন' : 'Reset Staff PIN',
                                                  style: const TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // 3-dot popup menu
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onSelected: (val) {
                                if (val == 'reset_pin') {
                                  StaffLoginManagementModal.showResetPinDialog(context, emp);
                                } else if (val == 'attendance') {
                                  MonthlyAttendanceModal.show(context, emp);
                                } else if (val == 'login_pin') {
                                  StaffLoginManagementModal.show(context);
                                } else if (val == 'edit') {
                                  AddEditEmployeeModal.show(context, existingEmployee: emp);
                                } else if (val == 'delete') {
                                  _confirmDeleteEmployee(context, emp);
                                }
                              },
                              itemBuilder: (ctx) => [
                                if (repo.isOwner) ...[
                                  const PopupMenuItem(
                                    value: 'reset_pin',
                                    child: Row(
                                      children: [
                                        Icon(Icons.password_rounded, color: AppColors.primary, size: 18),
                                        SizedBox(width: 8),
                                        Text('Reset Staff PIN'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'login_pin',
                                    child: Row(
                                      children: [
                                        Icon(Icons.key_rounded, color: AppColors.primary, size: 18),
                                        SizedBox(width: 8),
                                        Text('Manage Login & PIN'),
                                      ],
                                    ),
                                  ),
                                ],
                                const PopupMenuItem(
                                  value: 'attendance',
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 18),
                                      SizedBox(width: 8),
                                      Text('Attendance History'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
                                      SizedBox(width: 8),
                                      Text('Edit Profile'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
                                      SizedBox(width: 8),
                                      Text('Remove Staff', style: TextStyle(color: AppColors.danger)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Large Touch-Friendly Today Attendance Toggle (Guarded against overflow)
                        InkWell(
                          onTap: () => repo.toggleAttendance(emp.id),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: emp.isPresent ? AppColors.successLight : AppColors.dangerLight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: emp.isPresent ? AppColors.success : AppColors.danger,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        emp.isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                        size: 22,
                                        color: emp.isPresent ? AppColors.success : AppColors.danger,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              emp.isPresent ? 'PRESENT TODAY' : 'ABSENT TODAY',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w900,
                                                color: emp.isPresent ? AppColors.success : AppColors.danger,
                                                letterSpacing: 0.5,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              emp.isPresent ? 'On Duty • Tap to switch' : 'Off Duty • Tap to switch',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: emp.isPresent
                                                    ? AppColors.success.withValues(alpha: 0.8)
                                                    : AppColors.danger.withValues(alpha: 0.8),
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.swap_horiz_rounded, size: 14, color: AppColors.textSecondary),
                                      SizedBox(width: 4),
                                      Text(
                                        'Switch',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Monthly Summary & Calendar Trigger
                        Builder(
                          builder: (context) {
                            final now = DateTime.now();
                            final attSummary = repo.getMonthlyAttendanceSummary(emp.id, now.year, now.month);
                            final presentDays = attSummary['present'] ?? 0;
                            final absentDays = attSummary['absent'] ?? 0;

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.date_range_rounded, size: 15, color: AppColors.textSecondary),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'Present: $presentDays days | Absent: $absentDays days',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => MonthlyAttendanceModal.show(context, emp),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.calendar_month_rounded, size: 13, color: AppColors.primary),
                                          SizedBox(width: 4),
                                          Text(
                                            'History',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),

                        // Middle details: Salary & Prorated earned (Expanded + FittedBox)
                        Builder(
                          builder: (context) {
                            final now = DateTime.now();
                            final proratedSalary = repo.calculateProratedSalary(emp, now.year, now.month);

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'MONTHLY SALARY',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textSecondary,
                                            letterSpacing: 0.4,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            currency.format(emp.monthlySalary),
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          'EST. EARNED',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textSecondary,
                                            letterSpacing: 0.4,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            currency.format(proratedSalary),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
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
                          },
                        ),
                        const SizedBox(height: 12),

                        // Bottom Action Row: Salary Status & Pay Button (Responsive Wrap)
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: emp.isSalaryPaid
                                        ? AppColors.successLight
                                        : AppColors.warningLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        emp.isSalaryPaid
                                            ? Icons.check_circle_outline_rounded
                                            : Icons.pending_outlined,
                                        size: 14,
                                        color: emp.isSalaryPaid
                                            ? AppColors.success
                                            : AppColors.warning,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        emp.isSalaryPaid ? 'SALARY PAID' : 'SALARY UNPAID',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: emp.isSalaryPaid
                                              ? AppColors.success
                                              : AppColors.warning,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (emp.isSalaryPaid && emp.lastSalaryPaidDate != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    'Paid ${DateFormat('MMM d').format(emp.lastSalaryPaidDate!)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            if (!emp.isSalaryPaid)
                              SizedBox(
                                height: 48,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: () => _showSalaryPaymentDialog(context, emp),
                                  icon: const Icon(Icons.payments_rounded, size: 15),
                                  label: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Pay Salary',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => AddEditEmployeeModal.show(context),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(
          locale.isBangla ? 'নতুন কর্মচারী' : '+ Add Staff',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
