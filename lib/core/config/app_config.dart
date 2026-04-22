/// ─────────────────────────────────────────────────────────────────────────────
/// AppConfig — single place to change when the ngrok URL rotates.
///
/// Steps to update after restarting ngrok:
///   1. Copy the new https URL from the ngrok terminal
///      (e.g. https://xxxx.ngrok-free.app)
///   2. Paste it into [baseUrl] below (keep the /api suffix)
///   3. Hot-restart the app — done.
/// ─────────────────────────────────────────────────────────────────────────────
class AppConfig {
  AppConfig._();

  /// The full backend base URL including the /api prefix.
  /// ⚠️  Change ONLY this line when the ngrok URL changes.
  static const String baseUrl =
      'https://important-satisfy-sternness.ngrok-free.dev/api';
}
