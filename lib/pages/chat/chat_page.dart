import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../services/chat_service.dart';
import '../../../../providers/chat_provider.dart';
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

    // Load history from provider (uses cache if available)
    final chatProvider = context.read<ChatProvider>();
    await chatProvider.fetchMessages(widget.rideId);

    if (mounted) {
      _scrollToBottom();
    }
  }

  ChatMessage _chatMsgToUI(ChatMsg m) {
    return ChatMessage(
      id: m.id,
      text: m.text,
      isMe: m.senderId == _currentUserId,
      time: _formatTime(m.createdAt),
      isEdited: m.isEdited,
    );
  }

  void _onNewMessage(ChatMsg msg) {
    final chatProvider = context.read<ChatProvider>();
    // Avoid duplicates (we already added optimistic local messages)
    if (chatProvider.getMessages(widget.rideId).any((m) => m.id == msg.id))
      return;
    // Remove optimistic placeholder if this is our own message
    if (msg.senderId == _currentUserId) {
      chatProvider.deleteMessage(
        widget.rideId,
        chatProvider
            .getMessages(widget.rideId)
            .firstWhere((m) => m.id.startsWith('local_') && m.text == msg.text)
            .id,
      );
    }
    if (mounted) {
      chatProvider.addMessage(widget.rideId, _chatMsgToUI(msg));
      _scrollToBottom();
    }
  }

  void _onMessageEdited(String messageId, String text) {
    if (!mounted) return;
    final chatProvider = context.read<ChatProvider>();
    chatProvider.updateMessage(widget.rideId, messageId, text);
  }

  void _onMessageDeleted(String messageId) {
    if (!mounted) return;
    final chatProvider = context.read<ChatProvider>();
    chatProvider.deleteMessage(widget.rideId, messageId);
  }

  // ── Delete ──────────────────────────────────────────────
  void _deleteMessage(String id) {
    _chatService.deleteMessage(rideId: widget.rideId, messageId: id);
    final chatProvider = context.read<ChatProvider>();
    chatProvider.deleteMessage(widget.rideId, id);
  }

  // ── Edit ────────────────────────────────────────────────
  void _editMessage(String id, String newText) {
    _chatService.editMessage(
      rideId: widget.rideId,
      messageId: id,
      text: newText,
    );
    final chatProvider = context.read<ChatProvider>();
    chatProvider.updateMessage(widget.rideId, id, newText);
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

  String _formatDateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dt.year, dt.month, dt.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      // Format as "May 6, 2026"
      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    }
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
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  final isLoading = chatProvider.isLoading(widget.rideId);
                  final messages = chatProvider.getMessages(widget.rideId);
                  final error = chatProvider.getError(widget.rideId);

                  if (isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error loading messages',
                            style: AppTextStyles.bodyMedium(context),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error,
                            style: AppTextStyles.bodySmall(
                              context,
                            ).copyWith(color: AppColors.subtext(context)),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () =>
                                chatProvider.fetchMessages(widget.rideId),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        'No messages',
                        style: AppTextStyles.bodySmall(
                          context,
                        ).copyWith(color: AppColors.subtext(context)),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, i) {
                      final msg = messages[i];

                      // Check if we need to show a date separator
                      bool showDateSeparator = false;
                      String dateLabel = '';

                      if (i == 0) {
                        // Always show date for first message
                        showDateSeparator = true;
                        if (msg.createdAt != null) {
                          dateLabel = _formatDateLabel(msg.createdAt!);
                        }
                      } else {
                        // Check if date changed from previous message
                        final prevMsg = messages[i - 1];
                        if (msg.createdAt != null &&
                            prevMsg.createdAt != null) {
                          final currentDate = DateTime(
                            msg.createdAt!.year,
                            msg.createdAt!.month,
                            msg.createdAt!.day,
                          );
                          final prevDate = DateTime(
                            prevMsg.createdAt!.year,
                            prevMsg.createdAt!.month,
                            prevMsg.createdAt!.day,
                          );
                          if (currentDate != prevDate) {
                            showDateSeparator = true;
                            dateLabel = _formatDateLabel(msg.createdAt!);
                          }
                        }
                      }

                      return Column(
                        children: [
                          if (showDateSeparator && dateLabel.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface(context),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.border(context),
                                    ),
                                  ),
                                  child: Text(
                                    dateLabel,
                                    style: AppTextStyles.bodySmall(context)
                                        .copyWith(
                                          color: AppColors.subtext(context),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ChatBubble(
                            message: msg,
                            showTranslation: _autoTranslate,
                            onDelete: () => _deleteMessage(msg.id),
                            onEdit: (newText) => _editMessage(msg.id, newText),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            ChatInputBar(controller: _input, onSend: _sendMessage),
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
