import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Platform-safe biometric authentication service.
/// Automatically detects Web platforms (kIsWeb) and gracefully disables hardware biometrics
/// to prevent MissingPluginException or unsupported platform errors on Vercel web deployments.
class BiometricAuthService {
  static final BiometricAuthService _instance = BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;
  BiometricAuthService._internal();

  LocalAuthentication _auth = LocalAuthentication();

  @visibleForTesting
  void setMockAuth(LocalAuthentication mockAuth) {
    _auth = mockAuth;
  }

  /// Whether biometrics are supported on the current platform and device.
  /// Always returns false on Web (kIsWeb) without calling native platform channels.
  Future<bool> isBiometricAvailable() async {
    if (kIsWeb) {
      return false;
    }
    try {
      final isSupported = await _auth.isDeviceSupported();
      if (!isSupported) return false;
      return await _auth.canCheckBiometrics;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      debugPrint('BiometricAuthService.isBiometricAvailable error: $e');
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Authenticate the user with biometrics (Fingerprint / Face ID).
  /// Always returns false on Web (kIsWeb) with zero side effects.
  Future<bool> authenticate({
    String localizedReason = 'Authenticate to unlock Garage Accounting Pro',
    bool biometricOnly = true,
  }) async {
    if (kIsWeb) {
      return false;
    }
    try {
      final available = await isBiometricAvailable();
      if (!available) return false;

      return await _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: biometricOnly,
        persistAcrossBackgrounding: true,
      );
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      debugPrint('BiometricAuthService.authenticate platform error: $e');
      return false;
    } catch (e) {
      return false;
    }
  }
}
