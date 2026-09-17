import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/database/database_service.dart';
import '../../data/models/customer.dart';
import '../../data/models/bay_job.dart';
import '../../data/models/transaction_record.dart';
import '../../data/repositories/garage_repository.dart';

class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseService _db = DatabaseService();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  GarageRepository? _repository;
  Timer? _pushDebounceTimer;

  void attachRepository(GarageRepository repo) {
    _repository = repo;
  }

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;
  bool _hasPendingPush = false;

  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  String? _syncError;
  String? get syncError => _syncError;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  SupabaseClient? get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  User? get currentCloudUser =>
      client?.auth.currentUser ?? client?.auth.currentSession?.user;
  bool get isCloudAuthenticated => currentCloudUser != null;

  int get unsyncedCount {
    int count = 0;
    try {
      if (_db.customersBox.isOpen) {
        count += _db.customersBox.values
            .where((m) => m['isSynced'] != true)
            .length;
      }
      if (_db.bayJobsBox.isOpen) {
        count += _db.bayJobsBox.values
            .where((m) => m['isSynced'] != true)
            .length;
      }
      if (_db.transactionsBox.isOpen) {
        count += _db.transactionsBox.values
            .where((m) => m['isSynced'] != true)
            .length;
      }
    } catch (_) {}
    return count;
  }

  int get pendingUploads => unsyncedCount;

  void initConnectivityListener() {
    _connectivitySub?.cancel();
    try {
      _connectivitySub = Connectivity()
          .onConnectivityChanged
          .listen((List<ConnectivityResult> results) {
        final online = results.any((r) => r != ConnectivityResult.none);
        _isOnline = online;
        notifyListeners();
        if (online && isCloudAuthenticated) {
          pushUnsynced();
        }
      });
    } catch (e) {
      debugPrint('SyncService: Failed to init connectivity listener: $e');
    }
  }

  Future<AuthResponse?> signUp(String email, String password) async {
    final c = client;
    if (c == null) throw Exception('Supabase client is not initialized.');
    _syncError = null;
    try {
      final res = await c.auth.signUp(
        email: email.trim(),
        password: password,
      );
      notifyListeners();
      return res;
    } catch (e) {
      _syncError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<AuthResponse?> signIn(String email, String password) async {
    final c = client;
    if (c == null) throw Exception('Supabase client is not initialized.');
    _syncError = null;
    try {
      final res = await c.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      notifyListeners();
      if (res.user != null) {
        await pullRemoteData();
        await pushUnsynced();
      }
      return res;
    } catch (e) {
      _syncError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    final c = client;
    if (c == null) return;
    try {
      await c.auth.signOut();
    } catch (e) {
      debugPrint('SyncService.signOut error: $e');
    }
    _syncError = null;
    notifyListeners();
  }

  Future<void> pushUnsynced() async {
    final c = client;
    final user = currentCloudUser;
    if (c == null || user == null) return;

    if (_isSyncing) {
      _hasPendingPush = true;
      return;
    }

    _isSyncing = true;
    _syncError = null;
    notifyListeners();

    try {
      do {
        _hasPendingPush = false;

        // 1. Customers
        if (_db.customersBox.isOpen) {
          final unsyncedCustomers = _db.customersBox.values
              .where((m) => m['isSynced'] != true)
              .map((m) => Customer.fromMap(m))
              .toList();

          for (final customer in unsyncedCustomers) {
            try {
              await c.from('customers').upsert(customer.toSupabaseMap(user.id));
              final updated = customer.copyWith(isSynced: true);
              await _db.customersBox.put(updated.id, updated.toMap());
            } catch (e) {
              debugPrint('Failed to sync customer ${customer.id}: $e');
            }
          }
        }

        // 2. Bay Jobs
        if (_db.bayJobsBox.isOpen) {
          final unsyncedJobs = _db.bayJobsBox.values
              .where((m) => m['isSynced'] != true)
              .map((m) => BayJob.fromMap(m))
              .toList();

          for (final job in unsyncedJobs) {
            try {
              await c.from('bay_jobs').upsert(job.toSupabaseMap(user.id));
              final updated = job.copyWith(isSynced: true);
              await _db.bayJobsBox.put(updated.id, updated.toMap());
            } catch (e) {
              debugPrint('Failed to sync bay job ${job.id}: $e');
            }
          }
        }

        // 3. Transactions
        if (_db.transactionsBox.isOpen) {
          final unsyncedTx = _db.transactionsBox.values
              .where((m) => m['isSynced'] != true)
              .map((m) => TransactionRecord.fromMap(m))
              .toList();

          for (final tx in unsyncedTx) {
            try {
              await c.from('transactions').upsert(tx.toSupabaseMap(user.id));
              final updated = tx.copyWith(isSynced: true);
              await _db.transactionsBox.put(updated.id, updated.toMap());
            } catch (e) {
              debugPrint('Failed to sync transaction ${tx.id}: $e');
            }
          }
        }
      } while (_hasPendingPush);

      _lastSyncTime = DateTime.now();
    } catch (e) {
      _syncError = e.toString();
      debugPrint('SyncService.pushUnsynced error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> pullRemoteData() async {
    final c = client;
    final user = currentCloudUser;
    if (c == null || user == null) return;

    _isSyncing = true;
    _syncError = null;
    notifyListeners();

    try {
      // 1. Pull Customers
      if (_db.customersBox.isOpen) {
        final List<dynamic> remoteCustomers =
            await c.from('customers').select().eq('user_id', user.id);

        for (final raw in remoteCustomers) {
          if (raw is Map) {
            final remoteCust = Customer.fromMap(Map<String, dynamic>.from(raw));
            final localMap = _db.customersBox.get(remoteCust.id);
            if (localMap == null) {
              await _db.customersBox
                  .put(remoteCust.id, remoteCust.copyWith(isSynced: true).toMap());
            } else {
              final localCust = Customer.fromMap(localMap);
              if (remoteCust.updatedAt.isAfter(localCust.updatedAt)) {
                await _db.customersBox.put(
                    remoteCust.id, remoteCust.copyWith(isSynced: true).toMap());
              }
            }
          }
        }
      }

      // 2. Pull Bay Jobs
      if (_db.bayJobsBox.isOpen) {
        final List<dynamic> remoteJobs =
            await c.from('bay_jobs').select().eq('user_id', user.id);

        for (final raw in remoteJobs) {
          if (raw is Map) {
            final remoteJob = BayJob.fromMap(Map<String, dynamic>.from(raw));
            final localMap = _db.bayJobsBox.get(remoteJob.id);
            if (localMap == null) {
              await _db.bayJobsBox
                  .put(remoteJob.id, remoteJob.copyWith(isSynced: true).toMap());
            } else {
              final localJob = BayJob.fromMap(localMap);
              if (remoteJob.updatedAt.isAfter(localJob.updatedAt)) {
                await _db.bayJobsBox.put(
                    remoteJob.id, remoteJob.copyWith(isSynced: true).toMap());
              }
            }
          }
        }
      }

      // 3. Pull Transactions
      if (_db.transactionsBox.isOpen) {
        final List<dynamic> remoteTx =
            await c.from('transactions').select().eq('user_id', user.id);

        for (final raw in remoteTx) {
          if (raw is Map) {
            final remoteRecord =
                TransactionRecord.fromMap(Map<String, dynamic>.from(raw));
            final localMap = _db.transactionsBox.get(remoteRecord.id);
            if (localMap == null) {
              await _db.transactionsBox.put(
                  remoteRecord.id, remoteRecord.copyWith(isSynced: true).toMap());
            } else {
              final localRecord = TransactionRecord.fromMap(localMap);
              if (remoteRecord.updatedAt.isAfter(localRecord.updatedAt)) {
                await _db.transactionsBox.put(remoteRecord.id,
                    remoteRecord.copyWith(isSynced: true).toMap());
              }
            }
          }
        }
      }

      _lastSyncTime = DateTime.now();

      // Refresh memory cache in active repository
      if (_repository != null) {
        await _repository!.loadAllData();
      } else {
        try {
          final repo = GarageRepository();
          await repo.loadAllData();
        } catch (_) {}
      }
    } catch (e) {
      _syncError = e.toString();
      debugPrint('SyncService.pullRemoteData error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Fire-and-forget non-blocking push with fast debounce (<300ms)
  void pushUnsyncedData() {
    // Notify immediately so UI badge / pendingUploads updates reactively
    notifyListeners();

    if (!isCloudAuthenticated || !isOnline) return;

    _pushDebounceTimer?.cancel();
    _pushDebounceTimer = Timer(const Duration(milliseconds: 150), () {
      unawaited(pushUnsynced());
    });
  }

  /// Pull remote changes first, then push any pending local records
  Future<void> syncAll() async {
    await pullRemoteData();
    await pushUnsynced();
  }

  Future<void> deleteRemoteCustomer(String customerId) async {
    final c = client;
    final user = currentCloudUser;
    if (c == null || user == null) return;
    try {
      await c.from('customers').delete().eq('id', customerId).eq('user_id', user.id);
    } catch (e) {
      debugPrint('SyncService.deleteRemoteCustomer error: $e');
    }
  }

  Future<void> deleteRemoteBayJob(String jobId) async {
    final c = client;
    final user = currentCloudUser;
    if (c == null || user == null) return;
    try {
      await c.from('bay_jobs').delete().eq('id', jobId).eq('user_id', user.id);
    } catch (e) {
      debugPrint('SyncService.deleteRemoteBayJob error: $e');
    }
  }

  Future<void> deleteRemoteTransaction(String txId) async {
    final c = client;
    final user = currentCloudUser;
    if (c == null || user == null) return;
    try {
      await c.from('transactions').delete().eq('id', txId).eq('user_id', user.id);
    } catch (e) {
      debugPrint('SyncService.deleteRemoteTransaction error: $e');
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _pushDebounceTimer?.cancel();
    super.dispose();
  }
}
