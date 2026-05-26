import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'webauthn_api_service.dart';
import 'webauthn_platform_channel.dart';
import '../auth_service/auth_service.dart';
import 'auth_helpers.dart';

class WebAuthnService {
  final AuthService _authService = AuthService();

  /// In-memory cache so the Passkeys page feels instant on re-entry.
  /// Scoped by user ID to prevent cross-account leaks.
  static String? _cacheOwnerId;
  static List<dynamic>? _cachedPasskeys;

  /// Register a new passkey for the current user.
  /// Must be called when user is already logged in.
  /// [deviceName] is optional — if omitted the actual device model is used.
  Future<Map<String, dynamic>> registerPasskey({String? deviceName}) async {
    final token = await _authService.getAccessToken();
    if (token == null) throw Exception('User must be logged in');

    // Auto-detect device name when not supplied
    String effectiveDeviceName = deviceName ?? '';
    if (effectiveDeviceName.isEmpty) {
      try {
        final info = DeviceInfoPlugin();
        if (Platform.isAndroid) {
          final android = await info.androidInfo;
          effectiveDeviceName = android.model;
        } else if (Platform.isIOS) {
          final ios = await info.iosInfo;
          effectiveDeviceName = ios.name;
        }
      } catch (_) {
        // fallback handled below
      }
      if (effectiveDeviceName.isEmpty) {
        effectiveDeviceName = 'Passkey ${DateTime.now().year}';
      }
    }

    // 1. Start registration
    final startResult = await WebAuthnApiService.startRegistration(
      deviceName: effectiveDeviceName,
      accessToken: token,
    );

    // Device-level dedup: backend detected an existing passkey for this device
    final alreadyExists = startResult['alreadyExists'] as bool? ?? false;
    if (alreadyExists) {
      return {
        'success': true,
        'credentialId': startResult['credentialId'],
        'deviceName': startResult['deviceName'],
        'message': startResult['message'] ?? 'This passkey is already registered.',
      };
    }

    final optionsId = startResult['optionsId'] as String;
    final options = startResult['options'];

    // 2. Call native WebAuthn to create credential
    final nativeResponse = await WebAuthnPlatformChannel.register(
      jsonEncode(options),
    );

    // 3. Finish registration
    final result = await WebAuthnApiService.finishRegistration(
      dto: {
        'optionsId': optionsId,
        'deviceName': effectiveDeviceName,
        ...nativeResponse,
      },
      accessToken: token,
    );

    _cachedPasskeys = null; // invalidate cache
    return result;
  }

  /// Authenticate with passkey (passwordless login).
  Future<Map<String, dynamic>> authenticateWithPasskey({String? email}) async {
    // 1. Start authentication
    final startResult = await WebAuthnApiService.startAuthentication(
      email: email,
    );
    final optionsId = startResult['optionsId'] as String;
    final options = startResult['options'];

    // 2. Call native WebAuthn to get credential
    final nativeResponse = await WebAuthnPlatformChannel.authenticate(
      jsonEncode(options),
    );

    // 3. Finish authentication
    return WebAuthnApiService.finishAuthentication(
      dto: {
        'optionsId': optionsId,
        ...nativeResponse,
      },
    );
  }

  /// Returns the cached list if available (and owned by the current user),
  /// otherwise fetches from the API.
  Future<List<dynamic>> getPasskeys() async {
    final token = await _authService.getAccessToken();
    if (token == null) throw Exception('Not authenticated');

    final userId = AuthHelpers.extractUserId(token);
    if (userId != null && _cacheOwnerId == userId && _cachedPasskeys != null) {
      return _cachedPasskeys!;
    }

    final list = await WebAuthnApiService.listPasskeys(token);
    _cacheOwnerId = userId;
    _cachedPasskeys = list;
    return list;
  }

  Future<void> deletePasskey(String id) async {
    final token = await _authService.getAccessToken();
    if (token == null) throw Exception('Not authenticated');
    await WebAuthnApiService.deletePasskey(id, token);
    _cachedPasskeys = null;
  }

  Future<void> renamePasskey(String id, String deviceName) async {
    final token = await _authService.getAccessToken();
    if (token == null) throw Exception('Not authenticated');
    await WebAuthnApiService.renamePasskey(id, deviceName, token);
    _cachedPasskeys = null;
  }

  /// True if the service has cached passkeys for [userId].
  static bool hasCacheFor(String? userId) {
    return userId != null && _cacheOwnerId == userId && _cachedPasskeys != null;
  }

  /// Clears the in-memory passkey cache. Call on logout or account switch.
  static void clearCache() {
    _cacheOwnerId = null;
    _cachedPasskeys = null;
  }
}
