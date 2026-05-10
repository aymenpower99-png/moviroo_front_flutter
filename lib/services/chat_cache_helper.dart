import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'support_service.dart';

/// Persistent cache for per-ticket chat data.
///
/// On first open the chat fetches from the API and saves here.
/// On every subsequent open the cached messages are rendered instantly
/// (zero spinner) while a silent background refresh runs.
class ChatCacheHelper {
  static const String _ticketPrefix = 'cached_ticket_';
  static const String _messagesPrefix = 'cached_messages_';

  static String _ticketKey(String ticketId) => '$_ticketPrefix$ticketId';
  static String _messagesKey(String ticketId) => '$_messagesPrefix$ticketId';

  /// Save ticket + messages to local cache.
  static Future<void> save(
    String ticketId,
    SupportTicket ticket,
    List<TicketMessage> messages,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ticketKey(ticketId), jsonEncode(_ticketToJson(ticket)));
    await prefs.setString(
      _messagesKey(ticketId),
      jsonEncode(messages.map(_messageToJson).toList()),
    );
  }

  /// Load raw cached data for a ticket.
  /// Returns a map with keys 'ticket' and 'messages' (both JSON maps/lists),
  /// or null if nothing is cached.
  static Future<Map<String, dynamic>?> load(String ticketId) async {
    final prefs = await SharedPreferences.getInstance();
    final ticketRaw = prefs.getString(_ticketKey(ticketId));
    final messagesRaw = prefs.getString(_messagesKey(ticketId));
    if (ticketRaw == null || messagesRaw == null) return null;
    try {
      return {
        'ticket': jsonDecode(ticketRaw) as Map<String, dynamic>,
        'messages': jsonDecode(messagesRaw) as List<dynamic>,
      };
    } catch (_) {
      return null;
    }
  }

  /// Clear cache for a specific ticket.
  static Future<void> clear(String ticketId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ticketKey(ticketId));
    await prefs.remove(_messagesKey(ticketId));
  }

  static Map<String, dynamic> _ticketToJson(SupportTicket t) => {
        'id': t.id,
        'subject': t.subject,
        'description': t.description,
        'status': t.status.value,
        'category': t.category.value,
        'ride_id': t.rideId,
        'created_at': t.createdAt.toIso8601String(),
        'updated_at': t.updatedAt.toIso8601String(),
        'last_message': t.lastMessage,
        'last_message_at': t.lastMessageAt?.toIso8601String(),
        'has_unread': t.hasUnread,
      };

  static Map<String, dynamic> _messageToJson(TicketMessage m) => {
        'id': m.id,
        'body': m.body,
        'senderId': m.senderId,
        'ticketId': m.ticketId,
        'createdAt': m.createdAt.toIso8601String(),
        'updatedAt': m.updatedAt?.toIso8601String(),
        'isFromAdmin': m.isFromAdmin,
      };
}
