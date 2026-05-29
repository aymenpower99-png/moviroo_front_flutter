import 'dart:convert';

class AuthHelpers {
  static bool isTokenExpired(String token, {int bufferSeconds = 60}) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      // Base64 URL decode
      final normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      final decoded = base64.decode(normalized);
      final payload = jsonDecode(utf8.decode(decoded));
      final exp = payload['exp'];
      if (exp == null) return true;
      // Treat token as expired 60s before actual expiry to avoid races
      return DateTime.now().millisecondsSinceEpoch / 1000 >
          (exp - bufferSeconds);
    } catch (e) {
      return true;
    }
  }

  /// Extracts the user identifier from a JWT access token payload.
  /// Tries `sub`, then `id`, then `userId`.
  static String? extractUserId(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      final decoded = base64.decode(normalized);
      final payload = jsonDecode(utf8.decode(decoded));
      return payload['sub'] as String? ??
          payload['id'] as String? ??
          payload['userId'] as String?;
    } catch (_) {
      return null;
    }
  }
}
