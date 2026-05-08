import 'package:flutter/services.dart';

/// Platform channel for native WebAuthn / Passkey operations.
///
/// Android: uses androidx.credentials.CredentialManager (API 21+, passkeys API 34+)
/// iOS: uses AuthenticationServices (iOS 16+)
class WebAuthnPlatformChannel {
  static const MethodChannel _channel = MethodChannel('com.moviroo/webauthn');

  /// Calls native WebAuthn credential creation (registration).
  /// Returns a Map with id, rawId, response, type fields.
  static Future<Map<String, dynamic>> register(String jsonOptions) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'register',
        {'options': jsonOptions},
      );
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException catch (e) {
      throw Exception('Passkey registration failed: ${e.message}');
    }
  }

  /// Calls native WebAuthn credential authentication (login).
  /// Returns a Map with id, rawId, response, type fields.
  static Future<Map<String, dynamic>> authenticate(String jsonOptions) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'authenticate',
        {'options': jsonOptions},
      );
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException catch (e) {
      throw Exception('Passkey authentication failed: ${e.message}');
    }
  }
}
