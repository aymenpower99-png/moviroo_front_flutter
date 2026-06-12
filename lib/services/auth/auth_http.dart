import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import 'auth_storage.dart';
import 'auth_helpers.dart';
import 'blocked_account_handler.dart';
import '../auth_service/auth_service.dart';

class AuthHTTP {
  // Prevents concurrent token refreshes (race condition)
  static Future<Map<String, dynamic>?>? _refreshFuture;

  static Future<http.Response> authenticatedGet(String path) async {
    String? accessToken = await AuthStorage.getAccessToken();

    // Refresh if needed
    if (accessToken != null && AuthHelpers.isTokenExpired(accessToken)) {
      await _refreshTokens();
      accessToken = await AuthStorage.getAccessToken();
    }

    if (accessToken == null) {
      throw Exception('Not authenticated');
    }

    final response = await _safeRequest(
      () => http
          .get(
            Uri.parse('${_getBaseUrl()}$path'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw Exception('Request timed out. Check your connection.'),
          ),
    );

    _checkBlocked(response);

    if (response.statusCode == 401) {
      final refreshed = await _refreshTokens();
      if (refreshed != null) {
        return authenticatedGet(path);
      }
      throw Exception('Authentication failed');
    }

    return response;
  }

  static Future<http.Response> authenticatedPost(
    String path,
    Map<String, dynamic> body,
  ) async {
    String? accessToken = await AuthStorage.getAccessToken();

    // Refresh if needed
    if (accessToken != null && AuthHelpers.isTokenExpired(accessToken)) {
      await _refreshTokens();
      accessToken = await AuthStorage.getAccessToken();
    }

    if (accessToken == null) {
      throw Exception('Not authenticated');
    }

    final response = await _safeRequest(
      () => http
          .post(
            Uri.parse('${_getBaseUrl()}$path'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw Exception('Request timed out. Check your connection.'),
          ),
    );

    _checkBlocked(response);

    if (response.statusCode == 401) {
      final refreshed = await _refreshTokens();
      if (refreshed != null) {
        return authenticatedPost(path, body);
      }
      throw Exception('Authentication failed');
    }

    return response;
  }

  static Future<http.Response> authenticatedPatch(
    String path,
    Map<String, dynamic> body,
  ) async {
    String? accessToken = await AuthStorage.getAccessToken();

    if (accessToken != null && AuthHelpers.isTokenExpired(accessToken)) {
      await _refreshTokens();
      accessToken = await AuthStorage.getAccessToken();
    }

    if (accessToken == null) {
      throw Exception('Not authenticated');
    }

    final response = await _safeRequest(
      () => http
          .patch(
            Uri.parse('${_getBaseUrl()}$path'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw Exception('Request timed out. Check your connection.'),
          ),
    );

    _checkBlocked(response);

    if (response.statusCode == 401) {
      final refreshed = await _refreshTokens();
      if (refreshed != null) {
        return authenticatedPatch(path, body);
      }
      throw Exception('Authentication failed');
    }

    return response;
  }

  static Future<http.Response> authenticatedDelete(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? extraHeaders,
  }) async {
    String? accessToken = await AuthStorage.getAccessToken();

    if (accessToken != null && AuthHelpers.isTokenExpired(accessToken)) {
      await _refreshTokens();
      accessToken = await AuthStorage.getAccessToken();
    }

    if (accessToken == null) {
      throw Exception('Not authenticated');
    }

    final response = await _safeRequest(
      () => http
          .delete(
            Uri.parse('${_getBaseUrl()}$path'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
              if (extraHeaders != null) ...extraHeaders,
            },
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw Exception('Request timed out. Check your connection.'),
          ),
    );

    _checkBlocked(response);

    if (response.statusCode == 401) {
      final refreshed = await _refreshTokens();
      if (refreshed != null) {
        return authenticatedDelete(
          path,
          body: body,
          extraHeaders: extraHeaders,
        );
      }
      throw Exception('Authentication failed');
    }

    return response;
  }

  // ─── Blocked account check ───────────────────────────────────────────────

  static void _checkBlocked(http.Response response) {
    if (response.statusCode == 403) {
      try {
        final body = jsonDecode(response.body);
        final msg = (body['message'] ?? '').toString().toLowerCase();
        if (msg.contains('blocked')) {
          AuthStorage.clearTokens();
          AuthService.setBlocked(true);
          throw BlockedAccountException(
            'Your account has been blocked. Please contact support.',
          );
        }
      } on FormatException catch (_) {
        // Not JSON — ignore
      }
    }
  }

  static Future<Map<String, dynamic>?> _refreshTokens() {
    // Deduplicate: if a refresh is already in-flight, reuse it
    _refreshFuture ??= _doRefresh().whenComplete(() => _refreshFuture = null);
    return _refreshFuture!;
  }

  static Future<Map<String, dynamic>?> _doRefresh() async {
    final refreshToken = await AuthStorage.getRefreshToken();
    if (refreshToken == null) return null;

    try {
      final response = await _safeRequest(
        () => http
            .post(
              Uri.parse('${_getBaseUrl()}/auth/refresh'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $refreshToken',
              },
            )
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () =>
                  throw Exception('Request timed out. Check your connection.'),
            ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await AuthStorage.saveTokens(data['accessToken'], data['refreshToken']);
        return data;
      } else {
        // Only clear tokens on auth failure (4xx), not network errors
        if (response.statusCode == 401 || response.statusCode == 403) {
          await AuthStorage.clearTokens();
        }
        return null;
      }
    } catch (_) {
      // Network error — don't clear tokens, allow retry
      return null;
    }
  }

  static String _getBaseUrl() {
    return AppConfig.baseUrl;
  }

  // ─── Transport error handling ──────────────────────────────────────────────

  static Future<T> _safeRequest<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on HandshakeException catch (_) {
      throw Exception(
        'Secure connection failed. Please check your network and try again.',
      );
    } on CertificateException catch (_) {
      throw Exception(
        'Secure connection failed due to an invalid certificate.',
      );
    } on SocketException catch (_) {
      throw Exception(
        'No internet connection. Please check your network and try again.',
      );
    } on http.ClientException catch (_) {
      throw Exception(
        'Connection failed. Please check your network and try again.',
      );
    } on TimeoutException catch (_) {
      throw Exception('Request timed out. Check your connection.');
    } on FormatException catch (_) {
      throw Exception('Invalid response from server. Please try again later.');
    }
  }
}
