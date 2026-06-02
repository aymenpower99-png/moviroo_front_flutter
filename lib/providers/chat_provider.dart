import 'package:flutter/foundation.dart';
import '../services/chat_service.dart';
import '../pages/chat/_ChatMessage.dart';

/// Provider for caching chat messages by rideId.
/// Prevents unnecessary API calls when navigating in and out of chat.
class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();

  /// Cache of messages keyed by rideId
  final Map<String, List<ChatMessage>> _chatsByRideId = {};

  /// Track loading state per rideId
  final Map<String, bool> _loadingByRideId = {};

  /// Track errors per rideId
  final Map<String, String?> _errorByRideId = {};

  /// Current user ID (set when first message is loaded)
  String? _currentUserId;

  List<ChatMessage> getMessages(String rideId) {
    return _chatsByRideId[rideId] ?? [];
  }

  bool isLoading(String rideId) {
    return _loadingByRideId[rideId] ?? false;
  }

  String? getError(String rideId) {
    return _errorByRideId[rideId];
  }

  /// Fetch messages from backend if not already cached.
  /// [currentUserId] is required to correctly set `isMe` on each message.
  Future<void> fetchMessages(
    String rideId, {
    String? currentUserId,
    bool translate = false,
    String? targetLang,
  }) async {
    debugPrint(
      '📦 [ChatProvider] Fetching messages for ride: $rideId (translate=$translate, lang=$targetLang)',
    );
    _loadingByRideId[rideId] = true;
    _errorByRideId[rideId] = null;
    notifyListeners();

    try {
      final history = await _chatService.fetchHistory(
        rideId,
        translate: translate,
        targetLang: targetLang,
      );

      // Use provided currentUserId; do NOT guess from first message.
      if (currentUserId != null) {
        _currentUserId = currentUserId;
      }

      _chatsByRideId[rideId] = history.map((m) => _chatMsgToUI(m, locale: targetLang)).toList();
      _loadingByRideId[rideId] = false;
      notifyListeners();

      debugPrint(
        '📦 [ChatProvider] Loaded ${history.length} messages for ride: $rideId',
      );
    } catch (e) {
      _errorByRideId[rideId] = e.toString();
      _loadingByRideId[rideId] = false;
      notifyListeners();
      debugPrint('📦 [ChatProvider] Failed to load messages: $e');
    }
  }

  /// Add a new message to the cache
  void addMessage(String rideId, ChatMessage message) {
    if (!_chatsByRideId.containsKey(rideId)) {
      _chatsByRideId[rideId] = [];
    }

    // Avoid duplicates
    if (_chatsByRideId[rideId]!.any((m) => m.id == message.id)) {
      return;
    }

    _chatsByRideId[rideId]!.add(message);
    notifyListeners();
  }

  /// Update a message in the cache
  void updateMessage(String rideId, String messageId, String text) {
    if (!_chatsByRideId.containsKey(rideId)) return;

    final index = _chatsByRideId[rideId]!.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      _chatsByRideId[rideId]![index] = _chatsByRideId[rideId]![index].copyWith(
        text: text,
        isEdited: true,
      );
      notifyListeners();
    }
  }

  /// Delete a message from the cache
  void deleteMessage(String rideId, String messageId) {
    if (!_chatsByRideId.containsKey(rideId)) return;

    _chatsByRideId[rideId]!.removeWhere((m) => m.id == messageId);
    notifyListeners();
  }

  /// Clear cache for a specific ride
  void clearCache(String rideId) {
    _chatsByRideId.remove(rideId);
    _loadingByRideId.remove(rideId);
    _errorByRideId.remove(rideId);
    notifyListeners();
  }

  /// Clear all cache
  void clearAllCache() {
    _chatsByRideId.clear();
    _loadingByRideId.clear();
    _errorByRideId.clear();
    notifyListeners();
  }

  /// Convert backend ChatMsg to UI ChatMessage
  ChatMessage _chatMsgToUI(ChatMsg m, {String? locale}) {
    // When translation is active, backend returns:
    //   text = translated version
    //   original_text = original version
    // When translation is off, backend returns:
    //   text = original version
    //   original_text = null
    final bool hasTranslation = m.originalText != null && m.originalText!.isNotEmpty;

    if (hasTranslation) {
      return ChatMessage(
        id: m.id,
        text: m.originalText!,         // show original as main text
        translatedText: m.text,         // show translated as secondary
        isMe: m.senderId == _currentUserId,
        time: _formatTime(m.createdAt),
        isEdited: m.isEdited,
      );
    }

    // For real-time WebSocket messages: check if translations map has our locale
    if (m.translations != null && locale != null && m.translations!.containsKey(locale)) {
      return ChatMessage(
        id: m.id,
        text: m.text,                       // original
        translatedText: m.translations![locale], // pre-translated from WebSocket
        isMe: m.senderId == _currentUserId,
        time: _formatTime(m.createdAt),
        isEdited: m.isEdited,
      );
    }

    return ChatMessage(
      id: m.id,
      text: m.text,
      isMe: m.senderId == _currentUserId,
      time: _formatTime(m.createdAt),
      isEdited: m.isEdited,
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour:$m $period';
  }
}
