import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

import 'auth_service.dart';

/// Result of a local passkey challenge.
class PasskeyResult {
  /// The biometric method that succeeded, or null on failure.
  final String? method; // 'face' | 'fingerprint' | 'pin'

  /// Short-lived action token returned by the backend, used by sensitive
  /// endpoints (delete account, disable 2FA, change security settings).
  final String? actionToken;

  final bool success;
  final String? errorMessage;

  const PasskeyResult.success({
    required this.method,
    required this.actionToken,
  })  : success = true,
        errorMessage = null;

  const PasskeyResult.failure(this.errorMessage)
      : success = false,
        method = null,
        actionToken = null;
}

/// Passkey = device-level biometric layer (Face ID / Fingerprint / Device PIN).
///
/// Usage:
///   1. `PasskeyService.isSupported()` — check device capability before showing UI.
///   2. `PasskeyService.enable()` — register passkey on this device + backend flag.
///   3. `PasskeyService.challenge(reason: ...)` — before sensitive action.
///      Returns an `actionToken` the caller passes to the backend.
///
/// The backend NEVER receives or stores biometric data. It only:
///   - toggles a `passkeyEnabled` flag on the user
///   - issues a short-lived JWT (`actionToken`) after a successful local prompt
class PasskeyService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final AuthService _authService = AuthService();

  // ─── Device capability ────────────────────────────────────────────────────

  /// True if the device has any biometric OR device PIN set up.
  Future<bool> isSupported() async {
    try {
      final bool deviceSupported = await _localAuth.isDeviceSupported();
      final bool canCheck = await _localAuth.canCheckBiometrics;
      return deviceSupported || canCheck;
    } on PlatformException {
      return false;
    }
  }

  /// Returns a human-readable label for the strongest available method.
  Future<String> availableMethodLabel() async {
    try {
      final types = await _localAuth.getAvailableBiometrics();
      if (types.contains(BiometricType.face)) return 'Face ID';
      if (types.contains(BiometricType.fingerprint)) return 'Fingerprint';
      if (types.contains(BiometricType.iris)) return 'Iris';
      if (types.contains(BiometricType.strong) ||
          types.contains(BiometricType.weak)) {
        return 'Biometric';
      }
      return 'Device PIN';
    } on PlatformException {
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

  // ─── Enable / Disable passkey ─────────────────────────────────────────────

  /// Prompts biometric; on success tells the backend to flag passkey as enabled.
  Future<PasskeyResult> enable({String? localizedReason}) async {
    final authenticated = await _prompt(
      localizedReason ??
          'Confirm your identity to enable passkey on this device.',
    );
    if (!authenticated.success) return authenticated;

    try {
      await _authService.enablePasskey();
      return authenticated;
    } catch (e) {
      return PasskeyResult.failure(e.toString());
    }
  }

  /// Removes passkey from the backend (no biometric required to disable,
  /// since user already holds a valid session).
  Future<void> disable() => _authService.disablePasskey();

  // ─── Sensitive-action challenge ───────────────────────────────────────────

  /// Prompts biometric; on success asks the backend for a short-lived
  /// `actionToken` that can be passed to sensitive endpoints.
  Future<PasskeyResult> challenge({required String reason}) async {
    final prompt = await _prompt(reason);
    if (!prompt.success) return prompt;

    try {
      final response = await _authService.verifyPasskey(prompt.method!);
      final token = response['actionToken'] as String?;
      return PasskeyResult.success(
        method: prompt.method,
        actionToken: token,
      );
    } catch (e) {
      return PasskeyResult.failure(e.toString());
    }
  }

  // ─── Internal: prompt the OS biometric dialog ─────────────────────────────

  Future<PasskeyResult> _prompt(String reason) async {
    final List<BiometricType> types;
    try {
      types = await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return const PasskeyResult.failure(
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
        return const PasskeyResult.failure('Authentication cancelled.');
      }
      return PasskeyResult.success(
        method: _methodTagFor(types),
        actionToken: null,
      );
    } on PlatformException catch (e) {
      return PasskeyResult.failure(_prettyError(e));
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
