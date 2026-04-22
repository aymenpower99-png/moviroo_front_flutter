import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../core/config/app_config.dart';
import 'auth_storage.dart';

class AuthOAuth {
  static const String baseUrl = AppConfig.baseUrl;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  static Future<Map<String, dynamic>> googleSignIn() async {
    try {
      // Force account picker by clearing cached session
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in cancelled');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Failed to get Google ID token');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['accessToken'] as String?;
        final refreshToken = data['refreshToken'] as String?;
        if (accessToken != null && refreshToken != null) {
          await AuthStorage.saveTokens(accessToken, refreshToken);
        }
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Google sign-in failed');
      }
    } catch (e) {
      await _googleSignIn.signOut();
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> appleSignIn() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final String? idToken = credential.identityToken;
      if (idToken == null) {
        throw Exception('Failed to get Apple ID token');
      }

      final fullName =
          credential.givenName != null && credential.familyName != null
          ? '${credential.givenName} ${credential.familyName}'
          : null;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/apple'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken,
          if (fullName != null) 'fullName': fullName,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['accessToken'] as String?;
        final refreshToken = data['refreshToken'] as String?;
        if (accessToken != null && refreshToken != null) {
          await AuthStorage.saveTokens(accessToken, refreshToken);
        }
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Apple sign-in failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> signOutGoogle() async {
    final googleSignIn = GoogleSignIn(scopes: ['email']);
    await googleSignIn.signOut();
  }
}
