import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../database/database_service.dart';
import '../models/customer.dart';
import '../models/stock_item.dart';
import '../models/transaction_record.dart';
import '../models/expense_record.dart';
import '../models/bay_job.dart';
import '../models/employee.dart';
import '../models/attendance_record.dart';
import '../models/supplier_due.dart';
import '../models/app_user.dart';
import '../services/backup_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/services/biometric_auth_service.dart';

class DailyIncomeBreakdown {
  final double carWashIncome;
  final int carWashCount;
  final double settlePaymentIncome;
  final int settlePaymentCount;
  final double otherIncome;
  final int otherIncomeCount;
  final double totalIncome;
  final List<TransactionRecord> transactions;

  DailyIncomeBreakdown({
    required this.carWashIncome,
    required this.carWashCount,
    required this.settlePaymentIncome,
    required this.settlePaymentCount,
    required this.otherIncome,
    required this.otherIncomeCount,
    required this.totalIncome,
    required this.transactions,
  });
}

class DailyExpenseBreakdown {
  final Map<String, double> categoryTotals;
  final double totalExpense;
  final List<ExpenseRecord> expenses;

  DailyExpenseBreakdown({
    required this.categoryTotals,
    required this.totalExpense,
    required this.expenses,
  });
}

class DayCloseRecord {
  final String dateKey; // 'yyyy-MM-dd'
  final DateTime date;
  final DateTime closedAt;
  final double totalIncome;
  final double totalExpense;
  final double netAmount;
  final double carWashIncome;
  final int carWashCount;
  final double settlePaymentIncome;
  final int settlePaymentCount;
  final double otherIncome;
  final int otherIncomeCount;
  final Map<String, double> categoryExpenses;
  final String closedBy;
  final String notes;

  DayCloseRecord({
    required this.dateKey,
    required this.date,
    required this.closedAt,
    required this.totalIncome,
    required this.totalExpense,
    required this.netAmount,
    required this.carWashIncome,
    required this.carWashCount,
    required this.settlePaymentIncome,
    required this.settlePaymentCount,
    required this.otherIncome,
    required this.otherIncomeCount,
    required this.categoryExpenses,
    this.closedBy = 'Manager',
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'dateKey': dateKey,
      'date': date.toIso8601String(),
      'closedAt': closedAt.toIso8601String(),
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'netAmount': netAmount,
      'carWashIncome': carWashIncome,
      'carWashCount': carWashCount,
      'settlePaymentIncome': settlePaymentIncome,
      'settlePaymentCount': settlePaymentCount,
      'otherIncome': otherIncome,
      'otherIncomeCount': otherIncomeCount,
      'categoryExpenses': categoryExpenses,
      'closedBy': closedBy,
      'notes': notes,
    };
  }

  factory DayCloseRecord.fromMap(Map<dynamic, dynamic> map) {
    final catExp = <String, double>{};
    if (map['categoryExpenses'] != null) {
      (map['categoryExpenses'] as Map).forEach((k, v) {
        catExp[k.toString()] = (v is num) ? v.toDouble() : 0.0;
      });
    }

    return DayCloseRecord(
      dateKey: map['dateKey'] ?? '',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      closedAt: DateTime.tryParse(map['closedAt']?.toString() ?? '') ?? DateTime.now(),
      totalIncome: (map['totalIncome'] as num?)?.toDouble() ?? 0.0,
      totalExpense: (map['totalExpense'] as num?)?.toDouble() ?? 0.0,
      netAmount: (map['netAmount'] as num?)?.toDouble() ?? 0.0,
      carWashIncome: (map['carWashIncome'] as num?)?.toDouble() ?? 0.0,
      carWashCount: (map['carWashCount'] as num?)?.toInt() ?? 0,
      settlePaymentIncome: (map['settlePaymentIncome'] as num?)?.toDouble() ?? 0.0,
      settlePaymentCount: (map['settlePaymentCount'] as num?)?.toInt() ?? 0,
      otherIncome: (map['otherIncome'] as num?)?.toDouble() ?? 0.0,
      otherIncomeCount: (map['otherIncomeCount'] as num?)?.toInt() ?? 0,
      categoryExpenses: catExp,
      closedBy: map['closedBy']?.toString() ?? 'Manager',
      notes: map['notes']?.toString() ?? '',
    );
  }
}

class DailyCashFlow {
  final DateTime date;
  final String dayLabel;
  final double income;
  final double expense;
  final bool isToday;

  DailyCashFlow({
    required this.date,
    required this.dayLabel,
    required this.income,
    required this.expense,
    required this.isToday,
  });
}

class UndoActionItem {
  final String actionId;
  final String title;
  final String description;
  final String type; // 'due', 'payment', 'stock_out', 'expense', 'job', 'bay_job_status'
  final dynamic payload;
  final DateTime timestamp;

  UndoActionItem({
    required this.actionId,
    required this.title,
    required this.description,
    required this.type,
    required this.payload,
    required this.timestamp,
  });
}

