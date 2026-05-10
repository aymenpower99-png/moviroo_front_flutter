import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../services/support_service.dart';
import '../../../../services/ticket_read_receipt_helper.dart';
import '../../../../services/chat_cache_helper.dart';
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
  final TextEditingController _editController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SupportService _supportService = SupportService();

  SupportTicket? _ticket;
  List<TicketMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _currentUserId;

  // Inline editing state
  String? _editingMessageId;
  bool _isSavingEdit = false;

  // Unread divider state
  int? _firstUnreadIndex;

  bool get _isResolved => _ticket?.status == SupportTicketStatus.resolved;

  @override
  void initState() {
    super.initState();
    _initUserAndLoad();
  }

  Future<void> _initUserAndLoad() async {
    _currentUserId = await TokenStorage.getUserId();
    print('[SupportChatPage] Current user ID: $_currentUserId');

    // 1. Cache-first: render instantly if we have local data
    final cached = await ChatCacheHelper.load(widget.ticketId);
    if (cached != null) {
      _renderFromCache(cached);
    }

    // 2. Fresh fetch in background
    await _loadTicket();

    // 3. Mark as read and set cleared flag so divider won't reappear
    await TicketReadReceiptHelper.markAsRead(widget.ticketId);
    await TicketReadReceiptHelper.setUnreadCleared(widget.ticketId, true);
  }

  void _renderFromCache(Map<String, dynamic> cached) {
    try {
      final currentUserId = _currentUserId ?? '';
      final ticket =
          SupportTicket.fromJson(cached['ticket'] as Map<String, dynamic>);
      final messages = (cached['messages'] as List<dynamic>)
          .map((e) =>
              TicketMessage.fromJson(e as Map<String, dynamic>, currentUserId))
          .toList();

      if (mounted) {
        setState(() {
          _ticket = ticket;
          _messages = messages;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[SupportChatPage] Cache parse error: $e');
    }
  }

  Future<void> _loadTicket() async {
    try {
      print('[SupportChatPage] Loading ticket: ${widget.ticketId}');
      final data = await _supportService.getTicket(widget.ticketId);
      final loadedTicket = data['ticket'] as SupportTicket;
      final loadedMessages = data['messages'] as List<TicketMessage>;
      print(
          '[SupportChatPage] Loaded ${loadedMessages.length} messages');

      // ── Find latest admin message timestamp ──────────────────────────────
      DateTime? freshLastAdminMsgAt;
      for (final m in loadedMessages) {
        if (m.isFromAdmin) {
          if (freshLastAdminMsgAt == null ||
              m.createdAt.isAfter(freshLastAdminMsgAt)) {
            freshLastAdminMsgAt = m.createdAt;
          }
        }
      }

      // ── Detect new admin messages since last visit ───────────────────────
      final cachedLastAdminMsgAt =
          await TicketReadReceiptHelper.getLastAdminMessageAt(widget.ticketId);
      if (freshLastAdminMsgAt != null &&
          (cachedLastAdminMsgAt == null ||
              freshLastAdminMsgAt.isAfter(cachedLastAdminMsgAt))) {
        // New admin messages arrived → reset cleared flag so divider can show
        await TicketReadReceiptHelper.setUnreadCleared(widget.ticketId, false);
      }
      await TicketReadReceiptHelper.setLastAdminMessageAt(
          widget.ticketId, freshLastAdminMsgAt);

      // ── Persist full ticket+messages to cache ────────────────────────────
      await ChatCacheHelper.save(
          widget.ticketId, loadedTicket, loadedMessages);

      // ── Compute unread divider position ──────────────────────────────────
      final lastRead = await TicketReadReceiptHelper.getLastRead(widget.ticketId);
      final unreadCleared =
          await TicketReadReceiptHelper.isUnreadCleared(widget.ticketId);

      int? firstUnreadIndex;
      if (!unreadCleared &&
          lastRead != null &&
          freshLastAdminMsgAt != null &&
          freshLastAdminMsgAt.isAfter(lastRead)) {
        for (int i = 0; i < loadedMessages.length; i++) {
          if (loadedMessages[i].createdAt.isAfter(lastRead) &&
              loadedMessages[i].isFromAdmin) {
            firstUnreadIndex = i;
            break;
          }
        }
      }

      if (mounted) {
        setState(() {
          _ticket = loadedTicket;
          _messages = loadedMessages;
          _isLoading = false;
          _firstUnreadIndex = firstUnreadIndex;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('[SupportChatPage] Error loading ticket: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        if (_messages.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load ticket: $e')),
          );
        }
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
    if (text.isEmpty || _isSending || _isResolved) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await _supportService.replyToTicket(
        ticketId: widget.ticketId,
        body: text,
      );
      await _loadTicket();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _startEdit(TicketMessage message) {
    setState(() {
      _editingMessageId = message.id;
      _editController.text = message.body;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingMessageId = null;
      _editController.clear();
    });
  }

  Future<void> _saveEdit(String messageId) async {
    final text = _editController.text.trim();
    if (text.isEmpty || _isSavingEdit) return;

    setState(() => _isSavingEdit = true);
    try {
      await _supportService.editMessage(
        ticketId: widget.ticketId,
        messageId: messageId,
        body: text,
      );
      setState(() {
        _editingMessageId = null;
        _editController.clear();
      });
      await _loadTicket();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to edit: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingEdit = false);
    }
  }

  Future<void> _confirmDelete(TicketMessage message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _supportService.deleteMessage(
        ticketId: widget.ticketId,
        messageId: message.id,
      );
      setState(() {
        _messages.removeWhere((m) => m.id == message.id);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  void _showMessageOptions(TicketMessage message) {
    if (_isResolved) return;
    final isMine =
        _currentUserId != null && message.senderId == _currentUserId;
    if (!isMine) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading:
                    const Icon(Icons.edit, color: AppColors.primaryPurple),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(ctx);
                  _startEdit(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(message);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _editController.dispose();
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
            child: _isLoading && _messages.isEmpty
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
                              dateLabel =
                                  _formatDateLabel(message.createdAt);
                            }
                          }

                          final isEditing = _editingMessageId == message.id;
                          final showUnreadDivider =
                              _firstUnreadIndex == index;

                          return Column(
                            children: [
                              if (showDateSeparator)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface(context),
                                        borderRadius:
                                            BorderRadius.circular(12),
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
                              if (showUnreadDivider) const _UnreadDivider(),
                              if (isEditing)
                                _EditBubble(
                                  controller: _editController,
                                  isSaving: _isSavingEdit,
                                  onSave: () => _saveEdit(message.id),
                                  onCancel: _cancelEdit,
                                )
                              else
                                _MessageBubble(
                                  message: message,
                                  time: _formatTime(message.createdAt),
                                  currentUserId: _currentUserId,
                                  onLongPress: () =>
                                      _showMessageOptions(message),
                                  edited: message.updatedAt != null,
                                ),
                            ],
                          );
                        },
                      ),
          ),
          if (_isResolved)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                border:
                    Border(top: BorderSide(color: AppColors.border(context))),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline,
                      size: 18, color: AppColors.subtext(context)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This ticket is closed. You can still read the conversation history.',
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.subtext(context),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
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

class _UnreadDivider extends StatelessWidget {
  const _UnreadDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: AppColors.primaryPurple.withValues(alpha: 0.35),
              thickness: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Unread messages',
              style: AppTextStyles.bodySmall(context).copyWith(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: AppColors.primaryPurple.withValues(alpha: 0.35),
              thickness: 1,
            ),
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
  final VoidCallback? onLongPress;
  final bool edited;

  const _MessageBubble({
    required this.message,
    required this.time,
    this.currentUserId,
    this.onLongPress,
    this.edited = false,
  });

  @override
  Widget build(BuildContext context) {
    final isFromMe =
        currentUserId != null && message.senderId == currentUserId;

    return Align(
      alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  color:
                      isFromMe ? Colors.white : AppColors.text(context),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: isFromMe
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppColors.subtext(context),
                      fontSize: 11,
                    ),
                  ),
                  if (edited) ...[
                    const SizedBox(width: 6),
                    Text(
                      'edited',
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: isFromMe
                            ? Colors.white.withValues(alpha: 0.6)
                            : AppColors.subtext(context),
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditBubble extends StatelessWidget {
  final TextEditingController controller;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _EditBubble({
    required this.controller,
    required this.isSaving,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryPurple),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Edit message...',
                hintStyle: AppTextStyles.bodyMedium(context)
                    .copyWith(color: AppColors.subtext(context)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: AppTextStyles.bodyMedium(context)
                  .copyWith(color: AppColors.text(context)),
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSave(),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.bodySmall(context)
                        .copyWith(color: AppColors.subtext(context)),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: isSaving ? null : onSave,
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Save',
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
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
