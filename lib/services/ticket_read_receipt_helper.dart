import 'package:shared_preferences/shared_preferences.dart';

/// Helper for persisting per-ticket read/unread state.
///
/// Used by both the Messages list (purple dot) and the Chat screen
/// ("Unread messages" divider) to keep unread indicators in sync.
class TicketReadReceiptHelper {
  static const String _lastReadPrefix = 'last_read_ticket_';
  static const String _clearedPrefix = 'unread_cleared_';
  static const String _lastAdminMsgPrefix = 'last_admin_msg_';

  static String _lastReadKey(String ticketId) => '$_lastReadPrefix$ticketId';
  static String _clearedKey(String ticketId) => '$_clearedPrefix$ticketId';
  static String _lastAdminMsgKey(String ticketId) =>
      '$_lastAdminMsgPrefix$ticketId';

  // ── last_read_at ───────────────────────────────────────────────────────────

  static Future<void> markAsRead(String ticketId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _lastReadKey(ticketId), DateTime.now().toIso8601String());
  }

  static Future<DateTime?> getLastRead(String ticketId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastReadKey(ticketId));
    if (raw == null) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  // ── unread_cleared flag (divider) ──────────────────────────────────────────

  static Future<bool> isUnreadCleared(String ticketId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_clearedKey(ticketId)) ?? false;
  }

  static Future<void> setUnreadCleared(
      String ticketId, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_clearedKey(ticketId), value);
  }

  // ── last_admin_message_at (cached from full ticket fetch) ──────────────────

  static Future<DateTime?> getLastAdminMessageAt(String ticketId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastAdminMsgKey(ticketId));
    if (raw == null) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setLastAdminMessageAt(
      String ticketId, DateTime? dt) async {
    final prefs = await SharedPreferences.getInstance();
    if (dt == null) {
      await prefs.remove(_lastAdminMsgKey(ticketId));
    } else {
      await prefs.setString(_lastAdminMsgKey(ticketId), dt.toIso8601String());
    }
  }

  // ── unread check ───────────────────────────────────────────────────────────

  /// Returns true when:
  /// - [lastAdminMessageAt] is not null AND
  /// - either no last_read exists (never opened) OR last_read is older.
  static Future<bool> hasUnread(
    String ticketId,
    DateTime? lastAdminMessageAt,
  ) async {
    if (lastAdminMessageAt == null) {
      // We don't know of any admin messages. If the user never opened
      // the chat we still show the dot conservatively.
      final lastRead = await getLastRead(ticketId);
      return lastRead == null;
    }
    final lastRead = await getLastRead(ticketId);
    if (lastRead == null) return true;
    return lastAdminMessageAt.isAfter(lastRead);
  }
}
