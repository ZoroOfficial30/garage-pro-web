import 'package:hive_flutter/hive_flutter.dart';

class DatabaseService {
  static const String customersBoxName = 'customers_box';
  static const String stockItemsBoxName = 'stock_items_box';
  static const String transactionsBoxName = 'transactions_box';
  static const String expensesBoxName = 'expenses_box';
  static const String employeesBoxName = 'employees_box';
  static const String settingsBoxName = 'settings_box';
  static const String bayJobsBoxName = 'bay_jobs_box';
  static const String attendanceBoxName = 'attendance_box';
  static const String supplierDuesBoxName = 'supplier_dues_box';

  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  late Box<Map> customersBox;
  late Box<Map> stockItemsBox;
  late Box<Map> transactionsBox;
  late Box<Map> expensesBox;
  late Box<Map> employeesBox;
  late Box<dynamic> settingsBox;
  late Box<Map> bayJobsBox;
  late Box<Map> attendanceBox;
  late Box<Map> supplierDuesBox;

  Future<void> init() async {
    await Hive.initFlutter();

    customersBox = await Hive.openBox<Map>(customersBoxName);
    stockItemsBox = await Hive.openBox<Map>(stockItemsBoxName);
    transactionsBox = await Hive.openBox<Map>(transactionsBoxName);
    expensesBox = await Hive.openBox<Map>(expensesBoxName);
    employeesBox = await Hive.openBox<Map>(employeesBoxName);
    settingsBox = await Hive.openBox<dynamic>(settingsBoxName);
    bayJobsBox = await Hive.openBox<Map>(bayJobsBoxName);
    attendanceBox = await Hive.openBox<Map>(attendanceBoxName);
    supplierDuesBox = await Hive.openBox<Map>(supplierDuesBoxName);

    final dynamic setupVal = settingsBox.get('garage_setup_completed');
    if (setupVal == null) {
      final isFresh = customersBox.isEmpty && stockItemsBox.isEmpty;
      await settingsBox.put('garage_setup_completed', !isFresh);
    }

    // Always purge any legacy demo data from previous runs if present
    await purgeLegacyDemoData();
  }

  Future<void> purgeLegacyDemoData() async {
    const demoCustomerNames = {
      'Karim Chowdhury',
      'David Miller',
      'Ahmed Al-Mansoor',
      'Subhashis Roy',
    };

    final customerKeysToRemove = <dynamic>[];
    for (final entry in customersBox.toMap().entries) {
      final map = entry.value;
      if (demoCustomerNames.contains(map['name'])) {
        customerKeysToRemove.add(entry.key);
      }
    }
    for (final key in customerKeysToRemove) {
      await customersBox.delete(key);
    }

    final demoJobCustomerNames = {'Karim Chowdhury', 'Rahim Ullah', 'David Miller'};
    final jobKeysToRemove = <dynamic>[];
    for (final entry in bayJobsBox.toMap().entries) {
      final map = entry.value;
      if (demoJobCustomerNames.contains(map['customerName'])) {
        jobKeysToRemove.add(entry.key);
      }
    }
    for (final key in jobKeysToRemove) {
      await bayJobsBox.delete(key);
    }

    final txKeysToRemove = <dynamic>[];
    for (final entry in transactionsBox.toMap().entries) {
      final map = entry.value;
      final desc = map['description']?.toString() ?? '';
      final cName = map['customerName']?.toString() ?? '';
      if (demoCustomerNames.contains(cName) ||
          desc.contains('Bay 2 (Job #104)') ||
          desc.contains('Walk-in (Prado)') ||
          desc.contains('Walk-in (Camry)')) {
        txKeysToRemove.add(entry.key);
      }
    }
    for (final key in txKeysToRemove) {
      await transactionsBox.delete(key);
    }

    final demoExpTitles = {
      'Torque Wrench Calibration & Socket Set',
      'Staff Lunch & Afternoon Chai/Snacks',
      'Workshop Electricity Bill',
      'Heavy Industrial Degreaser (20L Drum)',
    };
    final expKeysToRemove = <dynamic>[];
    for (final entry in expensesBox.toMap().entries) {
      final map = entry.value;
      if (demoExpTitles.contains(map['title'])) {
        expKeysToRemove.add(entry.key);
      }
    }
    for (final key in expKeysToRemove) {
      await expensesBox.delete(key);
    }

    final demoSupplierCompanies = {
      'Castrol Lubricants Oman',
      'Mann-Filter Middle East',
      'Bosch Auto Parts Oman',
    };
    final supplierKeysToRemove = <dynamic>[];
    for (final entry in supplierDuesBox.toMap().entries) {
      final map = entry.value;
      if (demoSupplierCompanies.contains(map['companyName'])) {
        supplierKeysToRemove.add(entry.key);
      }
    }
    for (final key in supplierKeysToRemove) {
      await supplierDuesBox.delete(key);
    }
  }

  Future<void> seedInitialData() async {}
  Future<void> seedEmployees() async {}
  Future<void> seedBayJobs() async {}
  Future<void> seedAttendance() async {}
  Future<void> seedSupplierDues() async {}
}


