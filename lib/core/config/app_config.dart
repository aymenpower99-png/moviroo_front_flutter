/// ─────────────────────────────────────────────────────────────────────────────
/// AppConfig — change [baseUrl] when ngrok URL rotates.
/// ─────────────────────────────────────────────────────────────────────────────
class AppConfig {
  AppConfig._();

  /// Full backend URL including /api prefix.
  static const String baseUrl =
      'https://important-satisfy-sternness.ngrok-free.dev/api';
}
