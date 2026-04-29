import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../services/chat_service.dart';
import '_ChatMessage.dart';
import '_ChatInput.dart';
import '_TranslationBanner.dart';

class ChatPage extends StatefulWidget {
  final String rideId;
  final String? driverName;
  final String? driverId;
  final String? vehicleName;
  final String? vehicleColor;
  final String? plateNumber;

  const ChatPage({
    super.key,
    required this.rideId,
    this.driverName,
    this.driverId,
    this.vehicleName,
    this.vehicleColor,
    this.plateNumber,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _input = TextEditingController();
  bool _autoTranslate = true;
  final ChatService _chatService = ChatService();
  String? _currentUserId;
  bool _loading = true;

  // Messages will be loaded from backend via WebSocket
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    debugPrint(
      '🔵 [PassengerChat] Initializing chat with rideId: ${widget.rideId}',
    );

    // Get current user ID from token storage
    _currentUserId = await TokenStorage.getUserId();
    debugPrint('🔵 [PassengerChat] User ID: $_currentUserId');

    // Wire socket callbacks
    _chatService.onMessage = _onNewMessage;
    _chatService.onEdited = _onMessageEdited;
    _chatService.onDeleted = _onMessageDeleted;

    // Connect WebSocket
    try {
      await _chatService.connect(widget.rideId);
      debugPrint('✅ [PassengerChat] WebSocket connected');
    } catch (e) {
      debugPrint('❌ [PassengerChat] WebSocket connection failed: $e');
    }

    // Load history
    try {
      final history = await _chatService.fetchHistory(widget.rideId);
      debugPrint('✅ [PassengerChat] Loaded ${history.length} messages');
      if (mounted) {
        setState(() {
          _messages.clear();
          for (final m in history) {
            _messages.add(_chatMsgToUI(m));
          }
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('❌ [PassengerChat] Failed to load history: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  ChatMessage _chatMsgToUI(ChatMsg m) {
    return ChatMessage(
      id: m.id,
      text: m.text,
      isMe: m.senderId == _currentUserId,
      time: _formatTime(m.createdAt),
      isVoice: m.isVoice,
      isEdited: m.isEdited,
    );
  }

  void _onNewMessage(ChatMsg msg) {
    // Avoid duplicates (we already added optimistic local messages)
    if (_messages.any((m) => m.id == msg.id)) return;
    // Remove optimistic placeholder if this is our own message
    if (msg.senderId == _currentUserId) {
      _messages.removeWhere(
        (m) => m.id.startsWith('local_') && m.text == msg.text,
      );
    }
    if (mounted) {
      setState(() => _messages.add(_chatMsgToUI(msg)));
      _scrollToBottom();
    }
  }

  void _onMessageEdited(String messageId, String text) {
    if (!mounted) return;
    setState(() {
      final idx = _messages.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        _messages[idx] = _messages[idx].copyWith(text: text, isEdited: true);
      }
    });
  }

  void _onMessageDeleted(String messageId) {
    if (!mounted) return;
    setState(() => _messages.removeWhere((m) => m.id == messageId));
  }

  // ── Delete ──────────────────────────────────────────────
  void _deleteMessage(String id) {
    _chatService.deleteMessage(rideId: widget.rideId, messageId: id);
    setState(() => _messages.removeWhere((m) => m.id == id));
  }

  // ── Edit ────────────────────────────────────────────────
  void _editMessage(String id, String newText) {
    _chatService.editMessage(
      rideId: widget.rideId,
      messageId: id,
      text: newText,
    );
    setState(() {
      final index = _messages.indexWhere((m) => m.id == id);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
          text: newText,
          isEdited: true,
        );
      }
    });
  }

  // ── Send text ───────────────────────────────────────────
  void _sendMessage(String text) {
    if (text.trim().isEmpty ||
        widget.rideId.isEmpty ||
        _currentUserId == null) {
      return;
    }

    _chatService.sendMessage(
      rideId: widget.rideId,
      senderId: _currentUserId!,
      senderRole: 'passenger',
      text: text.trim(),
    );

    _input.clear();
    _scrollToBottom();
  }

  // ── Send voice ──────────────────────────────────────────
  void _sendVoice(String audioPath) {
    if (widget.rideId.isEmpty || _currentUserId == null) return;

    _chatService.sendMessage(
      rideId: widget.rideId,
      senderId: _currentUserId!,
      senderRole: 'passenger',
      text: '🎤 Voice message',
      isVoice: true,
    );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour:$m $period';
  }

  @override
  void dispose() {
    _scroll.dispose();
    _input.dispose();
    _chatService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            _ChatTopBar(
              driverName: widget.driverName,
              vehicleName: widget.vehicleName,
              vehicleColor: widget.vehicleColor,
              plateNumber: widget.plateNumber,
            ),
            TranslationBanner(
              enabled: _autoTranslate,
              onToggle: (v) => setState(() => _autoTranslate = v),
            ),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: _messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages',
                          style: AppTextStyles.bodySmall(
                            context,
                          ).copyWith(color: AppColors.subtext(context)),
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final msg = _messages[i];
                          return ChatBubble(
                            message: msg,
                            showTranslation: _autoTranslate,
                            onDelete: () => _deleteMessage(msg.id),
                            onEdit: (newText) => _editMessage(msg.id, newText),
                          );
                        },
                      ),
              ),
            ChatInputBar(
              controller: _input,
              onSend: _sendMessage,
              onVoiceSend: _sendVoice, // <-- wired here
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatTopBar extends StatelessWidget {
  final String? driverName;
  final String? vehicleName;
  final String? vehicleColor;
  final String? plateNumber;

  const _ChatTopBar({
    this.driverName,
    this.vehicleName,
    this.vehicleColor,
    this.plateNumber,
  });

  String get _vehicleInfo {
    final parts = <String>[];
    if (vehicleName != null && vehicleName!.isNotEmpty) parts.add(vehicleName!);
    if (vehicleColor != null && vehicleColor!.isNotEmpty)
      parts.add(vehicleColor!);
    if (plateNumber != null && plateNumber!.isNotEmpty) parts.add(plateNumber!);
    return parts.isNotEmpty ? parts.join(' • ') : 'Vehicle info';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryPurple.withValues(alpha: 0.15),
            child: Icon(
              Icons.person_rounded,
              color: AppColors.primaryPurple,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName ?? 'Driver',
                  style: AppTextStyles.bodyMedium(
                    context,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  _vehicleInfo,
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(color: AppColors.subtext(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
