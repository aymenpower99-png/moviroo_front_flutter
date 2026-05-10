/// Central feature flags for the Moviroo app.
///
/// Toggle these booleans to enable or disable features without deleting code.
class FeatureFlags {
  FeatureFlags._();

  /// Whether the WebAuthn / Passkey feature is visible in the UI.
  /// Backend APIs, native channels, and all logic remain intact.
  static const bool enablePasskeys = false;
}
