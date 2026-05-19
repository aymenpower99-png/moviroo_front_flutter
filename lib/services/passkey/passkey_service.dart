import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

import '../auth_service/auth_service.dart';

/// Result of a local biometric authentication challenge.
class BiometricResult {
  /// The biometric method that succeeded, or null on failure.
  final String? method; // 'face' | 'fingerprint' | 'pin'

  /// Short-lived action token returned by the backend, used by sensitive
  /// endpoints (delete account, disable 2FA, change security settings).
  final String? actionToken;

  final bool success;
  final String? errorMessage;

  const BiometricResult.success({
    required this.method,
    required this.actionToken,
  }) : success = true,
       errorMessage = null;

  const BiometricResult.failure(this.errorMessage)
    : success = false,
      method = null,
      actionToken = null;
}

/// Biometric Authentication = device-level biometric layer (Face ID / Fingerprint / Device PIN).
///
/// Usage:
///   1. `BiometricService.isSupported()` — check device capability before showing UI.
///   2. `BiometricService.enable()` — register biometric on this device + backend flag.
///   3. `BiometricService.challenge(reason: ...)` — before sensitive action.
///      Returns an `actionToken` the caller passes to the backend.
///
/// The backend NEVER receives or stores biometric data. It only:
///   - toggles a `passkeyEnabled` flag on the user
///   - issues a short-lived JWT (`actionToken`) after a successful local prompt
class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final AuthService _authService = AuthService();

  // ─── In-memory device capability cache (never changes during a session) ───
  static bool? _deviceSupportedCache;
  static String? _methodLabelCache;

  // ─── Device capability ────────────────────────────────────────────────────

  /// True if the device has any biometric OR device PIN set up.
  /// Result is cached for the app session to avoid repeated OS calls.
  Future<bool> isSupported() async {
    if (_deviceSupportedCache != null) return _deviceSupportedCache!;
    try {
      final bool deviceSupported = await _localAuth.isDeviceSupported();
      final bool canCheck = await _localAuth.canCheckBiometrics;
      _deviceSupportedCache = deviceSupported || canCheck;
      return _deviceSupportedCache!;
    } on PlatformException {
      _deviceSupportedCache = false;
      return false;
    }
  }

  /// Returns a human-readable label for the strongest available method.
  /// Result is cached for the app session.
  Future<String> availableMethodLabel() async {
    if (_methodLabelCache != null) return _methodLabelCache!;
    try {
      final types = await _localAuth.getAvailableBiometrics();
      if (types.contains(BiometricType.face)) {
        _methodLabelCache = 'Face ID';
      } else if (types.contains(BiometricType.fingerprint)) {
        _methodLabelCache = 'Fingerprint';
      } else if (types.contains(BiometricType.iris)) {
        _methodLabelCache = 'Iris';
      } else if (types.contains(BiometricType.strong) ||
          types.contains(BiometricType.weak)) {
        _methodLabelCache = 'Biometric';
      } else {
        _methodLabelCache = 'Device PIN';
      }
      return _methodLabelCache!;
    } on PlatformException {
      _methodLabelCache = 'Device PIN';
      return 'Device PIN';
    }
  }

  /// Maps a [BiometricType] to our backend enum tag.
  String _methodTagFor(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) return 'face';
    if (types.contains(BiometricType.fingerprint) ||
        types.contains(BiometricType.iris) ||
        types.contains(BiometricType.strong) ||
        types.contains(BiometricType.weak)) {
      return 'fingerprint';
    }
    return 'pin';
  }

  // ─── Enable / Disable biometric ─────────────────────────────────────────────

  /// Prompts biometric; on success tells the backend to flag biometric as enabled.
  Future<BiometricResult> enable({String? localizedReason}) async {
    final authenticated = await _prompt(
      localizedReason ??
          'Confirm your identity to enable biometric authentication on this device.',
    );
    if (!authenticated.success) return authenticated;

    try {
      await _authService.enablePasskey();
      return authenticated;
    } catch (e) {
      return BiometricResult.failure(e.toString());
    }
  }

  /// Removes biometric from the backend (no biometric required to disable,
  /// since user already holds a valid session).
  Future<void> disable() => _authService.disablePasskey();

  // ─── Sensitive-action challenge ───────────────────────────────────────────

  /// Prompts biometric; on success asks the backend for a short-lived
  /// `actionToken` that can be passed to sensitive endpoints.
  ///
  /// [purpose] scopes the token so it cannot be reused for a different
  /// sensitive action (e.g. 'disable-totp', 'delete-account').
  Future<BiometricResult> challenge({
    required String reason,
    String purpose = 'general',
  }) async {
    final prompt = await _prompt(reason);
    if (!prompt.success) return prompt;

    try {
      final response = await _authService.verifyPasskey(
        prompt.method!,
        purpose: purpose,
      );
      final token = response['actionToken'] as String?;
      return BiometricResult.success(method: prompt.method, actionToken: token);
    } catch (e) {
      return BiometricResult.failure(e.toString());
    }
  }

  // ─── Internal: prompt the OS biometric dialog ─────────────────────────────

  Future<BiometricResult> _prompt(String reason) async {
    final List<BiometricType> types;
    try {
      types = await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return const BiometricResult.failure(
        'Biometric authentication is not available on this device.',
      );
    }

    try {
      final ok = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          // Fall back to device PIN / pattern if biometric fails
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      if (!ok) {
        return const BiometricResult.failure('Authentication cancelled.');
      }
      return BiometricResult.success(
        method: _methodTagFor(types),
        actionToken: null,
      );
    } on PlatformException catch (e) {
      return BiometricResult.failure(_prettyError(e));
    }
  }

  String _prettyError(PlatformException e) {
    switch (e.code) {
      case auth_error.notAvailable:
        return 'Biometric hardware is not available.';
      case auth_error.notEnrolled:
        return 'No biometric or device PIN is set up. Please add one in system settings.';
      case auth_error.lockedOut:
      case auth_error.permanentlyLockedOut:
        return 'Too many failed attempts. Try again later or use device PIN.';
      case auth_error.passcodeNotSet:
        return 'Please set up a device PIN or passcode in system settings.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}
