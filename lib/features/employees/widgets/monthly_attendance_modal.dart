import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/currency/currency_manager.dart';
import '../../../core/localization/app_locale.dart';
import '../../../data/models/employee.dart';
import '../../../data/models/attendance_record.dart';
import '../../../data/repositories/garage_repository.dart';

class MonthlyAttendanceModal extends StatefulWidget {
  final Employee employee;

  const MonthlyAttendanceModal({super.key, required this.employee});

  static Future<void> show(BuildContext context, Employee employee) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MonthlyAttendanceModal(employee: employee),
    );
  }

  @override
  State<MonthlyAttendanceModal> createState() => _MonthlyAttendanceModalState();
}

class _MonthlyAttendanceModalState extends State<MonthlyAttendanceModal> {
  late DateTime _selectedMonth;
  bool _isCalendarView = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    });
  }

  void _goToCurrentMonth() {
    final now = DateTime.now();
    setState(() {
      _selectedMonth = DateTime(now.year, now.month, 1);
    });
  }

  void _showEditDayDialog(
    BuildContext context,
    GarageRepository repo,
    AppLocaleManager locale,
    DateTime targetDate,
    AttendanceRecord? existing,
  ) {
    bool isPresent = existing?.isPresent ?? true;
    final noteCtrl = TextEditingController(text: existing?.note ?? '');
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(targetDate);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_calendar_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale.isBangla ? 'উপস্থিতি পরিবর্তন করুন' : 'Edit Attendance',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                      ),
                      Text(
                        dateStr,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Staff: ${widget.employee.name}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),

                  // Present / Absent Segmented Toggle
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setDlgState(() => isPresent = true),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isPresent ? AppColors.success : AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isPresent ? AppColors.success : AppColors.border,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 18,
                                  color: isPresent ? Colors.white : AppColors.success,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  locale.isBangla ? 'উপস্থিত' : 'PRESENT',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: isPresent ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => setDlgState(() => isPresent = false),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !isPresent ? AppColors.danger : AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: !isPresent ? AppColors.danger : AppColors.border,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cancel_rounded,
                                  size: 18,
                                  color: !isPresent ? Colors.white : AppColors.danger,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  locale.isBangla ? 'অনুপস্থিত' : 'ABSENT',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: !isPresent ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Optional Notes
                  TextField(
                    controller: noteCtrl,
                    decoration: InputDecoration(
                      labelText: locale.isBangla ? 'মন্তব্য / কারণ (ঐচ্ছিক)' : 'Reason / Note (Optional)',
                      hintText: 'e.g. Sick Leave, Half Day, Emergency',
                      prefixIcon: const Icon(Icons.notes_rounded),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(locale.translate('cancel')),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.save_rounded, size: 18),
                label: Text(locale.translate('confirm')),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await repo.markAttendance(
                    employeeId: widget.employee.id,
                    date: targetDate,
                    isPresent: isPresent,
                    note: noteCtrl.text.trim(),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Attendance updated for ${DateFormat('dd MMM').format(targetDate)} (${isPresent ? 'Present' : 'Absent'})',
                        ),
                        backgroundColor: AppColors.primaryDark,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
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

    // Refresh current employee data from repo
    final employee = repo.getEmployeeById(widget.employee.id) ?? widget.employee;

    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    final monthName = DateFormat('MMMM yyyy').format(_selectedMonth);
    final summary = repo.getMonthlyAttendanceSummary(employee.id, year, month);
    final presentCount = summary['present'] ?? 0;
    final absentCount = summary['absent'] ?? 0;
    final totalMarked = summary['totalMarked'] ?? 0;
    final daysInMonth = summary['daysInMonth'] ?? 30;

    final attendanceRate = totalMarked > 0
        ? ((presentCount / totalMarked) * 100).toStringAsFixed(0)
        : '0';

    final proratedSalary = repo.calculateProratedSalary(employee, year, month);

    final monthlyRecords = repo.getMonthlyAttendance(employee.id, year, month);
    final now = DateTime.now();
    final isCurrentMonth = now.year == year && now.month == month;

    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.90,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              children: [
                // Staff avatar
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                  ),
                  child: ClipOval(
                    child: employee.avatarBase64 != null
                        ? Image.memory(
                            base64Decode(employee.avatarBase64!),
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Text(
                              employee.name.isNotEmpty ? employee.name[0].toUpperCase() : 'E',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              employee.role,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Salary: ${currency.format(employee.monthlySalary)}/mo',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                          ),
                        ],
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

          // Month Navigator Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 28),
                  tooltip: 'Previous Month',
                  onPressed: _previousMonth,
                ),
                InkWell(
                  onTap: isCurrentMonth ? null : _goToCurrentMonth,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          monthName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                        ),
                        if (!isCurrentMonth) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Current',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 28),
                  tooltip: 'Next Month',
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),

          // Monthly Summary KPIs Card
          Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                // Present Days
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'PRESENT',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$presentCount',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.success),
                      ),
                      Text(
                        'days',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 32, color: AppColors.border),

                // Absent Days
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'ABSENT',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$absentCount',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: absentCount > 0 ? AppColors.danger : AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'days',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 32, color: AppColors.border),

                // Rate
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'RATE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$attendanceRate%',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
                      ),
                      Text(
                        'attendance',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 32, color: AppColors.border),

                // Prorated Salary
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'EST. EARNED',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currency.format(proratedSalary),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'prorated',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // View Switcher (Calendar vs List)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isCalendarView ? 'Monthly Calendar (Tap to Edit)' : 'Attendance Log History',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.calendar_view_month_rounded,
                        color: _isCalendarView ? AppColors.primary : AppColors.textSecondary,
                        size: 22,
                      ),
                      tooltip: 'Calendar Grid',
                      onPressed: () => setState(() => _isCalendarView = true),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.list_alt_rounded,
                        color: !_isCalendarView ? AppColors.primary : AppColors.textSecondary,
                        size: 22,
                      ),
                      tooltip: 'List View',
                      onPressed: () => setState(() => _isCalendarView = false),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content Area
          Expanded(
            child: _isCalendarView
                ? _buildCalendarGrid(context, repo, locale, employee, year, month, daysInMonth, now)
                : _buildLogList(context, repo, locale, employee, monthlyRecords),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildCalendarGrid(
    BuildContext context,
    GarageRepository repo,
    AppLocaleManager locale,
    Employee employee,
    int year,
    int month,
    int daysInMonth,
    DateTime now,
  ) {
    // Weekday labels: Sun, Mon, Tue, Wed, Thu, Fri, Sat
    final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final firstDayOfWeek = DateTime(year, month, 1).weekday % 7; // 0 for Sun, 1 for Mon...

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Weekday header row
          Row(
            children: weekdays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Days Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 1.0,
              ),
              itemCount: firstDayOfWeek + daysInMonth,
              itemBuilder: (context, index) {
                if (index < firstDayOfWeek) {
                  return const SizedBox.shrink();
                }

                final day = index - firstDayOfWeek + 1;
                final cellDate = DateTime(year, month, day);
                final isToday = now.year == year && now.month == month && now.day == day;
                final isFuture = cellDate.isAfter(DateTime(now.year, now.month, now.day));

                final record = repo.getAttendanceRecord(employee.id, cellDate);
                final hasRecord = record != null;
                final isPresent = record?.isPresent ?? false;

                Color bgColor;
                Color textColor;
                Color borderColor;
                Widget? statusIcon;

                if (!hasRecord) {
                  bgColor = isFuture ? AppColors.surface.withValues(alpha: 0.5) : AppColors.surface;
                  textColor = isFuture ? AppColors.textSecondary.withValues(alpha: 0.4) : AppColors.textPrimary;
                  borderColor = isToday ? AppColors.primary : AppColors.border;
                } else if (isPresent) {
                  bgColor = AppColors.successLight;
                  textColor = AppColors.success;
                  borderColor = isToday ? AppColors.primary : AppColors.success.withValues(alpha: 0.4);
                  statusIcon = const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success);
                } else {
                  bgColor = AppColors.dangerLight;
                  textColor = AppColors.danger;
                  borderColor = isToday ? AppColors.primary : AppColors.danger.withValues(alpha: 0.4);
                  statusIcon = const Icon(Icons.cancel_rounded, size: 14, color: AppColors.danger);
                }

                return InkWell(
                  onTap: () => _showEditDayDialog(context, repo, locale, cellDate, record),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: borderColor,
                        width: isToday ? 2.0 : 1.0,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 4,
                          left: 6,
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isToday ? FontWeight.w900 : FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                        ),
                        if (statusIcon != null)
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: statusIcon,
                          ),
                        if (record?.note.isNotEmpty == true)
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: AppColors.warning,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList(
    BuildContext context,
    GarageRepository repo,
    AppLocaleManager locale,
    Employee employee,
    List<AttendanceRecord> records,
  ) {
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy_rounded, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 10),
            Text(
              'No attendance logged for ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final sorted = List<AttendanceRecord>.from(records)
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: sorted.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final rec = sorted[index];
        final dateStr = DateFormat('EEE, d MMMM yyyy').format(rec.date);
        final timeStr = DateFormat('hh:mm a').format(rec.markedAt);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: rec.isPresent ? AppColors.successLight : AppColors.dangerLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  rec.isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: rec.isPresent ? AppColors.success : AppColors.danger,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateStr,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          rec.isPresent ? 'Present' : 'Absent',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: rec.isPresent ? AppColors.success : AppColors.danger,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• Marked at $timeStr',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    if (rec.note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Note: ${rec.note}',
                        style: const TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                tooltip: 'Edit',
                onPressed: () => _showEditDayDialog(context, repo, locale, rec.date, rec),
              ),
            ],
          ),
        );
      },
    );
  }
}
