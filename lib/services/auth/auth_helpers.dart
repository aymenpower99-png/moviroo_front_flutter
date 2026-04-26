import 'dart:convert';

class AuthHelpers {
  static bool isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      // Base64 URL decode
      final normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      final decoded = base64.decode(normalized);
      final payload = jsonDecode(utf8.decode(decoded));
      final exp = payload['exp'];
      if (exp == null) return true;
      return DateTime.now().millisecondsSinceEpoch / 1000 > exp;
    } catch (e) {
      return true;
    }
  }
}
