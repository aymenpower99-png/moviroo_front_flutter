import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import 'auth_storage.dart';
import 'auth_helpers.dart';

class AuthHTTP {
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

    final response = await http.get(
      Uri.parse('${_getBaseUrl()}$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('Request timed out. Check your connection.'),
    );

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

    final response = await http.post(
      Uri.parse('${_getBaseUrl()}$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(body),
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('Request timed out. Check your connection.'),
    );

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

    final response = await http.patch(
      Uri.parse('${_getBaseUrl()}$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(body),
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('Request timed out. Check your connection.'),
    );

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
  }) async {
    String? accessToken = await AuthStorage.getAccessToken();

    if (accessToken != null && AuthHelpers.isTokenExpired(accessToken)) {
      await _refreshTokens();
      accessToken = await AuthStorage.getAccessToken();
    }

    if (accessToken == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.delete(
      Uri.parse('${_getBaseUrl()}$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: body != null ? jsonEncode(body) : null,
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('Request timed out. Check your connection.'),
    );

    if (response.statusCode == 401) {
      final refreshed = await _refreshTokens();
      if (refreshed != null) {
        return authenticatedDelete(path, body: body);
      }
      throw Exception('Authentication failed');
    }

    return response;
  }

  static Future<Map<String, dynamic>?> _refreshTokens() async {
    final refreshToken = await AuthStorage.getRefreshToken();
    if (refreshToken == null) return null;

    final response = await http.post(
      Uri.parse('${_getBaseUrl()}/auth/refresh'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $refreshToken',
      },
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('Request timed out. Check your connection.'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await AuthStorage.saveTokens(data['accessToken'], data['refreshToken']);
      return data;
    } else {
      await AuthStorage.clearTokens();
      return null;
    }
  }

  static String _getBaseUrl() {
    return AppConfig.baseUrl;
  }
}
