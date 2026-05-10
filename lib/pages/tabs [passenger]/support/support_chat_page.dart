import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../services/support_service.dart';
import '../../../../core/storage/token_storage.dart';

class SupportChatPage extends StatefulWidget {
  final String ticketId;
  final String subject;

  const SupportChatPage({
    super.key,
    required this.ticketId,
    required this.subject,
  });

  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SupportService _supportService = SupportService();

  List<TicketMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initUserAndLoad();
  }

  Future<void> _initUserAndLoad() async {
    _currentUserId = await TokenStorage.getUserId();
    print('[SupportChatPage] Current user ID: $_currentUserId');
    await _loadTicket();
  }

  Future<void> _loadTicket() async {
    try {
      print('[SupportChatPage] Loading ticket: ${widget.ticketId}');
      final data = await _supportService.getTicket(widget.ticketId);
      final loadedMessages = data['messages'] as List<TicketMessage>;
      print('[SupportChatPage] Loaded ${loadedMessages.length} messages');
      for (final m in loadedMessages) {
        print('[SupportChatPage] msg id=${m.id} senderId=${m.senderId} isFromAdmin=${m.isFromAdmin} body=${m.body}');
      }
      if (mounted) {
        setState(() {
          _messages = loadedMessages;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('[SupportChatPage] Error loading ticket: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load ticket: $e')));
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await _supportService.replyToTicket(
        ticketId: widget.ticketId,
        body: text,
      );
      // Reload to get the new message
      await _loadTicket();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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
      final months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Support', style: AppTextStyles.bodyMedium(context)),
            Text(
              widget.subject,
              style: AppTextStyles.bodySmall(
                context,
              ).copyWith(color: AppColors.subtext(context)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet',
                      style: AppTextStyles.bodyMedium(
                        context,
                      ).copyWith(color: AppColors.subtext(context)),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];

                      // Date separator logic
                      bool showDateSeparator = false;
                      String dateLabel = '';

                      if (index == 0) {
                        showDateSeparator = true;
                        dateLabel = _formatDateLabel(message.createdAt);
                      } else {
                        final prevMsg = _messages[index - 1];
                        final currentDate = DateTime(
                          message.createdAt.year,
                          message.createdAt.month,
                          message.createdAt.day,
                        );
                        final prevDate = DateTime(
                          prevMsg.createdAt.year,
                          prevMsg.createdAt.month,
                          prevMsg.createdAt.day,
                        );
                        if (currentDate != prevDate) {
                          showDateSeparator = true;
                          dateLabel = _formatDateLabel(message.createdAt);
                        }
                      }

                      return Column(
                        children: [
                          if (showDateSeparator)
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
                          _MessageBubble(
                            message: message,
                            time: _formatTime(message.createdAt),
                            currentUserId: _currentUserId,
                          ),
                        ],
                      );
                    },
                  ),
          ),
          _MessageInputBar(
            controller: _messageController,
            isSending: _isSending,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final TicketMessage message;
  final String time;
  final String? currentUserId;

  const _MessageBubble({
    required this.message,
    required this.time,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    // Passenger (current user) → RIGHT, purple bubble.
    // Admin (anyone else) → LEFT, white/neutral bubble.
    final isFromMe =
        currentUserId != null && message.senderId == currentUserId;

    return Align(
      alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isFromMe
              ? AppColors.primaryPurple
              : AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: isFromMe
              ? null
              : Border.all(color: AppColors.border(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.body,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: isFromMe ? Colors.white : AppColors.text(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: AppTextStyles.bodySmall(context).copyWith(
                color: isFromMe
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppColors.subtext(context),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _MessageInputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        border: Border(top: BorderSide(color: AppColors.border(context))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(color: AppColors.subtext(context)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.bg(context),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: isSending ? null : onSend,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSending
                    ? AppColors.subtext(context)
                    : AppColors.primaryPurple,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSending ? Icons.hourglass_empty : Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
