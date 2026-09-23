import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/currency/currency_manager.dart';
import 'core/localization/app_locale.dart';
import 'core/constants/api_constants.dart';
import 'core/services/sync_service.dart';
import 'data/database/database_service.dart';
import 'data/repositories/garage_repository.dart';
import 'features/navigation/main_scaffold.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
  };

  // Initialize Supabase Cloud backend
  try {
    await Supabase.initialize(
      url: ApiConstants.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: ApiConstants.supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Supabase.initialize error: $e');
  }

  // Initialize offline Hive database & sample workshop data
  final db = DatabaseService();
  try {
    await db.init();
  } catch (e, st) {
    debugPrint('DatabaseService.init error: $e\n$st');
  }

  final garageRepo = GarageRepository();
  try {
    await garageRepo.loadAllData();
  } catch (e, st) {
    debugPrint('GarageRepository.loadAllData error: $e\n$st');
  }

  // Cold Start Lock Enforcement:
  // If an owner profile exists and PIN lock is enabled, enforce LockScreen on initial startup
  if (garageRepo.isGarageSetupCompleted && garageRepo.pinLockEnabled) {
    garageRepo.lockApp();
  }

  // Initialize SyncService connectivity monitor & attach repository
  final syncService = SyncService();
  syncService.attachRepository(garageRepo);
  syncService.initConnectivityListener();

  // Automatic startup cloud sync if session exists
  if (syncService.isCloudAuthenticated && syncService.isOnline) {
    unawaited(syncService.syncAll());
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<GarageRepository>.value(value: garageRepo),
        ChangeNotifierProvider<CurrencyManager>(create: (_) => CurrencyManager()),
        ChangeNotifierProvider<AppLocaleManager>(create: (_) => AppLocaleManager()),
        ChangeNotifierProvider<SyncService>.value(value: syncService),
      ],
      child: const GarageAccountingApp(),
    ),
  );
}

class GarageAccountingApp extends StatefulWidget {
  final DateTime Function()? clock;
  final bool? enforceColdStartLock;
  const GarageAccountingApp({super.key, this.clock, this.enforceColdStartLock});

  @override
  State<GarageAccountingApp> createState() => _GarageAccountingAppState();
}

class _GarageAccountingAppState extends State<GarageAccountingApp> with WidgetsBindingObserver {
  DateTime? _backgroundTimestamp;

  DateTime _now() => widget.clock != null ? widget.clock!() : DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _triggerAutoSync();
    if (widget.enforceColdStartLock == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final repo = Provider.of<GarageRepository>(context, listen: false);
          if (repo.isGarageSetupCompleted && repo.pinLockEnabled && !repo.isAppLocked) {
            repo.lockApp();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _backgroundTimestamp ??= _now();
    } else if (state == AppLifecycleState.resumed) {
      _triggerAutoSync();
      if (_backgroundTimestamp != null) {
        final elapsed = _now().difference(_backgroundTimestamp!).inSeconds;
        _backgroundTimestamp = null;
        if (elapsed >= 10) {
          final repo = Provider.of<GarageRepository>(context, listen: false);
          if (repo.isAuthenticated && !repo.isAppLocked && repo.pinLockEnabled) {
            repo.lockApp();
          }
        }
      }
    }
  }

  void _triggerAutoSync() {
    final syncService = SyncService();
    if (syncService.isCloudAuthenticated && syncService.isOnline) {
      unawaited(syncService.syncAll());
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<AppLocaleManager>(context);
    final repo = Provider.of<GarageRepository>(context);

    return MaterialApp(
      title: 'Garage Accounting Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      locale: locale.locale,
      builder: (context, child) {
        return Directionality(
          textDirection: locale.textDirection,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: !repo.isGarageSetupCompleted
          ? const OnboardingScreen()
          : (repo.isAuthenticated && !repo.isAppLocked
              ? const MainScaffold()
              : const LoginScreen()),
    );
  }
}

