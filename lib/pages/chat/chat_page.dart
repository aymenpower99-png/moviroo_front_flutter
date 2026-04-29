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

  const ChatPage({
    super.key,
    required this.rideId,
    this.driverName,
    this.driverId,
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

  // Messages will be loaded from backend via WebSocket
  final List<ChatMessage> _messages = [];

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
  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userId = _currentUserId;
    if (userId == null) return;

    // Send via WebSocket
    _chatService.sendMessage(
      rideId: widget.rideId,
      senderId: userId,
      senderRole: 'passenger',
      text: text,
    );

    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: text,
          isMe: true,
          time: _formatTime(DateTime.now()),
        ),
      );
    });
    _input.clear();
    _scrollToBottom();
  }

  // ── Send voice ──────────────────────────────────────────
  void _sendVoice(String audioPath) {
    final userId = _currentUserId;
    if (userId == null) return;

    _chatService.sendMessage(
      rideId: widget.rideId,
      senderId: userId,
      senderRole: 'passenger',
      text: '🎤 Voice message',
      isVoice: true,
    );
    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: '🎤 Voice message',
          isMe: true,
          time: _formatTime(DateTime.now()),
          isVoice: true,
          audioPath: audioPath,
        ),
      );
    });
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
            _ChatTopBar(driverName: widget.driverName),
            TranslationBanner(
              enabled: _autoTranslate,
              onToggle: (v) => setState(() => _autoTranslate = v),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Today, 2:41 PM',
                style: AppTextStyles.bodySmall(
                  context,
                ).copyWith(color: AppColors.subtext(context), fontSize: 11),
              ),
            ),
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

  const _ChatTopBar({this.driverName});

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
                  'Vehicle info',
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
