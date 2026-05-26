import 'package:flutter/services.dart';

/// Thrown when the user cancels a native WebAuthn prompt.
/// This is a normal user action, not an error.
class PasskeyUserCancelledException implements Exception {
  final String? message;
  const PasskeyUserCancelledException([this.message]);

  @override
  String toString() => message ?? 'Passkey setup was cancelled.';
}

/// Platform channel for native WebAuthn / Passkey operations.
///
/// Android: uses androidx.credentials.CredentialManager (API 21+, passkeys API 34+)
/// iOS: uses AuthenticationServices (iOS 16+)
class WebAuthnPlatformChannel {
  static const MethodChannel _channel = MethodChannel('com.moviroo/webauthn');

  /// True if the [message] or [code] indicates the user cancelled the prompt.
  static bool _isUserCancelled(String? code, String? message) {
    final text = '${code ?? ''} ${message ?? ''}'.toLowerCase();
    return text.contains('cancel') ||
        text.contains('usercancel') ||
        text.contains('16') ||
        text.contains('domexception');
  }

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
      if (_isUserCancelled(e.code, e.message)) {
        throw PasskeyUserCancelledException(e.message);
      }
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
      if (_isUserCancelled(e.code, e.message)) {
        throw PasskeyUserCancelledException(e.message);
      }
      throw Exception('Passkey authentication failed: ${e.message}');
    }
  }
}
