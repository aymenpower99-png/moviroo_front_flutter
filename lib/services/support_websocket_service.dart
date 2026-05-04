import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/config/app_config.dart';
import '../core/storage/token_storage.dart';

/// Singleton WebSocket service for support tickets
/// Stays connected for entire app lifecycle to receive real-time updates
class SupportWebSocketService {
  static final SupportWebSocketService _instance =
      SupportWebSocketService._internal();
  factory SupportWebSocketService() => _instance;
  SupportWebSocketService._internal();

  io.Socket? _socket;
  String? _currentUserId;
  bool _isConnected = false;

  // Callbacks
  void Function(int unreadCount)? onUnreadCountChanged;

  Future<void> connect() async {
    if (_socket != null && _isConnected) return;

    _currentUserId = await TokenStorage.getUserId();
    if (_currentUserId == null) return;

    final token = await TokenStorage.getAccess();
    if (token == null) return;

    // Strip /api suffix from base URL for WebSocket
    String wsUrl = AppConfig.baseUrl;
    if (wsUrl.endsWith('/api')) {
      wsUrl = wsUrl.substring(0, wsUrl.length - 4);
    }

    _socket = io.io(
      '$wsUrl/support',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setExtraHeaders({'Authorization': 'Bearer $token', 'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      _isConnected = true;
      print('[SupportWebSocket] Connected to /support namespace');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      print('[SupportWebSocket] Disconnected');
    });

    _socket!.onConnectError((error) {
      _isConnected = false;
      print('[SupportWebSocket] Connection error: $error');
    });

    // Listen for admin replies to update unread count
    _socket!.on('support:ticket:reply', (data) {
      print('[SupportWebSocket] Received support:ticket:reply event: $data');
      if (data is Map<String, dynamic>) {
        _handleTicketReply(data);
      }
    });
  }

  void _handleTicketReply(Map<String, dynamic> data) {
    final senderId = data['senderId'] as String?;
    print(
      '[SupportWebSocket] _handleTicketReply - senderId: $senderId, currentUserId: $_currentUserId',
    );

    // Increment unread count if message is from admin (not from current user)
    if (senderId != null && senderId != _currentUserId) {
      print('[SupportWebSocket] Message from admin, incrementing unread count');
      onUnreadCountChanged?.call(1);
    }
  }

  Future<void> disconnect() async {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
    }
  }

  bool get isConnected => _isConnected;
}
