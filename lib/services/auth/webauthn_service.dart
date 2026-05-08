import 'dart:convert';
import 'webauthn_api_service.dart';
import 'webauthn_platform_channel.dart';
import '../auth_service/auth_service.dart';

class WebAuthnService {
  final AuthService _authService = AuthService();

  /// Register a new passkey for the current user.
  /// Must be called when user is already logged in.
  Future<Map<String, dynamic>> registerPasskey({String? deviceName}) async {
    final token = await _authService.getAccessToken();
    if (token == null) throw Exception('User must be logged in');

    // 1. Start registration
    final startResult = await WebAuthnApiService.startRegistration(
      deviceName: deviceName,
      accessToken: token,
    );
    final optionsId = startResult['optionsId'] as String;
    final options = startResult['options'] as Map<String, dynamic>;

    // Defensive patch: ensure RP ID is never localhost for mobile
    final rp = options['rp'] as Map<String, dynamic>?;
    if (rp != null && rp['id'] == 'localhost') {
      rp['id'] = 'com.example.moviroo';
    }

    // 2. Call native WebAuthn to create credential
    final nativeResponse = await WebAuthnPlatformChannel.register(
      jsonEncode(options),
    );

    // 3. Finish registration
    return WebAuthnApiService.finishRegistration(
      dto: {
        'optionsId': optionsId,
        ...nativeResponse,
      },
      accessToken: token,
    );
  }

  /// Authenticate with passkey (passwordless login).
  Future<Map<String, dynamic>> authenticateWithPasskey({String? email}) async {
    // 1. Start authentication
    final startResult = await WebAuthnApiService.startAuthentication(
      email: email,
    );
    final optionsId = startResult['optionsId'] as String;
    final options = startResult['options'] as Map<String, dynamic>;

    // Defensive patch: ensure RP ID is never localhost for mobile
    if (options['rpId'] == 'localhost') {
      options['rpId'] = 'com.example.moviroo';
    }

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

  Future<List<dynamic>> getPasskeys() async {
    final token = await _authService.getAccessToken();
    if (token == null) throw Exception('Not authenticated');
    return WebAuthnApiService.listPasskeys(token);
  }

  Future<void> deletePasskey(String id) async {
    final token = await _authService.getAccessToken();
    if (token == null) throw Exception('Not authenticated');
    return WebAuthnApiService.deletePasskey(id, token);
  }

  Future<void> renamePasskey(String id, String deviceName) async {
    final token = await _authService.getAccessToken();
    if (token == null) throw Exception('Not authenticated');
    return WebAuthnApiService.renamePasskey(id, deviceName, token);
  }
}
