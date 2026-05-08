import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../../core/storage/token_storage.dart';
import 'auth_storage.dart';

class WebAuthnApiService {
  static const String baseUrl = AppConfig.baseUrl;

  static Future<Map<String, dynamic>> startRegistration({
    String? deviceName,
    String? accessToken,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/passkeys/register/start'),
      headers: {
        'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        if (deviceName != null) 'deviceName': deviceName,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to start passkey registration');
  }

  static Future<Map<String, dynamic>> finishRegistration({
    required Map<String, dynamic> dto,
    String? accessToken,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/passkeys/register/finish'),
      headers: {
        'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(dto),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to finish passkey registration');
  }

  static Future<Map<String, dynamic>> startAuthentication({
    String? email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/passkeys/authenticate/start'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        if (email != null) 'email': email,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to start passkey authentication');
  }

  static Future<Map<String, dynamic>> finishAuthentication({
    required Map<String, dynamic> dto,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/passkeys/authenticate/finish'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dto),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      // Save tokens just like regular login
      final accessToken = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;
      if (accessToken != null && refreshToken != null) {
        await AuthStorage.saveTokens(accessToken, refreshToken);
        await TokenStorage.saveTokens(access: accessToken, refresh: refreshToken);
        if (data['user'] != null) {
          await TokenStorage.saveUser(jsonEncode(data['user']));
        }
      }
      return data;
    }
    throw Exception('Failed to finish passkey authentication');
  }

  static Future<List<dynamic>> listPasskeys(String accessToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/passkeys'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to list passkeys');
  }

  static Future<void> deletePasskey(String id, String accessToken) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/auth/passkeys/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete passkey');
    }
  }

  static Future<void> renamePasskey(
    String id,
    String deviceName,
    String accessToken,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/auth/passkeys/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({'deviceName': deviceName}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to rename passkey');
    }
  }
}
