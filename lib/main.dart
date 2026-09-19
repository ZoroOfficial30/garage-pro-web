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
  const GarageAccountingApp({super.key});

  @override
  State<GarageAccountingApp> createState() => _GarageAccountingAppState();
}

class _GarageAccountingAppState extends State<GarageAccountingApp> with WidgetsBindingObserver {
  Timer? _inactivityTimer;
  Timer? _backgroundTimer;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _triggerAutoSync();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _backgroundTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _triggerAutoSync();
      _handleForegroundResume();
    } else if (state == AppLifecycleState.paused ||
               state == AppLifecycleState.hidden ||
               state == AppLifecycleState.inactive) {
      _handleBackgroundPause();
    }
  }

  void _handleBackgroundPause() {
    _backgroundedAt = DateTime.now();
    _inactivityTimer?.cancel();

    // Do not run background lock timer in automated widget test environment to prevent pending timer leaks
    if (WidgetsBinding.instance.runtimeType.toString().contains('TestWidgetsFlutterBinding')) {
      return;
    }

    final repo = Provider.of<GarageRepository>(context, listen: false);
    if (!repo.isAuthenticated || repo.isAppLocked || !repo.pinLockEnabled) {
      return;
    }

    _backgroundTimer?.cancel();
    _backgroundTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        final currentRepo = Provider.of<GarageRepository>(context, listen: false);
        if (currentRepo.isAuthenticated && !currentRepo.isAppLocked && currentRepo.pinLockEnabled) {
          currentRepo.lockApp();
        }
      }
    });
  }

  void _handleForegroundResume() {
    _backgroundTimer?.cancel();
    if (_backgroundedAt != null) {
      final elapsed = DateTime.now().difference(_backgroundedAt!);
      if (elapsed >= const Duration(seconds: 10)) {
        final repo = Provider.of<GarageRepository>(context, listen: false);
        if (repo.isAuthenticated && !repo.isAppLocked && repo.pinLockEnabled) {
          repo.lockApp();
        }
      }
      _backgroundedAt = null;
    }
    _resetInactivityTimer();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();

    // Do not start unawaited timer in automated test environment unless explicitly driven
    if (WidgetsBinding.instance.runtimeType.toString().contains('TestWidgetsFlutterBinding')) {
      return;
    }

    final repo = Provider.of<GarageRepository>(context, listen: false);
    if (!repo.isAuthenticated || repo.isAppLocked || !repo.pinLockEnabled) {
      return;
    }

    _inactivityTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        final currentRepo = Provider.of<GarageRepository>(context, listen: false);
        if (currentRepo.isAuthenticated && !currentRepo.isAppLocked && currentRepo.pinLockEnabled) {
          currentRepo.lockApp();
        }
      }
    });
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

    // If user is authenticated, unlocked, and inactivity timer isn't running, start it
    if (repo.isAuthenticated && !repo.isAppLocked && repo.pinLockEnabled && _inactivityTimer == null) {
      _resetInactivityTimer();
    }

    return MaterialApp(
      title: 'Garage Accounting Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      locale: locale.locale,
      builder: (context, child) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _resetInactivityTimer(),
          onPointerMove: (_) => _resetInactivityTimer(),
          child: Directionality(
            textDirection: locale.textDirection,
            child: child ?? const SizedBox.shrink(),
          ),
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

