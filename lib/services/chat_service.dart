import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/config/app_config.dart';
import '../core/storage/token_storage.dart';

/// Represents a chat message from the backend.
class ChatMsg {
  final String id;
  final String rideId;
  final String senderId;
  final String senderRole;
  final String text;
  final String? originalText;
  final Map<String, String>? translations;
  final bool isVoice;
  final bool isEdited;
  final DateTime createdAt;

  ChatMsg({
    required this.id,
    required this.rideId,
    required this.senderId,
    required this.senderRole,
    required this.text,
    this.originalText,
    this.translations,
    this.isVoice = false,
    this.isEdited = false,
    required this.createdAt,
  });

  factory ChatMsg.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? transRaw =
        json['translations'] is Map ? json['translations'] as Map<String, dynamic> : null;
    final Map<String, String>? translations = transRaw != null
        ? Map<String, String>.from(transRaw)
        : null;

    return ChatMsg(
      id: json['id'] ?? '',
      rideId: json['ride_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      senderRole: json['sender_role'] ?? 'passenger',
      text: json['text'] ?? '',
      originalText: json['original_text'] as String?,
      translations: translations,
      isVoice: json['is_voice'] == true,
      isEdited: json['is_edited'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}

/// Chat service — connects to /chat WebSocket namespace and provides REST history.
class ChatService {
  io.Socket? _socket;
  String? _currentRideId;

  // Callbacks
  void Function(ChatMsg msg)? onMessage;
  void Function(String messageId, String text)? onEdited;
  void Function(String messageId)? onDeleted;

  /// Connect to the chat namespace and join the ride room.
  Future<void> connect(String rideId) async {
    if (_socket != null && _currentRideId == rideId) return;
    await disconnect();

    _currentRideId = rideId;
    final token = await TokenStorage.getAccess();

    // Strip /api suffix from base URL for WebSocket
    String wsUrl = AppConfig.baseUrl;
    if (wsUrl.endsWith('/api')) {
      wsUrl = wsUrl.substring(0, wsUrl.length - 4);
    }

    _socket = io.io(
      '$wsUrl/chat',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      _socket!.emit('chat:join', {'ride_id': rideId});
    });

    // Listen for new messages
    _socket!.on('chat:message', (data) {
      if (data is Map<String, dynamic>) {
        onMessage?.call(ChatMsg.fromJson(data));
      } else if (data is Map) {
        onMessage?.call(ChatMsg.fromJson(Map<String, dynamic>.from(data)));
      }
    });

    // Listen for edits
    _socket!.on('chat:edited', (data) {
      if (data is Map) {
        final id = data['message_id']?.toString() ?? '';
        final text = data['text']?.toString() ?? '';
        if (id.isNotEmpty) onEdited?.call(id, text);
      }
    });

    // Listen for deletes
    _socket!.on('chat:deleted', (data) {
      if (data is Map) {
        final id = data['message_id']?.toString() ?? '';
        if (id.isNotEmpty) onDeleted?.call(id);
      }
    });
  }

  /// Send a text message via WebSocket.
  void sendMessage({
    required String rideId,
    required String senderId,
    required String senderRole,
    required String text,
    bool isVoice = false,
  }) {
    _socket?.emit('chat:send', {
      'ride_id': rideId,
      'sender_id': senderId,
      'sender_role': senderRole,
      'text': text,
      'is_voice': isVoice,
    });
  }

  /// Edit a message via WebSocket.
  void editMessage({
    required String rideId,
    required String messageId,
    required String text,
  }) {
    _socket?.emit('chat:edit', {
      'ride_id': rideId,
      'message_id': messageId,
      'text': text,
    });
  }

  /// Delete a message via WebSocket.
  void deleteMessage({required String rideId, required String messageId}) {
    _socket?.emit('chat:delete', {'ride_id': rideId, 'message_id': messageId});
  }

  /// Fetch message history via REST.
  Future<List<ChatMsg>> fetchHistory(
    String rideId, {
    int limit = 50,
    bool translate = false,
    String? targetLang,
  }) async {
    try {
      final token = await TokenStorage.getAccess();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final queryParams = <String, String>{'limit': limit.toString()};
      if (translate && targetLang != null) {
        queryParams['translate'] = 'true';
        queryParams['lang'] = targetLang;
      }

      final uri = Uri.parse(
        '${AppConfig.baseUrl}/chat/$rideId/messages',
      ).replace(queryParameters: queryParams);

      final res = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body) as List<dynamic>;
        return data
            .map((e) => ChatMsg.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> disconnect() async {
    if (_currentRideId != null && _socket != null) {
      _socket!.emit('chat:leave', {'ride_id': _currentRideId});
    }
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _currentRideId = null;
  }
}
