import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../database/database_service.dart';

class BackupValidationResult {
  final bool isValid;
  final String? errorMessage;
  final int version;
  final DateTime? exportedAt;
  final String workshopName;
  final Map<String, int> counts;

  const BackupValidationResult({
    required this.isValid,
    this.errorMessage,
    this.version = 1,
    this.exportedAt,
    this.workshopName = 'Apex Auto Workshop',
    this.counts = const {},
  });

  int get totalRecords => counts.values.fold(0, (sum, count) => sum + count);
}

class BackupService {
  final DatabaseService _db;

  BackupService({DatabaseService? db}) : _db = db ?? DatabaseService();

  /// Compiles all 9 Hive data domains into a structured Map
  Future<Map<String, dynamic>> createBackupPayload() async {
    final now = DateTime.now();

    // 1. Customers
    final customersList = <Map<String, dynamic>>[];
    try {
      for (final val in _db.customersBox.values) {
        customersList.add(Map<String, dynamic>.from(val));
      }
    } catch (_) {}

    // 2. Stock items
    final stockItemsList = <Map<String, dynamic>>[];
    try {
      for (final val in _db.stockItemsBox.values) {
        stockItemsList.add(Map<String, dynamic>.from(val));
      }
    } catch (_) {}

    // 3. Transactions
    final transactionsList = <Map<String, dynamic>>[];
    try {
      for (final val in _db.transactionsBox.values) {
        transactionsList.add(Map<String, dynamic>.from(val));
      }
    } catch (_) {}

    // 4. Expenses
    final expensesList = <Map<String, dynamic>>[];
    try {
      for (final val in _db.expensesBox.values) {
        expensesList.add(Map<String, dynamic>.from(val));
      }
    } catch (_) {}

    // 5. Employees
    final employeesList = <Map<String, dynamic>>[];
    try {
      for (final val in _db.employeesBox.values) {
        employeesList.add(Map<String, dynamic>.from(val));
      }
    } catch (_) {}

    // 6. Attendance
    final attendanceList = <Map<String, dynamic>>[];
    try {
      for (final val in _db.attendanceBox.values) {
        attendanceList.add(Map<String, dynamic>.from(val));
      }
    } catch (_) {}

    // 7. Bay Jobs
    final bayJobsList = <Map<String, dynamic>>[];
    try {
      for (final val in _db.bayJobsBox.values) {
        bayJobsList.add(Map<String, dynamic>.from(val));
      }
    } catch (_) {}

    // 8. Supplier Dues
    final supplierDuesList = <Map<String, dynamic>>[];
    try {
      for (final val in _db.supplierDuesBox.values) {
        supplierDuesList.add(Map<String, dynamic>.from(val));
      }
    } catch (_) {}

    // 9. Settings (profile, logo, preferences, day closures)
    final settingsMap = <String, dynamic>{};
    try {
      for (final key in _db.settingsBox.keys) {
        final val = _db.settingsBox.get(key);
        if (val is Map) {
          settingsMap[key.toString()] = Map<String, dynamic>.from(val);
        } else {
          settingsMap[key.toString()] = val;
        }
      }
    } catch (_) {}

    final workshopName = (settingsMap['profile_name'] as String?)?.isNotEmpty == true
        ? settingsMap['profile_name'] as String
        : 'Apex Auto Workshop';

    final counts = {
      'customers': customersList.length,
      'stockItems': stockItemsList.length,
      'transactions': transactionsList.length,
      'expenses': expensesList.length,
      'employees': employeesList.length,
      'attendance': attendanceList.length,
      'bayJobs': bayJobsList.length,
      'supplierDues': supplierDuesList.length,
    };

    return {
      'app': 'Garage Accounting Pro',
      'version': 1,
      'exportedAt': now.toIso8601String(),
      'metadata': {
        'workshopName': workshopName,
        'counts': counts,
      },
      'data': {
        'customers': customersList,
        'stockItems': stockItemsList,
        'transactions': transactionsList,
        'expenses': expensesList,
        'employees': employeesList,
        'attendance': attendanceList,
        'bayJobs': bayJobsList,
        'supplierDues': supplierDuesList,
        'settings': settingsMap,
      },
    };
  }

