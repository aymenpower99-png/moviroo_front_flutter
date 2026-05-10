import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../services/support_service.dart';
import '../../../../services/ticket_read_receipt_helper.dart';

class MessagesModal extends StatefulWidget {
  final List<SupportTicket> initialTickets;
  final Function(SupportTicket) onTicketTap;

  const MessagesModal({
    super.key,
    required this.initialTickets,
    required this.onTicketTap,
  });

  @override
  State<MessagesModal> createState() => _MessagesModalState();
}

class _MessagesModalState extends State<MessagesModal> {
  final SupportService _supportService = SupportService();
  List<SupportTicket> _tickets = [];
  Map<String, bool> _unreadMap = {};
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tickets = List.from(widget.initialTickets);
    _computeUnreadMap();
    _loadTickets();
  }

  Future<void> _computeUnreadMap() async {
    final map = <String, bool>{};
    for (final t in _tickets) {
      final lastAdminMsgAt =
          await TicketReadReceiptHelper.getLastAdminMessageAt(t.id) ??
              t.lastMessageAt;
      final unread = await TicketReadReceiptHelper.hasUnread(t.id, lastAdminMsgAt);
      map[t.id] = unread;
    }
    if (mounted) setState(() => _unreadMap = map);
  }

  Future<void> _loadTickets() async {
    setState(() => _isRefreshing = true);
    try {
      final fresh = await _supportService.listTickets();
      if (mounted) {
        setState(() {
          _tickets = fresh;
          _isRefreshing = false;
        });
        _computeUnreadMap();
      }
    } catch (_) {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _handleTap(SupportTicket ticket) {
    // Remove dot immediately in-memory
    setState(() => _unreadMap[ticket.id] = false);
    TicketReadReceiptHelper.markAsRead(ticket.id);
    widget.onTicketTap(ticket);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Messages',
                    style: AppTextStyles.pageTitle(
                      context,
                    ).copyWith(fontSize: 20),
                  ),
                ),
                if (_isRefreshing)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryPurple,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Expanded(
            child: _tickets.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet',
                      style: AppTextStyles.bodyMedium(
                        context,
                      ).copyWith(color: AppColors.subtext(context)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = _tickets[index];
                      return _TicketThreadItem(
                        ticket: ticket,
                        showDot: _unreadMap[ticket.id] ?? false,
                        onTap: () => _handleTap(ticket),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TicketThreadItem extends StatelessWidget {
  final SupportTicket ticket;
  final bool showDot;
  final VoidCallback onTap;

  const _TicketThreadItem({
    required this.ticket,
    required this.showDot,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bg(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.support_agent_rounded,
                color: AppColors.primaryPurple,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.subject,
                    style: AppTextStyles.bodyLarge(
                      context,
                    ).copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ticket.lastMessage ?? ticket.description,
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.subtext(context),
                      fontWeight: showDot
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Unread dot
            if (showDot)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(left: 8),
                decoration: const BoxDecoration(
                  color: AppColors.primaryPurple,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
