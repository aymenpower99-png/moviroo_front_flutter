import 'dart:convert';
import 'auth_http.dart';

/// Two-factor method tag used across the API.
enum TwoFactorMethod { email, totp }

TwoFactorMethod? twoFactorMethodFromString(String? value) {
  switch (value) {
    case 'email':
      return TwoFactorMethod.email;
    case 'totp':
      return TwoFactorMethod.totp;
    default:
      return null;
  }
}

String twoFactorMethodToString(TwoFactorMethod m) =>
    m == TwoFactorMethod.totp ? 'totp' : 'email';

/// All security-related HTTP calls. Thin layer on top of [AuthHTTP] that
/// handles JSON parsing and error propagation.
class SecurityApi {
  // ─── Password ─────────────────────────────────────────────────────────────

  /// PATCH /auth/me/password
  static Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await AuthHTTP.authenticatedPatch('/auth/me/password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    _ensureOk(response, 'Failed to update password');
  }

  // ─── Email 2FA ────────────────────────────────────────────────────────────

  /// PATCH /auth/2fa — toggles email 2FA on/off.
  /// When enabling, pass the OTP received by email for verification.
  static Future<Map<String, dynamic>> toggleEmail2fa(bool enabled, {String? otp}) async {
    final body = <String, dynamic>{'enabled': enabled};
    if (otp != null) body['otp'] = otp;
    final response = await AuthHTTP.authenticatedPatch('/auth/2fa', body);
    _ensureOk(response, 'Failed to update 2FA');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// POST /auth/2fa/email/request-otp — sends an OTP to the user's email
  /// so they can prove ownership before enabling email 2FA.
  static Future<void> requestEmail2faEnableOtp() async {
    final response = await AuthHTTP.authenticatedPost(
      '/auth/2fa/email/request-otp',
      const {},
    );
    _ensureOk(response, 'Failed to send verification code');
  }

  // ─── TOTP (authenticator app) ─────────────────────────────────────────────

  /// POST /auth/2fa/totp/setup — returns `{ secret, qrCodeUrl, otpauthUrl }`.
  static Future<Map<String, dynamic>> setupTotp() async {
    final response = await AuthHTTP.authenticatedPost(
      '/auth/2fa/totp/setup',
      const {},
    );
    _ensureOk(response, 'Failed to start authenticator setup');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// POST /auth/2fa/totp/confirm — verifies the first TOTP code.
  static Future<Map<String, dynamic>> confirmTotp(String code) async {
    final response = await AuthHTTP.authenticatedPost(
      '/auth/2fa/totp/confirm',
      {'code': code},
    );
    _ensureOk(response, 'Invalid authenticator code');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// DELETE /auth/2fa/totp — unlinks the authenticator app.
  static Future<Map<String, dynamic>> disableTotp() async {
    final response = await AuthHTTP.authenticatedDelete('/auth/2fa/totp');
    _ensureOk(response, 'Failed to disable authenticator');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ─── Primary 2FA method switching ─────────────────────────────────────────

  /// POST /auth/2fa/primary/email/request-otp — emails a one-time code so the
  /// user can verify their identity before switching primary method.
  static Future<void> requestPrimarySwitchEmailOtp() async {
    final response = await AuthHTTP.authenticatedPost(
      '/auth/2fa/primary/email/request-otp',
      const {},
    );
    _ensureOk(response, 'Failed to send verification code');
  }

  /// PATCH /auth/2fa/primary — switches primary 2FA method after verification.
  static Future<Map<String, dynamic>> switchPrimary2fa({
    required TwoFactorMethod method,
    required String code,
  }) async {
    final response = await AuthHTTP.authenticatedPatch('/auth/2fa/primary', {
      'method': twoFactorMethodToString(method),
      'code': code,
    });
    _ensureOk(response, 'Failed to switch primary method');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ─── Passkey (device biometric) ───────────────────────────────────────────

  /// POST /auth/passkey/enable
  static Future<void> enablePasskey() async {
    final response = await AuthHTTP.authenticatedPost(
      '/auth/passkey/enable',
      const {},
    );
    _ensureOk(response, 'Failed to enable passkey');
  }

  /// DELETE /auth/passkey
  static Future<void> disablePasskey() async {
    final response = await AuthHTTP.authenticatedDelete('/auth/passkey');
    _ensureOk(response, 'Failed to disable passkey');
  }

  /// POST /auth/passkey/verify — must be called AFTER a successful local
  /// biometric prompt (Face ID / Fingerprint / Device PIN).
  ///
  /// Returns `{ actionToken, expiresInSeconds }`. The action token proves a
  /// fresh re-auth and can be sent to sensitive endpoints (delete account, etc.).
  static Future<Map<String, dynamic>> verifyPasskey(String method) async {
    final response = await AuthHTTP.authenticatedPost(
      '/auth/passkey/verify',
      {'method': method},
    );
    _ensureOk(response, 'Passkey verification failed');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ─── Delete account ───────────────────────────────────────────────────────

  /// POST /auth/me/delete/request-otp — sends an email OTP for delete re-auth.
  static Future<void> requestDeleteOtp() async {
    final response = await AuthHTTP.authenticatedPost(
      '/auth/me/delete/request-otp',
      const {},
    );
    _ensureOk(response, 'Failed to send verification code');
  }

  /// DELETE /auth/me — hard-deletes the account.
  /// Provide exactly ONE of: password, otp, passkeyToken.
  static Future<void> deleteAccount({
    String? password,
    String? otp,
    String? passkeyToken,
  }) async {
    final body = <String, dynamic>{};
    if (password != null) body['password'] = password;
    if (otp != null) body['otp'] = otp;
    if (passkeyToken != null) body['passkeyToken'] = passkeyToken;

    final response = await AuthHTTP.authenticatedDelete('/auth/me', body: body);
    _ensureOk(response, 'Failed to delete account');
  }

  // ─── Internal ─────────────────────────────────────────────────────────────

  static void _ensureOk(dynamic response, String fallback) {
    final status = response.statusCode as int;
    if (status >= 200 && status < 300) return;
    String message = fallback;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final raw = body['message'];
      if (raw is String) {
        message = raw;
      } else if (raw is List && raw.isNotEmpty) {
        message = raw.first.toString();
      }
    } catch (_) {
      // fall through
    }
    throw SecurityApiException(message, status);
  }
}

/// Thrown when the backend rejects a security action. [statusCode] mirrors the
/// HTTP status so UI layers can branch on 401 / 400 / 409, etc.
class SecurityApiException implements Exception {
  final String message;
  final int statusCode;
  const SecurityApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