  /// Exports backup data as a formatted JSON string
  Future<String> exportBackupJson({bool pretty = true}) async {
    final payload = await createBackupPayload();
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(payload);
    }
    return jsonEncode(payload);
  }

  /// Validates a backup JSON string before attempting to restore
  BackupValidationResult validateBackup(String jsonContent) {
    if (jsonContent.trim().isEmpty) {
      return const BackupValidationResult(
        isValid: false,
        errorMessage: 'The backup content is empty.',
      );
    }

    try {
      final decoded = jsonDecode(jsonContent);
      if (decoded is! Map) {
        return const BackupValidationResult(
          isValid: false,
          errorMessage: 'Invalid file format. Root JSON must be an object.',
        );
      }

      final map = Map<String, dynamic>.from(decoded);

      if (!map.containsKey('data') || map['data'] is! Map) {
        return const BackupValidationResult(
          isValid: false,
          errorMessage: 'Missing "data" section in backup file.',
        );
      }

      final data = Map<String, dynamic>.from(map['data'] as Map);
      final version = (map['version'] as num?)?.toInt() ?? 1;

      DateTime? exportedAt;
      if (map['exportedAt'] is String) {
        exportedAt = DateTime.tryParse(map['exportedAt'] as String);
      }

      String workshopName = 'Apex Auto Workshop';
      if (map['metadata'] is Map) {
        final meta = Map<String, dynamic>.from(map['metadata'] as Map);
        if (meta['workshopName'] is String && (meta['workshopName'] as String).isNotEmpty) {
          workshopName = meta['workshopName'] as String;
        }
      } else if (data['settings'] is Map) {
        final settings = Map<String, dynamic>.from(data['settings'] as Map);
        if (settings['profile_name'] is String && (settings['profile_name'] as String).isNotEmpty) {
          workshopName = settings['profile_name'] as String;
        }
      }

      final counts = <String, int>{
        'customers': (data['customers'] as List?)?.length ?? 0,
        'stockItems': (data['stockItems'] as List?)?.length ?? 0,
        'transactions': (data['transactions'] as List?)?.length ?? 0,
        'expenses': (data['expenses'] as List?)?.length ?? 0,
        'employees': (data['employees'] as List?)?.length ?? 0,
        'attendance': (data['attendance'] as List?)?.length ?? 0,
        'bayJobs': (data['bayJobs'] as List?)?.length ?? 0,
        'supplierDues': (data['supplierDues'] as List?)?.length ?? 0,
      };

      return BackupValidationResult(
        isValid: true,
        version: version,
        exportedAt: exportedAt,
        workshopName: workshopName,
        counts: counts,
      );
    } catch (e) {
      return BackupValidationResult(
        isValid: false,
        errorMessage: 'JSON parse error: ${e.toString()}',
      );
    }
  }

  /// Restores all 9 Hive boxes from a validated backup JSON string
  Future<bool> restoreFromBackupJson(String jsonContent) async {
    final validation = validateBackup(jsonContent);
    if (!validation.isValid) {
      debugPrint('Backup restoration rejected: ${validation.errorMessage}');
      return false;
    }

    try {
      final decoded = jsonDecode(jsonContent) as Map;
      final data = Map<String, dynamic>.from(decoded['data'] as Map);

      // 1. Clear all existing data boxes
      await _db.customersBox.clear();
      await _db.stockItemsBox.clear();
      await _db.transactionsBox.clear();
      await _db.expensesBox.clear();
      await _db.employeesBox.clear();
      await _db.attendanceBox.clear();
      await _db.bayJobsBox.clear();
      await _db.supplierDuesBox.clear();
      await _db.settingsBox.clear();

      // 2. Restore Customers
      if (data['customers'] is List) {
        for (final item in data['customers'] as List) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final id = map['id']?.toString();
            if (id != null && id.isNotEmpty) {
              await _db.customersBox.put(id, map);
            }
          }
        }
      }

      // 3. Restore Stock Items
      if (data['stockItems'] is List) {
        for (final item in data['stockItems'] as List) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final id = map['id']?.toString();
            if (id != null && id.isNotEmpty) {
              await _db.stockItemsBox.put(id, map);
            }
          }
        }
      }

      // 4. Restore Transactions
      if (data['transactions'] is List) {
        for (final item in data['transactions'] as List) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final id = map['id']?.toString();
            if (id != null && id.isNotEmpty) {
              await _db.transactionsBox.put(id, map);
            }
          }
        }
      }

      // 5. Restore Expenses
      if (data['expenses'] is List) {
        for (final item in data['expenses'] as List) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final id = map['id']?.toString();
            if (id != null && id.isNotEmpty) {
              await _db.expensesBox.put(id, map);
            }
          }
        }
      }

      // 6. Restore Employees
      if (data['employees'] is List) {
        for (final item in data['employees'] as List) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final id = map['id']?.toString();
            if (id != null && id.isNotEmpty) {
              await _db.employeesBox.put(id, map);
            }
          }
        }
      }

      // 7. Restore Attendance
      if (data['attendance'] is List) {
        for (final item in data['attendance'] as List) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final id = map['id']?.toString();
            if (id != null && id.isNotEmpty) {
              await _db.attendanceBox.put(id, map);
            }
          }
        }
      }

      // 8. Restore Bay Jobs
      if (data['bayJobs'] is List) {
        for (final item in data['bayJobs'] as List) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final id = map['id']?.toString();
            if (id != null && id.isNotEmpty) {
              await _db.bayJobsBox.put(id, map);
            }
          }
        }
      }

      // 9. Restore Supplier Dues
      if (data['supplierDues'] is List) {
        for (final item in data['supplierDues'] as List) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final id = map['id']?.toString();
            if (id != null && id.isNotEmpty) {
              await _db.supplierDuesBox.put(id, map);
            }
          }
        }
      }

      // 10. Restore Settings
      if (data['settings'] is Map) {
        final settings = Map<String, dynamic>.from(data['settings'] as Map);
        for (final entry in settings.entries) {
          await _db.settingsBox.put(entry.key, entry.value);
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error restoring backup: $e');
      return false;
    }
  }
}
