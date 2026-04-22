import 'package:http/http.dart' as http;
import 'auth/auth_storage.dart';
import 'auth/auth_helpers.dart';
import 'auth/auth_oauth.dart';
import 'auth/auth_api.dart';
import 'auth/auth_http.dart';
import 'auth/security_api.dart';
export 'auth/security_api.dart'
    show TwoFactorMethod, SecurityApiException, twoFactorMethodFromString;

class AuthService {
  // ─── User Data Cache ──────────────────────────────────────────────────────
  static Map<String, dynamic>? _cachedUser;

  void invalidateUserCache() => _cachedUser = null;

  Map<String, dynamic>? getCachedUser() => _cachedUser;

  // ─── Token Management ───────────────────────────────────────────────────────

  Future<String?> getAccessToken() => AuthStorage.getAccessToken();
  Future<String?> getRefreshToken() => AuthStorage.getRefreshToken();
  Future<void> saveTokens(String accessToken, String refreshToken) =>
      AuthStorage.saveTokens(accessToken, refreshToken);
  Future<void> clearTokens() => AuthStorage.clearTokens();
  Future<bool> isLoggedIn() => AuthStorage.isLoggedIn();

  // ─── Session Restore ───────────────────────────────────────────────────────

  /// Attempts to restore a previous session using the stored refresh token.
  /// Returns true if the session was restored, false otherwise.
  /// Also fetches and caches user profile data to avoid flicker on navigation.
  Future<bool> tryRestoreSession() async {
    final refreshToken = await AuthStorage.getRefreshToken();
    if (refreshToken == null) return false;

    // Check if access token is still valid first
    final accessToken = await AuthStorage.getAccessToken();
    if (accessToken != null && !AuthHelpers.isTokenExpired(accessToken)) {
      // Token valid — fetch and cache user profile
      await getCurrentUser();
      return true;
    }

    // Access token expired or missing — try refreshing
    final result = await AuthAPI.refreshTokens();
    if (result != null) {
      // Refresh successful — fetch and cache user profile
      await getCurrentUser();
      return true;
    }
    return false;
  }

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

  // ─── Security: Password / 2FA / Passkey / Delete ─────────────────────────

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await SecurityApi.updatePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<Map<String, dynamic>> toggleEmail2fa(bool enabled, {String? otp}) async {
    final result = await SecurityApi.toggleEmail2fa(enabled, otp: otp);
    _cachedUser = null;
    return result;
  }

  Future<void> requestEmail2faEnableOtp() =>
      SecurityApi.requestEmail2faEnableOtp();

  Future<Map<String, dynamic>> setupTotp() => SecurityApi.setupTotp();

  Future<Map<String, dynamic>> confirmTotp(String code) async {
    final result = await SecurityApi.confirmTotp(code);
    _cachedUser = null;
    return result;
  }

  Future<Map<String, dynamic>> disableTotp() async {
    final result = await SecurityApi.disableTotp();
    _cachedUser = null;
    return result;
  }

  Future<void> requestPrimarySwitchEmailOtp() =>
      SecurityApi.requestPrimarySwitchEmailOtp();

  Future<Map<String, dynamic>> switchPrimary2fa({
    required TwoFactorMethod method,
    required String code,
  }) async {
    final result = await SecurityApi.switchPrimary2fa(
      method: method,
      code: code,
    );
    _cachedUser = null;
    return result;
  }

  Future<void> enablePasskey() async {
    await SecurityApi.enablePasskey();
    _cachedUser = null;
  }

  Future<void> disablePasskey() async {
    await SecurityApi.disablePasskey();
    _cachedUser = null;
  }

  Future<Map<String, dynamic>> verifyPasskey(String method) =>
      SecurityApi.verifyPasskey(method);

  Future<void> requestDeleteOtp() => SecurityApi.requestDeleteOtp();

  Future<void> deleteAccount({
    String? password,
    String? otp,
    String? passkeyToken,
  }) async {
    await SecurityApi.deleteAccount(
      password: password,
      otp: otp,
      passkeyToken: passkeyToken,
    );
    await AuthStorage.clearTokens();
    _cachedUser = null;
  }
}
