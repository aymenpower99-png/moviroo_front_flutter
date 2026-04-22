import 'package:http/http.dart' as http;
import 'auth/auth_storage.dart';
import 'auth/auth_oauth.dart';
import 'auth/auth_api.dart';
import 'auth/auth_http.dart';

class AuthService {
  // ─── User Data Cache ──────────────────────────────────────────────────────
  static Map<String, dynamic>? _cachedUser;

  void invalidateUserCache() => _cachedUser = null;

  // ─── Token Management ───────────────────────────────────────────────────────

  Future<String?> getAccessToken() => AuthStorage.getAccessToken();
  Future<String?> getRefreshToken() => AuthStorage.getRefreshToken();
  Future<void> saveTokens(String accessToken, String refreshToken) =>
      AuthStorage.saveTokens(accessToken, refreshToken);
  Future<void> clearTokens() => AuthStorage.clearTokens();
  Future<bool> isLoggedIn() => AuthStorage.isLoggedIn();

  // ─── Login / Register ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    _cachedUser = null;
    return AuthAPI.login(email: email, password: password);
  }

  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
  }) => AuthAPI.register(
    firstName: firstName,
    lastName: lastName,
    email: email,
    password: password,
    phone: phone,
  );

  Future<Map<String, dynamic>> verifyEmail({
    required String userId,
    required String code,
  }) => AuthAPI.verifyEmail(userId: userId, code: code);

  // ─── OAuth: Google ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> googleSignIn() => AuthOAuth.googleSignIn();

  // ─── OAuth: Apple ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> appleSignIn() => AuthOAuth.appleSignIn();

  // ─── Update Profile ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    _cachedUser = null;
    return AuthAPI.updateProfile(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
    );
  }

  // ─── Forgot / Reset Password ─────────────────────────────────────────────────

  Future<void> forgotPassword(String email) => AuthAPI.forgotPassword(email);
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) => AuthAPI.resetPassword(token: token, newPassword: newPassword);

  // ─── Token Refresh ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> refreshTokens() => AuthAPI.refreshTokens();

  // ─── Resend Verification ───────────────────────────────────────────────────

  Future<void> resendVerification(String email) =>
      AuthAPI.resendVerification(email);

  // ─── Logout ─────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    _cachedUser = null;
    return AuthAPI.logout();
  }

  // ─── Get Current User ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getCurrentUser({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedUser != null) return _cachedUser;
    _cachedUser = await AuthAPI.getCurrentUser();
    return _cachedUser;
  }

  // ─── HTTP Client with Authorization ───────────────────────────────────────────

  Future<http.Response> authenticatedGet(String path) =>
      AuthHTTP.authenticatedGet(path);

  Future<http.Response> authenticatedPost(
    String path,
    Map<String, dynamic> body,
  ) => AuthHTTP.authenticatedPost(path, body);

  Future<http.Response> authenticatedPatch(
    String path,
    Map<String, dynamic> body,
  ) => AuthHTTP.authenticatedPatch(path, body);
}
