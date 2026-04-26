import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import 'auth_storage.dart';
import 'auth_oauth.dart';
import 'auth_http.dart';

class AuthAPI {
  static const String baseUrl = AppConfig.baseUrl;

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // If email verification required, don't save tokens
      if (data['requiresVerification'] == true) {
        return data;
      }
      // If 2FA OTP required, no tokens to save
      if (data['requiresOtp'] == true) {
        return data;
      }
      final accessToken = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;
      if (accessToken == null || refreshToken == null) {
        throw Exception('Invalid login response from server.');
      }
      await AuthStorage.saveTokens(accessToken, refreshToken);
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Login failed');
    }
  }

  static Future<Map<String, dynamic>> verifyLoginOtp({
    required String preAuthToken,
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'preAuthToken': preAuthToken, 'code': code}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final accessToken = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;
      if (accessToken == null || refreshToken == null) {
        throw Exception('Invalid response from server.');
      }
      await AuthStorage.saveTokens(accessToken, refreshToken);
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'OTP verification failed');
    }
  }

  static Future<void> resendLoginOtp(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/resend-otp?purpose=login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to resend code');
    }
  }

  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'phone': ?phone,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Registration failed');
    }
  }

  static Future<Map<String, dynamic>> verifyEmail({
    required String userId,
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'code': code}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await AuthStorage.saveTokens(data['accessToken'], data['refreshToken']);
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Verification failed');
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    final response = await AuthHTTP.authenticatedPatch('/auth/me', {
      'firstName': ?firstName,
      'lastName': ?lastName,
      'phone': ?phone,
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Profile update failed');
    }
  }

  static Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to send reset email');
    }
  }

  static Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token, 'newPassword': newPassword}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Password reset failed');
    }
  }

  static Future<Map<String, dynamic>?> refreshTokens() async {
    final refreshToken = await AuthStorage.getRefreshToken();
    if (refreshToken == null) return null;

    final response = await http.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $refreshToken',
      },
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

  static Future<void> resendVerification(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/resend-verification'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to resend verification');
    }
  }

  static Future<void> logout() async {
    final accessToken = await AuthStorage.getAccessToken();
    if (accessToken != null) {
      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
    }
    await AuthStorage.clearTokens();
    // Sign out from Google to force account selection on next login
    await AuthOAuth.signOutGoogle();
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final isLoggedIn = await AuthStorage.isLoggedIn();
    if (!isLoggedIn) return null;

    try {
      final response = await AuthHTTP.authenticatedGet('/auth/me');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
