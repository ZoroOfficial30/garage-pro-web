import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:garage_accounting_pro/core/currency/currency_manager.dart';
import 'package:garage_accounting_pro/core/localization/app_locale.dart';
import 'package:garage_accounting_pro/core/theme/app_theme.dart';
import 'package:garage_accounting_pro/data/models/employee.dart';
import 'package:garage_accounting_pro/data/models/attendance_record.dart';
import 'package:garage_accounting_pro/data/repositories/garage_repository.dart';
import 'package:garage_accounting_pro/features/employees/screens/employees_screen.dart';
import 'package:garage_accounting_pro/features/employees/widgets/monthly_attendance_modal.dart';

void main() {
  group('1. AttendanceRecord Model Tests', () {
    test('Serializes to map and deserializes from map correctly', () {
      final date = DateTime(2026, 9, 9);
      final markedAt = DateTime(2026, 9, 9, 8, 30);
      final record = AttendanceRecord(
        id: 'emp1_2026-09-09',
        employeeId: 'emp1',
        date: date,
        isPresent: true,
        markedAt: markedAt,
        note: 'On time',
        markedBy: 'Manager',
      );

      expect(record.dateKey, '2026-09-09');
      expect(record.monthKey, '2026-09');
      expect(record.dayOfMonth, 9);

      final map = record.toMap();
      expect(map['id'], 'emp1_2026-09-09');
      expect(map['isPresent'], isTrue);
      expect(map['note'], 'On time');

      final restored = AttendanceRecord.fromMap(map);
      expect(restored.id, record.id);
      expect(restored.employeeId, 'emp1');
      expect(restored.isPresent, isTrue);
      expect(restored.note, 'On time');
      expect(restored.markedBy, 'Manager');
    });

    test('copyWith updates properties accurately', () {
      final record = AttendanceRecord(
        id: 'r1',
        employeeId: 'e1',
        date: DateTime(2026, 9, 9),
        isPresent: true,
        markedAt: DateTime.now(),
      );

      final updated = record.copyWith(
        isPresent: false,
        note: 'Sick leave approved',
      );

      expect(updated.isPresent, isFalse);
      expect(updated.note, 'Sick leave approved');
      expect(updated.employeeId, 'e1');
    });
  });

  group('2. GarageRepository Attendance Tracking Tests', () {
    test('Marking attendance creates record and updates monthly summary', () async {
      final repo = GarageRepository();
      const empId = 'emp-test-1';

      // Mark 3 days present, 1 day absent in September 2026
      await repo.markAttendance(
        employeeId: empId,
        date: DateTime(2026, 9, 1),
        isPresent: true,
      );
      await repo.markAttendance(
        employeeId: empId,
        date: DateTime(2026, 9, 2),
        isPresent: true,
      );
      await repo.markAttendance(
        employeeId: empId,
        date: DateTime(2026, 9, 3),
        isPresent: false,
        note: 'Personal emergency',
      );
      await repo.markAttendance(
        employeeId: empId,
        date: DateTime(2026, 9, 4),
        isPresent: true,
      );

      final monthlyList = repo.getMonthlyAttendance(empId, 2026, 9);
      expect(monthlyList.length, 4);

      final summary = repo.getMonthlyAttendanceSummary(empId, 2026, 9);
      expect(summary['present'], 3);
      expect(summary['absent'], 1);
      expect(summary['totalMarked'], 4);
      expect(summary['daysInMonth'], 30); // September has 30 days
    });

    test('calculateProratedSalary accurately calculates prorated earnings', () {
      final repo = GarageRepository();
      final emp = Employee(
        id: 'emp-sal-1',
        name: 'Rashid Khan',
        role: 'Technician',
        phone: '123456',
        monthlySalary: 300.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // In September (30 days), 15 days present should equal 150.0 OMR
      for (int i = 1; i <= 15; i++) {
        repo.markAttendance(
          employeeId: emp.id,
          date: DateTime(2026, 9, i),
          isPresent: true,
        );
      }

      final prorated = repo.calculateProratedSalary(emp, 2026, 9);
      expect(prorated, closeTo(150.0, 0.01));
    });

    test('toggleAttendance switches today attendance status', () async {
      final repo = GarageRepository();
      const empId = 'emp-toggle-1';
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);

      // Mark present initially
      await repo.markAttendance(employeeId: empId, date: todayDate, isPresent: true);
      expect(repo.getAttendanceRecord(empId, todayDate)?.isPresent, isTrue);

      // Toggle to absent
      await repo.toggleAttendance(empId);
      expect(repo.getAttendanceRecord(empId, todayDate)?.isPresent, isFalse);

      // Toggle back to present
      await repo.toggleAttendance(empId);
      expect(repo.getAttendanceRecord(empId, todayDate)?.isPresent, isTrue);
    });

    test('markAllPresentToday bulk action marks all employees present', () async {
      final repo = GarageRepository();
      // Initially let's verify repo has employees from database or mock
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      await repo.markAllPresentToday();
      for (final emp in repo.employees) {
        expect(emp.isPresent, isTrue);
        final rec = repo.getAttendanceRecord(emp.id, today);
        expect(rec?.isPresent, isTrue);
      }
    });

    test('deleteAttendanceRecord removes record correctly', () async {
      final repo = GarageRepository();
      const empId = 'emp-del-1';
      final targetDate = DateTime(2026, 9, 15);

      await repo.markAttendance(employeeId: empId, date: targetDate, isPresent: true);
      expect(repo.getAttendanceRecord(empId, targetDate), isNotNull);

      await repo.deleteAttendanceRecord(empId, targetDate);
      expect(repo.getAttendanceRecord(empId, targetDate), isNull);
    });
  });

  group('3. Attendance Screen & Modal Widget Tests', () {
    Widget buildTestApp(Widget child, {GarageRepository? repository}) {
      final repo = repository ?? GarageRepository();
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: repo),
          ChangeNotifierProvider(create: (_) => CurrencyManager()),
          ChangeNotifierProvider(create: (_) => AppLocaleManager()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          home: child,
        ),
      );
    }

    testWidgets('EmployeesScreen renders Mark All Present and monthly summaries', (tester) async {
      final repo = GarageRepository();
      repo.setMockEmployees([
        Employee(
          id: 'emp-1',
          name: 'Sumon Ahmed',
          role: 'Head Mechanic',
          phone: '+880 1711-000002',
          monthlySalary: 350.0,
          isPresent: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);

      await tester.pumpWidget(buildTestApp(const EmployeesScreen(), repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Staff Directory'), findsOneWidget);
      expect(find.text('Mark All Present'), findsOneWidget);

      // Tap Mark All Present button to verify confirmation dialog
      await tester.ensureVisible(find.text('Mark All Present'));
      await tester.tap(find.text('Mark All Present'));
      await tester.pumpAndSettle();

      expect(find.text('Mark all active staff as present today?'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);

      // Confirm bulk action
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
    });

    testWidgets('MonthlyAttendanceModal renders calendar grid, KPIs and switches months', (tester) async {
      final repo = GarageRepository();
      final employee = Employee(
        id: 'emp-modal-test',
        name: 'Sumon Ahmed',
        role: 'Head Mechanic',
        phone: '+880 1711-000002',
        monthlySalary: 350.0,
        isPresent: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Seed 2 attendance days
      await repo.markAttendance(
        employeeId: employee.id,
        date: DateTime(2026, 9, 1),
        isPresent: true,
      );
      await repo.markAttendance(
        employeeId: employee.id,
        date: DateTime(2026, 9, 2),
        isPresent: false,
        note: 'Sick leave',
      );

      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => MonthlyAttendanceModal.show(context, employee),
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ),
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Check Header & KPIs
      expect(find.text('Sumon Ahmed'), findsOneWidget);
      expect(find.text('Head Mechanic'), findsOneWidget);
      expect(find.text('PRESENT'), findsOneWidget);
      expect(find.text('ABSENT'), findsOneWidget);
      expect(find.text('RATE'), findsOneWidget);
      expect(find.text('EST. EARNED'), findsOneWidget);

      // Check Calendar weekday headers
      expect(find.text('Sun'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);

      // Switch to List Log View
      final listViewIcon = find.byIcon(Icons.list_alt_rounded);
      expect(listViewIcon, findsOneWidget);
      await tester.tap(listViewIcon);
      await tester.pumpAndSettle();

      expect(find.text('Attendance Log History'), findsOneWidget);
    });
  });
}