class GarageRepository extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  late final BackupService _backupService = BackupService(db: _db);
  final Uuid _uuid = const Uuid();

  GarageRepository() {
    try {
      SyncService().attachRepository(this);
    } catch (_) {}
  }

  void _triggerAutoSync() {
    try {
      SyncService().pushUnsyncedData();
    } catch (_) {}
  }

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isOwner => _currentUser == null ? true : _currentUser!.isOwner;
  bool get isStaff => _currentUser?.isStaff ?? false;
  String get ownerPin => _getSetting('pin_code', '1234') as String;
  bool get isGarageSetupCompleted => _getSetting('garage_setup_completed', true) as bool;
  bool _isAppLocked = false;
  bool get isAppLocked => _isAppLocked;

  void lockApp() {
    if (_currentUser != null && !_isAppLocked) {
      _isAppLocked = true;
      notifyListeners();
    }
  }

  void unlockApp() {
    if (_isAppLocked) {
      _isAppLocked = false;
      notifyListeners();
    }
  }

  Future<void> setGarageSetupCompleted(bool completed) async {
    await _putSetting('garage_setup_completed', completed);
    notifyListeners();
  }

  Future<void> completeFreshSetup({
    required String name,
    required String pin,
  }) async {
    final cleanPin = pin.trim().isNotEmpty ? pin.trim() : '1234';
    final cleanName = name.trim().isNotEmpty ? name.trim() : 'Apex Auto Workshop';

    await updateWorkshopProfile(
      name: cleanName,
      phone: workshopProfile['phone'] ?? '+880 1711-234567',
      taxId: workshopProfile['taxId'] ?? 'VAT-89210-AUTO',
      address: workshopProfile['address'] ?? 'Industrial Bay 4, Workshop St',
    );
    await setOwnerPin(cleanPin);
    await _putSetting('garage_setup_completed', true);
    await loadAllData();
    await loginOwner(cleanPin);
    _triggerAutoSync();
    notifyListeners();
  }

  Future<void> completeCloudRestoreSetup() async {
    await _putSetting('garage_setup_completed', true);
    await loadAllData();
    await loginOwner(ownerPin);
    notifyListeners();
  }

  List<Customer> _customers = [];
  List<StockItem> _stockItems = [];
  List<TransactionRecord> _transactions = [];
  List<ExpenseRecord> _expenses = [];
  List<BayJob> _bayJobs = [];
  List<Employee> _employees = [];
  List<SupplierDue> _supplierDues = [];
  Map<String, DayCloseRecord> _closedDays = {};
  Map<String, AttendanceRecord> _attendanceMap = {};

  UndoActionItem? _lastUndoAction;
  Timer? _undoTimer;
  int _undoCountdown = 5;

  List<Customer> get customers => _customers;
  List<StockItem> get stockItems => _stockItems;
  List<TransactionRecord> get transactions => _transactions;
  List<ExpenseRecord> get expenses => _expenses;
  List<BayJob> get bayJobs => _bayJobs;
  List<Employee> get employees => _employees;
  List<SupplierDue> get supplierDues => List.unmodifiable(_supplierDues);
  Map<String, DayCloseRecord> get closedDays => _closedDays;
  Map<String, AttendanceRecord> get attendanceMap => _attendanceMap;

  String dayKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
  bool isDayClosed(DateTime date) => _closedDays.containsKey(dayKey(date));
  DayCloseRecord? getDayCloseRecord(DateTime date) => _closedDays[dayKey(date)];

  UndoActionItem? get lastUndoAction => _lastUndoAction;
  int get undoCountdown => _undoCountdown;

  double get totalOutstandingDues =>
      _customers.fold(0.0, (sum, c) => sum + c.totalDue);

  double get totalOutstandingSupplierDues =>
      _supplierDues.fold(0.0, (sum, d) => sum + d.dueAmount);

  double get totalPaidSupplierDues =>
      _supplierDues.fold(0.0, (sum, d) => sum + d.paidAmount);

  int get pendingSupplierDuesCount =>
      _supplierDues.where((d) => !d.isFullyPaid).length;

  double get todayIncome {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.isIncome &&
            t.date.year == now.year &&
            t.date.month == now.month &&
            t.date.day == now.day)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get todayExpense {
    final now = DateTime.now();
    return _expenses
        .where((e) =>
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  int get lowStockCount =>
      _stockItems.where((s) => s.isLowStock || s.isOutOfStock).length;

  List<StockItem> get lowStockItems =>
      _stockItems.where((s) => s.isLowStock || s.isOutOfStock).toList();

  int get todaySettledJobsCount {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.isPayment &&
            t.date.year == now.year &&
            t.date.month == now.month &&
            t.date.day == now.day)
        .length;
  }

  Future<void> loadAllData() async {
    try {
      _customers = _db.customersBox.values
          .map((m) => Customer.fromMap(m))
          .toList()
        ..sort((a, b) => b.totalDue.compareTo(a.totalDue));

      _stockItems = _db.stockItemsBox.values
          .map((m) => StockItem.fromMap(m))
          .toList()
        ..sort((a, b) => a.quantity.compareTo(b.quantity));

      _transactions = _db.transactionsBox.values
          .map((m) => TransactionRecord.fromMap(m))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      _expenses = _db.expensesBox.values
          .map((m) => ExpenseRecord.fromMap(m))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      _bayJobs = _db.bayJobsBox.values
          .map((m) => BayJob.fromMap(m))
          .toList()
        ..sort((a, b) => a.bayNumber.compareTo(b.bayNumber));

      _employees = _db.employeesBox.values
          .map((m) => Employee.fromMap(m))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      _supplierDues = _db.supplierDuesBox.values
          .map((m) => SupplierDue.fromMap(m))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      final closeMap = <String, DayCloseRecord>{};
      for (final k in _db.settingsBox.keys) {
        if (k.toString().startsWith('day_close_')) {
          final val = _db.settingsBox.get(k);
          if (val is Map) {
            final rec = DayCloseRecord.fromMap(val);
            closeMap[rec.dateKey] = rec;
          }
        }
      }
      _closedDays = closeMap;
    } catch (_) {}

    final attMap = <String, AttendanceRecord>{};
    try {
      for (final val in _db.attendanceBox.values) {
        final rec = AttendanceRecord.fromMap(val);
        attMap['${rec.employeeId}_${rec.dateKey}'] = rec;
      }
    } catch (_) {}
    _attendanceMap = attMap;

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    for (int i = 0; i < _employees.length; i++) {
      final emp = _employees[i];
      final key = '${emp.id}_$todayStr';
      if (_attendanceMap.containsKey(key)) {
        final rec = _attendanceMap[key]!;
        if (emp.isPresent != rec.isPresent) {
          _employees[i] = emp.copyWith(isPresent: rec.isPresent);
        }
      }
    }

    try {
      final savedSession = _db.settingsBox.get('active_user_session');
      if (savedSession is Map) {
        _currentUser = AppUser.fromMap(savedSession);
      }
    } catch (_) {}

    notifyListeners();
  }

  Customer? getCustomerById(String id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  List<TransactionRecord> getTransactionsForCustomer(String customerId, String customerName) {
    final nameLower = customerName.trim().toLowerCase();
    final list = _transactions.where((t) {
      if (t.customerId != null && t.customerId == customerId) return true;
      return t.customerName.trim().toLowerCase() == nameLower;
    }).toList();

    // If customer has an initial due / balance and no opening due transaction exists in list, synthesize or show it
    final cust = getCustomerById(customerId) ?? _customers.where((c) => c.name.toLowerCase() == nameLower).firstOrNull;
    if (cust != null && cust.totalBilled > 0) {
      final hasOpeningTx = list.any((t) =>
          t.description.toLowerCase().contains('opening due') ||
          t.description.toLowerCase().contains('opening balance'));
      if (!hasOpeningTx && list.isEmpty) {
        list.add(TransactionRecord(
          id: 'opening_${cust.id}',
          customerId: cust.id,
          customerName: cust.name,
          type: 'due',
          amount: cust.totalBilled,
          runningBalance: cust.totalDue,
          description: 'Opening Due',
          paymentMethod: 'credit',
          date: cust.createdAt,
          createdAt: cust.createdAt,
          updatedAt: cust.updatedAt,
        ));
      }
    }

    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<void> createCustomer(Customer customer) async {
    try {
      await _db.customersBox.put(customer.id, customer.toMap());
    } catch (_) {}
    _triggerAutoSync();
    _customers.removeWhere((c) => c.id == customer.id);
    _customers.insert(0, customer);

    if (customer.totalDue > 0) {
      final tx = TransactionRecord(
        id: _uuid.v4(),
        customerId: customer.id,
        customerName: customer.name,
        type: 'due',
        amount: customer.totalDue,
        runningBalance: customer.totalDue,
        description: 'Opening Due',
        paymentMethod: 'credit',
        date: customer.createdAt,
        createdAt: customer.createdAt,
        updatedAt: customer.updatedAt,
      );
      try {
        await _db.transactionsBox.put(tx.id, tx.toMap());
      } catch (_) {}
      _triggerAutoSync();
      _transactions.removeWhere((t) => t.id == tx.id);
      _transactions.insert(0, tx);
    }

    try {
      await loadAllData();
    } catch (_) {
      notifyListeners();
    }
    _triggerAutoSync();
  }

  Future<void> addCustomer(Customer customer) => createCustomer(customer);

  StockItem? getStockItemById(String id) {
    try {
      return _stockItems.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> createStockItem(StockItem item) async {
    try {
      await _db.stockItemsBox.put(item.id, item.toMap());
      await loadAllData();
      _triggerAutoSync();
    } catch (_) {
      _stockItems.insert(0, item);
      notifyListeners();
    }
  }

  Future<void> updateStockItem(StockItem item) async {
    await _db.stockItemsBox.put(item.id, item.toMap());
    await loadAllData();
    _triggerAutoSync();
  }

  Future<void> deleteStockItem(String id) async {
    await _db.stockItemsBox.delete(id);
    await loadAllData();
    _triggerAutoSync();
    try {
      unawaited(SyncService().deleteRemoteStockItem(id));
    } catch (_) {}
  }

  void _triggerUndoWindow(UndoActionItem action) {
    _undoTimer?.cancel();
    _lastUndoAction = action;
    _undoCountdown = 5;
    notifyListeners();

    _undoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_undoCountdown > 1) {
        _undoCountdown--;
        notifyListeners();
      } else {
        _clearUndoWindow();
      }
    });
  }

  void _clearUndoWindow() {
    _undoTimer?.cancel();
    _undoTimer = null;
    _lastUndoAction = null;
    _undoCountdown = 5;
    notifyListeners();
  }

  void clearUndoWindow() => _clearUndoWindow();

  @override
  void dispose() {
    _undoTimer?.cancel();
    _undoTimer = null;
    super.dispose();
  }

  // --- ACTIONS WITH UNDO SUPPORT ---

  Future<void> updateCustomer(Customer customer) async {
    try {
      await _db.customersBox.put(customer.id, customer.toMap());
    } catch (_) {}
    _triggerAutoSync();
    final idx = _customers.indexWhere((c) => c.id == customer.id);
    if (idx >= 0) {
      _customers[idx] = customer;
    } else {
      _customers.insert(0, customer);
    }
    await loadAllData();
    notifyListeners();
  }

  Future<void> deleteCustomer(String customerId) async {
    if (!isOwner) {
      debugPrint('Permission denied: Only Owner can delete customers.');
      return;
    }
    final customer = getCustomerById(customerId) ??
        _customers.where((c) => c.id == customerId).firstOrNull;
    if (customer == null) {
      try {
        await _db.customersBox.delete(customerId);
      } catch (_) {}
      _customers.removeWhere((c) => c.id == customerId);
      notifyListeners();
      _triggerAutoSync();
      try {
        SyncService().deleteRemoteCustomer(customerId);
      } catch (_) {}
      return;
    }

    final relatedTxs = _transactions.where((t) {
      if (t.customerId != null && t.customerId == customerId) return true;
      return t.customerName.trim().toLowerCase() == customer.name.trim().toLowerCase();
    }).toList();

    try {
      await _db.customersBox.delete(customerId);
    } catch (_) {}
    _customers.removeWhere((c) => c.id == customerId);

    for (final tx in relatedTxs) {
      try {
        await _db.transactionsBox.delete(tx.id);
      } catch (_) {}
      _transactions.removeWhere((t) => t.id == tx.id);
    }

    _triggerUndoWindow(UndoActionItem(
      actionId: customerId,
      title: 'Customer Deleted',
      description: '${customer.name} and records removed',
      type: 'customer_delete',
      payload: {
        'customer': customer.toMap(),
        'transactions': relatedTxs.map((t) => t.toMap()).toList(),
      },
      timestamp: DateTime.now(),
    ));

    notifyListeners();
    _triggerAutoSync();
    try {
      SyncService().deleteRemoteCustomer(customerId);
    } catch (_) {}
  }

  Future<void> addDue({
    required String customerName,
    required double amount,
    String? customerId,
    String? vehicleModel,
    String? phone,
    String description = 'Service / Parts Due Added',
    bool createNewCustomer = false,
  }) async {
    Customer customer;
    if (createNewCustomer) {
      customer = _createNewCustomerRecord(customerName, phone, vehicleModel);
    } else if (customerId != null) {
      final existing = getCustomerById(customerId);
      customer = existing ??
          (findCustomerByQuery(customerName) ??
              _createNewCustomerRecord(customerName, phone, vehicleModel));
    } else {
      customer = findCustomerByQuery(customerName) ??
          _createNewCustomerRecord(customerName, phone, vehicleModel);
    }

    final updatedDue = customer.totalDue + amount;
    final updatedBilled = customer.totalBilled + amount;
    final updatedCust = customer.copyWith(
      totalDue: updatedDue,
      totalBilled: updatedBilled,
      updatedAt: DateTime.now(),
    );
    await _db.customersBox.put(updatedCust.id, updatedCust.toMap());

    final tx = TransactionRecord(
      id: _uuid.v4(),
      customerId: customer.id,
      customerName: customer.name,
      type: 'due',
      amount: amount,
      runningBalance: updatedDue,
      description: description,
      paymentMethod: 'credit',
      date: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _db.transactionsBox.put(tx.id, tx.toMap());

    await loadAllData();

    _triggerUndoWindow(UndoActionItem(
      actionId: tx.id,
      title: 'Due Added',
      description: '+$amount OMR for ${customer.name}',
      type: 'due',
      payload: {'transactionId': tx.id, 'customerId': customer.id, 'amount': amount},
      timestamp: DateTime.now(),
    ));
    _triggerAutoSync();
  }

  Customer? findCustomerByQuery(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return null;
    final q = trimmed.toLowerCase();

    // 1. Direct ID match
    for (final c in _customers) {
      if (c.id.toLowerCase() == q) return c;
    }

    // 2. Exact phone match (clean)
    final cleanQ = q.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanQ.length >= 6) {
      for (final c in _customers) {
        final cleanPhone = c.phone.replaceAll(RegExp(r'[^0-9+]'), '');
        if (cleanPhone.isNotEmpty && (cleanPhone == cleanQ || cleanPhone.endsWith(cleanQ))) {
          return c;
        }
      }
    }

    // 3. Exact plate match (case-insensitive, spaces trimmed)
    final compactQ = q.replaceAll(' ', '');
    for (final c in _customers) {
      final compactPlate = c.plateNumber.toLowerCase().replaceAll(' ', '');
      if (compactPlate.isNotEmpty && compactPlate == compactQ) {
        return c;
      }
    }

    // 4. Exact name match (case-insensitive)
    for (final c in _customers) {
      if (c.name.trim().toLowerCase() == q) {
        return c;
      }
    }

    // 5. Starts-with / substring match for name
    for (final c in _customers) {
      if (c.name.toLowerCase().contains(q)) {
        return c;
      }
    }

    // 6. Substring match for plate
    for (final c in _customers) {
      if (c.plateNumber.toLowerCase().contains(q)) {
        return c;
      }
    }

    return null;
  }

  List<Customer> searchCustomers(String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return List.from(_customers);
    }

    final cleanDigits = query.replaceAll(RegExp(r'[^0-9]'), '');

    return _customers.where((c) {
      if (c.name.toLowerCase().contains(trimmed)) return true;
      if (c.vehicleModel.toLowerCase().contains(trimmed)) return true;
      if (c.plateNumber.toLowerCase().contains(trimmed)) return true;
      if (cleanDigits.length >= 3) {
        final custDigits = c.phone.replaceAll(RegExp(r'[^0-9]'), '');
        if (custDigits.contains(cleanDigits)) return true;
      }
      return false;
    }).toList();
  }

  Customer _createNewCustomerRecord(String name, String? phone, String? vehicleModel) {
    final newCust = Customer(
      id: _uuid.v4(),
      name: name.trim().isNotEmpty ? name.trim() : 'New Customer',
      phone: phone?.trim() ?? '',
      vehicleModel: vehicleModel?.trim() ?? '',
      plateNumber: '',
      totalDue: 0.0,
      totalBilled: 0.0,
      totalPaid: 0.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _db.customersBox.put(newCust.id, newCust.toMap());
    _customers.insert(0, newCust);
    _triggerAutoSync();
    return newCust;
  }

  Future<void> addPayment({
    required String customerName,
    required double amount,
    String? customerId,
    String paymentMethod = 'cash',
    String description = 'Payment Collected',
    bool createNewCustomer = false,
  }) async {
    Customer customer;
    if (createNewCustomer) {
      customer = _createNewCustomerRecord(customerName, null, null);
    } else if (customerId != null) {
      final existing = getCustomerById(customerId);
      customer = existing ??
          (findCustomerByQuery(customerName) ??
              _createNewCustomerRecord(customerName, null, null));
    } else {
      customer = findCustomerByQuery(customerName) ??
          _createNewCustomerRecord(customerName, null, null);
    }

    final updatedDue = (customer.totalDue - amount).clamp(0.0, double.infinity);
    final updatedPaid = customer.totalPaid + amount;
    final updatedCust = customer.copyWith(
      totalDue: updatedDue,
      totalPaid: updatedPaid,
      updatedAt: DateTime.now(),
    );
    await _db.customersBox.put(updatedCust.id, updatedCust.toMap());

    final tx = TransactionRecord(
      id: _uuid.v4(),
      customerId: customer.id,
      customerName: customer.name,
      type: 'payment',
      amount: amount,
      runningBalance: updatedDue,
      description: description,
      paymentMethod: paymentMethod,
      date: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _db.transactionsBox.put(tx.id, tx.toMap());

    await loadAllData();

    _triggerUndoWindow(UndoActionItem(
      actionId: tx.id,
      title: 'Payment Recorded',
      description: '+$amount OMR received from ${customer.name}',
      type: 'payment',
      payload: {'transactionId': tx.id, 'customerId': customer.id, 'amount': amount},
      timestamp: DateTime.now(),
    ));
    _triggerAutoSync();
  }

  Future<void> dispenseStock({
    required String itemName,
    required int quantity,
    String? itemId,
    String targetBay = 'Bay 1',
    double? customPrice,
    String paymentMethod = 'Cash',
    String? customerName,
  }) async {
    StockItem? item;
    if (itemId != null) {
      item = getStockItemById(itemId);
    }
    if (item == null) {
      for (final s in _stockItems) {
        if (s.name.toLowerCase().contains(itemName.trim().toLowerCase()) ||
            s.brand.toLowerCase().contains(itemName.trim().toLowerCase())) {
          item = s;
          break;
        }
      }
    }

    item ??= _stockItems.first;

    final updatedQty = (item.quantity - quantity).clamp(0, 9999);
    final updatedItem = item.copyWith(
      quantity: updatedQty,
      updatedAt: DateTime.now(),
    );
    try {
      await _db.stockItemsBox.put(updatedItem.id, updatedItem.toMap());
    } catch (_) {
      final idx = _stockItems.indexWhere((s) => s.id == updatedItem.id);
      if (idx >= 0) {
        _stockItems[idx] = updatedItem;
      }
    }

    final finalAmount = customPrice ?? (item.sellingPrice * quantity);

    final tx = TransactionRecord(
      id: _uuid.v4(),
      customerName: customerName ?? (targetBay.isNotEmpty ? targetBay : 'Counter Sale'),
      type: 'stock_sale',
      amount: finalAmount,
      runningBalance: 0.0,
      description: 'Stock Sale: $quantity ${item.unit} ${item.name} ($targetBay)',
      paymentMethod: paymentMethod.toLowerCase(),
      date: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    try {
      await _db.transactionsBox.put(tx.id, tx.toMap());
      await loadAllData();
    } catch (_) {
      _transactions.insert(0, tx);
      notifyListeners();
    }

    _triggerUndoWindow(UndoActionItem(
      actionId: tx.id,
      title: 'Stock Sold & Dispensed',
      description: 'Sold $quantity ${item.unit} ${item.name}',
      type: 'stock_sale',
      payload: {
        'transactionId': tx.id,
        'itemId': item.id,
        'quantity': quantity,
      },
      timestamp: DateTime.now(),
    ));
    _triggerAutoSync();
  }

  Future<void> addStock({
    required String itemName,
    required int quantity,
    String? itemId,
    String notes = 'Stock Replenished',
  }) async {
    StockItem? item;
    if (itemId != null) {
      item = getStockItemById(itemId);
    }
    if (item == null) {
      for (final s in _stockItems) {
        if (s.name.toLowerCase().contains(itemName.trim().toLowerCase()) ||
            s.brand.toLowerCase().contains(itemName.trim().toLowerCase())) {
          item = s;
          break;
        }
      }
    }

    item ??= _stockItems.first;

    final updatedQty = (item.quantity + quantity).clamp(0, 9999);
    final updatedItem = item.copyWith(
      quantity: updatedQty,
      updatedAt: DateTime.now(),
    );
    await _db.stockItemsBox.put(updatedItem.id, updatedItem.toMap());

    final tx = TransactionRecord(
      id: _uuid.v4(),
      customerName: 'Inventory Inflow',
      type: 'stock_in',
      amount: item.costPrice * quantity,
      description: 'Stock In: +$quantity ${item.unit} ${item.name} ($notes)',
      paymentMethod: 'purchase',
      date: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _db.transactionsBox.put(tx.id, tx.toMap());

    await loadAllData();

    _triggerUndoWindow(UndoActionItem(
      actionId: tx.id,
      title: 'Stock Added',
      description: 'Added +$quantity ${item.unit} ${item.name}',
      type: 'stock_in',
      payload: {
        'transactionId': tx.id,
        'itemId': item.id,
        'quantity': quantity,
      },
      timestamp: DateTime.now(),
    ));
  }

  Future<void> addExpenseRecord({
    required String title,
    required String category,
    required double amount,
    String paymentMethod = 'Cash',
    DateTime? date,
    String? receiptPath,
  }) async {
    final exp = ExpenseRecord(
      id: _uuid.v4(),
      title: title,
      category: category,
      amount: amount,
      paymentMethod: paymentMethod,
      date: date ?? DateTime.now(),
      receiptPath: receiptPath,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    try {
      await _db.expensesBox.put(exp.id, exp.toMap());
    } catch (_) {}
    _triggerAutoSync();
    _expenses.removeWhere((e) => e.id == exp.id);
    _expenses.insert(0, exp);
    _expenses.sort((a, b) => b.date.compareTo(a.date));
    await loadAllData();
    notifyListeners();

    _triggerUndoWindow(UndoActionItem(
      actionId: exp.id,
      title: 'Expense Logged',
      description: 'OMR $amount for $title ($category)',
      type: 'expense',
      payload: {'expenseId': exp.id},
      timestamp: DateTime.now(),
    ));
  }

  Future<void> recordExpense(ExpenseRecord expense) async {
    try {
      await _db.expensesBox.put(expense.id, expense.toMap());
    } catch (_) {}
    _triggerAutoSync();
    _expenses.removeWhere((e) => e.id == expense.id);
    _expenses.insert(0, expense);
    _expenses.sort((a, b) => b.date.compareTo(a.date));
    await loadAllData();
    notifyListeners();
  }

  Future<void> updateExpenseRecord(ExpenseRecord expense) async {
    try {
      await _db.expensesBox.put(expense.id, expense.toMap());
    } catch (_) {}
    _triggerAutoSync();
    final idx = _expenses.indexWhere((e) => e.id == expense.id);
    if (idx >= 0) {
      _expenses[idx] = expense;
    } else {
      _expenses.insert(0, expense);
    }
    await loadAllData();
    notifyListeners();
  }

  Future<void> deleteExpenseRecord(String id) async {
    try {
      await _db.expensesBox.delete(id);
    } catch (_) {}
    _triggerAutoSync();
    _expenses.removeWhere((e) => e.id == id);
    await loadAllData();
    notifyListeners();
  }

  List<ExpenseRecord> getExpensesForPeriod(String period) {
    final now = DateTime.now();
    return _expenses.where((e) {
      if (period == 'today') {
        return e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day;
      } else if (period == 'week') {
        final startOfWeek = now.subtract(const Duration(days: 7));
        return e.date.isAfter(startOfWeek);
      } else if (period == 'month') {
        return e.date.year == now.year && e.date.month == now.month;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double getExpenseTotalForPeriod(String period) {
    return getExpensesForPeriod(period).fold(0.0, (sum, e) => sum + e.amount);
  }

  double getCashExpenseForPeriod(String period) {
    return getExpensesForPeriod(period)
        .where((e) => e.paymentMethod.toLowerCase() == 'cash')
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double getDigitalExpenseForPeriod(String period) {
    return getExpensesForPeriod(period)
        .where((e) => e.paymentMethod.toLowerCase() != 'cash')
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  Future<void> addNewJob({
    required String customerName,
    required String vehicle,
    required String task,
    double estimatedCost = 0.0,
    String targetBay = 'Bay 1',
  }) async {
    Customer customer = _customers.firstWhere(
      (c) => c.name.toLowerCase() == customerName.trim().toLowerCase(),
      orElse: () {
        final newCust = Customer(
          id: _uuid.v4(),
          name: customerName.trim(),
          phone: '',
          vehicleModel: vehicle,
          plateNumber: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _db.customersBox.put(newCust.id, newCust.toMap());
        _customers.insert(0, newCust);
        return newCust;
      },
    );

    final tx = TransactionRecord(
      id: _uuid.v4(),
      customerId: customer.id,
      customerName: customer.name,
      type: 'invoice',
      amount: estimatedCost,
      runningBalance: customer.totalDue + estimatedCost,
      description: 'New Job in $targetBay: $task ($vehicle)',
      paymentMethod: 'pending',
      date: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _db.transactionsBox.put(tx.id, tx.toMap());

    await loadAllData();

    _triggerUndoWindow(UndoActionItem(
      actionId: tx.id,
      title: 'New Job Created',
      description: '$task for ${customer.name} ($targetBay)',
      type: 'job',
      payload: {'transactionId': tx.id},
      timestamp: DateTime.now(),
    ));
    _triggerAutoSync();
  }

  Future<void> undoLastAction() async {
    if (_lastUndoAction == null) return;
    final action = _lastUndoAction!;
    final payload = action.payload as Map<String, dynamic>;

    if (action.type == 'due' || action.type == 'payment') {
      final txId = payload['transactionId'] as String;
      final custId = payload['customerId'] as String;
      final amount = payload['amount'] as double;

      await _db.transactionsBox.delete(txId);
      final custMap = _db.customersBox.get(custId);
      if (custMap != null) {
        final cust = Customer.fromMap(custMap);
        if (action.type == 'due') {
          final revertedDue = (cust.totalDue - amount).clamp(0.0, double.infinity);
          final revertedBilled = (cust.totalBilled - amount).clamp(0.0, double.infinity);
          await _db.customersBox.put(
            custId,
            cust.copyWith(totalDue: revertedDue, totalBilled: revertedBilled).toMap(),
          );
        } else {
          final revertedDue = cust.totalDue + amount;
          final revertedPaid = (cust.totalPaid - amount).clamp(0.0, double.infinity);
          await _db.customersBox.put(
            custId,
            cust.copyWith(totalDue: revertedDue, totalPaid: revertedPaid).toMap(),
          );
        }
      }
    } else if (action.type == 'stock_out' || action.type == 'stock_sale') {
      final txId = payload['transactionId'] as String;
      final itemId = payload['itemId'] as String;
      final qty = payload['quantity'] as int;

      try {
        await _db.transactionsBox.delete(txId);
        final itemMap = _db.stockItemsBox.get(itemId);
        if (itemMap != null) {
          final item = StockItem.fromMap(itemMap);
          await _db.stockItemsBox.put(
            itemId,
            item.copyWith(quantity: item.quantity + qty).toMap(),
          );
        }
        await loadAllData();
      } catch (_) {
        _transactions.removeWhere((t) => t.id == txId);
        final idx = _stockItems.indexWhere((s) => s.id == itemId);
        if (idx >= 0) {
          _stockItems[idx] = _stockItems[idx].copyWith(quantity: _stockItems[idx].quantity + qty);
        }
        notifyListeners();
      }
    } else if (action.type == 'stock_in') {
      final txId = payload['transactionId'] as String;
      final itemId = payload['itemId'] as String;
      final qty = payload['quantity'] as int;

      await _db.transactionsBox.delete(txId);
      final itemMap = _db.stockItemsBox.get(itemId);
      if (itemMap != null) {
        final item = StockItem.fromMap(itemMap);
        await _db.stockItemsBox.put(
          itemId,
          item.copyWith(quantity: (item.quantity - qty).clamp(0, 9999)).toMap(),
        );
      }
    } else if (action.type == 'expense') {
      final expId = payload['expenseId'] as String;
      await _db.expensesBox.delete(expId);
    } else if (action.type == 'job') {
      final txId = payload['transactionId'] as String;
      await _db.transactionsBox.delete(txId);
    } else if (action.type == 'bay_job_status') {
      final jobId = payload['jobId'] as String;
      final oldStatus = payload['oldStatus'] as String;
      final jobMap = _db.bayJobsBox.get(jobId);
      if (jobMap != null) {
        final job = BayJob.fromMap(jobMap);
        await _db.bayJobsBox.put(jobId, job.copyWith(status: oldStatus).toMap());
      }
    } else if (action.type == 'bay_job_create') {
      final jobId = payload['jobId'] as String;
      try {
        await _db.bayJobsBox.delete(jobId);
      } catch (_) {}
      _bayJobs.removeWhere((j) => j.id == jobId);
      notifyListeners();
    } else if (action.type == 'bay_job_settle') {
      final jobId = payload['jobId'] as String;
      final oldStatus = payload['oldStatus'] as String? ?? 'ready_for_pickup';
      final incomeTxId = payload['incomeTxId'] as String?;
      final dueTxId = payload['dueTxId'] as String?;
      final custId = payload['customerId'] as String?;
      final addedDue = (payload['addedDue'] as num?)?.toDouble() ?? 0.0;

      try {
        final jobMap = _db.bayJobsBox.get(jobId);
        if (jobMap != null) {
          final job = BayJob.fromMap(jobMap);
          await _db.bayJobsBox.put(
            jobId,
            job.copyWith(
              status: oldStatus,
              settledAmount: null,
              paidAmount: null,
              dueAmount: null,
              paymentMethod: null,
            ).toMap(),
          );
        }
      } catch (_) {}
      final jobIdx = _bayJobs.indexWhere((j) => j.id == jobId);
      if (jobIdx >= 0) {
        _bayJobs[jobIdx] = _bayJobs[jobIdx].copyWith(
          status: oldStatus,
          settledAmount: null,
          paidAmount: null,
          dueAmount: null,
          paymentMethod: null,
        );
      }

      if (incomeTxId != null) {
        try {
          await _db.transactionsBox.delete(incomeTxId);
        } catch (_) {}
        _transactions.removeWhere((t) => t.id == incomeTxId);
      }

      if (dueTxId != null) {
        try {
          await _db.transactionsBox.delete(dueTxId);
        } catch (_) {}
        _transactions.removeWhere((t) => t.id == dueTxId);
      }

      if (custId != null && addedDue > 0) {
        try {
          final custMap = _db.customersBox.get(custId);
          if (custMap != null) {
            final cust = Customer.fromMap(custMap);
            final revertedDue = (cust.totalDue - addedDue).clamp(0.0, double.infinity);
            final revertedBilled = (cust.totalBilled - addedDue).clamp(0.0, double.infinity);
            await _db.customersBox.put(
              custId,
              cust.copyWith(totalDue: revertedDue, totalBilled: revertedBilled).toMap(),
            );
          }
        } catch (_) {}
        final cIdx = _customers.indexWhere((c) => c.id == custId);
        if (cIdx >= 0) {
          final cust = _customers[cIdx];
          final revertedDue = (cust.totalDue - addedDue).clamp(0.0, double.infinity);
          final revertedBilled = (cust.totalBilled - addedDue).clamp(0.0, double.infinity);
          _customers[cIdx] = cust.copyWith(totalDue: revertedDue, totalBilled: revertedBilled);
        }
      }
      notifyListeners();
    } else if (action.type == 'income') {
      final txId = payload['transactionId'] as String;
      try {
        await _db.transactionsBox.delete(txId);
      } catch (_) {
        _transactions.removeWhere((t) => t.id == txId);
      }
    } else if (action.type == 'income_deleted') {
      final txData = Map<String, dynamic>.from(payload as Map);
      final tx = TransactionRecord.fromMap(txData);
      try {
        await _db.transactionsBox.put(tx.id, tx.toMap());
      } catch (_) {
        _transactions.insert(0, tx);
      }
      if (tx.isPayment && tx.customerId != null) {
        try {
          final custMap = _db.customersBox.get(tx.customerId);
          if (custMap != null) {
            final cust = Customer.fromMap(custMap);
            final updatedDue = (cust.totalDue - tx.amount).clamp(0.0, double.infinity);
            final updatedPaid = cust.totalPaid + tx.amount;
            await _db.customersBox.put(
              cust.id,
              cust.copyWith(totalDue: updatedDue, totalPaid: updatedPaid).toMap(),
            );
          }
        } catch (_) {}
      }
    } else if (action.type == 'supplier_due_create') {
      final dueId = payload['dueId'] as String;
      try {
        await _db.supplierDuesBox.delete(dueId);
      } catch (_) {}
      _supplierDues.removeWhere((d) => d.id == dueId);
    } else if (action.type == 'supplier_due_delete') {
      final dueData = Map<String, dynamic>.from(payload as Map);
      final due = SupplierDue.fromMap(dueData);
      try {
        await _db.supplierDuesBox.put(due.id, due.toMap());
      } catch (_) {}
      _supplierDues.insert(0, due);
    } else if (action.type == 'supplier_payment') {
      final dueId = payload['dueId'] as String;
      final expenseId = payload['expenseId'] as String;
      final prevDueMap = Map<String, dynamic>.from(payload['previousDue'] as Map);
      final prevDue = SupplierDue.fromMap(prevDueMap);

      try {
        await _db.expensesBox.delete(expenseId);
      } catch (_) {}
      _expenses.removeWhere((e) => e.id == expenseId);

      try {
        await _db.supplierDuesBox.put(dueId, prevDue.toMap());
      } catch (_) {}
      final dIdx = _supplierDues.indexWhere((d) => d.id == dueId);
      if (dIdx >= 0) {
        _supplierDues[dIdx] = prevDue;
      }
    } else if (action.type == 'customer_delete') {
      final custMap = Map<String, dynamic>.from(payload['customer'] as Map);
      final cust = Customer.fromMap(custMap);
      try {
        await _db.customersBox.put(cust.id, cust.toMap());
      } catch (_) {}
      _customers.removeWhere((c) => c.id == cust.id);
      _customers.insert(0, cust);

      final txList = (payload['transactions'] as List?) ?? [];
      for (final item in txList) {
        final txMap = Map<String, dynamic>.from(item as Map);
        final tx = TransactionRecord.fromMap(txMap);
        try {
          await _db.transactionsBox.put(tx.id, tx.toMap());
        } catch (_) {}
        _transactions.removeWhere((t) => t.id == tx.id);
        _transactions.insert(0, tx);
      }
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    }

    _clearUndoWindow();
    await loadAllData();
    _triggerAutoSync();
  }

  Future<void> updateBayJobStatus(String jobId, String newStatus) async {
    BayJob? job;
    try {
      final jobMap = _db.bayJobsBox.get(jobId);
      if (jobMap != null) job = BayJob.fromMap(jobMap);
    } catch (_) {}
    job ??= _bayJobs.where((j) => j.id == jobId).firstOrNull;
    if (job == null) return;
    final oldStatus = job.status;

    final updated = job.copyWith(status: newStatus);
    try {
      await _db.bayJobsBox.put(jobId, updated.toMap());
    } catch (_) {}
    final jIdx = _bayJobs.indexWhere((j) => j.id == jobId);
    if (jIdx >= 0) {
      _bayJobs[jIdx] = updated;
    }
    try {
      await loadAllData();
    } catch (_) {
      notifyListeners();
    }

    _triggerUndoWindow(UndoActionItem(
      actionId: jobId,
      title: 'Bay Status Updated',
      description: '${job.bayNumber} changed to ${updated.displayStatus}',
      type: 'bay_job_status',
      payload: {'jobId': jobId, 'oldStatus': oldStatus},
      timestamp: DateTime.now(),
    ));
    _triggerAutoSync();
  }

  Future<void> createBayJob(BayJob job) async {
    try {
      await _db.bayJobsBox.put(job.id, job.toMap());
    } catch (_) {}
    _triggerAutoSync();
    _bayJobs.removeWhere((j) => j.id == job.id);
    _bayJobs.insert(0, job);
    try {
      await loadAllData();
    } catch (_) {
      notifyListeners();
    }

    _triggerUndoWindow(UndoActionItem(
      actionId: job.id,
      title: 'New Job Created',
      description: '${job.bayNumber}: ${job.taskDescription} for ${job.customerName}',
      type: 'bay_job_create',
      payload: {'jobId': job.id},
      timestamp: DateTime.now(),
    ));
    _triggerAutoSync();
  }

  Future<void> updateBayJob(BayJob job) async {
    try {
      await _db.bayJobsBox.put(job.id, job.toMap());
    } catch (_) {}
    _triggerAutoSync();
    final jIdx = _bayJobs.indexWhere((j) => j.id == job.id);
    if (jIdx >= 0) {
      _bayJobs[jIdx] = job;
    }
    try {
      await loadAllData();
    } catch (_) {
      notifyListeners();
    }
    _triggerAutoSync();
  }

  Future<void> settleBayJob({
    required String jobId,
    required double finalBill,
    required double paidNow,
    required double remainingDue,
    required String paymentMethod,
  }) async {
    BayJob? job;
    try {
      final jobMap = _db.bayJobsBox.get(jobId);
      if (jobMap != null) job = BayJob.fromMap(jobMap);
    } catch (_) {}
    job ??= _bayJobs.where((j) => j.id == jobId).firstOrNull;
    if (job == null) return;

    String? incomeTxId;
    String? dueTxId;
    Customer? targetCustomer;

    // 1. Locate or register customer
    if (job.customerId != null && job.customerId!.isNotEmpty) {
      try {
        targetCustomer = _customers.firstWhere((c) => c.id == job!.customerId);
      } catch (_) {}
    }
    if (targetCustomer == null) {
      try {
        targetCustomer = _customers.firstWhere(
          (c) => c.name.toLowerCase() == job!.customerName.trim().toLowerCase(),
        );
      } catch (_) {
        final newCust = Customer(
          id: _uuid.v4(),
          name: job.customerName.trim(),
          phone: job.customerPhone,
          vehicleModel: job.vehicleModel,
          plateNumber: job.plateNumber,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        try {
          await _db.customersBox.put(newCust.id, newCust.toMap());
        } catch (_) {}
        _customers.insert(0, newCust);
        targetCustomer = newCust;
      }
    }

    // 2. If Paid Amount > 0, log Income transaction under "Job Service"
    if (paidNow > 0) {
      incomeTxId = _uuid.v4();
      final incomeTx = TransactionRecord(
        id: incomeTxId,
        customerId: targetCustomer.id,
        customerName: targetCustomer.name,
        type: 'service',
        amount: paidNow,
        runningBalance: targetCustomer.totalDue,
        description: 'Job Service: ${job.taskDescription} (${job.bayNumber})',
        paymentMethod: paymentMethod.toLowerCase(),
        referenceJobId: job.id,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      try {
        await _db.transactionsBox.put(incomeTx.id, incomeTx.toMap());
      } catch (_) {}
      _transactions.insert(0, incomeTx);
    }

    // 3. If Remaining Due > 0, update customer totalDue & log due transaction
    if (remainingDue > 0) {
      dueTxId = _uuid.v4();
      final updatedDue = targetCustomer.totalDue + remainingDue;
      final updatedBilled = targetCustomer.totalBilled + remainingDue;
      final updatedCust = targetCustomer.copyWith(
        totalDue: updatedDue,
        totalBilled: updatedBilled,
      );
      try {
        await _db.customersBox.put(updatedCust.id, updatedCust.toMap());
      } catch (_) {}
      final cIdx = _customers.indexWhere((c) => c.id == updatedCust.id);
      if (cIdx >= 0) {
        _customers[cIdx] = updatedCust;
      }

      final dueTx = TransactionRecord(
        id: dueTxId,
        customerId: updatedCust.id,
        customerName: updatedCust.name,
        type: 'due',
        amount: remainingDue,
        runningBalance: updatedDue,
        description: 'Job Due Balance: ${job.taskDescription} (${job.bayNumber})',
        paymentMethod: 'credit',
        referenceJobId: job.id,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      try {
        await _db.transactionsBox.put(dueTx.id, dueTx.toMap());
      } catch (_) {}
      _transactions.insert(0, dueTx);
    }

    // 4. Update BayJob as completed
    final completedJob = job.copyWith(
      status: 'completed',
      settledAmount: finalBill,
      paidAmount: paidNow,
      dueAmount: remainingDue,
      paymentMethod: paymentMethod,
      updatedAt: DateTime.now(),
    );
    try {
      await _db.bayJobsBox.put(job.id, completedJob.toMap());
    } catch (_) {}
    final jIdx = _bayJobs.indexWhere((j) => j.id == job!.id);
    if (jIdx >= 0) {
      _bayJobs[jIdx] = completedJob;
    }

    try {
      await loadAllData();
    } catch (_) {
      notifyListeners();
    }

    // 5. Trigger 5-second Undo Window
    _triggerUndoWindow(UndoActionItem(
      actionId: job.id,
      title: 'Job Settled',
      description: '${job.bayNumber} completed for ${job.customerName}',
      type: 'bay_job_settle',
      payload: {
        'jobId': job.id,
        'oldStatus': job.status,
        'incomeTxId': incomeTxId,
        'dueTxId': dueTxId,
        'customerId': targetCustomer.id,
        'addedDue': remainingDue,
      },
      timestamp: DateTime.now(),
    ));
    _triggerAutoSync();
  }

  List<DailyCashFlow> getWeeklyCashFlow() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<DailyCashFlow> days = [];

    for (int i = 6; i >= 0; i--) {
      final dayDate = today.subtract(Duration(days: i));
      final dayLabel = DateFormat.E().format(dayDate);

      final dayIncome = _transactions
          .where((t) =>
              t.isPayment &&
              t.date.year == dayDate.year &&
              t.date.month == dayDate.month &&
              t.date.day == dayDate.day)
          .fold(0.0, (sum, t) => sum + t.amount);

      final dayExpense = _expenses
          .where((e) =>
              e.date.year == dayDate.year &&
              e.date.month == dayDate.month &&
              e.date.day == dayDate.day)
          .fold(0.0, (sum, e) => sum + e.amount);

      days.add(DailyCashFlow(
        date: dayDate,
        dayLabel: dayLabel,
        income: dayIncome,
        expense: dayExpense,
        isToday: i == 0,
      ));
    }

    return days;
  }

  double get weekInflow =>
      getWeeklyCashFlow().fold(0.0, (sum, d) => sum + d.income);

  double getWeeklyInflow() => weekInflow;

  double get weekExpense =>
      getWeeklyCashFlow().fold(0.0, (sum, d) => sum + d.expense);

  double getWeeklyExpense() => weekExpense;

  String getWorkshopName() =>
      workshopProfile['name']?.isNotEmpty == true ? workshopProfile['name']! : 'Apex Auto Workshop';

  final Map<String, dynamic> _inMemorySettings = {};

  dynamic _getSetting(String key, dynamic defaultValue) {
    if (_inMemorySettings.containsKey(key)) {
      return _inMemorySettings[key] ?? defaultValue;
    }
    try {
      return _db.settingsBox.get(key, defaultValue: defaultValue) ?? defaultValue;
    } catch (_) {
      return defaultValue;
    }
  }

  Future<void> _putSetting(String key, dynamic value) async {
    _inMemorySettings[key] = value;
    try {
      await _db.settingsBox.put(key, value);
    } catch (_) {}
  }

  // Workshop Profile
  Map<String, String> get workshopProfile => {
        'name': _getSetting('profile_name', 'Apex Auto Workshop') as String,
        'phone': _getSetting('profile_phone', '+880 1711-234567') as String,
        'taxId': _getSetting('profile_tax_id', 'VAT-89210-AUTO') as String,
        'address': _getSetting('profile_address', 'Industrial Bay 4, Workshop St') as String,
        'logoBase64': (_getSetting('profile_logo_base64', '') as String),
      };

  String? get workshopLogoBase64 {
    final logo = _getSetting('profile_logo_base64', '') as String;
    return logo.isNotEmpty ? logo : null;
  }

  Future<void> updateWorkshopProfile({
    required String name,
    required String phone,
    required String taxId,
    String? address,
    String? logoBase64,
  }) async {
    await _putSetting('profile_name', name.trim());
    await _putSetting('profile_phone', phone.trim());
    await _putSetting('profile_tax_id', taxId.trim());
    if (address != null) {
      await _putSetting('profile_address', address.trim());
    }
    if (logoBase64 != null) {
      await _putSetting('profile_logo_base64', logoBase64.trim());
    }
    notifyListeners();
  }

  Future<void> updateWorkshopLogo(String? logoBase64) async {
    await _putSetting('profile_logo_base64', (logoBase64 ?? '').trim());
    notifyListeners();
  }

  // Display & Security preferences
  bool get sunlightHighContrast =>
      _getSetting('sunlight_mode', true) as bool;
  bool get extraLargeText =>
      _getSetting('extra_large_text', false) as bool;
  bool get voiceFeedback =>
      _getSetting('voice_feedback', true) as bool;
  bool get pinLockEnabled =>
      _getSetting('pin_lock_enabled', true) as bool;
  bool get biometricEnabled =>
      _getSetting('biometric_enabled', true) as bool;
  String get pinCode =>
      _getSetting('pin_code', '1234') as String;

  Future<void> setSunlightHighContrast(bool value) async {
    await _putSetting('sunlight_mode', value);
    notifyListeners();
  }

  Future<void> setExtraLargeText(bool value) async {
    await _putSetting('extra_large_text', value);
    notifyListeners();
  }

  Future<void> setVoiceFeedback(bool value) async {
    await _putSetting('voice_feedback', value);
    notifyListeners();
  }

  Future<void> setPinLockEnabled(bool value) async {
    await _putSetting('pin_lock_enabled', value);
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool value) async {
    await _putSetting('biometric_enabled', value);
    notifyListeners();
  }

  Future<void> setPinCode(String newPin) async {
    await _putSetting('pin_code', newPin);
    notifyListeners();
  }

  // --- WHATSAPP DUE REMINDER TEMPLATE ---

  static const String defaultWhatsAppTemplate =
      'আসসালামু আলাইকুম, আপনার বর্তমান বাকি আছে {amount}। অনুগ্রহ করে পরিশোধ করুন। - {workshopName}';

  String get whatsappDueTemplate {
    final val = _getSetting('whatsapp_due_template', '') as String;
    if (val.trim().isEmpty) {
      return defaultWhatsAppTemplate;
    }
    return val;
  }

  Future<void> setWhatsAppDueTemplate(String template) async {
    await _putSetting('whatsapp_due_template', template.trim());
    notifyListeners();
  }

  Future<void> resetWhatsAppDueTemplate() async {
    await _putSetting('whatsapp_due_template', defaultWhatsAppTemplate);
    notifyListeners();
  }

  String formatWhatsAppDueMessage({
    required double amount,
    required String formattedAmount,
  }) {
    final template = whatsappDueTemplate;
    final shopName = workshopProfile['name']?.isNotEmpty == true
        ? workshopProfile['name']!
        : 'Apex Auto Workshop';

    String msg = template.replaceAll('{amount}', formattedAmount);
    msg = msg.replaceAll('{workshopName}', shopName);
    return msg;
  }

  void setMockCustomers(List<Customer> custs) {
    _customers = List.from(custs);
    notifyListeners();
  }

  // --- EMPLOYEE MANAGEMENT ---

  void setMockEmployees(List<Employee> emps) {
    _employees = List.from(emps);
    notifyListeners();
  }

  Employee? getEmployeeById(String id) {
    try {
      return _employees.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> createEmployee(Employee emp) async {
    await _db.employeesBox.put(emp.id, emp.toMap());
    await loadAllData();
    _triggerAutoSync();
  }

  Future<void> updateEmployee(Employee emp) async {
    await _db.employeesBox.put(emp.id, emp.toMap());
    await loadAllData();
    _triggerAutoSync();
  }

  Future<void> deleteEmployee(String id) async {
    await _db.employeesBox.delete(id);
    await loadAllData();
    _triggerAutoSync();
    try {
      unawaited(SyncService().deleteRemoteEmployee(id));
    } catch (_) {}
  }

  // --- ADVANCED ATTENDANCE SYSTEM ---

  String attendanceKey(String employeeId, DateTime date) =>
      '${employeeId}_${DateFormat('yyyy-MM-dd').format(date)}';

  AttendanceRecord? getAttendanceRecord(String employeeId, DateTime date) {
    final key = attendanceKey(employeeId, date);
    return _attendanceMap[key];
  }

  bool isEmployeePresentOn(String employeeId, DateTime date) {
    final rec = getAttendanceRecord(employeeId, date);
    if (rec != null) return rec.isPresent;
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      final emp = getEmployeeById(employeeId);
      return emp?.isPresent ?? true;
    }
    return false;
  }

  List<AttendanceRecord> getMonthlyAttendance(String employeeId, int year, int month) {
    return _attendanceMap.values.where((r) =>
        r.employeeId == employeeId &&
        r.date.year == year &&
        r.date.month == month).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Map<String, int> getMonthlyAttendanceSummary(String employeeId, int year, int month) {
    int present = 0;
    int absent = 0;
    for (final rec in _attendanceMap.values) {
      if (rec.employeeId == employeeId && rec.date.year == year && rec.date.month == month) {
        if (rec.isPresent) {
          present++;
        } else {
          absent++;
        }
      }
    }
    final daysInMonth = DateTime(year, month + 1, 0).day;
    return {
      'present': present,
      'absent': absent,
      'totalMarked': present + absent,
      'daysInMonth': daysInMonth,
    };
  }

  double calculateProratedSalary(Employee emp, int year, int month) {
    final summary = getMonthlyAttendanceSummary(emp.id, year, month);
    final presentDays = summary['present'] ?? 0;
    final daysInMonth = summary['daysInMonth'] ?? 30;
    if (daysInMonth == 0) return 0.0;
    return (emp.monthlySalary / daysInMonth) * presentDays;
  }

  Future<AttendanceRecord> markAttendance({
    required String employeeId,
    required DateTime date,
    required bool isPresent,
    String? note,
    String markedBy = 'Manager',
  }) async {
    final normDate = DateTime(date.year, date.month, date.day);
    final key = attendanceKey(employeeId, normDate);
    final record = AttendanceRecord(
      id: key,
      employeeId: employeeId,
      date: normDate,
      isPresent: isPresent,
      markedAt: DateTime.now(),
      note: note ?? '',
      markedBy: markedBy,
    );

    _attendanceMap[key] = record;
    try {
      await _db.attendanceBox.put(key, record.toMap());
    } catch (_) {}

    // If marking for today, also keep Employee.isPresent and lastAttendanceDate in sync
    final now = DateTime.now();
    if (normDate.year == now.year && normDate.month == now.month && normDate.day == now.day) {
      final emp = getEmployeeById(employeeId);
      if (emp != null) {
        final updatedEmp = emp.copyWith(
          isPresent: isPresent,
          lastAttendanceDate: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final idx = _employees.indexWhere((e) => e.id == employeeId);
        if (idx != -1) _employees[idx] = updatedEmp;
        try {
          await _db.employeesBox.put(updatedEmp.id, updatedEmp.toMap());
        } catch (_) {}
      }
    }

    notifyListeners();
    return record;
  }

  Future<void> toggleAttendance(String employeeId) async {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final existing = getAttendanceRecord(employeeId, todayDate);
    final emp = getEmployeeById(employeeId);
    final currentStatus = existing != null ? existing.isPresent : (emp?.isPresent ?? true);
    await markAttendance(
      employeeId: employeeId,
      date: todayDate,
      isPresent: !currentStatus,
    );
  }

  Future<void> markAllPresentToday() async {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    for (int i = 0; i < _employees.length; i++) {
      final emp = _employees[i];
      final key = attendanceKey(emp.id, todayDate);
      final record = AttendanceRecord(
        id: key,
        employeeId: emp.id,
        date: todayDate,
        isPresent: true,
        markedAt: DateTime.now(),
        note: 'Marked present (Bulk)',
        markedBy: 'Manager',
      );
      _attendanceMap[key] = record;
      try {
        await _db.attendanceBox.put(key, record.toMap());
      } catch (_) {}

      final updatedEmp = emp.copyWith(
        isPresent: true,
        lastAttendanceDate: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _employees[i] = updatedEmp;
      try {
        await _db.employeesBox.put(updatedEmp.id, updatedEmp.toMap());
      } catch (_) {}
    }

    notifyListeners();
  }

  Future<void> deleteAttendanceRecord(String employeeId, DateTime date) async {
    final normDate = DateTime(date.year, date.month, date.day);
    final key = attendanceKey(employeeId, normDate);
    _attendanceMap.remove(key);
    try {
      await _db.attendanceBox.delete(key);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> recordSalaryPayment(
      String employeeId, double amount, String paymentMethod) async {
    final emp = getEmployeeById(employeeId);
    if (emp == null) return;
    final updated = emp.copyWith(
      isSalaryPaid: true,
      lastSalaryPaidDate: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _db.employeesBox.put(updated.id, updated.toMap());

    final expense = ExpenseRecord(
      id: _uuid.v4(),
      title: 'Salary: ${emp.name}',
      category: 'Staff Salary',
      amount: amount,
      paymentMethod: paymentMethod,
      date: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _db.expensesBox.put(expense.id, expense.toMap());

    await loadAllData();
  }

  // --- DAILY SUMMARY & INCOME BREAKDOWN ---

  void setMockTransactions(List<TransactionRecord> txs) {
    _transactions = List.from(txs);
    notifyListeners();
  }

  Future<void> recordTransaction(TransactionRecord tx) async {
    try {
      await _db.transactionsBox.put(tx.id, tx.toMap());
    } catch (_) {}
    _triggerAutoSync();
    _transactions.removeWhere((t) => t.id == tx.id);
    _transactions.insert(0, tx);
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    try {
      await loadAllData();
    } catch (_) {
      notifyListeners();
    }
  }

  Future<void> recordIncome({
    required String category,
    required double amount,
    required String description,
    String customerName = 'Walk-in Customer',
    String? customerId,
    String paymentMethod = 'cash',
  }) async {
    final type =
        category.toLowerCase().contains('wash') ? 'car_wash' : 'service';
    final tx = TransactionRecord(
      id: _uuid.v4(),
      customerId: customerId,
      customerName: customerName,
      type: type,
      amount: amount,
      description: description,
      paymentMethod: paymentMethod,
      date: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _db.transactionsBox.put(tx.id, tx.toMap());
    } catch (_) {}
    _triggerAutoSync();
    _transactions.removeWhere((t) => t.id == tx.id);
    _transactions.insert(0, tx);
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    await loadAllData();
    notifyListeners();

    _triggerUndoWindow(UndoActionItem(
      actionId: tx.id,
      title: 'Income Logged',
      description: '+$amount OMR for $description ($category)',
      type: 'income',
      payload: {'transactionId': tx.id},
      timestamp: DateTime.now(),
    ));
    _triggerAutoSync();
  }

  Future<void> deleteIncomeRecord(String transactionId) async {
    TransactionRecord? tx;
    try {
      final txMap = _db.transactionsBox.get(transactionId);
      if (txMap != null) {
        tx = TransactionRecord.fromMap(txMap);
      }
    } catch (_) {
      tx = _transactions.where((t) => t.id == transactionId).firstOrNull;
    }
    if (tx == null) return;

    // If it was a customer payment (due settled), revert the customer's balance
    if (tx.isPayment && tx.customerId != null) {
      try {
        final custMap = _db.customersBox.get(tx.customerId);
        if (custMap != null) {
          final cust = Customer.fromMap(custMap);
          final revertedDue = cust.totalDue + tx.amount;
          final revertedPaid = (cust.totalPaid - tx.amount).clamp(0.0, double.infinity);
          await _db.customersBox.put(
            cust.id,
            cust.copyWith(totalDue: revertedDue, totalPaid: revertedPaid).toMap(),
          );
        }
      } catch (_) {}
    }

    try {
      await _db.transactionsBox.delete(transactionId);
    } catch (_) {}
    _triggerAutoSync();
    _transactions.removeWhere((t) => t.id == transactionId);
    await loadAllData();
    notifyListeners();

    _triggerUndoWindow(UndoActionItem(
      actionId: transactionId,
      title: 'Income Record Deleted',
      description: 'Removed ${tx.description} (${tx.amount} OMR)',
      type: 'income_deleted',
      payload: tx.toMap(),
      timestamp: DateTime.now(),
    ));
    _triggerAutoSync();
    try {
      SyncService().deleteRemoteTransaction(transactionId);
    } catch (_) {}
  }

  DailyIncomeBreakdown getDailyIncomeBreakdown(DateTime date) {
    final dayTxs = _transactions.where((t) =>
        t.isIncome &&
        t.date.year == date.year &&
        t.date.month == date.month &&
        t.date.day == date.day).toList();

    double carWashIncome = 0.0;
    int carWashCount = 0;
    double settlePaymentIncome = 0.0;
    int settlePaymentCount = 0;
    double otherIncome = 0.0;
    int otherIncomeCount = 0;

    for (final t in dayTxs) {
      if (t.isCarWash || t.description.toLowerCase().contains('wash')) {
        carWashIncome += t.amount;
        carWashCount++;
      } else if (t.isPayment) {
        settlePaymentIncome += t.amount;
        settlePaymentCount++;
      } else {
        otherIncome += t.amount;
        otherIncomeCount++;
      }
    }

    final totalIncome = carWashIncome + settlePaymentIncome + otherIncome;

    return DailyIncomeBreakdown(
      carWashIncome: carWashIncome,
      carWashCount: carWashCount,
      settlePaymentIncome: settlePaymentIncome,
      settlePaymentCount: settlePaymentCount,
      otherIncome: otherIncome,
      otherIncomeCount: otherIncomeCount,
      totalIncome: totalIncome,
      transactions: dayTxs,
    );
  }

  DailyExpenseBreakdown getDailyExpenseBreakdown(DateTime date) {
    final dayExpenses = _expenses.where((e) =>
        e.date.year == date.year &&
        e.date.month == date.month &&
        e.date.day == date.day).toList();

    final Map<String, double> categoryTotals = {};
    double totalExpense = 0.0;

    for (final e in dayExpenses) {
      totalExpense += e.amount;
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0.0) + e.amount;
    }

    return DailyExpenseBreakdown(
      categoryTotals: categoryTotals,
      totalExpense: totalExpense,
      expenses: dayExpenses,
    );
  }

  DailyIncomeBreakdown getIncomeBreakdownForPeriod(String period, {DateTime? customDate}) {
    final now = DateTime.now();
    final List<TransactionRecord> periodTxs = _transactions.where((t) {
      if (!t.isIncome) return false;
      if (period == 'today') {
        return t.date.year == now.year &&
            t.date.month == now.month &&
            t.date.day == now.day;
      } else if (period == 'week') {
        final startOfWeek = now.subtract(const Duration(days: 7));
        return t.date.isAfter(startOfWeek);
      } else if (period == 'month') {
        return t.date.year == now.year && t.date.month == now.month;
      } else if (period == 'custom' && customDate != null) {
        return t.date.year == customDate.year &&
            t.date.month == customDate.month &&
            t.date.day == customDate.day;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    double carWashIncome = 0.0;
    int carWashCount = 0;
    double settlePaymentIncome = 0.0;
    int settlePaymentCount = 0;
    double otherIncome = 0.0;
    int otherIncomeCount = 0;

    for (final t in periodTxs) {
      if (t.isCarWash || t.description.toLowerCase().contains('wash')) {
        carWashIncome += t.amount;
        carWashCount++;
      } else if (t.isPayment) {
        settlePaymentIncome += t.amount;
        settlePaymentCount++;
      } else {
        otherIncome += t.amount;
        otherIncomeCount++;
      }
    }

    final totalIncome = carWashIncome + settlePaymentIncome + otherIncome;

    return DailyIncomeBreakdown(
      carWashIncome: carWashIncome,
      carWashCount: carWashCount,
      settlePaymentIncome: settlePaymentIncome,
      settlePaymentCount: settlePaymentCount,
      otherIncome: otherIncome,
      otherIncomeCount: otherIncomeCount,
      totalIncome: totalIncome,
      transactions: periodTxs,
    );
  }

  DailyExpenseBreakdown getExpenseBreakdownForPeriod(String period, {DateTime? customDate}) {
    final now = DateTime.now();
    final List<ExpenseRecord> periodExpenses = _expenses.where((e) {
      if (period == 'today') {
        return e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day;
      } else if (period == 'week') {
        final startOfWeek = now.subtract(const Duration(days: 7));
        return e.date.isAfter(startOfWeek);
      } else if (period == 'month') {
        return e.date.year == now.year && e.date.month == now.month;
      } else if (period == 'custom' && customDate != null) {
        return e.date.year == customDate.year &&
            e.date.month == customDate.month &&
            e.date.day == customDate.day;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final Map<String, double> categoryTotals = {};
    double totalExpense = 0.0;

    for (final e in periodExpenses) {
      totalExpense += e.amount;
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0.0) + e.amount;
    }

    return DailyExpenseBreakdown(
      categoryTotals: categoryTotals,
      totalExpense: totalExpense,
      expenses: periodExpenses,
    );
  }

  Future<DayCloseRecord> closeDay(
    DateTime date, {
    String closedBy = 'Manager',
    String notes = '',
  }) async {
    final key = dayKey(date);
    final income = getDailyIncomeBreakdown(date);
    final expense = getDailyExpenseBreakdown(date);
    final net = income.totalIncome - expense.totalExpense;

    final record = DayCloseRecord(
      dateKey: key,
      date: DateTime(date.year, date.month, date.day),
      closedAt: DateTime.now(),
      totalIncome: income.totalIncome,
      totalExpense: expense.totalExpense,
      netAmount: net,
      carWashIncome: income.carWashIncome,
      carWashCount: income.carWashCount,
      settlePaymentIncome: income.settlePaymentIncome,
      settlePaymentCount: income.settlePaymentCount,
      otherIncome: income.otherIncome,
      otherIncomeCount: income.otherIncomeCount,
      categoryExpenses: Map.from(expense.categoryTotals),
      closedBy: closedBy,
      notes: notes,
    );

    _closedDays[key] = record;
    try {
      await _db.settingsBox.put('day_close_$key', record.toMap());
    } catch (_) {
      // Safely handled if settingsBox is not initialized in unit tests
    }
    notifyListeners();
    return record;
  }

  Future<void> reopenDay(DateTime date) async {
    final key = dayKey(date);
    _closedDays.remove(key);
    try {
      await _db.settingsBox.delete('day_close_$key');
    } catch (_) {
      // Safely handled if settingsBox is not initialized in unit tests
    }
    notifyListeners();
  }

  String generateLedgerCsv() {
    final buffer = StringBuffer();
    buffer.writeln('Type,ID,Customer/Title,Amount,Date,Payment Method,Details');
    for (final t in _transactions) {
      buffer.writeln(
          'Transaction,${t.id},"${t.customerName}",${t.amount},${t.date.toIso8601String()},${t.paymentMethod},"${t.description}"');
    }
    for (final e in _expenses) {
      buffer.writeln(
          'Expense,${e.id},"${e.title}",${e.amount},${e.date.toIso8601String()},${e.paymentMethod},"${e.category}"');
    }
    return buffer.toString();
  }

  // --- SUPPLIER DUES (OWNERS DUE TO COMPANY) ---

  Future<SupplierDue> addSupplierDue({
    required String companyName,
    required double totalAmount,
    required String itemsPurchased,
    DateTime? date,
    String notes = '',
  }) async {
    final now = DateTime.now();
    final due = SupplierDue(
      id: _uuid.v4(),
      companyName: companyName.trim(),
      totalAmount: totalAmount,
      paidAmount: 0.0,
      itemsPurchased: itemsPurchased.trim(),
      date: date ?? now,
      notes: notes.trim(),
      payments: const [],
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _db.supplierDuesBox.put(due.id, due.toMap());
      await loadAllData();
    } catch (_) {
      _supplierDues.insert(0, due);
      notifyListeners();
    }

    _triggerUndoWindow(UndoActionItem(
      actionId: due.id,
      title: 'Supplier Due Added',
      description: 'OMR ${due.totalAmount.toStringAsFixed(3)} to ${due.companyName}',
      type: 'supplier_due_create',
      payload: {'dueId': due.id},
      timestamp: DateTime.now(),
    ));

    return due;
  }

  Future<void> updateSupplierDue(SupplierDue due) async {
    final updated = due.copyWith(updatedAt: DateTime.now());
    try {
      await _db.supplierDuesBox.put(updated.id, updated.toMap());
      await loadAllData();
    } catch (_) {
      final idx = _supplierDues.indexWhere((d) => d.id == updated.id);
      if (idx >= 0) {
        _supplierDues[idx] = updated;
      }
      notifyListeners();
    }
  }

  Future<void> deleteSupplierDue(String id) async {
    SupplierDue? due;
    try {
      final map = _db.supplierDuesBox.get(id);
      if (map != null) {
        due = SupplierDue.fromMap(map);
      }
    } catch (_) {}
    due ??= _supplierDues.where((d) => d.id == id).firstOrNull;
    if (due == null) return;

    try {
      await _db.supplierDuesBox.delete(id);
      await loadAllData();
    } catch (_) {
      _supplierDues.removeWhere((d) => d.id == id);
      notifyListeners();
    }

    _triggerUndoWindow(UndoActionItem(
      actionId: id,
      title: 'Supplier Due Deleted',
      description: 'Removed ${due.companyName} (OMR ${due.dueAmount.toStringAsFixed(3)})',
      type: 'supplier_due_delete',
      payload: due.toMap(),
      timestamp: DateTime.now(),
    ));
  }

  Future<void> recordSupplierPayment({
    required String dueId,
    required double amount,
    String paymentMethod = 'Cash',
    DateTime? date,
    String notes = '',
  }) async {
    if (amount <= 0) return;

    SupplierDue? due;
    try {
      final map = _db.supplierDuesBox.get(dueId);
      if (map != null) {
        due = SupplierDue.fromMap(map);
      }
    } catch (_) {}
    due ??= _supplierDues.where((d) => d.id == dueId).firstOrNull;
    if (due == null) return;

    final payDate = date ?? DateTime.now();
    final expenseId = _uuid.v4();
    final paymentId = _uuid.v4();

    // 1. Create Expense Record under 'Supplier Payment' category
    final expense = ExpenseRecord(
      id: expenseId,
      title: 'Supplier Payment: ${due.companyName}',
      category: 'Supplier Payment',
      amount: amount,
      paymentMethod: paymentMethod,
      date: payDate,
      receiptPath: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _db.expensesBox.put(expense.id, expense.toMap());
    } catch (_) {
      _expenses.insert(0, expense);
    }

    // 2. Create SupplierPayment and update SupplierDue
    final payment = SupplierPayment(
      id: paymentId,
      amount: amount,
      date: payDate,
      paymentMethod: paymentMethod,
      notes: notes.trim(),
      expenseId: expenseId,
    );

    final updatedDue = due.copyWith(
      paidAmount: due.paidAmount + amount,
      payments: [...due.payments, payment],
      updatedAt: DateTime.now(),
    );

    try {
      await _db.supplierDuesBox.put(updatedDue.id, updatedDue.toMap());
      await loadAllData();
    } catch (_) {
      final idx = _supplierDues.indexWhere((d) => d.id == dueId);
      if (idx >= 0) {
        _supplierDues[idx] = updatedDue;
      }
      notifyListeners();
    }

    // 3. Trigger 5s Undo Window
    _triggerUndoWindow(UndoActionItem(
      actionId: paymentId,
      title: 'Supplier Payment Recorded',
      description: 'OMR ${amount.toStringAsFixed(3)} to ${due.companyName}',
      type: 'supplier_payment',
      payload: {
        'dueId': dueId,
        'paymentId': paymentId,
        'expenseId': expenseId,
        'amount': amount,
        'previousDue': due.toMap(),
      },
      timestamp: DateTime.now(),
    ));
  }

  // Backup & Restore
  BackupService get backupService => _backupService;

  Future<String> exportBackupJson({bool pretty = true}) {
    return _backupService.exportBackupJson(pretty: pretty);
  }

  BackupValidationResult validateBackup(String jsonContent) {
    return _backupService.validateBackup(jsonContent);
  }

  Future<bool> restoreFromBackupJson(String jsonContent) async {
    final success = await _backupService.restoreFromBackupJson(jsonContent);
    if (success) {
      _inMemorySettings.clear();
      await loadAllData();
      notifyListeners();
    }
    return success;
  }

  Map<String, int> getDatabaseStatistics() {
    return {
      'customers': _customers.length,
      'stockItems': _stockItems.length,
      'transactions': _transactions.length,
      'expenses': _expenses.length,
      'employees': _employees.length,
      'attendance': _attendanceMap.length,
      'bayJobs': _bayJobs.length,
      'supplierDues': _supplierDues.length,
    };
  }

  // --- AUTHENTICATION & ROLE-BASED ACCESS ---

  Future<bool> loginOwner(String pin) async {
    final cleanPin = pin.trim();
    if (cleanPin != ownerPin) {
      return false;
    }
    _currentUser = AppUser.defaultOwner(
      name: workshopProfile['name']?.isNotEmpty == true
          ? workshopProfile['name']!
          : 'Workshop Owner',
    );
    _isAppLocked = false;
    try {
      await _db.settingsBox.put('active_user_session', _currentUser!.toMap());
    } catch (_) {}
    notifyListeners();
    return true;
  }

  Future<bool> loginStaff(String employeeId, String pin) async {
    final cleanPin = pin.trim();
    final staffMember = _employees.where((e) => e.id == employeeId).firstOrNull;
    if (staffMember == null) {
      return false;
    }
    if (!staffMember.isLoginEnabled) {
      debugPrint('Login rejected: Staff member ${staffMember.name} login is disabled.');
      return false;
    }
    if (staffMember.pin != cleanPin) {
      return false;
    }
    _currentUser = AppUser(
      id: staffMember.id,
      name: staffMember.name,
      role: UserRole.staff,
      staffId: staffMember.id,
      avatarBase64: staffMember.avatarBase64,
      designation: staffMember.role,
    );
    _isAppLocked = false;
    try {
      await _db.settingsBox.put('active_user_session', _currentUser!.toMap());
    } catch (_) {}
    notifyListeners();
    return true;
  }

  Future<bool> unlockWithPin(String pin) async {
    final cleanPin = pin.trim();
    if (_currentUser == null || _currentUser!.isOwner) {
      return await loginOwner(cleanPin);
    } else {
      final staffId = _currentUser!.staffId ?? _currentUser!.id;
      return await loginStaff(staffId, cleanPin);
    }
  }

  Future<bool> unlockWithBiometrics() async {
    final ok = await BiometricAuthService().authenticate();
    if (ok) {
      if (_currentUser == null) {
        return await loginOwner(ownerPin);
      }
      _isAppLocked = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    _isAppLocked = false;
    try {
      await _db.settingsBox.delete('active_user_session');
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setOwnerPin(String newPin) async {
    await _putSetting('pin_code', newPin.trim());
    notifyListeners();
  }

  Future<void> toggleEmployeeLoginEnabled(String employeeId, bool isEnabled) async {
    if (!isOwner) {
      debugPrint('Permission denied: Only Owner can toggle staff login access.');
      return;
    }
    final idx = _employees.indexWhere((e) => e.id == employeeId);
    if (idx != -1) {
      final updated = _employees[idx].copyWith(isLoginEnabled: isEnabled);
      _employees[idx] = updated;
      try {
        await _db.employeesBox.put(updated.id, updated.toMap());
        _triggerAutoSync();
      } catch (_) {}
      notifyListeners();
    }
  }

  Future<void> setEmployeePin(String employeeId, String newPin) async {
    if (!isOwner) {
      debugPrint('Permission denied: Only Owner can set staff PINs.');
      return;
    }
    final idx = _employees.indexWhere((e) => e.id == employeeId);
    if (idx != -1) {
      final updated = _employees[idx].copyWith(
        pin: newPin.trim(),
        isLoginEnabled: true,
      );
      _employees[idx] = updated;
      try {
        await _db.employeesBox.put(updated.id, updated.toMap());
        _triggerAutoSync();
      } catch (_) {}
      notifyListeners();
    }
  }

  Future<void> resetDemoData() async {
    await _db.customersBox.clear();
    await _db.stockItemsBox.clear();
    await _db.transactionsBox.clear();
    await _db.expensesBox.clear();
    await _db.employeesBox.clear();
    await _db.bayJobsBox.clear();
    await _db.supplierDuesBox.clear();
    await _db.attendanceBox.clear();
    await _db.settingsBox.clear();
    _inMemorySettings.clear();
    _currentUser = null;
    await _putSetting('garage_setup_completed', true);
    await loadAllData();
    notifyListeners();
  }
}
